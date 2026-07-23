# frozen_string_literal: true

require "spec_helper"
require "json"
require "liquid"

RSpec.describe "Full build pipeline", type: :system do
  include_context "with temp documents directory"

  before do
    create_document("referat", "2026-03-01_Board_Meeting.pdf")
    create_document("referat", "2026-02-15_Annual_Report.docx")
    create_document("regnskab", "2026-03-10_Budget_2026.xlsx")
  end

  it "runs generator → json index → tag render end-to-end" do
    site = site_with_documents

    Jekyll::Documents::Generator.new.generate(site)
    Jekyll::Documents::JsonIndexGenerator.new.generate(site)

    expect(site.collections["documents"].docs.size).to eq(3)

    json_file = site.static_files.find { |f| f.is_a?(Jekyll::Documents::TextStaticFile) }
    expect(json_file).not_to be_nil

    json_data = JSON.parse(json_file.instance_variable_get(:@content))
    expect(json_data.size).to eq(3)

    titles = json_data.map { |d| d["title"] }
    expect(titles).to include("Board Meeting", "Annual Report", "Budget 2026")

    categories = json_data.map { |d| d["category"] }.uniq.sort
    expect(categories).to eq(%w[referat regnskab])
  end

  it "renders latest_documents tag with generated documents" do
    site = site_with_documents
    Jekyll::Documents::Generator.new.generate(site)

    template = Liquid::Template.parse("{% latest_documents count:10 %}")
    result = template.render({}, registers: { site: site })

    expect(result).to include("Board Meeting")
    expect(result).to include("Annual Report")
    expect(result).to include("Budget 2026")
    expect(result.scan("<li>").count).to eq(3)
  end

  it "renders latest_documents tag filtered by category" do
    site = site_with_documents
    Jekyll::Documents::Generator.new.generate(site)

    template = Liquid::Template.parse("{% latest_documents category:'referat' %}")
    result = template.render({}, registers: { site: site })

    expect(result).to include("Board Meeting")
    expect(result).to include("Annual Report")
    expect(result).not_to include("Budget 2026")
  end

  it "applies category_map remapping in generator and json index" do
    site = site_with_documents("documents" => { "category_map" => { "referat" => "minutes" } })
    Jekyll::Documents::Generator.new.generate(site)
    Jekyll::Documents::JsonIndexGenerator.new.generate(site)

    docs = site.collections["documents"].docs
    referat_docs = docs.select { |d| d.data["category"] == "minutes" }
    expect(referat_docs.size).to eq(2)

    json_file = site.static_files.find { |f| f.is_a?(Jekyll::Documents::TextStaticFile) }
    json_data = JSON.parse(json_file.instance_variable_get(:@content))
    categories = json_data.map { |d| d["category"] }.uniq.sort
    expect(categories).to eq(%w[minutes regnskab])
  end

  it "applies custom permalink pattern" do
    site = site_with_documents(
      "documents" => { "permalink" => "/docs/:category/:slug/" }
    )
    Jekyll::Documents::Generator.new.generate(site)

    doc = site.collections["documents"].docs.first
    expect(doc.data["permalink"]).to start_with("/docs/")
    expect(doc.data["permalink"]).to include(doc.data["category"])
    expect(doc.data["permalink"]).to include(doc.data["slug"])
  end

  it "applies file_type_icon filter to generated documents" do
    site = site_with_documents
    Jekyll::Documents::Generator.new.generate(site)

    doc = site.collections["documents"].docs.find { |d| d.data["file_type"] == "pdf" }
    expect(doc.data["file_type"]).to eq("pdf")

    filter_class = Class.new { include Jekyll::Documents::FileTypeIcons }
    icon = filter_class.new.file_type_icon(doc.data["file_type"])
    expect(icon).to eq("/assets/icons/color/pdf-document-svgrepo-com.svg")
  end

  it "writes JSON index file to disk" do
    site = site_with_documents
    Jekyll::Documents::Generator.new.generate(site)
    Jekyll::Documents::JsonIndexGenerator.new.generate(site)

    dest_dir = Dir.mktmpdir
    begin
      json_file = site.static_files.find { |f| f.is_a?(Jekyll::Documents::TextStaticFile) }
      json_file.write(dest_dir)

      written_path = json_file.destination(dest_dir)
      expect(File.exist?(written_path)).to be true

      content = JSON.parse(File.read(written_path))
      expect(content.size).to eq(3)
    ensure
      FileUtils.rm_rf(dest_dir)
    end
  end

  it "handles multiple categories with correct category inference" do
    create_document("referat", "2026-04-01_Extra_Meeting.pdf")

    site = site_with_documents
    Jekyll::Documents::Generator.new.generate(site)

    docs = site.collections["documents"].docs
    by_category = docs.group_by { |d| d.data["category"] }

    expect(by_category["referat"].size).to eq(3)
    expect(by_category["regnskab"].size).to eq(1)
  end

  it "skips non-document files when strict_extensions is false" do
    create_document("referat", "2026-05-01_Notes.txt")
    create_document("referat", "2026-05-02_Readme.md")

    site = site_with_documents("documents" => { "strict_extensions" => false })
    Jekyll::Documents::Generator.new.generate(site)

    docs = site.collections["documents"].docs
    extensions = docs.map { |d| d.data["extension"] }
    expect(extensions).to include(".pdf", ".docx", ".xlsx")
    expect(extensions).not_to include(".txt", ".md")
  end
end
