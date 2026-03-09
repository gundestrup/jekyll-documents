# frozen_string_literal: true

require "json"
require_relative "utils"

module Jekyll
  module Documents
    class JsonIndexGenerator < ::Jekyll::Generator
      safe true
      priority :low

      def generate(site)
        cfg = Configuration.read(site)
        return unless cfg["json_index"]

        docs = site.collections["documents"]&.docs || []
        return if docs.empty?

        items = docs.map do |d|
          {
            "url"       => d.url,
            "title"     => d.data["title"],
            "category"  => d.data["category"],
            "date"      => (d.data["date"] || Time.at(0)).strftime("%Y-%m-%d"),
            "slug"      => d.data["slug"],
            "file_type" => d.data["file_type"],
            "extension" => d.data["extension"]
          }
        end

        json = JSON.pretty_generate(items)
        path = cfg["json_index_path"] || "/documents.json"

        site.static_files << TextStaticFile.new(site, site.source, path, json)
      end
    end
  end
end
