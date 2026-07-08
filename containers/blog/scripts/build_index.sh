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

entries="[]"

while IFS=$'\t' read -r birth file; do
    name=$(basename "$file" .md)
    title=$(awk '/^# / { sub(/^# /, ""); print; exit }' "$file")
    [ -z "$title" ] && title="$name"
    mtime=$(stat -c "%Y" "$file")
    created=$(date -d "@$birth" --iso-8601=seconds)
    modified=$(date -d "@$mtime" --iso-8601=seconds)

    entry=$(jq -n \
        --arg name "$name" \
        --arg title "$title" \
        --arg created "$created" \
        --arg modified "$modified" \
        '{name: $name, title: $title, created: $created, modified: $modified, tags: [], topic: null, thumbnail: null, is_featured: false}')

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
