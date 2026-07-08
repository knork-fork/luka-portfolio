### metadata
header: Bloggy blog
title: Another personal portfolio blog
subtitle: Second blog post
seo_description: The second post in my portfolio series, with more notes on running a small personal blog.
is_featured: false
tags: ["Portfolio"]
topic: null
thumbnail: null
embed_text: More notes from running a small personal blog — the second entry in my portfolio series.
### metadata

# Serving the blog

The first post covered the build. This one is about **serving** the output — which,
for a static site, is refreshingly little work.

## One container per surface

Each surface is its own nginx container:

| Container   | Purpose            | Port  |
|-------------|--------------------|-------|
| `webserver` | main site          | 20242 |
| `blog`      | the blog you're on | 20243 |

## The nginx bit

Clean URLs (`/blog/my-post` instead of `/blog/my-post.html`) take one directive:

```nginx
location /blog/ {
    try_files $uri $uri.html $uri/ =404;
}
```

Wiring the container up is a few lines of compose:

```yaml
blog:
  image: nginx:latest
  volumes:
    - './containers/blog:/application'
  ports:
    - "20243:80"
```

> If your deploy needs a runbook, it is probably too complicated for a personal site.
