#!/usr/bin/env python3
import os
import sys
import json
import ast
import re
from typing import List


def to_bulleted_markdown(items: List[str]) -> str:
    return "\n".join(f"- {line}" for line in items if line)


def main() -> int:
    # Output path can be provided as first arg; default to RELEASE_NOTES.md
    out_path = sys.argv[1] if len(sys.argv) > 1 else "RELEASE_NOTES.md"

    raw = os.environ.get("RELEASE_NOTES", "") or ""
    s = raw.strip()
    items: List[str] = []

    if s:
        parsed = None
        # Try JSON array first
        try:
            parsed = json.loads(s)
        except Exception:
            parsed = None
        # Try Python literal list/tuple as a fallback (supports single quotes)
        if parsed is None:
            try:
                parsed = ast.literal_eval(s)
            except Exception:
                parsed = None

        if isinstance(parsed, (list, tuple)):
            for it in parsed:
                if it is None:
                    continue
                it = str(it).strip()
                if it:
                    items.append(it)

    # Build body: bulletize only when a list was parsed; otherwise, keep text.
    if items:
        body = to_bulleted_markdown(items)
    else:
        # Convert escaped sequences only if there are no actual newlines present
        if "\n" not in s:
            s = re.sub(r"(?<!\\)\\r?\\n", "\n", s)
            s = re.sub(r"(?<!\\)\\t", "\t", s)
        body = s

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(body)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())