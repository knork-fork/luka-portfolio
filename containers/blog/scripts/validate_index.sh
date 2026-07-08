#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INDEX="$SCRIPT_DIR/../index.json"

# Empty file
if [ ! -s "$INDEX" ]; then
    exit 1
fi

# Invalid JSON
if ! jq empty "$INDEX" 2>/dev/null; then
    exit 1
fi

# Empty array
if [ "$(jq 'length' "$INDEX")" -eq 0 ]; then
    exit 1
fi

# TODO: return true when post rendering is implemented
exit 0
