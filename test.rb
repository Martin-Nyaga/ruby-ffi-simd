require "ffi"
require "benchmark/ips"
require "terminal-table"
require "descriptive_statistics"

module NativeStatistics
  extend FFI::Library
  ffi_lib "./ext/build/lib.so"
  attach_function :descriptive_statistics, [:pointer, :ulong, :ulong], :pointer
  attach_function :descriptive_statistics_simd, [:pointer, :ulong, :ulong], :pointer
  attach_function :free_stats, [:pointer], :void

  class StatsResult < FFI::Struct
    layout :statistics, :pointer

    def to_a
      (0..3).map do |i|
        NativeStatistics::Stats.new(self[:statistics] + i * NativeStatistics::Stats.size).to_h
      end
    end
  end

  class Stats < FFI::Struct
    layout(
      :mean,
      :float,
      :min,
      :float,
      :max,
      :float,
      :variance,
      :float,
      :standard_deviation,
      :float
    )

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

module RubyStatistics
  def self.descriptive_statistics(arr, length)
    min = Float::INFINITY
    max = -Float::INFINITY
    sum = 0

    arr.each do |x|
      min = x if x < min
      max = x if x > max
      sum += x
    end

    mean = sum / length
    variance = arr.inject(0) { |var, x| var += ((x - mean) ** 2) / length }
    standard_deviation = Math.sqrt(variance)
    {mean: mean, min: min, max: max, variance: variance, standard_deviation: standard_deviation}
  end
end

def test_native(data, variables, length)
  results_ptr = NativeStatistics.descriptive_statistics(data, variables, length)
  NativeStatistics::StatsResult.new(results_ptr)
end

def test_native_simd(data, variables, length)
  results_ptr = NativeStatistics.descriptive_statistics_simd(data, variables, length)
  NativeStatistics::StatsResult.new(results_ptr)
end

def test_ruby_custom(data)
  data.map do |values|
    RubyStatistics.descriptive_statistics(values, values.length)
  end
end

def test_ruby_descriptive_statistics(data)
  data.map do |arr|
    {mean: arr.mean, min: arr.min, max: arr.max, variance: arr.variance, standard_deviation: arr.standard_deviation}
  end
end

def generate_ruby_data(length)
  ruby_data = (0..3).map { (0..(length - 1)).map { rand } }
end

def generate_native_data(ruby_data)
  pointer = FFI::MemoryPointer.new(:pointer, ruby_data.length)

  pointer_objects = ruby_data.map.with_index do |arr, i|
    ptr = FFI::MemoryPointer.new(:float, arr.length)
    ptr.put_array_of_float(0, arr)
    ptr
  end

  pointer.put_array_of_pointer(0, pointer_objects)
  pointer
end

def print_results(title, results, precision)
  headers = results[0].keys
  values = results.map { |r| r.values.map { |v| "%.#{precision}f" % v } }
  table = Terminal::Table.new(:headings => headers, :rows => values)
  puts(title + ":")
  puts(table)
end

class TestFailure < StandardError
end

def assert_values_within_delta(values, delta)
  values.each_cons(2) do |expected, actual|
    expected.each_with_index do |result, i|
      actual_result = actual[i]

      result.each do |k, v|
        raise TestFailure.new("Results don't match!") unless (actual_result[k] - result[k]).abs < delta
      end
    end
  end

  true
end

def format_number(number)
  number.to_s.reverse.gsub(/(\d{3})(?=\d)/, "\\1,").reverse
end

def compare(comparison_count = 10, precision = 6)
  puts("Comparing calculated statistics with #{format_number(comparison_count)} values...")

  ruby_data = generate_ruby_data(comparison_count)
  native_data = generate_native_data(ruby_data)
  native_data_simd = generate_native_data(ruby_data)

  ruby_custom_results = test_ruby_custom(ruby_data)
  ruby_desc_results = test_ruby_descriptive_statistics(ruby_data)
  native_results = test_native(native_data, ruby_data.length, comparison_count)
  native_simd_results = test_native_simd(native_data_simd, ruby_data.length, comparison_count)

  print_results("Ruby (Custom)", ruby_custom_results, precision)
  print_results("Ruby (Desc Stats)", ruby_desc_results, precision)
  print_results("Native", native_results.to_a, precision)
  print_results("Native (Simd)", native_simd_results.to_a, precision)

  results = [
    ruby_custom_results,
    ruby_desc_results,
    native_results.to_a,
    native_simd_results.to_a
  ]

  if assert_values_within_delta(results, 10 ** (-precision))
    puts("Test passed, results are equal to #{precision} decimal places!")
    puts
  end

rescue TestFailure => e
  puts("Test results did not match!")
  exit(1)
ensure
  NativeStatistics.free_stats(native_results) if native_results
  NativeStatistics.free_stats(native_simd_results) if native_simd_results
end

def benchmark(benchmark_count = 100_000)
  puts("Benchmarking with #{format_number(benchmark_count)} values...")
  ruby_data = generate_ruby_data(benchmark_count)

  Benchmark.ips do |x|
    x.config(warmup: 5)

    x.report("Ruby (Desc Stats)") do
      test_ruby_descriptive_statistics(ruby_data)
    end

    x.report("Ruby (Custom)") do
      test_ruby_custom(ruby_data)
    end

    x.report("Native") do
      # Include Ruby -> C array conversion time (for a fair benchmark comparison)
      native_data = generate_native_data(ruby_data)
      native_results = test_native(native_data, ruby_data.length, benchmark_count)
    ensure
      NativeStatistics.free_stats(native_results) if native_results
    end

    x.report("Native (Simd)") do
      # Include Ruby -> C array conversion time (for a fair benchmark comparison)
      native_data = generate_native_data(ruby_data)
      native_results = test_native_simd(native_data, ruby_data.length, benchmark_count)
    ensure
      NativeStatistics.free_stats(native_results) if native_results
    end

    x.compare!
  end
end

compare
benchmark
