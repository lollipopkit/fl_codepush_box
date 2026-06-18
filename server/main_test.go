package main

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
)

func TestEligibleIsStable(t *testing.T) {
	first := eligible("app", "1.0.0+1", "client", 25)
	for range 20 {
		if got := eligible("app", "1.0.0+1", "client", 25); got != first {
			t.Fatalf("eligible changed for stable inputs: first=%v got=%v", first, got)
		}
	}
	if !eligible("app", "1.0.0+1", "client", 100) {
		t.Fatal("100% rollout should always be eligible")
	}
	if eligible("app", "1.0.0+1", "client", 0) {
		t.Fatal("0% rollout should never be eligible")
	}
}

func TestEligibleIsMonotonicAndReleaseScoped(t *testing.T) {
	for i := range 1000 {
		clientID := "client-" + strconv.Itoa(i)
		if eligible("app", "1.0.0+1", clientID, 10) && !eligible("app", "1.0.0+1", clientID, 30) {
			t.Fatalf("10%% cohort was not included in 30%% rollout for %s", clientID)
		}
	}
	if cohort("app", "1.0.0+1", "client") != cohort("app", "1.0.0+1", "client") {
		t.Fatal("cohort must be stable")
	}
	if cohort("app", "1.0.0+1", "client") == cohort("app", "1.0.1+2", "client") {
		t.Fatal("cohort should reset for different release versions")
	}
}

func TestBestPatchUsesReleaseScopedCohortAcrossPatches(t *testing.T) {
	server, err := NewServer(filepath.Join(t.TempDir(), "store.json"))
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	if err := server.putApp(App{ID: "rollout-app", Name: "Rollout"}); err != nil {
		t.Fatal(err)
	}
	clientID := firstEligibleClient(t, "rollout-app", "1.0.0+1", 10)
	for _, patchNumber := range []int{1, 2} {
		patch := testPatchManifest("rollout-app", "1.0.0+1", patchNumber)
		patch.Active = true
		patch.ActiveChannel = "stable"
		patch.ActiveRollout = 10
		if err := server.putPatch(patch); err != nil {
			t.Fatal(err)
		}
	}

	best, err := server.bestPatch("rollout-app", "1.0.0+1", "android", "arm64-v8a", "stable", clientID, 0)
	if err != nil {
		t.Fatal(err)
	}
	if best == nil || best.PatchNumber != 2 {
		t.Fatalf("expected latest eligible patch 2, got %+v", best)
	}
}

