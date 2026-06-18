#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE_ROOT_DIR="$ROOT_DIR/vendor/flutter/engine/src"
ENGINE_SRC_DIR="$ENGINE_ROOT_DIR/flutter"
GN_SCRIPT="$ENGINE_SRC_DIR/tools/gn"
DEPOT_TOOLS_DIR="$ROOT_DIR/vendor/depot_tools"
DEPOT_HOME="${FCB_DEPOT_HOME:-$ROOT_DIR/target/fcb/depot-home}"
VPYTHON_ROOT="${FCB_VPYTHON_ROOT:-$DEPOT_HOME/vpython-root}"
GN_RUNNER=()

ANDROID_CPU="${FCB_ANDROID_CPU:-arm64}"
RUNTIME_MODE="${FCB_RUNTIME_MODE:-release}"
SKIP_NINJA="${FCB_SKIP_NINJA:-0}"
NINJA_TARGET="${FCB_NINJA_TARGET:-flutter/shell/platform/android:flutter_shell_native}"

usage() {
  cat <<USAGE
Usage:
  FCB_UPDATER_STATICLIB=/abs/path/libfcb_updater.a $0

Environment:
  FCB_ANDROID_CPU          Engine Android CPU: arm64, arm, x64, x86. Default: arm64
  FCB_RUNTIME_MODE         Engine runtime mode. Default: release
  FCB_UPDATER_STATICLIB    Existing ABI-matching Rust staticlib.
  FCB_BUILD_UPDATER        Build updater with cargo-ndk when staticlib is not set. Default: 1
  FCB_UPDATER_RUSTFLAGS    Rust flags for the updater staticlib.
                           Default: current RUSTFLAGS plus -C panic=abort
  FCB_UNWIND_STATICLIB     Existing ABI-matching Android libunwind.a.
  FCB_SKIP_GN              Skip GN generation. Default: 0
  FCB_SKIP_NINJA           Skip ninja build after GN generation. Default: 0
  FCB_SKIP_POSTPROCESS     Skip local-engine artifact refresh after ninja.
                           Default: 0
  FCB_SKIP_HOST_GEN_SNAPSHOT
                           Skip host gen_snapshot refresh. Default: 0
  FCB_NO_PREBUILT_DART_SDK Build Dart SDK artifacts from source instead of
                           using Engine prebuilt Dart SDK. Default: 0
  FCB_SYNC_ANDROID_JNILIBS Copy cargo-ndk libfcb_updater.so into the Flutter
                           package Android jniLibs for the selected ABI.
                           Default: 1
  FCB_LOCAL_ENGINE_HOST    Host Engine output used by Flutter builds.
                           Default: host_release
  FCB_SKIP_ENGINE_DEPS_CHECK
                           Skip preflight checks for Engine gclient deps. Default: 0
  FCB_DRY_RUN              Print commands without executing sync/GN/ninja/cargo. Default: 0
  FCB_DEPOT_HOME           HOME used for depot_tools/vpython cache.
  FCB_VPYTHON_ROOT         vpython virtualenv root.
  FCB_NINJA_TARGET         Ninja target. Default: $NINJA_TARGET
  FCB_GN_EXTRA_ARGS        Extra GN args, shell-tokenized.
  FCB_NINJA_EXTRA_ARGS     Extra ninja args, shell-tokenized.
USAGE
}

die() {
  echo "error: $*" >&2
  exit 1
}

run() {
  echo "+ $*" >&2
  if [ "${FCB_DRY_RUN:-0}" = "1" ]; then
    return 0
  fi
  "$@"
}

require_file() {
  [ -f "$1" ] || die "missing file: $1"
}

require_dir() {
  [ -d "$1" ] || die "missing directory: $1"
}

