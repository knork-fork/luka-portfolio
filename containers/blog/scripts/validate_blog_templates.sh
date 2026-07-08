#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOGS="$SCRIPT_DIR/../templates/blogs"

if [ -d "$BLOGS" ] && [ -z "$(find "$BLOGS" -maxdepth 1 -mindepth 1 -not -name '.gitkeep')" ]; then
    # No blog templates found, early return
    exit 0
fi

echo "Temporary error" >&2
exit 1
