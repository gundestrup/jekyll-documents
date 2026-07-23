# frozen_string_literal: true

require "spec_helper"
require "liquid"

RSpec.describe Jekyll::Documents::LatestDocumentsTag do
  let(:tag_class) { described_class }
  let(:site) { make_site }
  let(:context) { Liquid::Context.new({}, {}, { site: site }) }

  def create_tag(markup = "")
    tag_class.new("latest_documents", markup, Liquid::Tokenizer.new(""))
  end

  def render_tag(markup, site_override = nil)
    ctx = Liquid::Context.new({}, {}, { site: site_override || site })
    tag = create_tag(markup)
    tag.render(ctx)
  end

  describe "#initialize" do
    it "parses empty markup without error" do
      tag = create_tag("")
      expect(tag).to be_a(described_class)
    end

    it "parses markup with arguments" do
      tag = create_tag("count:5 category:'referat'")
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

    it "wraps output in ul with latest-documents class" do
      result = render_tag("", @site)
      expect(result).to start_with(%(<ul class="latest-documents">\n))
      expect(result).to end_with("</ul>\n")
    end

    it "renders each document as a list item with link" do
      result = render_tag("", @site)
      expect(result).to include(%(<li><a href="))
      expect(result).to include("Board Meeting")
    end

    it "includes date in small tag" do
      result = render_tag("", @site)
      expect(result).to include("<small>(2026-03-01)</small>")
    end

    it "limits to count argument" do
      result = render_tag("count:1", @site)
      expect(result.scan("<li>").count).to eq(1)
    end

    it "falls back to latest_default_count from config" do
      site = site_with_documents("documents" => { "latest_default_count" => 1 })
      generate_documents(site)
      result = render_tag("", site)
      expect(result.scan("<li>").count).to eq(1)
    end

    it "falls back to default count of 5 when no config" do
      result = render_tag("", @site)
      expect(result.scan("<li>").count).to eq(3)
    end

    it "filters by category" do
      result = render_tag("category:'referat'", @site)
      expect(result).to include("Board Meeting")
      expect(result).not_to include("Other Doc")
    end

    it "sorts by date descending" do
      result = render_tag("", @site)
      board_pos = result.index("Board Meeting")
      annual_pos = result.index("Annual Report")
      expect(board_pos).to be < annual_pos
    end

    it "returns empty list when no documents collection" do
      result = render_tag("", make_site)
      expect(result).to include("<ul")
      expect(result).to include("</ul>")
      expect(result.scan("<li>").count).to eq(0)
    end

    it "returns empty list when collection is nil" do
      ctx = Liquid::Context.new({}, {}, { site: make_site })
      tag = create_tag("")
      result = tag.render(ctx)
      expect(result.scan("<li>").count).to eq(0)
    end
  end

  describe "#parse_args" do
    it "parses unquoted value" do
      tag = create_tag("count:5")
      args = tag.send(:parse_args, "count:5")
      expect(args["count"]).to eq("5")
    end

    it "parses single-quoted value" do
      args = create_tag("category:'referat'").send(:parse_args, "category:'referat'")
      expect(args["category"]).to eq("referat")
    end

    it "parses multiple arguments" do
      args = create_tag("count:5 category:'referat'")
             .send(:parse_args, "count:5 category:'referat'")
      expect(args["count"]).to eq("5")
      expect(args["category"]).to eq("referat")
    end

    it "parses mixed quoted and unquoted arguments" do
      args = create_tag("category:'my docs' count:3")
             .send(:parse_args, "category:'my docs' count:3")
      expect(args["category"]).to eq("my docs")
      expect(args["count"]).to eq("3")
    end

    it "returns empty hash for empty markup" do
      args = create_tag("").send(:parse_args, "")
      expect(args).to eq({})
    end

    it "returns empty hash for whitespace-only markup" do
      args = create_tag("   ").send(:parse_args, "   ")
      expect(args).to eq({})
    end

    it "handles value with hyphens" do
      args = create_tag("category:my-category")
             .send(:parse_args, "category:my-category")
      expect(args["category"]).to eq("my-category")
    end

    it "handles value with underscores" do
      args = create_tag("filter:my_value")
             .send(:parse_args, "filter:my_value")
      expect(args["filter"]).to eq("my_value")
    end
  end

  describe "#escape_html" do
    let(:tag) { create_tag }

    it "escapes ampersand" do
      expect(tag.send(:escape_html, "a&b")).to eq("a&amp;b")
    end

    it "escapes less-than" do
      expect(tag.send(:escape_html, "a<b")).to eq("a&lt;b")
    end

    it "escapes greater-than" do
      expect(tag.send(:escape_html, "a>b")).to eq("a&gt;b")
    end

    it "escapes double quote" do
      expect(tag.send(:escape_html, 'a"b')).to eq("a&quot;b")
    end

    it "escapes single quote" do
      expect(tag.send(:escape_html, "a'b")).to eq("a&#39;b")
    end

    it "escapes all special characters at once" do
      input = '<script>alert("xss");</script>'
      expected = "&lt;script&gt;alert(&quot;xss&quot;);&lt;/script&gt;"
      expect(tag.send(:escape_html, input)).to eq(expected)
    end

    it "returns empty string for nil" do
      expect(tag.send(:escape_html, nil)).to eq("")
    end

    it "converts non-string to string before escaping" do
      expect(tag.send(:escape_html, 123)).to eq("123")
    end

    it "preserves normal text unchanged" do
      expect(tag.send(:escape_html, "Board Meeting")).to eq("Board Meeting")
    end
  end
end
