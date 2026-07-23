# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.shared_context "with temp documents directory" do
  let(:temp_dir) { Dir.mktmpdir }
  let(:docs_root) { File.join(temp_dir, "assets", "documents") }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  def create_document(category, filename, content = "fake content")
    dir = File.join(docs_root, category)
    FileUtils.mkdir_p(dir)
    path = File.join(dir, filename)
    File.write(path, content)
    path
  end

  def create_document_at_root(filename, content = "fake content")
    FileUtils.mkdir_p(docs_root)
    path = File.join(docs_root, filename)
    File.write(path, content)
    path
  end

  def site_with_documents(overrides = {})
    make_site({ "source" => temp_dir }.merge(overrides))
  end

  def generate_documents(site)
    generator = Jekyll::Documents::Generator.new
    generator.generate(site)
    generator
  end
end
