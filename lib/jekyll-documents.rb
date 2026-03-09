# frozen_string_literal: true

require "jekyll"
require_relative "jekyll/documents/version"
require_relative "jekyll/documents/configuration"
require_relative "jekyll/documents/utils"
require_relative "jekyll/documents/filters"
require_relative "jekyll/documents/file_type_icons"
require_relative "jekyll/documents/generator"
require_relative "jekyll/documents/json_index_generator"

# Liquid tag(s)
require_relative "jekyll/documents/tags/latest_documents"

module Jekyll
  module Documents
    # Namespace module for the plugin.
  end
end
