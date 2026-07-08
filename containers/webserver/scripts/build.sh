#!/usr/bin/env bash
set -euo pipefail

# By default JS and CSS are minified on their way into dist. Pass
# --no-minimization to copy them verbatim instead (e.g. for debugging).
MINIFY=true
for arg in "$@"; do
    case "$arg" in
        --no-minimization) MINIFY=false ;;
        *)
            echo "Unknown argument: $arg" >&2
            echo "Usage: build.sh [--no-minimization]" >&2
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/../static"
DIST_DIR="$BASE_DIR/files/dist"
STYLES_DIR="$BASE_DIR/files/styles"
JS_DIR="$BASE_DIR/files/js"
PAGES_DIR="$BASE_DIR/pages"
BLOG_TEMPLATES_DIR="$SCRIPT_DIR/../../blog/templates/components"
BLOG_PAGES_DIR="$SCRIPT_DIR/../../blog/static/pages"
BLOG_POSTS_DIR="$SCRIPT_DIR/../../blog/static/posts"

# Docker image that minifies JS/CSS with esbuild (see scripts/minify/).
# Bump the tag whenever scripts/minify/ changes to force a rebuild.
MINIFY_IMAGE="portfolio-minify:1"
if [ "$MINIFY" = true ]; then
    if ! docker image inspect "$MINIFY_IMAGE" >/dev/null 2>&1; then
        docker build -t "$MINIFY_IMAGE" "$SCRIPT_DIR/minify"
    fi
fi

# emit_asset SRC DEST: place an asset into dist. When minification is enabled,
# run it through esbuild (which picks the JS/CSS minifier from the extension);
# otherwise copy it verbatim. Paths are relative to $BASE_DIR/files, which is
# mounted into the container so esbuild can read the source and write to dist.
emit_asset() {
    local src="$1" dest="$2"
    if [ "$MINIFY" = true ]; then
        docker run --rm --user "$(id -u):$(id -g)" \
            -v "$BASE_DIR/files:/work" \
            "$MINIFY_IMAGE" "/work/${src}" --minify "--outfile=/work/${dest}"
    else
        cp "$BASE_DIR/files/$src" "$BASE_DIR/files/$dest"
    fi
}

# Empty dist folder
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Build style.css with content hash (hash tracks the source, so it changes
# whenever the authored CSS does, independent of minification).
STYLE_HASH=$(md5sum "$STYLES_DIR/style.css" | cut -c1-8)
emit_asset "styles/style.css" "dist/style.${STYLE_HASH}.css"

# Build JS files with content hash
JS_SED_ARGS=()
for js_file in "$JS_DIR"/*.js; do
    [ -f "$js_file" ] || continue
    JS_NAME=$(basename "$js_file" .js)
    JS_HASH=$(md5sum "$js_file" | cut -c1-8)
    emit_asset "js/${JS_NAME}.js" "dist/${JS_NAME}.${JS_HASH}.js"
    JS_SED_ARGS+=(-e "s|src=\"[^\"]*\" data-build=\"${JS_NAME}.js\"|src=\"/static/dist/${JS_NAME}.${JS_HASH}.js\" data-build=\"${JS_NAME}.js\"|g")
done

# Find all HTML files
HTML_SEARCH_DIRS=("$PAGES_DIR")
[ -d "$BLOG_TEMPLATES_DIR" ] && HTML_SEARCH_DIRS+=("$BLOG_TEMPLATES_DIR")
[ -d "$BLOG_PAGES_DIR" ] && HTML_SEARCH_DIRS+=("$BLOG_PAGES_DIR")
[ -d "$BLOG_POSTS_DIR" ] && HTML_SEARCH_DIRS+=("$BLOG_POSTS_DIR")
find "${HTML_SEARCH_DIRS[@]}" -name '*.html' | while read -r file; do
    # Replace style.css with the hashed version
    sed -i "s|href=\"[^\"]*\" data-build=\"style.css\"|href=\"/static/dist/style.${STYLE_HASH}.css\" data-build=\"style.css\"|g" "$file"
    # Replace JS files with hashed versions
    if [ ${#JS_SED_ARGS[@]} -gt 0 ]; then
        sed -i "${JS_SED_ARGS[@]}" "$file"
    fi
done

echo "Build finished successfully."
