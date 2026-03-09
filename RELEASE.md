# Release Guide

## Pre-Release Checklist

✅ All tests passing (72/72 core tests)
✅ README updated with current features
✅ CHANGELOG updated for v0.1.1
✅ Version bumped to 0.1.1
✅ Gem builds successfully
✅ Icon system complete (4 sets, 20+ formats)

## Step 1: Commit All Changes

```bash
# Add all new files
git add .

# Commit with descriptive message
git commit -m "Release v0.1.1: Add configurable icon system with 4 icon sets

- Add 4 icon sets: color, lines, minimal, ultra-minimal
- Include 20+ file type icons from svgrepo.com
- Add folder icons for category lists
- Icons appear in all views (pages, lists, search, categories)
- Add icon_set configuration option
- Update README with simplified documentation
- Fix slug generation (underscores to hyphens)
- Fix Danish character mapping
- Add comprehensive test suite (72 tests passing)
- Add YARD documentation
- Add example Jekyll site
- Add CI/CD workflow"
```

## Step 2: Tag the Release

```bash
# Create annotated tag
git tag -a v0.1.1 -m "Version 0.1.1 - Configurable Icon System"

# Push commits and tags
git push origin main
git push origin v0.1.1
```

## Step 3: Build the Gem

```bash
# Build gem
gem build jekyll-documents.gemspec

# This creates: jekyll-documents-0.1.1.gem
```

## Step 4: Test the Gem Locally (Optional)

```bash
# Install locally
gem install jekyll-documents-0.1.1.gem

# Test in a Jekyll site
cd /path/to/test-site
bundle exec jekyll build
```

## Step 5: Publish to RubyGems

### First Time Setup (if needed)
```bash
# Create RubyGems account at https://rubygems.org
# Get API key
gem signin
```

### Publish
```bash
# Push to RubyGems
gem push jekyll-documents-0.1.1.gem
```

## Step 6: Create GitHub Release

1. Go to: https://github.com/gundestrup/jekyll-documents/releases
2. Click "Draft a new release"
3. Choose tag: `v0.1.1`
4. Release title: `v0.1.1 - Configurable Icon System`
5. Description:

```markdown
## 🎨 Configurable Icon System

Choose from 4 beautiful icon styles for your documents!

### New Features
- **4 Icon Sets**: color, lines, minimal, ultra-minimal
- **20+ File Types**: PDF, DOCX, XLSX, PPTX, ODT, TXT, ZIP, MP3, MP4, JPG, PNG, and more
- **Folder Icons**: Category lists now show folder icons
- **Icons Everywhere**: Document pages, lists, search results, categories

### Configuration
```yaml
documents:
  icon_set: "color"  # Choose: color, lines, minimal, ultra-minimal
```

### Improvements
- Simplified README documentation
- Fixed slug generation (underscores → hyphens)
- Fixed Danish character mapping
- Comprehensive test suite (72 tests)
- YARD documentation
- Example Jekyll site

### Attribution
Icons from [SVG Repo](https://www.svgrepo.com)

### Installation
```ruby
gem "jekyll-documents", "~> 0.1.1"
```

See [README](https://github.com/gundestrup/jekyll-documents#readme) for full documentation.
```

6. Attach the gem file: `jekyll-documents-0.1.1.gem`
7. Click "Publish release"

## Verification

After publishing:

1. **RubyGems**: Check https://rubygems.org/gems/jekyll-documents
2. **GitHub**: Verify release at https://github.com/gundestrup/jekyll-documents/releases
3. **Install Test**: `gem install jekyll-documents` in a fresh environment

## Future Releases

For next release:
1. Update `lib/jekyll/documents/version.rb`
2. Update `CHANGELOG.md`
3. Follow steps above
