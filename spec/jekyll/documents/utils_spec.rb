# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe Jekyll::Documents::TextStaticFile do
  let(:site) { make_site }
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#initialize" do
    it "creates a TextStaticFile with content" do
      file = described_class.new(site, site.source, "/test.json", '{"test": true}')

      expect(file.instance_variable_get(:@content)).to eq('{"test": true}')
      expect(file.instance_variable_get(:@name)).to eq("test.json")
      expect(file.instance_variable_get(:@dir)).to eq("/")
    end

    it "handles nested paths" do
      file = described_class.new(site, site.source, "/path/to/test.json", "content")

      expect(file.instance_variable_get(:@dir)).to eq("/path/to")
      expect(file.instance_variable_get(:@name)).to eq("test.json")
    end
  end

  describe "#write" do
    it "writes content to destination" do
      file = described_class.new(site, site.source, "/test.json", '{"test": true}')

      result = file.write(temp_dir)

      expect(result).to be true
      # Jekyll's destination method includes the @dir in the path
      written_file = file.destination(temp_dir)
      expect(File.exist?(written_file)).to be true
      expect(File.read(written_file)).to eq('{"test": true}')
    end

    it "creates parent directories if needed" do
      file = described_class.new(site, site.source, "/nested/path/test.json", "content")

      result = file.write(temp_dir)

      expect(result).to be true
      written_file = file.destination(temp_dir)
      expect(File.exist?(written_file)).to be true
    end

    it "returns false on write error" do
      file = described_class.new(site, site.source, "/test.json", "content")

      # Make destination unwritable
      allow(File).to receive(:write).and_raise(Errno::EACCES)
      expect(Jekyll.logger).to receive(:error).with("jekyll-documents", /Failed to write/)

      result = file.write(temp_dir)

      expect(result).to be false
    end

    it "logs error message on failure" do
      file = described_class.new(site, site.source, "/test.json", "content")

      allow(File).to receive(:write).and_raise(StandardError.new("Test error"))
      expect(Jekyll.logger).to receive(:error).with("jekyll-documents", /Test error/)

      file.write(temp_dir)
    end
  end
end
