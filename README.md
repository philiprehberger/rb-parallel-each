# philiprehberger-parallel_each

[![Tests](https://github.com/philiprehberger/rb-parallel-each/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-parallel-each/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-parallel_each.svg)](https://rubygems.org/gems/philiprehberger-parallel_each)
[![GitHub release](https://img.shields.io/github/v/release/philiprehberger/rb-parallel-each)](https://github.com/philiprehberger/rb-parallel-each/releases)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-parallel-each)](https://github.com/philiprehberger/rb-parallel-each/commits/main)
[![License](https://img.shields.io/github/license/philiprehberger/rb-parallel-each)](LICENSE)
[![Bug Reports](https://img.shields.io/github/issues/philiprehberger/rb-parallel-each/bug)](https://github.com/philiprehberger/rb-parallel-each/issues?q=is%3Aissue+is%3Aopen+label%3Abug)
[![Feature Requests](https://img.shields.io/github/issues/philiprehberger/rb-parallel-each/enhancement)](https://github.com/philiprehberger/rb-parallel-each/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

Parallel iteration with configurable thread pool and ordered results

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-parallel_each"
```

Or install directly:

```bash
gem install philiprehberger-parallel_each
```

## Usage

```ruby
require "philiprehberger/parallel_each"

# Parallel map (results preserve input order)
results = Philiprehberger::ParallelEach.map(urls, concurrency: 8) do |url|
  fetch(url)
end
```

### Parallel Each

```ruby
Philiprehberger::ParallelEach.each(items, concurrency: 4) do |item|
  process(item)
end
```

### Parallel Select

```ruby
even = Philiprehberger::ParallelEach.select(numbers, concurrency: 4, &:even?)
```

### Parallel Flat Map

```ruby
pairs = Philiprehberger::ParallelEach.flat_map(records, concurrency: 4) do |r|
  [r.id, r.name]
end
```

### Map and Each with Index

```ruby
# map_with_index passes (item, index) to the block
labeled = Philiprehberger::ParallelEach.map_with_index(items, concurrency: 4) do |item, idx|
  "#{idx}: #{item}"
end

# each_with_index for side effects with index access
Philiprehberger::ParallelEach.each_with_index(items, concurrency: 4) do |item, idx|
  puts "Processing item #{idx}: #{item}"
end
```

### Short-Circuit Methods

```ruby
has_admin = Philiprehberger::ParallelEach.any?(users, concurrency: 4, &:admin?)
all_valid = Philiprehberger::ParallelEach.none?(records, concurrency: 4, &:invalid?)
```

### Count and Reduce

```ruby
even_count = Philiprehberger::ParallelEach.count(numbers, concurrency: 4, &:even?)

total = Philiprehberger::ParallelEach.reduce([1, 2, 3, 4], 0) { |acc, item| acc + item }
```

### Concurrency

All methods accept a `concurrency:` keyword argument that controls the thread pool size. It defaults to `Etc.nprocessors` (the number of available CPU cores).

```ruby
# Use 2 threads
Philiprehberger::ParallelEach.map(items, concurrency: 2) { |i| i * 2 }

# Use all available cores (default)
Philiprehberger::ParallelEach.map(items) { |i| i * 2 }
```

### Error Handling

If any block raises an exception, the first error is re-raised after all threads finish:

```ruby
begin
  Philiprehberger::ParallelEach.map(items, concurrency: 4) do |item|
    raise ArgumentError, 'invalid' if item.nil?

    transform(item)
  end
rescue ArgumentError => e
  puts e.message # => "invalid"
end
```

## API

| Method | Description |
|--------|-------------|
| `ParallelEach.map(collection, concurrency:) { \|item\| }` | Parallel map preserving input order |
| `ParallelEach.each(collection, concurrency:) { \|item\| }` | Parallel each, returns original collection |
| `ParallelEach.select(collection, concurrency:) { \|item\| }` | Parallel filter preserving input order |
| `ParallelEach.flat_map(collection, concurrency:) { \|item\| }` | Parallel flat_map, flattens one level |
| `ParallelEach.any?(collection, concurrency:) { \|item\| }` | Short-circuit any? |
| `ParallelEach.none?(collection, concurrency:) { \|item\| }` | Complement of any? |
| `ParallelEach.map_with_index(collection, concurrency:) { \|item, idx\| }` | Parallel map with index |
| `ParallelEach.each_with_index(collection, concurrency:) { \|item, idx\| }` | Parallel each with index |
| `ParallelEach.count(collection, concurrency:) { \|item\| }` | Count matching elements |
| `ParallelEach.reduce(collection, initial, concurrency:) { \|acc, item\| }` | Sequential reduction |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this package useful, consider giving it a star on GitHub — it helps motivate continued maintenance and development.

[![LinkedIn](https://img.shields.io/badge/Philip%20Rehberger-LinkedIn-0A66C2?logo=linkedin)](https://www.linkedin.com/in/philiprehberger)
[![More packages](https://img.shields.io/badge/more-open%20source%20packages-blue)](https://philiprehberger.com/open-source-packages)

## License

[MIT](LICENSE)
