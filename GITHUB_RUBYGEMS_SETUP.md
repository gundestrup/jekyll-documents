# GitHub + RubyGems Integration Setup

This guide shows how to link your GitHub repository with RubyGems for automated gem publishing.

## Benefits

✅ **Automated Publishing**: Push gem to RubyGems when you create a GitHub release  
✅ **GitHub Packages**: Also publish to GitHub Packages as backup  
✅ **Version Control**: Single source of truth for releases  
✅ **CI/CD Integration**: Automatic testing before publishing  

---

## Setup Steps

### Method 1: OIDC Trusted Publisher (Recommended)

This is the modern, more secure approach that works seamlessly with MFA.

1. Go to: https://rubygems.org/profile/oidc/pending_trusted_publishers/new
2. Fill in the form:
   - **Gem name**: `jekyll-documents`
   - **GitHub repository owner**: `gundestrup`
   - **GitHub repository name**: `jekyll-documents`
   - **Workflow filename**: `publish.yml`
   - **Environment name**: (leave blank)
3. Click **Create**
4. **Done!** No secrets needed in GitHub

### Method 2: API Key (Alternative)

If you prefer using API keys:

1. Go to: https://rubygems.org/profile/edit
2. Click **API Keys** → **New API Key**
3. **Name**: `GitHub Actions - jekyll-documents`
4. **Scopes**: ✓ Push rubygems
5. **MFA**: Select "UI and gem signin" (NOT "UI and API")
6. Copy the API key
7. Add to GitHub:
   - Go to: https://github.com/gundestrup/jekyll-documents/settings/secrets/actions
   - Click **New repository secret**
   - **Name**: `RUBYGEMS_API_KEY`
   - **Value**: Paste the API key
   - Click **Add secret**

### 2. Update Gemspec for GitHub Packages (Optional)

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

### 3. Test the Workflow

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
