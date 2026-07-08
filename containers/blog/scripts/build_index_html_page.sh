#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOG_DIR="$SCRIPT_DIR/.."
INDEX="$BLOG_DIR/index.json"
BASE="$BLOG_DIR/templates/components/base.html"
BLOG_HEADER="$BLOG_DIR/templates/components/blog_header.html"
CARD_TEMPLATE="$BLOG_DIR/templates/components/blog_card.html"
FEATURED_TEMPLATE="$BLOG_DIR/templates/components/blog_featured_section.html"
GRID_TEMPLATE="$BLOG_DIR/templates/components/blog_grid.html"
SHOW_MORE_TEMPLATE="$BLOG_DIR/templates/components/blog_show_more.html"
OUTPUT="$BLOG_DIR/static/pages/index.html"

GRADIENT_COUNT=6
VISIBLE_COUNT=6

if ! "$SCRIPT_DIR/validate_index.sh"; then
    echo "Error: index validation failed." >&2
    exit 1
fi

html_escape() {
    jq -rn --arg s "$1" '$s | @html'
}

pick_gradient_class() {
    local key="$1" sum
    sum=$(printf '%s' "$key" | cksum | cut -d' ' -f1)
    printf 'blog-card-grad-%s' "$((sum % GRADIENT_COUNT))"
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
    local name="$1" title="$2" topic="$3" header="$4" subtitle="$5" extra_class="$6"
    local key grad card_class
    key="${topic:-$title}"
    grad="$(pick_gradient_class "$key")"
    card_class="blog-card $grad"
    [ -n "$extra_class" ] && card_class="$card_class $extra_class"
    # Straight ASCII apostrophe renders as a vertical tick; use the typographic one
    title="${title//\'/’}"
    render "$CARD_TEMPLATE" \
        CARD_CLASS "$card_class" \
        CARD_NAME "$(html_escape "$name")" \
        CARD_EXTRA "$(html_escape "$header")" \
        CARD_TITLE "$(html_escape "$title")" \
        CARD_SUBTITLE "$(html_escape "$subtitle")"
}

CONTENT_FILE="$(mktemp)"
trap 'rm -f "$CONTENT_FILE"' EXIT

{
    cat "$BLOG_HEADER"

    featured="$(jq -c '[.[] | select(.is_featured == true)][0] // empty' "$INDEX")"
    if [ -n "$featured" ]; then
        f_name="$(printf '%s' "$featured" | jq -r '.name')"
        f_title="$(printf '%s' "$featured" | jq -r '.title')"
        f_topic="$(printf '%s' "$featured" | jq -r '.topic // ""')"
        f_header="$(printf '%s' "$featured" | jq -r '.header // ""')"
        f_subtitle="$(printf '%s' "$featured" | jq -r '.subtitle // ""')"
        render "$FEATURED_TEMPLATE" FEATURED_CARD "$(emit_card "$f_name" "$f_title" "$f_topic" "$f_header" "$f_subtitle" "blog-card-featured")"
    fi

    cards=""
    i=0
    while IFS= read -r entry; do
        name="$(printf '%s' "$entry" | jq -r '.name')"
        title="$(printf '%s' "$entry" | jq -r '.title')"
        topic="$(printf '%s' "$entry" | jq -r '.topic // ""')"
        header="$(printf '%s' "$entry" | jq -r '.header // ""')"
        subtitle="$(printf '%s' "$entry" | jq -r '.subtitle // ""')"
        extra_class=""
        [ "$i" -ge "$VISIBLE_COUNT" ] && extra_class="blog-card-hidden"
        cards+="$(emit_card "$name" "$title" "$topic" "$header" "$subtitle" "$extra_class")"$'\n'
        i=$((i + 1))
    done < <(jq -c 'sort_by(.created) | reverse | .[]' "$INDEX")

    show_more=""
    total="$(jq 'length' "$INDEX")"
    [ "$total" -gt "$VISIBLE_COUNT" ] && show_more="$(cat "$SHOW_MORE_TEMPLATE")"

    render "$GRID_TEMPLATE" GRID_CARDS "$cards" SHOW_MORE "$show_more"
} > "$CONTENT_FILE"

mkdir -p "$(dirname "$OUTPUT")"

awk 'FNR==NR { content=content $0 ORS; next }
     /<main><\/main>/ { printf "%s", content; next }
     { print }' "$CONTENT_FILE" "$BASE" > "$OUTPUT"

echo "Blog index page built successfully."
