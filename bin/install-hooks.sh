#!/bin/bash
# Enable git hooks for jekyll-documents
# Usage: bin/install-hooks.sh (once after cloning)
#
# Hooks live in bin/hooks/ as tracked files and git is pointed at them
# via core.hooksPath — no copying, so the installed hooks can never
# drift from the committed ones.

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

git -C "$REPO_ROOT" config core.hooksPath bin/hooks

echo "✅ Git hooks enabled (core.hooksPath=bin/hooks):"
echo "   pre-commit:  rubocop + semgrep (fast)"
echo "   pre-push:    rake quick (full quality gate)"
echo ""
echo "   Skip with: git commit --no-verify  /  git push --no-verify"