validate_engine_deps() {
  if [ "${FCB_SKIP_ENGINE_DEPS_CHECK:-0}" = "1" ]; then
    return 0
  fi

  local missing=0
  local path
  for path in \
    "$ENGINE_SRC_DIR/third_party/skia" \
    "$ENGINE_SRC_DIR/third_party/gn/gn"; do
    if [ ! -e "$path" ]; then
      echo "missing Engine dependency: $path" >&2
      missing=1
    fi
  done

  if ! compgen -G "$ENGINE_SRC_DIR/third_party/android_tools/sdk/ndk/*/toolchains/llvm/prebuilt/*/sysroot/usr/include/stdlib.h" >/dev/null; then
    echo "missing Engine dependency: $ENGINE_SRC_DIR/third_party/android_tools/sdk/ndk/*/toolchains/llvm/prebuilt/*/sysroot/usr/include/stdlib.h" >&2
    missing=1
  fi

  if [ "$missing" != "0" ]; then
    cat >&2 <<EOF
Engine dependencies are incomplete. Populate the embedded Engine checkout before
running GN, for example:

  scripts/bootstrap_engine_min_deps.sh

Then rerun:

  scripts/build_android_engine.sh
EOF
    exit 1
  fi
}

android_abi_for_cpu() {
  case "$1" in
    arm64) echo "arm64-v8a" ;;
    arm) echo "armeabi-v7a" ;;
    x64) echo "x86_64" ;;
    x86) echo "x86" ;;
    *) die "unsupported FCB_ANDROID_CPU: $1" ;;
  esac
}

android_jar_abi_for_cpu() {
  case "$1" in
    arm64) echo "arm64_v8a" ;;
    arm) echo "armeabi_v7a" ;;
    x64) echo "x86_64" ;;
    x86) echo "x86" ;;
    *) die "unsupported FCB_ANDROID_CPU: $1" ;;
  esac
}

android_triple_for_cpu() {
  case "$1" in
    arm64) echo "aarch64-linux-android" ;;
    arm) echo "armv7-linux-androideabi" ;;
    x64) echo "x86_64-linux-android" ;;
    x86) echo "i686-linux-android" ;;
    *) die "unsupported FCB_ANDROID_CPU: $1" ;;
  esac
}

android_clang_lib_arch_for_cpu() {
  case "$1" in
    arm64) echo "aarch64" ;;
    arm) echo "arm" ;;
    x64) echo "x86_64" ;;
    x86) echo "i386" ;;
    *) die "unsupported FCB_ANDROID_CPU: $1" ;;
  esac
}

ndk_prebuilt_host_tag() {
  local base="$ENGINE_SRC_DIR/third_party/android_tools/sdk/ndk"
  local preferred=()
  case "$(uname -s)" in
    Darwin) preferred=(darwin-x86_64 darwin-arm64) ;;
    Linux) preferred=(linux-x86_64) ;;
    *) preferred=() ;;
  esac

  local tag
  for tag in "${preferred[@]}"; do
    if compgen -G "$base/*/toolchains/llvm/prebuilt/$tag/sysroot/usr/include/stdlib.h" >/dev/null; then
      echo "$tag"
      return 0
    fi
  done

  local match
  while IFS= read -r match; do
    echo "$(basename "$(dirname "$(dirname "$(dirname "$match")")")")"
    return 0
  done < <(compgen -G "$base/*/toolchains/llvm/prebuilt/*/sysroot/usr/include/stdlib.h" | sort)

  die "missing Android NDK prebuilt sysroot under: $base/*/toolchains/llvm/prebuilt/*"
}

gn_out_name() {
  local cpu="$1"
  local mode="$2"
  local name="android_${mode}"

  if [ "$cpu" != "arm" ]; then
    name="${name}_${cpu}"
  fi

  echo "$name"
}

