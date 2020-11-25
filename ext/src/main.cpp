#include <cstdio>
#include "lib.cpp"

// Basic test for simd sum function
int main(void) {
  float values0[] = {1.0, 3.0, 3.0, 4.0};
  float values1[] = {1.0, 4.0, 3.0, 4.0};
  float values2[] = {1.0, 5.0, 3.0, 4.0};
  float values3[] = {1.0, 6.0, 3.0, 4.0};

  StatsResult* result = descriptive_statistics(values0, values1, values2, values3, 4);
  for (size_t i = 0; i < 4; i++) {
    printf("mean: %.2f\t min: %.2f\t max: %.2f\t variance: %.2f\t stdev: %2.f\n",
        result->statistics[i].mean,
        result->statistics[i].min,
        result->statistics[i].max,
        result->statistics[i].variance,
        result->statistics[i].standard_deviation);
  }
  
  free_stats(result);
}
