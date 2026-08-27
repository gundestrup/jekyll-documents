# frozen_string_literal: true

require "spec_helper"
require "json"
require "tmpdir"
require "fileutils"

INSTALLED_GEM_ICON_SETS = %w[color lines minimal ultra-minimal].freeze
INSTALLED_GEM_DOCUMENTS = {
  "reports" => {
    "2026-03-01_Annual_Report.pdf" => "pdf",
    "2026-02-15_Word_Report.docx" => "docx"
  },
  "presentations" => {
    "2026-01-10_Quarterly_Update.pptx" => "pptx"
  },
  "spreadsheets" => {
    "2025-12-20_Budget.xlsx" => "xlsx"
  },
  "open-format" => {
    "2025-11-15_Text_Document.odt" => "odt",
    "2025-10-01_Data.ods" => "ods",
    "2025-09-01_Slides.odp" => "odp"
  }
}.freeze

RSpec.describe "Installed gem Jekyll build", type: :system do
  let(:site_dir) { build_fixture_site }

  after do
    FileUtils.rm_rf(site_dir) if defined?(site_dir) && site_dir
  end

  it "builds real pages, lists, latest documents, search data, and assets for every icon set",
     :slow do
    INSTALLED_GEM_ICON_SETS.each do |icon_set|
      write_config(site_dir, icon_set)
      destination = build_site(site_dir, icon_set)

      assert_document_page(destination, icon_set)
      assert_document_list(destination)
      assert_latest_documents(destination)
      assert_search_index(destination, icon_set)
      assert_published_assets(destination)
    end
  end

  private

  def build_fixture_site
    dir = Dir.mktmpdir
    FileUtils.mkdir_p(File.join(dir, "assets", "documents"))
    FileUtils.mkdir_p(File.join(dir, "_layouts"))
    FileUtils.mkdir_p(File.join(dir, "_includes"))

    INSTALLED_GEM_DOCUMENTS.each do |category, documents|
      documents.each_key do |filename|
        path = File.join(dir, "assets", "documents", category, filename)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, "test content for #{filename}")
      end
    end

    gem_root = Gem::Specification.find_by_name("jekyll-documents").full_gem_path
    Dir.glob(File.join(gem_root, "_includes", "*")) do |include_path|
      FileUtils.cp(include_path, File.join(dir, "_includes", File.basename(include_path)))
    end
    FileUtils.cp(
      File.join(gem_root, "_layouts", "document.html"),
      File.join(dir, "_layouts", "document.html")
    )

    File.write(File.join(dir, "_layouts", "default.html"), <<~HTML)
      ---
      ---
      <!doctype html>
      <html><body>{{ content }}</body></html>
    HTML

    File.write(File.join(dir, "index.md"), <<~LIQUID)
      ---
      ---
      <h1>Document index</h1>
      <section id="document-list">{% include documents_list.html %}</section>
      <section id="latest-documents">{% include latest_documents.html count=3 %}</section>
      <section id="document-search">{% include documents_search.html %}</section>
    LIQUID

    dir
  end

  def write_config(site_dir, icon_set)
    File.write(File.join(site_dir, "_config.yml"), <<~YAML)
      plugins:
        - jekyll-documents
      baseurl: /manual
      collections:
        documents:
          output: true
      documents:
        icon_set: #{icon_set}
        include_extensions:
          - .pdf
          - .docx
          - .pptx
          - .xlsx
          - .odt
          - .ods
          - .odp
    YAML
  end

  def build_site(site_dir, icon_set)
    destination = File.join(site_dir, "_site-#{icon_set}")
    output = `cd "#{site_dir}" && jekyll build --destination "#{destination}" 2>&1`
    raise "Jekyll build failed for #{icon_set}:\n#{output}" unless $CHILD_STATUS.success?

    destination
  end

  def assert_document_page(destination, icon_set)
    page = File.join(destination, "documents", "reports", "annual-report", "index.html")
    expect(File).to exist(page)

    content = File.read(page)
    expect(content).to include('<article class="document">')
    expect(content).to include("Annual Report")
    expect(content).to include(
      'href="/manual/assets/documents/reports/2026-03-01_Annual_Report.pdf"'
    )
    expect(content).to include("<img")
    expect(content).to include("document-file-icon")
    expect(content).to include("/manual/assets/icons/#{icon_set}/")
  end

  def assert_document_list(destination)
    content = File.read(File.join(destination, "index.html"))
    list = content[%r{<section id="document-list">(.*?)</section>}m, 1]

    expect(list.scan("<li>").count).to eq(7)
    expect(list).to include("Annual Report", "Word Report", "Quarterly Update", "Budget")
    expect(list).to include('href="/manual/documents/reports/annual-report/"')
    expect(list).to include('href="/manual/documents/open-format/data/"')

    expected_order = [
      "Annual Report", "Word Report", "Quarterly Update", "Budget",
      "Text Document", "Data", "Slides"
    ]
    positions = expected_order.map { |title| list.index(title) }
    expect(positions).to all(be_a(Integer))
    expect(positions).to eq(positions.sort)

    expected_categories = %w[open-format presentations reports spreadsheets]
    categories = list.scan(%r{<small>\((?:[^,]+), ([^)]+)\)</small>}).flatten.uniq.sort
    expect(categories).to eq(expected_categories)
  end

  def assert_latest_documents(destination)
    content = File.read(File.join(destination, "index.html"))
    latest = content[%r{<section id="latest-documents">(.*?)</section>}m, 1]

    expect(latest.scan("<li>").count).to eq(3)
    expect(latest).to include("Annual Report")
    expect(latest).not_to include("Slides")
  end

  def assert_search_index(destination, icon_set)
    index_path = File.join(destination, "documents.json")
    search_path = File.join(destination, "assets", "js", "documents-search.js")
    data = JSON.parse(File.read(index_path))
    search_js = File.read(search_path)

    expect(data.size).to eq(7)
    expect(data.map { |entry| entry["file_type"] }).to contain_exactly(
      "pdf", "docx", "pptx", "xlsx", "odt", "ods", "odp"
    )
    expect(data).to all(include("url", "title", "category", "file_type", "icon_url"))
    icon_urls = data.map { |entry| entry["icon_url"] }
    expect(icon_urls.all? { |url| url.start_with?("/assets/icons/#{icon_set}/") }).to be true
    expect(search_js).to include("lunr", "idx.search", "__jekyllDocumentsIndexPath")

    page = File.read(File.join(destination, "index.html"))
    expect(page).to include("/manual/documents.json")
    expect(page).to include("/manual/assets/js/documents-search.js")
  end

  def assert_published_assets(destination)
    data = JSON.parse(File.read(File.join(destination, "documents.json")))
    data.each do |entry|
      icon_path = File.join(destination, entry["icon_url"].delete_prefix("/"))
      expect(File).to exist(icon_path)
    end

    expect(File).to exist(File.join(destination, "assets", "icons", "color",
                                    "folder-svgrepo-com.svg"))
    expect(File).to exist(File.join(destination, "assets", "icons", "lines",
                                    "folder-svgrepo-com.svg"))
    expect(File).to exist(File.join(destination, "assets", "icons", "minimal",
                                    "folder-svgrepo-com.svg"))
    expect(File).to exist(File.join(destination, "assets", "icons", "ultra-minimal",
                                    "folder-svgrepo-com.svg"))
  end
end
