#include "lib.h"

// Calculate descriptive statistics on 4 arrays in parallel using SSE2
// instructions
extern "C" StatsResult* descriptive_statistics(float* values0, float* values1, float* values2, float* values3, size_t len) {
  __m128 sums = _mm_setzero_ps();
  __m128 means = _mm_setzero_ps();
  __m128 mins = _mm_set_ps1(FLT_MAX);
  __m128 maxes = _mm_set_ps1(FLT_MIN);
  __m128 variances = _mm_setzero_ps();
  __m128 standard_deviations = _mm_setzero_ps();
  __m128 lengths = _mm_set_ps1((float) len);


  for (size_t i = 0; i < len; i++) {
    __m128 packed = _mm_set_ps(*(values0 + i), *(values1 + i), *(values2 + i), *(values3 + i));
    sums = _mm_add_ps(sums, packed);
    mins = _mm_min_ps(mins, packed);
    maxes = _mm_max_ps(maxes, packed);
  }
  means = _mm_div_ps(sums, lengths);

  for (size_t i = 0; i < len; i++) {
    __m128 packed = _mm_set_ps(*(values0 + i), *(values1 + i), *(values2 + i), *(values3 + i));
    __m128 deviation = _mm_sub_ps(packed, means);
    __m128 sqr_deviation = _mm_mul_ps(deviation, deviation);
    variances = _mm_add_ps(variances, _mm_div_ps(sqr_deviation, lengths));
  }
  standard_deviations = _mm_sqrt_ps(variances);

  StatsResult *result = (StatsResult*)malloc(sizeof(StatsResult));
  result->statistics = (Stats *)malloc(4 * sizeof(Stats));

  float* means_f32 = (float*)malloc(4*sizeof(float));
  _mm_store_ps(means_f32, means);
  float* mins_f32 = (float*)malloc(4*sizeof(float));
  _mm_store_ps(mins_f32, mins);
  float* maxes_f32 = (float*)malloc(4*sizeof(float));
  _mm_store_ps(maxes_f32, maxes);
  float* variances_f32 = (float*)malloc(4*sizeof(float));
  _mm_store_ps(variances_f32, variances);
  float* standard_deviations_f32 = (float*)malloc(4*sizeof(float));
  _mm_store_ps(standard_deviations_f32, standard_deviations);


  for (size_t i = 0; i < 4; i++) {
    result->statistics[i] = Stats {
      means_f32[i],
      mins_f32[i],
      maxes_f32[i],
      variances_f32[i],
      standard_deviations_f32[i]
    };
  }

  free(means_f32);
  free(mins_f32);
  free(maxes_f32);
  free(variances_f32);
  free(standard_deviations_f32);

  return result;
}

extern "C" void free_stats(StatsResult* stats) {
  free(stats->statistics);
  free(stats);
}
