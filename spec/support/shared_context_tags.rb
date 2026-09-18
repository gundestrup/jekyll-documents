# frozen_string_literal: true

RSpec.shared_context "liquid tag helpers" do
  let(:tag_class) { described_class }
  let(:site) { make_site }
  let(:context) { Liquid::Context.new({}, {}, { site: site }) }

  def create_tag(markup = "")
    tag_class.new(tag_name, markup, Liquid::Tokenizer.new(""))
  end

  def render_tag(markup, site_override = nil)
    ctx = Liquid::Context.new({}, {}, { site: site_override || site })
    create_tag(markup).render(ctx)
  end
end
