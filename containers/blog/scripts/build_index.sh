#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOG_DIR="$SCRIPT_DIR/.."
BLOGS_DIR="$BLOG_DIR/templates/blogs"
INDEX="$BLOG_DIR/index.json"

GRADIENT_COUNT=6

# Deterministically pick one of GRADIENT_COUNT card gradients from a key, so the
# same post always gets the same colour. Baked into index.json here (rather than
# computed at page-build time) because the HTML page pre-renders only the first
# few cards; blog.js builds the rest from index.json and needs the colour too.
pick_gradient_class() {
    local key="$1" sum
    sum=$(printf '%s' "$key" | cksum | cut -d' ' -f1)
    printf 'blog-card-grad-%s' "$((sum % GRADIENT_COUNT))"
}

# A post's lastmod is sourced from blog metadata: use modified_at if set,
# else created_at. Both are RFC-3339 (validated by validate_blog_templates.sh),
# so they are emitted verbatim.

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

while IFS=$'\t' read -r created_epoch file; do
    name=$(basename "$file" .md)
    # Skip unpublished posts; they must not appear in index.json (validation
    # guarantees is_published is exactly "true"/"false", so a plain compare is safe).
    [ "$(meta_value "$file" is_published)" = "true" ] || continue
    card_label=$(meta_value "$file" card_label)
    title=$(meta_value "$file" title)
    subtitle=$(meta_value "$file" subtitle)
    is_featured=$(meta_value "$file" is_featured)
    tags=$(meta_value "$file" tags)
    topic=$(meta_value "$file" topic)
    thumbnail=$(meta_value "$file" thumbnail)
    created_at=$(meta_value "$file" created_at)
    modified_at=$(meta_value "$file" modified_at)

    [ -z "$title" ] && title="$name"
    # Fall back to sane JSON defaults so --argjson never chokes on an empty value
    [ -z "$is_featured" ] && is_featured=false
    [ -z "$tags" ] && tags='[]'
    [ -z "$topic" ] && topic=null
    [ -z "$thumbnail" ] && thumbnail=null

    # Gradient keyed on topic (falling back to title), matching how cards are coloured
    grad_key="$title"
    [ -n "$topic" ] && [ "$topic" != "null" ] && grad_key="$topic"
    gradient=$(pick_gradient_class "$grad_key")

    entry=$(jq -n \
        --arg name "$name" \
        --arg title "$title" \
        --arg card_label "$card_label" \
        --arg subtitle "$subtitle" \
        --arg created "$created_at" \
        --arg modified "$modified_at" \
        --arg gradient "$gradient" \
        --argjson is_featured "$is_featured" \
        --argjson tags "$tags" \
        --argjson topic "$topic" \
        --argjson thumbnail "$thumbnail" \
        '{name: $name, title: $title, created: $created, modified: ($modified | if . == "" or . == "null" then null else . end), tags: $tags, topic: $topic, thumbnail: $thumbnail, is_featured: $is_featured, card_label: $card_label, subtitle: $subtitle, gradient: $gradient}')

    entries=$(jq -n --argjson arr "$entries" --argjson entry "$entry" '$arr + [$entry]')
done < <(
    find "$BLOGS_DIR" -maxdepth 1 -mindepth 1 -name '*.md' -not -name '.gitkeep' -print0 |
        while IFS= read -r -d '' f; do
            printf '%s\t%s\n' "$(date -d "$(meta_value "$f" created_at)" +%s)" "$f"
        done | sort -t"$(printf '\t')" -k1,1n -k2,2V
)

printf '%s\n' "$entries" | jq -r '
    if length == 0 then "[]"
    else "[\n  " + ([.[] | tojson] | join(",\n  ")) + "\n]"
    end
' > "$INDEX"
echo "Built index with $(jq 'length' "$INDEX") entries."
