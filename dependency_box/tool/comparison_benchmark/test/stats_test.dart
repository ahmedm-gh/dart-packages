import 'package:test/test.dart';
import 'package:comparison_benchmark/src/stats/stats.dart';

void main() {
  group('Statistical Engine Tests', () {
    test('Calculates exact statistics on known dataset [10, 20, 30, 40, 50]',
        () {
      final samples = [10.0, 20.0, 30.0, 40.0, 50.0];
      final series = BenchmarkSampleSeries(
        name: 'test_series',
        operationsPerSample: 1000,
        samples: samples,
      );

      expect(series.sampleCount, equals(5));
      expect(series.min, equals(10.0));
      expect(series.max, equals(50.0));
      expect(series.mean, equals(30.0));
      expect(series.median, equals(30.0));
      expect(series.q1, equals(20.0));
      expect(series.q3, equals(40.0));
      expect(series.iqr, equals(20.0));
      expect(series.standardDeviation, closeTo(15.811, 0.001));

      final (ciLower, ciUpper) = series.confidenceInterval95;
      expect(ciLower, lessThan(30.0));
      expect(ciUpper, greaterThan(30.0));
    });

    test('Speedup ratio and direction calculation', () {
      final baseline = BenchmarkSampleSeries(
        name: 'get_it',
        operationsPerSample: 1000,
        samples: [100.0, 100.0, 100.0, 100.0, 100.0],
      );
      final candidate = BenchmarkSampleSeries(
        name: 'dependency_box',
        operationsPerSample: 1000,
        samples: [25.0, 25.0, 25.0, 25.0, 25.0],
      );

      final comparison = BenchmarkComparison(
        scenario: 'Singleton Resolution',
        baselineName: baseline.name,
        candidateName: candidate.name,
        baseline: baseline,
        candidate: candidate,
      );

      // Candidate takes 25ns, baseline takes 100ns -> 4x speedup
      expect(comparison.speedupRatio, equals(4.0));
      expect(comparison.speedupRatio > 1.0, isTrue);
      expect(comparison.absoluteDifferenceNs, equals(75.0));
      expect(comparison.percentageImprovement, equals(75.0));
    });

    test('Rejection of zero, negative, infinite, and NaN measurements', () {
      expect(
        () => BenchmarkSampleSeries(
          name: 'invalid_zero',
          operationsPerSample: 100,
          samples: [10.0, 0.0, 30.0],
        ),
        throwsArgumentError,
      );

      expect(
        () => BenchmarkSampleSeries(
          name: 'invalid_negative',
          operationsPerSample: 100,
          samples: [10.0, -5.0, 30.0],
        ),
        throwsArgumentError,
      );

      expect(
        () => BenchmarkSampleSeries(
          name: 'invalid_nan',
          operationsPerSample: 100,
          samples: [10.0, double.nan, 30.0],
        ),
        throwsArgumentError,
      );

      expect(
        () => BenchmarkSampleSeries(
          name: 'invalid_infinity',
          operationsPerSample: 100,
          samples: [10.0, double.infinity, 30.0],
        ),
        throwsArgumentError,
      );

      expect(
        () => BenchmarkSampleSeries(
          name: 'empty',
          operationsPerSample: 100,
          samples: [],
        ),
        throwsArgumentError,
      );
    });

    test('JSON serialization contains all required fields', () {
      final series = BenchmarkSampleSeries(
        name: 'serialization_test',
        operationsPerSample: 100000,
        samples: [12.5, 13.0, 12.8, 12.1, 13.5],
      );
      final json = series.toJson();

      expect(json.containsKey('sample_count'), isTrue);
      expect(json.containsKey('operations_per_sample'), isTrue);
      expect(json.containsKey('mean_ns_per_op'), isTrue);
      expect(json.containsKey('median_ns_per_op'), isTrue);
      expect(json.containsKey('std_dev_ns'), isTrue);
      expect(json.containsKey('q1_ns'), isTrue);
      expect(json.containsKey('q3_ns'), isTrue);
      expect(json.containsKey('iqr_ns'), isTrue);
      expect(json.containsKey('p90_ns'), isTrue);
      expect(json.containsKey('p95_ns'), isTrue);
      expect(json.containsKey('ci_95_lower_ns'), isTrue);
      expect(json.containsKey('ci_95_upper_ns'), isTrue);
      expect(json.containsKey('raw_samples'), isTrue);
    });
  });
}
