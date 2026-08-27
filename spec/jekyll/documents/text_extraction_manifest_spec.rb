# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "digest"

RSpec.describe Jekyll::Documents::TextExtractionManifest do
  let(:temp_dir) { Dir.mktmpdir }
  let(:site) { make_site("source" => temp_dir) }
  let(:cache_dir) { ".cache/jekyll-documents" }
  let(:manifest) { described_class.new(site, cache_dir) }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  def make_source_file(rel_path, content = "fake pdf content")
    path = File.join(temp_dir, rel_path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  def digest_of(content)
    Digest::SHA256.hexdigest(content)
  end

  describe "#initialize" do
    it "creates a new empty manifest when no cache exists" do
      expect(manifest.size).to eq(0)
    end

    it "loads existing manifest from disk" do
      make_source_file("test.pdf", "content")
      digest = digest_of("content")
      manifest.set("test.pdf", digest, "extracted text")
      manifest.save

      reloaded = described_class.new(site, cache_dir)
      expect(reloaded.size).to eq(1)
      expect(reloaded.cached?("test.pdf", digest)).to be true
    end

    it "handles corrupt manifest gracefully" do
      FileUtils.mkdir_p(File.join(temp_dir, cache_dir))
      File.write(manifest.manifest_path, "{ invalid json }")
      reloaded = described_class.new(site, cache_dir)
      expect(reloaded.size).to eq(0)
    end
  end

  describe "#set and #get" do
    it "stores and retrieves text by path and digest" do
      content = "PDF content here"
      make_source_file("docs/report.pdf", content)
      digest = digest_of(content)

      manifest.set("docs/report.pdf", digest, "Extracted report text")
      result = manifest.get("docs/report.pdf", digest)

      expect(result).to eq("Extracted report text")
    end

    it "returns nil when digest does not match" do
      make_source_file("docs/report.pdf", "content")
      manifest.set("docs/report.pdf", digest_of("content"), "text")

      result = manifest.get("docs/report.pdf", "different_digest")
      expect(result).to be_nil
    end

    it "returns nil when path is not in manifest" do
      result = manifest.get("nonexistent.pdf", "any_digest")
      expect(result).to be_nil
    end

    it "stores text in a sharded directory structure" do
      content = "content"
      make_source_file("test.pdf", content)
      digest = digest_of(content)

      manifest.set("test.pdf", digest, "text")
      manifest.save

      shard = digest[0, 2]
      text_path = File.join(temp_dir, cache_dir, "text", shard, "#{digest}.txt")
      expect(File.file?(text_path)).to be true
      expect(File.read(text_path)).to eq("text")
    end

    it "overwrites previous entry when set is called again" do
      make_source_file("test.pdf", "content")
      digest = digest_of("content")

      manifest.set("test.pdf", digest, "first text")
      manifest.set("test.pdf", digest, "second text")

      expect(manifest.get("test.pdf", digest)).to eq("second text")
    end
  end

  describe "#cached?" do
    it "returns true when path and digest match" do
      make_source_file("test.pdf", "content")
      digest = digest_of("content")
      manifest.set("test.pdf", digest, "text")

      expect(manifest.cached?("test.pdf", digest)).to be true
    end

    it "returns false when digest does not match" do
      make_source_file("test.pdf", "content")
      manifest.set("test.pdf", digest_of("content"), "text")

      expect(manifest.cached?("test.pdf", "wrong")).to be false
    end

    it "returns false when path is not in manifest" do
      expect(manifest.cached?("missing.pdf", "any")).to be false
    end
  end

  describe "#cleanup_deleted" do
    it "removes entries for deleted source files" do
      make_source_file("keep.pdf", "keep content")
      make_source_file("delete.pdf", "delete content")

      keep_digest = digest_of("keep content")
      delete_digest = digest_of("delete content")

      manifest.set("keep.pdf", keep_digest, "keep text")
      manifest.set("delete.pdf", delete_digest, "delete text")
      manifest.save

      removed = manifest.cleanup_deleted(["keep.pdf"])
      manifest.save

      expect(removed).to eq(1)
      expect(manifest.cached?("keep.pdf", keep_digest)).to be true
      expect(manifest.cached?("delete.pdf", delete_digest)).to be false
    end

    it "deletes the text file for removed entries" do
      make_source_file("delete.pdf", "content")
      digest = digest_of("content")

      manifest.set("delete.pdf", digest, "text")
      manifest.save

      shard = digest[0, 2]
      text_path = File.join(temp_dir, cache_dir, "text", shard, "#{digest}.txt")
      expect(File.file?(text_path)).to be true

      manifest.cleanup_deleted([])
      manifest.save

      expect(File.file?(text_path)).to be false
    end

    it "returns 0 when no entries need removal" do
      make_source_file("keep.pdf", "content")
      manifest.set("keep.pdf", digest_of("content"), "text")

      removed = manifest.cleanup_deleted(["keep.pdf"])
      expect(removed).to eq(0)
    end

    it "handles empty manifest" do
      removed = manifest.cleanup_deleted(["some.pdf"])
      expect(removed).to eq(0)
    end
  end

  describe "#save" do
    it "writes manifest to disk as JSON" do
      make_source_file("test.pdf", "content")
      manifest.set("test.pdf", digest_of("content"), "text")
      manifest.save

      expect(File.file?(manifest.manifest_path)).to be true
      data = JSON.parse(File.read(manifest.manifest_path))
      expect(data["test.pdf"]["digest"]).to eq(digest_of("content"))
    end

    it "does not write when nothing changed" do
      make_source_file("test.pdf", "content")
      manifest.set("test.pdf", digest_of("content"), "text")
      manifest.save

      mtime = File.mtime(manifest.manifest_path)
      sleep 0.01
      manifest.save
      expect(File.mtime(manifest.manifest_path)).to eq(mtime)
    end

    it "persists across instances" do
      make_source_file("test.pdf", "content")
      digest = digest_of("content")

      manifest.set("test.pdf", digest, "persisted text")
      manifest.save

      reloaded = described_class.new(site, cache_dir)
      expect(reloaded.get("test.pdf", digest)).to eq("persisted text")
    end
  end

  describe "#size" do
    it "returns the number of entries" do
      make_source_file("a.pdf", "a")
      make_source_file("b.pdf", "b")

      manifest.set("a.pdf", digest_of("a"), "text a")
      manifest.set("b.pdf", digest_of("b"), "text b")

      expect(manifest.size).to eq(2)
    end
  end

  describe "error handling" do
    it "returns nil and logs warning when text file read fails" do
      make_source_file("test.pdf", "content")
      digest = digest_of("content")
      manifest.set("test.pdf", digest, "text")

      # Stub File.read to raise an error for the text file path
      entry = manifest.instance_variable_get(:@manifest)["test.pdf"]
      text_path = File.join(temp_dir, cache_dir, "text", entry["text_file"])

      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(text_path, encoding: "UTF-8")
                                   .and_raise(Errno::EACCES, "Permission denied")

      result = manifest.get("test.pdf", digest)
      expect(result).to be_nil
    end

    it "returns empty hash when manifest file raises non-JSON error on read" do
      FileUtils.mkdir_p(File.join(temp_dir, cache_dir))
      manifest_path = File.join(temp_dir, cache_dir, "text-extraction-manifest.json")
      # Write a valid file so File.file? returns true, but stub read to raise
      File.write(manifest_path, "{}")
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(manifest_path, encoding: "UTF-8")
                                   .and_raise(Errno::EIO, "Input/output error")

      reloaded = described_class.new(site, cache_dir)
      expect(reloaded.size).to eq(0)
    end

    it "handles delete_text_file failure gracefully" do
      make_source_file("delete.pdf", "content")
      digest = digest_of("content")

      manifest.set("delete.pdf", digest, "text")

      # Stub File.delete to raise an error for the text file
      entry = manifest.instance_variable_get(:@manifest)["delete.pdf"]
      text_path = File.join(temp_dir, cache_dir, "text", entry["text_file"])

      allow(File).to receive(:delete).and_call_original
      allow(File).to receive(:delete).with(text_path)
                                     .and_raise(Errno::EACCES, "Permission denied")

      # cleanup_deleted should not raise even though delete fails
      removed = manifest.cleanup_deleted([])
      expect(removed).to eq(1)
    end
  end
end
