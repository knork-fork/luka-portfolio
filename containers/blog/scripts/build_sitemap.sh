#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOG_DIR="$SCRIPT_DIR/.."
BLOGS_DIR="$BLOG_DIR/templates/blogs"
SITEMAP="$BLOG_DIR/sitemap.xml"

BASE_URL="https://luka-knezic.com"

# Emit the file's creation (birth) time as a W3C datetime, falling back to the
# modification time when the filesystem does not record a birth time.
lastmod_of() {
    local file="$1" epoch
    epoch="$(stat --format='%W' "$file")"
    if [ "$epoch" = "0" ] || [ "$epoch" = "-" ]; then
        epoch="$(stat --format='%Y' "$file")"
    fi
    date -d "@$epoch" +%Y-%m-%dT%H:%M:%S%:z
}

xml_escape() {
    local s="$1"
    s="${s//&/&amp;}"
    s="${s//</&lt;}"
    s="${s//>/&gt;}"
    printf '%s' "$s"
}

emit_url() {
    local loc="$1" lastmod="$2"
    printf '  <url>\n'
    printf '    <loc>%s</loc>\n' "$(xml_escape "$loc")"
    printf '    <lastmod>%s</lastmod>\n' "$lastmod"
    printf '  </url>\n'
}

{
    printf '<?xml version="1.0" encoding="UTF-8"?>\n'
    printf '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'

    # Blog index. Use the most recently created post as its lastmod so the
    # listing page's freshness tracks its newest entry.
    newest_epoch=0
    while IFS= read -r -d '' file; do
        epoch="$(stat --format='%W' "$file")"
        { [ "$epoch" = "0" ] || [ "$epoch" = "-" ]; } && epoch="$(stat --format='%Y' "$file")"
        [ "$epoch" -gt "$newest_epoch" ] && newest_epoch="$epoch"
    done < <(find "$BLOGS_DIR" -maxdepth 1 -mindepth 1 -name '*.md' -print0)

    if [ "$newest_epoch" -gt 0 ]; then
        emit_url "$BASE_URL/blog" "$(date -d "@$newest_epoch" +%Y-%m-%dT%H:%M:%S%:z)"
    fi

    # One entry per blog post, sorted by slug for stable output.
    while IFS= read -r -d '' file; do
        name="$(basename "$file")"
        stem="${name%.md}"
        emit_url "$BASE_URL/blog/$stem" "$(lastmod_of "$file")"
    done < <(find "$BLOGS_DIR" -maxdepth 1 -mindepth 1 -name '*.md' -print0 | LC_ALL=C sort -z)

    printf '</urlset>\n'
} > "$SITEMAP"

echo "Sitemap written to $SITEMAP"
