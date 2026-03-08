#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/../public/static"
DIST_DIR="$BASE_DIR/files/dist"
STYLES_DIR="$BASE_DIR/files/styles"
JS_DIR="$BASE_DIR/files/js"
PAGES_DIR="$BASE_DIR/pages"

# Empty dist folder
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Build style.css with content hash
STYLE_HASH=$(md5sum "$STYLES_DIR/style.css" | cut -c1-8)
cp "$STYLES_DIR/style.css" "$DIST_DIR/style.${STYLE_HASH}.css"

# Build JS files with content hash
JS_SED_ARGS=()
for js_file in "$JS_DIR"/*.js; do
    [ -f "$js_file" ] || continue
    JS_NAME=$(basename "$js_file" .js)
    JS_HASH=$(md5sum "$js_file" | cut -c1-8)
    cp "$js_file" "$DIST_DIR/${JS_NAME}.${JS_HASH}.js"
    JS_SED_ARGS+=(-e "s|src=\"[^\"]*\" data-build=\"${JS_NAME}.js\"|src=\"/static/dist/${JS_NAME}.${JS_HASH}.js\" data-build=\"${JS_NAME}.js\"|g")
done

# Find all HTML files
find "$PAGES_DIR" -name '*.html' | while read -r file; do
    # Replace style.css with the hashed version
    sed -i "s|href=\"[^\"]*\" data-build=\"style.css\"|href=\"/static/dist/style.${STYLE_HASH}.css\" data-build=\"style.css\"|g" "$file"
    # Replace JS files with hashed versions
    if [ ${#JS_SED_ARGS[@]} -gt 0 ]; then
        sed -i "${JS_SED_ARGS[@]}" "$file"
    fi
done

echo "Build finished successfully."
