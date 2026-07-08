### metadata
header: Performance
title: Shaving milliseconds off page loads
subtitle: Practical wins from lazy loading and smaller bundles.
seo_description: Practical performance wins for faster page loads, from lazy loading to shrinking JavaScript bundles.
is_featured: false
tags: ["Performance", "Web"]
topic: null
thumbnail: null
embed_text: Practical wins for faster page loads — lazy loading, smaller bundles, and shaving off the milliseconds that add up.
### metadata

# Shaving milliseconds off page loads

Performance work is unglamorous and *addictive*. You chase a 200ms win, ship it, and
immediately go looking for the next one.

## Measure first

Before touching anything, grab real numbers:

| Metric  | Before | After  |
|---------|--------|--------|
| LCP     | 2.9s   | 1.4s   |
| JS sent | 480 KB | 120 KB |

---

## Load what you need, when you need it

Deferring off-screen images is almost free:

```html
<img src="/hero.avif" alt="" loading="lazy" decoding="async">
```

And code-split the parts most visitors never reach:

```js
button.addEventListener("click", async () => {
  const { openEditor } = await import("./editor.js");
  openEditor();
});
```

The fastest code is the code you never send.
