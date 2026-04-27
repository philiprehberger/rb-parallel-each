# frozen_string_literal: true

module Philiprehberger
  module ParallelEach
    # Thread pool that processes work items from a queue.
    # Each item is a [index, element] pair. Results are collected
    # with their original index so callers can reassemble order.
    class WorkerPool
      Result = Struct.new(:index, :value, keyword_init: true)

      attr_reader :concurrency, :completed, :failed, :start_time, :end_time

      def initialize(concurrency:)
        @concurrency = [concurrency, 1].max
        @completed = 0
        @failed = 0
        @start_time = nil
        @end_time = nil
        @stats_mutex = Mutex.new
      end

      # Wall-clock duration of the most recent run, or nil if no run has finished.
      def elapsed_seconds
        return nil if @start_time.nil? || @end_time.nil?

        @end_time - @start_time
      end

      # Snapshot of execution stats from the most recent run.
      def stats
        {
          workers: @concurrency,
          completed: @completed,
          failed: @failed,
          elapsed_seconds: elapsed_seconds
        }
      end

      # Processes each element of the collection through the block using a thread pool.
      # Returns an array of Result structs sorted by index.
      def run(collection, &)
        queue = build_queue(collection)
        results = []
        mutex = Mutex.new
        error_state = { first: nil, mutex: Mutex.new }

        reset_stats
        threads = spawn_workers(queue, results, mutex, error_state, &)
        threads.each(&:join)
        finalize_stats

        ParallelEach.send(:record_stats, stats)
        raise error_state[:first] if error_state[:first]

        results.sort_by(&:index)
      end

      private

      def build_queue(collection)
        queue = Queue.new
        collection.each_with_index { |item, idx| queue << [idx, item] }
        @concurrency.times { queue << :stop }
        queue
      end

      def reset_stats
        @stats_mutex.synchronize do
          @completed = 0
          @failed = 0
          @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          @end_time = nil
        end
      end

      def finalize_stats
        @stats_mutex.synchronize do
          @end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end
      end

      def spawn_workers(queue, results, mutex, error_state, &block)
        Array.new(@concurrency) do
          Thread.new { worker_loop(queue, results, mutex, error_state, &block) }
        end
      end

      def worker_loop(queue, results, mutex, error_state, &block)
        loop do
          work = queue.pop
          break if work == :stop
          next if error_state[:first]

          process_work(work, results, mutex, error_state, &block)
        end
      end

      def process_work(work, results, mutex, error_state, &block)
        idx, item = work
        value = block.call(item)
        mutex.synchronize { results << Result.new(index: idx, value: value) }
        @stats_mutex.synchronize { @completed += 1 }
      rescue StandardError => e
        @stats_mutex.synchronize { @failed += 1 }
        error_state[:mutex].synchronize { error_state[:first] ||= e }
      end
    end
  end
end
