import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Static Type Safety Verification', () {
    final fixturesDir =
        Directory(p.join(Directory.current.path, 'test', 'fixtures'));

    setUpAll(() async {
      if (!fixturesDir.existsSync()) {
        fixturesDir.createSync(recursive: true);
      }
    });

    tearDownAll(() async {
      if (fixturesDir.existsSync()) {
        fixturesDir.deleteSync(recursive: true);
      }
    });

    test(
        'Passing null to non-nullable field causes compile-time analysis error',
        () async {
      final testFile = File(p.join(fixturesDir.path, 'invalid_usage.dart'));
      await testFile.writeAsString('''
import 'package:cloneable_example/user.dart';

void testInvalidUsage() {
  final user = User(name: 'Ahmed', age: 25, nickname: 'Dev');
  // Attempting to pass null to non-nullable field 'name'
  user.copyWith(name: null);
}
''');

      final result = await Process.run(
        'dart',
        ['analyze', testFile.path],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, isNot(0),
          reason:
              'Analyzer should fail when null is assigned to a non-nullable field');
      final output = '${result.stdout}\n${result.stderr}';
      expect(
        output,
        contains('argument_type_not_assignable'),
        reason: 'Expected argument_type_not_assignable error for name: null',
      );
    });

    test('Passing null to nullable field passes static analysis', () async {
      final testFile = File(p.join(fixturesDir.path, 'valid_usage.dart'));
      await testFile.writeAsString('''
import 'package:cloneable_example/user.dart';

void testValidUsage() {
  final user = User(name: 'Ahmed', age: 25, nickname: 'Dev');
  // Passing null to nullable field 'nickname' is completely valid
  user.copyWith(nickname: null);
}
''');

      final result = await Process.run(
        'dart',
        ['analyze', testFile.path],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, equals(0),
          reason:
              'Analyzer should succeed when null is assigned to a nullable field. Output: ${result.stdout} ${result.stderr}');
    });
  });
}
