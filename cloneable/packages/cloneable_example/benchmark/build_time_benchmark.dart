import 'dart:io';

Future<double> runCommandTimed(
  String executable,
  List<String> arguments,
  String workingDir,
) async {
  final sw = Stopwatch()..start();
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDir,
  );
  sw.stop();
  if (result.exitCode != 0) {
    throw ProcessException(
      executable,
      arguments,
      'Command failed: ${result.stderr}',
      result.exitCode,
    );
  }
  return sw.elapsedMilliseconds / 1000.0;
}

void main() async {
  print(
    '========================================================================================',
  );
  print(
    '                    CLONEABLE BUILD-TIME PERFORMANCE BENCHMARK                           ',
  );
  print(
    '========================================================================================',
  );

  final workingDir = Directory.current.path;

  // 1. Clean Build
  print('Measuring Clean Build...');
  await Process.run('dart', [
    'run',
    'build_runner',
    'clean',
  ], workingDirectory: workingDir);
  final cleanDuration = await runCommandTimed('dart', [
    'run',
    'build_runner',
    'build',
    '--delete-conflicting-outputs',
  ], workingDir);
  print('Clean Generation Time:       ${cleanDuration.toStringAsFixed(2)} s');

  // 2. Incremental Build (Touch single file)
  print('Measuring Incremental Build (1 file modified)...');
  final userFile = File('$workingDir/lib/user.dart');
  final originalContent = await userFile.readAsString();
  await userFile.writeAsString('$originalContent\n// touch for benchmark\n');

  final incrementalDuration = await runCommandTimed('dart', [
    'run',
    'build_runner',
    'build',
  ], workingDir);
  print(
    'Incremental Generation Time: ${incrementalDuration.toStringAsFixed(2)} s',
  );

  // Restore file
  await userFile.writeAsString(originalContent);

  // 3. No-op Build (Zero files changed)
  print('Measuring No-Op Build (0 files modified)...');
  final noopDuration = await runCommandTimed('dart', [
    'run',
    'build_runner',
    'build',
  ], workingDir);
  print('No-Op Generation Time:       ${noopDuration.toStringAsFixed(2)} s');

  print(
    '========================================================================================',
  );
  print('Summary:');
  print('- Clean Generation:       ${cleanDuration.toStringAsFixed(2)} s');
  print(
    '- Incremental Generation: ${incrementalDuration.toStringAsFixed(2)} s',
  );
  print('- No-Op (Cache hit):      ${noopDuration.toStringAsFixed(2)} s');
  print(
    '========================================================================================',
  );
}
