### metadata
header: Bloggy blog
title: Personal portfolio blog
subtitle: Personal portfolio page with a blog and featured projects.
seo_description: A walkthrough of building my personal portfolio — a static blog and featured projects wired together with simple shell build scripts.
is_featured: true
tags: ["Portfolio", "Web"]
topic: null
thumbnail: null
embed_text: Building a personal portfolio: a static blog and featured projects, glued together with plain shell scripts.
### metadata

## Building my portfolio blog

This site is intentionally boring: **static HTML**, a pinch of CSS, and a handful of
shell scripts. No framework, no database, no build server. Here is how the pieces fit
together.

## The moving parts

- **Templates** — hand-written HTML components in `templates/`
- **Posts** — plain markdown files, one per entry
  - metadata lives in a `### metadata` block at the top
  - everything below it is the body you are reading now
- **Scripts** — glue that stitches templates and posts into pages

## The build

Writing a post is just dropping a markdown file and running one script:

```bash
# render every post + rebuild the index and sitemap
containers/blog/scripts/compose_posts.sh
```

Each post is wrapped in the shared layout with a tiny `<main>` swap:

```html
<main class="page post-content">
  <!-- rendered markdown goes here -->
</main>
```

That is the whole trick. The full source lives on [GitHub](https://github.com/knork-fork).

> Simple tools you understand beat clever tools you don't.
