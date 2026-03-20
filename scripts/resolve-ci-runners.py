"""Resolve CI runner labels from .github/runners.json.

This script reads the runner configuration and outputs GitHub Actions step
outputs that map each runner role to a concrete runner label.

On forks (any repository other than ``astral-sh/uv``), only runners marked
``"free": true`` are selected.  On the main repository the first listed
runner for each role is used regardless of cost.

The script also emits an ``is_fork`` output so callers don't need separate
fork-detection logic.

Usage (in a GitHub Actions step)::

    python scripts/resolve-ci-runners.py >> "$GITHUB_OUTPUT"

The ``GITHUB_REPOSITORY`` environment variable (set automatically by GitHub
Actions) is used to detect whether we are running on a fork.
"""

# /// script
# requires-python = ">=3.12"
# ///

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

RUNNERS_JSON = Path(__file__).resolve().parent.parent / ".github" / "runners.json"
UPSTREAM_REPO = "astral-sh/uv"


def resolve_runners(
    runners_path: Path,
    *,
    is_fork: bool,
) -> list[tuple[str, str]]:
    """Return a list of ``(output_key, label)`` pairs."""
    with runners_path.open() as f:
        data = json.load(f)

    if not isinstance(data, dict):
        print(f"error: expected a JSON object in {runners_path}", file=sys.stderr)
        sys.exit(1)

    results: list[tuple[str, str]] = []
    for role, options in data.items():
        if not isinstance(options, list) or not options:
            print(
                f"error: runner role {role!r} must be a non-empty array",
                file=sys.stderr,
            )
            sys.exit(1)

        if is_fork:
            candidates = [r for r in options if r.get("free")]
            if not candidates:
                label = ""
            else:
                label = candidates[0]["label"]
        else:
            label = options[0]["label"]

        # Validate that the selected entry has a label
        if label is None:
            print(
                f"error: runner role {role!r} is missing a 'label' field",
                file=sys.stderr,
            )
            sys.exit(1)

        output_key = f"runner_{role.replace('-', '_')}"
        results.append((output_key, label))

    return results


def main() -> None:
    repository = os.environ.get("GITHUB_REPOSITORY", "")
    is_fork = repository != UPSTREAM_REPO

    if not RUNNERS_JSON.exists():
        print(f"error: {RUNNERS_JSON} not found", file=sys.stderr)
        sys.exit(1)

    results = resolve_runners(RUNNERS_JSON, is_fork=is_fork)

    for key, label in results:
        print(f"{key}={label}")

    print(f"is_fork={'true' if is_fork else 'false'}")


if __name__ == "__main__":
    main()
