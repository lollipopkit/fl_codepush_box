#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${FCB_APP_DIR:-$ROOT_DIR/examples/counter_app}"
FLUTTER_BIN="${FCB_FLUTTER_BIN:-$ROOT_DIR/vendor/flutter/bin/flutter}"
ENGINE_SRC_DIR="${FCB_ENGINE_SRC_DIR:-$ROOT_DIR/vendor/flutter/engine/src}"
ENGINE_OUT_NAME="${FCB_ENGINE_OUT_NAME:-android_release_arm64}"
LOCAL_ENGINE_HOST="${FCB_LOCAL_ENGINE_HOST:-host_release}"
ANDROID_TARGET_PLATFORM="${FCB_ANDROID_TARGET_PLATFORM:-android-arm64}"
PKG="${FCB_ANDROID_PACKAGE:-com.example.fcb_counter_app}"
WORKDIR="${FCB_WORKDIR:-$ROOT_DIR/target/fcb/android-arm64}"
case "$WORKDIR" in
  /*) ;;
  *) WORKDIR="$ROOT_DIR/$WORKDIR" ;;
esac
LOG_DIR="$WORKDIR/logs"
LOGCAT_FILE="$LOG_DIR/logcat.txt"
RESULT_FILE="$WORKDIR/result.txt"
ADB="${FCB_ADB:-$ENGINE_SRC_DIR/flutter/third_party/android_tools/sdk/platform-tools/adb}"
ADB_TIMEOUT_SECONDS="${FCB_ADB_TIMEOUT_SECONDS:-30}"
SKIP_BUILD="${FCB_SKIP_BUILD:-0}"
SKIP_INSTALL="${FCB_SKIP_INSTALL:-0}"
FLUTTER_CLEAN="${FCB_FLUTTER_CLEAN:-1}"
INSTALL_BYTECODE_PATCH="${FCB_INSTALL_BYTECODE_PATCH:-0}"
INSTALL_PATCH_SCRIPT="${FCB_INSTALL_PATCH_SCRIPT:-$ROOT_DIR/scripts/install_android_bytecode_patch.sh}"
EXPECTED_INITIAL_COUNTER="${FCB_EXPECTED_INITIAL_COUNTER:-}"
EXPECTED_ADJUSTED_COUNTER="${FCB_EXPECTED_ADJUSTED_COUNTER:-}"
EXPECTED_STATIC_COUNTER="${FCB_EXPECTED_STATIC_COUNTER:-}"
EXPECTED_STATUS_LABEL="${FCB_EXPECTED_STATUS_LABEL:-}"
EXPECTED_WIDGET_TREE_LABEL="${FCB_EXPECTED_WIDGET_TREE_LABEL:-}"
EXPECTED_FIELD_STATUS_LABEL="${FCB_EXPECTED_FIELD_STATUS_LABEL:-}"
EXPECTED_QUAD_COUNTER="${FCB_EXPECTED_QUAD_COUNTER:-}"
ALLOW_SECONDARY_ABI="${FCB_ALLOW_SECONDARY_ABI:-0}"
REQUIRE_PRIMARY_ABI="${FCB_REQUIRE_PRIMARY_ABI:-0}"
AOT_PROBE_ALLOWLIST="${FCB_AOT_PROBE_ALLOWLIST:-}"
SERVER_URL="${FCB_SERVER_URL:-}"
APP_ID="${FCB_APP_ID:-}"
PUBLIC_KEY="${FCB_PUBLIC_KEY:-}"
RELEASE_VERSION="${FCB_RELEASE_VERSION:-}"
CHANNEL="${FCB_CHANNEL:-}"
PLATFORM="${FCB_PLATFORM:-}"
ARCH="${FCB_ARCH:-}"
CACHE_DIR="${FCB_CACHE_DIR:-}"
BASELINE_ARTIFACT="${FCB_BASELINE_ARTIFACT:-}"
AUTO_INSTALL_ON_STARTUP="${FCB_AUTO_INSTALL_ON_STARTUP:-}"
if [ -n "$AOT_PROBE_ALLOWLIST" ]; then
  DEFAULT_GEN_SNAPSHOT_OPTIONS="--fcb_enable_aot_dispatch,--fcb_aot_probe_allowlist=$AOT_PROBE_ALLOWLIST"
else
  DEFAULT_GEN_SNAPSHOT_OPTIONS="--fcb_enable_aot_dispatch"
fi
EXTRA_GEN_SNAPSHOT_OPTIONS="${FCB_EXTRA_GEN_SNAPSHOT_OPTIONS:-$DEFAULT_GEN_SNAPSHOT_OPTIONS}"

usage() {
  cat <<USAGE
Usage:
  $0

Environment:
  FCB_APP_DIR                  Flutter app directory. Default: examples/counter_app
  FCB_FLUTTER_BIN              Flutter binary. Default: vendor/flutter/bin/flutter
  FCB_ENGINE_SRC_DIR           Engine src root. Default: vendor/flutter/engine/src
  FCB_ENGINE_OUT_NAME          Local Engine output. Default: android_release_arm64
  FCB_LOCAL_ENGINE_HOST        Local host Engine output. Default: host_release
  FCB_ANDROID_TARGET_PLATFORM  Flutter target platform. Default: android-arm64
  FCB_ANDROID_PACKAGE          Android package name. Default: com.example.fcb_counter_app
  FCB_ADB                      adb path. Default: Engine Android SDK adb
  FCB_SKIP_BUILD               Skip flutter build apk. Default: 0
  FCB_SKIP_INSTALL             Skip adb install. Default: 0
  FCB_FLUTTER_CLEAN            Run flutter clean before build. Default: 1
  FCB_INSTALL_BYTECODE_PATCH   Install a manual bytecode launch patch before starting. Default: 0
  FCB_INSTALL_PATCH_SCRIPT     Patch installer script. Default: scripts/install_android_bytecode_patch.sh
  FCB_EXPECTED_INITIAL_COUNTER Expected initialCounterValue result. Default: 42 with patch, otherwise 1
  FCB_EXPECTED_ADJUSTED_COUNTER
                              Expected adjustedCounterValue result. Default: 42 with patch, otherwise 8
  FCB_EXPECTED_STATIC_COUNTER  Expected PricingEngine.staticCounterValue result. Default: 42 with patch, otherwise 7
  FCB_EXPECTED_STATUS_LABEL    Expected statusLabel result. Default: patched with patch, otherwise base
  FCB_EXPECTED_WIDGET_TREE_LABEL
                              Expected widgetTreeLabel result. Default: patched widget tree with patch, otherwise baseline widget tree
  FCB_EXPECTED_FIELD_STATUS_LABEL
                              Expected fieldStatusLabel result. Default: patched-field with patch, otherwise base-field
  FCB_EXPECTED_QUAD_COUNTER    Expected quadCounterValue result. Default: 42 with patch, otherwise 10
  FCB_ALLOW_SECONDARY_ABI      Allow target ABI when listed as secondary ABI. Default: 0
  FCB_REQUIRE_PRIMARY_ABI      Require device primary ABI to match target ABI. Default: 0
  FCB_AOT_PROBE_ALLOWLIST      Optional gen_snapshot FCB probe allowlist. Default: unset
  FCB_EXTRA_GEN_SNAPSHOT_OPTIONS
                              Extra gen_snapshot flags. Default: --fcb_enable_aot_dispatch plus FCB_AOT_PROBE_ALLOWLIST when set
  FCB_SERVER_URL               Optional Dart define for counter_app FCB server URL.
  FCB_APP_ID                   Optional Dart define for counter_app app id.
  FCB_PUBLIC_KEY               Optional Dart define for counter_app public key.
  FCB_RELEASE_VERSION          Optional Dart define for release version.
  FCB_CHANNEL                  Optional Dart define for channel.
  FCB_PLATFORM                 Optional Dart define for platform.
  FCB_ARCH                     Optional Dart define for arch.
  FCB_CACHE_DIR                Optional Dart define for updater cache directory.
  FCB_BASELINE_ARTIFACT        Optional Dart define for baseline artifact path.
  FCB_AUTO_INSTALL_ON_STARTUP  Optional Dart define for startup update check/install.
  FCB_WORKDIR                  Per-run state/log directory. Default: target/fcb/android-arm64
USAGE
}

die() {
  echo "error: $*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || die "missing file: $1"
}

require_dir() {
  [ -d "$1" ] || die "missing directory: $1"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required"
}

run() {
  echo "+ $*" >&2
  "$@"
}

adb_cmd() {
  if command -v timeout >/dev/null 2>&1; then
    timeout "$ADB_TIMEOUT_SECONDS" "$ADB" "$@"
  else
    "$ADB" "$@"
  fi
}

adb_shell() {
  adb_cmd shell "$@"
}

target_abi_for_platform() {
  case "$ANDROID_TARGET_PLATFORM" in
    android-arm64) echo "arm64-v8a" ;;
    android-arm) echo "armeabi-v7a" ;;
    android-x64) echo "x86_64" ;;
    android-x86) echo "x86" ;;
    *) die "unsupported FCB_ANDROID_TARGET_PLATFORM: $ANDROID_TARGET_PLATFORM" ;;
  esac
}

expected_engine_machine_for_platform() {
  case "$ANDROID_TARGET_PLATFORM" in
    android-arm64) echo "ARM aarch64" ;;
    android-arm) echo "ARM" ;;
    android-x64) echo "x86-64" ;;
    android-x86) echo "Intel 80386" ;;
    *) die "unsupported FCB_ANDROID_TARGET_PLATFORM: $ANDROID_TARGET_PLATFORM" ;;
  esac
}

expected_host_machine() {
  if [ -n "${FCB_EXPECTED_HOST_MACHINE:-}" ]; then
    echo "$FCB_EXPECTED_HOST_MACHINE"
    return 0
  fi

  case "$(uname -s):$(uname -m)" in
    Darwin:arm64) echo "arm64" ;;
    *:x86_64|*:amd64) echo "x86-64" ;;
    *:aarch64|*:arm64) echo "ARM aarch64" ;;
    *) die "unsupported host machine for gen_snapshot verification: $(uname -m)" ;;
  esac
}

expected_android_gen_snapshot_machine() {
  if [ -n "${FCB_EXPECTED_ANDROID_GEN_SNAPSHOT_MACHINE:-}" ]; then
    echo "$FCB_EXPECTED_ANDROID_GEN_SNAPSHOT_MACHINE"
    return 0
  fi

  case "$(uname -s):$(uname -m)" in
    Darwin:arm64) echo "x86_64" ;;
    *) expected_host_machine ;;
  esac
}

verify_file_machine() {
  local path="$1"
  local expected="$2"
  local description="$3"
  local actual

  require_file "$path"
  require_command file
  actual="$(file "$path")"
  if [[ "$actual" != *"$expected"* ]]; then
    die "$description has wrong machine type; expected '$expected', got: $actual"
  fi
  echo "$description verified: $actual"
}

snapshot_version() {
  local path="$1"
  awk '/^[0-9a-f]{32}$/ { print; exit }' < <(strings "$path")
}

verify_snapshot_version_match() {
  local engine_path="$1"
  local snapshotter_path="$2"
  local description="$3"
  local engine_version snapshotter_version

  require_command strings
  engine_version="$(snapshot_version "$engine_path")"
  snapshotter_version="$(snapshot_version "$snapshotter_path")"
  [ -n "$engine_version" ] || die "could not extract Dart snapshot version from $engine_path"
  [ -n "$snapshotter_version" ] || die "could not extract Dart snapshot version from $snapshotter_path"

  if [ "$engine_version" != "$snapshotter_version" ]; then
    die "$description has Dart snapshot version '$snapshotter_version', but local-engine libflutter.so expects '$engine_version'"
  fi
  echo "$description Dart snapshot version verified: $snapshotter_version"
}

verify_host_gen_snapshot() {
  local host_out_dir="$1"
  local expected_machine="$2"
  local host_gen_snapshot="$host_out_dir/gen_snapshot"
  local clang_gen_snapshot="$host_out_dir/clang_arm64/gen_snapshot"

  if [ -f "$host_gen_snapshot" ] &&
      file "$host_gen_snapshot" | grep -Fq "$expected_machine"; then
    verify_file_machine "$host_gen_snapshot" "$expected_machine" "local-engine-host gen_snapshot"
    return 0
  fi

  if [ -f "$clang_gen_snapshot" ]; then
    verify_file_machine "$clang_gen_snapshot" "$expected_machine" "local-engine-host clang_arm64 gen_snapshot"
    return 0
  fi

  verify_file_machine "$host_gen_snapshot" "$expected_machine" "local-engine-host gen_snapshot"
}

file_mtime() {
  if stat -c %Y "$1" >/dev/null 2>&1; then
    stat -c %Y "$1"
  else
    stat -f %m "$1"
  fi
}

app_snapshot_path() {
  local target_abi
  target_abi="$(target_abi_for_platform)"
  echo "$APP_DIR/build/app/intermediates/flutter/release/$target_abi/app.so"
}

verify_app_snapshot() {
  local app_so gen_snapshot app_mtime snapshot_mtime
  app_so="$(app_snapshot_path)"
  gen_snapshot="$ENGINE_SRC_DIR/out/$LOCAL_ENGINE_HOST/gen_snapshot"

  verify_file_machine "$app_so" \
    "$(expected_engine_machine_for_platform)" \
    "Flutter AOT app.so"

  if [ "$SKIP_BUILD" = "1" ]; then
    require_command stat
    app_mtime="$(file_mtime "$app_so")"
    snapshot_mtime="$(file_mtime "$gen_snapshot")"
    if [ "$app_mtime" -lt "$snapshot_mtime" ]; then
      die "FCB_SKIP_BUILD=1 would reuse stale app.so built before local-engine gen_snapshot; rerun without FCB_SKIP_BUILD=1"
    fi
  fi
}

verify_local_engine_artifacts() {
  local out_dir="$ENGINE_SRC_DIR/out/$ENGINE_OUT_NAME"
  local host_out_dir="$ENGINE_SRC_DIR/out/$LOCAL_ENGINE_HOST"
  local libflutter_so="$out_dir/libflutter.so"
  local android_gen_snapshot_machine
  android_gen_snapshot_machine="$(expected_android_gen_snapshot_machine)"
  verify_file_machine "$out_dir/libflutter.so" \
    "$(expected_engine_machine_for_platform)" \
    "local-engine libflutter.so"
  verify_file_machine "$out_dir/gen_snapshot" \
    "$android_gen_snapshot_machine" \
    "local-engine gen_snapshot"
  verify_snapshot_version_match "$libflutter_so" \
    "$out_dir/gen_snapshot" \
    "local-engine gen_snapshot"
  if [ -f "$out_dir/clang_x64/gen_snapshot" ]; then
    verify_file_machine "$out_dir/clang_x64/gen_snapshot" \
      "$android_gen_snapshot_machine" \
      "local-engine clang_x64 gen_snapshot"
    verify_snapshot_version_match "$libflutter_so" \
      "$out_dir/clang_x64/gen_snapshot" \
      "local-engine clang_x64 gen_snapshot"
  fi
  verify_host_gen_snapshot "$host_out_dir" \
    "$(expected_host_machine)"
}

check_device_abi() {
  local target_abi primary_abi abi_list
  target_abi="$(target_abi_for_platform)"
  primary_abi="$(adb_shell getprop ro.product.cpu.abi | tr -d '\r[:space:]')"
  abi_list="$(adb_shell getprop ro.product.cpu.abilist | tr -d '\r[:space:]')"

  if [ "$primary_abi" = "$target_abi" ]; then
    return 0
  fi

  if [ "$REQUIRE_PRIMARY_ABI" = "1" ]; then
    die "device primary ABI is $primary_abi, but this acceptance run requires primary ABI $target_abi (abilist: ${abi_list:-unknown}); use a real $target_abi device or unset FCB_REQUIRE_PRIMARY_ABI for emulator/native-bridge smoke"
  fi

  if [ "$ALLOW_SECONDARY_ABI" != "1" ]; then
    die "device primary ABI is $primary_abi, but target platform $ANDROID_TARGET_PLATFORM requires $target_abi (abilist: ${abi_list:-unknown}); set FCB_ALLOW_SECONDARY_ABI=1 only for experimental native-bridge smoke"
  fi

  case ",$abi_list," in
    *,"$target_abi",*)
      echo "device primary ABI is $primary_abi; using supported secondary ABI $target_abi (abilist: $abi_list)"
      ;;
    *)
      die "device ABI list is ${abi_list:-unknown}, but target platform $ANDROID_TARGET_PLATFORM requires $target_abi"
      ;;
  esac
}

verify_apk_native_abis() {
  local apk="$1"
  local target_abi found_abis unexpected_abis
  target_abi="$(target_abi_for_platform)"
  require_command unzip

  found_abis="$(
    unzip -Z1 "$apk" 'lib/*/*.so' 2>/dev/null \
      | awk -F/ '{print $2}' \
      | sort -u
  )"
  [ -n "$found_abis" ] || die "APK contains no native libraries: $apk"

  if ! printf '%s\n' "$found_abis" | grep -Fxq "$target_abi"; then
    die "APK does not contain required ABI $target_abi; found: $(printf '%s' "$found_abis" | tr '\n' ' ')"
  fi

  unexpected_abis="$(
    printf '%s\n' "$found_abis" \
      | awk -v target="$target_abi" '$0 != target { print }'
  )"
  if [ -n "$unexpected_abis" ]; then
    die "APK contains non-target native ABI(s): $(printf '%s' "$unexpected_abis" | tr '\n' ' '); target is $target_abi"
  fi

  echo "APK native ABI verified: $target_abi"
}

