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
