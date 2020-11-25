#include <xmmintrin.h>
#include <float.h>

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

  StatsResult* descriptive_statistics(float* values0, float* values1, float* values2, float* values3, size_t len);
  void free_stats(StatsResult* stats);
}

