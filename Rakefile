# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "yard"

RSpec::Core::RakeTask.new(:spec)
YARD::Rake::YardocTask.new

# Default task: run all quality checks (most common use case)
task default: :quality

desc "Run all tests with coverage"
task test: :spec

desc "Run all quality checks (style, smells, security, tests)"
task quality: %i[rubocop reek bundler_audit spec]

desc "Run tests only (fast)"
task :spec do
  sh "bundle exec rspec"
end

desc "Check code style with RuboCop"
task :rubocop do
  sh "bundle exec rubocop"
end

desc "Auto-fix RuboCop issues"
task :rubocop_fix do
  sh "bundle exec rubocop -a"
end

desc "Check code smells with Reek"
task :reek do
  sh "bundle exec reek --config .reek.yml lib/"
end

desc "Run security audit"
task :bundler_audit do
  sh "bundle exec bundler-audit check --update"
end

desc "Run quick checks (style + tests only)"
task :quick do
  puts "🏃 Running quick checks..."
  begin
    sh "bundle exec rubocop"
    puts "✅ Style checks passed"
  rescue StandardError
    puts "⚠️  Style issues found (continuing with tests)"
  end
  sh "bundle exec rspec"
  puts "✅ Tests passed"
end

desc "Generate YARD documentation"
task :doc do
  sh "yard doc"
end

desc "Build and install the gem locally"
task :install_local do
  sh "gem build jekyll-documents.gemspec"
  sh "gem install jekyll-documents-*.gem"
end

# Display available tasks with descriptions
desc "Show available testing tasks"
task :help do
  puts "🧪 Testing Tasks:"
  puts "  rake              # Run all quality checks (default)"
  puts "  rake quality      # Run all quality checks"
  puts "  rake test         # Run tests only"
  puts "  rake spec         # Run tests with coverage"
  puts "  rake quick        # Quick check (style + tests)"
  puts ""
  puts "🔧 Individual Checks:"
  puts "  rake rubocop      # Code style check"
  puts "  rake rubocop_fix  # Auto-fix style issues"
  puts "  rake reek         # Code smell check"
  puts "  rake bundler_audit # Security scan"
  puts ""
  puts "📦 Other:"
  puts "  rake doc          # Generate documentation"
  puts "  rake install_local # Install gem locally"
  puts "  rake help         # Show this help"
end
