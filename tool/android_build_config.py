#!/usr/bin/env python3
"""Make the generated Android scaffold produce a *signed-nothing, minified-but-safe*
release APK.

The repository stores Dart only, so `android/` is produced in CI by
`flutter create`. Two things about that generated project can break (or
silently ruin) a release build, and both are fixed here, idempotently:

1. **Release shrinking and plugins.** Release builds run R8. When the app is
   small, R8 can see no reachable references to a class that a plugin only
   touches through reflection or through the generated
   `GeneratedPluginRegistrant`, and strip it — which shows up at runtime as a
   `MissingPluginException`. The framework ships rules that keep the embedding,
   but a defensive, explicit keep file costs nothing and makes the intent
   readable.

2. **Package identifier.** `--org` + `--project-name` decide the id. The app is a
   port of `dev.hemanths.paisa`, so the installed package should say so rather
   than inheriting a generator default.

Everything is checked before it is written, so this script can be run any number
of times, and it exits non-zero with a readable message if the scaffold it was
promised does not exist.

Usage:
    python3 tool/android_build_config.py --platform-dir android
"""

from __future__ import annotations

import argparse
import pathlib
import re
import sys

# Classes that must survive R8. The framework rules already cover the embedding;
# these keep the channel names of the plugins this app actually ships.
KEEP_RULES = """\
# MoneyMate — release keep rules.
#
# R8 may strip classes that are only reachable through the generated plugin
# registrant or through reflection. These are the plugins this app ships; losing
# any of them turns into a MissingPluginException at runtime, which no amount of
# analyzer coverage would catch.
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class dev.flutter.pigeon.** { *; }
-keep class androidx.biometric.** { *; }
-keep class androidx.core.hardware.fingerprint.** { *; }
"""

KEEP_FILE = "proguard-rules.pro"

# The identifier the app has always claimed (see `pubspec.yaml` and the CI
# `flutter create --org`). Kept in one place so a change is a one-line diff.
APPLICATION_ID = "dev.hemanths.paisa.moneymate"


def find_android_dir(platform_dir: pathlib.Path) -> pathlib.Path:
    app_gradle = platform_dir / "app" / "build.gradle.kts"
    app_gradle_groovy = platform_dir / "app" / "build.gradle"
    if not app_gradle.is_file() and not app_gradle_groovy.is_file():
        raise SystemExit(
            f"error: neither {app_gradle} nor {app_gradle_groovy} exists — did "
            "`flutter create` run?"
        )
    return app_gradle if app_gradle.is_file() else app_gradle_groovy


def write_keep_rules(platform_dir: pathlib.Path) -> bool:
    """Write the R8 keep file next to the app module. True if it changed."""
    proguard = platform_dir / "app" / KEEP_FILE
    if proguard.is_file() and proguard.read_text(encoding="utf-8") == KEEP_RULES:
        return False
    proguard.write_text(KEEP_RULES, encoding="utf-8")
    return True


def _release_member_span(source: str, open_brace: int) -> tuple[int, int]:
    """Return the span just before the closing brace of the block at `open_brace`."""
    depth = 0
    for index in range(open_brace, len(source)):
        char = source[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return index, index
    raise SystemExit("error: unbalanced braces in the generated Gradle file")


def _member_indent(source: str, open_brace: int) -> str:
    """Indentation used by the first member line inside the block, or a guess."""
    for line in source[open_brace + 1 :].splitlines():
        if line.strip():
            return line[: len(line) - len(line.lstrip())]
    line_start = source.rfind("\n", 0, open_brace) + 1
    return source[line_start:open_brace] + "    "


def wire_keep_rules(gradle: pathlib.Path) -> bool:
    """Point the release build type at the keep file. True if it changed."""
    source = gradle.read_text(encoding="utf-8")
    if KEEP_FILE in source:
        return False

    build_types = source.find("buildTypes")
    if build_types == -1:
        raise SystemExit("error: no `buildTypes` block; cannot wire the keep rules")
    release = re.search(r"release\s*\{", source[build_types:])
    if not release:
        raise SystemExit("error: no `release` build type; cannot wire the keep rules")

    open_brace = build_types + release.end() - 1
    assert source[open_brace] == "{", repr(source[open_brace - 5 : open_brace + 5])
    close_brace, _ = _release_member_span(source, open_brace)
    indent = _member_indent(source, open_brace)

    if gradle.suffix == ".kts":
        rule = (
            f'{indent}proguardFiles(getDefaultProguardFile('
            f'"proguard-android-optimize.txt"), "{KEEP_FILE}")\n'
        )
    else:
        rule = (
            f'{indent}proguardFiles getDefaultProguardFile('
            f'"proguard-android-optimize.txt"), "{KEEP_FILE}"\n'
        )

    # Insert immediately before the line that holds the block's closing brace,
    # so the new property lands after the last existing member.
    insert_at = source.rfind("\n", 0, close_brace) + 1
    source = source[:insert_at] + rule + source[insert_at:]
    gradle.write_text(source, encoding="utf-8")
    return True


def ensure_application_id(gradle: pathlib.Path) -> tuple[bool, str]:
    """Set the application id. Returns (changed, current value)."""
    source = gradle.read_text(encoding="utf-8")
    assignment = re.search(
        r'(applicationId\s*=?\s*)["\']([^"\']+)["\']', source
    )
    if not assignment:
        raise SystemExit(f"error: no applicationId in {gradle}")

    current = assignment.group(2)
    if current == APPLICATION_ID:
        return False, current

    source = (
        source[: assignment.start(2)] + APPLICATION_ID + source[assignment.end(2) :]
    )
    gradle.write_text(source, encoding="utf-8")
    return True, current


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--platform-dir",
        default="android",
        help="path to the generated Android platform folder (default: android)",
    )
    args = parser.parse_args(argv)

    platform_dir = pathlib.Path(args.platform_dir)
    gradle = find_android_dir(platform_dir)

    wrote_rules = write_keep_rules(platform_dir)
    wired = wire_keep_rules(gradle)
    renamed, previous = ensure_application_id(gradle)

    report = [
        f"{'wrote' if wrote_rules else 'unchanged'}: {platform_dir / 'app' / KEEP_FILE}",
        f"{'wired' if wired else 'already wired'}: {KEEP_FILE} in {gradle}",
        f"applicationId: {APPLICATION_ID}"
        + (f" (was {previous})" if renamed else " (unchanged)"),
    ]
    print("\n".join(report))
    return 0


if __name__ == "__main__":
    sys.exit(main())
