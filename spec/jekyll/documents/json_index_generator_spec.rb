# frozen_string_literal: true

require "spec_helper"
require "json"
require "fileutils"
require "tmpdir"

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

    context "with documents" do
      let(:temp_dir) { Dir.mktmpdir }
      let(:docs_dir) { File.join(temp_dir, "assets", "documents", "referat") }

      before do
        FileUtils.mkdir_p(docs_dir)
        File.write(File.join(docs_dir, "2026-03-01_Board_Meeting.pdf"), "fake pdf")
        File.write(File.join(docs_dir, "2026-02-15_Annual_Report.docx"), "fake docx")
      end

      after do
        FileUtils.rm_rf(temp_dir)
      end

      it "generates JSON index file" do
        site = make_site("source" => temp_dir)
        doc_generator = Jekyll::Documents::Generator.new
        doc_generator.generate(site)
        
        generator.generate(site)
        
        json_file = site.static_files.find { |f| f.is_a?(Jekyll::Documents::TextStaticFile) }
        expect(json_file).not_to be_nil
      end

      it "includes document metadata in JSON" do
        site = make_site("source" => temp_dir)
        doc_generator = Jekyll::Documents::Generator.new
        doc_generator.generate(site)
        
        generator.generate(site)
        
        json_file = site.static_files.find { |f| f.is_a?(Jekyll::Documents::TextStaticFile) }
        json_data = JSON.parse(json_file.instance_variable_get(:@content))
        
        expect(json_data).to be_an(Array)
        expect(json_data.size).to eq(2)
        
        first_doc = json_data.first
        expect(first_doc).to have_key("url")
        expect(first_doc).to have_key("title")
        expect(first_doc).to have_key("category")
        expect(first_doc).to have_key("date")
        expect(first_doc).to have_key("slug")
      end

      it "formats dates as YYYY-MM-DD" do
        site = make_site("source" => temp_dir)
        doc_generator = Jekyll::Documents::Generator.new
        doc_generator.generate(site)
        
        generator.generate(site)
        
        json_file = site.static_files.find { |f| f.is_a?(Jekyll::Documents::TextStaticFile) }
        json_data = JSON.parse(json_file.instance_variable_get(:@content))
        
        expect(json_data.first["date"]).to match(/^\d{4}-\d{2}-\d{2}$/)
      end

      it "uses custom json_index_path when configured" do
        site = make_site(
          "source" => temp_dir,
          "documents" => { "json_index_path" => "/custom/path.json" }
        )
        doc_generator = Jekyll::Documents::Generator.new
        doc_generator.generate(site)
        
        generator.generate(site)
        
        json_file = site.static_files.find { |f| f.is_a?(Jekyll::Documents::TextStaticFile) }
        expect(json_file.instance_variable_get(:@dir)).to eq("/custom")
        expect(json_file.instance_variable_get(:@name)).to eq("path.json")
      end
    end
  end
end
