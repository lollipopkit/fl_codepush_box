package main

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
)

func (s *Server) healthz(c *fiber.Ctx) error {
	if err := s.db.Ping(); err != nil {
		return fiber.NewError(fiber.StatusServiceUnavailable, err.Error())
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) metricsHandler(c *fiber.Ctx) error {
	c.Type("text/plain; version=0.0.4")
	return c.SendString(fmt.Sprintf(`# HELP fcb_patch_check_requests_total Patch check requests.
# TYPE fcb_patch_check_requests_total counter
fcb_patch_check_requests_total %d
# HELP fcb_patch_event_writes_total Patch event rows written.
# TYPE fcb_patch_event_writes_total counter
fcb_patch_event_writes_total %d
# HELP fcb_storage_errors_total Object storage errors.
# TYPE fcb_storage_errors_total counter
fcb_storage_errors_total %d
`,
		s.metrics.PatchCheckRequests.Load(),
		s.metrics.EventWrites.Load(),
		s.metrics.StorageErrors.Load(),
	))
}

func (s *Server) createApp(c *fiber.Ctx) error {
	var app App
	if err := c.BodyParser(&app); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	if app.ID == "" {
		return fiber.NewError(fiber.StatusBadRequest, "missing app id")
	}
	if app.Name == "" {
		app.Name = app.ID
	}
	if err := s.putAppInOrg(currentOrgID(c), app); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
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
	if err := s.ensureAppInOrg(currentOrgID(c), manifest.AppID); err != nil {
		return err
	}
	if err := s.putReleaseInOrg(currentOrgID(c), manifest); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
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
	orgID := currentOrgID(c)
	expectedKey := patchPayloadKey(manifest.AppID, manifest.ReleaseVersion, manifest.Platform, manifest.Arch, manifest.PatchNumber)
	if manifest.Payload.DownloadURL != expectedKey {
		return fiber.NewError(fiber.StatusBadRequest, "payload download_url does not match server object key")
	}
	if err := s.ensureAppInOrg(orgID, manifest.AppID); err != nil {
		return err
	}
	storageKey := orgScopedPayloadKey(orgID, expectedKey)
	if reader, _, err := s.storage.Get(context.Background(), storageKey); err == nil {
		_ = reader.Close()
		return fiber.NewError(fiber.StatusConflict, "payload object already exists")
	} else if !isObjectNotExist(err) {
		s.metrics.StorageErrors.Add(1)
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	if err := s.storage.Put(context.Background(), storageKey, bytes.NewReader(payload), int64(len(payload))); err != nil {
		s.metrics.StorageErrors.Add(1)
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	manifest.Payload.DownloadURL = storageKey
	manifest.Active = false
	manifest.ActiveChannel = manifest.Channel
	manifest.ActiveRollout = manifest.Policy.RolloutPercentage
	if err := s.putPatchInOrg(orgID, manifest); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) promotePatch(c *fiber.Ctx) error {
	var req PromotePatchRequest
	if err := c.BodyParser(&req); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	patch, err := s.getPatchInOrg(currentOrgID(c), req.AppID, req.ReleaseVersion, req.Platform, req.Arch, req.PatchNumber)
	if err != nil {
		if notFound(err) {
			return fiber.NewError(fiber.StatusNotFound, "patch not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	patch.Active = true
	patch.ActiveChannel = req.Channel
	patch.ActiveRollout = req.RolloutPercentage
	if err := s.putPatchInOrg(currentOrgID(c), patch); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) rollbackPatch(c *fiber.Ctx) error {
	var req PromotePatchRequest
	if err := c.BodyParser(&req); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	patch, err := s.getPatchInOrg(currentOrgID(c), req.AppID, req.ReleaseVersion, req.Platform, req.Arch, req.PatchNumber)
	if err != nil {
		if notFound(err) {
			return fiber.NewError(fiber.StatusNotFound, "patch not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	patch.Active = false
	patch.ActiveRollout = 0
	if err := s.putPatchInOrg(currentOrgID(c), patch); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) checkPatch(c *fiber.Ctx) error {
	s.metrics.PatchCheckRequests.Add(1)
	current, _ := strconv.Atoi(c.Query("current_patch_number"))
	orgID := c.Query("org_id")
	if orgID == "" {
		orgID = defaultOrgID
	}
	best, err := s.bestPatchInOrg(
		orgID,
		c.Query("app_id"),
		c.Query("release_version"),
		c.Query("platform"),
		c.Query("arch"),
		c.Query("channel"),
		c.Query("client_id"),
		current,
	)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	if best == nil {
		return c.JSON(CheckResponse{PatchAvailable: false})
	}
	manifestBytes, err := patchManifestBytes(*best)
	if err != nil {
		log.Printf("marshal patch manifest failed: %v", err)
		return fiber.NewError(fiber.StatusInternalServerError, "failed to marshal patch manifest")
	}
	signedPayloadURL, err := s.storage.SignedURL(context.Background(), best.Payload.DownloadURL, 15*time.Minute)
	if err != nil {
		s.metrics.StorageErrors.Add(1)
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	if strings.HasPrefix(signedPayloadURL, "/") {
		signedPayloadURL = fmt.Sprintf("%s://%s%s", c.Protocol(), requestHost(c), signedPayloadURL)
	}
	return c.JSON(CheckResponse{
		PatchAvailable: true,
		Patch: &PatchCheck{
			PatchNumber:  best.PatchNumber,
			ManifestURL:  manifestURL(c, orgID, best.AppID, best.ReleaseVersion, best.Platform, best.Arch, best.PatchNumber),
			PayloadURL:   signedPayloadURL,
			ManifestHash: sha256Hex(manifestBytes),
			PayloadHash:  best.Payload.Hash,
		},
	})
}

func (s *Server) patchPayload(c *fiber.Ctx) error {
	reader, size, err := s.storage.Get(context.Background(), c.Query("key"))
	if err != nil {
		if isObjectNotExist(err) {
			s.metrics.StorageErrors.Add(1)
			return fiber.NewError(fiber.StatusNotFound, "payload not found")
		}
		s.metrics.StorageErrors.Add(1)
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	defer reader.Close()
	data, err := io.ReadAll(reader)
	if err != nil {
		s.metrics.StorageErrors.Add(1)
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	if size >= 0 && int64(len(data)) != size {
		s.metrics.StorageErrors.Add(1)
		return fiber.NewError(fiber.StatusInternalServerError, "payload size mismatch")
	}
	return c.Send(data)
}

func (s *Server) patchManifest(c *fiber.Ctx) error {
	patchNumber, err := strconv.Atoi(c.Query("patch_number"))
	if err != nil || patchNumber <= 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid patch_number")
	}
	orgID := c.Query("org_id")
	if orgID == "" {
		orgID = defaultOrgID
	}
	patch, err := s.getPatchInOrg(orgID, c.Query("app_id"), c.Query("release_version"), c.Query("platform"), c.Query("arch"), patchNumber)
	if err != nil {
		if notFound(err) {
			return fiber.NewError(fiber.StatusNotFound, "patch not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
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
	var payload struct {
		OrgID          string `json:"org_id"`
		AppID          string `json:"app_id"`
		ReleaseVersion string `json:"release_version"`
		Platform       string `json:"platform"`
		Arch           string `json:"arch"`
		PatchNumber    *int   `json:"patch_number"`
		EventType      string `json:"event_type"`
		ClientIDHash   string `json:"client_id_hash"`
		Payload        any    `json:"payload"`
	}
	if len(c.Body()) > 0 {
		_ = c.BodyParser(&payload)
	}
	if payload.EventType != "" {
		orgID, err := validateOrgID(payload.OrgID)
		if err != nil {
			return fiber.NewError(fiber.StatusBadRequest, err.Error())
		}
		payloadJSON, _ := json.Marshal(payload.Payload)
		if _, err := s.db.Exec(
			`insert into patch_events(org_id, app_id, release_version, platform, arch, patch_number, event_type, client_id_hash, payload)
			 values(?, ?, ?, ?, ?, ?, ?, ?, ?)`,
			orgID, payload.AppID, payload.ReleaseVersion, payload.Platform, payload.Arch, payload.PatchNumber, payload.EventType, payload.ClientIDHash, string(payloadJSON),
		); err != nil {
			return fiber.NewError(fiber.StatusInternalServerError, err.Error())
		}
		s.metrics.EventWrites.Add(1)
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) adminListOrgs(c *fiber.Ctx) error {
	orgs, err := s.listOrganizationsForUser(currentUserID(c))
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(orgs)
}

func (s *Server) adminCreateOrg(c *fiber.Ctx) error {
	var org Organization
	if err := c.BodyParser(&org); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	if err := s.putOrganization(org); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	if err := s.addOrgMember(org.ID, OrgMemberRequest{UserID: currentUserID(c), Role: "owner"}); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) adminListOrgMembers(c *fiber.Ctx) error {
	members, err := s.listOrgMembers(c.Params("org"))
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(members)
}

func (s *Server) adminAddOrgMember(c *fiber.Ctx) error {
	var req OrgMemberRequest
	if err := c.BodyParser(&req); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	if err := s.addOrgMember(c.Params("org"), req); err != nil {
		if notFound(err) {
			return fiber.NewError(fiber.StatusNotFound, "user or org not found")
		}
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) adminUpdateOrgMember(c *fiber.Ctx) error {
	userID, err := strconv.ParseInt(c.Params("user_id"), 10, 64)
	if err != nil || userID <= 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid user id")
	}
	var req OrgMemberUpdateRequest
	if err := c.BodyParser(&req); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	if err := s.updateOrgMemberRole(c.Params("org"), userID, req.Role); err != nil {
		if notFound(err) {
			return fiber.NewError(fiber.StatusNotFound, "member not found")
		}
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) adminRemoveOrgMember(c *fiber.Ctx) error {
	userID, err := strconv.ParseInt(c.Params("user_id"), 10, 64)
	if err != nil || userID <= 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid user id")
	}
	if err := s.removeOrgMember(c.Params("org"), userID); err != nil {
		if notFound(err) {
			return fiber.NewError(fiber.StatusNotFound, "member not found")
		}
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) adminListApps(c *fiber.Ctx) error {
	return s.adminListAppsForOrg(c, defaultOrgID)
}

func (s *Server) adminListOrgApps(c *fiber.Ctx) error {
	return s.adminListAppsForOrg(c, c.Params("org"))
}

func (s *Server) adminListAppsForOrg(c *fiber.Ctx, orgID string) error {
	apps, err := s.listAppsInOrg(orgID)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(apps)
}

func (s *Server) adminCreateApp(c *fiber.Ctx) error {
	return s.adminCreateAppForOrg(c, defaultOrgID)
}

func (s *Server) adminCreateOrgApp(c *fiber.Ctx) error {
	return s.adminCreateAppForOrg(c, c.Params("org"))
}

func (s *Server) adminCreateAppForOrg(c *fiber.Ctx, orgID string) error {
	var app App
	if err := c.BodyParser(&app); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	if app.ID == "" {
		return fiber.NewError(fiber.StatusBadRequest, "missing app id")
	}
	if app.Name == "" {
		app.Name = app.ID
	}
	if err := s.putAppInOrg(orgID, app); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) adminGetApp(c *fiber.Ctx) error {
	return s.adminGetAppForOrg(c, defaultOrgID)
}

func (s *Server) adminGetOrgApp(c *fiber.Ctx) error {
	return s.adminGetAppForOrg(c, c.Params("org"))
}

func (s *Server) adminGetAppForOrg(c *fiber.Ctx, orgID string) error {
	app, err := s.getAppInOrg(orgID, c.Params("id"))
	if err != nil {
		if notFound(err) {
			return fiber.NewError(fiber.StatusNotFound, "app not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(app)
}

func (s *Server) getAppByID(c *fiber.Ctx) error {
	app, err := s.getAppInOrg(currentOrgID(c), c.Params("id"))
	if err != nil {
		if notFound(err) {
			return fiber.NewError(fiber.StatusNotFound, "app not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(app)
}

func (s *Server) resolveApp(c *fiber.Ctx) error {
	selector := c.Query("app")
	if selector == "" {
		return fiber.NewError(fiber.StatusBadRequest, "missing app")
	}
	if app, err := s.getAppInOrg(currentOrgID(c), selector); err == nil {
		return c.JSON(app)
	} else if !notFound(err) {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	apps, err := s.findAppsByNameInOrg(currentOrgID(c), selector)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	if len(apps) == 0 {
		return fiber.NewError(fiber.StatusNotFound, "app not found")
	}
	if len(apps) > 1 {
		ids := make([]string, 0, len(apps))
		for _, app := range apps {
			ids = append(ids, app.ID)
		}
		return c.Status(fiber.StatusConflict).JSON(map[string]any{
			"error": "app name is ambiguous; use --app-id",
			"ids":   ids,
		})
	}
	return c.JSON(apps[0])
}

func (s *Server) adminUpdateApp(c *fiber.Ctx) error {
	return s.adminUpdateAppForOrg(c, defaultOrgID)
}

func (s *Server) adminUpdateOrgApp(c *fiber.Ctx) error {
	return s.adminUpdateAppForOrg(c, c.Params("org"))
}

func (s *Server) adminUpdateAppForOrg(c *fiber.Ctx, orgID string) error {
	var app App
	if err := c.BodyParser(&app); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	app.ID = c.Params("id")
	if app.Name == "" {
		app.Name = app.ID
	}
	if err := s.putAppInOrg(orgID, app); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) adminDeleteApp(c *fiber.Ctx) error {
	return s.adminDeleteAppForOrg(c, defaultOrgID)
}

func (s *Server) adminDeleteOrgApp(c *fiber.Ctx) error {
	return s.adminDeleteAppForOrg(c, c.Params("org"))
}

func (s *Server) adminDeleteAppForOrg(c *fiber.Ctx, orgID string) error {
	if err := s.deleteAppInOrg(orgID, c.Params("id")); err != nil {
		if notFound(err) {
			return fiber.NewError(fiber.StatusNotFound, "app not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) adminListReleases(c *fiber.Ctx) error {
	return s.adminListReleasesForOrg(c, defaultOrgID)
}

func (s *Server) adminListOrgReleases(c *fiber.Ctx) error {
	return s.adminListReleasesForOrg(c, c.Params("org"))
}

func (s *Server) adminListReleasesForOrg(c *fiber.Ctx, orgID string) error {
	releases, err := s.listReleasesInOrg(orgID, c.Params("id"))
	if err != nil {
		if notFound(err) {
			return fiber.NewError(fiber.StatusNotFound, "app not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(releases)
}

func (s *Server) adminListPatches(c *fiber.Ctx) error {
	return s.adminListPatchesForOrg(c, defaultOrgID)
}

func (s *Server) adminListOrgPatches(c *fiber.Ctx) error {
	return s.adminListPatchesForOrg(c, c.Params("org"))
}

func (s *Server) adminListPatchesForOrg(c *fiber.Ctx, orgID string) error {
	patches, err := s.listPatchesInOrg(orgID, c.Params("id"))
	if err != nil {
		if notFound(err) {
			return fiber.NewError(fiber.StatusNotFound, "app not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(patches)
}

func (s *Server) adminPatchStats(c *fiber.Ctx) error {
	return s.adminPatchStatsForOrg(c, defaultOrgID)
}

func (s *Server) adminOrgPatchStats(c *fiber.Ctx) error {
	return s.adminPatchStatsForOrg(c, c.Params("org"))
}

func (s *Server) adminPatchStatsForOrg(c *fiber.Ctx, orgID string) error {
	patchNumber, err := strconv.Atoi(c.Params("patch_number"))
	if err != nil || patchNumber <= 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid patch_number")
	}
	if _, err := s.getAppInOrg(orgID, c.Params("id")); err != nil {
		if notFound(err) {
			return fiber.NewError(fiber.StatusNotFound, "app not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	stats, err := s.patchStatsInOrg(
		orgID,
		c.Params("id"),
		c.Query("release_version"),
		c.Query("platform"),
		c.Query("arch"),
		patchNumber,
	)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(stats)
}

func (s *Server) adminCreateToken(c *fiber.Ctx) error {
	return s.adminCreateTokenForOrg(c, defaultOrgID)
}

func (s *Server) adminCreateOrgToken(c *fiber.Ctx) error {
	return s.adminCreateTokenForOrg(c, c.Params("org"))
}

func (s *Server) adminCreateTokenForOrg(c *fiber.Ctx, orgID string) error {
	var req TokenRequest
	_ = c.BodyParser(&req)
	token, err := s.createTokenInOrg(orgID, req.Name)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(token)
}

func (s *Server) adminListTokens(c *fiber.Ctx) error {
	return s.adminListTokensForOrg(c, defaultOrgID)
}

func (s *Server) adminListOrgTokens(c *fiber.Ctx) error {
	return s.adminListTokensForOrg(c, c.Params("org"))
}

func (s *Server) adminListTokensForOrg(c *fiber.Ctx, orgID string) error {
	orgID, err := validateOrgID(orgID)
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	rows, err := s.db.Query(`select id, org_id, name, created_at from cli_tokens where org_id = ? and revoked_at is null order by id desc`, orgID)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	defer rows.Close()
	tokens := []TokenResponse{}
	for rows.Next() {
		var token TokenResponse
		var created string
		if err := rows.Scan(&token.ID, &token.OrgID, &token.Name, &created); err != nil {
			return fiber.NewError(fiber.StatusInternalServerError, err.Error())
		}
		token.CreatedAt = parseDBTime(created)
		tokens = append(tokens, token)
	}
	return c.JSON(tokens)
}

func (s *Server) adminRevokeToken(c *fiber.Ctx) error {
	return s.adminRevokeTokenForOrg(c, defaultOrgID)
}

func (s *Server) adminRevokeOrgToken(c *fiber.Ctx) error {
	return s.adminRevokeTokenForOrg(c, c.Params("org"))
}

func (s *Server) adminRevokeTokenForOrg(c *fiber.Ctx, orgID string) error {
	id, err := strconv.Atoi(c.Params("id"))
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid token id")
	}
	orgID, err = validateOrgID(orgID)
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	result, err := s.db.Exec(`update cli_tokens set revoked_at = current_timestamp where org_id = ? and id = ? and revoked_at is null`, orgID, id)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	n, _ := result.RowsAffected()
	if n == 0 {
		return fiber.NewError(fiber.StatusNotFound, "token not found")
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) ensureApp(appID string) error {
	return s.ensureAppInOrg(defaultOrgID, appID)
}

func (s *Server) ensureAppInOrg(orgID, appID string) error {
	if _, err := s.getAppInOrg(orgID, appID); err == nil {
		return nil
	} else if !notFound(err) {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return s.putAppInOrg(orgID, App{ID: appID, Name: appID})
}

func respondErr(c *fiber.Ctx, err error) error {
	if errors.Is(err, sql.ErrNoRows) {
		return fiber.NewError(http.StatusNotFound, "not found")
	}
	return fiber.NewError(http.StatusInternalServerError, err.Error())
}
