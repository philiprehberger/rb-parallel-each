# frozen_string_literal: true

require_relative 'lib/philiprehberger/parallel_each/version'

Gem::Specification.new do |spec|
  spec.name = 'philiprehberger-parallel_each'
  spec.version = Philiprehberger::ParallelEach::VERSION
  spec.authors = ['Philip Rehberger']
  spec.email = ['me@philiprehberger.com']
  spec.summary = 'Parallel iteration with configurable thread pool and ordered results'
  spec.description = 'Parallel map, each, select, and flat_map with a configurable thread pool. ' \
                     'Results maintain input order. Handles errors gracefully.'
  spec.homepage = 'https://philiprehberger.com/open-source-packages/ruby/philiprehberger-parallel_each'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/philiprehberger/rb-parallel-each'
  spec.metadata['changelog_uri'] = 'https://github.com/philiprehberger/rb-parallel-each/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/philiprehberger/rb-parallel-each/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
