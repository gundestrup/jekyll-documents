# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jekyll::Documents::AssetsGenerator do
  let(:site) { make_site }
  let(:generator) { described_class.new }

  it "registers packaged icons and JavaScript as static files" do
    generator.generate(site)

    expect(site.data["jekyll_documents"]).to eq(
      "json_index" => true,
      "json_index_path" => "/documents.json"
    )

    paths = site.static_files.map(&:relative_path)
    expect(paths).to include(
      "assets/icons/color/pdf-document-svgrepo-com.svg",
      "assets/icons/lines/pdf-file-type-svgrepo-com.svg",
      "assets/icons/minimal/extension-file-format-pdf-document-file-format-svgrepo-com.svg",
      "assets/js/documents-search.js"
    )
  end

  it "uses a configured JSON index path" do
    site = make_site("documents" => { "json_index_path" => "/search/documents.json" })

    generator.generate(site)

    expect(site.data["jekyll_documents"]).to eq(
      "json_index" => true,
      "json_index_path" => "/search/documents.json"
    )
  end

  it "exposes when the JSON index is disabled" do
    site = make_site("documents" => { "json_index" => false })

    generator.generate(site)

    expect(site.data["jekyll_documents"]["json_index"]).to be false
  end

  it "does not register the same asset more than once" do
    generator.generate(site)
    generator.generate(site)

    paths = site.static_files.map(&:relative_path)
    expect(paths.uniq).to eq(paths)
  end
end