func TestActiveRolloutZeroBlocksActivePatch(t *testing.T) {
	server, err := NewServer(filepath.Join(t.TempDir(), "store.json"))
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	if err := server.putApp(App{ID: "zero-rollout-app", Name: "Zero Rollout"}); err != nil {
		t.Fatal(err)
	}
	patch := testPatchManifest("zero-rollout-app", "1.0.0+1", 1)
	patch.Policy.RolloutPercentage = 100
	patch.Active = true
	patch.ActiveChannel = "stable"
	patch.ActiveRollout = 0
	if err := server.putPatch(patch); err != nil {
		t.Fatal(err)
	}

	best, err := server.bestPatch("zero-rollout-app", "1.0.0+1", "android", "arm64-v8a", "stable", "client", 0)
	if err != nil {
		t.Fatal(err)
	}
	if best != nil {
		t.Fatalf("0%% active rollout should not serve patch, got %+v", best)
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

func TestLocalFSStoragePutGetSignedURLAndDelete(t *testing.T) {
	storage, err := NewLocalFSStorage(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	if err := storage.Put(nil, "patches/app/payload.bin", strings.NewReader("payload"), 7); err != nil {
		t.Fatal(err)
	}
	reader, size, err := storage.Get(nil, "patches/app/payload.bin")
	if err != nil {
		t.Fatal(err)
	}
	data, _ := io.ReadAll(reader)
	_ = reader.Close()
	if size != 7 || string(data) != "payload" {
		t.Fatalf("unexpected storage read: size=%d data=%q", size, string(data))
	}
	signed, err := storage.SignedURL(nil, "patches/app/payload.bin", 0)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(signed, "/v1/patches/payload?") {
		t.Fatalf("unexpected signed URL: %s", signed)
	}
	if err := storage.Delete(nil, "patches/app/payload.bin"); err != nil {
		t.Fatal(err)
	}
	if _, _, err := storage.Get(nil, "patches/app/payload.bin"); !os.IsNotExist(err) {
		t.Fatalf("expected deleted object to be missing, got %v", err)
	}
}

func TestS3StorageConfigAndSignedURL(t *testing.T) {
	if _, err := NewS3Storage(t.Context(), S3StorageConfig{}); err == nil {
		t.Fatal("NewS3Storage accepted missing bucket")
	}
	storage, err := NewS3Storage(t.Context(), S3StorageConfig{
		Bucket:          "fcb-test",
		Region:          "us-east-1",
		Endpoint:        "http://127.0.0.1:9000",
		AccessKeyID:     "test-access-key",
		SecretAccessKey: "test-secret-key",
	})
	if err != nil {
		t.Fatal(err)
	}
	signed, err := storage.SignedURL(t.Context(), "patches/app/payload.bin", 0)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(signed, "http://127.0.0.1:9000/fcb-test/patches/app/payload.bin?") {
		t.Fatalf("unexpected S3 signed URL: %s", signed)
	}
	if !strings.Contains(signed, "X-Amz-Signature=") {
		t.Fatalf("S3 signed URL is missing signature: %s", signed)
	}
}

func TestHealthzAndMetrics(t *testing.T) {
	server, err := NewServer(filepath.Join(t.TempDir(), "store.json"))
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	app := buildApp(server)

	resp, err := app.Test(httptest.NewRequest(http.MethodGet, "/healthz", nil))
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("healthz returned HTTP %d", resp.StatusCode)
	}

	doJSON(t, app, http.MethodPost, "/v1/events", map[string]any{
		"app_id":          "metrics-app",
		"release_version": "1.0.0+1",
		"platform":        "android",
		"arch":            "arm64-v8a",
		"patch_number":    1,
		"event_type":      "install",
	}, http.StatusOK)
	checkReq := httptest.NewRequest(http.MethodGet, "/v1/patches/check?app_id=metrics-app&release_version=1.0.0%2B1&platform=android&arch=arm64-v8a&channel=stable&current_patch_number=0&client_id=test", nil)
	checkResp, err := app.Test(checkReq)
	if err != nil {
		t.Fatal(err)
	}
	_ = checkResp.Body.Close()

	metricsResp, err := app.Test(httptest.NewRequest(http.MethodGet, "/metrics", nil))
	if err != nil {
		t.Fatal(err)
	}
	defer metricsResp.Body.Close()
	body, _ := io.ReadAll(metricsResp.Body)
	text := string(body)
	if !strings.Contains(text, "fcb_patch_check_requests_total 1") {
		t.Fatalf("metrics missing patch check count: %s", text)
	}
	if !strings.Contains(text, "fcb_patch_event_writes_total 1") {
		t.Fatalf("metrics missing event write count: %s", text)
	}
}

func TestCrashRollbackEventPersistsPayload(t *testing.T) {
	server, err := NewServer(filepath.Join(t.TempDir(), "store.json"))
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	app := buildApp(server)

	doJSON(t, app, http.MethodPost, "/v1/events", map[string]any{
		"app_id":          "rollback-app",
		"release_version": "1.0.0+1",
		"platform":        "android",
		"arch":            "arm64-v8a",
		"patch_number":    11,
		"event_type":      "crash_rollback",
		"client_id_hash":  "client-hash",
		"payload": map[string]any{
			"patch_number":                 11,
			"boot_attempts":                3,
			"last_known_good_patch_number": 7,
			"event_type":                   "crash_rollback",
		},
	}, http.StatusOK)

	var appID, eventType, clientIDHash, payloadJSON string
	var patchNumber int
	if err := server.db.QueryRow(
		`select app_id, patch_number, event_type, client_id_hash, payload from patch_events where app_id = ?`,
		"rollback-app",
	).Scan(&appID, &patchNumber, &eventType, &clientIDHash, &payloadJSON); err != nil {
		t.Fatal(err)
	}
	if appID != "rollback-app" || patchNumber != 11 || eventType != "crash_rollback" || clientIDHash != "client-hash" {
		t.Fatalf("unexpected event row: app=%s patch=%d type=%s client=%s", appID, patchNumber, eventType, clientIDHash)
	}
	var payload map[string]any
	if err := json.Unmarshal([]byte(payloadJSON), &payload); err != nil {
		t.Fatal(err)
	}
	if payload["event_type"] != "crash_rollback" ||
		payload["patch_number"].(float64) != 11 ||
		payload["boot_attempts"].(float64) != 3 ||
		payload["last_known_good_patch_number"].(float64) != 7 {
		t.Fatalf("unexpected rollback payload: %s", payloadJSON)
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
	payloadURL, err := url.Parse(check.Patch.PayloadURL)
	if err != nil {
		t.Fatal(err)
	}
	payloadReq := httptest.NewRequest(http.MethodGet, payloadURL.RequestURI(), nil)
	payloadReq.Host = payloadURL.Host
	payloadResp, err := app.Test(payloadReq)
	if err != nil {
		t.Fatal(err)
	}
	defer payloadResp.Body.Close()
	if payloadResp.StatusCode != http.StatusOK {
		t.Fatalf("payload returned HTTP %d", payloadResp.StatusCode)
	}
	gotPayload, err := io.ReadAll(payloadResp.Body)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(gotPayload, payload) {
		t.Fatalf("unexpected payload body: %q", string(gotPayload))
	}
}

func TestOrgScopedPatchPayloadKeysDoNotCollide(t *testing.T) {
	tempDir := t.TempDir()
	server, err := NewServer(filepath.Join(tempDir, "store.json"))
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	app := buildApp(server)
	session := mustSessionCookie(t, app)

	for _, org := range []Organization{{ID: "acme", Name: "Acme"}, {ID: "widgets", Name: "Widgets"}} {
		doJSONWithCookie(t, app, http.MethodPost, "/api/admin/orgs", org, session, http.StatusOK)
	}

	acmeToken := createOrgTokenViaAdmin(t, app, session, "acme")
	widgetsToken := createOrgTokenViaAdmin(t, app, session, "widgets")
	for _, token := range []string{acmeToken, widgetsToken} {
		doJSONAuth(t, app, http.MethodPost, "/v1/apps", App{ID: "shared-app", Name: "Shared"}, token, http.StatusOK)
		doJSONAuth(t, app, http.MethodPost, "/v1/releases", ReleaseManifest{
			SchemaVersion:  1,
			AppID:          "shared-app",
			ReleaseVersion: "1.0.0+1",
			Channel:        "stable",
			Platform:       "android",
			Arch:           "arm64-v8a",
			Backend:        "bytecode",
			ArtifactHash:   "artifact",
			ArtifactSize:   1,
		}, token, http.StatusOK)
	}

	legacyKey := patchPayloadKey("shared-app", "1.0.0+1", "android", "arm64-v8a", 1)
	for _, tc := range []struct {
		token   string
		payload []byte
	}{
		{token: acmeToken, payload: []byte("acme-payload")},
		{token: widgetsToken, payload: []byte("widgets-payload")},
	} {
		manifest := PatchManifest{
			SchemaVersion:  1,
			AppID:          "shared-app",
			ReleaseVersion: "1.0.0+1",
			PatchNumber:    1,
			Channel:        "stable",
			CreatedAt:      "1970-01-01T00:00:00Z",
			Backend:        "bytecode",
			Platform:       "android",
			Arch:           "arm64-v8a",
			Payload: PayloadManifest{
				Kind:        "opaque_payload",
				Compression: "none",
				Hash:        sha256Hex(tc.payload),
				Size:        uint64(len(tc.payload)),
				DownloadURL: legacyKey,
			},
			Policy: PatchPolicy{
				RolloutPercentage: 100,
				AllowDowngrade:    false,
			},
			Signature: PatchSignature{
				Algorithm: "ed25519",
				KeyID:     "dev",
				Value:     "signature",
			},
		}
		doJSONAuth(t, app, http.MethodPost, "/v1/patches", CreatePatchRequest{
			Manifest:   manifest,
			PayloadB64: base64.StdEncoding.EncodeToString(tc.payload),
		}, tc.token, http.StatusOK)
	}

	for _, tc := range []struct {
		orgID string
		want  []byte
	}{
		{orgID: "acme", want: []byte("acme-payload")},
		{orgID: "widgets", want: []byte("widgets-payload")},
	} {
		storageKey := orgScopedPayloadKey(tc.orgID, legacyKey)
		got, err := os.ReadFile(filepath.Join(tempDir, "objects", storageKey))
		if err != nil {
			t.Fatalf("missing payload for %s at %s: %v", tc.orgID, storageKey, err)
		}
		if !bytes.Equal(got, tc.want) {
			t.Fatalf("unexpected payload for %s: %q", tc.orgID, string(got))
		}
		patch, err := server.getPatchInOrg(tc.orgID, "shared-app", "1.0.0+1", "android", "arm64-v8a", 1)
		if err != nil {
			t.Fatal(err)
		}
		if patch.Payload.DownloadURL != storageKey {
			t.Fatalf("unexpected stored payload key for %s: %s", tc.orgID, patch.Payload.DownloadURL)
		}
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

func TestOrgScopedAppsAndTokens(t *testing.T) {
	server, err := NewServer(filepath.Join(t.TempDir(), "store.json"))
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	app := buildApp(server)
	session := mustSessionCookie(t, app)

	for _, org := range []Organization{{ID: "acme", Name: "Acme"}, {ID: "widgets", Name: "Widgets"}} {
		req := httptest.NewRequest(http.MethodPost, "/api/admin/orgs", mustJSONReader(t, org))
		req.Header.Set("Content-Type", "application/json")
		req.AddCookie(session)
		resp, err := app.Test(req)
		if err != nil {
			t.Fatal(err)
		}
		_ = resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			t.Fatalf("create org %s returned HTTP %d", org.ID, resp.StatusCode)
		}
	}

	acmeToken := createOrgTokenViaAdmin(t, app, session, "acme")
	widgetsToken := createOrgTokenViaAdmin(t, app, session, "widgets")
	doJSONAuth(t, app, http.MethodPost, "/v1/apps", App{ID: "acme-app", Name: "Acme App"}, acmeToken, http.StatusOK)
	doJSONAuth(t, app, http.MethodPost, "/v1/apps", App{ID: "widgets-app", Name: "Widgets App"}, widgetsToken, http.StatusOK)
	doJSONAuth(t, app, http.MethodPost, "/v1/apps", App{ID: "shared-app", Name: "Acme Shared"}, acmeToken, http.StatusOK)
	doJSONAuth(t, app, http.MethodPost, "/v1/apps", App{ID: "shared-app", Name: "Widgets Shared"}, widgetsToken, http.StatusOK)

	for _, tc := range []struct {
		token string
		path  string
		want  int
	}{
		{token: acmeToken, path: "/v1/apps/acme-app", want: http.StatusOK},
		{token: acmeToken, path: "/v1/apps/widgets-app", want: http.StatusNotFound},
		{token: widgetsToken, path: "/v1/apps/widgets-app", want: http.StatusOK},
		{token: widgetsToken, path: "/v1/apps/acme-app", want: http.StatusNotFound},
	} {
		req := httptest.NewRequest(http.MethodGet, tc.path, nil)
		req.Header.Set("Authorization", "Bearer "+tc.token)
		resp, err := app.Test(req)
		if err != nil {
			t.Fatal(err)
		}
		_ = resp.Body.Close()
		if resp.StatusCode != tc.want {
			t.Fatalf("%s returned HTTP %d, want %d", tc.path, resp.StatusCode, tc.want)
		}
	}
	for _, tc := range []struct {
		token string
		name  string
		orgID string
	}{
		{token: acmeToken, name: "Acme Shared", orgID: "acme"},
		{token: widgetsToken, name: "Widgets Shared", orgID: "widgets"},
	} {
		req := httptest.NewRequest(http.MethodGet, "/v1/apps/shared-app", nil)
		req.Header.Set("Authorization", "Bearer "+tc.token)
		resp, err := app.Test(req)
		if err != nil {
			t.Fatal(err)
		}
		var got App
		if err := json.NewDecoder(resp.Body).Decode(&got); err != nil {
			_ = resp.Body.Close()
			t.Fatal(err)
		}
		_ = resp.Body.Close()
		if got.ID != "shared-app" || got.Name != tc.name || got.OrgID != tc.orgID {
			t.Fatalf("unexpected shared app for %s: %+v", tc.orgID, got)
		}
	}
	for _, event := range []map[string]any{
		{"org_id": "acme", "app_id": "shared-app", "release_version": "1.0.0+1", "platform": "android", "arch": "arm64-v8a", "patch_number": 1, "event_type": "install"},
		{"org_id": "widgets", "app_id": "shared-app", "release_version": "1.0.0+1", "platform": "android", "arch": "arm64-v8a", "patch_number": 1, "event_type": "launch_failure", "payload": map[string]any{"error_message": "widgets-only"}},
	} {
		doJSON(t, app, http.MethodPost, "/v1/events", event, http.StatusOK)
	}
	for _, tc := range []struct {
		orgID       string
		wantInstall int
		wantFailure int
	}{
		{orgID: "acme", wantInstall: 1, wantFailure: 0},
		{orgID: "widgets", wantInstall: 0, wantFailure: 1},
	} {
		req := httptest.NewRequest(http.MethodGet, "/api/admin/orgs/"+tc.orgID+"/apps/shared-app/patches/1/stats?release_version=1.0.0%2B1&platform=android&arch=arm64-v8a", nil)
		req.AddCookie(session)
		resp, err := app.Test(req)
		if err != nil {
			t.Fatal(err)
		}
		var stats PatchStatsResponse
		if err := json.NewDecoder(resp.Body).Decode(&stats); err != nil {
			_ = resp.Body.Close()
			t.Fatal(err)
		}
		_ = resp.Body.Close()
		if stats.Totals["install"] != tc.wantInstall || stats.Totals["launch_failure"] != tc.wantFailure {
			t.Fatalf("unexpected stats for %s: %+v", tc.orgID, stats.Totals)
		}
	}

	req := httptest.NewRequest(http.MethodGet, "/api/admin/orgs/acme/apps", nil)
	req.AddCookie(session)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("list acme apps returned HTTP %d", resp.StatusCode)
	}
	var apps []App
	if err := json.NewDecoder(resp.Body).Decode(&apps); err != nil {
		t.Fatal(err)
	}
	acmeAppIDs := map[string]bool{}
	for _, app := range apps {
		if app.OrgID != "acme" {
			t.Fatalf("unexpected non-acme app in acme list: %+v", apps)
		}
		acmeAppIDs[app.ID] = true
	}
	if len(apps) != 2 || !acmeAppIDs["acme-app"] || !acmeAppIDs["shared-app"] {
		t.Fatalf("unexpected acme apps: %+v", apps)
	}

	readerSession := createSessionForTestUser(t, server, "reader")
	doJSONWithCookie(t, app, http.MethodPost, "/api/admin/orgs/acme/members", OrgMemberRequest{Username: "reader", Role: "member"}, session, http.StatusOK)

	req = httptest.NewRequest(http.MethodGet, "/api/admin/orgs/acme/apps", nil)
	req.AddCookie(readerSession)
	resp, err = app.Test(req)
	if err != nil {
		t.Fatal(err)
	}
	_ = resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("member read returned HTTP %d", resp.StatusCode)
	}

	doJSONWithCookie(t, app, http.MethodPost, "/api/admin/orgs/acme/apps", App{ID: "blocked"}, readerSession, http.StatusNotFound)
	doJSONWithCookie(t, app, http.MethodPost, "/api/admin/orgs/acme/cli-tokens", TokenRequest{Name: "blocked"}, readerSession, http.StatusNotFound)

	readerID := userIDForTestUser(t, server, "reader")
	doJSONWithCookie(t, app, http.MethodPut, "/api/admin/orgs/acme/members/"+strconv.FormatInt(readerID, 10), OrgMemberUpdateRequest{Role: "owner"}, session, http.StatusOK)
	doJSONWithCookie(t, app, http.MethodPost, "/api/admin/orgs/acme/apps", App{ID: "reader-created"}, readerSession, http.StatusOK)
	doJSONWithCookie(t, app, http.MethodDelete, "/api/admin/orgs/acme/members/"+strconv.FormatInt(readerID, 10), map[string]any{}, session, http.StatusOK)
	doJSONWithCookie(t, app, http.MethodGet, "/api/admin/orgs/acme/apps", map[string]any{}, readerSession, http.StatusNotFound)

	adminID := userIDForTestUser(t, server, "admin")
	doJSONWithCookie(t, app, http.MethodDelete, "/api/admin/orgs/widgets/members/"+strconv.FormatInt(adminID, 10), map[string]any{}, session, http.StatusBadRequest)
}

func TestPatchStatsAggregatesEvents(t *testing.T) {
	server, err := NewServer(filepath.Join(t.TempDir(), "store.json"))
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	app := buildApp(server)
	session := mustSessionCookie(t, app)
	if err := server.putApp(App{ID: "app-stats", Name: "Stats"}); err != nil {
		t.Fatal(err)
	}
	events := []map[string]any{
		{"app_id": "app-stats", "release_version": "1.0.0+1", "platform": "android", "arch": "arm64-v8a", "patch_number": 2, "event_type": "install", "client_id_hash": "a"},
		{"app_id": "app-stats", "release_version": "1.0.0+1", "platform": "android", "arch": "arm64-v8a", "patch_number": 2, "event_type": "launch_success", "client_id_hash": "a"},
		{"app_id": "app-stats", "release_version": "1.0.0+1", "platform": "android", "arch": "arm64-v8a", "patch_number": 2, "event_type": "launch_failure", "client_id_hash": "b", "payload": map[string]any{"error_message": "boom"}},
		{"app_id": "app-stats", "release_version": "1.0.0+1", "platform": "android", "arch": "arm64-v8a", "patch_number": 2, "event_type": "crash_rollback", "client_id_hash": "c", "payload": map[string]any{"last_error": "boom"}},
		{"app_id": "app-stats", "release_version": "1.0.0+1", "platform": "ios", "arch": "arm64", "patch_number": 2, "event_type": "install", "client_id_hash": "ios"},
	}
	for _, event := range events {
		doJSON(t, app, http.MethodPost, "/v1/events", event, http.StatusOK)
	}

	req := httptest.NewRequest(http.MethodGet, "/api/admin/apps/app-stats/patches/2/stats?release_version=1.0.0%2B1&platform=android&arch=arm64-v8a", nil)
	req.AddCookie(session)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("stats returned HTTP %d: %s", resp.StatusCode, string(body))
	}
	var stats PatchStatsResponse
	if err := json.NewDecoder(resp.Body).Decode(&stats); err != nil {
		t.Fatal(err)
	}
	if stats.Totals["install"] != 1 || stats.Totals["launch_success"] != 1 || stats.Totals["launch_failure"] != 1 || stats.Totals["crash_rollback"] != 1 {
		t.Fatalf("unexpected totals: %+v", stats.Totals)
	}
	if len(stats.Last7Days) == 0 {
		t.Fatalf("expected daily stats: %+v", stats)
	}
	if len(stats.TopFailures) != 1 || stats.TopFailures[0].Reason != "boom" || stats.TopFailures[0].Count != 2 {
		t.Fatalf("unexpected top failures: %+v", stats.TopFailures)
	}
}

func TestPatchEventRetentionCleanup(t *testing.T) {
	server, err := NewServer(filepath.Join(t.TempDir(), "store.json"))
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	if _, err := server.db.Exec(
		`insert into patch_events(app_id, release_version, platform, arch, patch_number, event_type, created_at)
		 values
		 ('cleanup-app', '1.0.0+1', 'android', 'arm64-v8a', 1, 'install', datetime('now', '-100 days')),
		 ('cleanup-app', '1.0.0+1', 'android', 'arm64-v8a', 1, 'launch_success', datetime('now'))`,
	); err != nil {
		t.Fatal(err)
	}
	deleted, err := server.deleteOldPatchEvents(90)
	if err != nil {
		t.Fatal(err)
	}
	if deleted != 1 {
		t.Fatalf("deleted %d rows, want 1", deleted)
	}
	var remaining int
	if err := server.db.QueryRow(`select count(*) from patch_events`).Scan(&remaining); err != nil {
		t.Fatal(err)
	}
	if remaining != 1 {
		t.Fatalf("remaining events = %d, want 1", remaining)
	}
}

func mustJSONReader(t *testing.T, value any) io.Reader {
	t.Helper()
	body, err := json.Marshal(value)
	if err != nil {
		t.Fatal(err)
	}
	return bytes.NewReader(body)
}

func firstEligibleClient(t *testing.T, appID, releaseVersion string, rollout int) string {
	t.Helper()
	for i := range 10000 {
		clientID := "client-" + strconv.Itoa(i)
		if eligible(appID, releaseVersion, clientID, rollout) {
			return clientID
		}
	}
	t.Fatalf("no eligible client found for rollout %d", rollout)
	return ""
}

func testPatchManifest(appID, releaseVersion string, patchNumber int) PatchManifest {
	return PatchManifest{
		SchemaVersion:  1,
		AppID:          appID,
		ReleaseVersion: releaseVersion,
		PatchNumber:    patchNumber,
		Channel:        "stable",
		CreatedAt:      "1970-01-01T00:00:00Z",
		Backend:        "snapshot_replace",
		Platform:       "android",
		Arch:           "arm64-v8a",
		Payload: PayloadManifest{
			Kind:        "opaque_payload",
			Compression: "none",
			Hash:        "test-hash",
			Size:        1,
			DownloadURL: patchPayloadKey(appID, releaseVersion, "android", "arm64-v8a", patchNumber),
		},
		Policy: PatchPolicy{
			RolloutPercentage: 100,
			AllowDowngrade:    false,
		},
		Signature: PatchSignature{
			Algorithm: "ed25519",
			KeyID:     "test",
			Value:     "signature",
		},
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

func doJSONWithCookie(t *testing.T, app interface {
	Test(*http.Request, ...int) (*http.Response, error)
}, method, path string, value any, cookie *http.Cookie, want int) {
	t.Helper()
	body, err := json.Marshal(value)
	if err != nil {
		t.Fatal(err)
	}
	req := httptest.NewRequest(method, path, bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.AddCookie(cookie)
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

func mustSessionCookie(t *testing.T, app interface {
	Test(*http.Request, ...int) (*http.Response, error)
}) *http.Cookie {
	t.Helper()
	doJSON(t, app, http.MethodPost, "/api/auth/setup", SetupRequest{
		Username:  "admin",
		Password:  "password123",
		TokenName: "test",
	}, http.StatusOK)
	body, err := json.Marshal(LoginRequest{Username: "admin", Password: "password123"})
	if err != nil {
		t.Fatal(err)
	}
	req := httptest.NewRequest(http.MethodPost, "/api/auth/login", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	resp, err := app.Test(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("login returned HTTP %d: %s", resp.StatusCode, string(body))
	}
	for _, cookie := range resp.Cookies() {
		if cookie.Name == sessionCookie {
			return cookie
		}
	}
	t.Fatal("login did not set session cookie")
	return nil
}

func createSessionForTestUser(t *testing.T, server *Server, username string) *http.Cookie {
	t.Helper()
	result, err := server.db.Exec(`insert into users(username, password_hash) values(?, ?)`, username, "unused")
	if err != nil {
		t.Fatal(err)
	}
	userID, err := result.LastInsertId()
	if err != nil {
		t.Fatal(err)
	}
	token := username + "-session-token"
	if _, err := server.db.Exec(
		`insert into sessions(id, user_id, expires_at) values(?, ?, ?)`,
		sha256Hex([]byte(token)),
		userID,
		"2999-01-01T00:00:00Z",
	); err != nil {
		t.Fatal(err)
	}
	return &http.Cookie{Name: sessionCookie, Value: token}
}

func userIDForTestUser(t *testing.T, server *Server, username string) int64 {
	t.Helper()
	var userID int64
	if err := server.db.QueryRow(`select id from users where username = ?`, username).Scan(&userID); err != nil {
		t.Fatal(err)
	}
	return userID
}

func createOrgTokenViaAdmin(t *testing.T, app interface {
	Test(*http.Request, ...int) (*http.Response, error)
}, session *http.Cookie, orgID string) string {
	t.Helper()
	req := httptest.NewRequest(http.MethodPost, "/api/admin/orgs/"+orgID+"/cli-tokens", mustJSONReader(t, TokenRequest{Name: orgID + "-token"}))
	req.Header.Set("Content-Type", "application/json")
	req.AddCookie(session)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("create org token returned HTTP %d: %s", resp.StatusCode, string(body))
	}
	var token TokenResponse
	if err := json.NewDecoder(resp.Body).Decode(&token); err != nil {
		t.Fatal(err)
	}
	if token.OrgID != orgID || token.Token == "" {
		t.Fatalf("unexpected token response: %+v", token)
	}
	return token.Token
}
