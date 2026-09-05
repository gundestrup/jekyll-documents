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
      expect(config["resolution_mode"]).to eq("warn")
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

    it "handles missing documents key in site config" do
      site = make_site
      allow(site).to receive(:config).and_return({})

      config = described_class.read(site)

      expect(config["root"]).to eq("assets/documents")
      expect(config["slug_downcase"]).to be true
    end

    it "handles nil documents config value" do
      site = make_site
      allow(site).to receive(:config).and_return("documents" => nil)

      config = described_class.read(site)

      expect(config["root"]).to eq("assets/documents")
    end

    it "merges icon_set from user config" do
      site = make_site("documents" => { "icon_set" => "lines" })
      config = described_class.read(site)

      expect(config["icon_set"]).to eq("lines")
    end

    it "merges strict resolution mode from user config" do
      site = make_site("documents" => { "resolution_mode" => "strict" })
      config = described_class.read(site)

      expect(config["resolution_mode"]).to eq("strict")
    end

    it "aborts for an unsupported resolution mode" do
      site = make_site
      allow(site).to receive(:config)
        .and_return("documents" => { "resolution_mode" => "silent" })

      expect(Jekyll.logger).to receive(:abort_with)
        .with("jekyll-documents", /resolution_mode.*warn.*strict/).and_call_original

      expect { described_class.read(site) }.to raise_error(SystemExit)
    end

    it "preserves all default keys when user config provides subset" do
      site = make_site("documents" => { "root" => "custom" })
      config = described_class.read(site)

      expect(config.keys).to include("root", "permalink", "slug_downcase", "slug_danish_map",
                                     "categories_from_path", "include_extensions", "layout",
                                     "latest_default_count", "icon_set", "strict_filename",
                                     "strict_extensions", "resolution_mode", "json_index",
                                     "json_index_path", "category_map")
    end
  end
end
