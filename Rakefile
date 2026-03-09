# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "yard"

RSpec::Core::RakeTask.new(:spec)
YARD::Rake::YardocTask.new

task default: :spec

desc "Run all tests"
task test: :spec

desc "Generate YARD documentation"
task :doc do
  sh "yard doc"
end

desc "Build and install the gem locally"
task :install_local do
  sh "gem build jekyll-documents.gemspec"
  sh "gem install jekyll-documents-*.gem"
end
