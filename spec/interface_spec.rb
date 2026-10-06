# frozen_string_literal: true

require "yaml"

RSpec.describe "interface manifest" do
  root = File.expand_path("..", __dir__)
  interface = Jekyll::Documents::Interface.to_h

  it "matches the committed interface.yml" do
    manifest = YAML.load_file(File.join(root, "interface.yml"))
    expect(manifest).to eq(interface)
  end

  it "declares every Liquid tag registered by this gem" do
    owned = Liquid::Template.tags.select do |_name, klass|
      klass.to_s.start_with?("Jekyll::Documents")
    end.map(&:first)
    expect(owned.sort).to eq(interface["tags"].keys.sort)
  end

  it "lists exactly the option keys each tag reads" do
    tag_files = {
      "doc_link" => "tags/doc_link.rb",
      "doc_category" => "tags/doc_category.rb",
      "document_icon" => "tags/document_icon.rb",
      "latest_documents" => "tags/latest_documents.rb"
    }
    tag_files.each do |tag, path|
      source = File.read(File.join(root, "lib/jekyll/documents", path))
      key_pattern = /(?:@options|@args|options)\["(\w+)"\]/
      used = []
      pos = 0
      while (match = key_pattern.match(source, pos))
        used << match[1]
        pos = match.end(0)
      end
      used = used.uniq.sort
      declared = interface.dig("tags", tag, "params").sort
      expect(used).to eq(declared),
                      "#{tag}: code reads #{used.inspect} but manifest declares #{declared.inspect}"
    end
  end

  it "documents every tag, option, filter, config key, and enum value" do
    docs = (Dir[File.join(root, "*.md")] +
            Dir[File.join(root, "docs/**/*.md")] +
            Dir[File.join(root, "example/**/*.md")])
           .map { |f| File.read(f) }.join("\n")

    missing = []
    interface["tags"].each do |tag, spec|
      missing << "tag `#{tag}`" unless docs.match?(/\b#{tag}\b/)
      spec["params"].each do |param|
        missing << "#{tag} option `#{param}:`" unless docs.match?(/\b#{param}\s*:/)
      end
    end
    interface["filters"].each do |filter|
      missing << "filter `#{filter}`" unless docs.match?(/\b#{filter}\b/)
    end
    interface["config"].each do |section, keys|
      keys.each do |key|
        missing << "#{section} config `#{key}:`" unless docs.match?(/\b#{key}\s*:/)
      end
    end
    interface["enums"].each do |setting, values|
      values.each do |value|
        missing << "#{setting} value `#{value}`" unless docs.match?(/\b#{Regexp.escape(value)}\b/)
      end
    end

    expect(missing).to be_empty,
                       "interface items missing from docs:\n  #{missing.join("\n  ")}"
  end
end
