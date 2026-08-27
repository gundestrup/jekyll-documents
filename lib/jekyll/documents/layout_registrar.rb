# frozen_string_literal: true

require "fileutils"

module Jekyll
  module Documents
    # Registers gem-packaged _layouts and _includes with the site so Jekyll can
    # discover them without the gem being declared as a theme.
    #
    # Jekyll only auto-discovers _layouts and _includes from theme gems (set via
    # the +theme:+ config key). Plugin gems loaded via +group :jekyll_plugins+
    # do not get their template directories added to Jekyll's lookup paths.
    #
    # This hook copies any gem-packaged layouts and includes into the site's
    # source directories when the user has not provided their own. Files already
    # present in the site take precedence (user overrides are never clobbered).
    module LayoutRegistrar
      GEM_ROOT = File.expand_path("../../..", __dir__)
      TEMPLATE_DIRS = %w[_layouts _includes].freeze

      class << self
        # Copies gem-packaged template files into the site source.
        # @param site [Jekyll::Site] the Jekyll site instance
        # @return [void]
        def register(site)
          TEMPLATE_DIRS.each do |dir|
            gem_dir = File.join(GEM_ROOT, dir)
            next unless Dir.exist?(gem_dir)

            copy_templates(gem_dir, File.join(site.source, dir))
          end
        end

        private

        # Recursively copies files from +source_dir+ to +dest_dir+, skipping any
        # file that already exists in the destination (user overrides win).
        # @param source_dir [String] gem template directory
        # @param dest_dir [String] site template directory
        # @return [void]
        def copy_templates(source_dir, dest_dir)
          Dir.glob(File.join(source_dir, "**", "*")).each do |path|
            next unless File.file?(path)

            relative = path.delete_prefix("#{source_dir}/")
            destination = File.join(dest_dir, relative)
            next if File.exist?(destination)

            FileUtils.mkdir_p(File.dirname(destination))
            FileUtils.cp(path, destination)
          end
        end
      end
    end
  end
end

Jekyll::Hooks.register :site, :after_init do |site|
  Jekyll::Documents::LayoutRegistrar.register(site)

  # Exclude the text extraction cache directory from Jekyll output
  config = Jekyll::Documents::Configuration.read(site)
  if config["extract_text"] && config["text_cache_dir"]
    site.config["exclude"] = Array(site.config["exclude"])
    unless site.config["exclude"].include?(config["text_cache_dir"])
      site.config["exclude"] << config["text_cache_dir"]
    end
  end
end
