import 'dart:math' as math;

/// Statistical summary of independent benchmark sample measurements.
class BenchmarkSampleSeries {
  final String name;
  final int operationsPerSample;
  final List<double> rawNanosecondsPerOp;

  BenchmarkSampleSeries({
    required this.name,
    required this.operationsPerSample,
    required List<double> samples,
  }) : rawNanosecondsPerOp = List.unmodifiable(_validateAndSort(samples));

  static List<double> _validateAndSort(List<double> samples) {
    if (samples.isEmpty) {
      throw ArgumentError('Sample series cannot be empty.');
    }
    for (final s in samples) {
      if (s.isNaN || s.isInfinite || s <= 0.0) {
        throw ArgumentError(
          'Invalid measurement sample ($s). Must be a positive finite number.',
        );
      }
    }
    final sorted = List<double>.from(samples)..sort();
    return sorted;
  }

  int get sampleCount => rawNanosecondsPerOp.length;

  double get min => rawNanosecondsPerOp.first;
  double get max => rawNanosecondsPerOp.last;

  double get mean {
    final sum = rawNanosecondsPerOp.fold<double>(0.0, (a, b) => a + b);
    return sum / sampleCount;
  }

  double get median => percentile(0.50);

  double get p90 => percentile(0.90);
  double get p95 => percentile(0.95);
  double get q1 => percentile(0.25);
  double get q3 => percentile(0.75);
  double get iqr => q3 - q1;

  double get variance {
    if (sampleCount <= 1) return 0.0;
    final m = mean;
    final sumOfSquares = rawNanosecondsPerOp.fold<double>(
      0.0,
      (acc, val) => acc + math.pow(val - m, 2),
    );
    return sumOfSquares / (sampleCount - 1);
  }

  double get standardDeviation => math.sqrt(variance);

  /// 95% Confidence Interval for the mean using Student's t critical approximation.
  (double, double) get confidenceInterval95 {
    if (sampleCount <= 1) return (mean, mean);
    // Approximate t critical value for 95% CI (df ~ 20-30 -> t ~ 2.042 - 2.086)
    final df = sampleCount - 1;
    final tCrit = _studentTCritical95(df);
    final standardError = standardDeviation / math.sqrt(sampleCount);
    final margin = tCrit * standardError;
    return (math.max(0.0, mean - margin), mean + margin);
  }

  /// Calculates percentile using linear interpolation between closest ranks.
  double percentile(double p) {
    if (p < 0.0 || p > 1.0) {
      throw ArgumentError('Percentile p must be between 0.0 and 1.0');
    }
    if (sampleCount == 1) return rawNanosecondsPerOp.first;
    final index = p * (sampleCount - 1);
    final lower = index.floor();
    final upper = index.ceil();
    if (lower == upper) return rawNanosecondsPerOp[lower];
    final weight = index - lower;
    return rawNanosecondsPerOp[lower] * (1.0 - weight) +
        rawNanosecondsPerOp[upper] * weight;
  }

  Map<String, dynamic> toJson() {
    final (ciLower, ciUpper) = confidenceInterval95;
    return {
      'sample_count': sampleCount,
      'operations_per_sample': operationsPerSample,
      'min_ns_per_op': min,
      'max_ns_per_op': max,
      'mean_ns_per_op': mean,
      'median_ns_per_op': median,
      'std_dev_ns': standardDeviation,
      'q1_ns': q1,
      'q3_ns': q3,
      'iqr_ns': iqr,
      'p90_ns': p90,
      'p95_ns': p95,
      'ci_95_lower_ns': ciLower,
      'ci_95_upper_ns': ciUpper,
      'raw_samples': rawNanosecondsPerOp,
    };
  }

  static double _studentTCritical95(int df) {
    if (df <= 1) return 12.706;
    if (df == 2) return 4.303;
    if (df == 3) return 3.182;
    if (df == 4) return 2.776;
    if (df == 5) return 2.571;
    if (df == 10) return 2.228;
    if (df == 15) return 2.131;
    if (df == 20) return 2.086;
    if (df <= 25) return 2.064;
    if (df <= 30) return 2.042;
    if (df <= 60) return 2.000;
    if (df <= 120) return 1.980;
    return 1.960;
  }
}

/// Head-to-head comparison between a candidate implementation and a baseline.
class BenchmarkComparison {
  final String scenario;
  final String baselineName;
  final String candidateName;
  final BenchmarkSampleSeries baseline;
  final BenchmarkSampleSeries candidate;

  BenchmarkComparison({
    required this.scenario,
    required this.baselineName,
    required this.candidateName,
    required this.baseline,
    required this.candidate,
  });

  /// Speedup ratio: baseline_ns / candidate_ns.
  /// > 1.0 means candidate is faster than baseline.
  double get speedupRatio => baseline.median / candidate.median;

  /// Absolute time difference in nanoseconds per op (positive means candidate is faster).
  double get absoluteDifferenceNs => baseline.median - candidate.median;

  /// Percent improvement: ((baseline - candidate) / baseline) * 100.
  double get percentageImprovement =>
      ((baseline.median - candidate.median) / baseline.median) * 100.0;

  /// 95% CI for the speedup ratio calculated via Fieller's / ratio propagation approximation.
  (double, double) get speedupConfidenceInterval95 {
    final meanB = baseline.mean;
    final meanC = candidate.mean;
    final varB = baseline.variance / baseline.sampleCount;
    final varC = candidate.variance / candidate.sampleCount;

    final ratioMean = meanB / meanC;
    // Delta method variance of ratio: (Var(B)/meanB^2 + Var(C)/meanC^2) * ratio^2
    final relVar = (varB / (meanB * meanB)) + (varC / (meanC * meanC));
    final ratioStdErr = ratioMean * math.sqrt(math.max(0.0, relVar));
    final margin = 1.96 * ratioStdErr;
    return (math.max(0.01, ratioMean - margin), ratioMean + margin);
  }

  Map<String, dynamic> toJson() {
    final (ciLower, ciUpper) = speedupConfidenceInterval95;
    return {
      'scenario': scenario,
      'baseline_name': baselineName,
      'candidate_name': candidateName,
      'baseline_median_ns': baseline.median,
      'candidate_median_ns': candidate.median,
      'speedup_ratio': speedupRatio,
      'speedup_direction': 'candidate_faster_when_ratio_greater_than_1',
      'absolute_diff_ns': absoluteDifferenceNs,
      'percent_improvement': percentageImprovement,
      'speedup_ci_95_lower': ciLower,
      'speedup_ci_95_upper': ciUpper,
      'baseline_stats': baseline.toJson(),
      'candidate_stats': candidate.toJson(),
    };
  }
}
