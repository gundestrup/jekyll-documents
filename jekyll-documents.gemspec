# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "jekyll-documents"
  spec.version       = File.read(File.expand_path("lib/jekyll/documents/version.rb", __dir__))
                           .match(/VERSION\s*=\s*"([^"]+)"/)[1]
  spec.authors       = ["Svend Gundestrup"]
  spec.email         = ["no-reply@borg-collective.eu"]

  spec.summary       = "Auto-generate Jekyll pages for documents (PDF/DOCX/...) " \
                       "with category/date/title parsing."
  spec.description   = "A Jekyll plugin + theme that scans assets/documents/**, " \
                       "creates a collection item per file, adds metadata " \
                       "(title/date/category), outputs pages, generates " \
                       "a JSON index for Lunr, and integrates with jekyll-sitemap."
  spec.homepage      = "https://github.com/gundestrup/jekyll-documents"
  spec.license       = "AGPL-3.0-only"

  spec.metadata = {
    "source_code_uri" => "https://github.com/gundestrup/jekyll-documents",
    "bug_tracker_uri" => "https://github.com/gundestrup/jekyll-documents/issues",
    "changelog_uri" => "https://github.com/gundestrup/jekyll-documents/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://github.com/gundestrup/jekyll-documents",
    "homepage_uri" => "https://github.com/gundestrup/jekyll-documents",
    "rubygems_mfa_required" => "true"
  }

  spec.required_ruby_version = ">= 2.7"

  spec.files         = Dir.glob("{lib,assets,_includes,_layouts}/**/*") +
                       ["README.md", "CHANGELOG.md", "LICENSE", "jekyll-documents.gemspec"]
  spec.require_paths = ["lib"]

  spec.add_dependency "jekyll", ">= 4.0"

  spec.add_development_dependency "bundler-audit", "~> 0.9"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "reek", "~> 6.1"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.60"
  spec.add_development_dependency "rubocop-performance", "~> 1.20"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "yard", "~> 0.9"
end
