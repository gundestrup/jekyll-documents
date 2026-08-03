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
- **Smells**: 0 warnings

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
rake reek         # Code smells
rake bundler_audit # Security

# Development
rake doc          # Generate docs
rake install_local # Install locally
```

## Development Workflow

### 1. Setup
```bash
./setup_hooks.sh  # Install pre-commit hooks (optional)
```

### 2. Make Changes
Edit code in `lib/` directory

### 3. Test Changes
```bash
rake quick        # Fast check during development
rake              # Full check before commit
```

Pre-commit hook runs `rake quick` automatically.

### 4. Test in Real App
```ruby
# Gemfile in test app
gem "jekyll-documents", path: "/path/to/this/repo"
```

### 5. Release
```bash
./bump_version.sh patch  # Update version + CHANGELOG template
# Edit CHANGELOG.md to fill in changes
./release.sh             # Release with all checks
./release.sh --dry-run   # Preview without changes
```

### 6. Rollback (if needed)
```bash
./rollback.sh v0.1.2     # Undo a release
```

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

## Release Features

**Automated Checks:**
- ✅ Git status (uncommitted changes)
- ✅ CHANGELOG validation
- ✅ Version consistency
- ✅ Dependency check
- ✅ Quality checks (tests + style + security)
- ✅ Gem build verification

**Automated Actions:**
- ✅ CHANGELOG template generation
- ✅ Release notes extraction
- ✅ Clipboard copy (macOS/Linux)
- ✅ Post-release verification links

**Safety Features:**
- ✅ Dry-run mode (`--dry-run`)
- ✅ Rollback script
- ✅ Pre-commit hooks

## CI/CD

GitHub Actions runs:
1. Security audit
2. Code style
3. Code smells  
4. Tests

## Scripts

- `bump_version.sh` - Version bumping + CHANGELOG template
- `release.sh` - Full release with validation
- `rollback.sh` - Undo a release
- `setup_hooks.sh` - Install git hooks

## Config Files

- `.rubocop.yml` - Style rules
- `.reek.yml` - Smell detection
- `.bundler-audit.yml` - Security config
