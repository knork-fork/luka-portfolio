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

# Required keys present on each non-null, non-empty entry
REQUIRED_KEYS='["name","title","created","modified","tags","topic","thumbnail","is_featured"]'
MISSING=$(jq --argjson keys "$REQUIRED_KEYS" '
  [ .[] | select(type == "object" and length > 0) |
    . as $entry |
    $keys[] as $k |
    select($entry | has($k) | not) |
    $k ]
  | length
' "$INDEX")
if [ "$MISSING" -gt 0 ]; then
    echo "Error: one or more entries are missing required keys" >&2
    exit 1
fi

# At most one entry may have is_featured = true
FEATURED=$(jq '[.[] | select(.is_featured == true)] | length' "$INDEX")
if [ "$FEATURED" -gt 1 ]; then
    echo "Error: more than one entry has is_featured set to true" >&2
    exit 1
fi

exit 0
