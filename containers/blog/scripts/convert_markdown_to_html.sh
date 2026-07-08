#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOGS_DIR="$SCRIPT_DIR/../templates/blogs"
BASE="$SCRIPT_DIR/../templates/components/base.html"
OUTPUT_DIR="$SCRIPT_DIR/../static/posts"

# Public site root; per-post canonical URLs are built from this.
SITE_URL="https://luka-knezic.com/blog"

# Defaults used when a post leaves the corresponding metadata key null/empty.
# These mirror the fallback copy that base.html shipped before placeholders.
DEFAULT_META_DESCRIPTION="Notes and write-ups on backend systems, software architecture, and engineering experiments by Luka Knežić."
DEFAULT_EMBED_DESCRIPTION="Notes and write-ups on backend systems, software architecture, and engineering experiments."

if ! "$SCRIPT_DIR/validate_blog_templates.sh"; then
    echo "Error: blog template validation failed." >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Docker image that renders markdown bodies to HTML in bulk (see scripts/markdown/).
# Bump the tag whenever scripts/markdown/ changes to force a rebuild.
MD_IMAGE="blog-markdown:1"

# Scratch space shared with the renderer container: bodies in, HTML fragments out.
# Kept inside the repo (under $HOME) because snap-confined Docker cannot bind-mount /tmp.
WORK="$(mktemp -d "$SCRIPT_DIR/.mdwork.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/in" "$WORK/out"

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

# HTML-escape a value so it is safe inside a double-quoted attribute
html_escape() {
    jq -rn --arg s "$1" '$s | @html'
}

# Replace a placeholder token in the global $page with an (already escaped) value.
# The "&" dance keeps bash's ${//} (5.1+) from treating "&" as the matched text.
apply() {
    local token="$1" value="$2"
    value="${value//&/\\&}"
    page="${page//$token/$value}"
}

# Pass 1: strip each post's "### metadata" block, leaving just the body markdown.
# Everything after the closing "### metadata" fence is the body; the fence line
# itself is not emitted because seen is still 1 when the print rule runs for it.
while IFS= read -r -d '' file; do
    stem="$(basename "$file" .md)"
    awk 'seen==2 { print } /^### metadata$/ { seen++ }' "$file" > "$WORK/in/$stem.md"
done < <(find "$BLOGS_DIR" -maxdepth 1 -mindepth 1 -name '*.md' -print0)

# Build the renderer image once (idempotent), then convert every body in a single run.
if ! docker image inspect "$MD_IMAGE" >/dev/null 2>&1; then
    docker build -t "$MD_IMAGE" "$SCRIPT_DIR/markdown"
fi
docker run --rm -v "$WORK:/data" "$MD_IMAGE" /data/in /data/out

# Pass 2: fill each post's SEO placeholders and inject its rendered body.
while IFS= read -r -d '' file; do
    name="$(basename "$file")"
    stem="${name%.md}"
    out="$OUTPUT_DIR/$stem.html"

    # Pull the metadata this post cares about (values may be the literal "null")
    seo_description="$(meta_value "$file" seo_description)"
    embed_text="$(meta_value "$file" embed_text)"
    title="$(meta_value "$file" title)"
    [ -z "$title" ] && title="$stem"

    # <meta name="description"> uses seo_description, else the base.html default
    meta_description="$DEFAULT_META_DESCRIPTION"
    if [ -n "$seo_description" ] && [ "$seo_description" != "null" ]; then
        meta_description="$seo_description"
    fi

    # og:/twitter: descriptions use embed_text, else the base.html default
    embed_description="$DEFAULT_EMBED_DESCRIPTION"
    if [ -n "$embed_text" ] && [ "$embed_text" != "null" ]; then
        embed_description="$embed_text"
    fi

    og_url="$SITE_URL/$stem"

    # Fill the SEO placeholders in base.html for this specific post
    page="$(cat "$BASE")"
    apply __META_DESCRIPTION__ "$(html_escape "$meta_description")"
    apply __OG_DESCRIPTION__ "$(html_escape "$embed_description")"
    apply __TWITTER_DESCRIPTION__ "$(html_escape "$embed_description")"
    apply __PAGE_TITLE__ "$(html_escape "$title — Luka Knežić")"
    apply __OG_TITLE__ "$(html_escape "$title")"
    apply __TWITTER_TITLE__ "$(html_escape "$title")"
    apply __OG_URL__ "$(html_escape "$og_url")"

    # Inject the rendered body into base.html's empty <main></main>. The body is
    # read from a file (not passed via awk -v) so backslashes and "&" in real
    # content are preserved verbatim; mirrors the FNR==NR merge in compose_posts.sh.
    printf '%s\n' "$page" > "$WORK/page.html"
    awk 'FNR==NR { c = c $0 ORS; next }
         /<main><\/main>/ { printf "<main class=\"page post-content\">\n%s</main>\n", c; next }
         { print }' "$WORK/out/$stem.html" "$WORK/page.html" > "$out"
done < <(find "$BLOGS_DIR" -maxdepth 1 -mindepth 1 -name '*.md' -print0)

echo "Posts converted successfully."
