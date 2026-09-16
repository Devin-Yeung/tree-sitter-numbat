#!/usr/bin/env python3
"""Check that every corpus snippet is syntactically valid Numbat.

The tree-sitter grammar accepts more than the reference implementation in
places, so it is easy to accidentally add a corpus snippet that Numbat itself
rejects. This script extracts every test case from ``test/corpus/*.txt`` and
runs it through the real ``numbat`` binary with ``--no-prelude``. Only
*parsing* errors are reported; unresolved identifiers, type errors and other
semantic problems are ignored, since most snippets are fragments.

Requires a ``numbat`` binary on ``PATH`` (or set ``NUMBAT`` to its path).

Usage:
    python3 scripts/check-corpus-syntax.py [corpus-dir]

Exits with a non-zero status if any snippet fails to parse.
"""

from __future__ import annotations

import os
import pathlib
import re
import subprocess
import sys

SEPARATOR = re.compile(r"^=+$")
NUMBAT = os.environ.get("NUMBAT", "numbat")


def extract_tests(path: pathlib.Path) -> list[tuple[str, str]]:
    """Return the ``(name, source)`` pairs contained in a corpus file."""
    lines = path.read_text(encoding="utf-8").splitlines()
    tests: list[tuple[str, str]] = []
    i = 0
    while i < len(lines):
        # A test header looks like:  ==== / name / ====
        if (
            SEPARATOR.match(lines[i])
            and i + 2 < len(lines)
            and SEPARATOR.match(lines[i + 2])
        ):
            name = lines[i + 1]
            j = i + 3
            source: list[str] = []
            while j < len(lines) and lines[j].strip() != "---":
                source.append(lines[j])
                j += 1
            tests.append((name, "\n".join(source).strip("\n")))
            i = j + 1
        else:
            i += 1
    return tests


def parses(source: str) -> tuple[bool, str]:
    result = subprocess.run(
        [NUMBAT, "--no-prelude", "--no-config", "--no-init", "-e", source],
        capture_output=True,
        text=True,
    )
    output = result.stdout + result.stderr
    if "while parsing" in output:
        # Keep just the first few lines of the error message.
        return False, "\n".join(output.strip().splitlines()[:4])
    return True, ""


def main() -> int:
    default_corpus = pathlib.Path(__file__).resolve().parent.parent / "test" / "corpus"
    corpus = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else default_corpus

    failures: list[tuple[str, str, str]] = []
    total = 0
    for path in sorted(corpus.glob("*.txt")):
        for name, source in extract_tests(path):
            total += 1
            ok, message = parses(source)
            if not ok:
                failures.append((path.name, name, message))

    print(f"Checked {total} snippets, {len(failures)} parse failures.")
    for filename, name, message in failures:
        print(f"\n### {filename} :: {name}\n{message}")

    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
