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

        items = docs.map do |doc|
          data = doc.data
          {
            "url" => doc.url,
            "title" => data["title"],
            "category" => data["category"],
            "date" => (data["date"] || Time.at(0)).strftime("%Y-%m-%d"),
            "slug" => data["slug"],
            "file_type" => data["file_type"],
            "extension" => data["extension"]
          }
        end

        json = JSON.pretty_generate(items)
        path = cfg["json_index_path"] || "/documents.json"

        site.static_files << TextStaticFile.new(site, site.source, path, json)
      end
    end
  end
end
