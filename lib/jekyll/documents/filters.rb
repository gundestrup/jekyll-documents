# frozen_string_literal: true

module Jekyll
  module Documents
    module Filters
      DANISH_MAP = {
        "æ" => "ae", "ø" => "oe", "å" => "aa",
        "Æ" => "Ae", "Ø" => "Oe", "Å" => "Aa"
      }.freeze

      # Slugify while handling Danish letters and basic punctuation cleanup.
      def documents_slugify(input, downcase: true, danish_map: true)
        result = input.to_s.dup
        result = result.gsub(/[æøåÆØÅ]/) { |ch| DANISH_MAP[ch] } if danish_map
        result = result.strip.gsub(/[^\p{Alnum}\-_\s]/u, "")
        result = result.tr(" ", "-").squeeze("-")
        result = result.gsub(/[æøåÆØÅ]/, "") unless danish_map
        result = result.downcase if downcase
        result
      end

      # Title from filename e.g. "2026-03-01_Title_Here" -> "Title Here"
      def documents_title_from_filename(basename)
        basename = basename.to_s
        if basename =~ /^\d{4}-\d{2}-\d{2}_(.+)$/
          Regexp.last_match(1).tr("_", " ")
        else
          basename.tr("_", " ")
        end
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::Documents::Filters)
