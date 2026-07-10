#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOG_DIR="$SCRIPT_DIR/.."
INDEX="$BLOG_DIR/index.json"
BASE="$BLOG_DIR/templates/components/base.html"
BLOG_HEADER="$BLOG_DIR/templates/components/blog_header.html"
CARD_TEMPLATE="$BLOG_DIR/templates/components/blog_card.html"
TAGS_TEMPLATE="$BLOG_DIR/templates/components/blog_card_tags.html"
TAG_TEMPLATE="$BLOG_DIR/templates/components/blog_card_tag.html"
FEATURED_TEMPLATE="$BLOG_DIR/templates/components/blog_featured_section.html"
GRID_TEMPLATE="$BLOG_DIR/templates/components/blog_grid.html"
CONTROLS_TEMPLATE="$BLOG_DIR/templates/components/blog_controls.html"
CHIP_TEMPLATE="$BLOG_DIR/templates/components/blog_filter_chip.html"
OUTPUT="$BLOG_DIR/static/pages/index.html"

# Only the first PREBAKE_COUNT cards are rendered into the static page (SEO /
# no-JS). blog.js reads the full list from the embedded #blog-index-data block
# and builds the remaining cards when filtering/paginating.
PREBAKE_COUNT=6

if ! "$SCRIPT_DIR/validate_index.sh"; then
    echo "Error: index validation failed." >&2
    exit 1
fi

html_escape() {
    jq -rn --arg s "$1" '$s | @html'
}

# Render a card's tags (a JSON array) via the tag components; nothing when empty
build_tags() {
    local tags_json="${1:-[]}" count items=""
    count=$(printf '%s' "$tags_json" | jq 'length' 2>/dev/null || echo 0)
    [ "$count" -gt 0 ] || return 0
    while IFS= read -r tag; do
        items+="$(render "$TAG_TEMPLATE" TAG "$(html_escape "$tag")")"$'\n'
    done < <(printf '%s' "$tags_json" | jq -r '.[]')
    render "$TAGS_TEMPLATE" TAGS "$items"
}

# Lowercase a tag and turn spaces into hyphens for use in class/data/URL slugs
slugify() {
    printf '%s' "$1" | tr '[:upper:] ' '[:lower:]-'
}

# Space-separated tag slugs for a card's data-tags attribute (used by the filter)
build_tag_slugs() {
    local tags_json="${1:-[]}" out=""
    while IFS= read -r tag; do
        [ -n "$tag" ] || continue
        out+="$(slugify "$tag") "
    done < <(printf '%s' "$tags_json" | jq -r '.[]?')
    printf '%s' "${out% }"
}

# Render the tag-filter chips from the deduped, sorted union of all post tags
build_tag_chips() {
    local items=""
    while IFS= read -r tag; do
        [ -n "$tag" ] || continue
        items+="$(render "$CHIP_TEMPLATE" TAG_SLUG "$(slugify "$tag")" TAG "$(html_escape "$tag")")"$'\n'
    done < <(jq -r '[.[].tags[]?] | unique | .[]' "$INDEX")
    printf '%s' "$items"
}

