# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe Jekyll::Documents::LayoutRegistrar do
  let(:temp_source) { Dir.mktmpdir }
  let(:site) { make_site("source" => temp_source) }

  after do
    FileUtils.rm_rf(temp_source)
  end

  it "copies gem _layouts into the site source" do
    described_class.register(site)

    copied = File.read(File.join(temp_source, "_layouts", "document.html"))
    expect(copied).to include("{{ page.title }}")
    expect(copied).to include("{{ page.file_url | relative_url }}")
  end

  it "copies gem _includes into the site source" do
    described_class.register(site)

    %w[
      latest_documents.html
      documents_list.html
      category_list.html
      documents_search.html
    ].each do |file|
      expect(File.exist?(File.join(temp_source, "_includes", file))).to be true
    end
  end

  it "does not overwrite existing user layouts" do
    user_layouts = File.join(temp_source, "_layouts")
    FileUtils.mkdir_p(user_layouts)
    File.write(File.join(user_layouts, "document.html"), "<!-- user override -->\n")

    described_class.register(site)

    expect(File.read(File.join(user_layouts, "document.html"))).to eq("<!-- user override -->\n")
  end

  it "does not overwrite existing user includes" do
    user_includes = File.join(temp_source, "_includes")
    FileUtils.mkdir_p(user_includes)
    File.write(File.join(user_includes, "documents_list.html"), "<!-- user override -->\n")

    described_class.register(site)

    result = File.read(File.join(user_includes, "documents_list.html"))
    expect(result).to eq("<!-- user override -->\n")
  end

  it "copies only files the user is missing, leaving overrides intact" do
    user_includes = File.join(temp_source, "_includes")
    FileUtils.mkdir_p(user_includes)
    File.write(File.join(user_includes, "documents_list.html"), "<!-- user override -->\n")

    described_class.register(site)

    result = File.read(File.join(user_includes, "documents_list.html"))
    expect(result).to eq("<!-- user override -->\n")
    expect(File.exist?(File.join(user_includes, "category_list.html"))).to be true
  end

  it "is idempotent (calling twice does not duplicate or error)" do
    described_class.register(site)
    described_class.register(site)

    expect(File.exist?(File.join(temp_source, "_layouts", "document.html"))).to be true
  end

  it "excludes the configured cache directory even when extraction is disabled" do
    fresh_source = Dir.mktmpdir
    fresh_site = make_site("source" => fresh_source,
                           "documents" => { "text_cache_dir" => "document-cache" })

    Jekyll::Hooks.trigger(:site, :after_init, fresh_site)

    expect(fresh_site.config["exclude"]).to include("document-cache")
  ensure
    FileUtils.rm_rf(fresh_source) if defined?(fresh_source)
  end

  it "registers a :site, :after_init hook" do
    fresh_source = Dir.mktmpdir
    fresh_site = make_site("source" => fresh_source)
    Jekyll::Hooks.trigger(:site, :after_init, fresh_site)

    expect(File.exist?(File.join(fresh_source, "_layouts", "document.html"))).to be true
  ensure
    FileUtils.rm_rf(fresh_source) if defined?(fresh_source)
  end
end
