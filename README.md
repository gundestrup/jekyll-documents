# jekyll-documents

A Jekyll plugin + theme that automatically turns files under `assets/documents/` into document pages (like posts), with:

- **Auto-collection**: one page per file
- **Date & title** from filename: `YYYY-MM-DD_Title.ext`
- **Category** from folder name under `assets/documents/<category>/`
- **Strict validation** (optional) for filename format and allowed extensions
- **Permalinks** like `/documents/<category>/<slug>/`
- **JSON index** for client-side search (Lunr)
- **Theme assets**: layout, includes, and a small search widget
- **Sitemap**: fully compatible with `jekyll-sitemap` (no custom sitemap required)

## Requirements

- Ruby `>= 2.7` (tested with 3.2)
- Jekyll `>= 4.0`

## Install

In your site:

```ruby
# Gemfile
gem "jekyll", ">= 4.0"
gem "jekyll-sitemap"      # optional but recommended
gem "jekyll-documents", "~> 0.1.0"
```
 _config.yml
 ```yaml
plugins:
  - jekyll-sitemap
  - jekyll-documents

theme: jekyll-documents

# Plugin configuration
documents:
  root: "assets/documents"
  permalink: "/documents/:category/:slug/"
  title_from_filename: true
  slug_downcase: true
  slug_danish_map: true

  # Validation
  strict_filename: true
  strict_extensions: true

  # JSON for Lunr
  json_index: true
  json_index_path: "/documents.json"

  include_extensions:
    - ".pdf"
    - ".docx"
    - ".pptx"
    - ".xlsx"
    - ".odt"
    - ".ods"
    - ".odp"

  latest_default_count: 5
  layout: "document"
```
## File placement & naming
Place your files like this:
``assets/documents/<category>/<YYYY-MM-DD_Title_with_underscores>.pdf
Examples
```txt
assets/documents/referat/2026-03-01_Bestyrelsesmoede_Referat.pdf
assets/documents/invitation/2026-02-15_Generalforsamling_Invitation.pdf
```
Title/slug are derived from the portion after the date.
Category is the folder name (referat, invitation, etc.).

## How it works

The plugin scans documents.root (default assets/documents) for allowed extensions.
For each file, it creates a Jekyll collection item in documents with metadata:
 - title, date, category, file_url, extension, slug, permalink

It outputs a page at /documents/<category>/<slug>/ using the document layout.  
It generates /documents.json if enabled (for client-side search).  

## Search (Lunr)
```yaml
<!-- Include on the page where you want search -->
{% include documents_search.html %}

<!-- Lunr via CDN -->
https://unpkg.com/lunr/lunr.js</script>

<!-- The small widget shipped by this gem -->
<script src="{{ '/assets/js/documents-search.js' | relative
```
## Includes
Latest N documents
```liquid
{% include latest_documents.html count=5 %}
```
All documents
```liquid
{% include documents_list.html %}
```
Categories list
```liquid
{% include category_list.html %}
```
Search UI (input + results container)
```liquid
{% include documents_search.html %}
```
## Sitemap
If you use jekyll-sitemap, all generated document pages are automatically included in sitemap.xml because they are standard output pages.
## Configuration options
```yaml
documents:
  root: "assets/documents"                  # source folder for files
  permalink: "/documents/:category/:slug/"  # page URLs
  title_from_filename: true                 # parse title from filename
  slug_downcase: true                       # lowercase slugs
  slug_danish_map: true                     # æ/ø/å -> ae/oe/aa
  include_extensions: [".pdf", ".docx", ".pptx", ".xlsx", ".odt", ".ods", ".odp"]

  strict_filename: true                     # abort build if format invalid
  strict_extensions: true                   # abort build if ext not allowed

  json_index: true                          # output /documents.json
  json_index_path: "/documents.json"        # where to write JSON

  latest_default_count: 5                   # default for "latest" include/tag
  layout: "document"                        # layout for document pages
```
## Development
- Ruby >= 2.7
- bundle install
- rake build / gem build jekyll-documents.gemspec
## License
AGPL-3.0-only. See LICENSE.

## jekyll-documents structure
Jekyll static document generator
``` ini
jekyll-documents/
├─ .gitignore
├─ CHANGELOG.md
├─ Gemfile
├─ LICENSE
├─ README.md
├─ jekyll-documents.gemspec
├─ _includes/
│  ├─ category_list.html
│  ├─ documents_list.html
│  ├─ documents_search.html
│  └─ latest_documents.html
├─ _layouts/
│  └─ document.html
├─ assets/
│  └─ js/
│     └─ documents-search.js
└─ lib/
   ├─ jekyll-documents.rb
   └─ jekyll/
      └─ documents/
         ├─ configuration.rb
         ├─ filters.rb
         ├─ generator.rb
         ├─ json_index_generator.rb
         ├─ utils.rb
         ├─ version.rb
         └─ tags/
            └─ latest_documents.rb
  ```
