# philiprehberger-parallel_each

[![Tests](https://github.com/philiprehberger/rb-parallel-each/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-parallel-each/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-parallel_each.svg)](https://rubygems.org/gems/philiprehberger-parallel_each)
[![License](https://img.shields.io/github/license/philiprehberger/rb-parallel-each)](LICENSE)
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

# Parallel each
Philiprehberger::ParallelEach.each(items, concurrency: 4) do |item|
  process(item)
end

# Parallel select (filter)
even = Philiprehberger::ParallelEach.select(numbers, concurrency: 4, &:even?)

# Parallel flat_map
pairs = Philiprehberger::ParallelEach.flat_map(records, concurrency: 4) do |r|
  [r.id, r.name]
end

# Short-circuit any?
has_admin = Philiprehberger::ParallelEach.any?(users, concurrency: 4, &:admin?)
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

### `ParallelEach.map(collection, concurrency: Etc.nprocessors) { |item| ... }`

Parallel map that returns results in the same order as the input.

| Parameter | Description |
|-----------|-------------|
| `collection` | Any `Enumerable` |
| `concurrency` | Number of threads (default: `Etc.nprocessors`) |

### `ParallelEach.each(collection, concurrency: Etc.nprocessors) { |item| ... }`

Parallel each. Returns the original collection.

### `ParallelEach.select(collection, concurrency: Etc.nprocessors) { |item| ... }`

Parallel filter. Returns matching items in input order.

### `ParallelEach.flat_map(collection, concurrency: Etc.nprocessors) { |item| ... }`

Parallel flat_map. Flattens one level, preserving input order.

### `ParallelEach.any?(collection, concurrency: Etc.nprocessors) { |item| ... }`

Parallel any? with short-circuit behavior. Returns `true` as soon as any block invocation returns truthy.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

[MIT](LICENSE)
