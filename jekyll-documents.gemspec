# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "jekyll-documents"
  spec.version       = File.read(File.expand_path("lib/jekyll/documents/version.rb", __dir__))
                           .match(/VERSION\s*=\s*"([^"]+)"/)[1]
  spec.authors       = ["Svend Gundestrup"]
  spec.email         = ["no-reply@borg-collective.eu"]

  spec.summary       = "Auto-generate Jekyll pages for documents (PDF/DOCX/...) " \
                       "with category/date/title parsing."
  # NOTE: rubygems.org renders the description through RDoc::Markup only
  # when it starts with an == heading at column 0 — keep the heredoc
  # content flush-left or the page renders as one plain <p>.
  spec.description   = <<~DESC
    == Jekyll document pages

    Scans assets/documents/** into a browsable collection — one page per
    file with title, date, category and file-type icons baked at
    generation time — plus a Lunr JSON index and sitemap integration.

    * YYYY-MM-DD_Title.ext filenames; nested categories from folders
    * Tags: doc_link, doc_category, document_icon, latest_documents
    * Optional text extraction cache and jekyll-client-search integration

    A companion VS Code extension (jekyll-imgflow-vscode) provides tag
    autocomplete: https://github.com/gundestrup/jekyll-imgflow-vscode
  DESC
  spec.homepage      = "https://github.com/gundestrup/jekyll-documents"
  spec.license       = "AGPL-3.0-only"

  spec.metadata = {
    "source_code_uri" => "https://github.com/gundestrup/jekyll-documents",
    "bug_tracker_uri" => "https://github.com/gundestrup/jekyll-documents/issues",
    "changelog_uri" => "https://github.com/gundestrup/jekyll-documents/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://deepwiki.com/gundestrup/jekyll-documents",
    "rubygems_mfa_required" => "true"
  }

  # Floor derived from .ruby-version's major.minor — single source for the
  # supported minimum. If the floor ever needs to lag the dev version
  # (e.g. support 3.3 while developing on 3.4), revert to a literal here.
  spec.required_ruby_version =
    ">= #{File.read(File.expand_path('.ruby-version', __dir__)).strip[/\d+\.\d+/]}"

  spec.files         = Dir.glob("{lib,assets,_includes,_layouts}/**/*") +
                       ["README.md", "CHANGELOG.md", "LICENSE", "interface.yml",
                        "jekyll-documents.gemspec"]
  spec.require_paths = ["lib"]

  spec.add_dependency "jekyll", ">= 4.4", "< 5.0"
end
