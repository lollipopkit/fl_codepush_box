#!/usr/bin/env python3
"""Apply the FCB Android snapshot_replace hook to a Flutter Engine checkout."""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path


ROOT_MARKER = Path("flutter/shell/platform/android/BUILD.gn")
FCB_SOURCES_BLOCK = (
    "  if (fcb_enable_code_push) {\n"
    "    sources += [\n"
    '      "fcb/fcb_engine_hook.cc",\n'
    '      "fcb/fcb_engine_hook.h",\n'
    "    ]\n"
    "  }\n"
)
FCB_DEFINES_BLOCK = (
    "  if (fcb_enable_code_push) {\n"
    '    defines += [ "FCB_ENABLE_CODE_PUSH" ]\n'
    "  }\n"
)
FCB_LIBS_BLOCK = (
    "  fcb_android_unwind_staticlib = \"\"\n"
    "  if (current_cpu == \"arm64\") {\n"
    "    fcb_android_unwind_staticlib =\n"
    "        \"${android_toolchain_root}/lib/clang/19/lib/linux/aarch64/libunwind.a\"\n"
    "  } else if (current_cpu == \"arm\") {\n"
    "    fcb_android_unwind_staticlib =\n"
    "        \"${android_toolchain_root}/lib/clang/19/lib/linux/arm/libunwind.a\"\n"
    "  } else if (current_cpu == \"x64\") {\n"
    "    fcb_android_unwind_staticlib =\n"
    "        \"${android_toolchain_root}/lib/clang/19/lib/linux/x86_64/libunwind.a\"\n"
    "  } else if (current_cpu == \"x86\") {\n"
    "    fcb_android_unwind_staticlib =\n"
    "        \"${android_toolchain_root}/lib/clang/19/lib/linux/i386/libunwind.a\"\n"
    "  }\n"
    "\n"
    "  if (fcb_enable_code_push) {\n"
    "    libs += [ fcb_updater_staticlib, fcb_android_unwind_staticlib ]\n"
    "  }\n"
)
FCB_OLD_COMBINED_BLOCK = (
    "  if (fcb_enable_code_push) {\n"
    "    sources += [\n"
    '      "fcb/fcb_engine_hook.cc",\n'
    '      "fcb/fcb_engine_hook.h",\n'
    "    ]\n"
    '    defines += [ "FCB_ENABLE_CODE_PUSH" ]\n'
    "    libs += [ fcb_updater_staticlib ]\n"
    "  }\n"
)
FCB_OLD_UNWIND_LIBS_BLOCK = (
    "  if (fcb_enable_code_push) {\n"
    "    libs += [ fcb_updater_staticlib, \"unwind\" ]\n"
    "  }\n"
)


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if new in text:
        return text
    if old not in text:
        raise RuntimeError(f"could not find insertion point: {label}")
    return text.replace(old, new, 1)


def patch_build_gn(path: Path) -> str:
    text = path.read_text()
    text = replace_once(
        text,
        'import("//flutter/vulkan/config.gni")\n',
        'import("//flutter/vulkan/config.gni")\n\n'
        "declare_args() {\n"
        "  fcb_enable_code_push = false\n"
        '  fcb_updater_staticlib = ""\n'
        "}\n",
        "BUILD.gn declare_args",
    )
    text = replace_once(
        text,
        '    "flutter_main.h",\n',
        '    "flutter_main.h",\n',
        "BUILD.gn stable source anchor",
    )
    for block in (
        FCB_OLD_COMBINED_BLOCK,
        FCB_OLD_UNWIND_LIBS_BLOCK,
        FCB_SOURCES_BLOCK,
        FCB_DEFINES_BLOCK,
        FCB_LIBS_BLOCK,
    ):
        text = text.replace(block + "\n", "")
        text = text.replace(block, "")
    text = replace_once(
        text,
        "  sources += get_target_outputs(\":icudtl_asm\")\n",
        FCB_SOURCES_BLOCK + "\n" + "  sources += get_target_outputs(\":icudtl_asm\")\n",
        "BUILD.gn FCB sources block",
    )
    text = replace_once(
        text,
        "  defines = []\n",
        "  defines = []\n\n" + FCB_DEFINES_BLOCK,
        "BUILD.gn FCB defines block",
    )
    text = replace_once(
        text,
        '    "GLESv2",\n'
        "  ]\n",
        '    "GLESv2",\n'
        "  ]\n\n"
        + FCB_LIBS_BLOCK,
        "BUILD.gn FCB libs block",
    )
    return text


