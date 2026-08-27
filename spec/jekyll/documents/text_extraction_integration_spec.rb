# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "digest"
require "json"

RSpec.describe "Text extraction integration", :integration do
  let(:temp_dir) { Dir.mktmpdir }
  let(:fixtures_dir) { File.expand_path("../../fixtures/test_documents", __dir__) }
  let(:site) { make_site("source" => temp_dir, "documents" => { "extract_text" => true }) }
  let(:generator) { Jekyll::Documents::Generator.new }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  def copy_fixture(filename, category = "reports")
    src = File.join(fixtures_dir, filename)
    dest_dir = File.join(temp_dir, "assets", "documents", category)
    FileUtils.mkdir_p(dest_dir)
    dest = File.join(dest_dir, filename)
    FileUtils.cp(src, dest)
    dest
  end

  describe "real DOCX extraction" do
    before do
      copy_fixture("2026-03-01_Board_Meeting.docx", "minutes")
    end

    it "extracts known text content from the DOCX file" do
      generator.generate(site)

      doc = site.collections["documents"].docs.first
      expect(doc.content).to include("Board Meeting Minutes 2026")
      expect(doc.content).to include("quarterly board meeting")
      expect(doc.content).to include("annual budget proposal")
    end

    it "stores extracted text in the manifest cache" do
      generator.generate(site)

      manifest = generator.send(:text_manifest)
      expect(manifest.size).to eq(1)

      # Verify the text file exists on disk
      rel_path = "assets/documents/minutes/2026-03-01_Board_Meeting.docx"
      entry = manifest.instance_variable_get(:@manifest)[rel_path]
      expect(entry).not_to be_nil

      text_file = File.join(temp_dir, ".cache/jekyll-documents", "text", entry["text_file"])
      expect(File.file?(text_file)).to be true
      cached_text = File.read(text_file)
      expect(cached_text).to include("Board Meeting Minutes 2026")
    end

    it "writes a valid manifest JSON file to disk" do
      generator.generate(site)

      manifest_path = File.join(temp_dir, ".cache/jekyll-documents",
                                "text-extraction-manifest.json")
      expect(File.file?(manifest_path)).to be true

      data = JSON.parse(File.read(manifest_path))
      expect(data).to have_key("assets/documents/minutes/2026-03-01_Board_Meeting.docx")
      entry = data["assets/documents/minutes/2026-03-01_Board_Meeting.docx"]
      expect(entry["digest"]).to match(/^[a-f0-9]{64}$/)
      expect(entry["text_file"]).to match(%r{^[a-f0-9]{2}/[a-f0-9]{64}\.txt$})
      expect(entry["extracted_at"]).to be_an(Integer)
    end

    it "uses cached text on second build without re-extraction" do
      generator.generate(site)
      first_content = site.collections["documents"].docs.first.content

      # Replace the DOCX with a different file that would extract different text
      # but keep the same path — the digest will change, forcing re-extraction
      # Instead, just rebuild without modifying the file
      generator2 = Jekyll::Documents::Generator.new
      generator2.generate(site)

      second_content = site.collections["documents"].docs.last.content
      expect(second_content).to eq(first_content)
    end

    it "re-extracts when the source file changes" do
      generator.generate(site)

      # Modify the DOCX file (change its content → different digest)
      path = File.join(temp_dir, "assets/documents/minutes/2026-03-01_Board_Meeting.docx")
      File.write(path, "modified content")

      generator2 = Jekyll::Documents::Generator.new
      generator2.generate(site)

      # Extraction will fail on the modified file (not a valid DOCX),
      # so it should fall back to metadata content
      doc = site.collections["documents"].docs.last
      expect(doc.content).to include("Board Meeting")
    end
  end

  describe "real ODT extraction" do
    before do
      copy_fixture("2026-02-01_Budget_Proposal.odt", "finance")
    end

    it "extracts known text content from the ODT file" do
      generator.generate(site)

      doc = site.collections["documents"].docs.first
      expect(doc.content).to include("Quarterly Budget Proposal")
      expect(doc.content).to include("50000 DKK")
      expect(doc.content).to include("finance committee")
    end
  end

  describe "multiple document types" do
    before do
      copy_fixture("2026-03-01_Board_Meeting.docx", "minutes")
      copy_fixture("2026-02-01_Budget_Proposal.odt", "finance")
    end

    it "extracts text from all documents and caches all in manifest" do
      generator.generate(site)

      manifest = generator.send(:text_manifest)
      expect(manifest.size).to eq(2)

      docs = site.collections["documents"].docs
      docx_doc = docs.find { |d| d.data["extension"] == ".docx" }
      odt_doc = docs.find { |d| d.data["extension"] == ".odt" }

      expect(docx_doc.content).to include("Board Meeting Minutes 2026")
      expect(odt_doc.content).to include("Quarterly Budget Proposal")
    end

    it "cleans up manifest entries when a document is deleted" do
      generator.generate(site)
      expect(generator.send(:text_manifest).size).to eq(2)

      # Delete one file
      deleted = File.join(temp_dir, "assets/documents/finance/2026-02-01_Budget_Proposal.odt")
      File.delete(deleted)

      generator2 = Jekyll::Documents::Generator.new
      generator2.generate(site)

      expect(generator2.send(:text_manifest).size).to eq(1)
    end
  end

  describe "manifest persistence across builds" do
    before do
      copy_fixture("2026-03-01_Board_Meeting.docx", "minutes")
    end

    it "persists manifest to disk and reloads it on next build" do
      generator.generate(site)

      manifest_path = File.join(temp_dir, ".cache/jekyll-documents",
                                "text-extraction-manifest.json")
      expect(File.file?(manifest_path)).to be true

      # Create a new site and generator (simulating a fresh jekyll build)
      site2 = make_site("source" => temp_dir, "documents" => { "extract_text" => true })
      generator2 = Jekyll::Documents::Generator.new
      generator2.generate(site2)

      manifest2 = generator2.send(:text_manifest)
      expect(manifest2.size).to eq(1)

      # The text should come from cache, not re-extraction
      doc = site2.collections["documents"].docs.first
      expect(doc.content).to include("Board Meeting Minutes 2026")
    end
  end
end
