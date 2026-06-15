package main

import (
	"os"
	"path/filepath"
	"strings"

	"github.com/gofiber/fiber/v2"
)

func mountWebUI(app *fiber.App) {
	dist := os.Getenv("FCB_WEBUI_DIST")
	if dist == "" {
		dist = filepath.Join("webui", "dist")
	}
	if _, err := os.Stat(filepath.Join(dist, "index.html")); err != nil {
		app.Get("/", func(c *fiber.Ctx) error {
			c.Type("html")
			return c.SendString("<!doctype html><title>FCB</title><h1>FCB WebUI is not built</h1><p>Run npm install && npm run build in server/webui.</p>")
		})
		return
	}
	app.Static("/", dist)
	app.Get("*", func(c *fiber.Ctx) error {
		path := c.Path()
		if strings.HasPrefix(path, "/api/") || strings.HasPrefix(path, "/v1/") {
			return fiber.ErrNotFound
		}
		return c.SendFile(filepath.Join(dist, "index.html"))
	})
}
