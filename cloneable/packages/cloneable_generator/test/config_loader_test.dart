import 'package:build_test/build_test.dart';
import 'package:cloneable/cloneable.dart';
import 'package:cloneable_generator/src/cloneable_generator.dart';
import 'package:cloneable_generator/src/config_loader.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigLoader Built-in Defaults', () {
    setUp(() {
      ConfigLoader.clearCache();
    });

    test('falls back to CloneableDefaults.instance when no in-code defaults',
        () {
      final config = ConfigLoader.resolveDefaults();
      expect(config.output, equals(CloneableOutput.auto));
      expect(config.strategy, equals(CloneableStrategy.auto));
      expect(config.sentinel, equals(CloneableSentinel.auto));
      expect(config.deepCopyCollections, isFalse);
      expect(config.ignoreNull, isFalse);
      expect(config.active, isTrue);
      expect(config.cleanup, equals(CloneableCleanup.none));
      expect(config.fieldsConflict, equals(CloneableFieldsConflict.error));
      expect(config.method, equals(CloneableNaming.defaultMethod));
      expect(config.mixin.prefix, equals(r'_$'));
      expect(config.mixin.suffix, equals('Cloneable'));
      expect(config.extension.prefix, equals(r'$'));
      expect(config.extension.suffix, equals('Extension'));
      expect(config.typedef.prefix, equals(r'$'));
      expect(config.typedef.suffix, equals('CopyWithFn'));
      expect(config.file.prefix, equals(''));
      expect(config.file.suffix, equals('.cloneable.g'));
    });
  });

  group('ConfigLoader In-Code Discovery (Modern Dart 3+ Alternatives)', () {
    setUp(() {
      ConfigLoader.clearCache();
    });

    test('discovers defaults on unnamed library directive', () async {
      const source = '''
@Cloneable.defaults(
  output: CloneableOutput.inClass,
  strategy: CloneableStrategy.extension,
  sentinel: CloneableSentinel.private,
  deepCopyCollections: true,
  ignoreNull: true,
  cleanup: CloneableCleanup.remove,
  fieldsConflict: CloneableFieldsConflict.merge,
  naming: CloneableNaming(method: 'duplicate'),
)
library;

import 'package:cloneable/cloneable.dart';

@Cloneable()
class Person {
  final String name;
  const Person({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final libraries = await resolver.libraries.toList();
        final library =
            libraries.firstWhere((lib) => lib.getClass('Person') != null);

        final config = ConfigLoader.resolveDefaults(library: library);
        expect(config.output, equals(CloneableOutput.inClass));
        expect(config.strategy, equals(CloneableStrategy.extension));
        expect(config.sentinel, equals(CloneableSentinel.private));
        expect(config.deepCopyCollections, isTrue);
        expect(config.ignoreNull, isTrue);
        expect(config.cleanup, equals(CloneableCleanup.remove));
        expect(config.fieldsConflict, equals(CloneableFieldsConflict.merge));
        expect(config.method, equals('duplicate'));
      });
    });

    test('discovers defaults on modern abstract final config class', () async {
      const source = '''
library config_class_lib;

import 'package:cloneable/cloneable.dart';

@Cloneable.defaults(
  output: CloneableOutput.standalone,
  deepCopyCollections: true,
  naming: CloneableNaming(
    method: 'replicate',
    extension: CloneableAffix(prefix: 'Ext_'),
  ),
)
abstract final class CloneableConfig {}

@Cloneable()
class Widget {
  final int width;
  const Widget({required this.width});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('config_class_lib');
        expect(library, isNotNull);

        final config = ConfigLoader.resolveDefaults(library: library);
        expect(config.output, equals(CloneableOutput.standalone));
        expect(config.deepCopyCollections, isTrue);
        expect(config.method, equals('replicate'));
        // Partial affix override preserves default suffix:
        expect(config.extension.prefix, equals('Ext_'));
        expect(config.extension.suffix, equals('Extension'));
      });
    });

    test('discovers defaults from top-level const CloneableDefaults variable',
        () async {
      const source = '''
library const_var_lib;

import 'package:cloneable/cloneable.dart';

const cloneableConfig = CloneableDefaults(
  output: CloneableOutput.inLibrary,
  ignoreNull: true,
  naming: CloneableNaming(method: 'clone'),
);

@Cloneable()
class Model {
  final String id;
  const Model({required this.id});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('const_var_lib');
        expect(library, isNotNull);

        final config = ConfigLoader.resolveDefaults(library: library);
        expect(config.output, equals(CloneableOutput.inLibrary));
        expect(config.ignoreNull, isTrue);
        expect(config.method, equals('clone'));
      });
    });
  });

  group('ConfigLoader Partial Affix Overrides', () {
    setUp(() {
      ConfigLoader.clearCache();
    });

    test('setting only prefix preserves default suffix', () async {
      const source = '''
@Cloneable.defaults(
  naming: CloneableNaming(
    mixin: CloneableAffix(prefix: 'Custom_'),
    file: CloneableAffix(prefix: 'generated_'),
  ),
)
library prefix_only_lib;

import 'package:cloneable/cloneable.dart';
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('prefix_only_lib');
        expect(library, isNotNull);

        final config = ConfigLoader.resolveDefaults(library: library);
        expect(config.mixin.prefix, equals('Custom_'));
        expect(config.mixin.suffix, equals('Cloneable'));
        expect(config.file.prefix, equals('generated_'));
        expect(config.file.suffix, equals('.cloneable.g'));
      });
    });

    test('setting only suffix preserves default prefix', () async {
      const source = '''
@Cloneable.defaults(
  naming: CloneableNaming(
    mixin: CloneableAffix(suffix: '_Capability'),
    extension: CloneableAffix(suffix: '_Methods'),
  ),
)
library suffix_only_lib;

import 'package:cloneable/cloneable.dart';
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('suffix_only_lib');
        expect(library, isNotNull);

        final config = ConfigLoader.resolveDefaults(library: library);
        expect(config.mixin.prefix, equals(r'_$'));
        expect(config.mixin.suffix, equals('_Capability'));
        expect(config.extension.prefix, equals(r'$'));
        expect(config.extension.suffix, equals('_Methods'));
      });
    });

    test('explicit empty string clears the prefix or suffix', () async {
      const source = '''
@Cloneable.defaults(
  naming: CloneableNaming(
    mixin: CloneableAffix(prefix: 'Clean', suffix: ''),
  ),
)
library empty_affix_lib;

import 'package:cloneable/cloneable.dart';
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('empty_affix_lib');
        expect(library, isNotNull);

        final config = ConfigLoader.resolveDefaults(library: library);
        expect(config.mixin.prefix, equals('Clean'));
        expect(config.mixin.suffix, equals(''));
      });
    });
  });

  group('CloneableGenerator SSOT Cascading Integration', () {
    const generator = CloneableGenerator();

    setUp(() {
      ConfigLoader.clearCache();
    });

    test(
        'class annotation @Cloneable overrides library @Cloneable.defaults settings',
        () async {
      const source = '''
@Cloneable.defaults(
  strategy: CloneableStrategy.extension,
  naming: CloneableNaming(method: 'projectMethod'),
)
library cascade_lib;

import 'package:cloneable/cloneable.dart';

@Cloneable()
class DefaultUser {
  final String name;
  const DefaultUser({required this.name});
}

@Cloneable(
  naming: CloneableNaming(method: 'classMethod'),
)
class CustomUser {
  final String name;
  const CustomUser({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('cascade_lib');
        final defaults = ConfigLoader.resolveDefaults(library: library);

        // DefaultUser inherits projectMethod:
        final defaultClass = library!.getClass('DefaultUser')!;
        final defaultAnnotation = defaultClass.metadata.first;
        final defaultOutput = generator.generateForClass(
          element: defaultClass,
          annotation: ConstantReader(defaultAnnotation.computeConstantValue()),
          inputFileName: 'cascade_lib.dart',
          resolvedDefaults: defaults,
        );
        expect(defaultOutput,
            contains(r'$DefaultUserProjectMethodFn get projectMethod'));

        // CustomUser overrides projectMethod with classMethod:
        final customClass = library.getClass('CustomUser')!;
        final customAnnotation = customClass.metadata.first;
        final customOutput = generator.generateForClass(
          element: customClass,
          annotation: ConstantReader(customAnnotation.computeConstantValue()),
          inputFileName: 'cascade_lib.dart',
          resolvedDefaults: defaults,
        );
        expect(
            customOutput, contains(r'$CustomUserCopyWithFn get classMethod'));
        expect(customOutput, isNot(contains('projectMethod')));
      });
    });

    test(
        'class-level partial affix preserves defaults and generates custom extension',
        () async {
      const source = '''
library class_affix_lib;

import 'package:cloneable/cloneable.dart';

@Cloneable(
  naming: CloneableNaming(
    extension: CloneableAffix(prefix: 'My'),
  ),
)
class Device {
  final String serial;
  const Device({required this.serial});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('class_affix_lib');
        final classElement = library!.getClass('Device')!;
        final annotation = classElement.metadata.first;

        final defaults = ConfigLoader.resolveDefaults(library: library);
        final output = generator.generateForClass(
          element: classElement,
          annotation: ConstantReader(annotation.computeConstantValue()),
          inputFileName: 'class_affix_lib.dart',
          resolvedDefaults: defaults,
        );

        // Prefix is 'My', suffix is default 'Extension'
        expect(output, contains('extension MyDeviceExtension on Device'));
      });
    });
  });
}