count_tombstones() {
  adb_shell "ls /data/tombstones/tombstone_* 2>/dev/null | wc -l" \
    | tr -d '\r[:space:]' || true
}

is_uint() {
  [[ "${1:-}" =~ ^[0-9]+$ ]]
}

log_result_value() {
  local label="$1"
  local line
  line="$(grep -F "FCB $label result:" "$LOGCAT_FILE" | tail -n 1)"
  [ -n "$line" ] || return 1
  printf '%s\n' "${line##*FCB $label result: }"
}

seed_gradle_cache() {
  local host_home="$1"
  local host_dists="$host_home/.gradle/wrapper/dists"
  local host_modules="$host_home/.gradle/caches/modules-2"
  local work_dists="$GRADLE_USER_HOME/wrapper/dists"
  local work_modules="$GRADLE_USER_HOME/caches/modules-2"

  if find "$work_dists" -mindepth 3 -maxdepth 3 -type d -name 'gradle-*' 2>/dev/null | grep -q .; then
    :
  elif [ -d "$host_dists" ]; then
    rm -rf "$work_dists"
    mkdir -p "$(dirname "$work_dists")"
    cp -a "$host_dists" "$work_dists"
  fi

  if [ -d "$host_modules" ]; then
    mkdir -p "$(dirname "$work_modules")"
    mkdir -p "$work_modules"
    if command -v rsync >/dev/null 2>&1; then
      rsync -a --ignore-existing "$host_modules"/ "$work_modules"/
    else
      cp -Rpn "$host_modules"/. "$work_modules"/
    fi
  fi
}

