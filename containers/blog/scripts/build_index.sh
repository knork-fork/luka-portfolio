#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOGS_DIR="$SCRIPT_DIR/../templates/blogs"
INDEX="$SCRIPT_DIR/../index.json"

if [ -d "$BLOGS_DIR" ] && [ -z "$(find "$BLOGS_DIR" -maxdepth 1 -mindepth 1 -name '*.md' -not -name '.gitkeep')" ]; then
    exit 0
fi

if ! "$SCRIPT_DIR/validate_blog_templates.sh"; then
    exit 1
fi

# Read a single key's value from a blog's "### metadata ... ### metadata" block
meta_value() {
    local file="$1" key="$2"
    awk -v key="$key" '
        NR==1 && $0=="### metadata" { inblock=1; next }
        inblock && $0=="### metadata" { exit }
        inblock {
            idx = index($0, ":")
            if (idx > 0) {
                k = substr($0, 1, idx-1)
                v = substr($0, idx+1)
                gsub(/^[ \t]+|[ \t]+$/, "", k)
                gsub(/^[ \t]+|[ \t]+$/, "", v)
                if (k == key) { print v; exit }
            }
        }
    ' "$file"
}

entries="[]"

while IFS=$'\t' read -r birth file; do
    name=$(basename "$file" .md)
    header=$(meta_value "$file" header)
    title=$(meta_value "$file" title)
    subtitle=$(meta_value "$file" subtitle)
    is_featured=$(meta_value "$file" is_featured)
    tags=$(meta_value "$file" tags)
    topic=$(meta_value "$file" topic)
    thumbnail=$(meta_value "$file" thumbnail)

    [ -z "$title" ] && title="$name"
    # Fall back to sane JSON defaults so --argjson never chokes on an empty value
    [ -z "$is_featured" ] && is_featured=false
    [ -z "$tags" ] && tags='[]'
    [ -z "$topic" ] && topic=null
    [ -z "$thumbnail" ] && thumbnail=null

    mtime=$(stat -c "%Y" "$file")
    created=$(date -d "@$birth" --iso-8601=seconds)
    modified=$(date -d "@$mtime" --iso-8601=seconds)

    entry=$(jq -n \
        --arg name "$name" \
        --arg title "$title" \
        --arg header "$header" \
        --arg subtitle "$subtitle" \
        --arg created "$created" \
        --arg modified "$modified" \
        --argjson is_featured "$is_featured" \
        --argjson tags "$tags" \
        --argjson topic "$topic" \
        --argjson thumbnail "$thumbnail" \
        '{name: $name, title: $title, created: $created, modified: $modified, tags: $tags, topic: $topic, thumbnail: $thumbnail, is_featured: $is_featured, header: $header, subtitle: $subtitle}')

    entries=$(jq -n --argjson arr "$entries" --argjson entry "$entry" '$arr + [$entry]')
done < <(
    find "$BLOGS_DIR" -maxdepth 1 -mindepth 1 -name '*.md' -not -name '.gitkeep' -print0 |
        while IFS= read -r -d '' f; do
            birth=$(stat -c "%W" "$f")
            [ "$birth" -eq 0 ] && birth=$(stat -c "%Z" "$f")
            printf '%s\t%s\n' "$birth" "$f"
        done | sort -n
)

printf '%s\n' "$entries" | jq -r '
    if length == 0 then "[]"
    else "[\n  " + ([.[] | tojson] | join(",\n  ")) + "\n]"
    end
' > "$INDEX"
echo "Built index with $(jq 'length' "$INDEX") entries."
