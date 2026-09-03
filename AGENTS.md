# AGENTS.md — jekyll-documents

> **Single source of truth for all coding agents working on this project.**
> Tool-specific files (`CLAUDE.md`, `.windsurfrules`) reference this document.

## Project Summary

Jekyll plugin that turns files in `assets/documents/` into browsable document pages with icons, categories, and search.

- **Language:** Ruby (>= 3.4)
- **Framework:** Jekyll 4.x plugin (generator + Liquid tags/filters)
- **Gem:** `jekyll-documents` (version is defined in `lib/jekyll/documents/version.rb`)
- **License:** AGPL-3.0-only
- **Author:** Svend Gundestrup (<svend@gundestrup.dk>)
- **Repo:** <https://github.com/gundestrup/jekyll-documents>

## Architecture

```text
lib/jekyll-documents.rb                    # Entry point — requires all modules
lib/jekyll/documents/
  version.rb                               # VERSION constant
  configuration.rb                         # DEFAULTS + Configuration.read(site)
  generator.rb                             # Main generator: scans files, creates collection docs
  text_extraction_manifest.rb              # Persistent manifest for text extraction cache (SHA-256 digests, survives jekyll clean)
  assets_generator.rb                      # Publishes gem assets as Jekyll static files
  json_index_generator.rb                  # Generates /documents.json for Lunr search
  layout_registrar.rb                      # Copies gem _layouts/_includes into site source via :site, :after_init hook
  file_type_icons.rb                       # Icon mappings + Liquid filters
  filters.rb                               # documents_slugify + documents_title_from_filename
  utils.rb                                 # TextStaticFile (writes JSON index, sitemap: false)
  tags/latest_documents.rb                 # {% latest_documents %} Liquid tag
  tags/document_icon.rb                    # {% document_icon page %} Liquid tag
  tags/doc_link.rb                         # {% doc_link "title" %} Liquid tag
  tags/doc_category.rb                     # {% doc_category "name" %} Liquid tag
spec/browser/                                # Playwright browser tests for the built gem
```

### Data flow

1. `Generator#generate` scans `assets/documents/**/*` for files
2. Parses filenames (`YYYY-MM-DD_Title.ext`) → extracts date, title, slug, category
3. Bakes `icon_url` and `icon_set` into each document's `data` hash
4. If `extract_text: true`, extracts text from each file via the optional `plaintext` gem, using `TextExtractionManifest` for persistent SHA-256-keyed caching (survives `jekyll clean`, cleans up deleted files)
5. Creates `Jekyll::Document` objects in the `documents` collection
6. `AssetsGenerator` registers packaged icons and JavaScript as static files
7. `JsonIndexGenerator` builds `/documents.json` from the collection
8. `LayoutRegistrar` copies gem `_layouts` and `_includes` into the site source via a `:site, :after_init` hook (user files take precedence); also excludes the text cache dir from Jekyll output
9. Templates render icons with `{% document_icon doc %}` or `{% document_icon page %}` and use baked document data for other fields
10. `{% doc_link "title" %}` resolves a document by partial title or slug match and renders an `<a>` tag with the correct URL
11. `{% doc_category "name" %}` renders a link to a category page, or with `list:true` renders a sorted list of all documents in that category (supports `limit:N` and `text:"label"`)

### Template files

```text
_includes/latest_documents.html            # Recent docs list (uses document_icon tag)
_includes/documents_list.html              # Full doc list (uses document_icon tag)
_includes/category_list.html               # Category folders (reads icon_set from first doc)
_includes/documents_search.html            # Search input + Lunr.js + documents-search.js
_layouts/document.html                     # Single document page (uses document_icon tag)
assets/js/documents-search.js              # Client-side Lunr search
assets/css/documents.css                   # Framework-agnostic icon sizing (icon-x1 through icon-x9)
assets/icons/{color,lines,minimal,ultra-minimal}/  # SVG icon sets
```

## Critical Gotchas

### 1. Liquid context does not pass to filters

`file_type_icon_tag` filter accepts a `context:` kwarg, but Liquid filters **never** receive context automatically. Templates should use `{% document_icon doc %}` or `{% document_icon page %}`, which applies the baked icon URL and site `baseurl` with full Liquid context. The `file_type_icon_tag` filter remains available for lower-level or Ruby-side use.

### 2. `SiteDrop#config` always returns nil in Liquid

`Jekyll::Drops::SiteDrop#config` is hardcoded to return `nil`. Any `{{ site.config.documents.* }}` expression in Liquid silently fails. This is why config is baked into document data at generation time, and why `{% latest_documents %}` tag (which reads config via Ruby `Configuration.read(site)`) is preferred over `_includes/latest_documents.html`.

### 3. `public_class_method :new` is REQUIRED