add_dart_define() {
  local key="$1"
  local value="$2"
  if [ -n "$value" ]; then
    DART_DEFINES+=(--dart-define "$key=$value")
  fi
}

build_apk() {
  require_file "$FLUTTER_BIN"
  require_dir "$ENGINE_SRC_DIR"
  require_dir "$APP_DIR"

  DART_DEFINES=()
  add_dart_define FCB_SERVER_URL "$SERVER_URL"
  add_dart_define FCB_APP_ID "$APP_ID"
  add_dart_define FCB_PUBLIC_KEY "$PUBLIC_KEY"
  add_dart_define FCB_RELEASE_VERSION "$RELEASE_VERSION"
  add_dart_define FCB_CHANNEL "$CHANNEL"
  add_dart_define FCB_PLATFORM "$PLATFORM"
  add_dart_define FCB_ARCH "$ARCH"
  add_dart_define FCB_CACHE_DIR "$CACHE_DIR"
  add_dart_define FCB_BASELINE_ARTIFACT "$BASELINE_ARTIFACT"
  add_dart_define FCB_AUTO_INSTALL_ON_STARTUP "$AUTO_INSTALL_ON_STARTUP"

  local host_home="${HOME:-$WORKDIR/host-home}"
  export ANDROID_HOME="${ANDROID_HOME:-$ENGINE_SRC_DIR/flutter/third_party/android_tools/sdk}"
  export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
  export ANDROID_USER_HOME="${ANDROID_USER_HOME:-$WORKDIR/android-home}"
  export HOME="${FCB_FLUTTER_HOME:-$WORKDIR/flutter-home}"
  export PUB_CACHE="${PUB_CACHE:-$WORKDIR/pub-cache}"
  export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$WORKDIR/gradle-home}"
  export FLUTTER_ROOT="${FLUTTER_ROOT:-$ROOT_DIR/vendor/flutter}"
  export FCB_ENABLE_AOT_DISPATCH="${FCB_ENABLE_AOT_DISPATCH:-1}"
  export FCB_AOT_PROBE_ALLOWLIST="$AOT_PROBE_ALLOWLIST"
  export FCB_ANDROID_ABI_FILTER="${FCB_ANDROID_ABI_FILTER:-$(target_abi_for_platform)}"
  export ORG_GRADLE_PROJECT_fcbAndroidAbiFilter="$FCB_ANDROID_ABI_FILTER"

  mkdir -p "$ANDROID_USER_HOME" "$HOME" "$PUB_CACHE" "$GRADLE_USER_HOME"
  seed_gradle_cache "$host_home"

  (
    cd "$APP_DIR"
    if [ "$FLUTTER_CLEAN" = "1" ]; then
      run "$FLUTTER_BIN" --no-version-check clean
    fi
    run "$FLUTTER_BIN" --no-version-check pub get
    local build_args=(
      --no-version-check
      build
      apk
      --release \
      --no-tree-shake-icons \
      --extra-gen-snapshot-options="$EXTRA_GEN_SNAPSHOT_OPTIONS" \
      --target-platform "$ANDROID_TARGET_PLATFORM" \
      --local-engine-src-path "$ENGINE_SRC_DIR" \
      --local-engine-host "$LOCAL_ENGINE_HOST" \
      --local-engine "$ENGINE_OUT_NAME"
    )
    if [ "${#DART_DEFINES[@]}" -gt 0 ]; then
      build_args+=("${DART_DEFINES[@]}")
    fi
    run "$FLUTTER_BIN" "${build_args[@]}"
  )
}

