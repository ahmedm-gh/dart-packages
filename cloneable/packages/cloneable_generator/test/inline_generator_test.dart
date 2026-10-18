import 'dart:io';

import 'package:cloneable_generator/cloneable_generator.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('CloneableGeneratorRunner updateContent unit tests', () {
    final generator = CloneableGeneratorRunner();

    test('adds inline marker block at the end when no markers exist', () {
      const original = '''
import 'package:cloneable/cloneable.dart';

@Cloneable(inline: true)
class User {
  final String name;
  const User({required this.name});
}
''';

      const generatedCode = '''
extension \$UserCloneableExtension on User {
  User copyWith({String? name}) => User(name: name ?? this.name);
}''';

      final updated = generator.updateContent(
        content: original,
        classCodeMap: {'User': generatedCode},
      );

      expect(
          updated,
          contains(
              '// cloneable:start (User) - GENERATED CODE - DO NOT MODIFY BY HAND\n// (run: dart run cloneable_generator to regenerate)'));
      expect(updated, contains('// cloneable:end (User)'));
      expect(updated, contains('extension \$UserCloneableExtension on User'));
      expect(updated, contains('class User {'));
    });

    test('updates existing marker block in-place', () {
      const original = '''
import 'package:cloneable/cloneable.dart';

@Cloneable(inline: true)
class User {
  final String name;
  const User({required this.name});
}

// cloneable:start (User) - GENERATED CODE - DO NOT MODIFY BY HAND
// (run: dart run cloneable_generator to regenerate)
// Old content to be replaced
// cloneable:end (User)

void helper() {}
''';

      const newCode = '''
extension \$UserCloneableExtension on User {
  User copyWith({String? name}) => User(name: name ?? this.name);
}''';

      final updated = generator.updateContent(
        content: original,
        classCodeMap: {'User': newCode},
      );

      expect(updated, isNot(contains('Old content to be replaced')));
      expect(updated, contains('extension \$UserCloneableExtension on User'));
      expect(updated, contains('void helper() {}'));
    });

    test('upgrades legacy divider markers to new clean format', () {
      const original = '''
import 'package:cloneable/cloneable.dart';

@Cloneable(inline: true)
class User {
  final String name;
  const User({required this.name});
}

// =============================================================================
// Cloneable: start (User)
// =============================================================================
// Old content to be replaced
// =============================================================================
// Cloneable: end (User)
// =============================================================================

void helper() {}
''';

      const newCode = '''
extension \$UserCloneableExtension on User {
  User copyWith({String? name}) => User(name: name ?? this.name);
}''';

      final updated = generator.updateContent(
        content: original,
        classCodeMap: {'User': newCode},
      );

      expect(updated, isNot(contains('Old content to be replaced')));
      expect(
          updated,
          contains(
              '// cloneable:start (User) - GENERATED CODE - DO NOT MODIFY BY HAND\n// (run: dart run cloneable_generator to regenerate)'));
      expect(updated, contains('// cloneable:end (User)'));
      expect(updated, contains('extension \$UserCloneableExtension on User'));
      expect(updated, contains('void helper() {}'));
    });

    test('removes marker block when class code is null (obsolete/removed)', () {
      const original = '''
import 'package:cloneable/cloneable.dart';

class User {
  final String name;
  const User({required this.name});
}

// cloneable:start (User) - GENERATED CODE - DO NOT MODIFY BY HAND
// (run: dart run cloneable_generator to regenerate)
extension \$UserCloneableExtension on User {}
// cloneable:end (User)

void afterHelper() {}
''';

      final updated = generator.updateContent(
        content: original,
        classCodeMap: {'User': null},
      );

      expect(updated, isNot(contains('cloneable:start (User)')));
      expect(updated, isNot(contains('cloneable:end (User)')));
      expect(updated, isNot(contains('\$UserCloneableExtension')));
      expect(updated, contains('class User {'));
      expect(updated, contains('void afterHelper() {}'));
    });

    test('handles multiple classes in same file independently', () {
      const original = '''
import 'package:cloneable/cloneable.dart';

@Cloneable(inline: true)
class User {
  final String name;
  const User({required this.name});
}

@Cloneable(inline: true)
class Address {
  final String city;
  const Address({required this.city});
}
''';

      final updated = generator.updateContent(
        content: original,
        classCodeMap: {
          'User': 'extension \$UserExt on User {}',
          'Address': 'extension \$AddressExt on Address {}',
        },
      );

      expect(
          updated,
          contains(
              '// cloneable:start (User) - GENERATED CODE - DO NOT MODIFY BY HAND'));
      expect(updated, contains('// cloneable:end (User)'));
      expect(
          updated,
          contains(
              '// cloneable:start (Address) - GENERATED CODE - DO NOT MODIFY BY HAND'));
      expect(updated, contains('// cloneable:end (Address)'));
      expect(updated, contains('extension \$UserExt on User {}'));
      expect(updated, contains('extension \$AddressExt on Address {}'));
    });

    test('is idempotent when re-running on identical code', () {
      const original = '''
import 'package:cloneable/cloneable.dart';

@Cloneable(inline: true)
class User {
  final String name;
  const User({required this.name});
}
''';

      final firstRun = generator.updateContent(
        content: original,
        classCodeMap: {'User': 'extension \$UserExt on User {}'},
      );

      final secondRun = generator.updateContent(
        content: firstRun,
        classCodeMap: {'User': 'extension \$UserExt on User {}'},
      );

      expect(secondRun, equals(firstRun));
    });
  });

  group('CloneableGeneratorRunner filesystem integration tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('cloneable_cli_test_');

      var cloneableDir = Directory(
          p.normalize(p.join(Directory.current.path, 'packages', 'cloneable')));
      if (!cloneableDir.existsSync()) {
        cloneableDir = Directory(
            p.normalize(p.join(Directory.current.path, '..', 'cloneable')));
      }
      final cloneableUri = Uri.file(cloneableDir.path).toString();

      final dartTool = Directory(p.join(tempDir.path, '.dart_tool'))
        ..createSync();
      File(p.join(dartTool.path, 'package_config.json')).writeAsStringSync('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test_pkg",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "3.5"
    },
    {
      "name": "cloneable",
      "rootUri": "$cloneableUri",
      "packageUri": "lib/",
      "languageVersion": "3.5"
    }
  ]
}
''');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('generates inline copyWith extension and handles re-run and removal',
        () async {
      final pubspec = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
name: test_pkg
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

      final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
      final modelFile = File(p.join(libDir.path, 'user.dart'));
      modelFile.writeAsStringSync('''
