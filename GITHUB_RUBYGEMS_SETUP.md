# GitHub + RubyGems Integration Setup

This guide shows how to link your GitHub repository with RubyGems for automated gem publishing.

## Benefits

✅ **Automated Publishing**: Push gem to RubyGems when you create a GitHub release  
✅ **GitHub Packages**: Also publish to GitHub Packages as backup  
✅ **Version Control**: Single source of truth for releases  
✅ **CI/CD Integration**: Automatic testing before publishing  

---

## Setup Steps

### 1. Get RubyGems API Token

1. Sign in to RubyGems: https://rubygems.org/sign_in
2. Go to your profile settings: https://rubygems.org/profile/edit
3. Click on "API Keys" in the sidebar
4. Click "New API Key"
5. **Name**: `GitHub Actions - jekyll-documents`
6. **Scopes**: Select "Push rubygems"
7. **Index rubygems**: Leave unchecked
8. **MFA**: Enable if you have 2FA (recommended)
9. Click "Create"
10. **Copy the API key** (you'll only see it once!)

### 2. Add Secret to GitHub

1. Go to your repository: https://github.com/gundestrup/jekyll-documents
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. **Name**: `RUBYGEMS_API_KEY`
5. **Value**: Paste your RubyGems API key
6. Click **Add secret**

### 3. Update Gemspec for GitHub Packages (Optional)

The gemspec already has the correct metadata. Verify it includes:

```ruby
spec.metadata = {
  "source_code_uri" => "https://github.com/gundestrup/jekyll-documents",
  "bug_tracker_uri" => "https://github.com/gundestrup/jekyll-documents/issues",
  "changelog_uri"   => "https://github.com/gundestrup/jekyll-documents/blob/main/CHANGELOG.md",
  "documentation_uri" => "https://github.com/gundestrup/jekyll-documents",
  "homepage_uri"    => "https://github.com/gundestrup/jekyll-documents"
}
```

### 4. Test the Workflow

The workflow is triggered when you **publish a GitHub release**. To test:

1. Go to: https://github.com/gundestrup/jekyll-documents/releases
2. Click **Draft a new release**
3. Choose tag: `v0.1.1` (or create new version)
4. Click **Publish release**
5. Watch the Actions tab: https://github.com/gundestrup/jekyll-documents/actions

The workflow will:
- ✅ Build the gem
- ✅ Run tests
- ✅ Publish to RubyGems.org
- ✅ Publish to GitHub Packages

---

## How It Works

### Automatic Publishing Workflow

```yaml
# .github/workflows/publish.yml
on:
  release:
    types: [published]  # Triggers when you publish a release
```

When you create a GitHub release:
1. GitHub Actions runs the workflow
2. Builds the gem from gemspec
3. Publishes to RubyGems using your API key
4. Publishes to GitHub Packages (optional)

### Manual Publishing (Fallback)

If you prefer manual control, you can still publish manually:

```bash
gem build jekyll-documents.gemspec
gem push jekyll-documents-0.1.1.gem
```

---

## Future Releases

### Automated Process

1. **Update version** in `lib/jekyll/documents/version.rb`
2. **Update CHANGELOG.md**
3. **Commit changes**:
   ```bash
   git add .
   git commit -m "Bump version to 0.2.0"
   git push
   ```
4. **Create GitHub release**:
   - Go to https://github.com/gundestrup/jekyll-documents/releases/new
   - Create tag: `v0.2.0`
   - Write release notes
   - Click **Publish release**
5. **Done!** GitHub Actions automatically publishes to RubyGems

### Version Bumping Helper

You can use the included script:

```bash
# Bump patch version (0.1.1 → 0.1.2)
./bump_version.sh patch

# Bump minor version (0.1.1 → 0.2.0)
./bump_version.sh minor

# Bump major version (0.1.1 → 1.0.0)
./bump_version.sh major
```

---

## Installing from GitHub Packages

Users can install from GitHub Packages as an alternative:

```ruby
# Gemfile
source "https://rubygems.pkg.github.com/gundestrup" do
  gem "jekyll-documents", "~> 0.1.1"
end
```

They'll need a GitHub token with `read:packages` permission.

---

## Verification

After setup, verify:

1. **RubyGems**: https://rubygems.org/gems/jekyll-documents
2. **GitHub Packages**: https://github.com/gundestrup/jekyll-documents/packages
3. **GitHub Actions**: https://github.com/gundestrup/jekyll-documents/actions

---

## Security Notes

- ✅ API key stored as GitHub secret (encrypted)
- ✅ Only accessible to GitHub Actions
- ✅ Can be rotated anytime from RubyGems settings
- ✅ Scoped to only push gems (not delete/yank)
- ⚠️ Enable 2FA on RubyGems for extra security

---

## Troubleshooting

### Workflow fails with "Unauthorized"
- Check that `RUBYGEMS_API_KEY` secret is set correctly
- Verify API key hasn't expired
- Ensure API key has "Push rubygems" scope

### Gem version already exists
- You can't republish the same version
- Bump version in `version.rb` first
- Or yank the version from RubyGems (not recommended)

### GitHub Packages fails
- Ensure repository is public or users have access
- Check that GITHUB_TOKEN has packages:write permission

---

## Next Steps

1. ✅ Set up RubyGems API key
2. ✅ Add secret to GitHub
3. ✅ Create a release to test
4. 🎉 Enjoy automated publishing!
