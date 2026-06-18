#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADB="${FCB_ADB:-$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/android_tools/sdk/platform-tools/adb}"
PKG="${FCB_ANDROID_PACKAGE:-com.example.fcb_counter_app}"
PATCH_NUMBER="${FCB_PATCH_NUMBER:-1}"
RETURN_VALUE="${FCB_PATCH_RETURN_VALUE:-42}"
FUNCTION_ID="${FCB_FUNCTION_ID:-initialCounterValue}"
FUNCTION_ID_VARIANTS="${FCB_FUNCTION_ID_VARIANTS:-}"
PATCH_CODE_KIND="${FCB_PATCH_CODE_KIND:-const}"
PATCH_SOURCE_LOCATION="${FCB_PATCH_SOURCE_LOCATION:-package:fcb_counter_app/pricing_source.dart:1:1}"
ARG_FUNCTION_ID="${FCB_ARG_FUNCTION_ID:-adjustedCounterValue}"
INCLUDE_ARG_FUNCTION_PATCH="${FCB_INCLUDE_ARG_FUNCTION_PATCH:-${FCB_INCLUDE_ARGUMENT_FUNCTION_PATCH:-1}}"
STATIC_METHOD_ID="${FCB_STATIC_METHOD_ID:-PricingEngine.staticCounterValue}"
INCLUDE_STATIC_METHOD_PATCH="${FCB_INCLUDE_STATIC_METHOD_PATCH:-1}"
STRING_FUNCTION_ID="${FCB_STRING_FUNCTION_ID:-statusLabel}"
INCLUDE_STRING_FUNCTION_PATCH="${FCB_INCLUDE_STRING_FUNCTION_PATCH:-1}"
STRING_RETURN_VALUE="${FCB_PATCH_STRING_VALUE:-patched}"
WIDGET_TREE_FUNCTION_ID="${FCB_WIDGET_TREE_FUNCTION_ID:-widgetTreeLabel}"
INCLUDE_WIDGET_TREE_FUNCTION_PATCH="${FCB_INCLUDE_WIDGET_TREE_FUNCTION_PATCH:-1}"
WIDGET_TREE_RETURN_VALUE="${FCB_PATCH_WIDGET_TREE_VALUE:-patched widget tree}"
FIELD_FUNCTION_ID="${FCB_FIELD_FUNCTION_ID:-fieldStatusLabel}"
INCLUDE_FIELD_FUNCTION_PATCH="${FCB_INCLUDE_FIELD_FUNCTION_PATCH:-1}"
FIELD_NAME="${FCB_PATCH_FIELD_NAME:-patchLabel}"
QUAD_FUNCTION_ID="${FCB_QUAD_FUNCTION_ID:-quadCounterValue}"
INCLUDE_QUAD_FUNCTION_PATCH="${FCB_INCLUDE_QUAD_FUNCTION_PATCH:-1}"
RELEASE_VERSION="${FCB_RELEASE_VERSION:-1.0.0+1}"
WORKDIR="${FCB_WORKDIR:-$ROOT_DIR/target/fcb/android-arm64}"
case "$WORKDIR" in
  /*) ;;
  *) WORKDIR="$ROOT_DIR/$WORKDIR" ;;
esac

usage() {
  cat <<USAGE
Usage:
  $0

Environment:
  FCB_ADB                 adb path.
  FCB_ANDROID_PACKAGE     Android package. Default: com.example.fcb_counter_app
  FCB_PATCH_NUMBER        Installed patch number. Default: 1
  FCB_PATCH_RETURN_VALUE  Int returned by the bytecode patch. Default: 42
  FCB_FUNCTION_ID         Bytecode function id. Default: initialCounterValue
  FCB_PATCH_CODE_KIND     Code kind for FCB_FUNCTION_ID and variants: const, return_underflow, missing_arg, or invalid_opcode. Default: const
  FCB_PATCH_SOURCE_LOCATION
                           Source-map location written into manual bytecode functions.
  FCB_INCLUDE_ARG_FUNCTION_PATCH
                           Include adjustedCounterValue(int) patch. Default: 1
  FCB_INCLUDE_ARGUMENT_FUNCTION_PATCH
                           Backward-compatible alias for FCB_INCLUDE_ARG_FUNCTION_PATCH.
  FCB_ARG_FUNCTION_ID     One-arg function id. Default: adjustedCounterValue
  FCB_INCLUDE_STATIC_METHOD_PATCH
                           Include PricingEngine.staticCounterValue patch. Default: 1
  FCB_STATIC_METHOD_ID    Static method function id. Default: PricingEngine.staticCounterValue
  FCB_INCLUDE_STRING_FUNCTION_PATCH
                           Include statusLabel() string patch. Default: 1
  FCB_STRING_FUNCTION_ID  String function id. Default: statusLabel
  FCB_PATCH_STRING_VALUE  String returned by the string patch. Default: patched
  FCB_INCLUDE_WIDGET_TREE_FUNCTION_PATCH
                           Include widgetTreeLabel() patch. Default: 1
  FCB_WIDGET_TREE_FUNCTION_ID
                           Widget tree label function id. Default: widgetTreeLabel
  FCB_PATCH_WIDGET_TREE_VALUE
                           String returned by the widget tree patch. Default: patched widget tree
  FCB_INCLUDE_FIELD_FUNCTION_PATCH
                           Include fieldStatusLabel(PricingOffer) GetField patch. Default: 1
  FCB_FIELD_FUNCTION_ID   Field function id. Default: fieldStatusLabel
  FCB_PATCH_FIELD_NAME    Field name read by GetField. Default: patchLabel
  FCB_INCLUDE_QUAD_FUNCTION_PATCH
                           Include quadCounterValue(int,int,int,int) patch. Default: 1
  FCB_QUAD_FUNCTION_ID    Four-arg function id. Default: quadCounterValue
  FCB_RELEASE_VERSION     State release version. Default: 1.0.0+1
  FCB_WORKDIR             Local temp/log root. Default: target/fcb/android-arm64
  FCB_WRITE_PATCH_ONLY    Write local patch files only; do not use adb. Default: 0
USAGE
}

die() {
  echo "error: $*" >&2
  exit 1
}

run() {
  echo "+ $*" >&2
  "$@"
}

require_file() {
  [ -f "$1" ] || die "missing file: $1"
}

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  printf '%s' "$value"
}

append_unique_function_id() {
  local id="$1"
  local param_count="${2:-0}"
  local return_convention="${3:-unboxed_int64}"
  local constant_type="${4:-Int}"
  local constant_value="${5:-$RETURN_VALUE}"
  local code_kind="${6:-const}"
  local existing
  local index
  for index in "${!FUNCTION_IDS[@]}"; do
    existing="${FUNCTION_IDS[$index]}"
    [ "$existing" = "$id" ] && return 0
  done
  FUNCTION_IDS+=("$id")
  FUNCTION_PARAM_COUNTS+=("$param_count")
  FUNCTION_RETURN_CONVENTIONS+=("$return_convention")
  FUNCTION_CONSTANT_TYPES+=("$constant_type")
  FUNCTION_CONSTANT_VALUES+=("$constant_value")
  FUNCTION_CODE_KINDS+=("$code_kind")
  FUNCTION_FIELD_NAMES+=("")
}

append_unique_get_field_function_id() {
  local id="$1"
  local field_name="$2"
  local existing
  local index
  for index in "${!FUNCTION_IDS[@]}"; do
    existing="${FUNCTION_IDS[$index]}"
    [ "$existing" = "$id" ] && return 0
  done
  FUNCTION_IDS+=("$id")
  FUNCTION_PARAM_COUNTS+=("1")
  FUNCTION_RETURN_CONVENTIONS+=("tagged")
  FUNCTION_CONSTANT_TYPES+=("String")
  FUNCTION_CONSTANT_VALUES+=("$field_name")
  FUNCTION_CODE_KINDS+=("get_field")
  FUNCTION_FIELD_NAMES+=("$field_name")
}

append_unique_call_static_function_id() {
  local id="$1"
  local target_id="$2"
  local existing
  local index
  for index in "${!FUNCTION_IDS[@]}"; do
    existing="${FUNCTION_IDS[$index]}"
    [ "$existing" = "$id" ] && return 0
  done
  FUNCTION_IDS+=("$id")
  FUNCTION_PARAM_COUNTS+=("0")
  FUNCTION_RETURN_CONVENTIONS+=("tagged")
  FUNCTION_CONSTANT_TYPES+=("String")
  FUNCTION_CONSTANT_VALUES+=("$target_id")
  FUNCTION_CODE_KINDS+=("call_static")
  FUNCTION_FIELD_NAMES+=("")
}

adb_cmd() {
  "$ADB" "$@"
}

device_owner() {
  adb_cmd shell "stat -c '%u:%g' '/data/user/0/$PKG' 2>/dev/null" | tr -d '\r'
}

write_local_patch_files() {
  local out_dir="$1"
  local escaped_release
  escaped_release="$(json_escape "$RELEASE_VERSION")"

  case "$PATCH_CODE_KIND" in
    const|return_underflow|missing_arg|invalid_opcode) ;;
    *) die "unsupported FCB_PATCH_CODE_KIND: $PATCH_CODE_KIND" ;;
  esac

  mkdir -p "$out_dir"
  FUNCTION_IDS=()
  FUNCTION_PARAM_COUNTS=()
  FUNCTION_RETURN_CONVENTIONS=()
  FUNCTION_CONSTANT_TYPES=()
  FUNCTION_CONSTANT_VALUES=()
  FUNCTION_CODE_KINDS=()
  FUNCTION_FIELD_NAMES=()
  append_unique_function_id "$FUNCTION_ID" 0 unboxed_int64 Int "$RETURN_VALUE" "$PATCH_CODE_KIND"
  append_unique_function_id "package:fcb_counter_app/pricing_source.dart::$FUNCTION_ID" 0 unboxed_int64 Int "$RETURN_VALUE" "$PATCH_CODE_KIND"
  if [ "$INCLUDE_ARG_FUNCTION_PATCH" = "1" ]; then
    append_unique_function_id "$ARG_FUNCTION_ID" 1 unboxed_int64 Int "$RETURN_VALUE"
    append_unique_function_id "package:fcb_counter_app/pricing_source.dart::$ARG_FUNCTION_ID" 1 unboxed_int64 Int "$RETURN_VALUE"
  fi
  if [ "$INCLUDE_STATIC_METHOD_PATCH" = "1" ]; then
    append_unique_function_id "$STATIC_METHOD_ID" 0 unboxed_int64 Int "$RETURN_VALUE"
    append_unique_function_id "package:fcb_counter_app/pricing_source.dart::$STATIC_METHOD_ID" 0 unboxed_int64 Int "$RETURN_VALUE"
  fi
  if [ "$INCLUDE_STRING_FUNCTION_PATCH" = "1" ]; then
    append_unique_function_id "$STRING_FUNCTION_ID" 0 tagged String "$STRING_RETURN_VALUE"
    append_unique_function_id "package:fcb_counter_app/pricing_source.dart::$STRING_FUNCTION_ID" 0 tagged String "$STRING_RETURN_VALUE"
  fi
  if [ "$INCLUDE_WIDGET_TREE_FUNCTION_PATCH" = "1" ]; then
    append_unique_function_id "$WIDGET_TREE_FUNCTION_ID" 0 tagged String "$WIDGET_TREE_RETURN_VALUE"
    append_unique_function_id "package:fcb_counter_app/pricing_source.dart::$WIDGET_TREE_FUNCTION_ID" 0 tagged String "$WIDGET_TREE_RETURN_VALUE"
    append_unique_call_static_function_id "_phaseDWidgetTreeLabel" "$WIDGET_TREE_FUNCTION_ID"
    append_unique_call_static_function_id "package:fcb_counter_app/main.dart::_phaseDWidgetTreeLabel" "$WIDGET_TREE_FUNCTION_ID"
  fi
  if [ "$INCLUDE_FIELD_FUNCTION_PATCH" = "1" ]; then
    append_unique_get_field_function_id "$FIELD_FUNCTION_ID" "$FIELD_NAME"
    append_unique_get_field_function_id "package:fcb_counter_app/pricing_source.dart::$FIELD_FUNCTION_ID" "$FIELD_NAME"
    append_unique_get_field_function_id "_phaseDFieldStatusLabel" "$FIELD_NAME"
    append_unique_get_field_function_id "package:fcb_counter_app/main.dart::_phaseDFieldStatusLabel" "$FIELD_NAME"
  fi
  if [ "$INCLUDE_QUAD_FUNCTION_PATCH" = "1" ]; then
    append_unique_function_id "$QUAD_FUNCTION_ID" 4 unboxed_int64 Int "$RETURN_VALUE"
    append_unique_function_id "package:fcb_counter_app/pricing_source.dart::$QUAD_FUNCTION_ID" 4 unboxed_int64 Int "$RETURN_VALUE"
  fi
  if [ -n "$FUNCTION_ID_VARIANTS" ]; then
    local variant
    IFS=',' read -r -a FCB_VARIANTS <<<"$FUNCTION_ID_VARIANTS"
    for variant in "${FCB_VARIANTS[@]}"; do
      [ -n "$variant" ] && append_unique_function_id "$variant" 0 unboxed_int64 Int "$RETURN_VALUE" "$PATCH_CODE_KIND"
    done
  fi

  {
    printf '{"version":1,"functions":['
    local sep=""
    local function_id
    local param_count
    local return_convention
    local constant_type
    local constant_value
    local code_kind
    local local_count
    local escaped_function
    local escaped_constant
    local escaped_source_location
    local index
    escaped_source_location="$(json_escape "$PATCH_SOURCE_LOCATION")"
    for index in "${!FUNCTION_IDS[@]}"; do
      function_id="${FUNCTION_IDS[$index]}"
      param_count="${FUNCTION_PARAM_COUNTS[$index]}"
      return_convention="${FUNCTION_RETURN_CONVENTIONS[$index]}"
      constant_type="${FUNCTION_CONSTANT_TYPES[$index]}"
      constant_value="${FUNCTION_CONSTANT_VALUES[$index]}"
      code_kind="${FUNCTION_CODE_KINDS[$index]}"
      local_count="$param_count"
      escaped_function="$(json_escape "$function_id")"
      if [ "$code_kind" = "get_field" ]; then
        escaped_constant="$(json_escape "$constant_value")"
        printf '%s{"name":"%s","return_convention":"%s","param_count":%s,"local_count":%s,"constants":[{"type":"String","value":"%s"}],"code":[2,0,67,0,0,255],"source_map":[{"bytecode_offset":0,"source_location":"%s"}]}' \
          "$sep" "$escaped_function" "$return_convention" "$param_count" "$local_count" "$escaped_constant" "$escaped_source_location"
      elif [ "$code_kind" = "call_static" ]; then
        escaped_constant="$(json_escape "$constant_value")"
        printf '%s{"name":"%s","return_convention":"%s","param_count":%s,"local_count":%s,"constants":[{"type":"String","value":"%s"}],"code":[80,0,0,0,255],"source_map":[{"bytecode_offset":0,"source_location":"%s"}]}' \
          "$sep" "$escaped_function" "$return_convention" "$param_count" "$local_count" "$escaped_constant" "$escaped_source_location"
      elif [ "$code_kind" = "invalid_opcode" ]; then
        printf '%s{"name":"%s","return_convention":"%s","param_count":%s,"local_count":%s,"constants":[],"code":[254],"source_map":[{"bytecode_offset":0,"source_location":"%s"}]}' \
          "$sep" "$escaped_function" "$return_convention" "$param_count" "$local_count" "$escaped_source_location"
      elif [ "$code_kind" = "missing_arg" ]; then
        printf '%s{"name":"%s","return_convention":"%s","param_count":%s,"local_count":%s,"constants":[],"code":[2,0,255],"source_map":[{"bytecode_offset":0,"source_location":"%s"}]}' \
          "$sep" "$escaped_function" "$return_convention" "$param_count" "$local_count" "$escaped_source_location"
      elif [ "$code_kind" = "return_underflow" ]; then
        printf '%s{"name":"%s","return_convention":"%s","param_count":%s,"local_count":%s,"constants":[],"code":[255],"source_map":[{"bytecode_offset":0,"source_location":"%s"}]}' \
          "$sep" "$escaped_function" "$return_convention" "$param_count" "$local_count" "$escaped_source_location"
      elif [ "$constant_type" = "String" ]; then
        escaped_constant="$(json_escape "$constant_value")"
        printf '%s{"name":"%s","return_convention":"%s","param_count":%s,"local_count":%s,"constants":[{"type":"String","value":"%s"}],"code":[1,0,0,255],"source_map":[{"bytecode_offset":0,"source_location":"%s"}]}' \
          "$sep" "$escaped_function" "$return_convention" "$param_count" "$local_count" "$escaped_constant" "$escaped_source_location"
      else
        printf '%s{"name":"%s","return_convention":"%s","param_count":%s,"local_count":%s,"constants":[{"type":"Int","value":%s}],"code":[1,0,0,255],"source_map":[{"bytecode_offset":0,"source_location":"%s"}]}' \
          "$sep" "$escaped_function" "$return_convention" "$param_count" "$local_count" "$constant_value" "$escaped_source_location"
      fi
      sep=","
    done
    printf ']}\n'
  } >"$out_dir/payload.bin"
  cat >"$out_dir/manifest.json" <<JSON
{"schema_version":1,"patch_number":$PATCH_NUMBER,"release_version":"$escaped_release","backend":"bytecode","payload":{"kind":"bytecode_module","hash":"manual-device-smoke"}}
JSON
  cat >"$out_dir/state.json" <<JSON
{"schema_version":1,"release_version":"$escaped_release","current_patch_number":0,"pending_patch_number":$PATCH_NUMBER,"bad_patches":[],"last_launch":null,"installed":[{"patch_number":$PATCH_NUMBER,"backend":"bytecode","manifest_path":"patches/$PATCH_NUMBER/manifest.json","payload_path":"patches/$PATCH_NUMBER/payload.bin","artifact_path":null,"installed_at":"manual-device-smoke"}]}
JSON
}

install_patch() {
  require_file "$ADB"
  adb_cmd wait-for-device

  local owner
  owner="$(device_owner)"
  if [ -z "$owner" ] && [ "${FCB_ADB_ROOT_FOR_PATCH:-1}" = "1" ]; then
    adb_cmd root >/dev/null 2>&1 || true
    adb_cmd wait-for-device
    owner="$(device_owner)"
  fi
  [ -n "$owner" ] || die "cannot determine owner for /data/user/0/$PKG; is the app installed?"

  local local_dir="$WORKDIR/manual-bytecode-patch"
  local remote_dir="/data/local/tmp/fcb_patch_$PATCH_NUMBER"
  local cache_dir="/data/user/0/$PKG/code_cache/fcb"

  rm -rf "$local_dir"
  write_local_patch_files "$local_dir"

  run adb_cmd shell am force-stop "$PKG"
  run adb_cmd shell "rm -rf '$remote_dir' && mkdir -p '$remote_dir'"
  run adb_cmd push "$local_dir/payload.bin" "$remote_dir/payload.bin"
  run adb_cmd push "$local_dir/manifest.json" "$remote_dir/manifest.json"
  run adb_cmd push "$local_dir/state.json" "$remote_dir/state.json"
  run adb_cmd shell "mkdir -p '$cache_dir/patches/$PATCH_NUMBER' && cp '$remote_dir/payload.bin' '$cache_dir/patches/$PATCH_NUMBER/payload.bin' && cp '$remote_dir/manifest.json' '$cache_dir/patches/$PATCH_NUMBER/manifest.json' && cp '$remote_dir/state.json' '$cache_dir/state.json' && chown -R '$owner' '$cache_dir' && chmod -R u+rwX,go-rwx '$cache_dir' && rm -rf '$remote_dir'"

  echo "installed bytecode patch $PATCH_NUMBER for $FUNCTION_ID -> $RETURN_VALUE"
  echo "device cache: $cache_dir"
}

main() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
  fi
  if [ "${FCB_WRITE_PATCH_ONLY:-0}" = "1" ]; then
    local local_dir="$WORKDIR/manual-bytecode-patch"
    rm -rf "$local_dir"
    write_local_patch_files "$local_dir"
    echo "wrote bytecode patch files: $local_dir"
    return 0
  fi
  install_patch
}

main "$@"