render() {
    local template="$1" file
    file="$(cat "$template")"
    shift
    while [ $# -ge 2 ]; do
        local placeholder="{{$1}}" value="$2"
        # Escape & so bash's ${//} doesn't treat it as "the matched text" (bash 5.1+)
        value="${value//&/\\&}"
        file="${file//$placeholder/$value}"
        shift 2
    done
    printf '%s\n' "$file"
}

emit_card() {
    local name="$1" title="$2" grad="$3" card_label="$4" subtitle="$5" extra_class="$6" tags="${7:-[]}"
    local card_class="blog-card $grad"
    [ -n "$extra_class" ] && card_class="$card_class $extra_class"
    # Straight ASCII apostrophe renders as a vertical tick; use the typographic one
    title="${title//\'/’}"
    render "$CARD_TEMPLATE" \
        CARD_CLASS "$card_class" \
        CARD_NAME "$(html_escape "$name")" \
        CARD_TAG_SLUGS "$(build_tag_slugs "$tags")" \
        CARD_TAGS "$(build_tags "$tags")" \
        CARD_LABEL "$(html_escape "$card_label")" \
        CARD_TITLE "$(html_escape "$title")" \
        CARD_SUBTITLE "$(html_escape "$subtitle")"
}

CONTENT_FILE="$(mktemp)"
trap 'rm -f "$CONTENT_FILE"' EXIT

{
    cat "$BLOG_HEADER"

    render "$CONTROLS_TEMPLATE" TAG_CHIPS "$(build_tag_chips)"

    featured="$(jq -c '[.[] | select(.is_featured == true)][0] // empty' "$INDEX")"
    if [ -n "$featured" ]; then
        f_name="$(printf '%s' "$featured" | jq -r '.name')"
        f_title="$(printf '%s' "$featured" | jq -r '.title')"
        f_grad="$(printf '%s' "$featured" | jq -r '.gradient')"
        f_card_label="$(printf '%s' "$featured" | jq -r '.card_label // ""')"
        f_subtitle="$(printf '%s' "$featured" | jq -r '.subtitle // ""')"
        f_tags="$(printf '%s' "$featured" | jq -c '.tags // []')"
        render "$FEATURED_TEMPLATE" FEATURED_CARD "$(emit_card "$f_name" "$f_title" "$f_grad" "$f_card_label" "$f_subtitle" "blog-card-featured" "$f_tags")"
    fi

    # Pre-render only the first PREBAKE_COUNT cards (newest first); blog.js builds
    # the rest from the embedded data block below.
    cards=""
    i=0
    while IFS= read -r entry; do
        [ "$i" -ge "$PREBAKE_COUNT" ] && break
        name="$(printf '%s' "$entry" | jq -r '.name')"
        title="$(printf '%s' "$entry" | jq -r '.title')"
        grad="$(printf '%s' "$entry" | jq -r '.gradient')"
        card_label="$(printf '%s' "$entry" | jq -r '.card_label // ""')"
        subtitle="$(printf '%s' "$entry" | jq -r '.subtitle // ""')"
        tags="$(printf '%s' "$entry" | jq -c '.tags // []')"
        cards+="$(emit_card "$name" "$title" "$grad" "$card_label" "$subtitle" "" "$tags")"$'\n'
        i=$((i + 1))
    done < <(jq -c 'sort_by(.created) | reverse | .[]' "$INDEX")

    # Full post list (newest first) embedded for blog.js: it hydrates the grid,
    # filters, and paginates client-side. Escape "<" so the JSON can't terminate
    # the <script> element early.
    blog_index_data="$(jq -c 'sort_by(.created) | reverse
        | [ .[] | {name, title, card_label, subtitle, tags, topic, gradient, is_featured} ]' "$INDEX")"
    blog_index_data="${blog_index_data//</\\u003c}"

    render "$GRID_TEMPLATE" GRID_CARDS "$cards" BLOG_INDEX_DATA "$blog_index_data"
} > "$CONTENT_FILE"

mkdir -p "$(dirname "$OUTPUT")"

awk 'FNR==NR { content=content $0 ORS; next }
     /<main><\/main>/ { printf "%s", content; next }
     { print }' "$CONTENT_FILE" "$BASE" > "$OUTPUT"

# The listing page is not a single post, so fill base.html's SEO placeholders
# with the generic blog defaults (delimiter "|" since the URL contains slashes).
sed -i \
    -e 's|__PAGE_TITLE__|Blog — Luka Knežić|' \
    -e 's|__META_DESCRIPTION__|Notes and write-ups on backend systems, software architecture, and engineering experiments by Luka Knežić.|' \
    -e 's|__OG_DESCRIPTION__|Notes and write-ups on backend systems, software architecture, and engineering experiments.|' \
    -e 's|__OG_TITLE__|Blog — Luka Knežić|' \
    -e 's|__OG_URL__|https://luka-knezic.com/blog/|' \
    -e 's|__TWITTER_TITLE__|Blog — Luka Knežić|' \
    -e 's|__TWITTER_DESCRIPTION__|Notes and write-ups on backend systems, software architecture, and engineering experiments.|' \
    "$OUTPUT"

echo "Blog index page built successfully."
