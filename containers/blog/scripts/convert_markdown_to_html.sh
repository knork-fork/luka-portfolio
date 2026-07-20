#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOGS_DIR="$SCRIPT_DIR/../templates/blogs"
BASE="$SCRIPT_DIR/../templates/components/base.html"
OUTPUT_DIR="$SCRIPT_DIR/../static/posts"
INDEX="$SCRIPT_DIR/../index.json"

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
MD_IMAGE="blog-markdown:3"

# Scratch space shared with the renderer container: bodies in, HTML fragments out.
# Kept inside the repo (under $HOME) because snap-confined Docker cannot bind-mount /tmp.
WORK="$(mktemp -d "$SCRIPT_DIR/.mdwork.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/in" "$WORK/out" "$WORK/main"

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

# Pass 1: reduce each post to its body markdown. Everything after the closing
# "### metadata" fence is the body. The leading top-level "# H1" is dropped
# because the title is rendered in the standalone article header instead (from
# the post's metadata), so keeping it here would duplicate the title.
while IFS= read -r -d '' file; do
    # Skip unpublished posts: don't render their bodies or build their pages.
    [ "$(meta_value "$file" is_published)" = "true" ] || continue
    stem="$(basename "$file" .md)"
    awk '
        /^### metadata$/ { seen++; next }
        seen < 2 { next }
        !started && /^[[:space:]]*$/ { next }   # skip blank lines before the body
        !started && /^# / { started = 1; next } # drop the leading H1 title
        { started = 1; print }
    ' "$file" > "$WORK/in/$stem.md"
done < <(find "$BLOGS_DIR" -maxdepth 1 -mindepth 1 -name '*.md' -print0)

# Build the renderer image once (idempotent), then convert every body in a single run.
if ! docker image inspect "$MD_IMAGE" >/dev/null 2>&1; then
    docker build -t "$MD_IMAGE" "$SCRIPT_DIR/markdown"
fi
docker run --rm -v "$WORK:/data" "$MD_IMAGE" /data/in /data/out

# Pass 2: fill each post's SEO placeholders and inject its rendered body.
while IFS= read -r -d '' file; do
    [ "$(meta_value "$file" is_published)" = "true" ] || continue
    name="$(basename "$file")"
    stem="${name%.md}"
    out="$OUTPUT_DIR/$stem.html"

    # Pull the metadata this post cares about (values may be the literal "null")
    seo_description="$(meta_value "$file" seo_description)"
    embed_text="$(meta_value "$file" embed_text)"
    title="$(meta_value "$file" title)"
    [ -z "$title" ] && title="$stem"
    subtitle="$(meta_value "$file" subtitle)"

    # Quiet metadata row: tag pills (from the post's metadata) + a single date
    # line (from index.json). Show "Updated <modified_at>" when the post has a
    # modified_at; otherwise "Published <created_at>".
    tags_html=""
    while IFS= read -r tag; do
        [ -n "$tag" ] || continue
        # Slug must match blog.js slugify() so /blog?tags=<slug> pre-selects it.
        tag_slug="$(printf '%s' "$tag" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
        tags_html+="          <li><a class=\"post-tag\" href=\"/blog?tags=$(html_escape "$tag_slug")\">$(html_escape "$tag")</a></li>"$'\n'
    done < <(printf '%s' "$(meta_value "$file" tags)" | jq -r '.[]? // empty' 2>/dev/null || true)

    date_html=""
    iso_modified="$(jq -r --arg n "$stem" '.[] | select(.name == $n) | .modified // empty' "$INDEX" 2>/dev/null || true)"
    iso_created="$(jq -r --arg n "$stem" '.[] | select(.name == $n) | .created // empty' "$INDEX" 2>/dev/null || true)"
    if [ -n "$iso_modified" ]; then
        date_label="Updated"
        iso_date="$iso_modified"
    else
        date_label="Published"
        iso_date="$iso_created"
    fi
    if [ -n "$iso_date" ]; then
        human_date="$(date -d "$iso_date" '+%b %-d, %Y' 2>/dev/null || true)"
        [ -n "$human_date" ] && \
            date_html="        <time class=\"post-date\" datetime=\"${iso_date%%T*}\">$date_label $human_date</time>"$'\n'
    fi

    # Gradient class (same as this post's blog card) for the full-width header.
    gradient="$(jq -r --arg n "$stem" '.[] | select(.name == $n) | .gradient // empty' "$INDEX" 2>/dev/null || true)"
    [ -z "$gradient" ] && gradient="blog-card-grad-0"

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

    # Assemble the inner <main>: back link, a standalone article header
    # (metadata + title + lead), then the rendered body in a separate content
    # card below it. Built into a file (not passed via awk -v) so backslashes
    # and "&" in real content are preserved verbatim.
    {
        printf '  <header class="post-header %s">\n' "$gradient"
        printf '    <div class="post-header-inner">\n'
        printf '      <a class="post-back" href="/blog">&larr; Back to Blog</a>\n'
        if [ -n "$tags_html" ] || [ -n "$date_html" ]; then
            printf '      <div class="post-meta">\n'
            if [ -n "$tags_html" ]; then
                printf '        <ul class="post-tags">\n'
                printf '%s' "$tags_html"
                printf '        </ul>\n'
            fi
            [ -n "$date_html" ] && printf '%s' "$date_html"
            printf '      </div>\n'
        fi
        printf '      <h1 class="post-title">%s</h1>\n' "$(html_escape "$title")"
        if [ -n "$subtitle" ] && [ "$subtitle" != "null" ]; then
            printf '      <p class="post-lead">%s</p>\n' "$(html_escape "$subtitle")"
        fi
        printf '    </div>\n'
        printf '  </header>\n'
        printf '  <div class="post-body">\n'
        printf '    <article class="post-card">\n'
        printf '      <div class="post-content">\n'
        cat "$WORK/out/$stem.html"
        printf '      </div>\n'
        printf '    </article>\n'
        printf '  </div>\n'
    } > "$WORK/main/$stem.html"

    # Inject the assembled article into base.html's empty <main></main>. The
    # <main> is full-bleed (no .page max-width) so the gradient header can span
    # the full page width; inner wrappers re-constrain the content.
    printf '%s\n' "$page" > "$WORK/page.html"
    awk 'FNR==NR { c = c $0 ORS; next }
         /<main><\/main>/ { printf "<main class=\"post\">\n%s</main>\n", c; next }
         { print }' "$WORK/main/$stem.html" "$WORK/page.html" > "$out"
done < <(find "$BLOGS_DIR" -maxdepth 1 -mindepth 1 -name '*.md' -print0)

echo "Posts converted successfully."
