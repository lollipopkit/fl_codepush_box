package main

import (
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"hash/fnv"
	"io"
	"log"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"

	"github.com/gofiber/fiber/v2"
)

type App struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

type ReleaseManifest struct {
	SchemaVersion  int    `json:"schema_version"`
	AppID          string `json:"app_id"`
	ReleaseVersion string `json:"release_version"`
	Channel        string `json:"channel"`
	Platform       string `json:"platform"`
	Arch           string `json:"arch"`
	Backend        string `json:"backend"`
	ArtifactHash   string `json:"artifact_hash"`
	ArtifactSize   uint64 `json:"artifact_size"`
}

type PatchManifest struct {
	SchemaVersion  int             `json:"schema_version"`
	AppID          string          `json:"app_id"`
	ReleaseVersion string          `json:"release_version"`
	PatchNumber    int             `json:"patch_number"`
	Channel        string          `json:"channel"`
	CreatedAt      string          `json:"created_at"`
	Backend        string          `json:"backend"`
	Platform       string          `json:"platform"`
	Arch           string          `json:"arch"`
	Payload        PayloadManifest `json:"payload"`
	Policy         PatchPolicy     `json:"policy"`
	Signature      PatchSignature  `json:"signature"`
	Active         bool            `json:"active"`
	ActiveChannel  string          `json:"active_channel,omitempty"`
	ActiveRollout  int             `json:"active_rollout_percentage,omitempty"`
}

type CreatePatchRequest struct {
	Manifest   PatchManifest `json:"manifest"`
	PayloadB64 string        `json:"payload_b64"`
}

type PatchManifestWire struct {
	SchemaVersion  int             `json:"schema_version"`
	AppID          string          `json:"app_id"`
	ReleaseVersion string          `json:"release_version"`
	PatchNumber    int             `json:"patch_number"`
	Channel        string          `json:"channel"`
	CreatedAt      string          `json:"created_at"`
	Backend        string          `json:"backend"`
	Platform       string          `json:"platform"`
	Arch           string          `json:"arch"`
	Payload        PayloadManifest `json:"payload"`
	Policy         PatchPolicy     `json:"policy"`
	Signature      PatchSignature  `json:"signature"`
}

type PayloadManifest struct {
	Kind          string `json:"kind"`
	Compression   string `json:"compression"`
	Hash          string `json:"hash"`
	Size          uint64 `json:"size"`
	DownloadURL   string `json:"download_url"`
	DiffAlgorithm string `json:"diff_algorithm,omitempty"`
	BaseHash      string `json:"base_hash,omitempty"`
	OutputHash    string `json:"output_hash,omitempty"`
}

type PatchPolicy struct {
	RolloutPercentage int  `json:"rollout_percentage"`
	AllowDowngrade    bool `json:"allow_downgrade"`
}

type PatchSignature struct {
	Algorithm string `json:"algorithm"`
	KeyID     string `json:"key_id"`
	Value     string `json:"value"`
}

type PromotePatchRequest struct {
	AppID             string `json:"app_id"`
	ReleaseVersion    string `json:"release_version"`
	Platform          string `json:"platform"`
	Arch              string `json:"arch"`
	PatchNumber       int    `json:"patch_number"`
	Channel           string `json:"channel"`
	RolloutPercentage int    `json:"rollout_percentage"`
}

type CheckResponse struct {
	PatchAvailable bool        `json:"patch_available"`
	Patch          *PatchCheck `json:"patch,omitempty"`
}

type PatchCheck struct {
	PatchNumber  int    `json:"patch_number"`
	ManifestURL  string `json:"manifest_url"`
	PayloadURL   string `json:"payload_url"`
	ManifestHash string `json:"manifest_hash"`
	PayloadHash  string `json:"payload_hash"`
}

type Store struct {
	Apps     map[string]App             `json:"apps"`
	Releases map[string]ReleaseManifest `json:"releases"`
	Patches  map[string]PatchManifest   `json:"patches"`
}

type Server struct {
	mu         sync.Mutex
	path       string
	objectsDir string
	store      Store
}

