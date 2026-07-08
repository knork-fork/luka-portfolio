FROM node:20-alpine

WORKDIR /app

# Install pinned deps first so the layer is cached across builds.
COPY package.json package-lock.json* ./
RUN npm install --omit=dev --silent

COPY render_markdown.mjs ./

ENTRYPOINT ["node", "render_markdown.mjs"]
