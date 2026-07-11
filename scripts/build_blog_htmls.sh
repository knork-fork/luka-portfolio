#!/usr/bin/env bash
set -euo pipefail

# Thin wrapper: delegate to the blog container's compose_posts.sh.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$SCRIPT_DIR/../containers/blog/scripts/compose_posts.sh" "$@"
