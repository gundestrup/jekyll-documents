#!/bin/bash
# Rollback script for jekyll-documents
# Usage: ./rollback.sh v0.1.2

set -e

if [ -z "$1" ]; then
    echo "❌ Error: Version tag required"
    echo ""
    echo "Usage: ./rollback.sh v0.1.2"
    echo ""
    echo "This will:"
    echo "  • Delete the git tag"
    echo "  • Revert the release commit"
    echo "  • Clean up built gems"
    echo ""
    exit 1
fi

TAG="$1"
VERSION="${TAG#v}"

echo "🔄 Rollback Release Script"
echo "=========================="
echo ""
echo "⚠️  WARNING: This will rollback release $TAG"
echo ""

# Confirm
read -p "Are you sure you want to rollback $TAG? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Rollback cancelled"
    exit 1
fi

echo ""
echo "1️⃣  Checking if tag exists..."
if ! git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "❌ Tag $TAG does not exist"
    exit 1
fi
echo "✅ Tag $TAG found"

echo "2️⃣  Deleting local tag..."
git tag -d "$TAG"
echo "✅ Local tag deleted"

echo "3️⃣  Deleting remote tag..."
git push origin ":refs/tags/$TAG" || echo "⚠️  Remote tag may not exist"
echo "✅ Remote tag deleted (if it existed)"

echo "4️⃣  Finding release commit..."
RELEASE_COMMIT=$(git log --grep="Release v$VERSION" --format="%H" -n 1)
if [ -n "$RELEASE_COMMIT" ]; then
    echo "Found release commit: $RELEASE_COMMIT"
    read -p "Revert this commit? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git revert "$RELEASE_COMMIT" --no-edit
        echo "✅ Release commit reverted"
    fi
else
    echo "ℹ️  No release commit found"
fi

echo "5️⃣  Cleaning up built gems..."
rm -f jekyll-documents-*.gem
echo "✅ Built gems cleaned up"

echo ""
echo "✅ Rollback completed!"
echo ""
echo "📋 Next steps:"
echo "  1. If the gem was published to RubyGems, you cannot unpublish it"
echo "     (RubyGems policy - versions are permanent)"
echo "  2. If there's a critical issue, release a new patch version"
echo "  3. Update CHANGELOG.md to document the rollback"
echo ""
echo "  GitHub release (if created) must be deleted manually:"
echo "  https://github.com/gundestrup/jekyll-documents/releases"
echo ""
