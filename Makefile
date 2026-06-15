.PHONY: all up down restart status clean build-webui build-server

# Default port and database path configuration
FCB_SERVER_ADDR ?= 127.0.0.1:8080
FCB_SERVER_DB ?= .fcb/server/fcb.sqlite
FCB_SERVER_PID ?= .fcb/server/server.pid
FCB_SERVER_LOG ?= .fcb/server/server.log
FCB_WEBUI_DIST ?= server/webui/dist
FCB_LEGACY_SERVER_PID ?= server.pid
FCB_LEGACY_SERVER_LOG ?= server.log

all: build-webui build-server

# Build the Web UI static assets
build-webui:
	@echo "Building frontend webui..."
	cd server/webui && npm run build

# Build the Go server binary
build-server:
	@echo "Building backend Go server..."
	cd server && go build -o ../fcb_server .

# Start the server in the background
up: build-server
	@if [ ! -d "$(FCB_WEBUI_DIST)" ] || [ ! -f "$(FCB_WEBUI_DIST)/index.html" ]; then \
		$(MAKE) build-webui; \
	fi
	@mkdir -p "$$(dirname "$(FCB_SERVER_DB)")" "$$(dirname "$(FCB_SERVER_PID)")" "$$(dirname "$(FCB_SERVER_LOG)")"
	@if [ -s "$(FCB_SERVER_PID)" ] && kill -0 $$(cat "$(FCB_SERVER_PID)") 2>/dev/null; then \
		echo "Server is already running (PID: $$(cat "$(FCB_SERVER_PID)"))."; \
	elif [ -s "$(FCB_LEGACY_SERVER_PID)" ] && kill -0 $$(cat "$(FCB_LEGACY_SERVER_PID)") 2>/dev/null; then \
		echo "Server is already running from legacy PID file (PID: $$(cat "$(FCB_LEGACY_SERVER_PID)"))."; \
		echo "Run 'make restart' to move runtime files under .fcb/server."; \
	else \
		if [ -f "$(FCB_SERVER_PID)" ]; then \
			echo "Removing stale PID file: $(FCB_SERVER_PID)"; \
			rm -f "$(FCB_SERVER_PID)"; \
		fi; \
		if [ -f "$(FCB_LEGACY_SERVER_PID)" ]; then \
			echo "Removing stale legacy PID file: $(FCB_LEGACY_SERVER_PID)"; \
			rm -f "$(FCB_LEGACY_SERVER_PID)"; \
		fi; \
		echo "Starting FCB server on $(FCB_SERVER_ADDR)..."; \
		FCB_SERVER_ADDR="$(FCB_SERVER_ADDR)" \
		FCB_SERVER_DB="$(FCB_SERVER_DB)" \
		FCB_WEBUI_DIST="$(FCB_WEBUI_DIST)" \
		nohup ./fcb_server > "$(FCB_SERVER_LOG)" 2>&1 & echo $$! > "$(FCB_SERVER_PID)"; \
		sleep 0.5; \
		if [ -s "$(FCB_SERVER_PID)" ] && kill -0 $$(cat "$(FCB_SERVER_PID)") 2>/dev/null; then \
			echo "Server started successfully (PID: $$(cat "$(FCB_SERVER_PID)"))."; \
			echo "Logs: $(FCB_SERVER_LOG)"; \
		else \
			echo "Failed to start server. Check $(FCB_SERVER_LOG) for details."; \
			rm -f "$(FCB_SERVER_PID)"; \
		fi \
	fi

# Stop the running server
down:
	@PID_FILE=""; \
	if [ -s "$(FCB_SERVER_PID)" ]; then \
		PID_FILE="$(FCB_SERVER_PID)"; \
	elif [ -s "$(FCB_LEGACY_SERVER_PID)" ]; then \
		PID_FILE="$(FCB_LEGACY_SERVER_PID)"; \
	fi; \
	if [ -n "$$PID_FILE" ]; then \
		PID=$$(cat "$$PID_FILE"); \
		if ! kill -0 $$PID 2>/dev/null; then \
			echo "Server is not running; removing stale PID file: $$PID_FILE"; \
			rm -f "$$PID_FILE"; \
			exit 0; \
		fi; \
		echo "Stopping FCB server (PID: $$PID)..."; \
		kill $$PID 2>/dev/null || true; \
		for i in 1 2 3 4 5; do \
			if ! kill -0 $$PID 2>/dev/null; then \
				break; \
			fi; \
			sleep 0.2; \
		done; \
		if kill -0 $$PID 2>/dev/null; then \
			echo "Force killing PID $$PID..."; \
			kill -9 $$PID 2>/dev/null || true; \
		fi; \
		rm -f "$$PID_FILE"; \
		echo "Server stopped."; \
	else \
		echo "Server is not running (no $(FCB_SERVER_PID) or $(FCB_LEGACY_SERVER_PID) found)."; \
	fi

# Restart the server
restart: down up

# Check status of the server
status:
	@if [ -s "$(FCB_SERVER_PID)" ] && kill -0 $$(cat "$(FCB_SERVER_PID)") 2>/dev/null; then \
		echo "FCB server is running (PID: $$(cat "$(FCB_SERVER_PID)"), Address: $(FCB_SERVER_ADDR))."; \
	elif [ -s "$(FCB_LEGACY_SERVER_PID)" ] && kill -0 $$(cat "$(FCB_LEGACY_SERVER_PID)") 2>/dev/null; then \
		echo "FCB server is running from legacy PID file (PID: $$(cat "$(FCB_LEGACY_SERVER_PID)"), Address: $(FCB_SERVER_ADDR))."; \
	else \
		echo "FCB server is stopped."; \
	fi

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f fcb_server "$(FCB_SERVER_PID)" "$(FCB_SERVER_LOG)" "$(FCB_LEGACY_SERVER_PID)" "$(FCB_LEGACY_SERVER_LOG)"
