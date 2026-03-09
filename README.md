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
``

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
