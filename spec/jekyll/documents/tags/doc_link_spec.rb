# frozen_string_literal: true

require "spec_helper"
require "liquid"

RSpec.describe Jekyll::Documents::DocLinkTag do
  let(:tag_class) { described_class }
  let(:site) { make_site }
  let(:context) { Liquid::Context.new({}, {}, { site: site }) }

  def create_tag(markup = "")
    tag_class.new("doc_link", markup, Liquid::Tokenizer.new(""))
  end

  def render_tag(markup, site_override = nil)
    ctx = Liquid::Context.new({}, {}, { site: site_override || site })
    tag = create_tag(markup)
    tag.render(ctx)
  end

  describe "#initialize" do
    it "parses a quoted query" do
      tag = create_tag(%("Board Meeting"))
      expect(tag).to be_a(described_class)
    end

    it "parses a bare word query" do
      tag = create_tag("report")
      expect(tag).to be_a(described_class)
    end

    it "parses query with options" do
      tag = create_tag(%("Board Meeting" text:"Read the report"))
      expect(tag).to be_a(described_class)
    end
  end

  describe "#render" do
    include_context "with temp documents directory"

    before do
      create_document("referat", "2026-03-01_Board_Meeting.pdf")
      create_document("referat", "2026-02-15_Annual_Report.pdf")
      create_document("other", "2026-03-05_Other_Doc.pdf")
      @site = site_with_documents
      generate_documents(@site)
    end

    it "renders an anchor tag with the document URL" do
      result = render_tag(%("Board Meeting"), @site)
      expect(result).to start_with("<a href=")
      expect(result).to include("Board Meeting</span>")
    end

    it "includes the file icon by default" do
      result = render_tag(%("Board Meeting"), @site)
      expect(result).to include("<img")
      expect(result).to include('class="document-file-icon doc-link-icon"')
    end

    it "includes the file size by default" do
      result = render_tag(%("Board Meeting"), @site)
      expect(result).to include("doc-link-size")
    end

    it "hides the icon when icon:false" do
      result = render_tag(%("Board Meeting" icon:false), @site)
      expect(result).not_to include("<img")
    end

    it "hides the size when size:false" do
      result = render_tag(%("Board Meeting" size:false), @site)
      expect(result).not_to include("doc-link-size")
    end

    it "matches by exact title (case-insensitive)" do
      result = render_tag(%("board meeting"), @site)
      expect(result).to include("Board Meeting</span>")
    end

    it "matches by partial title" do
      result = render_tag(%("annual"), @site)
      expect(result).to include("Annual Report</span>")
    end

    it "matches by slug" do
      result = render_tag(%("other-doc"), @site)
      expect(result).to include("Other Doc</span>")
    end

    it "prefers a unique exact match over partial matches" do
      create_document("other", "2026-03-06_Report.pdf")
      site = site_with_documents
      generate_documents(site)

      result = render_tag(%("report"), site)

      expect(result).to include("Report</span>")
    end

    it "logs a warning and renders nothing for duplicate titles" do
      create_document("referat", "2026-01-01_Quarter_Report.pdf")
      create_document("referat", "2026-04-01_Quarter_Report.pdf")
      site = site_with_documents("documents" => {
                                   "permalink" => "/documents/:category/:date/:slug/"
                                 })
      generate_documents(site)

      expect(Jekyll.logger).to receive(:warn)
        .with("jekyll-documents", /Ambiguous doc_link.*Quarter Report.*2026-01-01.*2026-04-01/)

      expect(render_tag(%("Quarter Report"), site)).to eq("")
    end

    it "logs a warning and renders nothing for duplicate slugs" do
      create_document("referat", "2026-01-01_Quarter_Report.pdf")
      create_document("other", "2026-04-01_Quarter_Report.pdf")
      site = site_with_documents
      generate_documents(site)

      expect(Jekyll.logger).to receive(:warn)
        .with("jekyll-documents", /Ambiguous doc_link.*quarter-report/)

      expect(render_tag(%("quarter-report"), site)).to eq("")
    end

    it "aborts with all matching paths in strict resolution mode" do
      create_document("referat", "2026-01-01_Quarter_Report.pdf")
      create_document("other", "2026-04-01_Quarter_Report.pdf")
      site = site_with_documents("documents" => { "resolution_mode" => "strict" })
      generate_documents(site)

      candidates = /Ambiguous doc_link.*(?:2026-01-01.*2026-04-01|2026-04-01.*2026-01-01)/
      expect(Jekyll.logger).to receive(:abort_with)
        .with("jekyll-documents", candidates).and_call_original

      expect { render_tag(%("Quarter Report"), site) }.to raise_error(SystemExit)
    end

    it "resolves an exact source path and preserves options" do
      create_document("Departments/Europe/Research", "2026-01-01_Quarter_Report.pdf")
      create_document("Departments/America/Research", "2026-04-01_Quarter_Report.pdf")
      site = site_with_documents("documents" => {
                                   "permalink" => "/documents/:category_path/:date/:slug/"
                                 })
      generate_documents(site)

      markup = 'path:"Departments/Europe/Research/2026-01-01_Quarter_Report.pdf" ' \
               'text:"European report" icon:false size:false'
      result = render_tag(markup, site)
      american = render_tag(
        %(path:"Departments/America/Research/2026-04-01_Quarter_Report.pdf"), site
      )

      expect(result).to include("/departments/europe/research/2026-01-01/quarter-report/")
      expect(american).to include("/departments/america/research/2026-04-01/quarter-report/")
      expect(result).to include("European report</span>")
      expect(result).not_to include("<img")
      expect(result).not_to include("doc-link-size")
    end

    it "resolves a root-level source path" do
      create_document_at_root("2026-01-01_Root_Report.pdf")
      site = site_with_documents
      generate_documents(site)

      result = render_tag(%(path:"2026-01-01_Root_Report.pdf"), site)

      expect(result).to include("Root Report</span>")
    end

    it "normalizes separators for exact source path resolution" do
      create_document("Departments/Europe/Research", "2026-01-01_Quarter_Report.pdf")
      site = site_with_documents
      generate_documents(site)

      result = render_tag(
        %(path:"Departments\\Europe\\Research\\2026-01-01_Quarter_Report.pdf"), site
      )

      expect(result).to include("Quarter Report</span>")
    end

    it "logs an unknown source path and renders nothing" do
      expect(Jekyll.logger).to receive(:warn)
        .with("jekyll-documents", %r{Unknown doc_link path.*Missing/Document\.pdf})

      expect(render_tag(%(path:"Missing/Document.pdf"), @site)).to eq("")
    end

    it "uses custom text when provided" do
      result = render_tag(%("Board Meeting" text:"Read meeting notes"), @site)
      expect(result).to include("Read meeting notes</span>")
    end

    it "returns empty string when no match found" do
      result = render_tag(%("nonexistent document"), @site)
      expect(result).to eq("")
    end

    it "returns empty string when documents collection is empty" do
      empty_site = make_site
      result = render_tag(%("anything"), empty_site)
      expect(result).to eq("")
    end

    it "applies the site baseurl" do
      site = site_with_documents("baseurl" => "/site")
      generate_documents(site)
      result = render_tag(%("Board Meeting"), site)
      expect(result).to include('href="/site/')
    end

    it "escapes HTML in the link text" do
      create_document("test", "2026-01-01_A_&_B_Report.pdf")
      site = site_with_documents
      generate_documents(site)
      result = render_tag(%("A & B Report"), site)
      expect(result).to include("A &amp; B Report</span>")
    end

    it "formats file size in human-readable format" do
      result = render_tag(%("Board Meeting"), @site)
      # "fake content" is 12 bytes
      expect(result).to match(/\d+(\.\d+)?\s+(B|KB|MB|GB)/)
    end

    it "formats large file sizes in KB" do
      create_document("big", "2026-01-01_Large_File.pdf", "x" * 5000)
      site = site_with_documents
      generate_documents(site)
      result = render_tag(%("Large File"), site)
      expect(result).to include("KB")
    end

    it "formats very large file sizes in MB" do
      create_document("huge", "2026-01-01_Huge_File.pdf", "x" * 2_000_000)
      site = site_with_documents
      generate_documents(site)
      result = render_tag(%("Huge File"), site)
      expect(result).to include("MB")
    end
  end
end
