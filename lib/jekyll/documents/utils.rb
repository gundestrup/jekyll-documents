# frozen_string_literal: true

module Jekyll
  module Documents
    # A tiny StaticFile subclass for writing text files during build.
    class TextStaticFile < ::Jekyll::StaticFile
      def initialize(site, base, rel_dest, content)
        @site = site
        @base = base
        @dir  = File.dirname(rel_dest)
        @name = File.basename(rel_dest)
        @content = content
        super(site, base, @dir, @name)
      end

      def write(dest)
        dest_path = destination(dest)
        FileUtils.mkdir_p(File.dirname(dest_path))
        File.write(dest_path, @content)
        true
      end
    end
  end
end