func main() {
	dataPath := os.Getenv("FCB_SERVER_STORE")
	if dataPath == "" {
		dataPath = ".fcb/server/store.json"
	}
	server, err := NewServer(dataPath)
	if err != nil {
		log.Fatal(err)
	}
	app := buildApp(server)
	addr := os.Getenv("FCB_SERVER_ADDR")
	if addr == "" {
		addr = "127.0.0.1:8080"
	}
	log.Printf("fcb server listening on %s", addr)
	log.Fatal(app.Listen(addr))
}

func buildApp(server *Server) *fiber.App {
	app := fiber.New()
	app.Post("/v1/apps", server.createApp)
	app.Post("/v1/releases", server.createRelease)
	app.Post("/v1/patches", server.createPatch)
	app.Post("/v1/patches/promote", server.promotePatch)
	app.Post("/v1/patches/rollback", server.rollbackPatch)
	app.Get("/v1/patches/check", server.checkPatch)
	app.Get("/v1/patches/manifest", server.patchManifest)
	app.Get("/v1/patches/payload", server.patchPayload)
	app.Post("/v1/events", server.event)
	return app
}

func NewServer(path string) (*Server, error) {
	s := &Server{path: path, objectsDir: filepath.Join(filepath.Dir(path), "objects"), store: Store{
		Apps:     map[string]App{},
		Releases: map[string]ReleaseManifest{},
		Patches:  map[string]PatchManifest{},
	}}
	if data, err := os.ReadFile(path); err == nil {
		if err := json.Unmarshal(data, &s.store); err != nil {
			return nil, err
		}
	} else if !errors.Is(err, os.ErrNotExist) {
		return nil, err
	}
	return s, nil
}

