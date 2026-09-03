# frozen_string_literal: true

require "spec_helper"

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
      include_context "with temp documents directory"

      before do
        create_document("referat", "2026-03-01_Board_Meeting.pdf")
        create_document("referat", "2026-02-15_Annual_Report.docx")
      end

      it "creates documents collection" do
        site = site_with_documents
        generator.generate(site)

        expect(site.collections["documents"]).not_to be_nil
        expect(site.collections["documents"].docs.size).to eq(2)
      end

      it "configures collection for output" do
        site = site_with_documents
        generator.generate(site)

        expect(site.config["collections"]["documents"]["output"]).to be true
      end

      it "parses filename correctly" do
        site = site_with_documents
        generator.generate(site)

        doc = site.collections["documents"].docs.first
        expect(doc.data["title"]).to match(/Board Meeting|Annual Report/)
        expect(doc.data["date"]).to be_a(Time)
      end

      it "sets category from folder name" do
        site = site_with_documents
        generator.generate(site)

        doc = site.collections["documents"].docs.first
        expect(doc.data["category"]).to eq("referat")
      end

      it "generates slug from filename" do
        site = site_with_documents
        generator.generate(site)

        doc = site.collections["documents"].docs.first
        expect(doc.data["slug"]).to match(/board-meeting|annual-report/i)
      end

      it "sets file_type metadata" do
        site = site_with_documents
        generator.generate(site)

        pdf_doc = site.collections["documents"].docs.find { |d| d.data["extension"] == ".pdf" }
        expect(pdf_doc.data["file_type"]).to eq("pdf")
      end

      it "sets icon_url from configured icon set" do
        site = site_with_documents("documents" => { "icon_set" => "lines" })
        generator.generate(site)

        pdf_doc = site.collections["documents"].docs.find { |d| d.data["extension"] == ".pdf" }
        expect(pdf_doc.data["icon_url"]).to eq("/assets/icons/lines/pdf-file-type-svgrepo-com.svg")
      end

      it "sets icon_set on each document" do
        site = site_with_documents("documents" => { "icon_set" => "minimal" })
        generator.generate(site)

        doc = site.collections["documents"].docs.first
        expect(doc.data["icon_set"]).to eq("minimal")
      end

      it "sets permalink from configuration" do
        site = site_with_documents
        generator.generate(site)

        doc = site.collections["documents"].docs.first
        expect(doc.data["permalink"]).to include("/documents/")
        expect(doc.data["permalink"]).to include(doc.data["slug"])
        expect(doc.data["permalink"]).to include(doc.data["category"])
      end

      it "sets file_url to relative path" do
        site = site_with_documents
        generator.generate(site)

        doc = site.collections["documents"].docs.first
        expect(doc.data["file_url"]).to match(%r{^/assets/documents/})
      end

      it "sets layout from configuration" do
        site = site_with_documents
        generator.generate(site)

        doc = site.collections["documents"].docs.first
        expect(doc.data["layout"]).to eq("document")
      end

      it "sets extension metadata" do
        site = site_with_documents
        generator.generate(site)

        doc = site.collections["documents"].docs.find { |d| d.data["extension"] == ".docx" }
        expect(doc.data["extension"]).to eq(".docx")
        expect(doc.data["file_type"]).to eq("docx")
      end
    end

    context "with extract_text enabled" do
      include_context "with temp documents directory"

      let(:fake_resolver) { instance_double(Plaintext::Resolver) }

      before do
        create_document("referat", "2026-03-01_Board_Meeting.pdf")
        allow(Plaintext::Resolver).to receive(:new).and_return(fake_resolver)
        allow(fake_resolver).to receive(:text)
          .and_return("Extracted text from the PDF document about board meeting minutes.")
      end

      it "uses extracted text and searchable metadata as document content" do
        site = site_with_documents("documents" => { "extract_text" => true })
        generator.generate(site)

        doc = site.collections["documents"].docs.first
        expect(doc.content).to include("Extracted text from the PDF")
        expect(doc.content).to include("Board Meeting referat pdf")
      end

      it "truncates extracted text by UTF-8 bytes" do
        allow(fake_resolver).to receive(:text).and_return("åäöabc")
        site = site_with_documents("documents" => {
                                     "extract_text" => true, "text_max_bytes" => 5
                                   })

        generator.generate(site)

        extracted = generator.send(:truncate_bytes, "åäöabc", 5)
        expect(extracted).to eq("åä")
        expect(extracted.bytesize).to be <= 5
      end

      it "caches extracted text in the manifest" do
        site = site_with_documents("documents" => { "extract_text" => true })
        generator.generate(site)

        manifest = generator.send(:text_manifest)
        expect(manifest.size).to eq(1)
      end

      it "uses cached text on second build without re-extraction" do
        site = site_with_documents("documents" => { "extract_text" => true })
        generator.generate(site)

        # Second build — resolver should not be instantiated (cache hit)
        expect(Plaintext::Resolver).not_to receive(:new)

        generator2 = Jekyll::Documents::Generator.new
        generator2.generate(site)

        doc = site.collections["documents"].docs.last
        expect(doc.content).to include("Extracted text from the PDF")
      end

      it "falls back to metadata when extraction returns nil" do
        allow(fake_resolver).to receive(:text).and_return(nil)

        site = site_with_documents("documents" => { "extract_text" => true })
        generator.generate(site)

        doc = site.collections["documents"].docs.first
        expect(doc.content).to include("Board Meeting")
        expect(doc.content).to include("referat")
      end

      it "falls back to metadata when plaintext gem is not available" do
        hide_const("Plaintext")
        error = LoadError.new("cannot load such file -- plaintext")
        allow(generator).to receive(:require).with("plaintext").and_raise(error)

        site = site_with_documents("documents" => { "extract_text" => true })
        generator.generate(site)

        doc = site.collections["documents"].docs.first
        expect(doc.content).to include("Board Meeting")
        expect(doc.content).to include("referat")
      end

      it "loads plaintext gem via require when not yet defined" do
        hide_const("Plaintext")
        allow(generator).to receive(:require).with("plaintext").and_return(true)

        expect(generator.send(:load_plaintext)).to be true
      end

      it "falls back to metadata when extraction raises an error" do
        allow(fake_resolver).to receive(:text).and_raise("pdftotext not found")

        site = site_with_documents("documents" => { "extract_text" => true })
        generator.generate(site)

        doc = site.collections["documents"].docs.first
        expect(doc.content).to include("Board Meeting")
      end

      it "cleans up manifest entries for deleted documents" do
        create_document("referat", "2026-02-15_Annual_Report.docx")

        site = site_with_documents("documents" => { "extract_text" => true })
        generator.generate(site)

        manifest = generator.send(:text_manifest)
        expect(manifest.size).to eq(2)

        # Delete one file and rebuild
        docs = site.collections["documents"].docs
        deleted_path = docs.find { |d| d.data["title"] == "Annual Report" }.data["file_url"]
        deleted_rel = deleted_path.delete_prefix("/")
        File.delete(File.join(site.source, deleted_rel))

        generator2 = Jekyll::Documents::Generator.new
        generator2.generate(site)

        manifest2 = generator2.send(:text_manifest)
        expect(manifest2.size).to eq(1)
      end
    end

    context "with extract_text disabled (default)" do
      include_context "with temp documents directory"

      before do
        create_document("referat", "2026-03-01_Board_Meeting.pdf")
      end

      it "uses metadata-only content" do
        site = site_with_documents
        generator.generate(site)

        doc = site.collections["documents"].docs.first
        expect(doc.content).to include("Board Meeting")
        expect(doc.content).to include("referat")
        expect(doc.content).to include("pdf")
      end

      it "does not attempt text extraction" do
        site = site_with_documents
        allow(generator).to receive(:extract_file_content).and_call_original
        generator.generate(site)
        expect(generator).not_to have_received(:extract_file_content)
      end
    end

    context "with strict_extensions enabled" do
      include_context "with temp documents directory"

      it "aborts when encountering an unsupported file type" do
        create_document("referat", "2026-03-01_Valid.pdf")
        create_document("referat", "2026-03-02_Bad_File.exe")

        site = site_with_documents

        expect(Jekyll.logger).to receive(:abort_with)
          .with("jekyll-documents", /Unsupported file type.*\.exe/)

        generator.generate(site)
      end
    end

    context "with strict_extensions disabled" do
      include_context "with temp documents directory"

      it "skips unsupported file types without aborting" do
        create_document("referat", "2026-03-01_Valid.pdf")
        create_document("referat", "2026-03-02_Bad_File.exe")

        site = site_with_documents("documents" => { "strict_extensions" => false })
        generator.generate(site)

        docs = site.collections["documents"].docs
        expect(docs.size).to eq(1)
        expect(docs.first.data["extension"]).to eq(".pdf")
      end
    end

    context "with strict_filename enabled" do
      include_context "with temp documents directory"

      it "aborts when filename does not match YYYY-MM-DD_Title format" do
        create_document("referat", "InvalidFilename.pdf")

        site = site_with_documents

        expect(Jekyll.logger).to receive(:abort_with)
          .with("jekyll-documents", /Filename must be 'YYYY-MM-DD_Title\.ext'/)

        generator.generate(site)
      end
    end

    context "with strict_filename disabled" do
      include_context "with temp documents directory"

      it "processes files without date prefix" do
        create_document("referat", "Board_Meeting.pdf")

        site = site_with_documents("documents" => { "strict_filename" => false })
        generator.generate(site)

        doc = site.collections["documents"].docs.first
        expect(doc.data["title"]).to eq("Board Meeting")
        expect(doc.data["date"]).to be_a(Time)
      end
    end

    context "when called twice on the same site" do
      include_context "with temp documents directory"

      it "does not duplicate documents" do
        create_document("referat", "2026-03-01_Board_Meeting.pdf")

        site = site_with_documents
        generator.generate(site)
        initial_count = site.collections["documents"].docs.size

        generator.generate(site)
        expect(site.collections["documents"].docs.size).to eq(initial_count * 2)
      end

      it "reuses the same collection object" do
        create_document("referat", "2026-03-01_Board_Meeting.pdf")

        site = site_with_documents
        generator.generate(site)
        collection = site.collections["documents"]

        generator.generate(site)
        expect(site.collections["documents"]).to be(collection)
      end
    end
  end

  describe "#ensure_collection" do
    it "creates a new collection when it does not exist" do
      generator.instance_variable_set(:@config, Jekyll::Documents::Configuration::DEFAULTS)
      site = make_site

      collection = generator.send(:ensure_collection, site, "documents")

      expect(collection).to be_a(Jekyll::Collection)
      expect(site.collections["documents"]).to be(collection)
      expect(site.config["collections"]["documents"]["output"]).to be true
    end

    it "returns existing collection without creating a new one" do
      generator.instance_variable_set(:@config, Jekyll::Documents::Configuration::DEFAULTS)
      site = make_site
      existing = Jekyll::Collection.new(site, "documents")
      site.collections["documents"] = existing

      result = generator.send(:ensure_collection, site, "documents")

      expect(result).to be(existing)
    end
  end

  describe "#source_stub_for" do
    it "creates a virtual source path with category and basename" do
      generator.instance_variable_set(:@config, Jekyll::Documents::Configuration::DEFAULTS)

      path = generator.send(:source_stub_for, "2026-03-01_Board_Meeting", "referat")

      expect(path).to eq("_documents/referat-2026-03-01_Board_Meeting.md")
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

    it "handles empty string" do
      date, title, valid = generator.send(:parse_filename, "")

      expect(valid).to be false
      expect(date).to be_nil
      expect(title).to eq("")
    end

    it "handles date prefix with no title" do
      date, title, valid = generator.send(:parse_filename, "2026-03-01_")

      expect(valid).to be false
      expect(date).to be_nil
      expect(title).to eq("2026-03-01 ")
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

    it "preserves case when downcase disabled" do
      defaults = Jekyll::Documents::Configuration::DEFAULTS
      generator.instance_variable_set(:@config,
                                      defaults.merge("slug_downcase" => false))
      slug = generator.send(:build_slug, "Board_Meeting")
      expect(slug).to eq("Board-Meeting")
    end

    it "preserves Danish characters when mapping disabled" do
      defaults = Jekyll::Documents::Configuration::DEFAULTS
      generator.instance_variable_set(:@config,
                                      defaults.merge("slug_danish_map" => false))
      slug = generator.send(:build_slug, "Møde_om_Økonomi")
      expect(slug).to eq("møde-om-økonomi")
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

    it "returns uncategorized for file directly in root" do
      category = generator.send(:infer_category_from, "assets/documents/file.pdf")
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

    it "handles empty category_map" do
      generator.instance_variable_set(:@config, { "category_map" => {} })
      result = generator.send(:remap_category, "referat")
      expect(result).to eq("referat")
    end

    it "handles nil category_map" do
      generator.instance_variable_set(:@config, { "category_map" => nil })
      result = generator.send(:remap_category, "referat")
      expect(result).to eq("referat")
    end
  end

  describe "#configure_client_search" do
    it "injects passthrough_fields and icon_field when documents is in search collections" do
      site = make_site("client_search" => { "collections" => %w[posts documents] })
      generator.send(:configure_client_search, site)

      config = site.config["client_search"]
      expect(config["passthrough_fields"]).to include("file_type", "icon_url", "icon_set")
      expect(config["icon_field"]).to eq("icon_url")
    end

    it "does nothing when client_search is not configured" do
      site = make_site
      expect { generator.send(:configure_client_search, site) }.not_to raise_error
      expect(site.config["client_search"]).to be_nil
    end

    it "does nothing when documents is not in search collections" do
      site = make_site("client_search" => { "collections" => %w[posts] })
      generator.send(:configure_client_search, site)

      expect(site.config["client_search"]).not_to have_key("passthrough_fields")
    end

    it "preserves existing passthrough_fields and adds missing ones" do
      site = make_site("client_search" => {
                         "collections" => %w[posts documents],
                         "passthrough_fields" => ["file_type", { "author" => "creator" }]
                       })
      generator.send(:configure_client_search, site)

      fields = site.config["client_search"]["passthrough_fields"]
      expect(fields).to include("file_type", { "author" => "creator" }, "icon_url", "icon_set")
    end

    it "does not overwrite an existing icon_field" do
      site = make_site("client_search" => {
                         "collections" => %w[posts documents],
                         "icon_field" => "thumbnail"
                       })
      generator.send(:configure_client_search, site)

      expect(site.config["client_search"]["icon_field"]).to eq("thumbnail")
    end
  end
end
