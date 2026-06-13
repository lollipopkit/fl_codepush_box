#!/usr/bin/env sh
# Environment helper for the exe.dev VM Android Phase B validation setup.
#
# Source this file from the repository root:
#   . tests/e2e/phase_b_vm_env.sh

if [ -f "PLAN.md" ] && [ -d ".toolchains" ]; then
  REPO_ROOT=$(pwd)
else
  echo "phase_b_vm_env.sh must be sourced from the repository root" >&2
  return 2 2>/dev/null || exit 2
fi

export HOME="$REPO_ROOT/.toolchains/home"
export ANDROID_HOME="$REPO_ROOT/.toolchains/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_AVD_HOME="$REPO_ROOT/.toolchains/android-avd"
export XDG_RUNTIME_DIR="$REPO_ROOT/.toolchains/runtime"
export PATH="$REPO_ROOT/.toolchains/flutter/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

export ABI="${ABI:-x86_64}"
export TARGET_PLATFORM="${TARGET_PLATFORM:-android-x64}"
export ADB_DEVICE="${ADB_DEVICE:-emulator-5558}"
export FCB_BIN="${FCB_BIN:-$REPO_ROOT/target/debug/fcb}"
export SERVER_BIN="${SERVER_BIN:-/tmp/fcb_server}"
