# AI Instructions for jekyll-documents

> Context file for LLM coding assistants working on this project.

## Project Overview

Jekyll plugin that turns files in `assets/documents/` into browsable document pages with icons, categories, and search.

- **Language**: Ruby (>= 3.1)
- **Framework**: Jekyll 4.x plugin (generator + Liquid tags/filters)
- **Gem name**: `jekyll-documents`
- **Current version**: 0.3.0

## Architecture

```text
lib/jekyll-documents.rb                    # Entry point — requires all modules
lib/jekyll/documents/
  version.rb                               # VERSION constant
  configuration.rb                         # DEFAULTS + Configuration.read(site)
  generator.rb                             # Main generator: scans files, creates collection docs
  json_index_generator.rb                  # Generates /documents.json for Lunr search
  file_type_icons.rb                       # Icon mappings + Liquid filters
  filters.rb                               # documents_slugify + documents_title_from_filename
  utils.rb                                 # TextStaticFile (writes JSON index, sitemap: false)
  tags/latest_documents.rb                 # {% latest_documents %} Liquid tag
```

### Data flow

1. `Generator#generate` scans `assets/documents/**/*` for files
2. Parses filenames (`YYYY-MM-DD_Title.ext`) → extracts date, title, slug, category
3. Bakes `icon_url` and `icon_set` into each document's `data` hash
4. Creates `Jekyll::Document` objects in the `documents` collection
5. `JsonIndexGenerator` builds `/documents.json` from the collection
6. Templates render using baked data (`{{ doc.icon_url }}`, `{{ doc.category }}`, etc.)

### Template files

```text
_includes/latest_documents.html            # Recent docs list (uses baked icon_url)
_includes/documents_list.html              # Full doc list (uses baked icon_url)
_includes/category_list.html               # Category folders (reads icon_set from first doc)
_includes/documents_search.html            # Search input + Lunr.js + documents-search.js
_layouts/document.html                     # Single document page (uses page.icon_url)
assets/js/documents-search.js              # Client-side Lunr search
assets/icons/{color,lines,minimal,ultra-minimal}/  # SVG icon sets
```

## Critical Gotchas

### 1. Liquid context does not pass to filters

`file_type_icon_tag` filter accepts a `context:` kwarg, but Liquid filters **never** receive context automatically. Templates must use baked `{{ doc.icon_url }}` instead. The `file_type_icon_tag` filter still works when called from Ruby code (tags, generators) but not from Liquid templates.

### 2. `SiteDrop#config` always returns nil in Liquid

`Jekyll::Drops::SiteDrop#config` is hardcoded to return `nil`. Any `{{ site.config.documents.* }}` expression in Liquid silently fails. This is why config is baked into document data at generation time, and why `{% latest_documents %}` tag (which reads config via Ruby `Configuration.read(site)`) is preferred over `_includes/latest_documents.html`.

### 3. `public_class_method :new` is REQUIRED

`LatestDocumentsTag < Liquid::Tag` — `Liquid::Tag` makes `new` private. The `public_class_method :new` line in `tags/latest_documents.rb` re-exposes it. **Do not remove this line** — it causes 29 test failures.

### 4. Icon data is baked at generation time

The generator calls `FileTypeIcons.icon_for(file_type, icon_set)` and stores the result in `doc.data["icon_url"]`. Templates read `{{ doc.icon_url }}` — they do NOT call `file_type_icon_tag` filter. If you add new templates, use the baked data pattern.

### 5. `category_list.html` reads icon_set from first document

Since `site.documents` is an array (not config), `site.documents.icon_set` is nil. The include derives `icon_set` from `site.documents.first.icon_set` (baked by generator).

## Quality Gates

All must pass before commit/release:

```bash
rake quality          # Runs all 4 checks below
bundle exec rubocop   # 0 offenses required (24 files)
bundle exec reek --config .reek.yml lib/  # 0 warnings required (7 files)
bundle exec rspec     # 167 examples, 0 failures, 100% coverage
bundle exec bundler-audit check --update  # 0 vulnerabilities
```

Quick check during development:

```bash
rake quick            # RuboCop + RSpec only
```

## Code Conventions

- **Frozen string literals**: All files have `# frozen_string_literal: true`
- **Naming**: Descriptive variable names (not `s`, `d`, `m` — see reek config for exceptions)
- **Line length**: 100 chars max (RuboCop Layout/LineLength)
- **Tests**: RSpec with SimpleCov. Target 100% line coverage.
- **No comments** unless explaining non-obvious logic (frozen literals, rubocop disables)
- **Reek exclusions**: `.reek.yml` has targeted exclusions for design-inherent warnings (Jekyll generator complexity, boolean params in filters, inherited StaticFile instance variables). These are intentional — do not remove without understanding why.

## Configuration

User config in `_config.yml`:

```yaml
documents:
  root: "assets/documents"           # Source directory
  icon_set: "color"                   # color | lines | minimal | ultra-minimal
  permalink: "/documents/:category/:slug/"
  slug_downcase: true
  slug_danish_map: true
  categories_from_path: true
  strict_filename: true               # Abort on non-YYYY-MM-DD filenames
  strict_extensions: true             # Abort on unsupported file types
  json_index: true                    # Generate /documents.json
  json_index_path: "/documents.json"
  latest_default_count: 5
  category_map: {}                    # Optional: { "minutes" => "referater" }
```

## Release Process

```bash
./bump_version.sh minor               # Bump version + CHANGELOG template
# Edit CHANGELOG.md with actual changes
./release.sh --dry-run                # Verify everything passes
./release.sh                          # Interactive: quality checks, commit, tag, push
```

GitHub Actions auto-publishes to RubyGems on tag push.

## File Naming

Documents must follow `YYYY-MM-DD_Title.ext` format. Supported extensions: `.pdf .docx .pptx .xlsx .odt .ods .odp`. Category is derived from the parent folder name.

## Related Documents

- [README.md](./README.md) — User-facing quick start and feature overview
- [README.Development.md](./README.Development.md) — Development workflow, commands, scripts, CI/CD
- [readme.errors.md](./readme.errors.md) — Known bugs and issues with fix status markers
- [CHANGELOG.md](./CHANGELOG.md) — Version history and release notes
- [.rubocop.yml](./.rubocop.yml) — Code style rules (TargetRubyVersion 3.1)
- [.reek.yml](./.reek.yml) — Code smell detection with intentional exclusions
- [jekyll-documents.gemspec](./jekyll-documents.gemspec) — Gem spec and metadata
