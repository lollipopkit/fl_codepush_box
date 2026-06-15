package main

import (
	"database/sql"
	"flag"
	"log"
	"os"
	"path/filepath"

	"github.com/glebarez/sqlite"
	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

type Server struct {
	db         *sql.DB
	gormDB     *gorm.DB
	objectsDir string
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
	if err := os.MkdirAll(objectsDir, 0o755); err != nil {
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
	server := &Server{db: db, gormDB: gormDB, objectsDir: objectsDir}
	if err := server.migrate(); err != nil {
		_ = db.Close()
		return nil, err
	}
	return server, nil
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
	app.Get("/api/auth/setup-status", server.setupStatus)
	app.Post("/api/auth/setup", server.setup)
	app.Post("/api/auth/login", server.login)
	app.Post("/api/auth/logout", server.logout)
	app.Get("/api/auth/me", server.requireSession, server.me)

	admin := app.Group("/api/admin", server.requireSession)
	admin.Get("/apps", server.adminListApps)
	admin.Post("/apps", server.adminCreateApp)
	admin.Get("/apps/:id", server.adminGetApp)
	admin.Put("/apps/:id", server.adminUpdateApp)
	admin.Delete("/apps/:id", server.adminDeleteApp)
	admin.Get("/apps/:id/releases", server.adminListReleases)
	admin.Get("/apps/:id/patches", server.adminListPatches)
	admin.Post("/patches/promote", server.promotePatch)
	admin.Post("/patches/rollback", server.rollbackPatch)
	admin.Post("/tokens", server.adminCreateToken)
	admin.Get("/tokens", server.adminListTokens)
	admin.Delete("/tokens/:id", server.adminRevokeToken)

	app.Post("/v1/apps", server.requireBearer, server.createApp)
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
