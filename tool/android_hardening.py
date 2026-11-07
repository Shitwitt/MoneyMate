#!/usr/bin/env python3
"""Harden the generated Android project for `local_auth`.

The repository stores Dart only; the native `android/` folder is created inside
CI by `flutter create`. Out of the box that scaffold is not usable by
`package:local_auth`, which needs two things the generator does not provide:

  1. `<uses-permission android:name="android.permission.USE_BIOMETRIC" />`
     in `app/src/main/AndroidManifest.xml`.
  2. A host activity that extends `FlutterFragmentActivity`, not
     `FlutterActivity` — otherwise the prompt fails at runtime with
     "no_fragment_activity".

Both edits are idempotent, so this script can be run any number of times, before
or after a regeneration.

Usage:
    python3 tool/android_hardening.py [--platform-dir android]

Exits non-zero with a readable message if anything it needs is missing, so the
CI step fails loudly instead of shipping a silently broken APK.
"""

from __future__ import annotations

import argparse
import pathlib
import re
import sys

PERMISSION = "android.permission.USE_BIOMETRIC"
PERMISSION_ELEMENT = '<uses-permission android:name="android.permission.USE_BIOMETRIC" />'

FRAGMENT_ACTIVITY = "FlutterFragmentActivity"
PLAIN_ACTIVITY = "FlutterActivity"
ACTIVITY_IMPORT = f"import io.flutter.embedding.android.{FRAGMENT_ACTIVITY}"

LAUNCHER_NAMES = ("MainActivity.kt", "MainActivity.java", "MainActivity.kt.skipped")


def find_manifest(platform_dir: pathlib.Path) -> pathlib.Path:
    manifest = platform_dir / "app" / "src" / "main" / "AndroidManifest.xml"
    if not manifest.is_file():
        raise SystemExit(f"error: {manifest} not found — did `flutter create` run?")
    return manifest


def ensure_biometric_permission(manifest: pathlib.Path) -> bool:
    """Insert the USE_BIOMETRIC permission if absent. Returns True if changed."""
    source = manifest.read_text(encoding="utf-8")

    # `USE_FINGERPRINT` mentions the same word; check for the exact name.
    if PERMISSION in source:
        return False

    application = source.find("<application")
    if application == -1:
        raise SystemExit(f"error: no <application> element in {manifest}")

    # `<application` starts a line in every generated manifest, so copying that
    # line's indentation keeps the new element aligned with the rest.
    line_start = source.rfind("\n", 0, application) + 1
    indent = source[line_start:application]
    line = f"{indent if indent.strip() == '' else '    '}{PERMISSION_ELEMENT}\n"
    patched = source[:line_start] + line + source[line_start:]
    manifest.write_text(patched, encoding="utf-8")
    return True


def find_launchers(platform_dir: pathlib.Path) -> list[pathlib.Path]:
    main = platform_dir / "app" / "src" / "main"
    if not main.is_dir():
        raise SystemExit(f"error: {main} not found — did `flutter create` run?")

    launchers = [
        path
        for path in main.rglob("MainActivity.*")
        if path.suffix in (".kt", ".java") and path.is_file()
    ]
    if not launchers:
        raise SystemExit(
            f"error: no MainActivity.kt/java under {main}; cannot guarantee "
            "local_auth works with a plain FlutterActivity host"
        )
    return launchers


def harden_launcher(launcher: pathlib.Path) -> bool:
    """Make MainActivity extend FlutterFragmentActivity. True if changed."""
    source = launcher.read_text(encoding="utf-8")
    original = source

    # Normalise first so a re-run cannot produce FlutterFragmentFragmentActivity.
    source = re.sub(rf"\b{FRAGMENT_ACTIVITY}\b", PLAIN_ACTIVITY, source)
    source = re.sub(rf"\b{PLAIN_ACTIVITY}\b", FRAGMENT_ACTIVITY, source)

    if launcher.suffix == ".kt":
        # `import io.flutter.embedding.android.FlutterActivity` -> Fragment variant.
        if ACTIVITY_IMPORT not in source:
            activity_import = f"import io.flutter.embedding.android.{PLAIN_ACTIVITY}"
            if activity_import in source:
                source = source.replace(activity_import, ACTIVITY_IMPORT, 1)
            else:
                # No explicit import (fully-qualified or generated differently):
                # add one after the package declaration.
                package = re.search(r"^package\s+\S+\s*$", source, re.MULTILINE)
                if package:
                    insert_at = package.end() + 1
                    source = (
                        source[:insert_at]
                        + "\n"
                        + ACTIVITY_IMPORT
                        + "\n"
                        + source[insert_at:]
                    )
    else:
        java_import = f"import io.flutter.embedding.android.{PLAIN_ACTIVITY};"
        java_fragment = f"import io.flutter.embedding.android.{FRAGMENT_ACTIVITY};"
        if java_fragment not in source and java_import in source:
            source = source.replace(java_import, java_fragment, 1)

    if FRAGMENT_ACTIVITY not in source:
        raise SystemExit(
            f"error: {launcher} does not look like a Flutter launcher; "
            "expected it to extend/extend FlutterActivity"
        )

    if source == original:
        return False
    launcher.write_text(source, encoding="utf-8")
    return True


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--platform-dir",
        default="android",
        help="path to the generated Android platform folder (default: android)",
    )
    args = parser.parse_args(argv)

    platform_dir = pathlib.Path(args.platform_dir)
    manifest = find_manifest(platform_dir)
    changed_manifest = ensure_biometric_permission(manifest)

    launchers = find_launchers(platform_dir)
    changed_launchers = [p for p in launchers if harden_launcher(p)]

    report = [
        f"{'added' if changed_manifest else 'already present'}: USE_BIOMETRIC in {manifest}",
    ]
    for launcher in launchers:
        state = "repointed to FlutterFragmentActivity" if launcher in changed_launchers else "already FragmentActivity"
        report.append(f"{state}: {launcher}")

    print("\n".join(report))
    return 0


if __name__ == "__main__":
    sys.exit(main())
