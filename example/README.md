# Example Site

Demo Jekyll site with `jekyll-documents` plugin.

## Setup

```bash
cd example
bundle install
```

## Add Documents

```bash
mkdir -p assets/documents/reports
touch assets/documents/reports/2026-03-01_Annual_Report.pdf
```

Format: `YYYY-MM-DD_Title.ext`

## Run

```bash
bundle exec jekyll serve
```

Visit http://localhost:4000

## Features

- Auto-generated document pages
- Categories from folders
- File type icons
- Search with Lunr.js
- JSON index at `/documents.json`
