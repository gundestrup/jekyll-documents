# Development Guide

## Quick Start

```bash
rake              # Run all quality checks
rake quick        # Quick check (style + tests)
rake help         # Show all commands
```

## Quality Tools

**Coverage**: 98.99% (197/199 lines)  
**Security**: 0 vulnerabilities  
**Style**: 3 minor offenses (acceptable)  
**Smells**: 23 warnings (acceptable)

## Commands

```bash
# Testing
rake              # All checks (default)
rake quality      # All checks
rake test         # Tests only
rake spec         # Tests + coverage
rake quick        # Fast check

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
bundle exec rspec              # All tests
bundle exec rspec spec/filters # Specific file
```

### Coverage
- Target: 98%
- Current: 98.99%
- Integration tests for Liquid tags

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
