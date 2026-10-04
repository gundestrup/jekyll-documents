# TODO: Document autocomplete and search strategy

## Status (2026-09-09)

### Complete

- Ruby document identity and ambiguity handling are implemented in `jekyll-documents`:
  `source_path`, `category_path`, exact `path:` resolution, strict/warn diagnostics,
  category aggregation, permalink placeholders, and collision detection.
- Document content extraction is implemented through the optional `plaintext` gem and
  cached by `jekyll-documents` when `documents.extract_text: true`.
- The existing `jekyll-imgflow-vscode` companion extension implements document indexing
  and completions for `doc_link` and `doc_category`, including nested categories,
  duplicate-title/category disambiguation, root documents, mapped categories, and exact
  `path:` insertion. Its source and integration tests live in that separate repository.
- `jekyll-client-search` indexes `doc.content` for lexical search and optionally supports
  semantic embeddings through a local Ollama server. No LLM is required for extraction or
  normal lexical search.

### Still open

- Whether to retain, deprecate, or remove the built-in metadata-only browser search.
- Whether the VS Code extension should remain ImgFlow-branded or become a general Jekyll
  companion extension.
- Whether to add formal shared Ruby/TypeScript contract fixtures and slug completions.

## Decision direction

The project currently has two web-search paths:

- The built-in Lunr search (`documents_search.html`, `documents-search.js`, and
  `/documents.json`), which runs in the generated website and searches document
  metadata.
- Optional `jekyll-client-search` integration, which can index extracted
  document content and is the preferred full-text search path.

These are separate from authoring-time autocomplete. VS Code autocomplete must
inspect the workspace before a Jekyll build; it should not depend on the
browser's Lunr index or on a generated `/documents.json` file.

The current strategy is:

1. Keep document-reference autocomplete in the existing
   [jekyll-imgflow-vscode](https://github.com/gundestrup/jekyll-imgflow-vscode)
   companion extension. This is implemented and tested in that repository.
2. Keep the built-in metadata-only browser search as a standalone compatibility
   feature for existing sites.
3. Use `jekyll-client-search` as the optional full-text and semantic-search path.
4. Defer deprecating the built-in search until search ownership and migration
   documentation are formally decided.

## Can `jekyll-imgflow-vscode` be extended?

Yes. The companion extension now uses that infrastructure for documents:

- Reads `_config.yml` and the `documents` configuration.
- Indexes source files directly from the workspace.
- Watches configured directories for changes.
- Registers completion providers for Markdown and Liquid.
- Separates indexing from completion-item generation.
- Inserts exact `path:` references for duplicate document titles or categories.
- Includes nested paths, mapped categories, dates, file types, and source paths in details.

The extension does not depend on Jekyll, Ruby, Plaintext, Lunr, a generated JSON
index, or a running site.

## Implemented VS Code contract

Support completions for the tags provided by this gem:

```liquid
{% doc_link "Annual...
{% doc_category "fin...
```

Suggestions should be based on the configured document source tree:

- Document titles derived from `YYYY-MM-DD_Title.ext` filenames.
- Document slugs where useful, using the same observable convention as the
  Ruby plugin.
- Category names derived from document directories.
- Optional details such as file type, date, and relative path.

The completion provider activates in the first argument of `doc_link` and the
category argument of `doc_category`. It replaces the typed prefix and preserves
quote handling. Duplicate titles and category names insert exact `path:` references.

The implementation intentionally suggests titles and category names rather than
reimplementing every Ruby slug rule. Slug completions remain optional and are not
currently required for correct tag resolution.

## Avoiding duplicated logic

The VS Code extension cannot directly call the Ruby implementation for every
keystroke, so a small amount of TypeScript-side interpretation is unavoidable.
The goal should be to avoid duplicating infrastructure and to minimize
 duplicated business rules.

### Shared infrastructure in the existing extension — COMPLETE

Refactor the ImgFlow-specific pieces into reusable components:

- A generic file index that accepts one or more roots, allowed extensions, and
  a display-path mapper.
- Shared recursive file collection and filesystem watcher handling.
- Shared `_config.yml` loading and normalization.
- A generic Liquid completion provider driven by a tag specification:
  - tag name
  - argument position
  - source items
  - inserted text
  - completion-item kind and detail
- Thin ImgFlow and Documents adapters that provide their own configuration
  and tag-specific behavior.

The existing ImgFlow behavior must remain unchanged while this refactor is
introduced.

### Keep Ruby as the source of truth for build behavior — COMPLETE

The VS Code extension should not attempt to duplicate document extraction,
cache handling, permalink generation, or Jekyll rendering. It only needs to
index names and directories for authoring assistance.

For filename-derived titles and slugs, establish shared fixtures or contract
tests that compare representative Ruby and TypeScript results. Important cases
include:

- Date-prefixed filenames.
- Underscores and spaces.
- Danish characters and slug mapping.
- Case folding.
- Invalid or extensionless filenames.
- Nested category directories.

If the autocomplete only inserts the document title into `doc_link`, it can
avoid duplicating most slug-generation logic because the Ruby tag already
resolves titles. Slug suggestions should be added only if there is a clear
user benefit.

### Do not use generated search indexes for completions — COMPLETE

Using `/documents.json` would require a build, would be stale while editing,
and would couple the extension to the built-in Lunr implementation. Direct
source indexing is faster, more reliable, and consistent with
`jekyll-imgflow-vscode`.

## Suggested implementation phases

### Phase 1: confirm the extension boundary — COMPLETE

- Decide whether the Marketplace identity remains ImgFlow or becomes a wider
  Jekyll authoring companion.
- Confirm that the extension should support both Markdown and Liquid.
- Define insertion behavior for quoted and unquoted tag arguments.
- Decide whether suggestions should insert titles, slugs, or both.

### Phase 2: refactor shared VS Code infrastructure — COMPLETE

- Extract generic source-directory configuration handling.
- Extract generic file indexing and watcher support.
- Preserve existing ImgFlow tests and add reusable index/provider tests.

### Phase 3: add document indexing and completions — COMPLETE

- Read `documents.root` and `documents.include_extensions` from `_config.yml`.
- Use `assets/documents` as the default root, matching this gem.
- Add `doc_link` title completion.
- Add `doc_category` completion.
- Show useful completion details without reading document contents.

### Phase 4: compatibility and contract testing — COMPLETE

- Verify title/category results against this gem's filename and directory rules.
- Test file creation, deletion, rename, and configuration changes in the extension.
- Test sites with root, multiple, mapped, and nested document categories.
- Keep formal shared Ruby/TypeScript fixtures as a future improvement where practical.

### Phase 5: search cleanup in this gem — OPEN

The current implementation intentionally supports both search paths:

- Built-in browser search: metadata-only `/documents.json` plus the bundled browser UI.
- `jekyll-client-search`: optional full-text indexing of `doc.content`, with optional
  semantic embeddings through Ollama.

#### Keep both paths (current choice)

Pros:

- Preserves existing sites and public behavior.
- Gives users a zero-extra-dependency metadata search.
- Allows full-text or semantic search only for sites that need it.
- Avoids a breaking removal before migration documentation exists.

Cons:

- Two search configurations and two generated index formats must be documented.
- Users may not know that built-in browser search does not include extracted body text.
- The project carries duplicate browser-search UI and maintenance cost.

#### Deprecate the built-in search later

Pros:

- One supported search implementation and one configuration model.
- Full-text and optional semantic search have a clearer ownership boundary.
- Less bundled JavaScript and fewer generated-index compatibility concerns.

Cons:

- Existing sites using `documents_search.html` and `/documents.json` need migration.
- Removing the built-in index, include, JavaScript, configuration, and browser tests
  requires a major release.
- `jekyll-client-search` becomes a required dependency or an explicit site dependency.

Before changing this phase, document the migration path and decide whether the built-in
search remains a permanent lightweight fallback or is deprecated for a future major release.

## Non-goals

- Do not make the VS Code extension run `bundle exec jekyll build` on every
  completion request.
- Do not make VS Code depend on the Plaintext gem or external PDF tools.
- Do not make browser Lunr search responsible for editor autocomplete.
- Do not duplicate the complete Ruby generator, manifest, or search-index
  implementation in TypeScript.

## Shared contract fixtures — OPEN

This gem is the build-time source of truth for document identity (filename parsing,
`source_path`, `category_path`, `category_map`, root/nested categories, duplicate
disambiguation, exact `path:` resolution). The VS Code companion extension mirrors
that observable behavior in TypeScript for authoring-time autocomplete, and
`jekyll-client-search` consumes the generated `doc.content` and passthrough fields.

To keep the three implementations from drifting without coupling them at runtime,
each project should own a small, versioned contract fixture set for the behavior it
defines, and consuming projects should pin/copy the relevant fixtures for their own
tests rather than live-linking a branch.

### Ownership model

```text
jekyll-documents
  spec/fixtures/contracts/document-autocomplete/v1/
    basic-documents.yml
    nested-categories.yml
    duplicate-titles.yml
    duplicate-categories.yml
    root-documents.yml
    category-mappings.yml
    path-normalization.yml

jekyll-imgflow (separate repo)
  spec/fixtures/contracts/image-tags/v1/
    ...

jekyll-client-search (separate repo)
  spec/fixtures/contracts/search-index/v1/
    extracted-content.yml
    passthrough-fields.yml

jekyll-imgflow-vscode (separate repo)
  test/fixtures/jekyll-site/   # combined ImgFlow + Documents integration site
```

This gem owns the canonical document-identity fixtures because it defines the
build-time behavior. The VS Code extension copies/pins them and tests that its
TypeScript interpretation produces the same observable results. `jekyll-client-search`
owns a separate search-index contract (extracted content, passthrough fields, icon
fields) because it consumes generated documents rather than re-deriving identity.

### Fixture scope

Document-identity fixtures should cover only authoring-visible behavior:

- `YYYY-MM-DD_Title.ext` parsing
- `source_path` normalization (forward slashes, Windows separators)
- `category_path` and `category_slug` derivation
- `category_map` (full-path precedence over leaf)
- Root-level `uncategorized` handling
- Duplicate titles/categories → exact `path:` insertion
- `categories_from_path: false`

They should NOT duplicate PDF extraction, extraction cache internals, Jekyll
rendering, permalink implementation, search engine internals, or semantic
embeddings. Those belong in their respective owners' fixtures.

### Versioning and consumption

- Each fixture set carries a version directory (`v1/`).
- Consuming repositories record the source commit/gem version they pin to.
- Fixtures are copied into the consumer's test tree so tests run offline and
  reproducibly — no network fetch during every CI run.
- A future sync script (`npm run sync:jekyll-documents-contract` in the VS Code
  repo, for example) may automate copying, but is not required initially.
- Fixture/schema changes are treated as compatibility changes and updated
  through explicit pull requests in each consumer.

### Why not a single shared fixture repository now

A neutral `jekyll-contract-fixtures` repository would add a fourth release
process, another versioning system, cross-repository coordination, and more CI
complexity. It becomes worthwhile only when multiple external consumers
actually need the same fixtures. Until then, each project owns its contract
and consumers pin copies.

### Why not live-link fixtures

A live branch dependency or per-run network download would make tests
non-reproducible, dependent on GitHub/network availability, vulnerable to
unexpected fixture changes, and hard to correlate with a released gem version.

## Extension identity — OPEN

The VS Code companion extension is published as `jekyll-imgflow-vscode` but now
supports both ImgFlow image completions and `jekyll-documents` completions
(`doc_link`, `doc_category`). The current name no longer reflects the supported
feature set.

Options under consideration:

1. **Keep the current name** and document the dual role in the README.
   - Pros: no republish/migration churn; existing users keep updating.
   - Cons: name is misleading for new users looking for document support.
2. **Rename the extension** to a general Jekyll authoring companion
   (e.g. `jekyll-companion`, `jekyll-authoring`).
   - Pros: name reflects actual scope; clearer discovery on Open VSX.
   - Cons: requires a new extension ID, migration notes, and a final release
     under the old ID pointing users to the new one. Open VSX does not allow
     redirecting or overwriting published IDs.
3. **Publish a second extension** under the new name and keep `jekyll-imgflow-vscode`
   as an alias/bridge release that points users to the new one.
   - Pros: gradual migration; both names discoverable for a transition period.
   - Cons: two extensions to maintain during the transition; possible user
     confusion about which to install.

The decision is recorded here and in `jekyll-imgflow-vscode/README.todo.md`.
No rename has been performed yet.

## Open questions and current answers

- **Extension identity:** remains `jekyll-imgflow-vscode` for now; renaming or
  aliasing to a general Jekyll companion is an open product decision (see
  "Extension identity" above).
- **Completion values:** titles and category names are the default; exact `path:` values
  are inserted for duplicates. Slug suggestions remain optional.
- **Custom roots:** supported by reading `documents.root` from `_config.yml`; workspace
  boundaries and external absolute roots should remain covered by extension tests.
- **Category depth:** nested category paths are supported and shown in completion details.
- **Built-in search deprecation:** still open; see Phase 5 and its pros/cons above.
- **Shared contract fixtures:** this gem owns the canonical document-identity
  fixtures; consumers pin copies. See "Shared contract fixtures" above.
