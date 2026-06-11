package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"hash/fnv"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"sync"
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
}

type PayloadManifest struct {
	Kind        string `json:"kind"`
	Compression string `json:"compression"`
	Hash        string `json:"hash"`
	Size        uint64 `json:"size"`
	DownloadURL string `json:"download_url"`
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
	mu    sync.Mutex
	path  string
	store Store
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
	mux := http.NewServeMux()
	mux.HandleFunc("POST /v1/apps", server.createApp)
	mux.HandleFunc("POST /v1/releases", server.createRelease)
	mux.HandleFunc("POST /v1/patches", server.createPatch)
	mux.HandleFunc("POST /v1/patches/promote", server.promotePatch)
	mux.HandleFunc("POST /v1/patches/rollback", server.rollbackPatch)
	mux.HandleFunc("GET /v1/patches/check", server.checkPatch)
	mux.HandleFunc("POST /v1/events", server.event)
	addr := os.Getenv("FCB_SERVER_ADDR")
	if addr == "" {
		addr = "127.0.0.1:8080"
	}
	log.Printf("fcb server listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, mux))
}

func NewServer(path string) (*Server, error) {
	s := &Server{path: path, store: Store{
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

func (s *Server) createApp(w http.ResponseWriter, r *http.Request) {
	var app App
	if !decode(w, r, &app) {
		return
	}
	if app.ID == "" {
		http.Error(w, "missing app id", http.StatusBadRequest)
		return
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	s.store.Apps[app.ID] = app
	s.persistLocked(w)
	writeJSON(w, map[string]string{"status": "ok"})
}

func (s *Server) createRelease(w http.ResponseWriter, r *http.Request) {
	var manifest ReleaseManifest
	if !decode(w, r, &manifest) {
		return
	}
	if manifest.AppID == "" || manifest.ReleaseVersion == "" || manifest.Platform == "" || manifest.Arch == "" {
		http.Error(w, "release manifest missing required fields", http.StatusBadRequest)
		return
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	s.store.Releases[releaseKey(manifest.AppID, manifest.ReleaseVersion, manifest.Platform, manifest.Arch)] = manifest
	s.persistLocked(w)
	writeJSON(w, map[string]string{"status": "ok"})
}

func (s *Server) createPatch(w http.ResponseWriter, r *http.Request) {
	var manifest PatchManifest
	if !decode(w, r, &manifest) {
		return
	}
	if manifest.AppID == "" || manifest.ReleaseVersion == "" || manifest.PatchNumber == 0 {
		http.Error(w, "patch manifest missing required fields", http.StatusBadRequest)
		return
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	manifest.Active = false
	s.store.Patches[patchKey(manifest.AppID, manifest.ReleaseVersion, manifest.Platform, manifest.Arch, manifest.PatchNumber)] = manifest
	s.persistLocked(w)
	writeJSON(w, map[string]string{"status": "ok"})
}

func (s *Server) promotePatch(w http.ResponseWriter, r *http.Request) {
	var req PromotePatchRequest
	if !decode(w, r, &req) {
		return
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	key := patchKey(req.AppID, req.ReleaseVersion, req.Platform, req.Arch, req.PatchNumber)
	patch, ok := s.store.Patches[key]
	if !ok {
		http.Error(w, "patch not found", http.StatusNotFound)
		return
	}
	patch.Active = true
	patch.Channel = req.Channel
	patch.Policy.RolloutPercentage = req.RolloutPercentage
	s.store.Patches[key] = patch
	s.persistLocked(w)
	writeJSON(w, map[string]string{"status": "ok"})
}

func (s *Server) rollbackPatch(w http.ResponseWriter, r *http.Request) {
	var req PromotePatchRequest
	if !decode(w, r, &req) {
		return
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	key := patchKey(req.AppID, req.ReleaseVersion, req.Platform, req.Arch, req.PatchNumber)
	patch, ok := s.store.Patches[key]
	if !ok {
		http.Error(w, "patch not found", http.StatusNotFound)
		return
	}
	patch.Active = false
	patch.Policy.RolloutPercentage = 0
	s.store.Patches[key] = patch
	s.persistLocked(w)
	writeJSON(w, map[string]string{"status": "ok"})
}

func (s *Server) checkPatch(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	appID := q.Get("app_id")
	releaseVersion := q.Get("release_version")
	platform := q.Get("platform")
	arch := q.Get("arch")
	channel := q.Get("channel")
	clientID := q.Get("client_id")
	current, _ := strconv.Atoi(q.Get("current_patch_number"))

	s.mu.Lock()
	defer s.mu.Unlock()
	var best *PatchManifest
	for _, patch := range s.store.Patches {
		if patch.AppID != appID || patch.ReleaseVersion != releaseVersion || patch.Platform != platform || patch.Arch != arch {
			continue
		}
		if !patch.Active || patch.Channel != channel || patch.PatchNumber <= current {
			continue
		}
		if !eligible(appID, releaseVersion, patch.PatchNumber, clientID, patch.Policy.RolloutPercentage) {
			continue
		}
		copy := patch
		if best == nil || copy.PatchNumber > best.PatchNumber {
			best = &copy
		}
	}
	if best == nil {
		writeJSON(w, CheckResponse{PatchAvailable: false})
		return
	}
	manifestBytes, err := json.Marshal(best)
	if err != nil {
		log.Printf("marshal patch manifest failed: %v", err)
		http.Error(w, "failed to marshal patch manifest", http.StatusInternalServerError)
		return
	}
	writeJSON(w, CheckResponse{
		PatchAvailable: true,
		Patch: &PatchCheck{
			PatchNumber:  best.PatchNumber,
			ManifestURL:  fmt.Sprintf("server://patches/%s/%s/%s/%s/%d/patch_manifest.json", appID, releaseVersion, platform, arch, best.PatchNumber),
			PayloadURL:   best.Payload.DownloadURL,
			ManifestHash: sha256Hex(manifestBytes),
			PayloadHash:  best.Payload.Hash,
		},
	})
}

func (s *Server) event(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, map[string]string{"status": "ok"})
}

func (s *Server) persistLocked(w http.ResponseWriter) bool {
	if err := os.MkdirAll(filepath.Dir(s.path), 0o755); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return false
	}
	tmp := s.path + ".tmp"
	data, err := json.MarshalIndent(s.store, "", "  ")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return false
	}
	if err := os.WriteFile(tmp, data, 0o644); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return false
	}
	if err := os.Rename(tmp, s.path); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return false
	}
	return true
}

func decode(w http.ResponseWriter, r *http.Request, out any) bool {
	defer r.Body.Close()
	if err := json.NewDecoder(r.Body).Decode(out); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return false
	}
	return true
}

func writeJSON(w http.ResponseWriter, value any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(value)
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

func sha256Hex(bytes []byte) string {
	sum := sha256.Sum256(bytes)
	return hex.EncodeToString(sum[:])
}
