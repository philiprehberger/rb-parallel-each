# frozen_string_literal: true

require 'etc'
require_relative 'parallel_each/version'
require_relative 'parallel_each/worker_pool'

module Philiprehberger
  # Parallel iteration with configurable thread pool and ordered results.
  module ParallelEach
    # Parallel map that preserves input order.
    #
    # @param collection [Enumerable] items to process
    # @param concurrency [Integer] number of threads (default: number of processors)
    # @yield [item] block to execute for each item
    # @return [Array] results in the same order as the input
    def self.map(collection, concurrency: Etc.nprocessors, &block)
      return collection.map(&block) if concurrency <= 1

      pool = WorkerPool.new(concurrency: concurrency)
      pool.run(collection, &block).map(&:value)
    end

    # Parallel each that processes all items.
    #
    # @param collection [Enumerable] items to process
    # @param concurrency [Integer] number of threads (default: number of processors)
    # @yield [item] block to execute for each item
    # @return [Enumerable] the original collection
    def self.each(collection, concurrency: Etc.nprocessors, &block)
      map(collection, concurrency: concurrency, &block)
      collection
    end

    # Parallel select (filter) that preserves input order.
    #
    # @param collection [Enumerable] items to filter
    # @param concurrency [Integer] number of threads (default: number of processors)
    # @yield [item] block that returns truthy to keep the item
    # @return [Array] filtered items in the same order as the input
    def self.select(collection, concurrency: Etc.nprocessors, &block)
      return collection.select(&block) if concurrency <= 1

      pool = WorkerPool.new(concurrency: concurrency)
      results = pool.run(collection, &block)
      arr = collection.is_a?(Array) ? collection : collection.to_a
      results.select(&:value).map { |r| arr[r.index] }
    end

    # Parallel flat_map that preserves input order.
    #
    # @param collection [Enumerable] items to process
    # @param concurrency [Integer] number of threads (default: number of processors)
    # @yield [item] block that returns an array (or single value) for each item
    # @return [Array] flattened results in the same order as the input
    def self.flat_map(collection, concurrency: Etc.nprocessors, &block)
      return collection.flat_map(&block) if concurrency <= 1

      pool = WorkerPool.new(concurrency: concurrency)
      pool.run(collection, &block).flat_map { |r| Array(r.value) }
    end

    # Parallel map with index. Passes (item, index) to the block.
    #
    # @param collection [Enumerable] items to process
    # @param concurrency [Integer] number of threads (default: number of processors)
    # @yield [item, index] block to execute for each item with its index
    # @return [Array] results in the same order as the input
    def self.map_with_index(collection, concurrency: Etc.nprocessors)
      arr = collection.is_a?(Array) ? collection : collection.to_a
      map(arr.each_with_index.to_a, concurrency: concurrency) { |pair| yield(pair[0], pair[1]) }
    end

    # Parallel each with index. Passes (item, index) to the block.
    #
    # @param collection [Enumerable] items to process
    # @param concurrency [Integer] number of threads (default: number of processors)
    # @yield [item, index] block to execute for each item with its index
    # @return [Enumerable] the original collection
    def self.each_with_index(collection, concurrency: Etc.nprocessors)
      arr = collection.is_a?(Array) ? collection : collection.to_a
      map(arr.each_with_index.to_a, concurrency: concurrency) { |pair| yield(pair[0], pair[1]) }
      collection
    end

    # Parallel none? — complement of any?.
    #
    # @param collection [Enumerable] items to test
    # @param concurrency [Integer] number of threads (default: number of processors)
    # @yield [item] block that returns truthy/falsy
    # @return [Boolean]
    def self.none?(collection, concurrency: Etc.nprocessors, &block)
      !any?(collection, concurrency: concurrency, &block)
    end

    # Parallel count of matching elements.
    #
    # @param collection [Enumerable] items to count
    # @param concurrency [Integer] number of threads (default: number of processors)
    # @yield [item] block that returns truthy to count the item
    # @return [Integer]
    def self.count(collection, concurrency: Etc.nprocessors, &block)
      results = map(collection, concurrency: concurrency, &block)
      results.count { |r| r }
    end

    # Sequential reduction over the collection.
    #
    # @param collection [Enumerable] items to reduce
    # @param initial [Object] initial accumulator value
    # @param concurrency [Integer] unused, accepted for API consistency
    # @yield [accumulator, item] block that returns the new accumulator
    # @return [Object] final accumulator value
    def self.reduce(collection, initial, concurrency: Etc.nprocessors, &block)
      items = collection.is_a?(Array) ? collection : collection.to_a
      items.reduce(initial, &block)
    end

    # Parallel reject (inverse of select) that preserves input order.
    #
    # @param collection [Enumerable] items to filter
    # @param concurrency [Integer] number of threads (default: number of processors)
    # @yield [item] block that returns truthy to reject the item
    # @return [Array] items for which the block returned falsy, in original order
    def self.reject(collection, concurrency: Etc.nprocessors, &block)
      return collection.reject(&block) if concurrency <= 1

      pool = WorkerPool.new(concurrency: concurrency)
      results = pool.run(collection, &block)
      arr = collection.is_a?(Array) ? collection : collection.to_a
      results.reject(&:value).map { |r| arr[r.index] }
    end

    # Parallel partition. Evaluates the block on every element and returns
    # `[truthy_items, falsy_items]`, preserving input order within each array.
    #
    # @param collection [Enumerable] items to partition
    # @param concurrency [Integer] number of threads (default: number of processors)
    # @yield [item] block that returns truthy/falsy
    # @return [Array<Array>] a two-element array `[truthy, falsy]`
    def self.partition(collection, concurrency: Etc.nprocessors, &block)
      return collection.partition(&block) if concurrency <= 1

      pool = WorkerPool.new(concurrency: concurrency)
      results = pool.run(collection, &block)
      arr = collection.is_a?(Array) ? collection : collection.to_a
      truthy = results.select(&:value).map { |r| arr[r.index] }
      falsy  = results.reject(&:value).map { |r| arr[r.index] }
      [truthy, falsy]
    end

    # Parallel find with short-circuit behavior.
    # Returns the first element for which the block returns truthy, or nil.
    #
    # @param collection [Enumerable] items to search
    # @param concurrency [Integer] number of threads (default: number of processors)
    # @yield [item] block that returns truthy/falsy
    # @return [Object, nil] the first matching element or nil
    def self.find(collection, concurrency: Etc.nprocessors, &block)
      return collection.find(&block) if concurrency <= 1

      queue = Queue.new
      arr = collection.is_a?(Array) ? collection : collection.to_a
      arr.each_with_index { |item, idx| queue << [idx, item] }
      concurrency.times { queue << :stop }

      found_item = nil
      found_index = nil
      mutex = Mutex.new
      first_error = nil
      error_mutex = Mutex.new

      threads = Array.new([concurrency, 1].max) do
        Thread.new do
          loop do
            work = queue.pop
            break if work == :stop
            break if mutex.synchronize { !found_item.nil? }

            idx, item = work

            begin
              if block.call(item)
                mutex.synchronize do
                  if found_item.nil? || idx < found_index
                    found_item = item
                    found_index = idx
                  end
                end
                break
              end
            rescue StandardError => e
              error_mutex.synchronize { first_error ||= e }
              break
            end
          end
        end
      end

      threads.each(&:join)

      raise first_error if first_error

      found_item
    end

    # Parallel all? with short-circuit behavior.
    # Returns false as soon as any block invocation returns falsy.
    #
    # @param collection [Enumerable] items to test
    # @param concurrency [Integer] number of threads (default: number of processors)
    # @yield [item] block that returns truthy/falsy
    # @return [Boolean]
    def self.all?(collection, concurrency: Etc.nprocessors, &block)
      return collection.all?(&block) if concurrency <= 1

      !any?(collection, concurrency: concurrency) { |item| !block.call(item) }
    end

    # Parallel any? with short-circuit behavior.
    # Returns true as soon as any block invocation returns truthy.
    #
    # @param collection [Enumerable] items to test
    # @param concurrency [Integer] number of threads (default: number of processors)
    # @yield [item] block that returns truthy/falsy
    # @return [Boolean]
    def self.any?(collection, concurrency: Etc.nprocessors, &block)
      return collection.any?(&block) if concurrency <= 1

      queue = Queue.new
      collection.each_with_index { |item, idx| queue << [idx, item] }
      concurrency.times { queue << :stop }

      found = false
      mutex = Mutex.new
      first_error = nil
      error_mutex = Mutex.new

      threads = Array.new([concurrency, 1].max) do
        Thread.new do
          loop do
            work = queue.pop
            break if work == :stop
            break if found

            _idx, item = work

            begin
              if block.call(item)
                mutex.synchronize { found = true }
                break
              end
            rescue StandardError => e
              error_mutex.synchronize { first_error ||= e }
              break
            end
          end
        end
      end

      threads.each(&:join)

      raise first_error if first_error

      found
    end
  end
end
