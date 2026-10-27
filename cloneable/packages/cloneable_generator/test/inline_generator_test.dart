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

@Cloneable(output: CloneableOutput.inLibrary)
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
          '// cloneable:start (User) - GENERATED CODE - DO NOT MODIFY BY HAND\n// (run: dart run cloneable_generator to regenerate)',
        ),
      );
      expect(updated, contains('// cloneable:end (User)'));
      expect(updated, contains('extension \$UserCloneableExtension on User'));
      expect(updated, contains('class User {'));
    });

    test('updates existing marker block in-place', () {
      const original = '''
import 'package:cloneable/cloneable.dart';

@Cloneable(output: CloneableOutput.inLibrary)
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

@Cloneable(output: CloneableOutput.inLibrary)
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
          '// cloneable:start (User) - GENERATED CODE - DO NOT MODIFY BY HAND\n// (run: dart run cloneable_generator to regenerate)',
        ),
      );
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

@Cloneable(output: CloneableOutput.inLibrary)
class User {
  final String name;
  const User({required this.name});
}

@Cloneable(output: CloneableOutput.inLibrary)
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
          '// cloneable:start (User) - GENERATED CODE - DO NOT MODIFY BY HAND',
        ),
      );
      expect(updated, contains('// cloneable:end (User)'));
      expect(
        updated,
        contains(
          '// cloneable:start (Address) - GENERATED CODE - DO NOT MODIFY BY HAND',
        ),
      );
      expect(updated, contains('// cloneable:end (Address)'));
      expect(updated, contains('extension \$UserExt on User {}'));
      expect(updated, contains('extension \$AddressExt on Address {}'));
    });

    test('is idempotent when re-running on identical code', () {
      const original = '''
import 'package:cloneable/cloneable.dart';

@Cloneable(output: CloneableOutput.inLibrary)
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
        p.normalize(p.join(Directory.current.path, 'packages', 'cloneable')),
      );
      if (!cloneableDir.existsSync()) {
        cloneableDir = Directory(
          p.normalize(p.join(Directory.current.path, '..', 'cloneable')),
        );
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

    test(
      'generates inline copyWith extension and handles re-run and removal',
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

@Cloneable(output: CloneableOutput.inLibrary)
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
            '// cloneable:start (User) - GENERATED CODE - DO NOT MODIFY BY HAND\n// (run: dart run cloneable_generator to regenerate)',
          ),
        );
        expect(updatedContent1, contains('extension \$UserExtension on User'));
        expect(updatedContent1, contains('User Function({'));
        expect(updatedContent1, contains('get copyWith => _copyWith;'));
        expect(updatedContent1, isNot(contains('typedef')));

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
extension \$UserExtension on User {}
// cloneable:end (User)
''');

        final result3 = await generator.run(paths: [libDir.path]);
        expect(result3.updatedFiles, hasLength(1));

        final updatedContent3 = modelFile.readAsStringSync();
        expect(updatedContent3, isNot(contains('cloneable:start (User)')));
        expect(updatedContent3, isNot(contains('cloneable:end (User)')));
      },
    );

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

@Cloneable(output: CloneableOutput.inLibrary)
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
          '// cloneable:start (Profile) - GENERATED CODE - DO NOT MODIFY BY HAND\n// (run: dart run cloneable_generator to regenerate)',
        ),
      );
      expect(updatedContent, contains('// cloneable:end (Profile)'));
      expect(updatedContent, contains('mixin _\$ProfileCloneable {'));
    });

    test(
      'auto-injects mixin when strategy is CloneableStrategy.mixin',
      () async {
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

@Cloneable(strategy: CloneableStrategy.mixin, output: CloneableOutput.inLibrary)
class Profile {
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
          contains('class Profile with _\$ProfileCloneable {'),
        );
        expect(updatedContent, contains('mixin _\$ProfileCloneable {'));
      },
    );

    test('auto-injects mixin with empty prefix when strategy is CloneableStrategy.mixin and prefix is empty string', () async {
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

@Cloneable(
  strategy: CloneableStrategy.mixin,
  output: CloneableOutput.inLibrary,
  naming: CloneableNaming(mixin: CloneableAffix(prefix: '', suffix: 'CloneableMixin')),
)
class Profile {
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
        contains('class Profile with ProfileCloneableMixin {'),
      );
      expect(updatedContent, isNot(contains(r'_$ProfileCloneableMixin')));
      expect(updatedContent, isNot(contains('_ProfileCloneableMixin')));
      expect(updatedContent, contains('mixin ProfileCloneableMixin {'));
    });

    test(
      r'auto-injects mixin with custom prefix without prepending synthetic _$',
      () async {
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

@Cloneable(
  strategy: CloneableStrategy.mixin,
  output: CloneableOutput.inLibrary,
  naming: CloneableNaming(mixin: CloneableAffix(prefix: 'X', suffix: 'CloneableMixin')),
)
class Profile {
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
          contains('class Profile with XProfileCloneableMixin {'),
        );
        expect(updatedContent, isNot(contains(r'_$XProfileCloneableMixin')));
        expect(updatedContent, isNot(contains('_XProfileCloneableMixin')));
        expect(updatedContent, contains('mixin XProfileCloneableMixin {'));
      },
    );

    test('auto-injects generic mixin when strategy is CloneableStrategy.mixin on generic class', () async {
      final pubspec = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
name: test_pkg
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

      final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
      final modelFile = File(p.join(libDir.path, 'box.dart'));
      modelFile.writeAsStringSync('''
import 'package:cloneable/cloneable.dart';

@Cloneable(strategy: CloneableStrategy.mixin, output: CloneableOutput.inLibrary)
class Box<T> {
  final T value;

  const Box({
    required this.value,
  });
}
''');

      final generator = CloneableGeneratorRunner();
      final result = await generator.run(paths: [libDir.path]);
      expect(result.updatedFiles, hasLength(1));

      final updatedContent = modelFile.readAsStringSync();
      expect(
        updatedContent,
        contains('class Box<T> with _\$BoxCloneable<T> {'),
      );
      expect(updatedContent, contains('mixin _\$BoxCloneable<T> {'));
      expect(
        updatedContent,
        contains('Box<T> Function({T value}) get copyWith => _copyWith;'),
      );
    });

    test('auto-injects mixin and part directive when strategy is CloneableStrategy.mixin with output CloneableOutput.part', () async {
      final pubspec = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
name: test_pkg
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

      final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
      final modelFile = File(p.join(libDir.path, 'gadget.dart'));
      modelFile.writeAsStringSync('''
import 'package:cloneable/cloneable.dart';

@Cloneable(strategy: CloneableStrategy.mixin, output: CloneableOutput.part)
class Gadget {
  final String name;

  const Gadget({
    required this.name,
  });
}
''');

      final generator = CloneableGeneratorRunner();
      final result = await generator.run(paths: [libDir.path]);
      expect(result.updatedFiles, hasLength(2));

      final updatedContent = modelFile.readAsStringSync();
      expect(updatedContent, contains("part 'gadget.cloneable.g.dart';"));
      expect(
        updatedContent,
        contains('class Gadget with _\$GadgetCloneable {'),
      );

      final partFile = File(p.join(libDir.path, 'gadget.cloneable.g.dart'));
      expect(partFile.existsSync(), isTrue);
      expect(
        partFile.readAsStringSync(),
        contains('mixin _\$GadgetCloneable {'),
      );
    });

    test(
      'generates clean external part file without asterisks banner',
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
          partContent,
          startsWith('// GENERATED CODE - DO NOT MODIFY BY HAND'),
        );
        expect(partContent, contains("part of 'item.dart';"));
        expect(partContent, isNot(contains('***')));
        expect(partContent, isNot(contains('CloneableGenerator\n// ***')));
        expect(partContent, contains('Item Function({'));
        expect(partContent, isNot(contains('typedef')));

        // 2. Re-run is idempotent
        final result2 = await runner.run(paths: [libDir.path]);
        expect(result2.updatedFiles, isEmpty);
      },
    );

    test(
      'generates both inline and external part files in a single pass',
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

@Cloneable(output: CloneableOutput.inLibrary)
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
        final externalPartFile = File(
          p.join(libDir.path, 'external_user.g.dart'),
        );
        expect(externalPartFile.existsSync(), isTrue);
        final externalPartContent = externalPartFile.readAsStringSync();
        expect(externalPartContent, isNot(contains('***')));
        expect(
          externalPartContent,
          contains('mixin _\$ExternalUserCloneable {'),
        );
      },
    );

    test('supports inline generation with custom prefix', () async {
      final pubspec = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
name: test_pkg
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

      final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
      final modelFile = File(p.join(libDir.path, 'custom_inline.dart'));
      modelFile.writeAsStringSync('''
import 'package:cloneable/cloneable.dart';

@Cloneable(
  output: CloneableOutput.inLibrary,
  naming: CloneableNaming(inLibrary: CloneableAffix(prefix: 'Custom')),
)
class CustomInlineUser {
  final String name;
  const CustomInlineUser({required this.name});
}
''');

      final runner = CloneableGeneratorRunner();
      final result = await runner.run(paths: [libDir.path]);
      expect(result.updatedFiles, hasLength(1));

      final updatedContent = modelFile.readAsStringSync();
      expect(updatedContent, contains('cloneable:start (CustomInlineUser)'));
      expect(updatedContent, contains('cloneable:end (CustomInlineUser)'));
      expect(
        updatedContent,
        contains(
          'extension CustomCustomInlineUserExtension on CustomInlineUser {',
        ),
      );
      expect(updatedContent, contains('CustomInlineUser Function({'));
      expect(updatedContent, contains('get copyWith => _copyWith;'));
      expect(updatedContent, isNot(contains('typedef')));
    });

    test('supports inClass generation with copyWith inside class body without top-level typedef', () async {
      final pubspec = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
name: test_pkg
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

      final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
      final modelFile = File(p.join(libDir.path, 'in_class_model.dart'));
      modelFile.writeAsStringSync('''
import 'package:cloneable/cloneable.dart';

@Cloneable(output: CloneableOutput.inClass)
class InClassUser {
  final String name;
  final int age;

  const InClassUser({
    required this.name,
    required this.age,
  });
}
''');

      final runner = CloneableGeneratorRunner();
      final result = await runner.run(paths: [libDir.path]);
      expect(result.updatedFiles, hasLength(1));

      final updatedContent = modelFile.readAsStringSync();
      // No typedef generated anywhere in the file
      expect(updatedContent, isNot(contains('typedef')));
      expect(updatedContent, isNot(contains('cloneable:typedef')));

      // In-class markers and methods should be inside the class body
      expect(updatedContent, contains(r'static const _$undefined = Object();'));
      expect(updatedContent, contains('InClassUser Function({'));
      expect(updatedContent, contains('get copyWith => _copyWith;'));
      expect(updatedContent, contains('InClassUser _copyWith({'));
      expect(updatedContent, contains('// cloneable:start (InClassUser)'));
      expect(updatedContent, contains('// cloneable:end (InClassUser)'));
    });

    test('supports CloneableCleanup.remove eliminating @Cloneable, @CloneableField, and import when sentinel is private', () async {
      final pubspec = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
name: test_pkg
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

      final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
      final modelFile = File(p.join(libDir.path, 'clean_target.dart'));
      modelFile.writeAsStringSync('''
import 'package:cloneable/cloneable.dart';

@Cloneable(
  output: CloneableOutput.inClass,
  sentinel: CloneableSentinel.private,
  cleanup: CloneableCleanup.remove,
)
class CleanTarget {
  @CloneableField()
  final String name;

  const CleanTarget({
    required this.name,
  });
}
''');

      final runner = CloneableGeneratorRunner();
      final result = await runner.run(paths: [libDir.path]);
      expect(result.updatedFiles, hasLength(1));

      final updatedContent = modelFile.readAsStringSync();
      // Generated in-class copyWith is present
      expect(updatedContent, contains('get copyWith => _copyWith;'));
      expect(updatedContent, contains('CleanTarget _copyWith({'));
      // Annotations and import should be cleanly stripped
      expect(updatedContent, isNot(contains('@Cloneable')));
      expect(updatedContent, isNot(contains('@CloneableField')));
      expect(
        updatedContent,
        isNot(contains("package:cloneable/cloneable.dart")),
      );
    });

    test(
      'does not remove when sentinel is package even if cleanup is remove',
      () async {
        final pubspec = File(p.join(tempDir.path, 'pubspec.yaml'));
        pubspec.writeAsStringSync('''
name: test_pkg
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

        final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
        final modelFile = File(p.join(libDir.path, 'package_sentinel.dart'));
        modelFile.writeAsStringSync('''
import 'package:cloneable/cloneable.dart';

@Cloneable(
  output: CloneableOutput.inClass,
  sentinel: CloneableSentinel.package,
  cleanup: CloneableCleanup.remove,
)
class PackageTarget {
  final String name;

  const PackageTarget({
    required this.name,
  });
}
''');

        final runner = CloneableGeneratorRunner();
        final result = await runner.run(paths: [libDir.path]);
        expect(result.updatedFiles, hasLength(1));

        final updatedContent = modelFile.readAsStringSync();
        // Annotations and import should NOT be removed because sentinel is package
        expect(updatedContent, contains('@Cloneable'));
        expect(updatedContent, contains("package:cloneable/cloneable.dart"));
      },
    );

    test('supports CloneableCleanup.deactivate setting active: false in place while preserving fields and import', () async {
      final pubspec = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
name: test_pkg
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

      final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
      final modelFile = File(p.join(libDir.path, 'deactivate_target.dart'));
      modelFile.writeAsStringSync('''
import 'package:cloneable/cloneable.dart';

@Cloneable(
  output: CloneableOutput.inClass,
  cleanup: CloneableCleanup.deactivate,
)
class DeactivateTarget {
  @CloneableField()
  final String title;

  const DeactivateTarget({
    required this.title,
  });
}
''');

      final runner = CloneableGeneratorRunner();
      final result = await runner.run(paths: [libDir.path]);
      expect(result.updatedFiles, hasLength(1));

      final updatedContent = modelFile.readAsStringSync();
      // Member code is generated
      expect(updatedContent, contains('get copyWith => _copyWith;'));
      expect(updatedContent, contains('DeactivateTarget _copyWith({'));
      // @Cloneable annotation is rewritten to active: false
      expect(updatedContent, contains('active: false'));
      // Annotations on fields and package import are preserved
      expect(updatedContent, contains('@CloneableField()'));
      expect(updatedContent, contains("package:cloneable/cloneable.dart"));

      // Second run should skip this class because active is false
      final secondResult = await runner.run(paths: [libDir.path]);
      expect(secondResult.updatedFiles, isEmpty);
    });

    test('transition: switching from inClass to inLibrary removes in-class markers and members and generates top-level extension', () async {
      final pubspec = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
name: test_pkg
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

      final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
      final modelFile = File(p.join(libDir.path, 'transition_target.dart'));
      modelFile.writeAsStringSync('''
import 'package:cloneable/cloneable.dart';

@Cloneable.inClass()
class TransitionTarget {
  final String name;

  const TransitionTarget({
    required this.name,
  });
}
''');

      final runner = CloneableGeneratorRunner();
      // First pass: generate in-class
      final r1 = await runner.run(paths: [libDir.path]);
      expect(r1.updatedFiles, hasLength(1));

      var content = modelFile.readAsStringSync();
      expect(content, contains('// cloneable:start (TransitionTarget)'));
      expect(content, contains('TransitionTarget _copyWith({'));

      // Switch mode to inLibrary
      content = content.replaceAll(
        '@Cloneable.inClass()',
        '@Cloneable.inLibrary()',
      );
      modelFile.writeAsStringSync(content);

      // Second pass: regenerate
      final r2 = await runner.run(paths: [libDir.path]);
      expect(r2.updatedFiles, hasLength(1));

      final r2Content = modelFile.readAsStringSync();
      final classOpenIdx = r2Content.indexOf('class TransitionTarget');
      final classCloseIdx = r2Content.indexOf('}', classOpenIdx);
      final classBody = r2Content.substring(classOpenIdx, classCloseIdx + 1);
      // Old in-class members must be gone from the class body
      expect(classBody, isNot(contains('_copyWith')));
      expect(classBody, isNot(contains('// cloneable:start')));
      // Top-level extension must be generated
      expect(
        r2Content,
        contains('extension \$TransitionTargetExtension on TransitionTarget'),
      );
      expect(
        r2Content,
        contains(
          'TransitionTarget Function({String name}) get copyWith => _copyWith;',
        ),
      );
    });

    test('transition: switching from inLibrary to inClass removes top-level markers and injects in-class members', () async {
      final pubspec = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
name: test_pkg
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

      final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
      final modelFile = File(p.join(libDir.path, 'library_to_class.dart'));
      modelFile.writeAsStringSync('''
import 'package:cloneable/cloneable.dart';

@Cloneable.inLibrary()
class LibToClassTarget {
  final int count;

  const LibToClassTarget({
    required this.count,
  });
}
''');

      final runner = CloneableGeneratorRunner();
      // First pass: generate inLibrary
      final r1 = await runner.run(paths: [libDir.path]);
      expect(r1.updatedFiles, hasLength(1));

      var content = modelFile.readAsStringSync();
      expect(
        content,
        contains('extension \$LibToClassTargetExtension on LibToClassTarget'),
      );

      // Switch mode to inClass
      content = content.replaceAll(
        '@Cloneable.inLibrary()',
        '@Cloneable.inClass()',
      );
      modelFile.writeAsStringSync(content);

      // Second pass: regenerate
      final r2 = await runner.run(paths: [libDir.path]);
      expect(r2.updatedFiles, hasLength(1));

      final r2Content = modelFile.readAsStringSync();
      // Top-level extension must be removed
      expect(
        r2Content,
        isNot(contains('extension \$LibToClassTargetExtension')),
      );
      // In-class member must be present
      expect(r2Content, contains('get copyWith => _copyWith;'));
      expect(r2Content, contains('LibToClassTarget _copyWith({'));
    });

    test('transition: switching from part to inClass removes part directive, deletes part file, and generates in-class code', () async {
      final pubspec = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
name: test_pkg
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

      final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
      final modelFile = File(p.join(libDir.path, 'part_to_class.dart'));
      modelFile.writeAsStringSync('''
import 'package:cloneable/cloneable.dart';

part 'part_to_class.cloneable.dart';

@Cloneable.part()
class PartToClassTarget {
  final String label;

  const PartToClassTarget({
    required this.label,
  });
}
''');

      final runner = CloneableGeneratorRunner();
      // First pass: generate part file
      final r1 = await runner.run(paths: [libDir.path]);
      final partFile = File(
        p.join(libDir.path, 'part_to_class.cloneable.dart'),
      );
      expect(partFile.existsSync(), isTrue);
      expect(r1.updatedFiles, contains(partFile.path));

      var content = modelFile.readAsStringSync();
      expect(content, contains("part 'part_to_class.cloneable.dart';"));

      // Switch mode to inClass
      content = content.replaceAll('@Cloneable.part()', '@Cloneable.inClass()');
      modelFile.writeAsStringSync(content);

      // Second pass: regenerate
      final r2 = await runner.run(paths: [libDir.path]);
      expect(r2.updatedFiles, contains(modelFile.path));
      expect(r2.deletedFiles, contains(partFile.path));

      // Part file is deleted
      expect(partFile.existsSync(), isFalse);

      final r2Content = modelFile.readAsStringSync();
      // Part directive is removed from modelFile
      expect(r2Content, isNot(contains('part ')));
      // In-class code is generated
      expect(r2Content, contains('get copyWith => _copyWith;'));
      expect(r2Content, contains('PartToClassTarget _copyWith({'));
    });
  });
}
