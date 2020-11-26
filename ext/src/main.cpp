#include <cstdio>
#include "lib.cpp"

int main(void) {
  float** values = (float**)malloc(4 * sizeof(float*));
  float values0[] = {1.0, 3.0, 3.0, 4.0};
  float values1[] = {1.0, 4.0, 3.0, 4.0};
  float values2[] = {1.0, 5.0, 3.0, 4.0};
  float values3[] = {1.0, 6.0, 3.0, 4.0};
  values[0] = values0;
  values[1] = values1;
  values[2] = values2;
  values[3] = values3;

  StatsResult* result = descriptive_statistics_simd(values, 4, 4);
  for (size_t i = 0; i < 4; i++) {
    printf("mean: %.2f\t min: %.2f\t max: %.2f\t variance: %.2f\t stdev: %2.f\n",
        result->statistics[i].mean,
        result->statistics[i].min,
        result->statistics[i].max,
        result->statistics[i].variance,
        result->statistics[i].standard_deviation);
  }
  
  free(values);
  free_stats(result);
}
