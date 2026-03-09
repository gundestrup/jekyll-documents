# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"

RSpec.describe Jekyll::Documents::LatestDocumentsTag do
  # Note: These tests are pending because Liquid::Tag requires proper Liquid context
  # The tag works correctly when used in Jekyll templates
  
  let(:tag) { described_class.new("latest_documents", "", ["token"]) }
  let(:site) { make_site }
  let(:context) { { registers: { site: site } } }

  describe "#render" do
    context "with no documents" do
      it "returns empty list" do
        site.collections["documents"] = Jekyll::Collection.new(site, "documents")
        
        result = tag.render(context)
        
        expect(result).to include("<ul")
        expect(result).to include("</ul>")
      end
    end

    context "with documents" do
      let(:temp_dir) { Dir.mktmpdir }
      let(:docs_dir) { File.join(temp_dir, "assets", "documents", "referat") }

      before do
        FileUtils.mkdir_p(docs_dir)
        File.write(File.join(docs_dir, "2026-03-01_Board_Meeting.pdf"), "fake pdf")
        File.write(File.join(docs_dir, "2026-02-15_Annual_Report.pdf"), "fake pdf")
        File.write(File.join(docs_dir, "2026-01-10_Old_Document.pdf"), "fake pdf")
      end

      after do
        FileUtils.rm_rf(temp_dir)
      end

      it "renders list of documents" do
        site = make_site("source" => temp_dir)
        generator = Jekyll::Documents::Generator.new
        generator.generate(site)
        context = { registers: { site: site } }
        
        result = tag.render(context)
        
        expect(result).to include("<ul")
        expect(result).to include("<li>")
        expect(result).to include("</ul>")
      end

      it "limits to configured count" do
        site = make_site("source" => temp_dir, "documents" => { "latest_default_count" => 2 })
        generator = Jekyll::Documents::Generator.new
        generator.generate(site)
        context = { registers: { site: site } }
        
        result = tag.render(context)
        
        # Should only show 2 documents
        expect(result.scan(/<li>/).count).to eq(2)
      end

      it "sorts by date descending" do
        site = make_site("source" => temp_dir)
        generator = Jekyll::Documents::Generator.new
        generator.generate(site)
        context = { registers: { site: site } }
        
        result = tag.render(context)
        
        # Most recent should appear first
        board_pos = result.index("Board Meeting")
        annual_pos = result.index("Annual Report")
        old_pos = result.index("Old Document")
        
        expect(board_pos).to be < annual_pos if board_pos && annual_pos
        expect(annual_pos).to be < old_pos if annual_pos && old_pos
      end

      it "escapes HTML in titles" do
        FileUtils.mkdir_p(docs_dir)
        File.write(File.join(docs_dir, "2026-03-01_<script>alert('xss')</script>.pdf"), "fake")
        
        site = make_site("source" => temp_dir)
        generator = Jekyll::Documents::Generator.new
        generator.generate(site)
        context = { registers: { site: site } }
        
        result = tag.render(context)
        
        expect(result).not_to include("<script>")
        expect(result).to include("&lt;script&gt;")
      end

      it "includes date in output" do
        site = make_site("source" => temp_dir)
        generator = Jekyll::Documents::Generator.new
        generator.generate(site)
        context = { registers: { site: site } }
        
        result = tag.render(context)
        
        expect(result).to match(/\d{2}-\d{2}-\d{4}/)
      end
    end
  end

  describe "#parse_args" do
    it "parses count argument" do
      tag = described_class.new("latest_documents", "count:10", ["token"])
      args = tag.instance_variable_get(:@args)
      
      expect(args["count"]).to eq("10")
    end

    it "parses category argument with quotes" do
      tag = described_class.new("latest_documents", "category:'referat'", ["token"])
      args = tag.instance_variable_get(:@args)
      
      expect(args["category"]).to eq("referat")
    end

    it "parses multiple arguments" do
      tag = described_class.new("latest_documents", "count:5 category:'referat'", ["token"])
      args = tag.instance_variable_get(:@args)
      
      expect(args["count"]).to eq("5")
      expect(args["category"]).to eq("referat")
    end

    it "handles arguments without quotes" do
      tag = described_class.new("latest_documents", "count:5", ["token"])
      args = tag.instance_variable_get(:@args)
      
      expect(args["count"]).to eq("5")
    end
  end

  describe "#escape_html" do
    it "escapes ampersands" do
      result = tag.send(:escape_html, "Board & Meeting")
      expect(result).to eq("Board &amp; Meeting")
    end

    it "escapes less than" do
      result = tag.send(:escape_html, "<script>")
      expect(result).to eq("&lt;script&gt;")
    end

    it "escapes quotes" do
      result = tag.send(:escape_html, 'Say "hello"')
      expect(result).to eq("Say &quot;hello&quot;")
    end

    it "escapes apostrophes" do
      result = tag.send(:escape_html, "It's working")
      expect(result).to eq("It&#39;s working")
    end

    it "handles nil input" do
      result = tag.send(:escape_html, nil)
      expect(result).to eq("")
    end
  end
end
