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

  it "renders generated documents through a parsed Liquid template" do
    site = site_with_documents
    generate_documents(site)

    result = render_tag("", site)

    expect(result).to include("<ul", "<li>", "Board Meeting", "</ul>")
    expect(result.index("Board Meeting")).to be < result.index("Annual Report")
    expect(result.index("Annual Report")).to be < result.index("Old Document")
  end

  it "escapes HTML entities in document titles" do
    create_document("referat", "2026-04-01_Test&Report<Alert>.pdf")

    site = site_with_documents
    generate_documents(site)

    result = render_tag("", site)

    expect(result).to include("&amp;", "&lt;", "&gt;")
    expect(result).not_to include("<Alert>")
  end
end
