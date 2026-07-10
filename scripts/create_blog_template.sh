#!/usr/bin/env bash
#
# Creates a new blog post from a generic template.
#
# The metadata block mirrors the structure (and grouping) of existing posts,
# but with placeholder values. created_at is stamped with the current system
# time, modified_at is null, is_published=true, is_featured=false, tags=[]
# and topic=null. The body showcases common markdown features.

set -euo pipefail

# Resolve paths relative to the repo, regardless of where the script is run from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BLOGS_DIR="${REPO_ROOT}/containers/blog/templates/blogs"

OUT_FILE="${BLOGS_DIR}/new-blog-post.md"
CREATED_AT="$(date +%Y-%m-%dT%H:%M:%S%:z)"

mkdir -p "${BLOGS_DIR}"

cat > "${OUT_FILE}" <<EOF
### metadata
title: Blog post title
subtitle: A short subtitle
card_label: Category

seo_description: A concise, search-friendly description of this post.
embed_text: A short summary used when this post is shared or embedded.

is_published: true
is_featured: false

tags: []
topic: null

thumbnail: null

created_at: ${CREATED_AT}
modified_at: null
### metadata

## Introduction
This is a sample paragraph to get you started. You can write **bold text**, *italic text*, and even ***both at once***. Inline \`code\` sits nicely within a sentence too.

Here is a [link to somewhere](https://example.com) to round things out.

## Lists
An unordered list:

- First item
- Second item
  - A nested item
  - Another nested item
- Third item

An ordered list:

1. Step one
2. Step two
3. Step three

## Code blocks
Inline code looks like \`const answer = 42;\`, but longer snippets deserve a fenced block:

\`\`\`python
def greet(name: str) -> str:
    return f"Hello, {name}!"


print(greet("world"))
\`\`\`

And a shell example:

\`\`\`bash
echo "Building the site..."
npm run build
\`\`\`

## Blockquotes
> A well-placed quote can break up the rhythm of a post.
> It can even span multiple lines.

## Tables
| Feature    | Supported |
| ---------- | --------- |
| Headers    | Yes       |
| Lists      | Yes       |
| Codeblocks | Yes       |

## Closing words
Replace this content with your own. Happy writing!
EOF

# Print a path relative to the repo root for readability.
REL_PATH="${OUT_FILE#"${REPO_ROOT}/"}"
echo "Blog at ${REL_PATH} created"
echo "Now rename the markdown file to what the url stub will be, then edit the metadata and content."
echo -e "Once done, run \033[1mscripts/build_blog_htmls.sh\033[0m"