install_and_launch() {
  require_file "$ADB"

  local apk="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
  require_file "$apk"
  verify_apk_native_abis "$apk"

  run adb_cmd start-server
  adb_cmd wait-for-device
  check_device_abi

  local before_tombstones
  before_tombstones="$(count_tombstones)"
  echo "tombstones before launch: ${before_tombstones:-unknown}"

  if [ "$SKIP_INSTALL" != "1" ]; then
    adb_cmd uninstall "$PKG" >/dev/null 2>&1 || true
    run adb_cmd install -r "$apk"
  fi

  if [ "$INSTALL_BYTECODE_PATCH" = "1" ]; then
    require_file "$INSTALL_PATCH_SCRIPT"
    (
      export FCB_ADB="$ADB"
      export FCB_ANDROID_PACKAGE="$PKG"
      export FCB_WORKDIR="$WORKDIR"
      run "$INSTALL_PATCH_SCRIPT"
    )
  fi

  adb_cmd logcat -c || true
  run adb_shell am force-stop "$PKG"
  run adb_shell am start -n "$PKG/.MainActivity"
  sleep "${FCB_LAUNCH_WAIT_SECONDS:-12}"

  local pid
  pid="$(adb_shell pidof "$PKG" | tr -d '\r[:space:]' || true)"
  if [ -z "$pid" ]; then
    adb_cmd logcat -d -v time >"$LOGCAT_FILE" || true
    tail -n 200 "$LOGCAT_FILE" >&2 || true
    die "app process is not running after launch"
  fi

  adb_cmd logcat -d -v time >"$LOGCAT_FILE" || true

  if grep -Eiq 'AndroidRuntime|FATAL|SIGSEGV|SIGILL|tombstone|segmentation fault' "$LOGCAT_FILE"; then
    grep -Ein 'fcb|flutter|dart|AndroidRuntime|FATAL|SIGSEGV|SIGILL|crash|tombstone|updater|patch|libflutter|libapp' \
      "$LOGCAT_FILE" >&2 || true
    die "crash-like entries found in logcat; full log: $LOGCAT_FILE"
  fi

  if [ "$INSTALL_BYTECODE_PATCH" = "1" ] &&
      ! grep -Eq 'FCB VM bytecode patch registered|FCB VM bytecode patch [0-9]+ selected' "$LOGCAT_FILE"; then
    grep -Ein 'fcb|updater|patch|bytecode|libflutter|flutter|dart' \
      "$LOGCAT_FILE" >&2 || true
    die "bytecode patch was installed but VM registration was not observed; full log: $LOGCAT_FILE"
  fi

  local expected_counter="$EXPECTED_INITIAL_COUNTER"
  if [ -z "$expected_counter" ]; then
    if [ "$INSTALL_BYTECODE_PATCH" = "1" ]; then
      expected_counter="${FCB_PATCH_RETURN_VALUE:-42}"
    else
      expected_counter="1"
    fi
  fi
  if ! grep -Fq "FCB initialCounterValue result: $expected_counter" "$LOGCAT_FILE"; then
    grep -Ein 'fcb|initialCounterValue|counter|updater|patch|bytecode|libflutter|flutter|dart' \
      "$LOGCAT_FILE" >&2 || true
    die "expected initialCounterValue result $expected_counter was not observed; full log: $LOGCAT_FILE"
  fi

  local expected_adjusted_counter="$EXPECTED_ADJUSTED_COUNTER"
  if [ -z "$expected_adjusted_counter" ]; then
    if [ "$INSTALL_BYTECODE_PATCH" = "1" ] &&
        [ "${FCB_INCLUDE_ARG_FUNCTION_PATCH:-1}" = "1" ]; then
      expected_adjusted_counter="${FCB_PATCH_RETURN_VALUE:-42}"
    else
      expected_adjusted_counter="8"
    fi
  fi
  if ! grep -Fq "FCB adjustedCounterValue result: $expected_adjusted_counter" "$LOGCAT_FILE"; then
    grep -Ein 'fcb|adjustedCounterValue|initialCounterValue|counter|updater|patch|bytecode|libflutter|flutter|dart' \
      "$LOGCAT_FILE" >&2 || true
    die "expected adjustedCounterValue result $expected_adjusted_counter was not observed; full log: $LOGCAT_FILE"
  fi

  local expected_static_counter="$EXPECTED_STATIC_COUNTER"
  if [ -z "$expected_static_counter" ]; then
    if [ "$INSTALL_BYTECODE_PATCH" = "1" ] &&
        [ "${FCB_INCLUDE_STATIC_METHOD_PATCH:-1}" = "1" ]; then
      expected_static_counter="${FCB_PATCH_RETURN_VALUE:-42}"
    else
      expected_static_counter="7"
    fi
  fi
  if ! grep -Fq "FCB staticCounterValue result: $expected_static_counter" "$LOGCAT_FILE"; then
    grep -Ein 'fcb|staticCounterValue|initialCounterValue|counter|updater|patch|bytecode|libflutter|flutter|dart' \
      "$LOGCAT_FILE" >&2 || true
    die "expected staticCounterValue result $expected_static_counter was not observed; full log: $LOGCAT_FILE"
  fi

  local expected_status_label="$EXPECTED_STATUS_LABEL"
  if [ -z "$expected_status_label" ]; then
    if [ "$INSTALL_BYTECODE_PATCH" = "1" ] &&
        [ "${FCB_INCLUDE_STRING_FUNCTION_PATCH:-1}" = "1" ]; then
      expected_status_label="${FCB_PATCH_STRING_VALUE:-patched}"
    else
      expected_status_label="base"
    fi
  fi
  if ! grep -Fq "FCB statusLabel result: $expected_status_label" "$LOGCAT_FILE"; then
    grep -Ein 'fcb|statusLabel|staticCounterValue|initialCounterValue|counter|updater|patch|bytecode|libflutter|flutter|dart' \
      "$LOGCAT_FILE" >&2 || true
    die "expected statusLabel result $expected_status_label was not observed; full log: $LOGCAT_FILE"
  fi

  local expected_widget_tree_label="$EXPECTED_WIDGET_TREE_LABEL"
  if [ -z "$expected_widget_tree_label" ]; then
    if [ "$INSTALL_BYTECODE_PATCH" = "1" ] &&
        [ "${FCB_INCLUDE_WIDGET_TREE_FUNCTION_PATCH:-1}" = "1" ]; then
      expected_widget_tree_label="${FCB_PATCH_WIDGET_TREE_VALUE:-patched widget tree}"
    else
      expected_widget_tree_label="baseline widget tree"
    fi
  fi
  if ! grep -Fq "FCB widgetTreeLabel result: $expected_widget_tree_label" "$LOGCAT_FILE"; then
    grep -Ein 'fcb|widgetTreeLabel|statusLabel|staticCounterValue|initialCounterValue|counter|updater|patch|bytecode|libflutter|flutter|dart' \
      "$LOGCAT_FILE" >&2 || true
    die "expected widgetTreeLabel result $expected_widget_tree_label was not observed; full log: $LOGCAT_FILE"
  fi

  local expected_field_status_label="$EXPECTED_FIELD_STATUS_LABEL"
  if [ -z "$expected_field_status_label" ]; then
    if [ "$INSTALL_BYTECODE_PATCH" = "1" ] &&
        [ "${FCB_INCLUDE_FIELD_FUNCTION_PATCH:-1}" = "1" ]; then
      expected_field_status_label="patched-field"
    else
      expected_field_status_label="base-field"
    fi
  fi
  if ! grep -Fq "FCB fieldStatusLabel result: $expected_field_status_label" "$LOGCAT_FILE"; then
    grep -Ein 'fcb|fieldStatusLabel|statusLabel|staticCounterValue|initialCounterValue|counter|updater|patch|bytecode|libflutter|flutter|dart' \
      "$LOGCAT_FILE" >&2 || true
    die "expected fieldStatusLabel result $expected_field_status_label was not observed; full log: $LOGCAT_FILE"
  fi

  local expected_quad_counter="$EXPECTED_QUAD_COUNTER"
  if [ -z "$expected_quad_counter" ]; then
    if [ "$INSTALL_BYTECODE_PATCH" = "1" ] &&
        [ "${FCB_INCLUDE_QUAD_FUNCTION_PATCH:-1}" = "1" ]; then
      expected_quad_counter="${FCB_PATCH_RETURN_VALUE:-42}"
    else
      expected_quad_counter="10"
    fi
  fi
  if ! grep -Fq "FCB quadCounterValue result: $expected_quad_counter" "$LOGCAT_FILE"; then
    grep -Ein 'fcb|quadCounterValue|statusLabel|staticCounterValue|initialCounterValue|counter|updater|patch|bytecode|libflutter|flutter|dart' \
      "$LOGCAT_FILE" >&2 || true
    die "expected quadCounterValue result $expected_quad_counter was not observed; full log: $LOGCAT_FILE"
  fi

  if ! grep -Fq "FCB setState applied widget state" "$LOGCAT_FILE"; then
    grep -Ein 'fcb|setState|widgetTreeLabel|statusLabel|counter|updater|patch|bytecode|flutter|dart' \
      "$LOGCAT_FILE" >&2 || true
    die "setState application was not observed; full log: $LOGCAT_FILE"
  fi

  if ! grep -Fq "FCB plugin method channel cacheDir result:" "$LOGCAT_FILE" ||
      grep -Fq "FCB plugin method channel cacheDir result: unavailable" "$LOGCAT_FILE"; then
    grep -Ein 'fcb|method channel|cacheDir|getPaths|updater|patch|bytecode|flutter|dart' \
      "$LOGCAT_FILE" >&2 || true
    die "plugin method channel cacheDir was not observed; full log: $LOGCAT_FILE"
  fi

  local after_tombstones
  after_tombstones="$(count_tombstones)"
  if is_uint "$before_tombstones" && is_uint "$after_tombstones" &&
      [ "$after_tombstones" -gt "$before_tombstones" ]; then
    die "tombstone count increased from $before_tombstones to $after_tombstones; full log: $LOGCAT_FILE"
  fi

  {
    echo "mode: $([ "$INSTALL_BYTECODE_PATCH" = "1" ] && echo patch || echo nopatch)"
    echo "pid: $pid"
    echo "tombstones_before: ${before_tombstones:-unknown}"
    echo "tombstones_after: ${after_tombstones:-unknown}"
    echo "initialCounterValue_expected: $expected_counter"
    echo "initialCounterValue_observed: $(log_result_value initialCounterValue)"
    echo "adjustedCounterValue_expected: $expected_adjusted_counter"
    echo "adjustedCounterValue_observed: $(log_result_value adjustedCounterValue)"
    echo "staticCounterValue_expected: $expected_static_counter"
    echo "staticCounterValue_observed: $(log_result_value staticCounterValue)"
    echo "statusLabel_expected: $expected_status_label"
    echo "statusLabel_observed: $(log_result_value statusLabel)"
    echo "widgetTreeLabel_expected: $expected_widget_tree_label"
    echo "widgetTreeLabel_observed: $(log_result_value widgetTreeLabel)"
    echo "setState_observed: true"
    echo "methodChannelCacheDir_observed: $(log_result_value 'plugin method channel cacheDir')"
    echo "fieldStatusLabel_expected: $expected_field_status_label"
    echo "fieldStatusLabel_observed: $(log_result_value fieldStatusLabel)"
    echo "quadCounterValue_expected: $expected_quad_counter"
    echo "quadCounterValue_observed: $(log_result_value quadCounterValue)"
    echo "logcat: $LOGCAT_FILE"
  } >"$RESULT_FILE"

  echo "pid: $pid"
  echo "tombstones after launch: ${after_tombstones:-unknown}"
  echo "logcat: $LOGCAT_FILE"
  echo "result: $RESULT_FILE"
}

main() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
  fi

  mkdir -p "$LOG_DIR"

  verify_local_engine_artifacts

  if [ "$SKIP_BUILD" != "1" ]; then
    build_apk
  else
    echo "skipping Flutter APK build because FCB_SKIP_BUILD=1"
  fi

  verify_app_snapshot
  install_and_launch
}

main "$@"
