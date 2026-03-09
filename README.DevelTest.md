# Development & Testing Workflow

## 1. Make Changes to Gem Code

## 2. Run Tests
```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/jekyll/documents/filters_spec.rb

# Run with coverage
bundle exec rspec --format documentation
```

**All tests must pass before releasing!**

## 3. Test in Real Jekyll App

### Option A: Use Gemfile Path (Recommended)
```ruby
# In your test Jekyll app's Gemfile
gem "jekyll-documents", path: "/Users/svend/workspace/jekyll-documents"
```
Then run `bundle` - changes are picked up automatically!

### Option B: Build and Install Manually
```bash
# In gem directory
gem build jekyll-documents.gemspec

# In your Jekyll app directory
gem install /path/to/jekyll-documents/jekyll-documents-X.Y.Z.gem
```

## 4. Verify Functionality
- Test document parsing
- Check icon display
- Verify search works
- Test all Liquid filters and tags

## 5. Repeat Until Satisfied

## When Ready to Release
### Pre-Release Checklist
- [ ] All tests passing (`bundle exec rspec`)
- [ ] Tested in real Jekyll app
- [ ] CHANGELOG.md updated
- [ ] README.md updated (if needed)
- [ ] No uncommitted changes

### Release Steps

**1. Bump version:**
```bash
./bump_version.sh patch  # or minor/major
```

**2. Update CHANGELOG.md** with changes for this version

**3. Run release script:**
```bash
./release.sh
```
This will:
- Prompt for commit message
- Commit changes
- Create git tag
- Push to GitHub

**4. Create GitHub release:**
- Click the provided link
- Add release notes
- Click **Publish release**
- ✨ Workflow automatically publishes to RubyGems!

**5. Verify publication:**
- Check: https://rubygems.org/gems/jekyll-documents
- Test install: `gem install jekyll-documents`

---

## Running Tests

### Full Test Suite
```bash
bundle exec rspec
```

### Specific Tests
```bash
# Test filters
bundle exec rspec spec/jekyll/documents/filters_spec.rb

# Test generator
bundle exec rspec spec/jekyll/documents/generator_spec.rb

# Test file type icons
bundle exec rspec spec/jekyll/documents/file_type_icons_spec.rb
```

### Watch Mode (if using guard)
```bash
bundle exec guard
```

### Test Coverage
Tests are located in `spec/` directory following RSpec conventions.

Current coverage: **72 passing tests**

---

## Troubleshooting

### Tests failing?
1. Check Ruby version: `ruby -v` (needs >= 2.7)
2. Update dependencies: `bundle install`
3. Clear cache: `rm -rf tmp/`

### Gem not updating in Jekyll app?
1. Using path in Gemfile? Run `bundle update jekyll-documents`
2. Using installed gem? Uninstall old version first: `gem uninstall jekyll-documents`
3. Clear Jekyll cache: `bundle exec jekyll clean`
