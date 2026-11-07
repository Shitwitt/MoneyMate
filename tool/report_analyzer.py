#!/usr/bin/env python3
"""Post a `flutter analyze` report as a commit comment.

Why this exists: GitHub Actions job logs are served from blob storage that is not
always reachable from a restricted network, while the REST API is. When the
analyzer fails, this puts the complete, untruncated report somewhere a human (or
an agent) can read it with a plain API call.

Usage (inside CI):
    python3 tool/report_analyzer.py analyze.txt

Reads `GITHUB_TOKEN` and `COMMIT_COMMENT_URL` from the environment. If either is
missing the report is printed instead and the script still exits 0, so a
reporting failure never masks the real analyzer failure.
"""

from __future__ import annotations

import json
import os
import re
import sys
import urllib.error
import urllib.request

MAX_BODY = 60000  # GitHub's commit-comment limit is 65536 characters.

# Frames like `#42     RenderObject.layout (package:flutter/...` carry no
# information for a human reading a failure summary and would push the actual
# test names out of the comment.
_STACK_FRAME = re.compile(r"^#\d+\s+\S")
_NOISE = re.compile(
    r"^(When the exception was thrown|The relevant error-causing widget was|"
    r"\s*$|::group::|::endgroup::)"
)
_NUMBERED_FRAME_BLOCK = re.compile(r"^#\d+\s.*$", re.MULTILINE)


def condense(text: str, per_file_lines: int = 60) -> str:
    """Keep the interesting parts of a `flutter test` log."""
    # Drop whole stack-frame blocks (`#0 ...` through the last `#NNN ...`).
    lines = text.splitlines()
    kept, frames = [], 0
    for line in lines:
        if _STACK_FRAME.match(line):
            frames += 1
            if frames == 1:
                kept.append("    … stack frames omitted …")
            continue
        frames = 0
        if _NOISE.match(line):
            continue
        kept.append(line)
    return "\n".join(kept)


def post_comment(url: str, token: str, body: str) -> None:
    payload = json.dumps({"body": body}).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=payload,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "Content-Type": "application/json",
            "User-Agent": "moneymate-ci",
        },
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        response.read()


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: report_analyzer.py <analyzer-output-file>", file=sys.stderr)
        return 2

    with open(argv[1], encoding="utf-8", errors="replace") as handle:
        report = handle.read()

    if os.environ.get("CONDENSE"):
        report = condense(report)
    title = os.environ.get("REPORT_TITLE", "flutter analyze report")

    token = os.environ.get("GITHUB_TOKEN")
    url = os.environ.get("COMMIT_COMMENT_URL")
    if not token or not url:
        print(report)
        print("note: GITHUB_TOKEN/COMMIT_COMMENT_URL unset; report printed only")
        return 0

    body = (title + "\n\n```\n" + report + "\n```")[:MAX_BODY]
    try:
        post_comment(url, token, body)
    except urllib.error.URLError as error:  # network down, permissions, etc.
        print(f"note: could not post report ({error}); printing instead")
        print(report)
        return 0

    print("posted analyzer report as a commit comment")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
