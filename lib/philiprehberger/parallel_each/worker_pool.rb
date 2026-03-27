# frozen_string_literal: true

module Philiprehberger
  module ParallelEach
    # Thread pool that processes work items from a queue.
    # Each item is a [index, element] pair. Results are collected
    # with their original index so callers can reassemble order.
    class WorkerPool
      Result = Struct.new(:index, :value, keyword_init: true)

      attr_reader :concurrency

      def initialize(concurrency:)
        @concurrency = [concurrency, 1].max
      end

      # Processes each element of the collection through the block using a thread pool.
      # Returns an array of Result structs sorted by index.
      def run(collection, &block)
        queue = Queue.new
        collection.each_with_index { |item, idx| queue << [idx, item] }
        @concurrency.times { queue << :stop }

        results = []
        mutex = Mutex.new
        first_error = nil
        error_mutex = Mutex.new

        threads = Array.new(@concurrency) do
          Thread.new do
            loop do
              work = queue.pop
              break if work == :stop

              idx, item = work

              # Skip remaining work if an error has occurred
              next if first_error

              begin
                value = block.call(item)
                mutex.synchronize { results << Result.new(index: idx, value: value) }
              rescue StandardError => e
                error_mutex.synchronize { first_error ||= e }
              end
            end
          end
        end

        threads.each(&:join)

        raise first_error if first_error

        results.sort_by(&:index)
      end
    end
  end
end
