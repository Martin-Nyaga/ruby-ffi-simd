## Exploring Ruby FFI and SIMD instructions 

This repository explores how to do some basic FFI in ruby using [Ruby
FFI](https://github.com/ffi/ffi), as well as how [SIMD
instructions](https://en.wikipedia.org/wiki/SIMD) work. Using some basic
descriptive statistics as a test case, the results are pretty interesting!

- Ruby FFI makes calling into C code relatively simple. FFI lets you write C/C++
  code which exports the desired interface without really caring that it is
  called from ruby. Wrapping the native interface with FFI objects using the FFI
  DSL is a lot nicer compared to doing it directly in C with the ruby C API.
  This also applies to calling any arbitrary C/C++ libraries. In addition, being
  able to "enrich" arbitrary C structs with ruby methods directly in ruby is
  also really useful (although this is equally possible with the C API).
- On the statistics computation example here, ruby can perform reasonably well
  with well written code that can calculate multuiple statistics on every loop
  through the data. Libraries like `descriptive_statistics` don't really reuse
  previously computed statistics, and so have to re-calculate them in repeated
  loops which makes them orders of magnitude slower.
- Native code with `-O3` performing the same loop as ruby is much much faster,
  as expected. The speed up is ~25x!
- Explicitly writing the computations out using 128-bit SIMD intrinsics squeezes
  out an extra ~30% performance from the native code. This is great, but not
  really close to the theoretical 4x that you might expect. Presumably `-O3` is
  already doing quite well to optimise the generated code, so the explicit
  intrinsics don't make that big of a difference in the end. Still, 30% is a
  decent return for not too much work.

## Benchmark Results

```
Comparing calculated statistics with 10 values...
Ruby (Custom):
+----------+----------+----------+----------+--------------------+
| mean     | min      | max      | variance | standard_deviation |
+----------+----------+----------+----------+--------------------+
| 0.657200 | 0.018774 | 0.999315 | 0.098239 | 0.313432           |
| 0.494228 | 0.103677 | 0.922196 | 0.093787 | 0.306247           |
| 0.435724 | 0.071016 | 0.859478 | 0.060833 | 0.246644           |
| 0.399854 | 0.212832 | 0.711103 | 0.033990 | 0.184363           |
+----------+----------+----------+----------+--------------------+
Ruby (Desc Stats):
+----------+----------+----------+----------+--------------------+
| mean     | min      | max      | variance | standard_deviation |
+----------+----------+----------+----------+--------------------+
| 0.657200 | 0.018774 | 0.999315 | 0.098239 | 0.313432           |
| 0.494228 | 0.103677 | 0.922196 | 0.093787 | 0.306247           |
| 0.435724 | 0.071016 | 0.859478 | 0.060833 | 0.246644           |
| 0.399854 | 0.212832 | 0.711103 | 0.033990 | 0.184363           |
+----------+----------+----------+----------+--------------------+
Native:
+----------+----------+----------+----------+--------------------+
| mean     | min      | max      | variance | standard_deviation |
+----------+----------+----------+----------+--------------------+
| 0.657200 | 0.018774 | 0.999315 | 0.098239 | 0.313432           |
| 0.494228 | 0.103677 | 0.922196 | 0.093787 | 0.306247           |
| 0.435724 | 0.071016 | 0.859478 | 0.060833 | 0.246644           |
| 0.399854 | 0.212832 | 0.711103 | 0.033990 | 0.184363           |
+----------+----------+----------+----------+--------------------+
Native (Simd):
+----------+----------+----------+----------+--------------------+
| mean     | min      | max      | variance | standard_deviation |
+----------+----------+----------+----------+--------------------+
| 0.657200 | 0.018774 | 0.999315 | 0.098239 | 0.313432           |
| 0.494228 | 0.103677 | 0.922196 | 0.093787 | 0.306247           |
| 0.435724 | 0.071016 | 0.859478 | 0.060833 | 0.246644           |
| 0.399854 | 0.212832 | 0.711103 | 0.033990 | 0.184363           |
+----------+----------+----------+----------+--------------------+
Test passed, results are equal to 6 decimal places!

Benchmarking with 100,000 values...
Warming up --------------------------------------
   Ruby (Desc Stats)     1.000  i/100ms
       Ruby (Custom)     1.000  i/100ms
              Native    39.000  i/100ms
       Native (Simd)    48.000  i/100ms
Calculating -------------------------------------
   Ruby (Desc Stats)      3.404  (± 0.0%) i/s -     17.000  in   5.005342s
       Ruby (Custom)     15.779  (± 6.3%) i/s -     79.000  in   5.024171s
              Native    356.612  (± 5.6%) i/s -      1.794k in   5.046749s
       Native (Simd)    461.957  (± 5.6%) i/s -      2.304k in   5.003756s

Comparison:
       Native (Simd):      462.0 i/s
              Native:      356.6 i/s - 1.30x  (± 0.00) slower
       Ruby (Custom):       15.8 i/s - 29.28x  (± 0.00) slower
   Ruby (Desc Stats):        3.4 i/s - 135.72x  (± 0.00) slower
```
## Running the benchmark
Make sure to have `gcc` installed. Then you can run `bundle install` to install
the ruby dependecies, and `make` to run the benchmark.
