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

const [inDir, outDir] = process.argv.slice(2);
if (!inDir || !outDir) {
  console.error('Usage: node render_markdown.mjs <inDir> <outDir>');
  process.exit(1);
}

let count = 0;
for (const file of readdirSync(inDir).filter((f) => f.endsWith('.md'))) {
  const html = md.render(readFileSync(join(inDir, file), 'utf8'));
  writeFileSync(join(outDir, `${basename(file, '.md')}.html`), html);
  count += 1;
}

console.log(`Rendered ${count} markdown file(s).`);
