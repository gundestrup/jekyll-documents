#!/bin/bash
# Version bumping script for jekyll-documents

set -e

VERSION_FILE="lib/jekyll/documents/version.rb"

# Get current version
CURRENT=$(grep 'VERSION = ' "$VERSION_FILE" | sed 's/.*VERSION = "\(.*\)".*/\1/')
IFS='.' read -r -a parts <<< "$CURRENT"

MAJOR="${parts[0]}"
MINOR="${parts[1]}"
PATCH="${parts[2]}"

case "$1" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    echo "Usage: $0 {major|minor|patch}"
    echo ""
    echo "Current version: $CURRENT"
    echo ""
    echo "Examples:"
    echo "  $0 patch  # $CURRENT → ${MAJOR}.${MINOR}.$((PATCH + 1))"
    echo "  $0 minor  # $CURRENT → ${MAJOR}.$((MINOR + 1)).0"
    echo "  $0 major  # $CURRENT → $((MAJOR + 1)).0.0"
    exit 1
    ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"

echo "Bumping version: $CURRENT → $NEW_VERSION"
echo ""

# Update version file
sed -i.bak "s/VERSION = \".*\"/VERSION = \"$NEW_VERSION\"/" "$VERSION_FILE"
rm "${VERSION_FILE}.bak"

echo "✅ Updated $VERSION_FILE"
echo ""
echo "Next steps:"
echo "  1. Update CHANGELOG.md with changes for v$NEW_VERSION"
echo "  2. Commit: git add . && git commit -m 'Bump version to $NEW_VERSION'"
echo "  3. Tag: git tag -a v$NEW_VERSION -m 'Version $NEW_VERSION'"
echo "  4. Push: git push origin main --tags"
echo "  5. Create GitHub release at: https://github.com/gundestrup/jekyll-documents/releases/new"
echo ""
