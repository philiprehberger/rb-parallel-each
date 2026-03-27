# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::ParallelEach do
  describe '.map' do
    it 'preserves input order' do
      result = described_class.map((1..20).to_a, concurrency: 4) { |n| n * 2 }
      expect(result).to eq((1..20).map { |n| n * 2 })
    end

    it 'applies the block to each element' do
      result = described_class.map(%w[hello world], concurrency: 2, &:upcase)
      expect(result).to eq(%w[HELLO WORLD])
    end

    it 'handles an empty collection' do
      result = described_class.map([], concurrency: 2) { |n| n }
      expect(result).to eq([])
    end

    it 'falls back to sequential map when concurrency is 1' do
      result = described_class.map([1, 2, 3], concurrency: 1) { |n| n + 1 }
      expect(result).to eq([2, 3, 4])
    end

    it 'propagates errors from the block' do
      expect do
        described_class.map([1, 2, 3], concurrency: 2) do |n|
          raise ArgumentError, 'boom' if n == 2

          n
        end
      end.to raise_error(ArgumentError, 'boom')
    end
  end

  describe '.each' do
    it 'processes all items' do
      results = Concurrent::Array.new if defined?(Concurrent::Array)
      results = []
      mutex = Mutex.new

      described_class.each([1, 2, 3, 4, 5], concurrency: 3) do |n|
        mutex.synchronize { results << n }
      end

      expect(results.sort).to eq([1, 2, 3, 4, 5])
    end

    it 'returns the original collection' do
      collection = [1, 2, 3]
      result = described_class.each(collection, concurrency: 2) { |n| n * 2 }
      expect(result).to equal(collection)
    end
  end

  describe '.select' do
    it 'filters elements based on the block' do
      result = described_class.select((1..10).to_a, concurrency: 3, &:even?)
      expect(result).to eq([2, 4, 6, 8, 10])
    end

    it 'preserves input order' do
      result = described_class.select((1..20).to_a, concurrency: 4) { |n| n > 10 }
      expect(result).to eq((11..20).to_a)
    end

    it 'returns empty array when nothing matches' do
      result = described_class.select([1, 3, 5], concurrency: 2, &:even?)
      expect(result).to eq([])
    end
  end

  describe '.flat_map' do
    it 'flattens results' do
      result = described_class.flat_map([1, 2, 3], concurrency: 2) { |n| [n, n * 10] }
      expect(result).to eq([1, 10, 2, 20, 3, 30])
    end

    it 'preserves order' do
      result = described_class.flat_map(%w[a b c], concurrency: 3) { |s| [s, s.upcase] }
      expect(result).to eq(%w[a A b B c C])
    end

    it 'handles single-value returns' do
      result = described_class.flat_map([1, 2, 3], concurrency: 2) { |n| n * 2 }
      expect(result).to eq([2, 4, 6])
    end
  end

  describe '.any?' do
    it 'returns true when a match is found' do
      result = described_class.any?([1, 2, 3, 4, 5], concurrency: 2, &:even?)
      expect(result).to be true
    end

    it 'returns false when no match is found' do
      result = described_class.any?([1, 3, 5, 7], concurrency: 2, &:even?)
      expect(result).to be false
    end

    it 'returns false for an empty collection' do
      result = described_class.any?([], concurrency: 2) { |_n| true }
      expect(result).to be false
    end

    it 'short-circuits on match' do
      call_count = Concurrent::AtomicFixnum.new(0) if defined?(Concurrent::AtomicFixnum)
      call_count = 0
      mutex = Mutex.new

      # Use a large collection with the match early
      items = [true] + Array.new(1000, false)

      described_class.any?(items, concurrency: 2) do |item|
        mutex.synchronize { call_count += 1 }
        sleep(0.01) unless item
        item
      end

      # Should not have processed all 1001 items
      expect(call_count).to be < 1001
    end

    it 'propagates errors from the block' do
      expect do
                described_class.any?([1, 2, 3], concurrency: 2) do |_item|
                  raise 'fail'
                end
              end.to raise_error(RuntimeError, 'fail')
    end
  end

  describe 'concurrency' do
    it 'actually runs in parallel' do
      # Each item sleeps 0.1s. With 4 threads, 4 items should take ~0.1s, not ~0.4s
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      described_class.map([1, 2, 3, 4], concurrency: 4) do |_n|
        sleep(0.1)
      end

      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

      # Should complete in under 0.3s if truly parallel (0.1s ideal + overhead)
      expect(elapsed).to be < 0.3
    end
  end

  describe 'error propagation' do
    it 're-raises the first error encountered in map' do
      expect do
        described_class.map([1, 2, 3], concurrency: 2) do |n|
          raise StandardError, "error on #{n}" if n == 1

          n
        end
      end.to raise_error(StandardError, /error on/)
    end

    it 're-raises errors in select' do
      expect do
        described_class.select([1, 2, 3], concurrency: 2) do |n|
          raise TypeError, 'bad type' if n == 2

          true
        end
      end.to raise_error(TypeError, 'bad type')
    end
  end
end
