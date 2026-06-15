package main

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestEligibleIsStable(t *testing.T) {
	first := eligible("app", "1.0.0+1", 7, "client", 25)
	for range 20 {
		if got := eligible("app", "1.0.0+1", 7, "client", 25); got != first {
			t.Fatalf("eligible changed for stable inputs: first=%v got=%v", first, got)
		}
	}
	if !eligible("app", "1.0.0+1", 7, "client", 100) {
		t.Fatal("100% rollout should always be eligible")
	}
	if eligible("app", "1.0.0+1", 7, "client", 0) {
		t.Fatal("0% rollout should never be eligible")
	}
}

func TestObjectPathRejectsTraversal(t *testing.T) {
	server, err := NewServer(filepath.Join(t.TempDir(), "store.json"))
	if err != nil {
		t.Fatal(err)
	}
	for _, key := range []string{"../payload.bin", "/tmp/payload.bin", "patches/../payload.bin"} {
		if _, err := server.objectPath(key); err == nil {
			t.Fatalf("objectPath accepted invalid key %q", key)
		}
	}
	if path, err := server.objectPath("patches/app/release/payload.bin"); err != nil || !strings.Contains(path, "objects") {
		t.Fatalf("objectPath rejected valid key: path=%q err=%v", path, err)
	}
	app := buildApp(server)
	req := httptest.NewRequest(http.MethodGet, "/v1/patches/payload?key=%2e%2e%2fpayload.bin", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusOK {
		t.Fatal("/v1/patches/payload accepted URL-encoded traversal key")
	}
}

func TestCreatePatchStoresPayloadAndCheckReturnsDownloadURLs(t *testing.T) {
	tempDir := t.TempDir()
	server, err := NewServer(filepath.Join(tempDir, "store.json"))
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	token := mustToken(t, server)
	app := buildApp(server)
	payload := []byte("payload")
	manifest := PatchManifest{
		SchemaVersion:  1,
		AppID:          "00000000-0000-0000-0000-000000000001",
		ReleaseVersion: "1.0.0+1",
		PatchNumber:    1,
		Channel:        "stable",
		CreatedAt:      "1970-01-01T00:00:00Z",
		Backend:        "snapshot_replace",
		Platform:       "android",
		Arch:           "arm64-v8a",
		Payload: PayloadManifest{
			Kind:        "opaque_payload",
			Compression: "none",
			Hash:        sha256Hex(payload),
			Size:        uint64(len(payload)),
			DownloadURL: patchPayloadKey("00000000-0000-0000-0000-000000000001", "1.0.0+1", "android", "arm64-v8a", 1),
		},
		Policy: PatchPolicy{
			RolloutPercentage: 0,
			AllowDowngrade:    false,
		},
		Signature: PatchSignature{
			Algorithm: "ed25519",
			KeyID:     "dev",
			Value:     "signature",
		},
	}
	createPatch := CreatePatchRequest{
		Manifest:   manifest,
		PayloadB64: base64.StdEncoding.EncodeToString(payload),
	}
	doJSONAuth(t, app, http.MethodPost, "/v1/patches", createPatch, token, http.StatusOK)
	if _, err := os.Stat(filepath.Join(tempDir, "objects", manifest.Payload.DownloadURL)); err != nil {
		t.Fatalf("payload object was not written: %v", err)
	}

	promote := PromotePatchRequest{
		AppID:             manifest.AppID,
		ReleaseVersion:    manifest.ReleaseVersion,
		Platform:          manifest.Platform,
		Arch:              manifest.Arch,
		PatchNumber:       manifest.PatchNumber,
		Channel:           "stable",
		RolloutPercentage: 100,
	}
	doJSONAuth(t, app, http.MethodPost, "/v1/patches/promote", promote, token, http.StatusOK)
	req := httptest.NewRequest(
		http.MethodGet,
		"/v1/patches/check?app_id="+manifest.AppID+"&release_version=1.0.0%2B1&platform=android&arch=arm64-v8a&channel=stable&current_patch_number=0&client_id=test",
		nil,
	)
	req.Host = "updates.local:9090"
	resp, err := app.Test(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("check returned HTTP %d", resp.StatusCode)
	}
	var check CheckResponse
	if err := json.NewDecoder(resp.Body).Decode(&check); err != nil {
		t.Fatal(err)
	}
	if !check.PatchAvailable || check.Patch == nil {
		t.Fatalf("expected patch to be available: %+v", check)
	}
	if !strings.Contains(check.Patch.PayloadURL, "/v1/patches/payload?") {
		t.Fatalf("payload URL should point at server payload endpoint: %q", check.Patch.PayloadURL)
	}
	if !strings.Contains(check.Patch.ManifestURL, "/v1/patches/manifest?") {
		t.Fatalf("manifest URL should point at server manifest endpoint: %q", check.Patch.ManifestURL)
	}
	if !strings.Contains(check.Patch.PayloadURL, "updates.local:9090") || !strings.Contains(check.Patch.ManifestURL, "updates.local:9090") {
		t.Fatalf("download URLs should preserve host port: %+v", check.Patch)
	}
}

func TestResolveAppByIDOrName(t *testing.T) {
	server, err := NewServer(filepath.Join(t.TempDir(), "store.json"))
	if err != nil {
		t.Fatal(err)
	}
	token := mustToken(t, server)
	app := buildApp(server)

	doJSONAuth(t, app, http.MethodPost, "/v1/apps", App{ID: "app-a", Name: "Counter"}, token, http.StatusOK)
	doJSONAuth(t, app, http.MethodPost, "/v1/apps", App{ID: "app-b", Name: "Other"}, token, http.StatusOK)

	for _, path := range []string{"/v1/apps/resolve?app=app-a", "/v1/apps/resolve?app=Counter"} {
		req := httptest.NewRequest(http.MethodGet, path, nil)
		req.Header.Set("Authorization", "Bearer "+token)
		resp, err := app.Test(req)
		if err != nil {
			t.Fatal(err)
		}
		defer resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			body, _ := io.ReadAll(resp.Body)
			t.Fatalf("%s returned HTTP %d: %s", path, resp.StatusCode, string(body))
		}
		var resolved App
		if err := json.NewDecoder(resp.Body).Decode(&resolved); err != nil {
			t.Fatal(err)
		}
		if resolved.ID != "app-a" {
			t.Fatalf("%s resolved %q, want app-a", path, resolved.ID)
		}
	}

	doJSONAuth(t, app, http.MethodPost, "/v1/apps", App{ID: "app-c", Name: "Counter"}, token, http.StatusOK)
	req := httptest.NewRequest(http.MethodGet, "/v1/apps/resolve?app=Counter", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusConflict {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("ambiguous name returned HTTP %d, want 409: %s", resp.StatusCode, string(body))
	}

	req = httptest.NewRequest(http.MethodGet, "/v1/apps/resolve?app=missing", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err = app.Test(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNotFound {
		t.Fatalf("missing app returned HTTP %d, want 404", resp.StatusCode)
	}
}

func doJSON(t *testing.T, app interface {
	Test(*http.Request, ...int) (*http.Response, error)
}, method, path string, value any, want int) {
	doJSONAuth(t, app, method, path, value, "", want)
}

func doJSONAuth(t *testing.T, app interface {
	Test(*http.Request, ...int) (*http.Response, error)
}, method, path string, value any, token string, want int) {
	t.Helper()
	body, err := json.Marshal(value)
	if err != nil {
		t.Fatal(err)
	}
	req := httptest.NewRequest(method, path, bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	resp, err := app.Test(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != want {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("%s %s returned HTTP %d, want %d: %s", method, path, resp.StatusCode, want, string(body))
	}
}

func mustToken(t *testing.T, server *Server) string {
	t.Helper()
	token, err := server.createToken("test")
	if err != nil {
		t.Fatal(err)
	}
	return token.Token
}
