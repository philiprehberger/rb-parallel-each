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

  describe '.map_with_index' do
    it 'passes item and index to the block' do
      result = described_class.map_with_index(%w[a b c], concurrency: 2) { |item, idx| "#{item}#{idx}" }
      expect(result).to eq(%w[a0 b1 c2])
    end

    it 'preserves order' do
      result = described_class.map_with_index((1..10).to_a, concurrency: 4) { |_item, idx| idx }
      expect(result).to eq((0..9).to_a)
    end
  end

  describe '.each_with_index' do
    it 'yields item and index' do
      pairs = []
      mutex = Mutex.new
      described_class.each_with_index(%w[a b c], concurrency: 2) do |item, idx|
        mutex.synchronize { pairs << [item, idx] }
      end
      expect(pairs.sort_by(&:last)).to eq([['a', 0], ['b', 1], ['c', 2]])
    end

    it 'returns the original collection' do
      collection = [1, 2, 3]
      result = described_class.each_with_index(collection, concurrency: 2) { |_item, _idx| }
      expect(result).to equal(collection)
    end
  end

  describe '.none?' do
    it 'returns true when no elements match' do
      result = described_class.none?([1, 3, 5], concurrency: 2, &:even?)
      expect(result).to be true
    end

    it 'returns false when any element matches' do
      result = described_class.none?([1, 2, 3], concurrency: 2, &:even?)
      expect(result).to be false
    end

    it 'returns true for empty collection' do
      result = described_class.none?([], concurrency: 2) { |_| true }
      expect(result).to be true
    end
  end

  describe '.count' do
    it 'counts matching elements' do
      result = described_class.count((1..10).to_a, concurrency: 3, &:even?)
      expect(result).to eq(5)
    end

    it 'returns zero when nothing matches' do
      result = described_class.count([1, 3, 5], concurrency: 2, &:even?)
      expect(result).to eq(0)
    end
  end

  describe '.reduce' do
    it 'reduces collection with initial value' do
      result = described_class.reduce([1, 2, 3, 4], 0, concurrency: 2) { |acc, item| acc + item }
      expect(result).to eq(10)
    end

    it 'works with string accumulation' do
      result = described_class.reduce(%w[a b c], '', concurrency: 2) { |acc, item| acc + item }
      expect(result).to eq('abc')
    end
  end

  describe '.reject' do
    it 'filters out elements where block returns truthy' do
      result = described_class.reject((1..10).to_a, concurrency: 3, &:even?)
      expect(result).to eq([1, 3, 5, 7, 9])
    end

    it 'preserves input order' do
      result = described_class.reject((1..20).to_a, concurrency: 4) { |n| n <= 10 }
      expect(result).to eq((11..20).to_a)
    end

    it 'returns all elements when nothing is rejected' do
      result = described_class.reject([1, 3, 5], concurrency: 2, &:even?)
      expect(result).to eq([1, 3, 5])
    end

    it 'returns empty array when all are rejected' do
      result = described_class.reject([2, 4, 6], concurrency: 2, &:even?)
      expect(result).to eq([])
    end
  end

  describe '.find' do
    it 'returns the first matching element' do
      result = described_class.find([1, 2, 3, 4], concurrency: 2, &:even?)
      expect([2, 4]).to include(result)
    end

    it 'returns nil when no match is found' do
      result = described_class.find([1, 3, 5], concurrency: 2, &:even?)
      expect(result).to be_nil
    end

    it 'returns nil for empty collection' do
      result = described_class.find([], concurrency: 2) { |_| true }
      expect(result).to be_nil
    end

    it 'falls back to sequential when concurrency is 1' do
      result = described_class.find([1, 2, 3], concurrency: 1, &:even?)
      expect(result).to eq(2)
    end
  end

  describe '.all?' do
    it 'returns true when all elements match' do
      result = described_class.all?([2, 4, 6], concurrency: 2, &:even?)
      expect(result).to be true
    end

    it 'returns false when any element does not match' do
      result = described_class.all?([2, 3, 4], concurrency: 2, &:even?)
      expect(result).to be false
    end

    it 'returns true for empty collection' do
      result = described_class.all?([], concurrency: 2) { |_| false }
      expect(result).to be true
    end

    it 'falls back to sequential when concurrency is 1' do
      result = described_class.all?([2, 4, 6], concurrency: 1, &:even?)
      expect(result).to be true
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

  describe '.partition' do
    it 'returns [truthy, falsy] arrays preserving input order' do
      truthy, falsy = described_class.partition([1, 2, 3, 4, 5, 6], concurrency: 3, &:even?)
      expect(truthy).to eq([2, 4, 6])
      expect(falsy).to eq([1, 3, 5])
    end

    it 'returns two empty arrays for an empty input' do
      expect(described_class.partition([], concurrency: 4) { |_| true }).to eq([[], []])
    end

    it 'places everything in the truthy bucket when all elements match' do
      expect(described_class.partition([1, 2, 3], concurrency: 2) { |_| true }).to eq([[1, 2, 3], []])
    end

    it 'places everything in the falsy bucket when nothing matches' do
      expect(described_class.partition([1, 2, 3], concurrency: 2) { |_| false }).to eq([[], [1, 2, 3]])
    end

    it 'falls back to sequential partition when concurrency <= 1' do
      expect(described_class.partition([1, 2, 3, 4], concurrency: 1, &:odd?)).to eq([[1, 3], [2, 4]])
    end

    it 'preserves order even when block durations vary' do
      collection = (1..10).to_a
      truthy, falsy = described_class.partition(collection, concurrency: 4) do |n|
        sleep(0.01) if n.odd?
        n.even?
      end
      expect(truthy).to eq([2, 4, 6, 8, 10])
      expect(falsy).to eq([1, 3, 5, 7, 9])
    end
  end
end
