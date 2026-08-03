# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "rubygems"

site_dir = Dir.mktmpdir("jekyll-documents-browser-site-")
destination = File.join(site_dir, "_site")
gem_root = Gem::Specification.find_by_name("jekyll-documents").full_gem_path

def write_document(site_dir, category, filename)
  path = File.join(site_dir, "assets", "documents", category, filename)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, "browser test content")
end

write_document(site_dir, "reports", "2026-03-01_Annual_Report.pdf")
write_document(site_dir, "reports", "2026-02-15_Word_Report.docx")

FileUtils.mkdir_p(File.join(site_dir, "_includes"))
FileUtils.mkdir_p(File.join(site_dir, "_layouts"))
Dir.glob(File.join(gem_root, "_includes", "*")) do |include_path|
  FileUtils.cp(include_path, File.join(site_dir, "_includes", File.basename(include_path)))
end
FileUtils.cp(
  File.join(gem_root, "_layouts", "document.html"),
  File.join(site_dir, "_layouts", "document.html")
)

File.write(File.join(site_dir, "_layouts", "default.html"), <<~HTML)
  ---
  ---
  <!doctype html>
  <html><body>{{ content }}</body></html>
HTML

File.write(File.join(site_dir, "index.md"), <<~LIQUID)
  ---
  ---
  <h1>Browser search</h1>
  {% include documents_search.html %}
LIQUID

File.write(File.join(site_dir, "_config.yml"), <<~YAML)
  plugins:
    - jekyll-documents
  baseurl: /manual
  collections:
    documents:
      output: true
  documents:
    icon_set: color
YAML

success = system("jekyll", "build", "--source", site_dir, "--destination", destination,
                 out: File::NULL, err: File::NULL)
abort "Jekyll browser fixture build failed" unless success

server_root = Dir.mktmpdir("jekyll-documents-browser-server-")
FileUtils.mkdir_p(File.join(server_root, "manual"))
FileUtils.cp_r(Dir.glob(File.join(destination, "*")), File.join(server_root, "manual"))
puts server_root
