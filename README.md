## Ruby FFI and SIMD instructions 

Exploring how to do some basic FFI in ruby using [Ruby
FFI](https://github.com/ffi/ffi), as well as how [SIMD
instructions](https://en.wikipedia.org/wiki/SIMD) work. Testing with some basic
calculations, the results are pretty interesting!

- Ruby FFI makes calling into C code really easy; much easier than writing Ruby
  C extensions.
- The resulting C code is much faster. Granted, the ruby implementation based on
  `descriptive_statistics` is not very performant and could be improved a lot,
  but it does not compare with what can be achieve through SIMD.

#### Tests and Benchmark

```
Comparing calculated statistics with 10 values...
Ruby:
+-----------+-----------+-----------+-----------+--------------------+
| mean      | min       | max       | variance  | standard_deviation |
+-----------+-----------+-----------+-----------+--------------------+
| 0.5804351 | 0.0687393 | 0.9394778 | 0.0498613 | 0.2232964          |
| 0.5009497 | 0.0662217 | 0.8502424 | 0.0371614 | 0.1927729          |
| 0.3576839 | 0.0743144 | 0.6811809 | 0.0464864 | 0.2156070          |
| 0.6475030 | 0.0099109 | 0.9200629 | 0.0904033 | 0.3006713          |
+-----------+-----------+-----------+-----------+--------------------+
Simd:
+-----------+-----------+-----------+-----------+--------------------+
| mean      | min       | max       | variance  | standard_deviation |
+-----------+-----------+-----------+-----------+--------------------+
| 0.5804350 | 0.0687393 | 0.9394777 | 0.0498613 | 0.2232964          |
| 0.5009497 | 0.0662217 | 0.8502424 | 0.0371614 | 0.1927729          |
| 0.3576839 | 0.0743144 | 0.6811809 | 0.0464864 | 0.2156070          |
| 0.6475030 | 0.0099109 | 0.9200628 | 0.0904033 | 0.3006713          |
+-----------+-----------+-----------+-----------+--------------------+
Test passed, results are equal to 7 decimal places!

Benchmarking with 1,000,000 values...
Rehearsal ----------------------------------------
Ruby  10.119025   0.090076  10.209101 ( 10.209152)
Simd   0.037891   0.000000   0.037891 (  0.037893)
------------------------------ total: 10.246992sec

           user     system      total        real
Ruby  11.238048   0.009948  11.247996 ( 11.248054)
Simd   0.038782   0.000027   0.038809 (  0.038808)

```
