# jekyll-documents

Turn files in `assets/documents/` into browsable document pages with icons, categories, and search.

**Features:**
- Auto-collection from files
- File type icons (4 styles)
- Categories from folders
- Client-side search
- Strict validation

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

## Requirements

Ruby >= 2.7, Jekyll >= 4.0
## File Naming

**Format:** `YYYY-MM-DD_Title_With_Underscores.ext`

```
assets/documents/reports/2026-03-01_Annual_Report.pdf
assets/documents/minutes/2026-02-15_Board_Meeting.docx
```

- Date: `YYYY-MM-DD`
- Title: Underscores → spaces
- Category: From folder name

  

## File Type Icons

The plugin automatically displays file type icons for all supported formats. Icons are included in the gem and based on designs from [svgrepo.com](https://www.svgrepo.com/).

**Icon Sets:** color (default), lines, minimal, ultra-minimal

**Supported:** PDF, DOCX, XLSX, PPTX, ODT, ODS, ODP, TXT, ZIP, MP3, MP4, JPG, PNG, HTML, XML, CSV, RTF

**Configuration:**
```yaml
documents:
  icon_set: "color"  # color, lines, minimal, ultra-minimal
```

**Icons appear in:** document pages, lists, search results, category folders

**Liquid filters:**
```liquid
{{ page.file_type | file_type_icon_tag }}
{{ page.file_type | file_type_icon }}
```

*Icons from [svgrepo.com](https://www.svgrepo.com/)*

## Includes

```liquid
{% include latest_documents.html count=5 %}
{% include documents_list.html %}
{% include category_list.html %}
{% include documents_search.html %}
```

## Search

```html
<script src="https://unpkg.com/lunr/lunr.js"></script>
<script src="{{ '/assets/js/documents-search.js' | relative_url }}"></script>
```
## Configuration

```yaml
documents:
  root: "assets/documents"
  permalink: "/documents/:category/:slug/"
  icon_set: "color"  # color, lines, minimal, ultra-minimal
  include_extensions: [".pdf", ".docx", ".pptx", ".xlsx"]
  strict_filename: true
  json_index: true
```

See [configuration.rb](lib/jekyll/documents/configuration.rb) for all options.
## Development

```bash
bundle install
bundle exec rspec       # Run tests
bundle exec rake doc    # Generate docs
cd example && bundle exec jekyll serve  # Example site
```

## License

AGPL-3.0-only

## Attribution

Icons by [SVG Repo](https://www.svgrepo.com)
