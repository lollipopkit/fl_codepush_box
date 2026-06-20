.PHONY: all up down restart status clean build-webui build-server ci-local-core check-workflows check-github-actions-inventory check-phase-h-runbooks test-s3-storage test-admin-runtime test-crash-rollback test-kernel-compile test-flutter-package test-vendor-sdk-delta test-vendor-vm-runtime

# Default port and database path configuration
FCB_SERVER_ADDR ?= 127.0.0.1:8080
FCB_SERVER_DB ?= .fcb/server/fcb.sqlite
FCB_SERVER_PID ?= .fcb/server/server.pid
FCB_SERVER_LOG ?= .fcb/server/server.log
FCB_WEBUI_DIST ?= server/webui/dist
FCB_LEGACY_SERVER_PID ?= server.pid
FCB_LEGACY_SERVER_LOG ?= server.log
FLUTTER ?= flutter

all: build-webui build-server

ci-local-core:
	@echo "Running local core CI..."
	scripts/ci_local_core.sh

check-workflows: check-github-actions-inventory
	@echo "Checking GitHub workflow files..."
	@test -d .github/workflows
	@for workflow in .github/workflows/*.yml; do \
		test -s "$$workflow" || { echo "empty workflow: $$workflow" >&2; exit 1; }; \
		grep -Eq '^[[:space:]]*on:' "$$workflow" || { echo "workflow missing on: $$workflow" >&2; exit 1; }; \
		grep -Eq '^[[:space:]]*jobs:' "$$workflow" || { echo "workflow missing jobs: $$workflow" >&2; exit 1; }; \
	done

check-github-actions-inventory:
	@echo "Checking GitHub Actions inventory..."
	@for workflow in \
		.github/workflows/android_emulator.yml \
		.github/workflows/desktop.yml \
		.github/workflows/e2e_x64.yml \
		.github/workflows/flutter_package.yml \
		.github/workflows/ios_simulator.yml \
		.github/workflows/rust.yml \
		.github/workflows/server.yml \
		.github/workflows/server_s3.yml; do \
		test -s "$$workflow" || { echo "missing workflow: $$workflow" >&2; exit 1; }; \
	done

check-phase-h-runbooks:
	@echo "Checking Phase H runbooks..."
	@for path in \
		plans/phase_h_vendor_ci_devices.md \
		docs/ios_distribution.md \
		docs/apple_compliance.md \
		docs/known_issues.md \
		scripts/full_arm64_drill.sh \
		scripts/full_ios_drill.sh \
		scripts/check_android_arm64_device.sh; do \
		test -s "$$path" || { echo "missing Phase H runbook artifact: $$path" >&2; exit 1; }; \
	done

test-s3-storage:
	@echo "Running S3 storage drill..."
	scripts/test_s3_storage.sh

test-admin-runtime:
	@echo "Running admin runtime drill..."
	scripts/test_admin_runtime.sh

test-crash-rollback:
	@echo "Running crash rollback drill..."
	scripts/test_crash_rollback.sh

test-kernel-compile:
	@echo "Running Kernel compile-from-plan drill..."
	tests/e2e/test_kernel_compile_from_plan.sh

test-flutter-package:
	@echo "Running fcb_code_push Flutter package tests..."
	cd packages/fcb_code_push && $(FLUTTER) test

test-vendor-sdk-delta:
	@echo "Running vendor Dart SDK delta audit..."
	scripts/audit_vendor_dart_sdk_delta.sh

test-vendor-vm-runtime:
	@echo "Running vendor Dart VM FCB runtime test..."
	scripts/test_vendor_vm_runtime.sh

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
