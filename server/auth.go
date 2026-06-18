package main

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"golang.org/x/crypto/bcrypt"
)

const sessionCookie = "fcb_session"

func (s *Server) setupStatus(c *fiber.Ctx) error {
	done, err := s.setupDone()
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(map[string]bool{"setup_required": !done})
}

func (s *Server) setup(c *fiber.Ctx) error {
	done, err := s.setupDone()
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	if done {
		return fiber.NewError(fiber.StatusConflict, "setup already completed")
	}
	var req SetupRequest
	if err := c.BodyParser(&req); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	if strings.TrimSpace(req.Username) == "" || len(req.Password) < 8 {
		return fiber.NewError(fiber.StatusBadRequest, "username and password with at least 8 chars are required")
	}
	if req.TokenName == "" {
		req.TokenName = "default"
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	tx, err := s.db.Begin()
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	defer tx.Rollback()
	result, err := tx.Exec(`insert into users(username, password_hash) values(?, ?)`, req.Username, string(hash))
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	userID, err := result.LastInsertId()
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	if _, err := tx.Exec(`insert or ignore into organizations(id, name) values(?, ?)`, defaultOrgID, "Default"); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	if _, err := tx.Exec(`insert or ignore into org_memberships(org_id, user_id, role) values(?, ?, ?)`, defaultOrgID, userID, "owner"); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	token, err := randomToken()
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	if _, err := tx.Exec(`insert into cli_tokens(org_id, name, token_hash) values(?, ?, ?)`, defaultOrgID, req.TokenName, sha256Hex([]byte(token))); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	if err := tx.Commit(); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(SetupResponse{Status: "ok", Token: token})
}

func (s *Server) login(c *fiber.Ctx) error {
	var req LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	var userID int64
	var passwordHash string
	err := s.db.QueryRow(`select id, password_hash from users where username = ?`, req.Username).Scan(&userID, &passwordHash)
	if err != nil || bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(req.Password)) != nil {
		return fiber.NewError(fiber.StatusUnauthorized, "invalid credentials")
	}
	token, err := randomToken()
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	expires := time.Now().Add(7 * 24 * time.Hour).UTC()
	if _, err := s.db.Exec(`insert into sessions(id, user_id, expires_at) values(?, ?, ?)`, sha256Hex([]byte(token)), userID, expires.Format(time.RFC3339)); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	c.Cookie(&fiber.Cookie{Name: sessionCookie, Value: token, HTTPOnly: true, SameSite: "Lax", Expires: expires})
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) logout(c *fiber.Ctx) error {
	token := c.Cookies(sessionCookie)
	if token != "" {
		_, _ = s.db.Exec(`delete from sessions where id = ?`, sha256Hex([]byte(token)))
	}
	c.Cookie(&fiber.Cookie{Name: sessionCookie, Value: "", HTTPOnly: true, SameSite: "Lax", Expires: time.Unix(0, 0)})
	return c.JSON(map[string]string{"status": "ok"})
}

func (s *Server) me(c *fiber.Ctx) error {
	return c.JSON(map[string]any{"authenticated": true, "username": c.Locals("username"), "user_id": currentUserID(c), "org_id": currentOrgID(c)})
}

func (s *Server) requireSession(c *fiber.Ctx) error {
	token := c.Cookies(sessionCookie)
	if token == "" {
		return fiber.NewError(fiber.StatusUnauthorized, "login required")
	}
	var username, expiresAt string
	var userID int64
	err := s.db.QueryRow(
		`select users.id, users.username, sessions.expires_at from sessions join users on users.id = sessions.user_id where sessions.id = ?`,
		sha256Hex([]byte(token)),
	).Scan(&userID, &username, &expiresAt)
	if err != nil {
		return fiber.NewError(fiber.StatusUnauthorized, "login required")
	}
	expires, err := time.Parse(time.RFC3339, expiresAt)
	if err != nil || time.Now().After(expires) {
		_, _ = s.db.Exec(`delete from sessions where id = ?`, sha256Hex([]byte(token)))
		return fiber.NewError(fiber.StatusUnauthorized, "session expired")
	}
	c.Locals("user_id", userID)
	c.Locals("username", username)
	c.Locals("org_id", defaultOrgID)
	return c.Next()
}

func (s *Server) requireOrgRole(minRole string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		userID := currentUserID(c)
		if userID == 0 {
			return fiber.NewError(fiber.StatusUnauthorized, "login required")
		}
		ok, err := s.userHasOrgRole(c.Params("org"), userID, minRole)
		if err != nil {
			return fiber.NewError(fiber.StatusInternalServerError, err.Error())
		}
		if !ok {
			return fiber.NewError(fiber.StatusNotFound, "org not found")
		}
		c.Locals("org_id", c.Params("org"))
		return c.Next()
	}
}

func (s *Server) requireBearer(c *fiber.Ctx) error {
	value := c.Get("Authorization")
	if !strings.HasPrefix(value, "Bearer ") {
		return fiber.NewError(fiber.StatusUnauthorized, "bearer token required")
	}
	tokenHash := sha256Hex([]byte(strings.TrimPrefix(value, "Bearer ")))
	rows, err := s.db.Query(`select token_hash, org_id from cli_tokens where revoked_at is null`)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	ok := false
	orgID := defaultOrgID
	for rows.Next() {
		var stored, storedOrgID string
		if err := rows.Scan(&stored, &storedOrgID); err != nil {
			_ = rows.Close()
			return fiber.NewError(fiber.StatusInternalServerError, err.Error())
		}
		if subtle.ConstantTimeCompare([]byte(stored), []byte(tokenHash)) == 1 {
			ok = true
			orgID = storedOrgID
			break
		}
	}
	if err := rows.Err(); err != nil {
		_ = rows.Close()
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	_ = rows.Close()
	if ok {
		if orgID == "" {
			orgID = defaultOrgID
		}
		c.Locals("org_id", orgID)
		return c.Next()
	}
	return fiber.NewError(fiber.StatusUnauthorized, "invalid bearer token")
}

func (s *Server) createToken(name string) (TokenResponse, error) {
	return s.createTokenInOrg(defaultOrgID, name)
}

func (s *Server) createTokenInOrg(orgID, name string) (TokenResponse, error) {
	orgID, err := validateOrgID(orgID)
	if err != nil {
		return TokenResponse{}, err
	}
	if _, err := s.getOrganization(orgID); err != nil {
		return TokenResponse{}, err
	}
	if strings.TrimSpace(name) == "" {
		name = "token"
	}
	token, err := randomToken()
	if err != nil {
		return TokenResponse{}, err
	}
	result, err := s.db.Exec(`insert into cli_tokens(org_id, name, token_hash) values(?, ?, ?)`, orgID, name, sha256Hex([]byte(token)))
	if err != nil {
		return TokenResponse{}, err
	}
	id, err := result.LastInsertId()
	if err != nil {
		return TokenResponse{}, err
	}
	return TokenResponse{ID: id, OrgID: orgID, Name: name, Token: token, CreatedAt: time.Now().UTC()}, nil
}

func currentOrgID(c *fiber.Ctx) string {
	if orgID, ok := c.Locals("org_id").(string); ok && orgID != "" {
		return orgID
	}
	return defaultOrgID
}

func currentUserID(c *fiber.Ctx) int64 {
	switch value := c.Locals("user_id").(type) {
	case int64:
		return value
	case int:
		return int64(value)
	default:
		return 0
	}
}

func randomToken() (string, error) {
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(bytes), nil
}
