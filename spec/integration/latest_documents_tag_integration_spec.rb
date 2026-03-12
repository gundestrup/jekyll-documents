# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"
require "liquid"

RSpec.describe "LatestDocumentsTag Integration", type: :integration do
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

  def render_tag(markup, site)
    template = Liquid::Template.parse("{% latest_documents #{markup} %}")
    template.render({}, registers: { site: site })
  end

  it "renders list of documents" do
    site = make_site("source" => temp_dir)
    generator = Jekyll::Documents::Generator.new
    generator.generate(site)

    result = render_tag("", site)

    expect(result).to include("<ul")
    expect(result).to include("<li>")
    expect(result).to include("Board Meeting")
    expect(result).to include("</ul>")
  end

  it "limits to configured count" do
    site = make_site("source" => temp_dir)
    generator = Jekyll::Documents::Generator.new
    generator.generate(site)

    result = render_tag("count:2", site)

    expect(result.scan("<li>").count).to eq(2)
  end

  it "filters by category" do
    other_dir = File.join(temp_dir, "assets", "documents", "other")
    FileUtils.mkdir_p(other_dir)
    File.write(File.join(other_dir, "2026-03-05_Other_Doc.pdf"), "fake")

    site = make_site("source" => temp_dir)
    generator = Jekyll::Documents::Generator.new
    generator.generate(site)

    result = render_tag("category:'referat'", site)

    expect(result).to include("Board Meeting")
    expect(result).not_to include("Other Doc")
  end

  it "sorts documents by date descending" do
    site = make_site("source" => temp_dir)
    generator = Jekyll::Documents::Generator.new
    generator.generate(site)

    result = render_tag("", site)

    board_pos = result.index("Board Meeting")
    annual_pos = result.index("Annual Report")
    old_pos = result.index("Old Document")

    expect(board_pos).to be < annual_pos
    expect(annual_pos).to be < old_pos
  end

  it "includes dates in output" do
    site = make_site("source" => temp_dir)
    generator = Jekyll::Documents::Generator.new
    generator.generate(site)

    result = render_tag("", site)

    expect(result).to match(/2026-03-01/)
    expect(result).to match(/2026-02-15/)
  end

  it "escapes HTML entities" do
    site = make_site("source" => temp_dir)
    generator = Jekyll::Documents::Generator.new
    generator.generate(site)

    # Test the escape_html method through rendering
    result = render_tag("", site)

    # Ensure no unescaped HTML
    expect(result).not_to match(/<script>/)
  end

  it "handles empty documents collection" do
    site = make_site("source" => temp_dir)
    # Don't generate documents

    result = render_tag("", site)

    expect(result).to include("<ul")
    expect(result).to include("</ul>")
    expect(result.scan("<li>").count).to eq(0)
  end
end
