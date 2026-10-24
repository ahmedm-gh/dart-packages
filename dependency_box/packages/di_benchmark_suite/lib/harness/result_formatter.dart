import 'dart:convert';
import 'dart:io';
import 'benchmark_framework.dart';

class ResultFormatter {
  static void exportJson(List<BenchmarkMetric> metrics, String outputPath) {
    final file = File(outputPath);
    file.parent.createSync(recursive: true);
    final jsonString = const JsonEncoder.withIndent('  ').convert(
      metrics.map((m) => m.toJson()).toList(),
    );
    file.writeAsStringSync(jsonString);
    print('Exported JSON results to: $outputPath');
  }

  static void exportCsv(List<BenchmarkMetric> metrics, String outputPath) {
    final file = File(outputPath);
    file.parent.createSync(recursive: true);
    final buffer = StringBuffer();

    buffer.writeln(
      'Scenario,Framework,RuntimeMode,Registrations,TotalOperations,TotalElapsedMicros,MedianLatency,Unit,P95Latency,MinLatency,MaxLatency,VariabilityPercent,ThroughputOpsPerSec',
    );

    for (final m in metrics) {
      final unit = m.isMicros ? 'us' : 'ns';
      buffer.writeln(
        '"${m.scenario}","${m.framework}","${m.runtimeMode}",${m.registrations},${m.totalOperations},${m.totalElapsedMicros},${m.medianNs.toStringAsFixed(2)},"$unit",${m.p95Ns.toStringAsFixed(2)},${m.minNs.toStringAsFixed(2)},${m.maxNs.toStringAsFixed(2)},${m.variabilityPercent.toStringAsFixed(2)},${m.opsPerSec.toStringAsFixed(0)}',
      );
    }

    file.writeAsStringSync(buffer.toString());
    print('Exported CSV results to: $outputPath');
  }

  static void exportAggregateJson(
    List<AggregateProcessMetric> aggregates,
    String outputPath,
  ) {
    final file = File(outputPath);
    file.parent.createSync(recursive: true);
    final jsonString = const JsonEncoder.withIndent('  ').convert(
      aggregates.map((a) => a.toJson()).toList(),
    );
    file.writeAsStringSync(jsonString);
    print('Exported Multi-Process Aggregate JSON to: $outputPath');
  }

  static void exportAggregateCsv(
    List<AggregateProcessMetric> aggregates,
    String outputPath,
  ) {
    final file = File(outputPath);
    file.parent.createSync(recursive: true);
    final buffer = StringBuffer();

    buffer.writeln(
      'Scenario,Framework,RuntimeMode,Registrations,RunsCount,CrossRunMedian,Unit,CrossRunP95,CrossRunMean,Variance,StdDev,VariabilityPercent,MinLatency,MaxLatency,AvgThroughputOpsPerSec',
    );

    for (final a in aggregates) {
      final unit = a.isMicros ? 'us' : 'ns';
      buffer.writeln(
        '"${a.scenario}","${a.framework}","${a.runtimeMode}",${a.registrations},${a.processRunsCount},${a.acrossRunMedianNs.toStringAsFixed(2)},"$unit",${a.acrossRunP95Ns.toStringAsFixed(2)},${a.acrossRunMeanNs.toStringAsFixed(2)},${a.acrossRunVarianceNs.toStringAsFixed(4)},${a.acrossRunStdDevNs.toStringAsFixed(3)},${a.acrossRunVariabilityPercent.toStringAsFixed(2)}%,${a.minNs.toStringAsFixed(2)},${a.maxNs.toStringAsFixed(2)},${a.avgOpsPerSec.toStringAsFixed(0)}',
      );
    }

    file.writeAsStringSync(buffer.toString());
    print('Exported Multi-Process Aggregate CSV to: $outputPath');
  }

