#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/../public/static"
DIST_DIR="$BASE_DIR/files/dist"
STYLES_DIR="$BASE_DIR/files/styles"
PAGES_DIR="$BASE_DIR/pages"

# Empty dist folder
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Build style.css with content hash
STYLE_HASH=$(md5sum "$STYLES_DIR/style.css" | cut -c1-8)
cp "$STYLES_DIR/style.css" "$DIST_DIR/style.${STYLE_HASH}.css"

# Find all HTML files
find "$PAGES_DIR" -name '*.html' | while read -r file; do
    # Replace style.css with the hashed version
    sed -i "s|href=\"[^\"]*\" data-build=\"style.css\"|href=\"/static/dist/style.${STYLE_HASH}.css\" data-build=\"style.css\"|g" "$file"
done

echo "Build finished successfully."
