# Changelog

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