resolve_unwind_staticlib() {
  local configured="${FCB_UNWIND_STATICLIB:-}"
  if [ -n "$configured" ]; then
    case "$configured" in
      /*) ;;
      *) configured="$(cd "$(dirname "$configured")" && pwd)/$(basename "$configured")" ;;
    esac
    require_file "$configured"
    echo "$configured"
    return 0
  fi

  local arch host_tag pattern
  arch="$(android_clang_lib_arch_for_cpu "$ANDROID_CPU")"
  host_tag="$(ndk_prebuilt_host_tag)"
  pattern="$ENGINE_SRC_DIR/third_party/android_tools/sdk/ndk/*/toolchains/llvm/prebuilt/$host_tag/lib/clang/*/lib/linux/$arch/libunwind.a"

  local matches=()
  while IFS= read -r path; do
    matches+=("$path")
  done < <(compgen -G "$pattern" | sort)

  if [ "${#matches[@]}" -eq 0 ]; then
    die "missing Android libunwind.a matching: $pattern"
  fi

  local last_index=$((${#matches[@]} - 1))
  echo "${matches[$last_index]}"
}

parse_extra_args() {
  local var_name="$1"
  local value="${!var_name:-}"
  [ -z "$value" ] && return 0

  # Intentionally tokenizes trusted local env vars so quoted paths are preserved.
  eval "set -- $value"
  printf '%s\n' "$@"
}

strip_tool_for_cpu() {
  local triple ndk_strip host_tag
  triple="$(android_triple_for_cpu "$ANDROID_CPU")"
  if command -v "${triple}-strip" >/dev/null 2>&1; then
    echo "${triple}-strip"
    return 0
  fi
  host_tag="$(ndk_prebuilt_host_tag)"
  while IFS= read -r ndk_strip; do
    if [ -x "$ndk_strip" ]; then
      echo "$ndk_strip"
      return 0
    fi
  done < <(compgen -G "$ENGINE_SRC_DIR/third_party/android_tools/sdk/ndk/*/toolchains/llvm/prebuilt/$host_tag/bin/llvm-strip" | sort -r)
  if command -v llvm-strip >/dev/null 2>&1; then
    echo "llvm-strip"
    return 0
  fi
  if command -v strip >/dev/null 2>&1; then
    echo "strip"
    return 0
  fi
  die "strip tool is required to refresh lib.stripped/libflutter.so"
}

refresh_android_engine_artifacts() {
  local out_dir="$1"
  local jar_abi jar_path strip_tool tmp_dir

  if [ "${FCB_SKIP_POSTPROCESS:-0}" = "1" ]; then
    echo "skipping Engine artifact postprocess because FCB_SKIP_POSTPROCESS=1"
    return 0
  fi

  require_file "$out_dir/libflutter.so"
  mkdir -p "$out_dir/lib.stripped"
  run cp "$out_dir/libflutter.so" "$out_dir/lib.stripped/libflutter.so"
  strip_tool="$(strip_tool_for_cpu)"
  run "$strip_tool" --strip-unneeded "$out_dir/lib.stripped/libflutter.so"

  jar_abi="$(android_jar_abi_for_cpu "$ANDROID_CPU")"
  jar_path="$out_dir/${jar_abi}_${RUNTIME_MODE}.jar"
  require_file "$jar_path"
  command -v zip >/dev/null 2>&1 || die "zip is required to update $jar_path"

  tmp_dir="$(mktemp -d /tmp/fcb-engine-jar.XXXXXX)"
  mkdir -p "$tmp_dir/lib/$(android_abi_for_cpu "$ANDROID_CPU")"
  cp "$out_dir/lib.stripped/libflutter.so" \
    "$tmp_dir/lib/$(android_abi_for_cpu "$ANDROID_CPU")/libflutter.so"
  (
    cd "$tmp_dir"
    run zip -q -u "$jar_path" \
      "lib/$(android_abi_for_cpu "$ANDROID_CPU")/libflutter.so"
  )
  rm -rf "$tmp_dir"

  run ninja -C "$out_dir" clang_x64/gen_snapshot
  require_file "$out_dir/clang_x64/gen_snapshot"
  run cp "$out_dir/clang_x64/gen_snapshot" "$out_dir/gen_snapshot"
  run ninja -C "$out_dir" flutter/lib/snapshot:strong_platform
  require_file "$out_dir/flutter_patched_sdk/platform_strong.dill"
  rm -rf "$out_dir/flutter_patched_sdk_product"
  cp -R "$out_dir/flutter_patched_sdk" "$out_dir/flutter_patched_sdk_product"
  require_file "$out_dir/flutter_patched_sdk_product/platform_strong.dill"
}

