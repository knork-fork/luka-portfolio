### metadata
header: Tooling
title: My favourite command line tools
subtitle: The small utilities that quietly make every day faster.
seo_description: A tour of the small command line utilities that quietly make my day-to-day development faster.
is_featured: false
tags: ["CLI", "Tooling"]
topic: null
thumbnail: null
embed_text: The small command line tools that quietly make every day at the terminal a little faster.
### metadata

# My favourite command line tools

Most of my day happens in a terminal, so small ergonomic wins compound fast. These are
the tools I would reinstall first on a fresh machine.

## The shortlist

| Tool  | Replaces | Why I like it                  |
|-------|----------|--------------------------------|
| `rg`  | `grep`   | fast, respects `.gitignore`    |
| `fd`  | `find`   | sane defaults, readable syntax |
| `bat` | `cat`    | syntax highlighting + paging   |
| `jq`  | —        | slicing JSON without a script  |

## In practice

A search-and-preview loop I run constantly:

```bash
# every TODO left in tracked source, with context
rg -n "TODO|FIXME" --glob '!vendor' | bat --style=plain
```

Piping `fd` into a quick loop for bulk renames:

```bash
fd -e jpeg | while read -r f; do
  mv -- "$f" "${f%.jpeg}.jpg"
done
```

None of these are essential. Together they save a few minutes an hour, which is a lot
of minutes over a year.
