# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jekyll::Documents::Configuration do
  describe ".read" do
    it "returns default configuration when no config provided" do
      site = make_site
      config = described_class.read(site)

      expect(config["root"]).to eq("assets/documents")
      expect(config["permalink"]).to eq("/documents/:category/:slug/")
      expect(config["slug_downcase"]).to be true
      expect(config["slug_danish_map"]).to be true
      expect(config["categories_from_path"]).to be true
      expect(config["strict_filename"]).to be true
      expect(config["strict_extensions"]).to be true
      expect(config["json_index"]).to be true
      expect(config["layout"]).to eq("document")
      expect(config["latest_default_count"]).to eq(5)
    end

    it "merges user configuration with defaults" do
      site = make_site("documents" => {
        "root" => "custom/path",
        "strict_filename" => false,
        "latest_default_count" => 10
      })
      config = described_class.read(site)

      expect(config["root"]).to eq("custom/path")
      expect(config["strict_filename"]).to be false
      expect(config["latest_default_count"]).to eq(10)
      expect(config["slug_downcase"]).to be true # still has default
    end

    it "includes all expected extensions" do
      site = make_site
      config = described_class.read(site)

      expect(config["include_extensions"]).to include(".pdf", ".docx", ".pptx", ".xlsx")
      expect(config["include_extensions"]).to include(".odt", ".ods", ".odp")
    end

    it "includes empty category_map by default" do
      site = make_site
      config = described_class.read(site)

      expect(config["category_map"]).to eq({})
    end
  end
end
