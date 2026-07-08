#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOGS="$SCRIPT_DIR/../templates/blogs"

if [ -d "$BLOGS" ] && [ -z "$(find "$BLOGS" -maxdepth 1 -mindepth 1 -not -name '.gitkeep')" ]; then
    # No blog templates found, early return
    exit 0
fi

errors=0

while IFS= read -r -d '' file; do
    name="$(basename "$file")"

    # Validate that the filename ends with .md
    if [[ "$name" != *.md ]]; then
        echo "Error: '$name' is not a .md file" >&2
        errors=$((errors + 1))
        continue
    fi

    stem="${name%.md}"

    # Validate that the filename matches the pattern: lowercase letters, digits, hyphens only;
    # must start with a letter; no leading/trailing/consecutive hyphens
    if [[ ! "$stem" =~ ^[a-z][a-z0-9-]*$ ]] || [[ "$stem" =~ -- ]] || [[ "$stem" == *- ]]; then
        echo "Error: '$name' filename does not match pattern 'name-123.md' (lowercase letters, digits, hyphens only; must start with a letter; no leading/trailing/consecutive hyphens)" >&2
        errors=$((errors + 1))
    fi
done < <(find "$BLOGS" -maxdepth 1 -mindepth 1 -not -name '.gitkeep' -print0)

[ "$errors" -eq 0 ] || exit 1
