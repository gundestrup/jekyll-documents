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

    it "prefers a unique exact match over partial matches" do
      create_document("report", "2026-01-01_Exact.pdf")
      create_document("annual-report", "2026-01-01_Annual.pdf")
      site = site_with_documents
      generate_documents(site)

      result = render_tag(%("report"), site)

      expect(result).to include('href="/documents/report/"')
    end

    it "logs a warning and renders nothing for ambiguous partial matches" do
      create_document("annual-reports", "2026-01-01_Annual.pdf")
      create_document("board-reports", "2026-01-01_Board.pdf")
      site = site_with_documents
      generate_documents(site)

      expect(Jekyll.logger).to receive(:warn)
        .with("jekyll-documents", /Ambiguous doc_category.*reports.*annual-reports.*board-reports/)

      expect(render_tag(%("reports"), site)).to eq("")
    end

    it "aborts with all matching categories in strict resolution mode" do
      create_document("annual-reports", "2026-01-01_Annual.pdf")
      create_document("board-reports", "2026-01-01_Board.pdf")
      site = site_with_documents("documents" => { "resolution_mode" => "strict" })
      generate_documents(site)

      expect(Jekyll.logger).to receive(:abort_with)
        .with("jekyll-documents", /Ambiguous doc_category.*annual-reports.*board-reports/)
        .and_call_original

      expect { render_tag(%("reports"), site) }.to raise_error(SystemExit)
    end

    it "resolves an exact hierarchical category path" do
      create_document("Departments/Europe/Research", "2026-01-01_Europe.pdf")
      site = site_with_documents
      generate_documents(site)

      result = render_tag(
        %(path:"Departments/Europe/Research" text:"European Research"), site
      )

      expect(result).to include('href="/documents/research/"')
      expect(result).to include(">European Research</a>")
    end

    it "resolves the uncategorized root category path" do
      create_document_at_root("2026-01-01_Root.pdf")
      site = site_with_documents
      generate_documents(site)

      result = render_tag(%(path:"uncategorized"), site)

      expect(result).to include('href="/documents/uncategorized/"')
    end

    it "normalizes separators for exact category path resolution" do
      create_document("Departments/Europe/Research", "2026-01-01_Europe.pdf")
      site = site_with_documents
      generate_documents(site)

      result = render_tag(%(path:"Departments\\Europe\\Research"), site)

      expect(result).to include('href="/documents/research/"')
    end

    it "logs an unknown category path and renders nothing" do
      expect(Jekyll.logger).to receive(:warn)
        .with("jekyll-documents", %r{Unknown doc_category path.*Missing/Research})

      expect(render_tag(%(path:"Missing/Research"), @site)).to eq("")
    end

    it "reports repeated short category names from different paths" do
      create_document("Departments/Europe/Research", "2026-01-01_Europe.pdf")
      create_document("Departments/America/Research", "2026-01-01_America.pdf")
      site = site_with_documents
      generate_documents(site)

      expect(Jekyll.logger).to receive(:warn)
        .with("jekyll-documents", %r{Ambiguous doc_category.*Departments/America/Research.*Europe})

      expect(render_tag(%("research"), site)).to eq("")
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

    it "lists only documents from an exact category path" do
      create_document("Departments/Europe/Research", "2026-04-01_Europe_New.pdf")
      create_document("Departments/Europe/Research", "2026-01-01_Europe_Old.pdf")
      create_document("Departments/America/Research", "2026-03-01_America.pdf")
      site = site_with_documents
      generate_documents(site)

      result = render_tag(
        %(path:"Departments/Europe/Research" list:true limit:1), site
      )

      expect(result).to include("Europe New")
      expect(result).not_to include("Europe Old")
      expect(result).not_to include("America")
    end

    it "aggregates repeated short categories explicitly" do
      create_document("Departments/Europe/Research", "2026-01-01_Europe.pdf")
      create_document("Departments/America/Research", "2026-02-01_America.pdf")
      site = site_with_documents
      generate_documents(site)

      result = render_tag(%("research" aggregate:true list:true), site)

      expect(result).to include("Europe")
      expect(result).to include("America")
    end
  end
end
