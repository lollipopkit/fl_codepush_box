#!/usr/bin/env python3
"""Force android:extractNativeLibs="true" in an AndroidManifest.xml."""

from __future__ import annotations

import re
import sys
from pathlib import Path


def force_extract_native_libs(manifest_path: Path) -> None:
    data = manifest_path.read_text(encoding="utf-8")
    match = re.search(r"<application\b([^>]*)>", data)
    if not match:
        raise ValueError(f"missing <application> tag in {manifest_path}")

    tag = match.group(0)
    if "android:extractNativeLibs=" in tag:
        new_tag = re.sub(
            r'android:extractNativeLibs="[^"]*"',
            'android:extractNativeLibs="true"',
            tag,
            count=1,
        )
    else:
        new_tag = tag.replace(
            "<application", '<application android:extractNativeLibs="true"', 1
        )

    manifest_path.write_text(
        data[: match.start()] + new_tag + data[match.end() :],
        encoding="utf-8",
    )


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} <AndroidManifest.xml>", file=sys.stderr)
        return 2
    try:
        force_extract_native_libs(Path(sys.argv[1]))
    except Exception as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
