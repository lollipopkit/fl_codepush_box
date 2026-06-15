package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"hash/fnv"
	"io"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/gofiber/fiber/v2"
)

func (s *Server) objectPath(key string) (string, error) {
	clean := filepath.Clean(key)
	if clean == "." || filepath.IsAbs(clean) || clean != key || clean == ".." || strings.HasPrefix(clean, "../") {
		return "", fmt.Errorf("invalid object key")
	}
	return filepath.Join(s.objectsDir, clean), nil
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

func patchPayloadKey(appID, releaseVersion, platform, arch string, patchNumber int) string {
	return fmt.Sprintf("patches/%s/%s/%s/%s/%d/payload.bin", appID, releaseVersion, platform, arch, patchNumber)
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
	return fmt.Sprintf("%s://%s/v1/patches/manifest?%s", c.Protocol(), requestHost(c), q.Encode())
}

func payloadURL(c *fiber.Ctx, key string) string {
	q := url.Values{}
	q.Set("key", key)
	return fmt.Sprintf("%s://%s/v1/patches/payload?%s", c.Protocol(), requestHost(c), q.Encode())
}

func requestHost(c *fiber.Ctx) string {
	if host := c.Get("Host"); host != "" {
		return host
	}
	return c.Hostname()
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
