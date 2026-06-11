module fcb-server

go 1.26

// Fiber is pinned at v2.52.13+ for GHSA-qjv7-627w-8qjv and
// GHSA-mrq8-rjmw-wpq3. GHSA-68rr-p4fp-j59v covers UUID entropy; this repo
// targets Go 1.26, reducing risk, but Fiber advisories should be monitored.
require github.com/gofiber/fiber/v2 v2.52.13

require (
	github.com/andybalholm/brotli v1.1.0 // indirect
	github.com/google/uuid v1.6.0 // indirect
	github.com/klauspost/compress v1.17.9 // indirect
	github.com/mattn/go-colorable v0.1.13 // indirect
	github.com/mattn/go-isatty v0.0.20 // indirect
	github.com/mattn/go-runewidth v0.0.16 // indirect
	github.com/rivo/uniseg v0.2.0 // indirect
	github.com/valyala/bytebufferpool v1.0.0 // indirect
	github.com/valyala/fasthttp v1.51.0 // indirect
	github.com/valyala/tcplisten v1.0.0 // indirect
	golang.org/x/sys v0.28.0 // indirect
)
