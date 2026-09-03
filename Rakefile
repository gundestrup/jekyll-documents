# frozen_string_literal: true

require "bundler/gem_tasks"
require "yard"

YARD::Rake::YardocTask.new

VERSION_FILE = File.expand_path("lib/jekyll/documents/version.rb", __dir__)
CHANGELOG_FILE = File.expand_path("CHANGELOG.md", __dir__)

# Default task: run all quality checks (most common use case)
task default: :quality

desc "Run all tests with coverage"
task test: %i[install_local spec browser_test]

desc "Run all quality checks (style, security, tests)"
task quality: %i[install_local rubocop bundler_audit spec]

desc "Run tests only (fast)"
task spec: :install_local do
  sh "bundle exec rspec"
end

desc "Run browser end-to-end tests"
task browser_test: :install_local do
  sh "npm run test:browser"
end

desc "Check code style with RuboCop"
task :rubocop do
  sh "bundle exec rubocop"
end

desc "Auto-fix RuboCop issues"
task :rubocop_fix do
  sh "bundle exec rubocop -a"
end

desc "Run security audit"
task :bundler_audit do
  sh "bundle exec bundler-audit check --update"
end

desc "Run quick checks (style + tests only)"
task quick: :install_local do
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
task install_local: :build do
  version = File.read(VERSION_FILE)[/VERSION = "([^"]+)"/, 1]
  sh "gem install --force pkg/jekyll-documents-#{version}.gem"
end

# Display available tasks with descriptions
desc "Show available testing tasks"
task :help do
  puts "🧪 Testing Tasks:"
  puts "  rake              # Run all quality checks (default)"
  puts "  rake quality      # Run all quality checks"
  puts "  rake test         # Rebuild/install gem + Ruby + browser tests"
  puts "  rake spec         # Rebuild/install gem + tests with coverage"
  puts "  rake quick        # Rebuild/install gem + quick checks"
  puts "  rake browser_test # Rebuild/install gem + browser tests"
  puts ""
  puts "🔧 Individual Checks:"
  puts "  rake rubocop      # Code style check"
  puts "  rake rubocop_fix  # Auto-fix style issues"
  puts "  rake bundler_audit # Security scan"
  puts ""
  puts "📦 Other:"
  puts "  rake doc          # Generate documentation"
  puts "  rake install_local # Install gem locally"
  puts "  rake help         # Show this help"
end

namespace :version do
  desc "Print the current gem version"
  task :show do
    puts File.read(VERSION_FILE)[/VERSION = "([^"]+)"/, 1]
  end

  desc "Bump the gem version: bundle exec rake 'version:bump[patch]'"
  task :bump, [:part] do |_task, args|
    part = args[:part].to_s
    abort "Usage: bundle exec rake 'version:bump[major|minor|patch]'" unless
      %w[major minor patch].include?(part)

    current = Gem::Version.new(File.read(VERSION_FILE)[/VERSION = "([^"]+)"/, 1])
    segments = current.segments
    index = { "major" => 0, "minor" => 1, "patch" => 2 }.fetch(part)
    segments[index] += 1
    ((index + 1)...segments.length).each { |position| segments[position] = 0 }
    next_version = segments.join(".")

    content = File.read(VERSION_FILE)
    updated = content.sub(/VERSION = "[^"]+"/, "VERSION = \"#{next_version}\"")
    File.write(VERSION_FILE, updated)

    puts "Bumped #{current} -> #{next_version}"
    puts "Updated: #{VERSION_FILE}"
    puts "Add a '## [#{next_version}] - YYYY-MM-DD' entry to CHANGELOG.md before committing."
  end

  desc "Verify CHANGELOG.md has an entry for the current version"
  task :check_changelog do
    version = File.read(VERSION_FILE)[/VERSION = "([^"]+)"/, 1]
    changelog = File.read(CHANGELOG_FILE)
    unless changelog.match?(/^## \[#{Regexp.escape(version)}\]/)
      abort "CHANGELOG.md has no '## [#{version}]' entry. Add one before releasing."
    end
    puts "✅ CHANGELOG.md has an entry for version #{version}"
  end
end
