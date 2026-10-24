import 'dart:convert';
import 'dart:io';
import 'package:di_benchmark_suite/correctness/conformance_suite.dart';
import 'package:di_benchmark_suite/harness/benchmark_framework.dart';
import 'package:di_benchmark_suite/harness/result_formatter.dart';
import 'package:di_benchmark_suite/scenarios/benchmark_scenarios.dart';

void main(List<String> args) async {
  final mode = args.contains('--aot') ? 'AOT' : 'JIT';
  final isChild = args.contains('--child');
  final outIndex = args.indexOf('--out');
  final customOutPath = (outIndex != -1 && outIndex + 1 < args.length)
      ? args[outIndex + 1]
      : null;

  if (!isChild) {
    stdout.writeln(
      '=========================================================================================',
    );
    stdout.writeln('  RIGOROUS DART DEPENDENCY INJECTION BENCHMARK SUITE');
    stdout.writeln('  Runtime Mode: $mode');
    stdout.writeln(
      '  Dart SDK:     ${Platform.version.split(' ').first} (${Platform.operatingSystem} ${Platform.operatingSystemVersion})',
    );
    stdout.writeln(
      '=========================================================================================\n',
    );

    // Step 0: Timer & Harness Overhead Diagnostics
    final timerReport = HarnessDiagnostics.validateTimerOverhead();
    timerReport.printSummary();

    // Step 1: Pre-benchmark Conformance & Correctness Verification
    final correctnessPassed = await ConformanceSuite.runAllTests();
    if (!correctnessPassed) {
      stderr.writeln(
        'Pre-benchmark conformance checks failed! Aborting benchmarks.',
      );
      exit(1);
    }
  }

  // Step 2: Run All Benchmark Scenarios
  final runner = BenchmarkRunner(runtimeMode: mode);
  final suite = BenchmarkSuiteScenarios(runner: runner);

  // Scenario 0: Baselines (Empty Loop & Direct Variable)
  suite.runScenario0();

  // Multi-Scale Iteration Scaling (1e5, 1e6, 1e7, 1e8 ops)
  suite.runHotPathScalingSuite();

  // Scenarios A through G
  suite.runScenarioA();
  suite.runScenarioB();
  suite.runScenarioC();
  suite.runScenarioD();
  await suite.runScenarioE();
  suite.runScenarioF();
  suite.runScenarioG();

  // Step 3: Print and Export Results
  if (!isChild) {
    ResultFormatter.printMarkdownSummary(suite.results);
  }

  final defaultJsonPath = 'results/benchmark_${mode.toLowerCase()}.json';
  final defaultCsvPath = 'results/benchmark_${mode.toLowerCase()}.csv';

  final jsonPath = customOutPath ?? defaultJsonPath;
  ResultFormatter.exportJson(suite.results, jsonPath);

  if (!isChild) {
    ResultFormatter.exportCsv(suite.results, defaultCsvPath);
    stdout.writeln('\nBenchmark Suite Completed Successfully!');
  } else {
    // Write marker for orchestrator process
    stdout.writeln('__METRICS_JSON_START__');
    stdout.writeln(jsonEncode(suite.results.map((m) => m.toJson()).toList()));
    stdout.writeln('__METRICS_JSON_END__');
  }
}
