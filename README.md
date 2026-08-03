# jekyll-documents
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/gundestrup/jekyll-documents)

Turn files in `assets/documents/` into browsable document pages.

**Requirements**: Ruby 3.3+ • Jekyll 4.4+

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

```liquid
{% include latest_documents.html count=5 %}
{% include documents_list.html %}
{% include documents_search.html %}
```

## Configuration

```yaml
documents:
  root: "assets/documents"
  icon_set: "color"
  strict_filename: true
```

See [configuration.rb](lib/jekyll/documents/configuration.rb) for all options.

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
./bump_version.sh patch
./release.sh
```

## License

AGPL-3.0-only • Icons by [SVG Repo](https://www.svgrepo.com)
