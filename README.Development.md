# Development Guide

**DeepWiki**: [https://deepwiki.com/gundestrup/jekyll-documents](https://deepwiki.com/gundestrup/jekyll-documents)

## Quick Start

```bash
rake              # Run all quality checks
rake quick        # Quick check (style + tests)
rake help         # Show all commands
```

## Quality Tools

- **Ruby coverage**: 100% (275/275 lines)
- **Security**: 0 vulnerabilities
- **Style**: 0 offenses

## Commands

```bash
# Testing
rake              # All checks (default)
rake quality      # All checks
rake test         # Rebuild/install gem + Ruby + browser tests
rake spec         # Rebuild/install gem + tests + coverage
rake quick        # Rebuild/install gem + fast check
rake browser_test  # Rebuild/install gem + browser E2E tests

# Individual checks
rake rubocop      # Code style
rake rubocop_fix  # Auto-fix
rake bundler_audit # Security

# Version management
rake version:show              # Print current version
rake "version:bump[patch]"     # Bump patch version
rake version:check_changelog   # Verify CHANGELOG entry exists

# Development
rake doc          # Generate docs
rake install_local # Install locally
```

## Development Workflow

### 1. Setup
```bash
bin/install-hooks.sh  # Install pre-commit and pre-push hooks
```

### 2. Make Changes
Edit code in `lib/` directory

### 3. Test Changes
```bash
rake quick        # Fast check during development
rake              # Full check before commit
```

Pre-commit hook runs RuboCop only (fast, ~2s). Pre-push hook runs
`rake quick` (RuboCop + RSpec) as a full quality gate before pushing.

### 4. Test in Real App
```ruby
# Gemfile in test app
gem "jekyll-documents", path: "/path/to/this/repo"
```

### 5. Release
```bash
bundle exec rake "version:bump[patch]"  # Update version.rb
# Edit CHANGELOG.md: add '## [X.Y.Z] - YYYY-MM-DD' section
bundle exec rake version:check_changelog # Verify CHANGELOG entry
git add lib/jekyll/documents/version.rb CHANGELOG.md
git commit -m "Release X.Y.Z: summary"
git tag -a vX.Y.Z -m "Release X.Y.Z"
git push origin main
git push origin vX.Y.Z                  # Triggers release workflow
```

Pushing the tag triggers the release workflow which builds the gem,
attaches it to a GitHub release, and publishes to RubyGems via trusted
publishing. No manual `gh release create` needed.

## Testing

### Run Tests
```bash
rake spec                         # Rebuild/install gem, then run all tests
bundle exec rspec spec/filters    # Run one source-level spec file
rake install_local                # Rebuild and force-install the gem
```

System tests verify the packaged gem contents and run a Jekyll build using the installed gem.
The full `rake quality` task rebuilds and force-installs the gem before running the Ruby test suite. Run `rake browser_test` for real browser coverage of the search UI; it requires Node.js and Chromium.

### Coverage
- Target: 100% Ruby line coverage
- Current: 100% (275/275 lines)
- Integration tests cover Liquid tags and the full Ruby build pipeline
- Playwright browser tests cover search interaction, generated links, icons, baseurl, and network errors

## Troubleshooting

**Tests failing?**
```bash
bundle install      # Update deps
rm -rf tmp/         # Clear cache
```

**Gem not updating?**
```bash
bundle update jekyll-documents  # Path gem
gem uninstall jekyll-documents  # Installed gem
```

## CI/CD

GitHub Actions runs on every push and pull request:
1. Ruby quality suite (RuboCop, bundler-audit, RSpec) — Ruby 3.3/3.4
2. Browser tests (Playwright + Chromium)
3. Gem build verification
4. npm audit (JavaScript dependency security)
5. npm outdated (non-blocking — warns about outdated packages)

The release workflow triggers on tag push (`v*`), verifies the tag
matches the gem version, checks the CHANGELOG has an entry for the
version, builds the gem, uploads it to the GitHub release, and publishes
to RubyGems via trusted publishing (OIDC).

## Git Hooks

Install hooks locally after cloning:

```bash
bin/install-hooks.sh
```

| Hook | What it runs | When |
| --- | --- | --- |
| `pre-commit` | `rubocop` only (~2s) | Before each commit |
| `pre-push` | `rubocop + rspec` (~15s) | Before each push |

Skip with `git commit --no-verify` or `git push --no-verify`.

## Config Files

- `.rubocop.yml` - Style rules
- `.bundler-audit.yml` - Security config
