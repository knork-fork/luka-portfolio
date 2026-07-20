// Bulk markdown -> HTML converter for blog post bodies.
//
// Reads every *.md file in <inDir> and writes an HTML fragment (the inner
// content that gets dropped into <main>) with the same stem to <outDir>.
// One Node process handles the whole batch so the caller only pays for a
// single `docker run`.
//
// Usage: node render_markdown.mjs <inDir> <outDir>

import MarkdownIt from 'markdown-it';
import taskLists from 'markdown-it-task-lists';
import hljs from 'highlight.js';
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, basename } from 'node:path';

const md = new MarkdownIt({
  html: true, // blog bodies are author-trusted, so allow raw HTML
  linkify: true, // turn bare URLs into links (GFM autolinks)
  typographer: true, // smart quotes / dashes
  highlight(str, lang) {
    const code =
      lang && hljs.getLanguage(lang)
        ? hljs.highlight(str, { language: lang, ignoreIllegals: true }).value
        : md.utils.escapeHtml(str);
    // Emit a full <pre> so markdown-it uses it verbatim; the `hljs` class is
    // what the highlight theme in style.css hooks onto.
    const cls = lang ? ` class="language-${md.utils.escapeHtml(lang)}"` : '';
    return `<pre class="hljs"><code${cls}>${code}</code></pre>\n`;
  },
}).use(taskLists); // GFM tables + strikethrough are on by default in markdown-it

// Turn a standalone image or video (a line that is only an <img>/<video>,
// optionally wrapped in a single <p> as markdown-it does for `![alt](src)`)
// into a <figure> so the stylesheet can center and frame it. When an <img>
// carries a non-empty alt, that text becomes the visible <figcaption>. Inline
// media sitting inside a paragraph of prose is left untouched — its line has
// other content, so the anchored ^...$ match never fires.
function figurifyImages(html) {
  return html.replace(
    /^([ \t]*)(?:<p>\s*)?(<img\b[^>]*?>|<video\b[^>]*>(?:[\s\S]*?<\/video>)?)(?:\s*<\/p>)?[ \t]*$/gim,
    (_whole, indent, mediaTag) => {
      // Caption text comes from an <img>'s alt, or a <video>'s data-caption
      // (video has no alt). Reused verbatim: markdown-it has already
      // HTML-escaped attribute values, and raw-HTML bodies are author-trusted.
      const capMatch = mediaTag.match(
        /\b(?:alt|data-caption)\s*=\s*(?:"([^"]*)"|'([^']*)')/i,
      );
      const cap = (capMatch ? (capMatch[1] ?? capMatch[2] ?? '') : '').trim();
      const caption = cap ? `${indent}  <figcaption>${cap}</figcaption>\n` : '';
      return `${indent}<figure class="post-figure">\n${indent}  ${mediaTag}\n${caption}${indent}</figure>`;
    },
  );
}

const [inDir, outDir] = process.argv.slice(2);
if (!inDir || !outDir) {
  console.error('Usage: node render_markdown.mjs <inDir> <outDir>');
  process.exit(1);
}

let count = 0;
for (const file of readdirSync(inDir).filter((f) => f.endsWith('.md'))) {
  const html = figurifyImages(md.render(readFileSync(join(inDir, file), 'utf8')));
  writeFileSync(join(outDir, `${basename(file, '.md')}.html`), html);
  count += 1;
}

console.log(`Rendered ${count} markdown file(s).`);
