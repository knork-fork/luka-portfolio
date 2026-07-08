### metadata
header: Career
title: Notes from my first year as a developer
subtitle: What I wish I had known before writing production code.
seo_description: Lessons from my first year as a developer and what I wish I had known before shipping production code.
is_featured: false
tags: ["Career"]
topic: null
thumbnail: null
embed_text: Notes from my first year as a developer — the things I wish I had known before writing production code.
### metadata

# Notes from my first year as a developer

A year ago I could not have told you what a *merge conflict* was. Here are the things I
wish someone had told me on day one.

## Things that actually mattered

1. **Reading** code is a bigger part of the job than writing it
2. Small, frequent commits beat one heroic one
3. Asking a "dumb" question early is cheaper than guessing for a day

## The habit that helped most

Committing often, with messages my future self could read:

```bash
git add -p                 # stage in small, reviewable chunks
git commit -m "Fix off-by-one in pagination"
```

> Nobody remembers the junior who asked too many questions. Everyone remembers the one
> who silently shipped a bug to production.

Be kind to your future self. They are the one reading your git log at 2am.
