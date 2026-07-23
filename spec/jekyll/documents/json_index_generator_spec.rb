# frozen_string_literal: true

require "spec_helper"
require "json"

RSpec.describe Jekyll::Documents::JsonIndexGenerator do
  let(:generator) { described_class.new }
  let(:site) { make_site }

  describe "#generate" do
    context "when json_index is disabled" do
      it "does not generate JSON file" do
        site = make_site("documents" => { "json_index" => false })
        generator.generate(site)

        expect(site.static_files).to be_empty
      end
    end

    context "when documents collection is empty" do
      it "does not generate JSON file" do
        site = make_site
        site.collections["documents"] = Jekyll::Collection.new(site, "documents")

        generator.generate(site)

        expect(site.static_files).to be_empty
      end
    end

    context "when documents collection is nil" do
      it "does not generate JSON file" do
        site = make_site

        generator.generate(site)

        expect(site.static_files).to be_empty
      end
    end

    context "with documents" do
      include_context "with temp documents directory"

      before do
        create_document("referat", "2026-03-01_Board_Meeting.pdf")
        create_document("referat", "2026-02-15_Annual_Report.docx")
      end

      def generate_all(site)
        Jekyll::Documents::Generator.new.generate(site)
        generator.generate(site)
      end

      def json_data(site)
        json_file = site.static_files.find { |f| f.is_a?(Jekyll::Documents::TextStaticFile) }
        JSON.parse(json_file.instance_variable_get(:@content))
      end

      it "generates JSON index file" do
        site = site_with_documents
        generate_all(site)

        json_file = site.static_files.find { |f| f.is_a?(Jekyll::Documents::TextStaticFile) }
        expect(json_file).not_to be_nil
      end

      it "includes document metadata in JSON" do
        site = site_with_documents
        generate_all(site)
        data = json_data(site)

        expect(data).to be_an(Array)
        expect(data.size).to eq(2)

        first_doc = data.first
        expect(first_doc).to have_key("url")
        expect(first_doc).to have_key("title")
        expect(first_doc).to have_key("category")
        expect(first_doc).to have_key("date")
        expect(first_doc).to have_key("slug")
        expect(first_doc).to have_key("file_type")
        expect(first_doc).to have_key("extension")
      end

      it "includes correct title values" do
        site = site_with_documents
        generate_all(site)
        data = json_data(site)

        titles = data.map { |d| d["title"] }
        expect(titles).to include("Board Meeting")
        expect(titles).to include("Annual Report")
      end

      it "includes correct category value" do
        site = site_with_documents
        generate_all(site)
        data = json_data(site)

        expect(data.all? { |d| d["category"] == "referat" }).to be true
      end

      it "includes correct file_type and extension values" do
        site = site_with_documents
        generate_all(site)
        data = json_data(site)

        pdf_doc = data.find { |d| d["extension"] == ".pdf" }
        expect(pdf_doc["file_type"]).to eq("pdf")

        docx_doc = data.find { |d| d["extension"] == ".docx" }
        expect(docx_doc["file_type"]).to eq("docx")
      end

      it "includes correct slug values" do
        site = site_with_documents
        generate_all(site)
        data = json_data(site)

        slugs = data.map { |d| d["slug"] }
        expect(slugs).to include("board-meeting")
        expect(slugs).to include("annual-report")
      end

      it "formats dates as YYYY-MM-DD" do
        site = site_with_documents
        generate_all(site)
        data = json_data(site)

        expect(data.all? { |d| d["date"] =~ /^\d{4}-\d{2}-\d{2}$/ }).to be true
      end

      it "includes correct date values" do
        site = site_with_documents
        generate_all(site)
        data = json_data(site)

        dates = data.map { |d| d["date"] }
        expect(dates).to include("2026-03-01")
        expect(dates).to include("2026-02-15")
      end

      it "uses custom json_index_path when configured" do
        site = site_with_documents("documents" => { "json_index_path" => "/custom/path.json" })
        generate_all(site)

        json_file = site.static_files.find { |f| f.is_a?(Jekyll::Documents::TextStaticFile) }
        expect(json_file.instance_variable_get(:@dir)).to eq("/custom")
        expect(json_file.instance_variable_get(:@name)).to eq("path.json")
      end

      it "generates valid JSON parseable by JSON.parse" do
        site = site_with_documents
        generate_all(site)

        expect { json_data(site) }.not_to raise_error
      end
    end
  end
end
