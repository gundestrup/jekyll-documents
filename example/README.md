# Example Jekyll Site

This directory contains a working example of a Jekyll site using the `jekyll-documents` plugin.

## Setup

```bash
cd example
bundle install
```

## Add Sample Documents

Create some sample documents in the `assets/documents/` directory:

```bash
mkdir -p assets/documents/board
mkdir -p assets/documents/minutes
mkdir -p assets/documents/reports

# Create sample files (you can use any PDF, DOCX, etc.)
# Format: YYYY-MM-DD_Title_With_Underscores.ext
touch assets/documents/board/2026-03-01_Board_Meeting_Minutes.pdf
touch assets/documents/minutes/2026-02-15_Annual_General_Meeting.pdf
touch assets/documents/reports/2026-01-10_Financial_Report_Q4.xlsx
```

## Run the Site

```bash
bundle exec jekyll serve
```

Then visit http://localhost:4000

## What You'll See

- **Home page** with latest documents, full document list, categories, and search
- **Individual document pages** at `/documents/<category>/<slug>/`
- **JSON index** at `/documents.json` for search functionality
- **File type icons** for each document
- **Sitemap** at `/sitemap.xml`

## Features Demonstrated

1. Automatic document page generation
2. Category-based organization
3. Date parsing from filenames
4. Slug generation
5. File type icons
6. Search functionality with Lunr.js
7. Sitemap integration