def patch_flutter_main(path: Path) -> str:
    text = path.read_text()
    text = replace_once(
        text,
        '#include "flutter/shell/platform/android/flutter_main.h"\n',
        '#include "flutter/shell/platform/android/flutter_main.h"\n'
        '#include "flutter/shell/platform/android/fcb/fcb_engine_hook.h"\n',
        "flutter_main include",
    )
    text = replace_once(
        text,
        "namespace {\n\n",
        "namespace {\n\n"
        "int SetFcbAotArtifactPath(void* user_data, const char* artifact_path) {\n"
        "  if (user_data == nullptr || artifact_path == nullptr ||\n"
        "      artifact_path[0] == '\\0') {\n"
        "    return -1;\n"
        "  }\n"
        "  auto* settings = reinterpret_cast<flutter::Settings*>(user_data);\n"
        "  settings->application_library_paths.clear();\n"
        "  settings->application_library_paths.emplace_back(artifact_path);\n"
        "  return 0;\n"
        "}\n\n"
        "void MaybeApplyFcbSnapshotReplace(flutter::Settings& settings,\n"
        "                                  const std::string& engine_caches_path) {\n"
        "  const std::string cache_dir = engine_caches_path + \"/fcb\";\n"
        "  __android_log_print(ANDROID_LOG_INFO, \"Flutter\",\n"
        "                      \"FCB snapshot_replace cache: %s\", cache_dir.c_str());\n"
        "  FcbInitParams params = {};\n"
        "  params.platform = \"android\";\n"
        "#if defined(__aarch64__)\n"
        "  params.arch = \"arm64-v8a\";\n"
        "#elif defined(__arm__)\n"
        "  params.arch = \"armeabi-v7a\";\n"
        "#elif defined(__x86_64__)\n"
        "  params.arch = \"x86_64\";\n"
        "#elif defined(__i386__)\n"
        "  params.arch = \"x86\";\n"
        "#endif\n"
        "  params.cache_dir = cache_dir.c_str();\n"
        "  params.check_on_startup = 0;\n"
        "  if (fcb_init(&params) != 0) {\n"
        "    __android_log_print(ANDROID_LOG_WARN, \"Flutter\", \"FCB init failed: %s\",\n"
        "                        fcb_last_error());\n"
        "    return;\n"
        "  }\n"
        "  FcbEnginePatchDecision decision = {};\n"
        "  const int rc = fcb_apply_android_snapshot_replace(\n"
        "      fcb_get_launch_patch, SetFcbAotArtifactPath, &settings, &decision);\n"
        "  if (rc == 1) {\n"
        "    __android_log_print(ANDROID_LOG_INFO, \"Flutter\",\n"
        "                        \"FCB snapshot_replace patch %d: %s\",\n"
        "                        decision.patch_number, decision.artifact_path);\n"
        "  } else {\n"
        "    __android_log_print(ANDROID_LOG_INFO, \"Flutter\",\n"
        "                        \"FCB snapshot_replace not applied rc=%d error=%s\", rc,\n"
        "                        fcb_last_error());\n"
        "  }\n"
        "}\n\n",
        "flutter_main helper",
    )
    text = replace_once(
        text,
        "  settings.enable_platform_isolates = true;\n",
        "  settings.enable_platform_isolates = true;\n\n"
        "#if defined(FCB_ENABLE_CODE_PUSH)\n"
        "  MaybeApplyFcbSnapshotReplace(\n"
        "      settings, fml::jni::JavaStringToString(env, engineCachesPath));\n"
        "#endif\n",
        "flutter_main launch hook",
    )
    return text


def patch_platform_view_android(path: Path) -> str:
    text = path.read_text()
    text = replace_once(
        text,
        '#include "flutter/shell/platform/android/platform_view_android.h"\n',
        '#include "flutter/shell/platform/android/platform_view_android.h"\n'
        '#include "flutter/shell/platform/android/fcb/fcb_engine_hook.h"\n',
        "platform_view include",
    )
    text = replace_once(
        text,
        "void PlatformViewAndroid::FireFirstFrameCallback() {\n"
        "  jni_facade_->FlutterViewOnFirstFrame();\n"
        "}\n",
        "void PlatformViewAndroid::FireFirstFrameCallback() {\n"
        "#if defined(FCB_ENABLE_CODE_PUSH)\n"
        "  fcb_mark_android_launch_success(fcb_mark_launch_success);\n"
        "#endif\n"
        "  jni_facade_->FlutterViewOnFirstFrame();\n"
        "}\n",
        "platform_view success hook",
    )
    return text


def write_if_changed(path: Path, text: str, dry_run: bool) -> bool:
    if path.read_text() == text:
        return False
    if not dry_run:
        path.write_text(text)
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("engine_src", type=Path)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    engine_src = args.engine_src.resolve()
    if not (engine_src / ROOT_MARKER).is_file():
        raise SystemExit(f"not a Flutter Engine src checkout: {engine_src}")

    repo_android = Path(__file__).resolve().parent
    engine_android = engine_src / "flutter/shell/platform/android"
    fcb_dir = engine_android / "fcb"

    changed = []
    for name in ["fcb_engine_hook.cc", "fcb_engine_hook.h"]:
        src = repo_android / name
        dst = fcb_dir / name
        if not dst.exists() or dst.read_bytes() != src.read_bytes():
            changed.append(str(dst))
            if not args.dry_run:
                fcb_dir.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dst)

    patches = {
        engine_android / "BUILD.gn": patch_build_gn,
        engine_android / "flutter_main.cc": patch_flutter_main,
        engine_android / "platform_view_android.cc": patch_platform_view_android,
    }
    for path, patcher in patches.items():
        if write_if_changed(path, patcher(path), args.dry_run):
            changed.append(str(path))

    if changed:
        print("would change:" if args.dry_run else "changed:")
        for path in changed:
            print(path)
    else:
        print("already applied")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
