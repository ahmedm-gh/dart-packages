import 'dart:convert';
import 'dart:io';

import 'package:comparison_benchmark/comparison_benchmark.dart';

void main(List<String> args) {
  if (args.isNotEmpty && args[0] == '--worker') {
    final library = args[1];
    final sw = Stopwatch()..start();
    final BenchmarkAdapter adapter = switch (library) {
      'dependency_box' => DependencyBoxAdapter(),
      'get_it' => GetItAdapter(),
      _ => throw ArgumentError('Unknown library: $library'),
    };
    adapter.registerRealisticGraph();
    adapter.setupRealisticGraphResolution();
    final res = adapter.resolveRealisticGraph();
    sw.stop();

    // Output elapsed microseconds
    stdout.writeln(
      jsonEncode({
        'library': library,
        'elapsed_micros': sw.elapsedMicroseconds,
        'checksum': res.hashCode,
      }),
    );
    exit(0);
  }

  // Orchestrator mode: run multiple clean processes per library
  final runsPerLib = 10;
  final libraries = ['dependency_box', 'get_it'];
  final results = <String, List<double>>{for (final lib in libraries) lib: []};

  stdout.writeln(
    '================================================================================',
  );
  stdout.writeln(
    '  COLD-START BENCHMARK (Process-Isolated Setup & 1st Resolution)',
  );
  stdout.writeln('  Runs: $runsPerLib clean processes per library');
  stdout.writeln(
    '================================================================================\n',
  );

  final scriptPath = Platform.script.toFilePath();

  for (var r = 0; r < runsPerLib; r++) {
    // Rotate order
    final rotated = [
      ...libraries.sublist(r % libraries.length),
      ...libraries.sublist(0, r % libraries.length),
    ];
    for (final lib in rotated) {
      final proc = Process.runSync(Platform.resolvedExecutable, [
        scriptPath,
        '--worker',
        lib,
      ]);
      if (proc.exitCode != 0) {
        stderr.writeln('Worker error for $lib: ${proc.stderr}');
        continue;
      }
      final out =
          jsonDecode(proc.stdout.toString().trim()) as Map<String, dynamic>;
      final micros = out['elapsed_micros'] as int;
      results[lib]!.add(micros / 1000.0); // milliseconds
    }
  }

  stdout.writeln(
    '| Library | Cold Startup (Median ms) | Mean (ms) | StdDev (ms) | Min (ms) | Max (ms) |',
  );
  stdout.writeln('| :--- | :---: | :---: | :---: | :---: | :---: |');

  for (final lib in libraries) {
    final series = BenchmarkSampleSeries(
      name: lib,
      operationsPerSample: 1,
      samples: results[lib]!,
    );
    stdout.writeln(
      '| **$lib** | **${series.median.toStringAsFixed(2)} ms** | ${series.mean.toStringAsFixed(2)} ms | ${series.standardDeviation.toStringAsFixed(2)} ms | ${series.min.toStringAsFixed(2)} ms | ${series.max.toStringAsFixed(2)} ms |',
    );
  }
  stdout.writeln();
}
