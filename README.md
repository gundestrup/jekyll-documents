# jekyll-documents
[![Status: Active](https://img.shields.io/badge/status-active-success)](https://github.com/gundestrup/jekyll-documents)
[![Tests](https://github.com/gundestrup/jekyll-documents/actions/workflows/test.yml/badge.svg)](https://github.com/gundestrup/jekyll-documents/actions/workflows/test.yml)
[![Codecov](https://codecov.io/gh/gundestrup/jekyll-documents/graph/badge.svg)](https://codecov.io/gh/gundestrup/jekyll-documents)
[![Gem Version](https://img.shields.io/gem/v/jekyll-documents)](https://rubygems.org/gems/jekyll-documents)
[![Gem Downloads](https://img.shields.io/gem/dt/jekyll-documents)](https://rubygems.org/gems/jekyll-documents)
[![License: AGPL-3.0-only](https://img.shields.io/badge/license-AGPL--3.0--only-blue)](LICENSE)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/gundestrup/jekyll-documents)

Turn files in `assets/documents/` into browsable document pages.

**Requirements**: Ruby 3.4+ • Jekyll 4.4+

**Features**: Auto-collection • File icons • Categories • Search

[![DeepWiki](https://img.shields.io/badge/DeepWiki-docs-blue)](https://deepwiki.com/gundestrup/jekyll-documents)

## Quick Start

```ruby
# Gemfile
gem "jekyll-documents"
```

```yaml
# _config.yml
plugins:
  - jekyll-documents

documents:
  icon_set: "color"  # color, lines, minimal, ultra-minimal
```

```
# Add files
assets/documents/reports/2026-03-01_Annual_Report.pdf
assets/documents/minutes/2026-02-15_Board_Meeting.docx
```

```liquid
<!-- Use in templates -->
{% include latest_documents.html %}
{% include documents_list.html %}
{% include category_list.html %}
```

## File Naming

**Format**: `YYYY-MM-DD_Title.ext`

```
assets/documents/reports/2026-03-01_Annual_Report.pdf
```

Date → `YYYY-MM-DD` • Title → underscores to spaces • Category → folder name

## Icons

4 icon sets: `color` (default), `lines`, `minimal`, `ultra-minimal`

```yaml
documents:
  icon_set: "color"
```

Render a document icon in templates with the context-aware tag:

```liquid
{% document_icon page %}
```

The tag applies the configured icon set and site `baseurl` automatically. The `file_type_icon` and
`file_type_icon_tag` filters remain available for lower-level or Ruby-side use.

## Usage

### Includes

```liquid
{% include latest_documents.html count=5 %}
{% include documents_list.html %}
{% include documents_search.html %}
```

### Liquid Tags

**Link to a document** by title or slug (partial match, case-insensitive):

```liquid
{% doc_link "Annual Report" %}
{% doc_link "annual" text:"Read the report" %}
{% doc_link "board-meeting" icon:false size:false %}
```

Renders an `<a>` tag with the file type icon, title, and human-readable file size.
Use `text:"..."` to override the link text, `icon:false` to hide the icon,
or `size:false` to hide the file size.

**Link to or list a category**:

```liquid
{% doc_category "reports" %}
{% doc_category "reports" text:"All reports" %}
{% doc_category "reports" list:true %}
{% doc_category "reports" list:true limit:5 %}
```

Link mode renders an `<a>` tag to the category page.
List mode renders a `<ul>` of all documents in the category, sorted by date descending.
Use `limit:N` to cap the number of items.

## Configuration

```yaml
documents:
  root: "assets/documents"
  icon_set: "color"
  strict_filename: true
```

See [configuration.rb](lib/jekyll/documents/configuration.rb) for all options.

## Icon sizing

Icons default to `1em` (line-height) so they scale with surrounding text.
A framework-agnostic CSS file with fixed-size utility classes is included:

```html
<link rel="stylesheet" href="{{ '/assets/css/documents.css' | relative_url }}">
```

| Class | Size |
| --- | --- |
| (default) | `1em` — scales with line height |
| `icon-x1` | 16px |
| `icon-x2` | 32px |
| `icon-x3` | 48px |
| `icon-x4` | 64px |
| `icon-x5` | 96px |
| `icon-x6` | 128px |
| `icon-x7` | 150px |
| `icon-x8` | 256px |
| `icon-x9` | 512px |

Usage with the `document_icon` tag:

```liquid
{% document_icon page class:"document-file-icon icon-x2" %}
```

Or with any `<img>`:

```html
<img src="..." class="document-file-icon icon-x3" />
```

The CSS uses `display: inline-block` and `vertical-align: middle` — no
dependency on Bulma, Bootstrap, Tailwind, or any other framework.

## Search Integration

Documents are compatible with [jekyll-client-search](https://github.com/gundestrup/jekyll-client-search)
for client-side search. Each document has `categories` (plural array) and
searchable `content` baked in at generation time, so search plugins can
index uploaded files alongside posts.

To include documents in the search index, add `documents` to the
`collections` list in `_config.yml`:

```yaml
client_search:
  collections:
    - posts
    - documents
```

### Icons and file-type metadata in search results

jekyll-documents bakes `file_type`, `icon_url`, and `icon_set` into each
document's data at generation time. When jekyll-client-search is installed
and `documents` is in the search collections, these fields are
**auto-injected** into the search index — no extra configuration needed:

```yaml
client_search:
  collections:
    - posts
    - documents
```

This makes jekyll-client-search render:

- `data-file-type`, `data-icon-set` attributes on each result `<article>`
  (for CSS-based badges and theme-aware styling)
- An `<img class="client-search-result-icon">` before the title, using the
  icon from the configured `icon_set` (color, lines, minimal, or ultra-minimal)

The icon automatically matches the `icon_set` configured in your `documents`
section — no extra configuration needed for theme consistency.

**Field renaming** (for integration with other search conventions):

```yaml
client_search:
  passthrough_fields:
    - file_type: doctype      # rename in the search index
    - icon_url: thumbnail
  icon_field: thumbnail
```

**CSS examples:**

```css
/* File-type badge */
.client-search-result[data-file-type="pdf"]::before {
  content: "PDF";
  background: #e74c3c; color: white;
  padding: 0 0.3em; font-size: 0.7em; margin-right: 0.3em;
}

/* Theme-aware icon sizing */
.client-search-result[data-icon-set="color"] .client-search-result-icon { width: 2em; }
.client-search-result[data-icon-set="ultra-minimal"] .client-search-result-icon { width: 1em; }
```

See the [jekyll-client-search README](https://github.com/gundestrup/jekyll-client-search#customizing-search-results-with-css)
for all CSS customization options.

## Text Extraction

Extract text from PDF/DOCX/XLSX/PPTX/ODT/ODS/ODP files so search engines
can index document contents, not just metadata.

### Setup

Add the optional [`plaintext`](https://github.com/planio-gmbh/plaintext) gem
to your Gemfile:

```ruby
# Gemfile
gem "plaintext", group: :jekyll_plugins
```

Enable extraction in `_config.yml`:

```yaml
documents:
  extract_text: true
```

### How it works

- Extracted text is stored in `doc.content`, which `jekyll-client-search`
  indexes automatically — no extra configuration needed
- Text is cached in `.cache/jekyll-documents/` (in your site source,
  not `.jekyll-cache/`), so it **survives `jekyll clean`**
- Cache invalidation uses **SHA-256 file digests** — only changed files
  are re-extracted
- Stale cache entries for deleted files are cleaned up automatically
  at the start of each build
- Falls back to metadata-only content (title, category, file type, date)
  if the `plaintext` gem is missing or extraction fails

### Configuration

```yaml
documents:
  extract_text: true                    # Enable text extraction
  text_max_bytes: 500000                # Truncate extracted text (default 500KB)
  text_cache_dir: ".cache/jekyll-documents"  # Cache directory in site source
```

Add the cache directory to `.gitignore`:

```
.cache/jekyll-documents/
```

### CLI tool dependencies

The `plaintext` gem uses the `rubyzip` Ruby gem for Office formats (no CLI
tools needed). PDF extraction shells out to a system command:

| Format | Tool |
|--------|------|
| PDF | `pdftotext` (poppler-utils) |
| DOCX/PPTX/XLSX | rubyzip (Ruby gem, no CLI needed) |
| ODT/ODS/ODP | rubyzip (Ruby gem, no CLI needed) |

## Development

```bash
rake              # Ruby quality checks
rake test         # Rebuild/install gem + Ruby and browser tests
rake browser_test # Browser search tests (Node.js + Chromium required)
rake quick        # Fast Ruby check
rake help         # Show commands
```

**Quality**: 100% coverage • 0 vulnerabilities • 0 offenses • 0 warnings

See [README.Development.md](README.Development.md) for details.

**DeepWiki**: [https://deepwiki.com/gundestrup/jekyll-documents](https://deepwiki.com/gundestrup/jekyll-documents)

## Release

```bash
bundle exec rake "version:bump[patch]"
# Edit CHANGELOG.md
git add lib/jekyll/documents/version.rb CHANGELOG.md
git commit -m "Release X.Y.Z: summary"
git tag -a vX.Y.Z -m "Release X.Y.Z"
git push origin main
git push origin vX.Y.Z
```

## License

AGPL-3.0-only • Icons by [SVG Repo](https://www.svgrepo.com)
