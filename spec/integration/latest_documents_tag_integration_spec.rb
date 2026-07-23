# frozen_string_literal: true

require "spec_helper"
require "liquid"

RSpec.describe "LatestDocumentsTag Integration", type: :integration do
  include_context "with temp documents directory"

  before do
    create_document("referat", "2026-03-01_Board_Meeting.pdf")
    create_document("referat", "2026-02-15_Annual_Report.pdf")
    create_document("referat", "2026-01-10_Old_Document.pdf")
  end

  def render_tag(markup, site)
    template = Liquid::Template.parse("{% latest_documents #{markup} %}")
    template.render({}, registers: { site: site })
  end

  it "renders list of documents" do
    site = site_with_documents
    generate_documents(site)

    result = render_tag("", site)

    expect(result).to include("<ul")
    expect(result).to include("<li>")
    expect(result).to include("Board Meeting")
    expect(result).to include("</ul>")
  end

  it "limits to configured count" do
    site = site_with_documents
    generate_documents(site)

    result = render_tag("count:2", site)

    expect(result.scan("<li>").count).to eq(2)
  end

  it "filters by category" do
    create_document("other", "2026-03-05_Other_Doc.pdf")

    site = site_with_documents
    generate_documents(site)

    result = render_tag("category:'referat'", site)

    expect(result).to include("Board Meeting")
    expect(result).not_to include("Other Doc")
  end

  it "sorts documents by date descending" do
    site = site_with_documents
    generate_documents(site)

    result = render_tag("", site)

    board_pos = result.index("Board Meeting")
    annual_pos = result.index("Annual Report")
    old_pos = result.index("Old Document")

    expect(board_pos).to be < annual_pos
    expect(annual_pos).to be < old_pos
  end

  it "includes dates in output" do
    site = site_with_documents
    generate_documents(site)

    result = render_tag("", site)

    expect(result).to match(/2026-03-01/)
    expect(result).to match(/2026-02-15/)
  end

  it "escapes HTML entities in document titles" do
    create_document("referat", "2026-04-01_Test&Report<Alert>.pdf")

    site = site_with_documents
    generate_documents(site)

    result = render_tag("", site)

    expect(result).to include("&amp;")
    expect(result).to include("&lt;")
    expect(result).to include("&gt;")
    expect(result).not_to include("<Alert>")
  end

  it "handles empty documents collection" do
    site = site_with_documents

    result = render_tag("", site)

    expect(result).to include("<ul")
    expect(result).to include("</ul>")
    expect(result.scan("<li>").count).to eq(0)
  end
end
