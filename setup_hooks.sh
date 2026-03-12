#!/bin/bash
# Setup git hooks for jekyll-documents

echo "🔧 Setting up git hooks..."
echo ""

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Create pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook for jekyll-documents
# Runs quick quality checks before allowing commit

echo "🔍 Running pre-commit checks..."
echo ""

# Run quick checks (style + tests)
if rake quick 2>&1 | grep -q "✅ Tests passed"; then
    echo ""
    echo "✅ Pre-commit checks passed"
    exit 0
else
    echo ""
    echo "❌ Pre-commit checks failed"
    echo ""
    echo "Fix the issues or use 'git commit --no-verify' to skip checks"
    exit 1
fi
EOF

# Make it executable
chmod +x .git/hooks/pre-commit

echo "✅ Pre-commit hook installed"
echo ""
echo "The hook will run 'rake quick' before each commit."
echo "To skip the hook, use: git commit --no-verify"
echo ""