refresh_host_gen_snapshot() {
  local host_out_name="${FCB_LOCAL_ENGINE_HOST:-host_release}"
  local host_out_dir="$ENGINE_ROOT_DIR/out/$host_out_name"

  if [ "${FCB_SKIP_HOST_GEN_SNAPSHOT:-0}" = "1" ]; then
    echo "skipping host gen_snapshot refresh because FCB_SKIP_HOST_GEN_SNAPSHOT=1"
    return 0
  fi

  local host_gn_cmd=("${GN_RUNNER[@]}" --runtime-mode "$RUNTIME_MODE")
  if [ "${FCB_NO_PREBUILT_DART_SDK:-0}" = "1" ]; then
    host_gn_cmd+=(--no-prebuilt-dart-sdk)
  fi
  run "${host_gn_cmd[@]}"
  run ninja -C "$host_out_dir" gen_snapshot
  run ninja -C "$host_out_dir" flutter/lib/snapshot:strong_platform
  rm -rf "$host_out_dir/flutter_patched_sdk_product"
  cp -R "$host_out_dir/flutter_patched_sdk" "$host_out_dir/flutter_patched_sdk_product"
  run ninja -C "$host_out_dir" flutter/flutter_frontend_server:frontend_server
  require_file "$host_out_dir/gen_snapshot"
  require_file "$host_out_dir/flutter_patched_sdk/platform_strong.dill"
  require_file "$host_out_dir/flutter_patched_sdk_product/platform_strong.dill"
  require_file "$host_out_dir/gen/frontend_server_aot.dart.snapshot"
}

normalize_gn_arg() {
  local arg="$1"
  if [[ "$arg" == *=* ]]; then
    local key="${arg%%=*}"
    local value="${arg#*=}"
    case "$value" in
      true|false|[0-9]*|\"*|\'*|\[*)
        printf '%s\n' "$arg"
        ;;
      *)
        value="${value//\\/\\\\}"
        value="${value//\"/\\\"}"
        printf '%s="%s"\n' "$key" "$value"
        ;;
    esac
  else
    printf '%s\n' "$arg"
  fi
}

