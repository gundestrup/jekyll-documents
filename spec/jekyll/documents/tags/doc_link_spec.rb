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
      expect(result).to include('class="file-icon doc-link-icon"')
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
