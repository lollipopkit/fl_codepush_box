package main

import (
	"context"
	"database/sql"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"sync/atomic"
	"time"

	"github.com/glebarez/sqlite"
	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

type Server struct {
	db         *sql.DB
	gormDB     *gorm.DB
	objectsDir string
	storage    Storage
	metrics    ServerMetrics
}

type ServerMetrics struct {
	PatchCheckRequests atomic.Uint64
	EventWrites        atomic.Uint64
	StorageErrors      atomic.Uint64
}

func main() {
	dbPath := flag.String("db", envDefault("FCB_SERVER_DB", ".fcb/server/fcb.sqlite"), "sqlite database path")
	objectsDir := flag.String("objects", "", "object storage directory")
	storeCompat := flag.String("store", "", "deprecated json store path; sqlite db path is used for compatibility")
	flag.Parse()

	if *storeCompat != "" && *dbPath == envDefault("FCB_SERVER_DB", ".fcb/server/fcb.sqlite") {
		*dbPath = *storeCompat
	}
	server, err := NewServerWithObjects(*dbPath, *objectsDir)
	if err != nil {
		log.Fatal(err)
	}
	defer server.Close()
	cleanupCtx, cancelCleanup := context.WithCancel(context.Background())
	defer cancelCleanup()
	server.startEventRetentionCleanup(cleanupCtx, eventRetentionDaysFromEnv(), 24*time.Hour)

	app := buildApp(server)
	addr := envDefault("FCB_SERVER_ADDR", "127.0.0.1:8080")
	log.Printf("fcb server listening on %s", addr)
	log.Fatal(app.Listen(addr))
}

func NewServer(path string) (*Server, error) {
	return NewServerWithObjects(path, "")
}

func NewServerWithObjects(path string, objectsDir string) (*Server, error) {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return nil, err
	}
	if objectsDir == "" {
		objectsDir = filepath.Join(filepath.Dir(path), "objects")
	}
	storage, err := newStorageFromEnv(objectsDir)
	if err != nil {
		return nil, err
	}
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, err
	}
	gormDB, err := gorm.Open(sqlite.Open(path), &gorm.Config{})
	if err != nil {
		_ = db.Close()
		return nil, err
	}
	server := &Server{db: db, gormDB: gormDB, objectsDir: objectsDir, storage: storage}
	if err := server.migrate(); err != nil {
		if gdb, gerr := gormDB.DB(); gerr == nil {
			_ = gdb.Close()
		}
		_ = db.Close()
		return nil, err
	}
	return server, nil
}

func newStorageFromEnv(objectsDir string) (Storage, error) {
	switch driver := envDefault("FCB_STORAGE_DRIVER", "fs"); driver {
	case "fs":
		return NewLocalFSStorage(objectsDir)
	case "s3":
		return NewS3Storage(context.Background(), S3StorageConfig{
			Bucket:          os.Getenv("FCB_S3_BUCKET"),
			Region:          os.Getenv("FCB_S3_REGION"),
			Endpoint:        os.Getenv("FCB_S3_ENDPOINT"),
			AccessKeyID:     os.Getenv("FCB_S3_ACCESS_KEY_ID"),
			SecretAccessKey: os.Getenv("FCB_S3_SECRET_ACCESS_KEY"),
		})
	default:
		return nil, fmt.Errorf("unsupported FCB_STORAGE_DRIVER %q", driver)
	}
}

func (s *Server) Close() error {
	if s.gormDB != nil {
		if db, err := s.gormDB.DB(); err == nil {
			_ = db.Close()
		}
	}
	return s.db.Close()
}

