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
read -p "Enter commit message: " COMMIT_MSG
if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG="Release v$VERSION"
fi
git commit -m "$COMMIT_MSG"

echo "3️⃣  Creating tag v$VERSION..."
git tag -a "v$VERSION" -m "Version $VERSION"

echo "4️⃣  Pushing to GitHub..."
git push origin main
git push origin "v$VERSION"

echo ""
echo "✅ Code pushed to GitHub!"
echo ""
echo "📋 Next step:"
echo "   Create GitHub release at: https://github.com/gundestrup/jekyll-documents/releases/new?tag=v$VERSION"
echo ""
echo "   The workflow will automatically:"
echo "   ✓ Build the gem"
echo "   ✓ Publish to RubyGems.org (via OIDC)"
echo ""
echo "   No manual gem push needed! 🎉"
echo ""
