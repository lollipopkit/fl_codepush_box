package main

import (
	"database/sql"
	"encoding/base64"
	"errors"
	"log"
	"net/http"
	"os"
	"strconv"

	"github.com/gofiber/fiber/v2"
)

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
	if err := s.putApp(app); err != nil {
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
	if err := s.ensureApp(manifest.AppID); err != nil {
		return err
	}
	if err := s.putRelease(manifest); err != nil {
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
	expectedKey := patchPayloadKey(manifest.AppID, manifest.ReleaseVersion, manifest.Platform, manifest.Arch, manifest.PatchNumber)
	if manifest.Payload.DownloadURL != expectedKey {
		return fiber.NewError(fiber.StatusBadRequest, "payload download_url does not match server object key")
	}
	objectPath, err := s.objectPath(expectedKey)
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	if err := s.ensureApp(manifest.AppID); err != nil {
		return err
	}
	if _, err := os.Stat(objectPath); err == nil {
		return fiber.NewError(fiber.StatusConflict, "payload object already exists")
	} else if !errors.Is(err, os.ErrNotExist) {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	if err := writeFileAtomic(objectPath, payload); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	manifest.Active = false
	manifest.ActiveChannel = manifest.Channel
	manifest.ActiveRollout = manifest.Policy.RolloutPercentage
	if err := s.putPatch(manifest); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) promotePatch(c *fiber.Ctx) error {
	var req PromotePatchRequest
	if err := c.BodyParser(&req); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	patch, err := s.getPatch(req.AppID, req.ReleaseVersion, req.Platform, req.Arch, req.PatchNumber)
	if err != nil {
		if notFound(err) {
			return fiber.NewError(fiber.StatusNotFound, "patch not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	patch.Active = true
	patch.ActiveChannel = req.Channel
	patch.ActiveRollout = req.RolloutPercentage
	if err := s.putPatch(patch); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) rollbackPatch(c *fiber.Ctx) error {
	var req PromotePatchRequest
	if err := c.BodyParser(&req); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	patch, err := s.getPatch(req.AppID, req.ReleaseVersion, req.Platform, req.Arch, req.PatchNumber)
	if err != nil {
		if notFound(err) {
			return fiber.NewError(fiber.StatusNotFound, "patch not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	patch.Active = false
	patch.ActiveRollout = 0
	if err := s.putPatch(patch); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) checkPatch(c *fiber.Ctx) error {
	current, _ := strconv.Atoi(c.Query("current_patch_number"))
	best, err := s.bestPatch(
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
	return c.JSON(CheckResponse{
		PatchAvailable: true,
		Patch: &PatchCheck{
			PatchNumber:  best.PatchNumber,
			ManifestURL:  manifestURL(c, best.AppID, best.ReleaseVersion, best.Platform, best.Arch, best.PatchNumber),
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
	patchNumber, err := strconv.Atoi(c.Query("patch_number"))
	if err != nil || patchNumber <= 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid patch_number")
	}
	patch, err := s.getPatch(c.Query("app_id"), c.Query("release_version"), c.Query("platform"), c.Query("arch"), patchNumber)
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
		AppID          string `json:"app_id"`
		ReleaseVersion string `json:"release_version"`
		Platform       string `json:"platform"`
		Arch           string `json:"arch"`
		PatchNumber    *int   `json:"patch_number"`
		EventType      string `json:"event_type"`
		ClientIDHash   string `json:"client_id_hash"`
	}
	if len(c.Body()) > 0 {
		_ = c.BodyParser(&payload)
	}
	if payload.EventType != "" {
		_, _ = s.db.Exec(
			`insert into patch_events(app_id, release_version, platform, arch, patch_number, event_type, client_id_hash)
			 values(?, ?, ?, ?, ?, ?, ?)`,
			payload.AppID, payload.ReleaseVersion, payload.Platform, payload.Arch, payload.PatchNumber, payload.EventType, payload.ClientIDHash,
		)
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) adminListApps(c *fiber.Ctx) error {
	apps, err := s.listApps()
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(apps)
}

func (s *Server) adminCreateApp(c *fiber.Ctx) error {
	return s.createApp(c)
}

func (s *Server) adminGetApp(c *fiber.Ctx) error {
	app, err := s.getApp(c.Params("id"))
	if err != nil {
		if notFound(err) {
			return fiber.NewError(fiber.StatusNotFound, "app not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(app)
}

func (s *Server) getAppByID(c *fiber.Ctx) error {
	app, err := s.getApp(c.Params("id"))
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
	if app, err := s.getApp(selector); err == nil {
		return c.JSON(app)
	} else if !notFound(err) {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	apps, err := s.findAppsByName(selector)
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
	var app App
	if err := c.BodyParser(&app); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	app.ID = c.Params("id")
	if app.Name == "" {
		app.Name = app.ID
	}
	if err := s.putApp(app); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) adminDeleteApp(c *fiber.Ctx) error {
	if err := s.deleteApp(c.Params("id")); err != nil {
		if notFound(err) {
			return fiber.NewError(fiber.StatusNotFound, "app not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) adminListReleases(c *fiber.Ctx) error {
	releases, err := s.listReleases(c.Params("id"))
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(releases)
}

func (s *Server) adminListPatches(c *fiber.Ctx) error {
	patches, err := s.listPatches(c.Params("id"))
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(patches)
}

func (s *Server) adminCreateToken(c *fiber.Ctx) error {
	var req TokenRequest
	_ = c.BodyParser(&req)
	token, err := s.createToken(req.Name)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(token)
}

func (s *Server) adminListTokens(c *fiber.Ctx) error {
	rows, err := s.db.Query(`select id, name, created_at from cli_tokens where revoked_at is null order by id desc`)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	defer rows.Close()
	tokens := []TokenResponse{}
	for rows.Next() {
		var token TokenResponse
		var created string
		if err := rows.Scan(&token.ID, &token.Name, &created); err != nil {
			return fiber.NewError(fiber.StatusInternalServerError, err.Error())
		}
		token.CreatedAt = parseDBTime(created)
		tokens = append(tokens, token)
	}
	return c.JSON(tokens)
}

func (s *Server) adminRevokeToken(c *fiber.Ctx) error {
	id, err := strconv.Atoi(c.Params("id"))
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid token id")
	}
	result, err := s.db.Exec(`update cli_tokens set revoked_at = current_timestamp where id = ? and revoked_at is null`, id)
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
	if _, err := s.getApp(appID); err == nil {
		return nil
	} else if !notFound(err) {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return s.putApp(App{ID: appID, Name: appID})
}

func respondErr(c *fiber.Ctx, err error) error {
	if errors.Is(err, sql.ErrNoRows) {
		return fiber.NewError(http.StatusNotFound, "not found")
	}
	return fiber.NewError(http.StatusInternalServerError, err.Error())
}
