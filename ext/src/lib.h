#include <xmmintrin.h>
#include <float.h>
#include <math.h>

#include <cstdio>

struct Stats {
  float mean;
  float min;
  float max;
  float variance;
  float standard_deviation;
};

extern "C" {
  struct StatsResult {
    Stats* statistics;
  };

  StatsResult* descriptive_statistics_simd(float** values, size_t dimension_0, size_t dimension_1);
  StatsResult* descriptive_statistics(float** values, size_t dimension_0, size_t dimension_1);
  void free_stats(StatsResult* stats);
}

