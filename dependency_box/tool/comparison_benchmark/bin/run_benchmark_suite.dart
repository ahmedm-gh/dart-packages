import 'dart:io';

import 'package:comparison_benchmark/comparison_benchmark.dart';

Future<void> main(List<String> args) async {
  var sampleCount = 20;
  var mode = 'JIT';
  var isSmoke = false;
  String? filterId;
  var outputDir = 'results';

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--smoke') {
      isSmoke = true;
    } else if (arg == '--samples' && i + 1 < args.length) {
      sampleCount = int.tryParse(args[++i]) ?? sampleCount;
    } else if (arg == '--mode' && i + 1 < args.length) {
      mode = args[++i];
    } else if (arg == '--workload' && i + 1 < args.length) {
      filterId = args[++i];
    } else if (arg == '--output-dir' && i + 1 < args.length) {
      outputDir = args[++i];
    } else if (arg == '--help' || arg == '-h') {
      stdout.writeln('Definitive Dart DI Benchmark Suite Runner');
      stdout.writeln('Options:');
      stdout.writeln('  --smoke              Run quick smoke benchmark');
      stdout.writeln(
        '  --samples <n>        Number of independent samples (default: 20)',
      );
      stdout.writeln(
        '  --mode <JIT|AOT>     Recorded execution mode (default: JIT)',
      );
      stdout.writeln('  --workload <id>      Run a single workload by ID');
      stdout.writeln(
        '  --output-dir <path>  Directory to save results (default: results)',
      );
      exit(0);
    }
  }

  stdout.writeln(
    '================================================================================',
  );
  stdout.writeln(
    '  DEFINITIVE DART DI BENCHMARK: dependency_box vs get_it 9.3.0',
  );
  stdout.writeln(
    '  Mode: $mode | Samples: $sampleCount | Smoke: $isSmoke | Output: $outputDir',
  );
  stdout.writeln(
    '  Dart SDK: ${Platform.version.split(" ").first} (${Platform.operatingSystem})',
  );
  stdout.writeln(
    '================================================================================\n',
  );

  final adapters = <BenchmarkAdapter>[DependencyBoxAdapter(), GetItAdapter()];

  final options = BenchmarkOptions(
    sampleCount: sampleCount,
    executionMode: mode,
    isSmoke: isSmoke,
    filterWorkloadId: filterId,
  );

  final runner = BenchmarkSuiteRunner(adapters: adapters, options: options);

  final sw = Stopwatch()..start();
  final results = await runner.runSuite(
    onProgress: (msg) => stdout.writeln(msg),
  );
  sw.stop();

  stdout.writeln('\nBenchmark completed in ${sw.elapsed.inSeconds} seconds.');
  stdout.writeln('Exporting results to $outputDir...');

  await runner.exportResults(results: results, outputDir: outputDir);

  stdout.writeln('All results exported successfully:');
  stdout.writeln('  - $outputDir/raw_samples.json');
  stdout.writeln('  - $outputDir/aggregated_results.json');
  stdout.writeln('  - $outputDir/results.csv');
  stdout.writeln('  - $outputDir/BENCHMARK_REPORT.md\n');
}
