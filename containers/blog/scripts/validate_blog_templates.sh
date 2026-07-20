#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOGS="$SCRIPT_DIR/../templates/blogs"

# Keys that every blog's "### metadata" block must contain (see templates/blogs/blog-1.md)
REQUIRED_META_KEYS=(card_label title subtitle seo_description embed_text is_published is_featured tags topic thumbnail created_at modified_at force_gradient)

# RFC 3339 timestamp shape, e.g. "2026-07-08T22:57:57+02:00"
TIMESTAMP_RE='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{2}:[0-9]{2}$'

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

    # Read a metadata value by key (first match), trimming surrounding whitespace
    meta_value() {
        printf '%s\n' "$block" | sed -n "s/^$1:[[:space:]]*//p" | head -n1
    }

    local is_published created_at modified_at force_gradient
    is_published="$(meta_value is_published)"
    created_at="$(meta_value created_at)"
    modified_at="$(meta_value modified_at)"
    force_gradient="$(meta_value force_gradient)"

    # is_published must be exactly true or false
    if [ "$is_published" != "true" ] && [ "$is_published" != "false" ]; then
        echo "Error: '$name' metadata 'is_published' must be 'true' or 'false' (got '$is_published')" >&2
        rc=1
    fi

    # created_at must never be null and must match the timestamp shape
    if [ "$created_at" = "null" ] || [ -z "$created_at" ]; then
        echo "Error: '$name' metadata 'created_at' must not be null" >&2
        rc=1
    elif [[ ! "$created_at" =~ $TIMESTAMP_RE ]]; then
        echo "Error: '$name' metadata 'created_at' must be a timestamp like '2026-07-08T22:57:57+02:00' (got '$created_at')" >&2
        rc=1
    fi

    # modified_at may be null; otherwise it must match the timestamp shape
    if [ "$modified_at" != "null" ] && [[ ! "$modified_at" =~ $TIMESTAMP_RE ]]; then
        echo "Error: '$name' metadata 'modified_at' must be null or a timestamp like '2026-07-08T22:57:57+02:00' (got '$modified_at')" >&2
        rc=1
    fi

    # force_gradient must be null or one of the blog-card-grad-0 .. blog-card-grad-5 classes
    if [ "$force_gradient" != "null" ] && [[ ! "$force_gradient" =~ ^blog-card-grad-[0-5]$ ]]; then
        echo "Error: '$name' metadata 'force_gradient' must be null or 'blog-card-grad-0' through 'blog-card-grad-5' (got '$force_gradient')" >&2
        rc=1
    fi

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
