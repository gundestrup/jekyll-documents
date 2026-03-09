# frozen_string_literal: true

require "jekyll"
require "rspec"
require_relative "../lib/jekyll-documents"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.order = :random
  Kernel.srand config.seed
end

# Helper to create a test Jekyll site
def make_site(config = {})
  site_config = Jekyll.configuration(
    "source" => File.expand_path("fixtures", __dir__),
    "destination" => File.expand_path("../tmp", __dir__),
    "quiet" => true
  ).merge(config)
  
  Jekyll::Site.new(site_config)
end
