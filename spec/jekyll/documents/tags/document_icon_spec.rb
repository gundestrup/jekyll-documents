# frozen_string_literal: true

require "spec_helper"
require "liquid"

RSpec.describe Jekyll::Documents::DocumentIconTag do
  def render_tag(markup, variables = {}, config = {})
    site = make_site(config)
    context = Liquid::Context.new(variables, {}, { site: site })
    described_class.new("document_icon", markup, Liquid::Tokenizer.new("")).render(context)
  end

  let(:document) do
    {
      "icon_url" => "/assets/icons/color/pdf-document-svgrepo-com.svg",
      "file_type" => "pdf"
    }
  end

  it "renders an icon from a document's baked icon URL" do
    result = render_tag("page", "page" => document)

    expect(result).to eq(
      '<img src="/assets/icons/color/pdf-document-svgrepo-com.svg" ' \
      'alt="PDF file" class="document-file-icon" ' \
      'style="width:1em;height:1em;vertical-align:middle;" />'
    )
  end

  it "applies the site baseurl" do
    result = render_tag("page", { "page" => { "icon_url" => "/assets/icons/test.svg",
                                              "file_type" => "pdf" } },
                        "baseurl" => "/docs")

    expect(result).to include('src="/docs/assets/icons/test.svg"')
  end

  it "supports custom class and alt text" do
    result = render_tag("page class:icon alt:'PDF document'", "page" => {
                          "icon_url" => "/assets/icons/test.svg",
                          "file_type" => "pdf"
                        })

    expect(result).to eq(
      '<img src="/assets/icons/test.svg" alt="PDF document" class="icon" ' \
      'style="width:1em;height:1em;vertical-align:middle;" />'
    )
  end

  it "falls back to the configured icon set when icon URL is absent" do
    result = render_tag("page", { "page" => { "file_type" => "pdf" } },
                        "documents" => { "icon_set" => "lines" })

    expect(result).to include('src="/assets/icons/lines/pdf-file-type-svgrepo-com.svg"')
  end

  it "escapes generated attributes" do
    result = render_tag("page alt:'A & B' class:'icon\"large'", "page" => {
                          "icon_url" => "/assets/icons/test.svg",
                          "file_type" => "pdf"
                        })

    expect(result).to include('alt="A &amp; B"')
    expect(result).to include('class="icon&quot;large"')
  end

  it "returns an empty string when the document is missing" do
    expect(render_tag("missing")).to eq("")
  end

  it "falls back to unknown icon when document has no data or [] access" do
    bare = Class.new do
      def to_liquid = self
    end.new
    result = render_tag("page", "page" => bare)
    expect(result).to include("unknown-document")
  end
end
