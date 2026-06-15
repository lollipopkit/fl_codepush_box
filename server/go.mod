module fcb-server

go 1.26

// Fiber is pinned at v2.52.13+ for GHSA-qjv7-627w-8qjv and
// GHSA-mrq8-rjmw-wpq3. GHSA-68rr-p4fp-j59v covers UUID entropy; this repo
// targets Go 1.26, reducing risk, but Fiber advisories should be monitored.
require github.com/gofiber/fiber/v2 v2.52.13

require golang.org/x/crypto v0.53.0

require modernc.org/sqlite v1.52.0

require (
	github.com/andybalholm/brotli v1.2.1 // indirect
	github.com/clipperhouse/uax29/v2 v2.7.0 // indirect
	github.com/dustin/go-humanize v1.0.1 // indirect
	github.com/google/go-cmp v0.7.0 // indirect
	github.com/google/pprof v0.0.0-20260604005048-7023385849c0 // indirect
	github.com/google/uuid v1.6.0 // indirect
	github.com/hashicorp/golang-lru/v2 v2.0.7 // indirect
	github.com/ianlancetaylor/demangle v0.0.0-20260505044615-1ff4bf46051f // indirect
	github.com/klauspost/compress v1.18.6 // indirect
	github.com/mattn/go-colorable v0.1.15 // indirect
	github.com/mattn/go-isatty v0.0.22 // indirect
	github.com/mattn/go-runewidth v0.0.24 // indirect
	github.com/ncruces/go-strftime v1.0.0 // indirect
	github.com/philhofer/fwd v1.2.0 // indirect
	github.com/remyoudompheng/bigfft v0.0.0-20230129092748-24d4a6f8daec // indirect
	github.com/rivo/uniseg v0.4.7 // indirect
	github.com/tinylib/msgp v1.6.4 // indirect
	github.com/valyala/bytebufferpool v1.0.0 // indirect
	github.com/valyala/fasthttp v1.71.0 // indirect
	github.com/xyproto/randomstring v1.2.0 // indirect
	github.com/yuin/goldmark v1.8.2 // indirect
	golang.org/x/exp v0.0.0-20260611194520-c48552f49976 // indirect
	golang.org/x/mod v0.37.0 // indirect
	golang.org/x/sync v0.21.0 // indirect
	golang.org/x/sys v0.46.0 // indirect
	golang.org/x/telemetry v0.0.0-20260611141451-d61e87d5f4a3 // indirect
	golang.org/x/tools v0.46.0 // indirect
	lukechampine.com/uint128 v1.3.0 // indirect
	modernc.org/cc/v4 v4.28.4 // indirect
	modernc.org/ccgo/v4 v4.34.4 // indirect
	modernc.org/fileutil v1.4.0 // indirect
	modernc.org/gc/v2 v2.6.5 // indirect
	modernc.org/gc/v3 v3.1.4 // indirect
	modernc.org/goabi0 v0.2.0 // indirect
	modernc.org/lexer v1.0.5 // indirect
	modernc.org/libc v1.73.4 // indirect
	modernc.org/mathutil v1.7.1 // indirect
	modernc.org/memory v1.11.0 // indirect
	modernc.org/opt v0.2.0 // indirect
	modernc.org/sortutil v1.2.1 // indirect
	modernc.org/strutil v1.2.1 // indirect
	modernc.org/token v1.1.0 // indirect
)
