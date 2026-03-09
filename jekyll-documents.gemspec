# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "jekyll-documents"
  spec.version       = File.read(File.expand_path("lib/jekyll/documents/version.rb", __dir__))
                         .match(/VERSION\s*=\s*"([^"]+)"/)[1]
  spec.authors       = ["Svend Erik Gundestrup"]
  spec.email         = ["no-reply@example.com"]

  spec.summary       = "Auto-generate Jekyll pages for documents (PDF/DOCX/...) with category/date/title parsing."
  spec.description   = "A Jekyll plugin + theme that scans assets/documents/**, creates a collection item per file, " \
                       "adds metadata (title/date/category), outputs pages, generates a JSON index for Lunr, and integrates with jekyll-sitemap."
  spec.homepage      = "https://github.com/YOUR_ORG/jekyll-documents"
  spec.license       = "AGPL-3.0-only"

  spec.required_ruby_version = ">= 2.7"

  spec.files         = Dir.glob("{lib,assets,_includes,_layouts}/**/*") +
                       ["README.md", "CHANGELOG.md", "LICENSE", "jekyll-documents.gemspec"]
  spec.require_paths = ["lib"]

  spec.add_dependency "jekyll", ">= 4.0"
end
