#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOGS="$SCRIPT_DIR/../templates/blogs"

# Keys that every blog's "### metadata" block must contain (see templates/blogs/blog-1.md)
REQUIRED_META_KEYS=(header title subtitle seo_description embed_text is_featured tags topic thumbnail)

if [ -d "$BLOGS" ] && [ -z "$(find "$BLOGS" -maxdepth 1 -mindepth 1 -not -name '.gitkeep')" ]; then
    # No blog templates found, early return
    exit 0
fi

# Validate the "### metadata ... ### metadata" block and its required keys
validate_metadata() {
    local file="$1" name="$2" rc=0 key

    # Must open with a "### metadata" fence on the first line
    if [ "$(head -n1 "$file")" != "### metadata" ]; then
        echo "Error: '$name' must start with a '### metadata' line" >&2
        return 1
    fi

    # Must be wrapped by exactly two "### metadata" fences
    if [ "$(grep -c '^### metadata$' "$file")" -ne 2 ]; then
        echo "Error: '$name' metadata must be wrapped between two '### metadata' lines" >&2
        return 1
    fi

    # Extract the block between the two fences and check each required key exists
    local block
    block="$(awk 'NR>1 && /^### metadata$/ {exit} NR>1 {print}' "$file")"
    for key in "${REQUIRED_META_KEYS[@]}"; do
        if ! printf '%s\n' "$block" | grep -q "^${key}:"; then
            echo "Error: '$name' metadata is missing key '$key'" >&2
            rc=1
        fi
    done

    return "$rc"
}

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

    # Validate the metadata block contains all required keys and structure
    if ! validate_metadata "$file" "$name"; then
        errors=$((errors + 1))
    fi
done < <(find "$BLOGS" -maxdepth 1 -mindepth 1 -not -name '.gitkeep' -print0)

[ "$errors" -eq 0 ] || exit 1
