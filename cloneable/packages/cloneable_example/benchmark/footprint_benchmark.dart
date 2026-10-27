import 'dart:io';

void main() async {
  print(
    '========================================================================================',
  );
  print(
    '                    CLONEABLE FOOTPRINT AND BINARY BENCHMARK                             ',
  );
  print(
    '========================================================================================',
  );

  final currentDir = Directory.current;

  // 1. Measure Generated File Sizes
  int totalBytes = 0;
  int totalLines = 0;
  int fileCount = 0;

  final libDir = Directory('${currentDir.path}/lib');
  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.g.dart')) {
      final content = entity.readAsStringSync();
      final bytes = entity.lengthSync();
      final lines = content.split('\n').length;
      totalBytes += bytes;
      totalLines += lines;
      fileCount++;
      print(
        'Generated: ${entity.path.split('packages/cloneable_example/').last.padRight(35)} | $lines lines | $bytes bytes',
      );
    }
  }

  print(
    '----------------------------------------------------------------------------------------',
  );
  print('Total Generated Files:       $fileCount');
  print('Total Generated Lines:       $totalLines lines');
  print(
    'Total Generated Source Size: $totalBytes bytes (${(totalBytes / 1024.0).toStringAsFixed(2)} KB)',
  );
  print(
    '----------------------------------------------------------------------------------------',
  );

  // 2. Measure AOT Binary Compilation
  print('Testing AOT Compilation: `dart compile exe bin/main.dart`...');
  final binDir = Directory('${currentDir.path}/bin');
  if (!binDir.existsSync()) binDir.createSync(recursive: true);

  final mainFile = File('${binDir.path}/main.dart');
  await mainFile.writeAsString('''
import 'package:cloneable_example/user.dart';

void main() {
  final user = User(name: 'Ahmed', age: 25, nickname: 'Dev');
  final updated = user.copyWith(name: 'Mohamed', nickname: null);
  print('Result: \${updated.name}, \${updated.age}, \${updated.nickname}');
}
''');

  final exeFile = File('${binDir.path}/main.exe');
  final sw = Stopwatch()..start();
  final compileResult = await Process.run('dart', [
    'compile',
    'exe',
    mainFile.path,
    '-o',
    exeFile.path,
  ], workingDirectory: currentDir.path);
  sw.stop();

  if (compileResult.exitCode == 0 && exeFile.existsSync()) {
    final exeBytes = exeFile.lengthSync();
    print(
      'AOT Compilation Time:        ${(sw.elapsedMilliseconds / 1000.0).toStringAsFixed(2)} s',
    );
    print(
      'AOT Binary Output Size:      $exeBytes bytes (${(exeBytes / (1024.0 * 1024.0)).toStringAsFixed(2)} MB)',
    );
    // Clean up
    exeFile.deleteSync();
  } else {
    print(
      'AOT Compilation Output:\n${compileResult.stdout}\n${compileResult.stderr}',
    );
  }

  if (mainFile.existsSync()) mainFile.deleteSync();
  if (binDir.existsSync() && binDir.listSync().isEmpty) binDir.deleteSync();

  print(
    '========================================================================================',
  );
}
