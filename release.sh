#!/bin/bash
# Quick release script for jekyll-documents

set -e

echo "🚀 Jekyll Documents Release Script"
echo "===================================="
echo ""

# Get version from version.rb
VERSION=$(grep 'VERSION = ' lib/jekyll/documents/version.rb | sed 's/.*VERSION = "\(.*\)".*/\1/')
echo "📦 Version: $VERSION"
echo ""

# Confirm
read -p "Ready to release v$VERSION? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Release cancelled"
    exit 1
fi

echo ""
echo "1️⃣  Adding all files..."
git add .

echo "2️⃣  Committing changes..."
git commit -m "Release v$VERSION: Add configurable icon system with 4 icon sets

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

echo "3️⃣  Creating tag v$VERSION..."
git tag -a "v$VERSION" -m "Version $VERSION - Configurable Icon System"

echo "4️⃣  Pushing to GitHub..."
git push origin main
git push origin "v$VERSION"

echo "5️⃣  Building gem..."
gem build jekyll-documents.gemspec

echo ""
echo "✅ Release complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Publish to RubyGems: gem push jekyll-documents-$VERSION.gem"
echo "   2. Create GitHub release at: https://github.com/gundestrup/jekyll-documents/releases"
echo "   3. Attach gem file: jekyll-documents-$VERSION.gem"
echo ""
