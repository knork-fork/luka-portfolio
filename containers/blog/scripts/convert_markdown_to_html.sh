#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOGS_DIR="$SCRIPT_DIR/../templates/blogs"
BASE="$SCRIPT_DIR/../templates/components/base.html"
OUTPUT_DIR="$SCRIPT_DIR/../static/posts"

if ! "$SCRIPT_DIR/validate_blog_templates.sh"; then
    echo "Error: blog template validation failed." >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

while IFS= read -r -d '' file; do
    name="$(basename "$file")"
    stem="${name%.md}"
    out="$OUTPUT_DIR/$stem.html"

    # TODO - no markdown to HTML conversion yet, just output the name of the blog post
    main_content="<main style=\"display:flex;align-items:center;justify-content:center;min-height:60vh;\">\n  <p>$name</p>\n</main>"
    awk -v content="$main_content" '
        /<main><\/main>/ { print content; next }
        { print }
    ' "$BASE" > "$out"
done < <(find "$BLOGS_DIR" -maxdepth 1 -mindepth 1 -name '*.md' -print0)

echo "Posts converted successfully."