  static void printMarkdownSummary(List<BenchmarkMetric> metrics) {
    stdout.writeln(
      '\n=========================================================================================',
    );
    stdout.writeln('  BENCHMARK SUMMARY COMPARISON TABLE');
    stdout.writeln(
      '=========================================================================================\n',
    );

    final grouped = <String, Map<String, BenchmarkMetric>>{};
    for (final m in metrics) {
      grouped.putIfAbsent(m.scenario, () => {})[m.framework] = m;
    }

    stdout.writeln(
      '| Scenario | dependency_box | get_it 9.3.0 | injectable 3.0.0 | Baseline / Winner |',
    );
    stdout.writeln('|:---|:---:|:---:|:---:|:---|');

    for (final entry in grouped.entries) {
      final scenario = entry.key;
      final map = entry.value;

      final box = map['dependency_box'];
      final getIt = map['get_it'];
      final inj = map['injectable'];

      // Check if it's a baseline scenario
      if (scenario.startsWith('0') ||
          map.containsKey('baseline_raw_loop') ||
          map.containsKey('baseline_closure') ||
          map.containsKey('baseline_direct_var') ||
          map.containsKey('baseline_field_access') ||
          map.containsKey('baseline_direct')) {
        final baselineKey = map.keys
            .firstWhere((k) => k.startsWith('baseline'), orElse: () => '');
        final baselineMetric = map[baselineKey];
        final val = baselineMetric != null
            ? '${baselineMetric.medianNs.toStringAsFixed(2)} ns'
            : 'N/A';
        final boxVal =
            box != null ? '${box.medianNs.toStringAsFixed(2)} ns' : '-';
        final giVal =
            getIt != null ? '${getIt.medianNs.toStringAsFixed(2)} ns' : '-';
        stdout.writeln(
            '| $scenario | $boxVal | $giVal | - | **Baseline: $val** |');
        continue;
      }

      final unit = (box?.isMicros ?? false) ? 'µs' : 'ns';

      final boxStr =
          box != null ? '${box.medianNs.toStringAsFixed(2)} $unit' : 'N/A';
      final getItStr =
          getIt != null ? '${getIt.medianNs.toStringAsFixed(2)} $unit' : 'N/A';
      final injStr =
          inj != null ? '${inj.medianNs.toStringAsFixed(2)} $unit' : '-';

      String winner = 'Comparable';
      if (box != null && getIt != null) {
        if (box.medianNs < getIt.medianNs) {
          final ratio = getIt.medianNs / box.medianNs;
          final pct =
              ((getIt.medianNs - box.medianNs) / getIt.medianNs) * 100.0;
          winner =
              '**dependency_box ${ratio.toStringAsFixed(2)}x faster** (-${pct.toStringAsFixed(1)}%)';
        } else if (getIt.medianNs < box.medianNs) {
          final ratio = box.medianNs / getIt.medianNs;
          winner = 'get_it ${ratio.toStringAsFixed(2)}x faster';
        }
      }

      stdout.writeln(
        '| $scenario | **$boxStr** | $getItStr | $injStr | $winner |',
      );
    }
    stdout.writeln('');
  }

  static void printMultiProcessAggregateTable(
    List<AggregateProcessMetric> aggregates,
  ) {
    stdout.writeln(
      '\n=========================================================================================',
    );
    stdout.writeln(
        '  MULTI-PROCESS CROSS-RUN STATISTICAL TABLE (FRESH PROCESS ISOLATION)');
    stdout.writeln(
      '=========================================================================================\n',
    );

    stdout.writeln(
      '| Scenario | Framework | Runs | Cross-Run Median | Cross-Run P95 | Variance (σ²) | Std Dev (σ) | CV (%) | Winner / Comparison |',
    );
    stdout.writeln('|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---|');

    final grouped = <String, Map<String, AggregateProcessMetric>>{};
    for (final a in aggregates) {
      grouped.putIfAbsent(a.scenario, () => {})[a.framework] = a;
    }

    for (final entry in grouped.entries) {
      final scenario = entry.key;
      final map = entry.value;

      final box = map['dependency_box'];
      final getIt = map['get_it'];

      for (final f in map.values) {
        final unit = f.isMicros ? 'µs' : 'ns';
        String comp = '-';
        if (f.framework == 'dependency_box' && getIt != null) {
          final ratio = getIt.acrossRunMedianNs / f.acrossRunMedianNs;
          comp = '**${ratio.toStringAsFixed(2)}x faster than get_it**';
        } else if (f.framework == 'get_it' && box != null) {
          comp = 'Baseline reference';
        } else if (f.framework == 'injectable' && getIt != null) {
          final diff = f.acrossRunMedianNs - getIt.acrossRunMedianNs;
          comp =
              'Delegates to get_it (overhead: ${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(2)} $unit)';
        } else if (f.framework.startsWith('baseline')) {
          comp = 'Theoretical baseline bound';
        }

        stdout.writeln(
          '| $scenario | `${f.framework}` | ${f.processRunsCount} | **${f.acrossRunMedianNs.toStringAsFixed(2)} $unit** | ${f.acrossRunP95Ns.toStringAsFixed(2)} $unit | ${f.acrossRunVarianceNs.toStringAsFixed(3)} | ±${f.acrossRunStdDevNs.toStringAsFixed(2)} $unit | ${f.acrossRunVariabilityPercent.toStringAsFixed(1)}% | $comp |',
        );
      }
    }
    stdout.writeln('');
  }
}
