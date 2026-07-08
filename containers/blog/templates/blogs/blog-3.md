### metadata
header: Design notes
title: Building a design system from scratch
subtitle: Lessons learned setting up tokens, components and documentation.
seo_description: How I built a design system from scratch, covering design tokens, reusable components, and documentation.
is_featured: false
tags: ["Design", "CSS", "Components"]
topic: null
thumbnail: null
embed_text: Building a design system from scratch — tokens, reusable components, and docs that people actually read.
### metadata

# Building a design system from scratch

A design system for a one-person project sounds like overkill. It isn't. Even a *tiny*
set of tokens keeps every page feeling like the same website.

## Start with tokens, not components

Colours, spacing and type live in one place as CSS custom properties:

```css
:root {
  --color-bg: #fafaf9;
  --color-text: #1c1917;
  --color-accent: #2563eb;
  --font-sans: "Inter", system-ui, sans-serif;
}
```

The same values can be exported as JSON for tooling:

```json
{
  "color": { "bg": "#fafaf9", "text": "#1c1917", "accent": "#2563eb" },
  "font": { "sans": "Inter, system-ui, sans-serif" }
}
```

## A quick token reference

| Token            | Value     | Used for            |
|------------------|-----------|---------------------|
| `--color-accent` | `#2563eb` | links, active state |
| `--color-border` | `#e7e5e4` | hairlines, cards    |

## Where I am

- [x] Colour + type tokens
- [x] Buttons and links
- [ ] Form controls
- [ ] Dark theme

Ship the tokens first; the components fall out of them.
