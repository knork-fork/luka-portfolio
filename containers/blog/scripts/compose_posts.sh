#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOG_DIR="$SCRIPT_DIR/.."

BASE="$BLOG_DIR/templates/components/base.html"
NO_BLOGS="$BLOG_DIR/templates/components/no_blogs.html"
OUTPUT="$BLOG_DIR/static/pages/index.html"

# Run the webserver build
"$SCRIPT_DIR/../../webserver/scripts/build.sh"

if ! "$SCRIPT_DIR/validate_index.sh"; then
    awk 'FNR==NR { content=content $0 "\n"; next }
         /<main><\/main>/ { printf "%s", content; next }
         { print }' "$NO_BLOGS" "$BASE" > "$OUTPUT"
    echo "No blogs found. Generated index.html with no blogs message." 
    exit 0
fi

"$SCRIPT_DIR/validate_blog_templates.sh" || exit $?

# TODO: render posts

echo "Posts composed successfully."