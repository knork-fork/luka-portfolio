FROM node:20-alpine

WORKDIR /app

# Install pinned deps first so the layer is cached across builds.
COPY package.json package-lock.json* ./
RUN npm install --omit=dev --silent

# esbuild picks the JS/CSS minifier from the input file's extension. Args passed
# to `docker run` (input path, --minify, --outfile=...) append to this entrypoint.
ENTRYPOINT ["node_modules/.bin/esbuild"]
