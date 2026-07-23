# Changelog


## [0.3.0] - 2026-07-23

### Added
- **Baked icon data**: Generator now bakes `icon_url` and `icon_set` into each document's data at build time, eliminating the need for Liquid context in filters
- **`FileTypeIcons.icon_for` class method**: Allows icon URL resolution without a Liquid context (used by generator)
- **Search JavaScript wired up**: `_includes/documents_search.html` now loads Lunr.js and `documents-search.js` for out-of-the-box client-side search
- **jekyll-sitemap integration**: `TextStaticFile` exposes `sitemap: false` data to exclude generated JSON index from sitemap
- **Unit tests for `FileTypeIcons.icon_for`**: 5 new tests covering all icon sets, fallbacks, and nil handling
- **Generator tests for icon data**: Tests verifying `icon_url` and `icon_set` are correctly baked into document data
- **System test for full build pipeline**: End-to-end test covering generator → JSON index → tag rendering

### Changed
- **Minimum Ruby version**: Bumped from `>= 2.7` to `>= 3.2` (zeitwerk 2.7+ — a Jekyll dependency — requires Ruby >= 3.2)
- **RuboCop `TargetRubyVersion`**: Updated from `2.7` to `3.2` to match gemspec
- **Templates use baked icon data**: `latest_documents.html`, `documents_list.html`, `document.html` now use `{{ doc.icon_url }}` instead of the broken `file_type_icon_tag` filter
- **`category_list.html` icon set**: Now reads `icon_set` from first document's baked data instead of non-functional `site.documents.icon_set`
- **`latest_documents.html` count fallback**: Simplified to `| default: 5` since `site.config` is inaccessible in Liquid
- **Reek configuration**: Updated `.reek.yml` with targeted exclusions for design-inherent warnings
- **Code quality**: Renamed uncommunicative variables (`s` → `slug`/`result`, `d` → `doc`, `m` → `match`, `y/m/d` → `year/month/day`) across all source files
- **Reduced duplicate method calls**: Extracted `data = doc.data` locals in generator, JSON index generator, and latest documents tag
- **Simplified `get_icon_set`**: Reduced from 6 statements to 3 using safe navigation with `dig`
- **Test suite**: 167 examples (up from 79), 100% line coverage (212/212 lines)
- **RuboCop**: 0 offenses (24 files inspected)
- **Reek**: 0 warnings (7 files inspected)

### Fixed
- **Icon set config ignored in templates** (High): `file_type_icon_tag` filter never received Liquid context, causing `icon_set` config to be silently ignored — always fell back to `"color"`. Fixed by baking icon URLs into document data at generation time
- **`rel_path` slicing** (Low): Replaced fragile `path[(site.source.length + 1)..]` with `String#delete_prefix` for robustness
- **`Date.parse` in `parse_filename`** (Low): Replaced with `Date.new(year, month, day)` using integer-converted regex captures for clarity
- **`category_list.html` folder icon** (Low): `site.documents.icon_set` always resolved to `nil` since `site.documents` is an array — now reads from baked document data
- **Search include missing JavaScript** (Medium): `documents_search.html` had input/results elements but no script tags — now loads Lunr.js and search JS
- **No active jekyll-sitemap integration** (Low): JSON index file now flagged with `sitemap: false` to exclude it from sitemap

## [0.2.0] - 2026-03-12

### Added
- **Comprehensive code quality tools** (RuboCop, Reek, Bundler Audit, SimpleCov)
- **98.99% test coverage** with integration tests for Liquid tags
- **Enhanced release automation** with 10 safety checks and validations
- **Pre-commit hooks** for automatic quality checks
- **Dry-run mode** for release preview
- **Rollback capability** for undoing releases
- **Automated CHANGELOG templates** when bumping versions
- **Release notes generator** with clipboard integration
- **Git status and dependency checks** before release
- **Version consistency validation** across files
- **Post-release verification** with helpful links

### Changed
- **Consolidated documentation** (README.Development.md combines all dev docs)
- **Simplified README.md** with KISS approach
- **Improved Rake tasks** with better organization and help system
- **Enhanced test suite** with 79 passing tests
- **Better error handling** in release scripts

### Fixed
- **Liquid tag testing** through integration tests (resolves 98% coverage)
- **Keyword argument compatibility** in filters
- **Release script safety** with comprehensive validation
- **Documentation consistency** across all markdown files

### Development
- **Quality metrics**: 98.99% coverage • 0 vulnerabilities • 3 RuboCop offenses
- **Release workflow**: Fully automated with rollback capability
- **Testing**: 79 examples, 0 failures, integration tests for all features

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