func (s *Server) createApp(c *fiber.Ctx) error {
	var app App
	if err := c.BodyParser(&app); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	if app.ID == "" {
		return fiber.NewError(fiber.StatusBadRequest, "missing app id")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	s.store.Apps[app.ID] = app
	if err := s.persistLocked(); err != nil {
		return err
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) createRelease(c *fiber.Ctx) error {
	var manifest ReleaseManifest
	if err := c.BodyParser(&manifest); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	if manifest.AppID == "" || manifest.ReleaseVersion == "" || manifest.Platform == "" || manifest.Arch == "" {
		return fiber.NewError(fiber.StatusBadRequest, "release manifest missing required fields")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	s.store.Releases[releaseKey(manifest.AppID, manifest.ReleaseVersion, manifest.Platform, manifest.Arch)] = manifest
	if err := s.persistLocked(); err != nil {
		return err
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) createPatch(c *fiber.Ctx) error {
	var req CreatePatchRequest
	if err := c.BodyParser(&req); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	manifest := req.Manifest
	if manifest.AppID == "" || manifest.ReleaseVersion == "" || manifest.PatchNumber == 0 {
		return fiber.NewError(fiber.StatusBadRequest, "patch manifest missing required fields")
	}
	payload, err := base64.StdEncoding.DecodeString(req.PayloadB64)
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid payload_b64")
	}
	if uint64(len(payload)) != manifest.Payload.Size {
		return fiber.NewError(fiber.StatusBadRequest, "payload size mismatch")
	}
	if sha256Hex(payload) != manifest.Payload.Hash {
		return fiber.NewError(fiber.StatusBadRequest, "payload hash mismatch")
	}
	objectPath, err := s.objectPath(manifest.Payload.DownloadURL)
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}

	s.mu.Lock()
	defer s.mu.Unlock()
	if err := writeFileAtomic(objectPath, payload); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	manifest.Active = false
	manifest.ActiveChannel = manifest.Channel
	manifest.ActiveRollout = manifest.Policy.RolloutPercentage
	s.store.Patches[patchKey(manifest.AppID, manifest.ReleaseVersion, manifest.Platform, manifest.Arch, manifest.PatchNumber)] = manifest
	if err := s.persistLocked(); err != nil {
		return err
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) promotePatch(c *fiber.Ctx) error {
	var req PromotePatchRequest
	if err := c.BodyParser(&req); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	key := patchKey(req.AppID, req.ReleaseVersion, req.Platform, req.Arch, req.PatchNumber)
	patch, ok := s.store.Patches[key]
	if !ok {
		return fiber.NewError(fiber.StatusNotFound, "patch not found")
	}
	patch.Active = true
	patch.ActiveChannel = req.Channel
	patch.ActiveRollout = req.RolloutPercentage
	s.store.Patches[key] = patch
	if err := s.persistLocked(); err != nil {
		return err
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) rollbackPatch(c *fiber.Ctx) error {
	var req PromotePatchRequest
	if err := c.BodyParser(&req); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	key := patchKey(req.AppID, req.ReleaseVersion, req.Platform, req.Arch, req.PatchNumber)
	patch, ok := s.store.Patches[key]
	if !ok {
		return fiber.NewError(fiber.StatusNotFound, "patch not found")
	}
	patch.Active = false
	patch.ActiveRollout = 0
	s.store.Patches[key] = patch
	if err := s.persistLocked(); err != nil {
		return err
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) checkPatch(c *fiber.Ctx) error {
	appID := c.Query("app_id")
	releaseVersion := c.Query("release_version")
	platform := c.Query("platform")
	arch := c.Query("arch")
	channel := c.Query("channel")
	clientID := c.Query("client_id")
	current, _ := strconv.Atoi(c.Query("current_patch_number"))

	s.mu.Lock()
	defer s.mu.Unlock()
	var best *PatchManifest
	for _, patch := range s.store.Patches {
		if patch.AppID != appID || patch.ReleaseVersion != releaseVersion || patch.Platform != platform || patch.Arch != arch {
			continue
		}
		if !patch.Active || activeChannel(patch) != channel || patch.PatchNumber <= current {
			continue
		}
		if !eligible(appID, releaseVersion, patch.PatchNumber, clientID, activeRollout(patch)) {
			continue
		}
		copy := patch
		if best == nil || copy.PatchNumber > best.PatchNumber {
			best = &copy
		}
	}
	if best == nil {
		return c.JSON(CheckResponse{PatchAvailable: false})
	}
	manifestBytes, err := patchManifestBytes(*best)
	if err != nil {
		log.Printf("marshal patch manifest failed: %v", err)
		return fiber.NewError(fiber.StatusInternalServerError, "failed to marshal patch manifest")
	}
	return c.JSON(CheckResponse{
		PatchAvailable: true,
		Patch: &PatchCheck{
			PatchNumber:  best.PatchNumber,
			ManifestURL:  manifestURL(c, appID, releaseVersion, platform, arch, best.PatchNumber),
			PayloadURL:   payloadURL(c, best.Payload.DownloadURL),
			ManifestHash: sha256Hex(manifestBytes),
			PayloadHash:  best.Payload.Hash,
		},
	})
}

func (s *Server) patchPayload(c *fiber.Ctx) error {
	objectPath, err := s.objectPath(c.Query("key"))
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	if _, err := os.Stat(objectPath); err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return fiber.NewError(fiber.StatusNotFound, "payload not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.SendFile(objectPath)
}

func (s *Server) patchManifest(c *fiber.Ctx) error {
	appID := c.Query("app_id")
	releaseVersion := c.Query("release_version")
	platform := c.Query("platform")
	arch := c.Query("arch")
	patchNumber, err := strconv.Atoi(c.Query("patch_number"))
	if err != nil || patchNumber <= 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid patch_number")
	}

	s.mu.Lock()
	defer s.mu.Unlock()
	patch, ok := s.store.Patches[patchKey(appID, releaseVersion, platform, arch, patchNumber)]
	if !ok {
		return fiber.NewError(fiber.StatusNotFound, "patch not found")
	}
	manifestBytes, err := patchManifestBytes(patch)
	if err != nil {
		log.Printf("marshal patch manifest failed: %v", err)
		return fiber.NewError(fiber.StatusInternalServerError, "failed to marshal patch manifest")
	}
	c.Type("json")
	return c.Send(manifestBytes)
}

func (s *Server) event(c *fiber.Ctx) error {
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) objectPath(key string) (string, error) {
	clean := filepath.Clean(key)
	if clean == "." || filepath.IsAbs(clean) || clean != key || clean == ".." || strings.HasPrefix(clean, "../") {
		return "", fmt.Errorf("invalid object key")
	}
	return filepath.Join(s.objectsDir, clean), nil
}

func (s *Server) persistLocked() error {
	if err := os.MkdirAll(filepath.Dir(s.path), 0o755); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	tmp := s.path + ".tmp"
	data, err := json.MarshalIndent(s.store, "", "  ")
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	if err := os.WriteFile(tmp, data, 0o644); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	if err := os.Rename(tmp, s.path); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return nil
}

func patchManifestBytes(patch PatchManifest) ([]byte, error) {
	return json.Marshal(PatchManifestWire{
		SchemaVersion:  patch.SchemaVersion,
		AppID:          patch.AppID,
		ReleaseVersion: patch.ReleaseVersion,
		PatchNumber:    patch.PatchNumber,
		Channel:        patch.Channel,
		CreatedAt:      patch.CreatedAt,
		Backend:        patch.Backend,
		Platform:       patch.Platform,
		Arch:           patch.Arch,
		Payload:        patch.Payload,
		Policy:         patch.Policy,
		Signature:      patch.Signature,
	})
}

func releaseKey(appID, releaseVersion, platform, arch string) string {
	return appID + "|" + releaseVersion + "|" + platform + "|" + arch
}

func patchKey(appID, releaseVersion, platform, arch string, patchNumber int) string {
	return fmt.Sprintf("%s|%s|%s|%s|%d", appID, releaseVersion, platform, arch, patchNumber)
}

func eligible(appID, releaseVersion string, patchNumber int, clientID string, rollout int) bool {
	if rollout <= 0 {
		return false
	}
	if rollout >= 100 {
		return true
	}
	h := fnv.New32a()
	_, _ = h.Write([]byte(fmt.Sprintf("%s%s%d%s", appID, releaseVersion, patchNumber, clientID)))
	return int(h.Sum32()%100) < rollout
}

func activeChannel(patch PatchManifest) string {
	if patch.ActiveChannel != "" {
		return patch.ActiveChannel
	}
	return patch.Channel
}

func activeRollout(patch PatchManifest) int {
	if patch.ActiveRollout != 0 {
		return patch.ActiveRollout
	}
	return patch.Policy.RolloutPercentage
}

func manifestURL(c *fiber.Ctx, appID, releaseVersion, platform, arch string, patchNumber int) string {
	q := url.Values{}
	q.Set("app_id", appID)
	q.Set("release_version", releaseVersion)
	q.Set("platform", platform)
	q.Set("arch", arch)
	q.Set("patch_number", strconv.Itoa(patchNumber))
	return fmt.Sprintf("%s://%s/v1/patches/manifest?%s", c.Protocol(), c.Hostname(), q.Encode())
}

func payloadURL(c *fiber.Ctx, key string) string {
	q := url.Values{}
	q.Set("key", key)
	return fmt.Sprintf("%s://%s/v1/patches/payload?%s", c.Protocol(), c.Hostname(), q.Encode())
}

func writeFileAtomic(path string, data []byte) error {
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	file, err := os.CreateTemp(dir, filepath.Base(path)+".*.tmp")
	if err != nil {
		return err
	}
	tmpName := file.Name()
	cleanup := true
	defer func() {
		if cleanup {
			_ = os.Remove(tmpName)
		}
	}()
	if n, err := file.Write(data); err != nil {
		_ = file.Close()
		return err
	} else if n != len(data) {
		_ = file.Close()
		return io.ErrShortWrite
	}
	if err := file.Sync(); err != nil {
		_ = file.Close()
		return err
	}
	if err := file.Close(); err != nil {
		return err
	}
	if err := os.Chmod(tmpName, 0o644); err != nil {
		return err
	}
	if err := os.Rename(tmpName, path); err != nil {
		return err
	}
	cleanup = false
	return nil
}

func sha256Hex(bytes []byte) string {
	sum := sha256.Sum256(bytes)
	return hex.EncodeToString(sum[:])
}
