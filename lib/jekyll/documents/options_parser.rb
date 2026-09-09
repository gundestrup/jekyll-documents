# frozen_string_literal: true

require "strscan"

module Jekyll
  module Documents
    # Linear-time parser for Liquid tag markup key:value pairs.
    # Replaces polynomial-redos-vulnerable regex scanning with
    # anchored scans that advance through the input once.
    module OptionsParser
      module_function

      def parse_options(markup)
        scanner = StringScanner.new(markup.to_s)
        options = {}

        until scanner.eos?
          scanner.skip(/\s+/)
          break if scanner.eos?

          key = scanner.scan(/\w+/)
          unless key
            scanner.getch
            next
          end

          scanner.skip(/\s*/)
          next unless scanner.scan(":")

          scanner.skip(/\s*/)
          value = if scanner.scan(/'([^']*)'/) || scanner.scan(/"([^"]*)"/)
                    scanner[1]
                  else
                    scanner.scan(/\S+/)
                  end
          options[key] = value unless value.nil?
        end

        options
      end
    end
  end
end
