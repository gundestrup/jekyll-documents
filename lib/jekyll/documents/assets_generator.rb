# frozen_string_literal: true

module Jekyll
  module Documents
    # Registers gem-packaged frontend assets for copying into the generated site.
    class AssetsGenerator < ::Jekyll::Generator
      safe true
      priority :normal

      def generate(site)
        package_root = File.expand_path("../../..", __dir__)
        site.data["jekyll_documents"] = configuration(site)
        register_assets(site, package_root)
      end

      private

      def configuration(site)
        config = Configuration.read(site)
        {
          "json_index" => config["json_index"],
          "json_index_path" => config["json_index_path"]
        }
      end

      def register_assets(site, package_root)
        assets_root = File.join(package_root, "assets")
        Dir.glob(File.join(assets_root, "**", "*")).each do |path|
          register_asset(site, package_root, path)
        end
      end

      def register_asset(site, package_root, path)
        return unless File.file?(path)

        relative_path = path.delete_prefix("#{package_root}/")
        return if site.static_files.any? { |file| file.relative_path == relative_path }

        site.static_files << ::Jekyll::StaticFile.new(
          site,
          package_root,
          File.dirname(relative_path),
          File.basename(relative_path)
        )
      end
    end
  end
end
