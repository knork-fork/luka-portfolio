### metadata
header: Side projects
title: Shipping a weekend project without burning out
subtitle: Scoping ruthlessly so the fun does not turn into a chore.
seo_description: How to scope a weekend project ruthlessly so shipping it stays fun instead of becoming a chore.
is_featured: false
tags: []
topic: null
thumbnail: null
embed_text: Shipping a weekend project without burning out — scoping ruthlessly so the fun doesn't turn into a chore.
### metadata

# Shipping a weekend project without burning out

I have a graveyard of half-finished side projects. The ones I actually *finished* have
one thing in common: I scoped them until they were almost embarrassingly small.

## Cut the scope, then cut it again

Write the version-one feature list, then delete half of it:

- [x] One thing the app does well
- [x] The plainest possible UI
- [ ] Accounts and login
- [ ] A settings page
- [ ] The clever feature that made you excited

Those unchecked items are v2 — *if there is a v2*.

## Keep the setup trivial

A `package.json` a future-you can run without thinking:

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build"
  }
}
```

```bash
npm install && npm run dev
```

> A finished project you are slightly bored of beats a perfect one you never shipped.
