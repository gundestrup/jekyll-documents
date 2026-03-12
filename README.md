# jekyll-documents

Turn files in `assets/documents/` into browsable document pages.

**Features**: Auto-collection • File icons • Categories • Search

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

```liquid
{{ page.file_type | file_type_icon_tag }}
```

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
rake              # All quality checks
rake quick        # Fast check
rake help         # Show commands
```

**Quality**: 98.99% coverage • 0 vulnerabilities • RuboCop • Reek

See [README.Development.md](README.Development.md) for details.

## Release

```bash
./bump_version.sh patch
./release.sh
```

## License

AGPL-3.0-only • Icons by [SVG Repo](https://www.svgrepo.com)