`LatestDocumentsTag < Liquid::Tag` — `Liquid::Tag` makes `new` private. The `public_class_method :new` line in `tags/latest_documents.rb` re-exposes it. **Do not remove this line** — it causes 29 test failures.

### 4. Icon data is baked at generation time

The generator calls `FileTypeIcons.icon_for(file_type, icon_set)` and stores the result in `doc.data["icon_url"]`. Templates should render icons with `{% document_icon doc %}` or `{% document_icon page %}` rather than manually constructing `<img>` tags. The tag handles the baked URL, `baseurl`, escaping, and defaults. Icons use the `document-file-icon` CSS class (not `file-icon`, which collides with Bulma's flex-based class) with inline `1em` sizing. A framework-agnostic CSS file (`assets/css/documents.css`) provides `icon-x1` through `icon-x9` utility classes (16px–512px) for fixed sizes.

### 5. `category_list.html` reads icon_set from first document

Since `site.documents` is an array (not config), `site.documents.icon_set` is nil. The include derives `icon_set` from `site.documents.first.icon_set` (baked by generator).

### 6. Layouts and includes are auto-copied, not themed

Jekyll only auto-discovers `_layouts` and `_includes` from **theme gems** (via the `theme:` config key). This gem is a plugin, not a theme, so `LayoutRegistrar` copies the gem's `_layouts/` and `_includes/` into the site source directory via a `:site, :after_init` hook. Files already present in the user's site are never overwritten. **Do not remove the hook** — without it, Jekyll cannot find the `document` layout and the includes.

## Quality Gates

All must pass before commit/release:

```bash
rake quality          # Runs all 3 checks below
bundle exec rubocop   # 0 offenses required (40 files)
rake spec             # Rebuilds/installs gem, 280 Ruby examples, 0 failures, 99.52% coverage
rake browser_test     # Rebuilds/installs gem and runs Playwright browser tests
bundle exec bundler-audit check --update  # 0 vulnerabilities
```

Quick check during development:

```bash
rake quick            # RuboCop + RSpec only
```

## Code Conventions

- **Frozen string literals**: All files have `# frozen_string_literal: true`
- **Naming**: Descriptive variable names (not `s`, `d`, `m`)
- **Line length**: 100 chars max (RuboCop Layout/LineLength)
- **Tests**: RSpec with SimpleCov. Target 100% line coverage.
- **No comments** unless explaining non-obvious logic (frozen literals, rubocop disables)

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
  extract_text: false                 # Enable text extraction (requires 'plaintext' gem)
  text_max_bytes: 500000              # Truncate extracted text
  text_cache_dir: ".cache/jekyll-documents"  # Persistent cache dir (survives jekyll clean)
  category_map: {}                    # Optional: { "minutes" => "referater" }
```

## Release Process

```bash
bundle exec rake "version:bump[minor]"  # Bump version in version.rb
# Edit CHANGELOG.md with actual changes (## [X.Y.Z] - YYYY-MM-DD)
bundle exec rake version:check_changelog # Verify CHANGELOG entry exists
git add lib/jekyll/documents/version.rb CHANGELOG.md
git commit -m "Release X.Y.Z: summary"
git tag -a vX.Y.Z -m "Release X.Y.Z"
git push origin main
git push origin vX.Y.Z                  # Triggers release workflow
```

Pushing the tag triggers the release workflow which builds the gem,
attaches it to a GitHub release, and publishes to RubyGems via trusted
publishing. No manual `gh release create` needed.

## File Naming

Documents must follow `YYYY-MM-DD_Title.ext` format. Supported extensions: `.pdf .docx .pptx .xlsx .odt .ods .odp`. Category is derived from the parent folder name.

## Related Documents

- [README.md](./README.md) — User-facing quick start and feature overview
- [README.Development.md](./README.Development.md) — Development workflow, commands, CI/CD
- [readme.errors.md](./readme.errors.md) — Known bugs and issues with fix status markers
- [CHANGELOG.md](./CHANGELOG.md) — Version history and release notes
- [.rubocop.yml](./.rubocop.yml) — Code style rules (TargetRubyVersion 3.4)
- [jekyll-documents.gemspec](./jekyll-documents.gemspec) — Gem spec and metadata
- [.devin/wiki.json](./.devin/wiki.json) — DeepWiki steering file

## Do NOT

- Do not remove `public_class_method :new` from `LatestDocumentsTag` (causes 29 test failures)
- Do not remove the `:site, :after_init` hook in `LayoutRegistrar` (breaks layout/include discovery)
- Do not add or remove comments unless explicitly requested
- Do not bypass RuboCop rules — fix the code, not the config
- Do not use `puts`/`print` in production code — use `Jekyll.logger`
- Do not rescue `Exception` — rescue `StandardError` or specific error classes
