### metadata
header: Backend bits
title: Why I switched to containers
subtitle: A short story about reproducible builds and fewer surprises.
seo_description: Why I moved my projects to containers, and how reproducible builds cut down on surprises.
is_featured: false
tags: ["Docker", "DevOps"]
topic: null
thumbnail: null
embed_text: Why I switched to containers, and how reproducible builds turned "works on my machine" into fewer surprises.
### metadata

# Why I switched to containers

"Works on my machine" used to be a running joke on every project I touched. Containers
did not make me a better engineer — they just deleted an entire category of problem.

## What changed

1. The environment is **code**, reviewed like any other file
2. Onboarding is one command instead of a wiki page
3. Production and local drift far less

## A minimal image

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev
COPY . .
CMD ["node", "server.js"]
```

## Wiring it up

```yaml
services:
  app:
    build: .
    ports:
      - "3000:3000"
```

Then the entire stack starts with:

```bash
docker compose up --build
```

> The goal isn't containers for their own sake — it's making the boring parts
> reproducible so you can spend attention on the interesting parts.
