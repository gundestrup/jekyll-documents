# frozen_string_literal: true

module Jekyll
  module Documents
    module Filters
      DANISH_MAP = {
        "æ" => "ae", "ø" => "oe", "å" => "aa",
        "Æ" => "Ae", "Ø" => "Oe", "Å" => "Aa"
      }.freeze

      # Slugify while handling Danish letters and basic punctuation cleanup.
      def documents_slugify(input, downcase = true, danish_map = true)
        s = input.to_s.dup
        s = s.gsub(/[æøåÆØÅ]/) { |ch| DANISH_MAP[ch] } if danish_map
        s = s.strip.gsub(/[^\p{Alnum}\-_\s]/u, "")
        s = s.tr(" ", "-").gsub(/-+/, "-")
        s = s.downcase if downcase
        s
      end

      # Title from filename e.g. "2026-03-01_Title_Here" -> "Title Here"
      def documents_title_from_filename(basename)
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
