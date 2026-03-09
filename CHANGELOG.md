# Changelog

## [0.1.0] - 2026-03-09
- Initial release.
- Scans `assets/documents/**` and generates a `documents` collection.
- Filename parsing: `YYYY-MM-DD_Title.ext`.
- Category inferred from folder name.
- Strict validation for filename format and extensions (configurable).
- JSON index generation for Lunr (`/documents.json`).
- Theme assets (layout, includes, JS) provided.
- Works with `jekyll-sitemap` out-of-the-box.
