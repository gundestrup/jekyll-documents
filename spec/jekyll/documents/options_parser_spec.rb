# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jekyll::Documents::OptionsParser do
  it "parses bare and quoted values" do
    result = described_class.parse_options(
      %(count:5 category:'my docs' text:"Read the report")
    )

    expect(result).to eq(
      "count" => "5", "category" => "my docs", "text" => "Read the report"
    )
  end

  it "allows whitespace around colons" do
    expect(described_class.parse_options("key : value")).to eq("key" => "value")
  end

  it "skips expressions and punctuation without options" do
    result = described_class.parse_options(%(page.icon_url "Board Meeting" class:icon))

    expect(result).to eq("class" => "icon")
  end

  it "preserves an unclosed quote as part of a bare value" do
    expect(described_class.parse_options("key:'unclosed")).to eq("key" => "'unclosed")
  end

  it "omits keys without values" do
    expect(described_class.parse_options("key: ")).to eq({})
  end

  it "returns an empty hash for empty input" do
    expect(described_class.parse_options(nil)).to eq({})
  end

  it "handles long non-matching input in linear time" do
    markup = "#{'a' * 100_000} count:5"

    expect(described_class.parse_options(markup)).to eq("count" => "5")
  end
end
