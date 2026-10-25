import 'dart:io';

Future<void> main(List<String> args) async {
  final isSmoke = args.contains('--smoke');
  final sampleCount = isSmoke ? '3' : '20';

  stdout.writeln(
      '================================================================================');
  stdout.writeln('  STARTING COMPREHENSIVE BENCHMARK CAMPAIGN');
  stdout.writeln(
      '  Mode: ${isSmoke ? "Smoke" : "Full Production Campaign (20 Samples)"}');
  stdout.writeln(
      '================================================================================\n');

  // Step 1: Run Conformance & Statistical Unit Tests
  stdout.writeln(
      '>>> Step 1/4: Running Conformance & Statistical Correctness Tests...');
  final testProc = await Process.run('dart', ['test']);
  stdout.writeln(testProc.stdout);
  if (testProc.exitCode != 0) {
    stderr.writeln(testProc.stderr);
    exit(testProc.exitCode);
  }

  // Step 2: Run Full JIT Benchmark Campaign
  stdout.writeln(
      '>>> Step 2/4: Running JIT Benchmark Campaign ($sampleCount samples per case)...');
  final jitArgs = [
    'run',
    'bin/run_benchmark_suite.dart',
    '--samples',
    sampleCount,
    '--mode',
    'JIT',
    '--output-dir',
    'results/jit',
  ];
  if (isSmoke) jitArgs.add('--smoke');
  final jitProc =
      await Process.start('dart', jitArgs, mode: ProcessStartMode.inheritStdio);
  final jitExit = await jitProc.exitCode;
  if (jitExit != 0) exit(jitExit);

  // Step 3: Run Process-Isolated Cold-Start Benchmark
  stdout.writeln(
      '\n>>> Step 3/4: Running Process-Isolated Cold-Start Benchmark...');
  final coldProc = await Process.start(
      'dart', ['run', 'bin/cold_start_benchmark.dart'],
      mode: ProcessStartMode.inheritStdio);
  final coldExit = await coldProc.exitCode;
  if (coldExit != 0) exit(coldExit);

  // Step 4: Compile & Run Native AOT Benchmark Campaign
  stdout.writeln(
      '\n>>> Step 4/4: Compiling & Running Native AOT Benchmark Campaign...');
  final exeFile = File('bin/benchmark_suite.exe');
  if (exeFile.existsSync()) exeFile.deleteSync();

  final compileProc = await Process.run('dart', [
    'compile',
    'exe',
    'bin/run_benchmark_suite.dart',
    '-o',
    'bin/benchmark_suite.exe',
  ]);
  if (compileProc.exitCode != 0) {
    stderr.writeln('AOT compilation failed: ${compileProc.stderr}');
  } else {
    stdout.writeln('AOT binary compiled successfully: bin/benchmark_suite.exe');
    final aotArgs = [
      '--samples',
      sampleCount,
      '--mode',
      'AOT',
      '--output-dir',
      'results/aot',
    ];
    if (isSmoke) aotArgs.add('--smoke');
    final aotProc = await Process.start('bin/benchmark_suite.exe', aotArgs,
        mode: ProcessStartMode.inheritStdio);
    final aotExit = await aotProc.exitCode;
    if (aotExit != 0) exit(aotExit);
  }

  // Consolidate primary report into results/BENCHMARK_REPORT.md
  final jitReportFile = File('results/jit/BENCHMARK_REPORT.md');
  if (jitReportFile.existsSync()) {
    final reportDir = Directory('results');
    if (!reportDir.existsSync()) reportDir.createSync(recursive: true);
    await jitReportFile.copy('results/BENCHMARK_REPORT.md');
  }

  stdout.writeln(
      '\n================================================================================');
  stdout.writeln('  CAMPAIGN COMPLETED SUCCESSFULLY');
  stdout.writeln('  Artifacts generated:');
  stdout.writeln(
      '    - results/jit/ (raw_samples.json, aggregated_results.json, results.csv, BENCHMARK_REPORT.md)');
  stdout.writeln(
      '    - results/aot/ (raw_samples.json, aggregated_results.json, results.csv, BENCHMARK_REPORT.md)');
  stdout.writeln('    - results/BENCHMARK_REPORT.md');
  stdout.writeln(
      '================================================================================\n');
}
