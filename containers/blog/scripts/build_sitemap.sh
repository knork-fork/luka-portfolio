#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOG_DIR="$SCRIPT_DIR/.."
BLOGS_DIR="$BLOG_DIR/templates/blogs"
SITEMAP="$BLOG_DIR/sitemap.xml"

BASE_URL="https://luka-knezic.com"

# A post's lastmod is sourced from blog metadata: use modified_at if set,
# else created_at. Both are RFC-3339 (validated by validate_blog_templates.sh),
# so they are emitted verbatim.
lastmod_of() {
    local file="$1" modified
    modified="$(meta_value "$file" modified_at)"
    if [ -n "$modified" ] && [ "$modified" != "null" ]; then
        printf '%s' "$modified"
    else
        meta_value "$file" created_at
    fi
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

# Collect one "loc<TAB>lastmod" line per published post, sorted by slug for
# stable output.
post_entries=""
while IFS= read -r -d '' file; do
    [ "$(meta_value "$file" is_published)" = "true" ] || continue
    stem="$(basename "$file" .md)"
    post_entries+="$BASE_URL/blog/$stem"$'\t'"$(lastmod_of "$file")"$'\n'
done < <(find "$BLOGS_DIR" -maxdepth 1 -mindepth 1 -name '*.md' -print0 | LC_ALL=C sort -z)

# The /blog listing's lastmod tracks *listing* changes only: a post added or
# removed, or a post's lastmod changing. It must NOT move when unrelated files
# (CSS, templates) are rebuilt. So diff the current post set against the previous
# sitemap: reuse the old /blog lastmod when the set is byte-identical, otherwise
# re-stamp with the current build time.
new_sig="$post_entries"
old_sig=""
old_blog_lastmod=""
if [ -f "$SITEMAP" ]; then
    # Pair each <loc> with the <lastmod> that follows it (POSIX awk, no gawk
    # capture-group extension). The /blog entry is set aside; the rest is the
    # comparison signature.
    while IFS=$'\t' read -r loc lastmod; do
        [ -n "$loc" ] || continue
        if [ "$loc" = "$BASE_URL/blog" ]; then
            old_blog_lastmod="$lastmod"
        else
            old_sig+="$loc"$'\t'"$lastmod"$'\n'
        fi
    done < <(awk '
        /<loc>/     { s=$0; sub(/.*<loc>/,"",s);     sub(/<\/loc>.*/,"",s);     loc=s; next }
        /<lastmod>/ { s=$0; sub(/.*<lastmod>/,"",s); sub(/<\/lastmod>.*/,"",s); print loc "\t" s }
    ' "$SITEMAP")
fi

if [ "$new_sig" = "$old_sig" ] && [ -n "$old_blog_lastmod" ]; then
    blog_lastmod="$old_blog_lastmod"
else
    blog_lastmod="$(date +%Y-%m-%dT%H:%M:%S%:z)"
fi

{
    printf '<?xml version="1.0" encoding="UTF-8"?>\n'
    printf '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'

    # Blog index entry — only when there is at least one published post.
    if [ -n "$post_entries" ]; then
        emit_url "$BASE_URL/blog" "$blog_lastmod"
    fi

    # One entry per blog post, already sorted by slug.
    while IFS=$'\t' read -r loc lastmod; do
        [ -n "$loc" ] || continue
        emit_url "$loc" "$lastmod"
    done <<< "$post_entries"

    printf '</urlset>\n'
} > "$SITEMAP"

echo "Sitemap written to $SITEMAP"
