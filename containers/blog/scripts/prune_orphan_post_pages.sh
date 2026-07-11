#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOGS_DIR="$SCRIPT_DIR/../templates/blogs"
OUTPUT_DIR="$SCRIPT_DIR/../static/posts"

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

# Nothing generated yet, nothing to prune.
[ -d "$OUTPUT_DIR" ] || exit 0

# Drop any built post page whose source markdown was deleted or unpublished.
# The post's filename stem is the shared key: static/posts/<stem>.html maps back
# to templates/blogs/<stem>.md.
shopt -s nullglob
for html in "$OUTPUT_DIR"/*.html; do
    stem="$(basename "$html" .html)"
    src="$BLOGS_DIR/$stem.md"
    if [ ! -f "$src" ] || [ "$(meta_value "$src" is_published)" != "true" ]; then
        rm -f "$html"
        echo "Pruned orphan post page: $stem.html"
    fi
done
