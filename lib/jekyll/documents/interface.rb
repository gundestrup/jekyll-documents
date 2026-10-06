# frozen_string_literal: true

module Jekyll
  module Documents
    # Machine-readable description of the plugin's public interface:
    # Liquid tags + their options, filters, config keys, and enum values.
    # `rake interface` writes this as interface.yml (shipped in the gem) so
    # tooling like editor extensions can consume it without parsing Ruby.
    module Interface
      TAG_OPTIONS = {
        "doc_link" => %w[icon path size text],
        "doc_category" => %w[aggregate limit list path text],
        "document_icon" => %w[alt class],
        "latest_documents" => %w[category count]
      }.freeze

      FILTERS = %w[
        documents_slugify
        documents_title_from_filename
        file_type_icon
        file_type_icon_tag
      ].freeze

      def self.to_h
        {
          "gem" => "jekyll-documents",
          "version" => VERSION,
          "tags" => TAG_OPTIONS.transform_values { |params| { "params" => params } },
          "filters" => FILTERS,
          "config" => { "documents" => Configuration::DEFAULTS.keys.sort },
          "enums" => {
            "icon_set" => FileTypeIcons::ICON_MAP.keys.sort,
            "resolution_mode" => Configuration::RESOLUTION_MODES.sort
          }
        }
      end
    end
  end
end
