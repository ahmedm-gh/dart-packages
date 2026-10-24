import 'dart:convert';
import 'dart:io';
import 'package:di_benchmark_suite/harness/benchmark_framework.dart';
import 'package:di_benchmark_suite/harness/result_formatter.dart';

void main(List<String> args) async {
  final isAot = args.contains('--aot');
  final mode = isAot ? 'AOT' : 'JIT';

  var runsCount = 5;
  final runsIndex = args.indexOf('--runs');
  if (runsIndex != -1 && runsIndex + 1 < args.length) {
    runsCount = int.tryParse(args[runsIndex + 1]) ?? 5;
  }

  stdout.writeln(
      '=========================================================================================');
  stdout.writeln('  MULTI-PROCESS BENCHMARK ORCHESTRATOR');
  stdout.writeln('  Mode:           $mode');
  stdout.writeln('  Total Fresh Runs: $runsCount independent OS processes');
  stdout.writeln(
      '  Dart SDK:       ${Platform.version.split(' ').first} (${Platform.operatingSystem})');
  stdout.writeln(
      '=========================================================================================\n');

  String executable;
  List<String> baseArgs;

  if (isAot) {
    stdout.writeln('Compiling native AOT executable for fresh process runs...');
    final compileResult = await Process.run(
      'dart',
      ['compile', 'exe', 'bin/run_benchmarks.dart', '-o', 'bin/bench_aot.exe'],
    );
    if (compileResult.exitCode != 0) {
      stderr.writeln('AOT compilation failed:\n${compileResult.stderr}');
      exit(1);
    }
    executable = 'bin/bench_aot.exe';
    baseArgs = ['--aot', '--child'];
  } else {
    executable = 'dart';
    baseArgs = ['run', 'bin/run_benchmarks.dart', '--child'];
  }

  final allRunsMetrics = <List<BenchmarkMetric>>[];
  final tempDir = Directory('results/temp_runs');
  tempDir.createSync(recursive: true);

  for (var r = 1; r <= runsCount; r++) {
    final runOutFile = 'results/temp_runs/run_${mode.toLowerCase()}_$r.json';
    stdout.write('Executing fresh process run $r / $runsCount ... ');

    final processArgs = [...baseArgs, '--out', runOutFile];
    final sw = Stopwatch()..start();
    final result = await Process.run(executable, processArgs);
    sw.stop();

    if (result.exitCode != 0) {
      stdout.writeln('[FAILED]');
      stderr.writeln(result.stderr);
      exit(1);
    }

    final file = File(runOutFile);
    if (!file.existsSync()) {
      stdout.writeln('[FAILED: No output file]');
      exit(1);
    }

    final jsonContent = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    final runMetrics = jsonContent
        .map((j) => BenchmarkMetric.fromJson(j as Map<String, dynamic>))
        .toList();
    allRunsMetrics.add(runMetrics);

    stdout.writeln(
        '[DONE in ${(sw.elapsedMilliseconds / 1000.0).toStringAsFixed(1)}s]');
  }

  // Aggregate results across runs
  final scenariosMap = <String, Map<String, List<BenchmarkMetric>>>{};

  for (final run in allRunsMetrics) {
    for (final m in run) {
      scenariosMap
          .putIfAbsent(m.scenario, () => {})
          .putIfAbsent(m.framework, () => [])
          .add(m);
    }
  }

  final aggregateMetrics = <AggregateProcessMetric>[];

  for (final scenarioEntry in scenariosMap.entries) {
    for (final frameworkEntry in scenarioEntry.value.entries) {
      final list = frameworkEntry.value;
      aggregateMetrics.add(AggregateProcessMetric.aggregate(list));
    }
  }

  // Print Summary Table
  ResultFormatter.printMultiProcessAggregateTable(aggregateMetrics);

  // Export JSON & CSV
  final jsonPath = 'results/multi_process_${mode.toLowerCase()}.json';
  final csvPath = 'results/multi_process_${mode.toLowerCase()}.csv';
  ResultFormatter.exportAggregateJson(aggregateMetrics, jsonPath);
  ResultFormatter.exportAggregateCsv(aggregateMetrics, csvPath);

  // Clean up temp runs and AOT binary
  try {
    tempDir.deleteSync(recursive: true);
  } catch (_) {}

  if (isAot) {
    try {
      File('bin/bench_aot.exe').deleteSync();
      stdout.writeln('Cleaned up compiled AOT binary bin/bench_aot.exe');
    } catch (_) {}
  }

  stdout.writeln(
      '\nMulti-process benchmarking finished successfully across $runsCount independent runs!');
}
