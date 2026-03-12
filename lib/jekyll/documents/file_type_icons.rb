# frozen_string_literal: true

module Jekyll
  module Documents
    # Maps file extensions to local SVG icon files with configurable icon sets
    # Provides Liquid filters for displaying file type icons
    # Icons are based on designs from svgrepo.com and included in the gem
    # @api public
    module FileTypeIcons
      # Mapping of file extensions to icon files for each icon set
      # Icons sourced from svgrepo.com collections:
      # Color: https://www.svgrepo.com/collection/file-type-doctype-vectors/
      # Lines: https://www.svgrepo.com/collection/simple-file-types-line-vectors/
      # Minimal: https://www.svgrepo.com/collection/file-type-minimal-icons/
      # Ultra-minimal: Based on simple document icons
      ICON_MAP = {
        "color" => {
          "pdf" => "/assets/icons/color/pdf-document-svgrepo-com.svg",
          "docx" => "/assets/icons/color/word-document-svgrepo-com.svg",
          "doc" => "/assets/icons/color/word-document-svgrepo-com.svg",
          "pptx" => "/assets/icons/color/ppt-document-svgrepo-com.svg",
          "ppt" => "/assets/icons/color/ppt-document-svgrepo-com.svg",
          "xlsx" => "/assets/icons/color/excel-document-svgrepo-com.svg",
          "xls" => "/assets/icons/color/excel-document-svgrepo-com.svg",
          "odt" => "/assets/icons/color/word-document-svgrepo-com.svg",
          "ods" => "/assets/icons/color/excel-document-svgrepo-com.svg",
          "odp" => "/assets/icons/color/ppt-document-svgrepo-com.svg",
          "txt" => "/assets/icons/color/txt-document-svgrepo-com.svg",
          "zip" => "/assets/icons/color/zip-document-svgrepo-com.svg",
          "mp3" => "/assets/icons/color/audio-document-svgrepo-com.svg",
          "mp4" => "/assets/icons/color/mp4-document-svgrepo-com.svg",
          "jpg" => "/assets/icons/color/image-document-svgrepo-com.svg",
          "jpeg" => "/assets/icons/color/image-document-svgrepo-com.svg",
          "png" => "/assets/icons/color/image-document-svgrepo-com.svg",
          "csv" => "/assets/icons/color/csv-document-svgrepo-com.svg",
          "html" => "/assets/icons/color/html-document-svgrepo-com.svg",
          "xml" => "/assets/icons/color/xml-document-svgrepo-com.svg",
          "rtf" => "/assets/icons/color/rtf-document-svgrepo-com.svg"
        },
        "lines" => {
          "pdf" => "/assets/icons/lines/pdf-svgrepo-com.svg",
          "docx" => "/assets/icons/lines/doc-svgrepo-com.svg",
          "doc" => "/assets/icons/lines/doc-svgrepo-com.svg",
          "pptx" => "/assets/icons/lines/ppt-svgrepo-com.svg",
          "ppt" => "/assets/icons/lines/ppt-svgrepo-com.svg",
          "xlsx" => "/assets/icons/lines/xls-svgrepo-com.svg",
          "xls" => "/assets/icons/lines/xls-svgrepo-com.svg",
          "odt" => "/assets/icons/lines/doc-svgrepo-com.svg",
          "ods" => "/assets/icons/lines/xls-svgrepo-com.svg",
          "odp" => "/assets/icons/lines/ppt-svgrepo-com.svg",
          "txt" => "/assets/icons/lines/txt-svgrepo-com.svg",
          "zip" => "/assets/icons/lines/zip-svgrepo-com.svg",
          "mp3" => "/assets/icons/lines/mp3-svgrepo-com.svg",
          "mp4" => "/assets/icons/lines/mp4-svgrepo-com.svg",
          "jpg" => "/assets/icons/lines/jpg-svgrepo-com.svg",
          "jpeg" => "/assets/icons/lines/jpg-svgrepo-com.svg",
          "png" => "/assets/icons/lines/png-svgrepo-com.svg"
        },
        "minimal" => {
          "pdf" => "/assets/icons/minimal/pdf-svgrepo-com.svg",
          "docx" => "/assets/icons/minimal/doc-svgrepo-com.svg",
          "doc" => "/assets/icons/minimal/doc-svgrepo-com.svg",
          "pptx" => "/assets/icons/minimal/ppt-svgrepo-com.svg",
          "ppt" => "/assets/icons/minimal/ppt-svgrepo-com.svg",
          "xlsx" => "/assets/icons/minimal/xls-svgrepo-com.svg",
          "xls" => "/assets/icons/minimal/xls-svgrepo-com.svg",
          "odt" => "/assets/icons/minimal/doc-svgrepo-com.svg",
          "ods" => "/assets/icons/minimal/xls-svgrepo-com.svg",
          "odp" => "/assets/icons/minimal/ppt-svgrepo-com.svg",
          "txt" => "/assets/icons/minimal/txt-svgrepo-com.svg",
          "zip" => "/assets/icons/minimal/zip-svgrepo-com.svg",
          "mp3" => "/assets/icons/minimal/mp3-svgrepo-com.svg",
          "mp4" => "/assets/icons/minimal/mp4-svgrepo-com.svg",
          "jpg" => "/assets/icons/minimal/jpg-svgrepo-com.svg",
          "jpeg" => "/assets/icons/minimal/jpg-svgrepo-com.svg",
          "png" => "/assets/icons/minimal/png-svgrepo-com.svg"
        },
        "ultra-minimal" => {
          "pdf" => "/assets/icons/ultra-minimal/pdf.svg",
          "docx" => "/assets/icons/ultra-minimal/doc.svg",
          "doc" => "/assets/icons/ultra-minimal/doc.svg",
          "pptx" => "/assets/icons/ultra-minimal/ppt.svg",
          "ppt" => "/assets/icons/ultra-minimal/ppt.svg",
          "xlsx" => "/assets/icons/ultra-minimal/xls.svg",
          "xls" => "/assets/icons/ultra-minimal/xls.svg",
          "odt" => "/assets/icons/ultra-minimal/doc.svg",
          "ods" => "/assets/icons/ultra-minimal/xls.svg",
          "odp" => "/assets/icons/ultra-minimal/ppt.svg",
          "txt" => "/assets/icons/ultra-minimal/txt.svg",
          "zip" => "/assets/icons/ultra-minimal/zip.svg",
          "mp3" => "/assets/icons/ultra-minimal/mp3.svg",
          "mp4" => "/assets/icons/ultra-minimal/mp4.svg",
          "jpg" => "/assets/icons/ultra-minimal/jpg.svg",
          "png" => "/assets/icons/ultra-minimal/png.svg"
        }
      }.freeze

      # Returns the icon URL for a given file type using configured icon set
      # @param file_type [String] the file extension (e.g., 'pdf', 'docx')
      # @param context [Liquid::Context] the Liquid context for accessing site config
      # @return [String] the icon file URL
      # @example
      #   file_type_icon('pdf') #=> "/assets/icons/color/pdf.svg"
      def file_type_icon(file_type, context = nil)
        icon_set = get_icon_set(context)
        icons = ICON_MAP[icon_set] || ICON_MAP["color"]
        icons[file_type.to_s.downcase] ||
          "/assets/icons/#{icon_set}/unknown-document-svgrepo-com.svg"
      end

      # Returns an HTML img tag for the file type icon
      # @param file_type [String] the file extension
      # @param css_class [String] CSS class for the img tag (default: 'file-icon')
      # @param alt [String, nil] alt text for the image (default: auto-generated)
      # @param context [Liquid::Context] the Liquid context for accessing site config
      # @return [String] HTML img tag
      # @example
      #   file_type_icon_tag('pdf') #=> \
      #     '<img src="/assets/icons/color/pdf.svg" alt="PDF file" class="file-icon" />'
      def file_type_icon_tag(file_type, css_class: "file-icon", alt: nil, context: nil)
        url = file_type_icon(file_type, context)
        alt_text = alt || "#{file_type.upcase} file"
        %(<img src="#{url}" alt="#{alt_text}" class="#{css_class}" />)
      end

      private

      # Gets the configured icon set from site configuration
      # @param context [Liquid::Context] the Liquid context
      # @return [String] the icon set name
      def get_icon_set(context)
        return "color" unless context

        site_config = context.registers[:site]&.config
        documents_config = site_config["documents"] if site_config
        icon_set = documents_config["icon_set"] if documents_config

        # Validate icon set exists
        return "color" unless icon_set && ICON_MAP.key?(icon_set)

        icon_set
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::Documents::FileTypeIcons)