func buildApp(server *Server) *fiber.App {
	app := fiber.New()
	app.Get("/healthz", server.healthz)
	app.Get("/metrics", server.metricsHandler)
	app.Get("/api/auth/setup-status", server.setupStatus)
	app.Post("/api/auth/setup", server.setup)
	app.Post("/api/auth/login", server.login)
	app.Post("/api/auth/logout", server.logout)
	app.Get("/api/auth/me", server.requireSession, server.me)

	admin := app.Group("/api/admin", server.requireSession)
	admin.Get("/orgs", server.adminListOrgs)
	admin.Post("/orgs", server.adminCreateOrg)
	admin.Get("/orgs/:org/members", server.requireOrgRole("member"), server.adminListOrgMembers)
	admin.Post("/orgs/:org/members", server.requireOrgRole("owner"), server.adminAddOrgMember)
	admin.Put("/orgs/:org/members/:user_id", server.requireOrgRole("owner"), server.adminUpdateOrgMember)
	admin.Delete("/orgs/:org/members/:user_id", server.requireOrgRole("owner"), server.adminRemoveOrgMember)
	admin.Get("/orgs/:org/apps", server.requireOrgRole("member"), server.adminListOrgApps)
	admin.Post("/orgs/:org/apps", server.requireOrgRole("owner"), server.adminCreateOrgApp)
	admin.Get("/orgs/:org/apps/:id", server.requireOrgRole("member"), server.adminGetOrgApp)
	admin.Put("/orgs/:org/apps/:id", server.requireOrgRole("owner"), server.adminUpdateOrgApp)
	admin.Delete("/orgs/:org/apps/:id", server.requireOrgRole("owner"), server.adminDeleteOrgApp)
	admin.Get("/orgs/:org/apps/:id/releases", server.requireOrgRole("member"), server.adminListOrgReleases)
	admin.Get("/orgs/:org/apps/:id/patches", server.requireOrgRole("member"), server.adminListOrgPatches)
	admin.Get("/orgs/:org/apps/:id/patches/:patch_number/stats", server.requireOrgRole("member"), server.adminOrgPatchStats)
	admin.Post("/orgs/:org/patches/promote", server.requireOrgRole("owner"), server.promotePatch)
	admin.Post("/orgs/:org/patches/rollback", server.requireOrgRole("owner"), server.rollbackPatch)
	admin.Post("/orgs/:org/cli-tokens", server.requireOrgRole("owner"), server.adminCreateOrgToken)
	admin.Get("/orgs/:org/cli-tokens", server.requireOrgRole("member"), server.adminListOrgTokens)
	admin.Delete("/orgs/:org/cli-tokens/:id", server.requireOrgRole("owner"), server.adminRevokeOrgToken)
	admin.Get("/apps", server.adminListApps)
	admin.Post("/apps", server.adminCreateApp)
	admin.Get("/apps/:id", server.adminGetApp)
	admin.Put("/apps/:id", server.adminUpdateApp)
	admin.Delete("/apps/:id", server.adminDeleteApp)
	admin.Get("/apps/:id/releases", server.adminListReleases)
	admin.Get("/apps/:id/patches", server.adminListPatches)
	admin.Get("/apps/:id/patches/:patch_number/stats", server.adminPatchStats)
	admin.Post("/patches/promote", server.promotePatch)
	admin.Post("/patches/rollback", server.rollbackPatch)
	admin.Post("/tokens", server.adminCreateToken)
	admin.Get("/tokens", server.adminListTokens)
	admin.Delete("/tokens/:id", server.adminRevokeToken)

	app.Post("/v1/apps", server.requireBearer, server.createApp)
	app.Get("/v1/apps/resolve", server.requireBearer, server.resolveApp)
	app.Get("/v1/apps/:id", server.requireBearer, server.getAppByID)
	app.Post("/v1/releases", server.requireBearer, server.createRelease)
	app.Post("/v1/patches", server.requireBearer, server.createPatch)
	app.Post("/v1/patches/promote", server.requireBearer, server.promotePatch)
	app.Post("/v1/patches/rollback", server.requireBearer, server.rollbackPatch)

	app.Get("/v1/patches/check", server.checkPatch)
	app.Get("/v1/patches/manifest", server.patchManifest)
	app.Get("/v1/patches/payload", server.patchPayload)
	app.Post("/v1/events", server.event)
	mountWebUI(app)
	return app
}

func envDefault(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

func eventRetentionDaysFromEnv() int {
	value := envDefault("FCB_EVENT_RETENTION_DAYS", "90")
	days, err := strconv.Atoi(value)
	if err != nil || days <= 0 {
		return 90
	}
	return days
}
