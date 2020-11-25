require "ffi"
require "descriptive_statistics"
require "benchmark"
require "terminal-table"

module SimdStatistics
  extend FFI::Library
  ffi_lib "./ext/build/lib.so"
  attach_function :descriptive_statistics, [:pointer, :pointer, :pointer, :pointer, :ulong], :pointer
  attach_function :free_stats, [:pointer], :void

  class StatsResult < FFI::Struct
    layout :statistics, :pointer

    def to_a
      (0..3).map do |i|
        SimdStatistics::Stats.new(self[:statistics] + i * SimdStatistics::Stats.size).to_h
      end.reverse
    end
  end

  class Stats < FFI::Struct
    layout :mean, :float,
           :min, :float,
           :max, :float,
           :variance, :float,
           :standard_deviation, :float

    def to_h
      {
        mean: self[:mean],
        min: self[:min],
        max: self[:max],
        variance: self[:variance],
        standard_deviation: self[:standard_deviation]
      }
    end
  end
end

def test_native(data, length)
  results_ptr = SimdStatistics.descriptive_statistics(data[0], data[1], data[2], data[3], length)
  SimdStatistics::StatsResult.new(results_ptr)
end

def test_ruby(data, length)
  data.map do |values|
    values.descriptive_statistics.slice(:mean, :min, :max, :variance, :standard_deviation)
  end
end

def generate_ruby_data(length)
  ruby_data = (0..3).map { (0..(length - 1)).map { rand } }
end

def generate_native_data(ruby_data)
  ruby_data.map do |arr|
    ptr =  FFI::MemoryPointer.new(:float, arr.length)
    ptr.put_array_of_float(0, arr)
    ptr
  end
end

def print_results(title, results, precision = 7)
  headers = results[0].keys
  values = results.map {|r| r.values.map { |v| "%.#{precision}f" % v }}
  table = Terminal::Table.new :headings => headers, :rows => values
  puts title + ":"
  puts table
end

class TestFailure < StandardError; end
def assert_values_within_delta(expected, actual, delta = 1e-7)
  expected.each_with_index do |result, i|
    actual_result = actual[i]
    result.each do |k, v|
      raise TestFailure.new("Results don't match!") unless (actual_result[k] - result[k]).abs < delta
    end
  end
  true
end

def format_number(number)
  number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
end

comparison_count = 10
puts "Comparing calculated statistics with #{format_number(comparison_count)} values..."

begin
  ruby_data = generate_ruby_data(comparison_count)
  native_data = generate_native_data(ruby_data)
  ruby_results = test_ruby(ruby_data, comparison_count)
  native_results = test_native(native_data, comparison_count)

  precision = 7
  print_results "Ruby", ruby_results, precision
  print_results "Simd", native_results.to_a, precision
  if assert_values_within_delta ruby_results, native_results.to_a, 10**(-precision)
    puts "Test passed, results are equal to #{precision} decimal places!"
    puts
  end
rescue TestFailure => e
  puts "Test results did not match!"
  exit(1)
ensure
  SimdStatistics.free_stats(native_results)
end

benchmark_count = 1_000_000
puts "Benchmarking with #{format_number(benchmark_count)} values..."
ruby_data = generate_ruby_data(benchmark_count)

Benchmark.bmbm do |x|
  x.report "Ruby" do
    test_ruby(ruby_data, benchmark_count)
  end

  x.report "Simd" do
    # Include Ruby -> C array conversion time (for a fair benchmark comparison)
    native_data = generate_native_data(ruby_data)
    native_results = test_native(native_data, benchmark_count)
  ensure
    SimdStatistics.free_stats(native_results)
  end
end
