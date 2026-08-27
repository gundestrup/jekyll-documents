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
      LINES_ICON_PATH = "/assets/icons/lines/"
      MINIMAL_ICON_PATH = "/assets/icons/minimal/"

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
          "pdf" => "#{LINES_ICON_PATH}pdf-file-type-svgrepo-com.svg",
          "docx" => "#{LINES_ICON_PATH}word-file-type-svgrepo-com.svg",
          "doc" => "#{LINES_ICON_PATH}word-file-type-svgrepo-com.svg",
          "pptx" => "#{LINES_ICON_PATH}ppt-file-type-svgrepo-com.svg",
          "ppt" => "#{LINES_ICON_PATH}ppt-file-type-svgrepo-com.svg",
          "xlsx" => "#{LINES_ICON_PATH}excel-file-type-svgrepo-com.svg",
          "xls" => "#{LINES_ICON_PATH}excel-file-type-svgrepo-com.svg",
          "odt" => "#{LINES_ICON_PATH}word-file-type-svgrepo-com.svg",
          "ods" => "#{LINES_ICON_PATH}excel-file-type-svgrepo-com.svg",
          "odp" => "#{LINES_ICON_PATH}ppt-file-type-svgrepo-com.svg",
          "txt" => "#{LINES_ICON_PATH}txt-file-type-svgrepo-com.svg",
          "zip" => "#{LINES_ICON_PATH}zip-file-type-svgrepo-com.svg",
          "mp3" => "#{LINES_ICON_PATH}mp3-file-type-svgrepo-com.svg",
          "mp4" => "#{LINES_ICON_PATH}other-file-type-svgrepo-com.svg",
          "jpg" => "#{LINES_ICON_PATH}jpg-file-type-svgrepo-com.svg",
          "jpeg" => "#{LINES_ICON_PATH}jpg-file-type-svgrepo-com.svg",
          "png" => "#{LINES_ICON_PATH}png-file-type-svgrepo-com.svg"
        },
        "minimal" => {
          "pdf" => "#{MINIMAL_ICON_PATH}" \
                   "extension-file-format-pdf-document-file-format-svgrepo-com.svg",
          "docx" => "#{MINIMAL_ICON_PATH}" \
                    "extension-file-format-document-file-format-svgrepo-com.svg",
          "doc" => "#{MINIMAL_ICON_PATH}" \
                   "extension-file-format-document-file-format-svgrepo-com.svg",
          "pptx" => "#{MINIMAL_ICON_PATH}" \
                    "extension-file-format-document-file-format-2-svgrepo-com.svg",
          "ppt" => "#{MINIMAL_ICON_PATH}" \
                   "extension-file-format-document-file-format-2-svgrepo-com.svg",
          "xlsx" => "#{MINIMAL_ICON_PATH}" \
                    "extension-file-format-document-file-format-2-svgrepo-com.svg",
          "xls" => "#{MINIMAL_ICON_PATH}" \
                   "extension-file-format-document-file-format-2-svgrepo-com.svg",
          "odt" => "#{MINIMAL_ICON_PATH}" \
                   "extension-file-format-document-file-format-svgrepo-com.svg",
          "ods" => "#{MINIMAL_ICON_PATH}" \
                   "extension-file-format-document-file-format-2-svgrepo-com.svg",
          "odp" => "#{MINIMAL_ICON_PATH}" \
                   "extension-file-format-document-file-format-2-svgrepo-com.svg",
          "txt" => "#{MINIMAL_ICON_PATH}" \
                   "extension-file-format-txt-document-file-format-svgrepo-com.svg",
          "zip" => "#{MINIMAL_ICON_PATH}" \
                   "extension-file-format-document-file-format-2-svgrepo-com.svg",
          "mp3" => "#{MINIMAL_ICON_PATH}" \
                   "extension-file-format-document-file-format-2-svgrepo-com.svg",
          "mp4" => "#{MINIMAL_ICON_PATH}" \
                   "extension-file-format-document-file-format-2-svgrepo-com.svg",
          "jpg" => "#{MINIMAL_ICON_PATH}" \
                   "extension-file-format-jpg-document-file-format-svgrepo-com.svg",
          "jpeg" => "#{MINIMAL_ICON_PATH}" \
                    "file-format-jpeg-document-extension-file-format-svgrepo-com.svg",
          "png" => "#{MINIMAL_ICON_PATH}" \
                   "extension-file-format-document-file-format-2-svgrepo-com.svg"
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

      UNKNOWN_ICON_MAP = {
        "color" => "/assets/icons/color/unknown-document-svgrepo-com.svg",
        "lines" => "#{LINES_ICON_PATH}other-file-type-svgrepo-com.svg",
        "minimal" => "#{MINIMAL_ICON_PATH}" \
                     "extension-file-format-document-file-format-2-svgrepo-com.svg",
        "ultra-minimal" => "/assets/icons/ultra-minimal/file.svg"
      }.freeze

      # Returns the icon URL for a given file type and explicit icon set
      # @param file_type [String] the file extension (e.g., 'pdf', 'docx')
      # @param icon_set [String] the icon set name (defaults to 'color')
      # @return [String] the icon file URL
      # @example
      #   FileTypeIcons.icon_for('pdf', 'lines') #=>
      #     "/assets/icons/lines/pdf-file-type-svgrepo-com.svg"
      def self.icon_for(file_type, icon_set = "color")
        selected_set = ICON_MAP.key?(icon_set) ? icon_set : "color"
        icons = ICON_MAP[selected_set]
        icons[file_type.to_s.downcase] || UNKNOWN_ICON_MAP[selected_set]
      end

      # Returns the icon URL for a given file type using configured icon set
      # @param file_type [String] the file extension (e.g., 'pdf', 'docx')
      # @param context [Liquid::Context] the Liquid context for accessing site config
      # @return [String] the icon file URL
      # @example
      #   file_type_icon('pdf') #=> "/assets/icons/color/pdf.svg"
      def file_type_icon(file_type, context = nil)
        Jekyll::Documents::FileTypeIcons.icon_for(file_type, get_icon_set(context))
      end

      # Returns an HTML img tag for the file type icon
      # @param file_type [String] the file extension
      # @param css_class [String] CSS class for the img tag (default: 'file-icon')
      # @param alt [String, nil] alt text for the image (default: auto-generated)
      # @param context [Liquid::Context] the Liquid context for accessing site config
      # @return [String] HTML img tag
      # @example
      #   file_type_icon_tag('pdf') #=> \
      #     '<img src="..." alt="PDF file" class="document-file-icon" ... />'
      def file_type_icon_tag(file_type, css_class: "document-file-icon", alt: nil, context: nil)
        url = file_type_icon(file_type, context)
        alt_text = alt || "#{file_type.to_s.upcase} file"
        style = "width:1em;height:1em;vertical-align:middle;"
        "<img src=\"#{url}\" alt=\"#{alt_text}\" " \
          "class=\"#{css_class}\" style=\"#{style}\" />"
      end

      private

      # Gets the configured icon set from site configuration
      # @param context [Liquid::Context] the Liquid context
      # @return [String] the icon set name
      def get_icon_set(context)
        return "color" unless context

        site = context.registers[:site]
        icon_set = site&.config&.dig("documents", "icon_set")
        return "color" unless icon_set && ICON_MAP.key?(icon_set)

        icon_set
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::Documents::FileTypeIcons)
