#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOG_DIR="$SCRIPT_DIR/.."
BLOGS_DIR="$BLOG_DIR/templates/blogs"
SITEMAP="$BLOG_DIR/sitemap.xml"

BASE_URL="https://luka-knezic.com"

# Emit the epoch of the file's last content change as recorded by git.
#
# Filesystem timestamps (birth/mtime) are unusable here: git does not preserve
# them, so a clone, checkout, or any regeneration of the file resets them to
# "now" and the sitemap's lastmod is bumped on every build even when nothing
# changed. Git's last-commit date is stable and only advances when the post's
# content actually changes. Fall back to mtime for files not yet committed.
lastmod_epoch_of() {
    local file="$1" epoch
    epoch="$(git -C "$BLOG_DIR" log -1 --format='%ct' -- "$file" 2>/dev/null || true)"
    if [ -z "$epoch" ]; then
        epoch="$(stat --format='%Y' "$file")"
    fi
    printf '%s' "$epoch"
}

lastmod_of() {
    date -d "@$(lastmod_epoch_of "$1")" +%Y-%m-%dT%H:%M:%S%:z
}

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
        [ "$(meta_value "$file" is_published)" = "true" ] || continue
        epoch="$(lastmod_epoch_of "$file")"
        [ "$epoch" -gt "$newest_epoch" ] && newest_epoch="$epoch"
    done < <(find "$BLOGS_DIR" -maxdepth 1 -mindepth 1 -name '*.md' -print0)

    if [ "$newest_epoch" -gt 0 ]; then
        emit_url "$BASE_URL/blog" "$(date -d "@$newest_epoch" +%Y-%m-%dT%H:%M:%S%:z)"
    fi

    # One entry per blog post, sorted by slug for stable output.
    while IFS= read -r -d '' file; do
        [ "$(meta_value "$file" is_published)" = "true" ] || continue
        name="$(basename "$file")"
        stem="${name%.md}"
        emit_url "$BASE_URL/blog/$stem" "$(lastmod_of "$file")"
    done < <(find "$BLOGS_DIR" -maxdepth 1 -mindepth 1 -name '*.md' -print0 | LC_ALL=C sort -z)

    printf '</urlset>\n'
} > "$SITEMAP"

echo "Sitemap written to $SITEMAP"
