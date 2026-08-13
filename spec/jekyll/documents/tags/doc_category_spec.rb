# frozen_string_literal: true

require "spec_helper"
require "liquid"

RSpec.describe Jekyll::Documents::DocCategoryTag do
  let(:tag_class) { described_class }
  let(:site) { make_site }
  let(:context) { Liquid::Context.new({}, {}, { site: site }) }

  def create_tag(markup = "")
    tag_class.new("doc_category", markup, Liquid::Tokenizer.new(""))
  end

  def render_tag(markup, site_override = nil)
    ctx = Liquid::Context.new({}, {}, { site: site_override || site })
    tag = create_tag(markup)
    tag.render(ctx)
  end

  describe "#initialize" do
    it "parses a quoted category" do
      tag = create_tag(%("skibladet"))
      expect(tag).to be_a(described_class)
    end

    it "parses a bare word category" do
      tag = create_tag("referat")
      expect(tag).to be_a(described_class)
    end

    it "parses category with options" do
      tag = create_tag(%("skibladet" text:"All skiblad" list:true limit:5))
      expect(tag).to be_a(described_class)
    end
  end

  describe "#render — link mode" do
    include_context "with temp documents directory"

    before do
      create_document("referat", "2026-03-01_Board_Meeting.pdf")
      create_document("referat", "2026-02-15_Annual_Report.pdf")
      create_document("skibladet", "2026-01-01_Skiblad_nr_60.pdf")
      @site = site_with_documents
      generate_documents(@site)
    end

    it "renders an anchor tag with the category URL" do
      result = render_tag(%("referat"), @site)
      expect(result).to start_with("<a href=")
      expect(result).to include('href="/documents/referat/"')
      expect(result).to include(">referat</a>")
    end

    it "matches category case-insensitively" do
      result = render_tag(%("REFERAT"), @site)
      expect(result).to include('href="/documents/referat/"')
    end

    it "matches by partial category name" do
      result = render_tag(%("skib"), @site)
      expect(result).to include('href="/documents/skibladet/"')
    end

    it "uses custom text when provided" do
      result = render_tag(%("referat" text:"Referater"), @site)
      expect(result).to include(">Referater</a>")
    end

    it "applies the site baseurl" do
      site = site_with_documents("baseurl" => "/site")
      generate_documents(site)
      result = render_tag(%("referat"), site)
      expect(result).to include('href="/site/documents/referat/"')
    end

    it "returns empty string when no match found" do
      result = render_tag(%("nonexistent"), @site)
      expect(result).to eq("")
    end

    it "returns empty string when documents collection is empty" do
      empty_site = make_site
      result = render_tag(%("anything"), empty_site)
      expect(result).to eq("")
    end
  end

  describe "#render — list mode" do
    include_context "with temp documents directory"

    before do
      create_document("referat", "2026-03-01_Board_Meeting.pdf")
      create_document("referat", "2026-02-15_Annual_Report.pdf")
      create_document("referat", "2026-01-10_Old_Doc.pdf")
      create_document("skibladet", "2026-01-01_Skiblad_nr_60.pdf")
      @site = site_with_documents
      generate_documents(@site)
    end

    it "renders a ul with doc-category-list class" do
      result = render_tag(%("referat" list:true), @site)
      expect(result).to start_with(%(<ul class="doc-category-list"))
      expect(result).to end_with("</ul>\n")
    end

    it "lists all documents in the category sorted by date descending" do
      result = render_tag(%("referat" list:true), @site)
      expect(result).to include("Board Meeting")
      expect(result).to include("Annual Report")
      expect(result).to include("Old Doc")
      # Board Meeting (2026-03-01) should come before Annual Report (2026-02-15)
      expect(result.index("Board Meeting")).to be < result.index("Annual Report")
    end

    it "respects the limit option" do
      result = render_tag(%("referat" list:true limit:2), @site)
      expect(result).to include("Board Meeting")
      expect(result).to include("Annual Report")
      expect(result).not_to include("Old Doc")
    end

    it "includes dates in list items" do
      result = render_tag(%("referat" list:true), @site)
      expect(result).to include("2026-03-01")
      expect(result).to include("2026-02-15")
    end

    it "only lists documents from the specified category" do
      result = render_tag(%("skibladet" list:true), @site)
      expect(result).to include("Skiblad nr 60")
      expect(result).not_to include("Board Meeting")
    end
  end
end
