#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOG_DIR="$SCRIPT_DIR/.."

BASE="$BLOG_DIR/templates/components/base.html"
NO_BLOGS="$BLOG_DIR/templates/components/no_blogs.html"
OUTPUT="$BLOG_DIR/static/pages/index.html"

if ! "$SCRIPT_DIR/build_index.sh"; then
    echo "Error: failed to build blog index." >&2
    exit 1
fi

# Run the webserver build
"$SCRIPT_DIR/../../webserver/scripts/build.sh"

if ! "$SCRIPT_DIR/validate_index.sh"; then
    awk 'FNR==NR { content=content $0 "\n"; next }
         /<main><\/main>/ { printf "%s", content; next }
         { print }' "$NO_BLOGS" "$BASE" > "$OUTPUT"
    # Fill base.html's SEO placeholders with the generic blog defaults.
    sed -i \
        -e 's|__PAGE_TITLE__|Blog — Luka Knežić|' \
        -e 's|__META_DESCRIPTION__|Notes and write-ups on backend systems, software architecture, and engineering experiments by Luka Knežić.|' \
        -e 's|__OG_DESCRIPTION__|Notes and write-ups on backend systems, software architecture, and engineering experiments.|' \
        -e 's|__OG_TITLE__|Blog — Luka Knežić|' \
        -e 's|__OG_URL__|https://luka-knezic.com/blog/|' \
        -e 's|__TWITTER_TITLE__|Blog — Luka Knežić|' \
        -e 's|__TWITTER_DESCRIPTION__|Notes and write-ups on backend systems, software architecture, and engineering experiments.|' \
        "$OUTPUT"
    echo "No blogs found. Generated index.html with no blogs message."
    # No publishable posts, prune any leftover per-post pages and sitemap
    "$SCRIPT_DIR/prune_orphan_post_pages.sh"
    "$SCRIPT_DIR/build_sitemap.sh"
    exit 0
fi

# Build /blog page
if ! "$SCRIPT_DIR/build_index_html_page.sh"; then
    echo "Error: failed to build blog index page." >&2
    exit 1
fi

# Build individual blog post pages
if ! "$SCRIPT_DIR/convert_markdown_to_html.sh"; then
    echo "Error: failed to convert markdown to HTML." >&2
    exit 1
fi

# Remove per-post pages whose source markdown was deleted or unpublished.
if ! "$SCRIPT_DIR/prune_orphan_post_pages.sh"; then
    echo "Error: failed to prune orphan post pages." >&2
    exit 1
fi

# Regenerate the sitemap from the current set of blog posts
if ! "$SCRIPT_DIR/build_sitemap.sh"; then
    echo "Error: failed to build sitemap." >&2
    exit 1
fi