resolve_updater_staticlib() {
  local configured="${FCB_UPDATER_STATICLIB:-}"
  if [ -n "$configured" ]; then
    case "$configured" in
      /*) ;;
      *) configured="$(cd "$(dirname "$configured")" && pwd)/$(basename "$configured")" ;;
    esac
    require_file "$configured"
    echo "$configured"
    return 0
  fi

  if [ "${FCB_BUILD_UPDATER:-1}" != "1" ]; then
    die "FCB_UPDATER_STATICLIB is required when FCB_BUILD_UPDATER!=1"
  fi

  local abi triple
  abi="$(android_abi_for_cpu "$ANDROID_CPU")"
  triple="$(android_triple_for_cpu "$ANDROID_CPU")"
  local out_dir="$ROOT_DIR/target/fcb/android-updater"
  local cargo_target_dir="${CARGO_TARGET_DIR:-$ROOT_DIR/target}"
  local copied_lib="$out_dir/$abi/libfcb_updater.a"
  local target_lib="$cargo_target_dir/$triple/release/libfcb_updater.a"
  local updater_rustflags="${FCB_UPDATER_RUSTFLAGS:-${RUSTFLAGS:-} -C panic=abort}"

  if [ "${FCB_DRY_RUN:-0}" != "1" ]; then
    command -v cargo-ndk >/dev/null 2>&1 ||
      die "cargo-ndk is required to build libfcb_updater.a. Install with: cargo install cargo-ndk"
  fi

  run env RUSTFLAGS="$updater_rustflags" cargo ndk \
    --manifest-path "$ROOT_DIR/Cargo.toml" \
    -t "$abi" \
    -o "$out_dir" \
    build \
    -p fcb_updater \
    --release >&2 || return $?

  local lib="$target_lib"
  if [ -f "$copied_lib" ]; then
    lib="$copied_lib"
  fi

  if [ "${FCB_DRY_RUN:-0}" != "1" ]; then
    require_file "$lib"
  fi
  echo "$lib"
}

sync_android_jnilibs() {
  if [ "${FCB_SYNC_ANDROID_JNILIBS:-1}" != "1" ]; then
    return 0
  fi

  local abi="$1"
  local so_path="$ROOT_DIR/target/fcb/android-updater/$abi/libfcb_updater.so"
  local dest="$ROOT_DIR/packages/fcb_code_push/android/src/main/jniLibs/$abi/libfcb_updater.so"
  if [ ! -f "$so_path" ]; then
    echo "warning: updater cdylib not found, skipping jniLibs sync: $so_path" >&2
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  run cp "$so_path" "$dest"
}

main() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
  fi

  require_dir "$ENGINE_SRC_DIR"
  require_file "$GN_SCRIPT"

  if [ -d "$DEPOT_TOOLS_DIR" ]; then
    export PATH="$DEPOT_TOOLS_DIR:$PATH"
  fi

  if command -v vpython3 >/dev/null 2>&1; then
    GN_RUNNER=("$GN_SCRIPT")
  else
    command -v python3 >/dev/null 2>&1 || die "python3 is required to run $GN_SCRIPT"
    GN_RUNNER=(python3 "$GN_SCRIPT")
  fi

  if [ "${FCB_SKIP_GN:-0}" != "1" ]; then
    validate_engine_deps
  fi

  local updater_staticlib unwind_staticlib
  updater_staticlib="$(resolve_updater_staticlib)"
  unwind_staticlib="$(resolve_unwind_staticlib)"
  sync_android_jnilibs "$(android_abi_for_cpu "$ANDROID_CPU")"

  if [ -d "$DEPOT_TOOLS_DIR" ]; then
    mkdir -p "$DEPOT_HOME" "$VPYTHON_ROOT"
    export HOME="$DEPOT_HOME"
    export VPYTHON_VIRTUALENV_ROOT="$VPYTHON_ROOT"
  fi

  local out_name out_dir
  out_name="$(gn_out_name "$ANDROID_CPU" "$RUNTIME_MODE")"
  out_dir="$ENGINE_ROOT_DIR/out/$out_name"

  local gn_cmd=(
    "${GN_RUNNER[@]}"
    --android
    --android-cpu "$ANDROID_CPU"
    --runtime-mode "$RUNTIME_MODE"
    --gn-args "fcb_enable_code_push=true"
    --gn-args "fcb_updater_staticlib=\"$updater_staticlib\""
    --gn-args "fcb_unwind_staticlib=\"$unwind_staticlib\""
  )
  if [ "${FCB_NO_PREBUILT_DART_SDK:-0}" = "1" ]; then
    gn_cmd+=(--no-prebuilt-dart-sdk)
  fi

  while IFS= read -r arg; do
    gn_cmd+=(--gn-args "$(normalize_gn_arg "$arg")")
  done < <(parse_extra_args FCB_GN_EXTRA_ARGS)

  if [ "${FCB_SKIP_GN:-0}" != "1" ]; then
    run "${gn_cmd[@]}"
  else
    echo "skipping GN generation because FCB_SKIP_GN=1"
  fi

  echo "Engine out dir: $out_dir"
  echo "Updater staticlib: $updater_staticlib"
  echo "Unwind staticlib: $unwind_staticlib"

  if [ "$SKIP_NINJA" = "1" ]; then
    echo "skipping ninja because FCB_SKIP_NINJA=1"
    exit 0
  fi

  if [ "${FCB_DRY_RUN:-0}" != "1" ]; then
    require_dir "$out_dir"
  fi

  local ninja_cmd=(ninja -C "$out_dir" "$NINJA_TARGET")
  while IFS= read -r arg; do
    ninja_cmd+=("$arg")
  done < <(parse_extra_args FCB_NINJA_EXTRA_ARGS)

  run "${ninja_cmd[@]}"
  refresh_android_engine_artifacts "$out_dir"
  refresh_host_gen_snapshot
}

main "$@"
