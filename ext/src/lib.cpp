#include "lib.h"

// Calculate descriptive statistics on 4 arrays in parallel using SSE2
// instructions
extern "C" StatsResult* descriptive_statistics_simd(float** values, size_t dimension_0, size_t dimension_1)
{
  StatsResult *result = (StatsResult*)malloc(sizeof(StatsResult));
  result->statistics = (Stats *)malloc(dimension_0 * sizeof(Stats));

  for (size_t j = 0; j < dimension_0; j+= 4) {
    __m128 sums = _mm_setzero_ps();
    __m128 means = _mm_setzero_ps();
    __m128 mins = _mm_set_ps1(FLT_MAX);
    __m128 maxes = _mm_set_ps1(FLT_MIN);
    __m128 variances = _mm_setzero_ps();
    __m128 standard_deviations = _mm_setzero_ps();
    __m128 lengths = _mm_set_ps1((float) dimension_1);

    for (size_t i = 0; i < dimension_1; i++) {
      // Pack values in opposite order to maintain expected ruby order
      __m128 packed = _mm_set_ps(values[j + 3][i], values[j + 2][i], values[j + 1][i], values[j][i]);
      sums = _mm_add_ps(sums, packed);
      mins = _mm_min_ps(mins, packed);
      maxes = _mm_max_ps(maxes, packed);
    }
    means = _mm_div_ps(sums, lengths);

    for (size_t i = 0; i < dimension_1; i++) {
      // Pack values in opposite order to maintain expected ruby order
      __m128 packed = _mm_set_ps(values[j + 3][i], values[j + 2][i], values[j + 1][i], values[j][i]);
      __m128 deviation = _mm_sub_ps(packed, means);
      __m128 sqr_deviation = _mm_mul_ps(deviation, deviation);
      variances = _mm_add_ps(variances, _mm_div_ps(sqr_deviation, lengths));
    }
    standard_deviations = _mm_sqrt_ps(variances);

    for (size_t i = 0; i < dimension_0; i++) {
      result->statistics[i] = Stats {
        ((float*)&means)[i],
        ((float*)&mins)[i],
        ((float*)&maxes)[i],
        ((float*)&variances)[i],
        ((float*)&standard_deviations)[i]
      };
    }
  }

  return result;
}

extern "C" StatsResult* descriptive_statistics(float** values, size_t dimension_0, size_t dimension_1)
{
  StatsResult *result = (StatsResult*)malloc(sizeof(StatsResult));
  result->statistics = (Stats *)malloc(dimension_0 * sizeof(Stats));

  for (size_t j = 0; j < dimension_0; j++) {
    float sum = 0;
    float min = FLT_MAX;
    float max = FLT_MIN;

    for (size_t i = 0; i < dimension_1; i++) {
      float value = values[j][i];
      sum += value;
      if (value < min) min = value;
      if (value > max) max = value;
    }
    float mean = sum / dimension_1;
    float variance = 0;
    for (size_t i = 0; i < dimension_1; i++) {
      float value = values[j][i];
      float deviation = value - mean;
      float sqr_deviation = deviation * deviation;
      variance += (sqr_deviation / dimension_1);
    }
    float standard_deviation = sqrt(variance);

    result->statistics[j] = Stats {
      mean,
      min,
      max,
      variance,
      standard_deviation
    };
  }

  return result;
}

extern "C" void free_stats(StatsResult* stats)
{
  free(stats->statistics);
  free(stats);
}
