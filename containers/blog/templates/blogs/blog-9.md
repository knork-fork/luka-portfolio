### metadata
header: Frontend
title: Rethinking how I use CSS grid
subtitle: Layouts got simpler once I stopped fighting the spec.
seo_description: Rethinking CSS grid — how my layouts got simpler once I stopped fighting the spec.
is_featured: false
tags: ["CSS", "Frontend"]
topic: null
thumbnail: null
embed_text: Rethinking how I use CSS grid — layouts got a lot simpler once I stopped fighting the spec.
### metadata

# Rethinking how I use CSS grid

I spent years bolting flexbox onto layouts that wanted to be grids. Once I let grid do
what it is good at, a lot of my CSS simply disappeared.

## Before: fighting the layout

```css
.cards { display: flex; flex-wrap: wrap; }
.card  { width: calc(33.333% - 1rem); margin: 0.5rem; }
```

Those magic `calc()`s broke every time the gap changed.

---

## After: describing the layout

```css
.cards {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 1rem;
}
```

The markup stays boring, which is the point:

```html
<div class="cards">
  <article class="card">…</article>
  <article class="card">…</article>
</div>
```

No media queries, no `calc()`, no margins fighting the gap. The grid reflows itself.
