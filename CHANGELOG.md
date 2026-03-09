# Changelog

## [0.1.2] - 2026-03-09

### Added
- **Release automation scripts**

## [0.1.1] - 2026-03-09

### Added
- **4 icon sets**: color, lines, minimal, ultra-minimal (configurable)
- File type icons for 20+ formats (PDF, DOCX, XLSX, etc.)
- Folder icons for category lists
- Icons in all views: document pages, lists, search results, categories
- `file_type_icon` and `file_type_icon_tag` Liquid filters
- RSpec test suite (100+ tests, all passing)
- YARD documentation
- Example Jekyll site
- CI/CD workflow (GitHub Actions)
- `icon_set` configuration option

### Fixed
- Icon URLs (now using actual svgrepo.com icons)
- XSS vulnerabilities (HTML escaping)
- Date format standardized to ISO (YYYY-MM-DD)
- Slug generation edge cases
- JavaScript search null safety

### Changed
- Icons now included in gem (no external dependencies)
- JSON index includes file_type and extension
- Search results display icons dynamically
- Improved documentation and examples

### Attribution
- Icons from [SVG Repo](https://www.svgrepo.com)

## [0.1.0] - 2026-03-09

### Initial Release
- Auto-collection from `assets/documents/`
- Filename parsing: `YYYY-MM-DD_Title.ext`
- Category from folder structure
- Strict validation (configurable)
- JSON index for Lunr search
- Theme assets (layouts, includes, JS)
- Sitemap compatible