import 'package:cloneable/cloneable.dart';

@Cloneable(inline: true)
class User {
  final String name;
  final int? age;

  const User({
    required this.name,
    this.age,
  });
}
''');

      final generator = CloneableGeneratorRunner();

      // 1. First execution -> updates user.dart
      final result1 = await generator.run(paths: [libDir.path]);
      expect(result1.updatedFiles, hasLength(1));

      final updatedContent1 = modelFile.readAsStringSync();
      expect(
          updatedContent1,
          contains(
              '// cloneable:start (User) - GENERATED CODE - DO NOT MODIFY BY HAND\n// (run: dart run cloneable_generator to regenerate)'));
      expect(updatedContent1, contains('// cloneable:end (User)'));
      expect(updatedContent1, contains('typedef \$UserCopyWith'));
      expect(updatedContent1,
          contains('extension \$UserCloneableExtension on User'));
      expect(updatedContent1,
          contains('\$UserCopyWith get copyWith => _copyWith;'));

      // 2. Second execution -> idempotent, 0 updated files
      final result2 = await generator.run(paths: [libDir.path]);
      expect(result2.updatedFiles, isEmpty);

      // 3. User removes @Cloneable completely -> cleans up inline markers
      modelFile.writeAsStringSync('''
import 'package:cloneable/cloneable.dart';

class User {
  final String name;
  final int? age;

  const User({
    required this.name,
    this.age,
  });
}

// cloneable:start (User) - GENERATED CODE - DO NOT MODIFY BY HAND
// (run: dart run cloneable_generator to regenerate)
typedef \$UserCopyWith = User Function({String? name, int? age});
// cloneable:end (User)
''');

      final result3 = await generator.run(paths: [libDir.path]);
      expect(result3.updatedFiles, hasLength(1));

      final updatedContent3 = modelFile.readAsStringSync();
      expect(updatedContent3, isNot(contains('cloneable:start (User)')));
      expect(updatedContent3, isNot(contains('cloneable:end (User)')));
    });

    test('supports inline generation with mixin strategy', () async {
      final pubspec = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
name: test_pkg
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

      final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
      final modelFile = File(p.join(libDir.path, 'profile.dart'));
      modelFile.writeAsStringSync('''
