# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"

RSpec.describe Jekyll::Documents::Generator do
  let(:generator) { described_class.new }
  let(:site) { make_site }

  describe "#generate" do
    context "when documents directory does not exist" do
      it "logs a warning and returns early" do
        site = make_site("documents" => { "root" => "nonexistent/path" })

        expect(Jekyll.logger).to receive(:warn).with("jekyll-documents", /Directory not found/)

        generator.generate(site)
        expect(site.collections["documents"]).to be_nil
      end
    end

    context "with valid documents" do
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

      it "creates documents collection" do
        site = make_site("source" => temp_dir)
        generator.generate(site)

        expect(site.collections["documents"]).not_to be_nil
        expect(site.collections["documents"].docs.size).to eq(2)
      end

      it "configures collection for output" do
        site = make_site("source" => temp_dir)
        generator.generate(site)

        expect(site.config["collections"]["documents"]["output"]).to be true
      end

      it "parses filename correctly" do
        site = make_site("source" => temp_dir)
        generator.generate(site)

        doc = site.collections["documents"].docs.first
        expect(doc.data["title"]).to match(/Board Meeting|Annual Report/)
        expect(doc.data["date"]).to be_a(Date)
      end

      it "sets category from folder name" do
        site = make_site("source" => temp_dir)
        generator.generate(site)

        doc = site.collections["documents"].docs.first
        expect(doc.data["category"]).to eq("referat")
      end

      it "generates slug from filename" do
        site = make_site("source" => temp_dir)
        generator.generate(site)

        doc = site.collections["documents"].docs.first
        expect(doc.data["slug"]).to match(/board-meeting|annual-report/i)
      end

      it "sets file_type metadata" do
        site = make_site("source" => temp_dir)
        generator.generate(site)

        pdf_doc = site.collections["documents"].docs.find { |d| d.data["extension"] == ".pdf" }
        expect(pdf_doc.data["file_type"]).to eq("pdf")
      end
    end
  end

  describe "#parse_filename" do
    it "parses valid YYYY-MM-DD_Title format" do
      date, title, valid = generator.send(:parse_filename, "2026-03-01_Board_Meeting")

      expect(valid).to be true
      expect(date).to eq(Date.new(2026, 3, 1))
      expect(title).to eq("Board Meeting")
    end

    it "handles underscores in title" do
      _, title, valid = generator.send(:parse_filename, "2026-03-01_Board_Meeting_Minutes")

      expect(valid).to be true
      expect(title).to eq("Board Meeting Minutes")
    end

    it "returns invalid for incorrect format" do
      date, title, valid = generator.send(:parse_filename, "InvalidFilename")

      expect(valid).to be false
      expect(date).to be_nil
      expect(title).to eq("InvalidFilename")
    end

    it "handles invalid dates gracefully" do
      date, _, valid = generator.send(:parse_filename, "2026-13-99_Invalid_Date")

      expect(valid).to be false
      expect(date).to be_nil
    end
  end

  describe "#build_slug" do
    before do
      generator.instance_variable_set(:@config, Jekyll::Documents::Configuration::DEFAULTS)
    end

    it "removes date prefix from filename" do
      slug = generator.send(:build_slug, "2026-03-01_Board_Meeting")
      expect(slug).to eq("board-meeting")
    end

    it "converts spaces to hyphens" do
      slug = generator.send(:build_slug, "Board Meeting Minutes")
      expect(slug).to eq("board-meeting-minutes")
    end

    it "removes special characters" do
      slug = generator.send(:build_slug, "Board@Meeting#2026!")
      expect(slug).to eq("boardmeeting2026")
    end

    it "handles Danish characters when enabled" do
      slug = generator.send(:build_slug, "Møde_om_Økonomi")
      expect(slug).to eq("moede-om-oekonomi")
    end

    it "removes leading and trailing hyphens" do
      slug = generator.send(:build_slug, "---Board-Meeting---")
      expect(slug).to eq("board-meeting")
    end

    it "returns 'untitled' for empty slug" do
      slug = generator.send(:build_slug, "---")
      expect(slug).to eq("untitled")
    end

    it "downcases when configured" do
      slug = generator.send(:build_slug, "BOARD_MEETING")
      expect(slug).to eq("board-meeting")
    end
  end

  describe "#infer_category_from" do
    before do
      generator.instance_variable_set(:@config, {
                                        "categories_from_path" => true,
                                        "root" => "assets/documents"
                                      })
    end

    it "extracts category from path" do
      category = generator.send(:infer_category_from, "assets/documents/referat/file.pdf")
      expect(category).to eq("referat")
    end

    it "handles nested paths" do
      category = generator.send(:infer_category_from, "assets/documents/board/meetings/file.pdf")
      expect(category).to eq("meetings")
    end

    it "returns uncategorized when disabled" do
      generator.instance_variable_set(:@config, { "categories_from_path" => false })
      category = generator.send(:infer_category_from, "assets/documents/referat/file.pdf")
      expect(category).to eq("uncategorized")
    end
  end

  describe "#remap_category" do
    before do
      generator.instance_variable_set(:@config, {
                                        "category_map" => { "referat" => "minutes" }
                                      })
    end

    it "remaps category when mapping exists" do
      result = generator.send(:remap_category, "referat")
      expect(result).to eq("minutes")
    end

    it "returns original category when no mapping" do
      result = generator.send(:remap_category, "invitation")
      expect(result).to eq("invitation")
    end

    it "downcases the result" do
      result = generator.send(:remap_category, "REFERAT")
      expect(result).to eq("referat")
    end
  end
end
