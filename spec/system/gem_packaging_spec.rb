# frozen_string_literal: true

require "spec_helper"
require "rubygems"
require "rubygems/package"

RSpec.describe "Gem packaging", type: :system do
  let(:gem_path) do
    paths = Dir.glob("jekyll-documents-*.gem")
    raise "No built gem found. Run `rake spec` or `rake install_local` first." if paths.empty?

    paths.max_by { |path| File.mtime(path) }
  end

  let(:package) { Gem::Package.new(gem_path) }
  let(:specification) { package.spec }
  let(:gem_files) { package.contents }

  it "has a freshly built gem file" do
    expect(File).to exist(gem_path)
    expect(File.mtime(gem_path)).to be > File.mtime("jekyll-documents.gemspec")
  end

  it "declares the current version and Ruby requirement" do
    expect(specification.version.to_s).to eq(Jekyll::Documents::VERSION)
    expect(specification.required_ruby_version.satisfied_by?(Gem::Version.new("3.3"))).to be true
    expect(specification.required_ruby_version.satisfied_by?(Gem::Version.new("3.2"))).to be false
  end

  it "includes every runtime source file" do
    expected = %w[
      lib/jekyll-documents.rb
      lib/jekyll/documents/version.rb
      lib/jekyll/documents/configuration.rb
      lib/jekyll/documents/generator.rb
      lib/jekyll/documents/assets_generator.rb
      lib/jekyll/documents/json_index_generator.rb
      lib/jekyll/documents/file_type_icons.rb
      lib/jekyll/documents/filters.rb
      lib/jekyll/documents/utils.rb
      lib/jekyll/documents/tags/latest_documents.rb
      lib/jekyll/documents/tags/document_icon.rb
    ]

    expect(gem_files).to include(*expected)
  end

  it "includes all runtime templates and frontend assets" do
    expected = %w[
      _layouts/document.html
      _includes/documents_list.html
      _includes/latest_documents.html
      _includes/documents_search.html
      _includes/category_list.html
      assets/js/documents-search.js
      assets/icons/color/pdf-document-svgrepo-com.svg
      assets/icons/lines/pdf-file-type-svgrepo-com.svg
      assets/icons/minimal/extension-file-format-pdf-document-file-format-svgrepo-com.svg
      assets/icons/ultra-minimal/pdf.svg
    ]

    expect(gem_files).to include(*expected)
  end

  it "includes required documentation and excludes development files" do
    expect(gem_files).to include("README.md", "CHANGELOG.md", "LICENSE", "jekyll-documents.gemspec")
    expect(gem_files).not_to include(".reek.yml", ".rubocop.yml", "Rakefile", "Gemfile")
    expect(gem_files).not_to include("AI_INSTRUCTIONS.md")
    expect(gem_files).not_to match(%r{^spec/})
  end

  it "declares dependencies compatible with the tested runtime" do
    runtime_dependencies = specification.runtime_dependencies.to_h do |dependency|
      [dependency.name, dependency.requirement]
    end
    development_dependencies = specification.development_dependencies.to_h do |dependency|
      [dependency.name, dependency.requirement]
    end

    expect(runtime_dependencies["jekyll"].satisfied_by?(Gem::Version.new("4.4.1"))).to be true
    expect(development_dependencies["rspec"].satisfied_by?(Gem::Version.new("3.13.2"))).to be true
    expect(development_dependencies["rubocop"].satisfied_by?(Gem::Version.new("1.88.2"))).to be true
    expect(development_dependencies["reek"].satisfied_by?(Gem::Version.new("6.5.0"))).to be true
  end
end