import 'package:cloneable/cloneable.dart';

@Cloneable(inline: true)
class Profile with _\$ProfileCloneable {
  final String bio;

  const Profile({
    required this.bio,
  });
}
''');

      final generator = CloneableGeneratorRunner();
      final result = await generator.run(paths: [libDir.path]);
      expect(result.updatedFiles, hasLength(1));

      final updatedContent = modelFile.readAsStringSync();
      expect(
          updatedContent,
          contains(
              '// cloneable:start (Profile) - GENERATED CODE - DO NOT MODIFY BY HAND\n// (run: dart run cloneable_generator to regenerate)'));
      expect(updatedContent, contains('// cloneable:end (Profile)'));
      expect(updatedContent, contains('mixin _\$ProfileCloneable {'));
    });

    test('generates clean external part file without asterisks banner',
        () async {
      final pubspec = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
name: test_pkg
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

      final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
      final modelFile = File(p.join(libDir.path, 'item.dart'));
      modelFile.writeAsStringSync('''
import 'package:cloneable/cloneable.dart';

part 'item.g.dart';

@Cloneable()
class Item with _\$ItemCloneable {
  final String title;
  final double price;

  const Item({
    required this.title,
    required this.price,
  });
}
''');

      final runner = CloneableGeneratorRunner();

      // 1. Generate external part file
      final result1 = await runner.run(paths: [libDir.path]);
      expect(result1.updatedFiles, hasLength(1));
      expect(result1.updatedFiles.first, endsWith('item.g.dart'));

      final partFile = File(p.join(libDir.path, 'item.g.dart'));
      expect(partFile.existsSync(), isTrue);

      final partContent = partFile.readAsStringSync();
      // Verify clean header with NO asterisks
      expect(
          partContent, startsWith('// GENERATED CODE - DO NOT MODIFY BY HAND'));
      expect(partContent, contains("part of 'item.dart';"));
      expect(partContent, isNot(contains('***')));
      expect(partContent, isNot(contains('CloneableGenerator\n// ***')));
      expect(partContent, contains('mixin _\$ItemCloneable {'));
      expect(partContent, contains('typedef \$ItemCopyWith'));

      // 2. Re-run is idempotent
      final result2 = await runner.run(paths: [libDir.path]);
      expect(result2.updatedFiles, isEmpty);
    });

    test('generates both inline and external part files in a single pass',
        () async {
      final pubspec = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
name: test_pkg
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

      final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();

      // Model 1: Inline
      final inlineFile = File(p.join(libDir.path, 'inline_user.dart'));
      inlineFile.writeAsStringSync('''
import 'package:cloneable/cloneable.dart';

@Cloneable(inline: true)
class InlineUser {
  final String name;
  const InlineUser({required this.name});
}
''');

      // Model 2: External part file
      final externalFile = File(p.join(libDir.path, 'external_user.dart'));
      externalFile.writeAsStringSync('''
import 'package:cloneable/cloneable.dart';

part 'external_user.g.dart';

@Cloneable()
class ExternalUser with _\$ExternalUserCloneable {
  final String name;
  const ExternalUser({required this.name});
}
''');

      final runner = CloneableGeneratorRunner();
      final result = await runner.run(paths: [libDir.path]);

      expect(result.updatedFiles, hasLength(2));

      // Check inline file was updated in place
      final inlineContent = inlineFile.readAsStringSync();
      expect(inlineContent, contains('cloneable:start (InlineUser)'));
      expect(inlineContent, contains('cloneable:end (InlineUser)'));

      // Check external part file was created cleanly
      final externalPartFile =
          File(p.join(libDir.path, 'external_user.g.dart'));
      expect(externalPartFile.existsSync(), isTrue);
      final externalPartContent = externalPartFile.readAsStringSync();
      expect(externalPartContent, isNot(contains('***')));
      expect(externalPartContent, contains('mixin _\$ExternalUserCloneable {'));
    });
  });
}
