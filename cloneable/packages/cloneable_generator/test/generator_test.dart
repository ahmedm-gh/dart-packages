import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:cloneable_generator/src/cloneable_generator.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

extension on Metadata {
  ElementAnnotation get first => annotations.first;
}

void main() {
  group('CloneableGenerator Direct Tests', () {
    const generator = CloneableGenerator();

    test('generateForAnnotatedElement produces expected mixin and interface',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  final String? constructor;
  const Cloneable({this.constructor});
}

class CloneableField {
  final bool ignore;
  const CloneableField({this.ignore = false});
}

const cloneableUndefined = Object();

@Cloneable()
class Person with _\$PersonCloneable {
  final String name;
  final int age;
  final String? bio;

  const Person({
    required this.name,
    required this.age,
    this.bio,
  });
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('Person')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('Person Function({'));
        expect(output, contains('String name,'));
        expect(output, contains('int age,'));
        expect(output, contains('String? bio,'));
        expect(output, contains('mixin _\$PersonCloneable {'));
        expect(output, contains('get copyWith => _copyWith;'));
        expect(output, isNot(contains('typedef')));
        expect(output, contains('Object? name = cloneableUndefined,'));
        expect(
            output,
            contains(
                'identical(name, cloneableUndefined) ? self.name : name as String'));
      });
    });

    test('generateForAnnotatedElement respects ignoreNull on class and field',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  final String? constructor;
  final bool deepCopyCollections;
  final bool ignoreNull;
  const Cloneable({
    this.constructor,
    this.deepCopyCollections = false,
    this.ignoreNull = false,
  });
}

class CloneableField {
  final bool ignore;
  final bool? deepCopy;
  final bool? ignoreNull;
  const CloneableField({this.ignore = false, this.deepCopy, this.ignoreNull});
}

const cloneableUndefined = Object();

@Cloneable()
class Config with _\$ConfigCloneable {
  final String host;

  @CloneableField(ignoreNull: true)
  final String? path;

  const Config({required this.host, this.path});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('Config')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(
            output,
            contains(
                'identical(path, cloneableUndefined) || path == null ? self.path : path as String?'));
      });
    });

    test(
        'generateForAnnotatedElement generates deep collection copies when enabled',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  final String? constructor;
  final bool deepCopyCollections;
  const Cloneable({this.constructor, this.deepCopyCollections = false});
}

class CloneableField {
  final bool ignore;
  final bool? deepCopy;
  const CloneableField({this.ignore = false, this.deepCopy});
}

const cloneableUndefined = Object();

@Cloneable(deepCopyCollections: true)
class Team with _\$TeamCloneable {
  final String name;
  final List<String> members;
  final Map<String, int>? scores;

  const Team({
    required this.name,
    required this.members,
    this.scores,
  });
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('Team')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('List.of(self.members)'));
        expect(output, contains('Map.of(self.scores!)'));
      });
    });

    test('Diagnostics: throws when applied to abstract class', () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  final String? constructor;
  const Cloneable({this.constructor});
}

@Cloneable()
abstract class AbstractPerson with _\$AbstractPersonCloneable {
  final String name;
  const AbstractPerson(this.name);
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('AbstractPerson')!;
        final annotation = classElement.metadata.first;

        expect(
          () => generator.generateForAnnotatedElement(
            classElement,
            ConstantReader(annotation.computeConstantValue()),
            _MockBuildStep('test_lib.dart'),
          ),
          throwsA(isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains('cannot be applied to abstract classes'),
          )),
        );
      });
    });

    test('Diagnostics: throws when applied to non-class element (e.g., enum)',
        () async {
      const source = '''
library test_lib;

class Cloneable {
  const Cloneable();
}

@Cloneable()
enum MyEnum { a, b }
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final enumElement =
            library!.enums.firstWhere((e) => e.name == 'MyEnum');
        final annotation = enumElement.metadata.first;

        expect(
          () => generator.generateForAnnotatedElement(
            enumElement,
            ConstantReader(annotation.computeConstantValue()),
            _MockBuildStep('test_lib.dart'),
          ),
          throwsA(isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains('can only be applied to classes'),
          )),
        );
      });
    });

    test(
        'generateForAnnotatedElement produces extension when mixin is omitted (auto)',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

enum CloneableStrategy { auto, extension, mixin }

class Cloneable {
  final String? constructor;
  final bool deepCopyCollections;
  final CloneableStrategy strategy;
  const Cloneable({
    this.constructor,
    this.deepCopyCollections = false,
    this.strategy = CloneableStrategy.auto,
  });
}

class CloneableField {
  final bool ignore;
  const CloneableField({this.ignore = false});
}

const cloneableUndefined = Object();

@Cloneable()
class CleanPerson {
  final String name;
  final int age;

  const CleanPerson({
    required this.name,
    required this.age,
  });
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('CleanPerson')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('CleanPerson Function({'));
        expect(output,
            contains('extension \$CleanPersonExtension on CleanPerson {'));
        expect(output, contains('get copyWith => _copyWith;'));
        expect(output, contains('CleanPerson _copyWith({'));
        expect(output, isNot(contains('typedef')));
      });
    });

    test(
        'generateForAnnotatedElement does not recognize short _\$Person as mixin (defaults to extension in auto)',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  const Cloneable();
}

const cloneableUndefined = Object();

@Cloneable()
class Person with _\$Person {
  final String name;
  const Person({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('Person')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        // Does NOT generate mixin _$Person (short _$Foo is disabled)
        expect(output, isNot(contains('mixin _\$Person {')));
        // Defaults to clean extension
        expect(output, contains('extension \$PersonExtension on Person {'));
      });
    });

    test(
        'generateForAnnotatedElement supports custom methodName via @Cloneable(methodName: "clone")',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  final String methodName;
  const Cloneable({this.methodName = 'copyWith'});
}

const cloneableUndefined = Object();

@Cloneable(methodName: 'clone')
class Person with _\$PersonClone {
  final String name;
  const Person({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('Person')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('Person Function({'));
        expect(output, contains('mixin _\$PersonClone {'));
        expect(output, contains('get clone => _clone;'));
        expect(output, contains('Person _clone({'));
        expect(output, isNot(contains('typedef')));
      });
    });

    test(
        'generateForAnnotatedElement produces only _\$PersonCopyWith when written',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  const Cloneable();
}

const cloneableUndefined = Object();

@Cloneable()
class Person with _\$PersonCopyWith {
  final String name;
  const Person({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('Person')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('mixin _\$PersonCopyWith {'));
        expect(output, isNot(contains('mixin _\$PersonCloneable {')));
        expect(output, isNot(contains('mixin _\$Person {')));
        expect(output, isNot(contains('extension \$PersonCloneableExtension')));
      });
    });

    test(
        'generateForAnnotatedElement produces only _\$PersonCloneable when written',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  const Cloneable();
}

const cloneableUndefined = Object();

@Cloneable()
class Person with _\$PersonCloneable {
  final String name;
  const Person({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('Person')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('mixin _\$PersonCloneable {'));
        expect(output, isNot(contains('mixin _\$Person {')));
        expect(output, isNot(contains('mixin _\$PersonCopyWith {')));
        expect(output, isNot(contains('extension \$PersonCloneableExtension')));
      });
    });

    test(
        'Diagnostics: throws when strategy is mixin but class is missing mixin',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

enum CloneableStrategy { auto, extension, mixin }

class Cloneable {
  final String? constructor;
  final bool deepCopyCollections;
  final CloneableStrategy strategy;
  const Cloneable({
    this.constructor,
    this.deepCopyCollections = false,
    this.strategy = CloneableStrategy.auto,
  });
}

@Cloneable(strategy: CloneableStrategy.mixin)
class MissingMixinPerson {
  final String name;
  const MissingMixinPerson(this.name);
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('MissingMixinPerson')!;
        final annotation = classElement.metadata.first;

        expect(
          () => generator.generateForAnnotatedElement(
            classElement,
            ConstantReader(annotation.computeConstantValue()),
            _MockBuildStep('test_lib.dart'),
          ),
          throwsA(isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains(
                "is configured with CloneableStrategy.mixin but does not mix in"),
          )),
        );
      });
    });

    test(
        'generateForAnnotatedElement generates standalone extension without part of when part directive is omitted',
        () async {
      const source = '''
library test_lib;

class Cloneable {
  final String methodName;
  const Cloneable({this.methodName = 'copyWith'});
}

const cloneableUndefined = Object();

@Cloneable()
class StandalonePerson {
  final String name;
  const StandalonePerson({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('StandalonePerson')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        // Does NOT use part of
        expect(output, isNot(contains('part of')));
        // Includes standalone imports
        expect(output, contains("import 'package:cloneable/cloneable.dart';"));
        expect(output, contains("import 'test_lib.dart';"));
        expect(
            output,
            contains(
                'extension \$StandalonePersonExtension on StandalonePerson {'));
        expect(output, contains('StandalonePerson Function({'));
        expect(output, contains('get copyWith => _copyWith;'));
        expect(output, isNot(contains('typedef')));
      });
    });

    test(
        'generateForAnnotatedElement includes external library imports in standalone extension when part directive is omitted',
        () async {
      await resolveSources(
        {
          'a|lib/external.dart': '''
library external_lib;
class Status {}
''',
          'a|lib/standalone.dart': '''
library test_lib;

import 'external.dart';
import 'external.dart' as ext;

class Cloneable {
  final String methodName;
  const Cloneable({this.methodName = 'copyWith'});
}

const cloneableUndefined = Object();

@Cloneable()
class StandaloneOrder {
  final Status status;
  final ext.Status extStatus;
  const StandaloneOrder({required this.status, required this.extStatus});
}
''',
        },
        (resolver) async {
          final library =
              await resolver.libraryFor(AssetId('a', 'lib/standalone.dart'));
          final classElement = library.getClass('StandaloneOrder')!;
          final annotation = classElement.metadata.first;

          final output = generator.generateForAnnotatedElement(
            classElement,
            ConstantReader(annotation.computeConstantValue()),
            _MockBuildStep('standalone.dart'),
          );

          expect(output, isNot(contains('part of')));
          expect(
              output, contains("import 'package:cloneable/cloneable.dart';"));
          expect(output, contains("import 'standalone.dart';"));
          expect(output, contains("import 'external.dart';"));
          expect(output, contains("import 'external.dart' as ext;"));
          expect(output, contains('Status status,'));
          expect(output, contains('ext.Status extStatus,'));
        },
      );
    });

    test(
        'generateForAnnotatedElement accepts selective part "test_lib_cloneable.g.dart"',
        () async {
      const source = '''
library test_lib;

part 'test_lib_cloneable.g.dart';

class Cloneable {
  const Cloneable();
}

const cloneableUndefined = Object();

@Cloneable()
class Person with _\$PersonCloneable {
  final String name;
  const Person({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('Person')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('mixin _\$PersonCloneable {'));
        expect(output,
            isNot(contains("import 'package:cloneable/cloneable.dart';")));
      });
    });

    test(
        'generateForAnnotatedElement accepts selective part "test_lib_copyWith.g.dart"',
        () async {
      const source = '''
library test_lib;

part 'test_lib_copyWith.g.dart';

class Cloneable {
  const Cloneable();
}

const cloneableUndefined = Object();

@Cloneable()
class Person with _\$PersonCopyWith {
  final String name;
  const Person({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('Person')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('mixin _\$PersonCopyWith {'));
        expect(output,
            isNot(contains("import 'package:cloneable/cloneable.dart';")));
      });
    });

    test(
        'generateForAnnotatedElement accepts selective part according to methodName "test_lib_clone.g.dart"',
        () async {
      const source = '''
library test_lib;

part 'test_lib_clone.g.dart';

class Cloneable {
  final String methodName;
  const Cloneable({this.methodName = 'copyWith'});
}

const cloneableUndefined = Object();

@Cloneable(methodName: 'clone')
class Person with _\$PersonClone {
  final String name;
  const Person({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('Person')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('mixin _\$PersonClone {'));
        expect(output, contains('get clone => _clone;'));
      });
    });

    test(
        'Diagnostics: throws when strategy is mixin but part directive is missing',
        () async {
      const source = '''
library test_lib;

enum CloneableStrategy { auto, extension, mixin }

class Cloneable {
  final CloneableStrategy strategy;
  const Cloneable({this.strategy = CloneableStrategy.auto});
}

@Cloneable(strategy: CloneableStrategy.mixin)
class MissingPartPerson with _\$MissingPartPersonCloneable {
  final String name;
  const MissingPartPerson(this.name);
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('MissingPartPerson')!;
        final annotation = classElement.metadata.first;

        expect(
          () => generator.generateForAnnotatedElement(
            classElement,
            ConstantReader(annotation.computeConstantValue()),
            _MockBuildStep('test_lib.dart'),
          ),
          throwsA(isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains('requires a part directive'),
          )),
        );
      });
    });

    test('Diagnostics: throws when named constructor not found', () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  final String? constructor;
  const Cloneable({this.constructor});
}

@Cloneable(constructor: 'nonExistent')
class BadConstructorPerson with _\$BadConstructorPersonCloneable {
  final String name;
  const BadConstructorPerson(this.name);
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('BadConstructorPerson')!;
        final annotation = classElement.metadata.first;

        expect(
          () => generator.generateForAnnotatedElement(
            classElement,
            ConstantReader(annotation.computeConstantValue()),
            _MockBuildStep('test_lib.dart'),
          ),
          throwsA(isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains("does not have a constructor named 'nonExistent'"),
          )),
        );
      });
    });

    test(
        'generateForAnnotatedElement generates private sentinel when sentinel is CloneableSentinel.private',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

enum CloneableSentinel { auto, private, package }

class Cloneable {
  final CloneableSentinel sentinel;
  const Cloneable({this.sentinel = CloneableSentinel.auto});
}

@Cloneable(sentinel: CloneableSentinel.private)
class Person with _\$PersonCloneable {
  final String name;
  const Person({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('Person')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains(r'const _$undefined = Object();'));
        expect(output, contains(r'Object? name = _$undefined,'));
        expect(output, contains(r'identical(name, _$undefined)'));
        expect(output, isNot(contains(r' = $undefined,')));
      });
    });

    test(
        'generateForAnnotatedElement uses prefix when package:cloneable is imported with prefix',
        () async {
      const source = '''
library test_lib;

import 'package:cloneable/cloneable.dart' as c;

part 'test_lib.g.dart';

@c.Cloneable()
class Person with _\$PersonCloneable {
  final String name;
  const Person({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('Person')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('Object? name = c.\$undefined,'));
        expect(output, contains('identical(name, c.\$undefined)'));
        expect(output, isNot(contains(r'const _$undefined')));
      });
    });

    test('generateForAnnotatedElement preserves prefixed types from AST',
        () async {
      await resolveSources(
        {
          'a|lib/external.dart': '''
library external_lib;
class CustomType {}
''',
          'a|lib/test_lib.dart': '''
library test_lib;
import 'external.dart' as ext;
part 'test_lib.g.dart';

class Cloneable {
  const Cloneable();
}

const cloneableUndefined = Object();

@Cloneable()
class PrefixedModel with _\$PrefixedModelCloneable {
  final ext.CustomType item;
  final ext.CustomType? optionalItem;
  final List<ext.CustomType> list;

  const PrefixedModel({
    required this.item,
    this.optionalItem,
    required this.list,
  });
}
''',
        },
        (resolver) async {
          final library =
              await resolver.libraryFor(AssetId('a', 'lib/test_lib.dart'));
          final classElement = library.getClass('PrefixedModel')!;
          final annotation = classElement.metadata.first;

          final output = generator.generateForAnnotatedElement(
            classElement,
            ConstantReader(annotation.computeConstantValue()),
            _MockBuildStep('test_lib.dart'),
          );

          expect(output, contains('ext.CustomType item,'));
          expect(output, contains('ext.CustomType? optionalItem,'));
          expect(output, contains('List<ext.CustomType> list,'));
          expect(output, contains('item as ext.CustomType'));
          expect(output, contains('optionalItem as ext.CustomType?'));
          expect(output, contains('list as List<ext.CustomType>'));
        },
      );
    });

    test(
        'generateForAnnotatedElement uses package sentinel when sentinel is CloneableSentinel.package',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

enum CloneableSentinel { auto, private, package }

class Cloneable {
  final CloneableSentinel sentinel;
  const Cloneable({this.sentinel = CloneableSentinel.auto});
}

const cloneableUndefined = Object();

@Cloneable(sentinel: CloneableSentinel.package)
class Person with _\$PersonCloneable {
  final String name;
  const Person({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('Person')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('Object? name = cloneableUndefined,'));
        expect(output, contains('identical(name, cloneableUndefined)'));
        expect(output, isNot(contains('static const _undefined')));
      });
    });

    test(
        'generateForAnnotatedElement produces empty string when active is false',
        () async {
      const source = '''
library test_lib;

class Cloneable {
  final bool active;
  const Cloneable({this.active = true});
}

@Cloneable(active: false)
class InactivePerson {
  final String name;
  const InactivePerson(this.name);
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('InactivePerson')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, isEmpty);
      });
    });

    test(
        'generateForAnnotatedElement ignores abstract/non-class elements when active is false without throwing',
        () async {
      const source = '''
library test_lib;

class Cloneable {
  final bool active;
  const Cloneable({this.active = true});
}

@Cloneable(active: false)
abstract class InactiveAbstractClass {
  final String name;
  const InactiveAbstractClass(this.name);
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('InactiveAbstractClass')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, isEmpty);
      });
    });

    test(
        'generateForAnnotatedElement respects whitelist via @Cloneable(fields: [...])',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  final List<String>? fields;
  const Cloneable({this.fields});
}

const cloneableUndefined = Object();

@Cloneable(fields: ['name', 'age'])
class User with _\$UserCloneable {
  final String name;
  final int age;
  final String email;

  const User({
    required this.name,
    required this.age,
    required this.email,
  });
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('User')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        // Function signature includes allowed fields but NOT excluded field
        expect(output, contains('User Function({'));
        expect(output, contains('String name,'));
        expect(output, contains('int age,'));
        expect(output, isNot(contains('String email,')));
        expect(output, isNot(contains('typedef')));

        // Call parameters include allowed fields
        expect(output, contains('Object? name = cloneableUndefined,'));
        expect(output, contains('Object? age = cloneableUndefined,'));
        expect(output, isNot(contains('Object? email = cloneableUndefined,')));

        // Constructor arguments pass self.email
        expect(output, contains('email: self.email,'));
      });
    });

    test(
        'generateForAnnotatedElement ignores class when fields is explicitly empty (like active = false)',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  final List<String>? fields;
  const Cloneable({this.fields});
}

@Cloneable(fields: [])
class EmptyWhitelistUser with _\$EmptyWhitelistUserCloneable {
  final String name;
  final int age;

  const EmptyWhitelistUser({required this.name, required this.age});
}

@Cloneable()
class InClassEmptyUser with _\$InClassEmptyUserCloneable {
  final String name;

  const InClassEmptyUser({required this.name});

  List<Object?> get cloneableFields => [];
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');

        // 1. Annotation explicitly empty
        final classElement = library!.getClass('EmptyWhitelistUser')!;
        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(classElement.metadata.first.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );
        expect(output, isEmpty);

        // 2. In-class getter explicitly empty
        final inClassElement = library.getClass('InClassEmptyUser')!;
        final inClassOutput = generator.generateForAnnotatedElement(
          inClassElement,
          ConstantReader(inClassElement.metadata.first.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );
        expect(inClassOutput, isEmpty);
      });
    });

    test(
        'generateForAnnotatedElement respects whitelist via in-class get cloneableFields => [...]',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  const Cloneable();
}

const cloneableUndefined = Object();

@Cloneable()
class User with _\$UserCloneable {
  final String name;
  final int age;
  final String email;

  const User({
    required this.name,
    required this.age,
    required this.email,
  });

  List<Object?> get cloneableFields => [name, age];
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('User')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('User Function({'));
        expect(output, contains('String name,'));
        expect(output, contains('int age,'));
        expect(output, isNot(contains('String email,')));
        expect(output, contains('email: self.email,'));
        expect(output, isNot(contains('typedef')));
      });
    });

    test(
        'generateForAnnotatedElement respects whitelist via in-class get copyWithFields => [...]',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  const Cloneable();
}

const cloneableUndefined = Object();

@Cloneable()
class User with _\$UserCloneable {
  final String name;
  final int age;
  final String email;

  const User({
    required this.name,
    required this.age,
    required this.email,
  });

  List<Object?> get copyWithFields => [name, age];
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('User')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('User Function({'));
        expect(output, contains('String name,'));
        expect(output, contains('int age,'));
        expect(output, isNot(contains('String email,')));
        expect(output, contains('email: self.email,'));
        expect(output, isNot(contains('typedef')));
      });
    });

    test(
        'generateForAnnotatedElement respects custom cloneableFieldsGetter in @Cloneable',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  final String? cloneableFieldsGetter;
  const Cloneable({this.cloneableFieldsGetter});
}

const cloneableUndefined = Object();

@Cloneable(cloneableFieldsGetter: 'allowedProps')
class CustomUser with _\$CustomUserCloneable {
  final String name;
  final int age;

  const CustomUser({required this.name, required this.age});

  List<Object?> get allowedProps => [name];
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('CustomUser')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('String name,'));
        expect(output, isNot(contains('int age,')));
        expect(output, contains('age: self.age,'));
      });
    });

    test(
        'generateForAnnotatedElement respects whitelist via in-class strings and block body',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  const Cloneable();
}

const cloneableUndefined = Object();

@Cloneable()
class StringUser with _\$StringUserCloneable {
  final String name;
  final int age;
  final String email;

  const StringUser({
    required this.name,
    required this.age,
    required this.email,
  });

  List<String> get cloneableFields {
    return ['name'];
  }
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');

        final stringUser = library!.getClass('StringUser')!;
        final stringOutput = generator.generateForAnnotatedElement(
          stringUser,
          ConstantReader(stringUser.metadata.first.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );
        expect(stringOutput, contains('String name,'));
        expect(stringOutput, isNot(contains('int age,')));
        expect(stringOutput, contains('age: self.age,'));
      });
    });

    test(
        'Diagnostics: throws when fields are specified in both @Cloneable(fields: ...) and in-class getter',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  final List<String>? fields;
  const Cloneable({this.fields});
}

@Cloneable(fields: ['name'])
class ConflictUser with _\$ConflictUserCloneable {
  final String name;
  final int age;

  const ConflictUser({required this.name, required this.age});

  List<Object?> get cloneableFields => [name, age];
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('ConflictUser')!;
        final annotation = classElement.metadata.first;

        expect(
          () => generator.generateForAnnotatedElement(
            classElement,
            ConstantReader(annotation.computeConstantValue()),
            _MockBuildStep('test_lib.dart'),
          ),
          throwsA(isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains(
                "Fields cannot be specified in both @Cloneable(fields: ...) and the 'cloneableFields' getter in class 'ConflictUser'."),
          )),
        );
      });
    });

    test(
        'Diagnostics: throws when multiple in-class field whitelist getters are defined',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  const Cloneable();
}

@Cloneable()
class MultiGetterUser with _\$MultiGetterUserCloneable {
  final String name;
  final int age;

  const MultiGetterUser({required this.name, required this.age});

  List<Object?> get cloneableFields => [name];
  List<Object?> get copyWithFields => [name, age];
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('MultiGetterUser')!;
        final annotation = classElement.metadata.first;

        expect(
          () => generator.generateForAnnotatedElement(
            classElement,
            ConstantReader(annotation.computeConstantValue()),
            _MockBuildStep('test_lib.dart'),
          ),
          throwsA(isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains(
                "Multiple in-class field whitelist getters found ('cloneableFields', 'copyWithFields') in class 'MultiGetterUser'."),
          )),
        );
      });
    });

    test(
        'Diagnostics: throws when cloneableFieldsGetter is specified but not found on class',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  final String? cloneableFieldsGetter;
  const Cloneable({this.cloneableFieldsGetter});
}

@Cloneable(cloneableFieldsGetter: 'nonExistentGetter')
class MissingGetterUser with _\$MissingGetterUserCloneable {
  final String name;

  const MissingGetterUser({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('MissingGetterUser')!;
        final annotation = classElement.metadata.first;

        expect(
          () => generator.generateForAnnotatedElement(
            classElement,
            ConstantReader(annotation.computeConstantValue()),
            _MockBuildStep('test_lib.dart'),
          ),
          throwsA(isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains(
                "Class 'MissingGetterUser' specifies cloneableFieldsGetter: 'nonExistentGetter', but no in-class getter or field named 'nonExistentGetter' was found."),
          )),
        );
      });
    });

    test(
        'Diagnostics: throws when field in fields does not match any constructor parameter',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  final List<String>? fields;
  const Cloneable({this.fields});
}

@Cloneable(fields: ['namme'])
class TypoUser with _\$TypoUserCloneable {
  final String name;
  final int age;

  const TypoUser({required this.name, required this.age});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('TypoUser')!;
        final annotation = classElement.metadata.first;

        expect(
          () => generator.generateForAnnotatedElement(
            classElement,
            ConstantReader(annotation.computeConstantValue()),
            _MockBuildStep('test_lib.dart'),
          ),
          throwsA(isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains(
                "Field 'namme' in '@Cloneable(fields: ...)' does not match any constructor parameter in class 'TypoUser'."),
          )),
        );
      });
    });

    test(
        'Diagnostics: throws when in-class fields getter does not return a list literal',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  const Cloneable();
}

@Cloneable()
class NonListUser with _\$NonListUserCloneable {
  final String name;

  const NonListUser({required this.name});

  List<Object?> get cloneableFields => null as dynamic;
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('NonListUser')!;
        final annotation = classElement.metadata.first;

        expect(
          () => generator.generateForAnnotatedElement(
            classElement,
            ConstantReader(annotation.computeConstantValue()),
            _MockBuildStep('test_lib.dart'),
          ),
          throwsA(isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains(
                "The 'cloneableFields' getter in class 'NonListUser' must return a list literal"),
          )),
        );
      });
    });

    test(
        'Diagnostics: throws when in-class fields list contains non-field identifier',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  const Cloneable();
}

@Cloneable()
class InvalidElementUser with _\$InvalidElementUserCloneable {
  final String name;

  const InvalidElementUser({required this.name});

  List<Object?> get cloneableFields => [name, 123];
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('InvalidElementUser')!;
        final annotation = classElement.metadata.first;

        expect(
          () => generator.generateForAnnotatedElement(
            classElement,
            ConstantReader(annotation.computeConstantValue()),
            _MockBuildStep('test_lib.dart'),
          ),
          throwsA(isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains(
                "The 'cloneableFields' list in class 'InvalidElementUser' must contain only field identifiers or field name strings."),
          )),
        );
      });
    });

    test(
        'generateForAnnotatedElement treats fields as regular field when in constructor',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  const Cloneable();
}

const cloneableUndefined = Object();

@Cloneable()
class ContainerModel with _\$ContainerModelCloneable {
  final List<String> fields;
  final String title;

  const ContainerModel({
    required this.fields,
    required this.title,
  });
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('ContainerModel')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        // fields is a constructor field, so it is included in copyWith!
        expect(output, contains('List<String> fields,'));
        expect(output, contains('String title,'));
      });
    });

    test('supports typedef alias e.g. typedef UseCopyWith = Cloneable',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  const Cloneable();
}

typedef UseCopyWith = Cloneable;

const cloneableUndefined = Object();

@UseCopyWith()
class AliasedModel with _\$AliasedModelCloneable {
  final String name;

  const AliasedModel({
    required this.name,
  });
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('AliasedModel')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('AliasedModel Function({'));
        expect(output, contains('mixin _\$AliasedModelCloneable'));
        expect(output, isNot(contains('typedef')));

        final cloneableType = library.getClass('Cloneable')!.thisType;
        final annotated = LibraryReader(library)
            .annotatedWith(TypeChecker.fromStatic(cloneableType));
        expect(annotated, isNotEmpty);
        expect(annotated.first.element.name, equals('AliasedModel'));
      });
    });

    test(
        'generateForAnnotatedElement produces empty string when output is inLibrary or inClass',
        () async {
      const source = '''
library test_lib;

enum CloneableOutput {
  auto,
  part,
  standalone,
  inLibrary,
  inClass;
}

class Cloneable {
  final CloneableOutput output;
  const Cloneable({this.output = CloneableOutput.auto});
}

@Cloneable(output: CloneableOutput.inLibrary)
class InlineModel {
  final String name;
  const InlineModel({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('InlineModel')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, isEmpty);
      });
    });

    test('generateForClass respects custom prefix with mixin (part approach)',
        () async {
      const source = r'''
library test_lib;

part 'test_lib.g.dart';

class CloneableAffix {
  final String prefix;
  final String suffix;
  const CloneableAffix({this.prefix = '', this.suffix = ''});
}

class CloneableNaming {
  final CloneableAffix part;
  const CloneableNaming({
    this.part = const CloneableAffix(),
  });
}

class Cloneable {
  final CloneableNaming naming;
  const Cloneable({this.naming = const CloneableNaming()});
}

const cloneableUndefined = Object();

@Cloneable(naming: CloneableNaming(part: CloneableAffix(prefix: '_', suffix: 'Cloneable')))
class CustomPerson with _CustomPersonCloneable {
  final String name;
  const CustomPerson({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('CustomPerson')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('CustomPerson Function({'));
        expect(output, contains('mixin _CustomPersonCloneable {'));
        expect(output, contains('get copyWith => _copyWith;'));
        expect(output, isNot(contains('typedef')));
      });
    });

    test(
        'generateForClass respects custom prefix with extension (standalone/no-part approach)',
        () async {
      const source = r'''
library test_lib;

class CloneableAffix {
  final String prefix;
  final String suffix;
  const CloneableAffix({this.prefix = '', this.suffix = ''});
}

class CloneableNaming {
  final CloneableAffix standalone;
  const CloneableNaming({
    this.standalone = const CloneableAffix(),
  });
}

class Cloneable {
  final CloneableNaming naming;
  const Cloneable({this.naming = const CloneableNaming()});
}

const cloneableUndefined = Object();

@Cloneable(naming: CloneableNaming(standalone: CloneableAffix(prefix: 'My')))
class StandaloneItem {
  final String title;
  const StandaloneItem({required this.title});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('StandaloneItem')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForClass(
          element: classElement,
          annotation: ConstantReader(annotation.computeConstantValue()),
          inputFileName: 'standalone_item.dart',
        );

        expect(output, contains('StandaloneItem Function({'));
        expect(
            output,
            contains(
                'extension MyStandaloneItemExtension on StandaloneItem {'));
        expect(output, contains('get copyWith => _copyWith;'));
        expect(output, isNot(contains('typedef')));
      });
    });

    test('generateForClass respects empty prefix (prefix: "")', () async {
      const source = r'''
library test_lib;

class CloneableAffix {
  final String prefix;
  final String suffix;
  const CloneableAffix({this.prefix = '', this.suffix = ''});
}

class CloneableNaming {
  final CloneableAffix standalone;
  const CloneableNaming({
    this.standalone = const CloneableAffix(),
  });
}

class Cloneable {
  final CloneableNaming naming;
  const Cloneable({this.naming = const CloneableNaming()});
}

const cloneableUndefined = Object();

@Cloneable(naming: CloneableNaming(standalone: CloneableAffix(prefix: '')))
class PlainUser {
  final String id;
  const PlainUser({required this.id});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('PlainUser')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForClass(
          element: classElement,
          annotation: ConstantReader(annotation.computeConstantValue()),
          inputFileName: 'plain_user.dart',
        );

        expect(output, contains('PlainUser Function({'));
        expect(output, contains('extension PlainUserExtension on PlainUser {'));
        expect(output, contains('get copyWith => _copyWith;'));
        expect(output, isNot(contains('typedef')));
      });
    });

    test('generator defaultPrefix is used when prefix is not set in annotation',
        () async {
      const customPrefixGen = CloneableGenerator(defaultPrefix: 'Gen');
      const source = r'''
library test_lib;

class CloneableAffix {
  final String prefix;
  final String suffix;
  const CloneableAffix({this.prefix = '', this.suffix = ''});
}

class CloneableNaming {
  final CloneableAffix? standalone;
  const CloneableNaming({
    this.standalone,
  });
}

class Cloneable {
  final CloneableNaming naming;
  const Cloneable({this.naming = const CloneableNaming()});
}

const cloneableUndefined = Object();

@Cloneable()
class FallbackUser {
  final String name;
  const FallbackUser({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('FallbackUser')!;
        final annotation = classElement.metadata.first;

        final output = customPrefixGen.generateForClass(
          element: classElement,
          annotation: ConstantReader(annotation.computeConstantValue()),
          inputFileName: 'fallback_user.dart',
        );

        expect(output, contains('FallbackUser Function({'));
        expect(output,
            contains('extension GenFallbackUserExtension on FallbackUser {'));
        expect(output, isNot(contains('typedef')));
      });
    });

    test(
        'strategy mixin error message includes customized prefix recommendation',
        () async {
      const source = r'''
library test_lib;

part 'test_lib.g.dart';

enum CloneableStrategy { auto, extension, mixin }

class CloneableAffix {
  final String prefix;
  final String suffix;
  const CloneableAffix({this.prefix = '', this.suffix = ''});
}

class CloneableNaming {
  final CloneableAffix mixin;
  const CloneableNaming({
    this.mixin = const CloneableAffix(prefix: r'_$', suffix: 'Cloneable'),
  });
}

class Cloneable {
  final CloneableStrategy strategy;
  final CloneableNaming naming;
  const Cloneable({
    this.strategy = CloneableStrategy.auto,
    this.naming = const CloneableNaming(),
  });
}

@Cloneable(
  strategy: CloneableStrategy.mixin,
  naming: CloneableNaming(mixin: CloneableAffix(prefix: 'Custom', suffix: 'Cloneable')),
)
class MissingMixinUser {
  final String name;
  const MissingMixinUser({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('MissingMixinUser')!;
        final annotation = classElement.metadata.first;

        expect(
          () => generator.generateForClass(
            element: classElement,
            annotation: ConstantReader(annotation.computeConstantValue()),
            inputFileName: 'test_lib.dart',
          ),
          throwsA(
            isA<InvalidGenerationSourceError>().having(
              (e) => e.message,
              'message',
              contains('_CustomMissingMixinUserCloneable'),
            ),
          ),
        );
      });
    });

    test('generateForClass respects custom suffix with mixin (part approach)',
        () async {
      const source = r'''
library test_lib;

part 'test_lib.g.dart';

class CloneableAffix {
  final String prefix;
  final String suffix;
  const CloneableAffix({this.prefix = '', this.suffix = ''});
}

class CloneableNaming {
  final CloneableAffix part;
  const CloneableNaming({
    this.part = const CloneableAffix(),
  });
}

class Cloneable {
  final CloneableNaming naming;
  const Cloneable({this.naming = const CloneableNaming()});
}

const cloneableUndefined = Object();

@Cloneable(naming: CloneableNaming(part: CloneableAffix(prefix: r'$', suffix: 'Copyable')))
class CustomSuffixPerson with _$CustomSuffixPersonCopyable {
  final String name;
  const CustomSuffixPerson({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('CustomSuffixPerson')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('mixin _\$CustomSuffixPersonCopyable {'));
        expect(output, contains('CustomSuffixPerson Function({'));
        expect(output, isNot(contains('typedef')));
      });
    });

    test(
        'generateForClass respects custom suffix with extension (standalone approach)',
        () async {
      const source = r'''
library test_lib;

class CloneableAffix {
  final String prefix;
  final String suffix;
  const CloneableAffix({this.prefix = '', this.suffix = ''});
}

class CloneableNaming {
  final CloneableAffix standalone;
  const CloneableNaming({
    this.standalone = const CloneableAffix(),
  });
}

class Cloneable {
  final CloneableNaming naming;
  const Cloneable({this.naming = const CloneableNaming()});
}

const cloneableUndefined = Object();

@Cloneable(naming: CloneableNaming(standalone: CloneableAffix(prefix: r'$', suffix: 'Copyable')))
class StandaloneItem {
  final String title;
  const StandaloneItem({required this.title});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('StandaloneItem')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForClass(
          element: classElement,
          annotation: ConstantReader(annotation.computeConstantValue()),
          inputFileName: 'standalone_item.dart',
        );

        expect(
            output,
            contains(
                'extension \$StandaloneItemCopyableExtension on StandaloneItem {'));
        expect(output, contains('StandaloneItem Function({'));
        expect(output, isNot(contains('typedef')));
      });
    });

    test('generateForClass respects granular mixin prefix and suffix overrides',
        () async {
      const source = r'''
library test_lib;

part 'test_lib.g.dart';

class CloneableAffix {
  final String prefix;
  final String suffix;
  const CloneableAffix({this.prefix = '', this.suffix = ''});
}

class CloneableNaming {
  final CloneableAffix mixin;
  const CloneableNaming({
    this.mixin = const CloneableAffix(prefix: r'_$', suffix: 'Cloneable'),
  });
}

class Cloneable {
  final CloneableNaming naming;
  const Cloneable({this.naming = const CloneableNaming()});
}

const cloneableUndefined = Object();

@Cloneable(
  naming: CloneableNaming(
    mixin: CloneableAffix(prefix: '_MyMix', suffix: 'Special'),
  ),
)
class GranularMixinUser with _MyMixGranularMixinUserSpecial {
  final String id;
  const GranularMixinUser({required this.id});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('GranularMixinUser')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForClass(
          element: classElement,
          annotation: ConstantReader(annotation.computeConstantValue()),
          inputFileName: 'test_lib.dart',
        );

        expect(output, contains('mixin _MyMixGranularMixinUserSpecial {'));
      });
    });

    test(
        'generateForClass respects granular extension prefix and suffix overrides',
        () async {
      const source = r'''
library test_lib;

class CloneableAffix {
  final String prefix;
  final String suffix;
  const CloneableAffix({this.prefix = '', this.suffix = ''});
}

class CloneableNaming {
  final CloneableAffix extension;
  const CloneableNaming({
    this.extension = const CloneableAffix(prefix: r'$', suffix: 'Extension'),
  });
}

class Cloneable {
  final CloneableNaming naming;
  const Cloneable({this.naming = const CloneableNaming()});
}

const cloneableUndefined = Object();

@Cloneable(
  naming: CloneableNaming(
    extension: CloneableAffix(prefix: 'Ext', suffix: 'CustomHelper'),
  ),
)
class GranularExtUser {
  final String name;
  const GranularExtUser({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('GranularExtUser')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForClass(
          element: classElement,
          annotation: ConstantReader(annotation.computeConstantValue()),
          inputFileName: 'granular_ext_user.dart',
        );

        expect(
            output,
            contains(
                'extension ExtGranularExtUserCustomHelper on GranularExtUser {'));
      });
    });

    test('generateForClass respects part affix in part approach', () async {
      const source = r'''
library test_lib;

part 'test_lib.g.dart';

class CloneableAffix {
  final String prefix;
  final String suffix;
  const CloneableAffix({this.prefix = '', this.suffix = ''});
}

class CloneableNaming {
  final CloneableAffix part;
  const CloneableNaming({
    this.part = const CloneableAffix(),
  });
}

class Cloneable {
  final CloneableNaming naming;
  const Cloneable({this.naming = const CloneableNaming()});
}

const cloneableUndefined = Object();

@Cloneable(
  naming: CloneableNaming(
    part: CloneableAffix(prefix: 'P', suffix: 'Part'),
  ),
)
class PartApproachUser with _PPartApproachUserPart {
  final String name;
  const PartApproachUser({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('PartApproachUser')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForClass(
          element: classElement,
          annotation: ConstantReader(annotation.computeConstantValue()),
          inputFileName: 'test_lib.dart',
        );

        expect(output, contains('mixin _PPartApproachUserPart {'));
        expect(output, contains('PartApproachUser Function({'));
        expect(output, isNot(contains('typedef')));
      });
    });

    test('generateForClass respects standalone affix in standalone approach',
        () async {
      const source = r'''
library test_lib;

class CloneableAffix {
  final String prefix;
  final String suffix;
  const CloneableAffix({this.prefix = '', this.suffix = ''});
}

class CloneableNaming {
  final CloneableAffix standalone;
  const CloneableNaming({
    this.standalone = const CloneableAffix(),
  });
}

class Cloneable {
  final CloneableNaming naming;
  const Cloneable({this.naming = const CloneableNaming()});
}

const cloneableUndefined = Object();

@Cloneable(
  naming: CloneableNaming(
    standalone: CloneableAffix(prefix: 'Solo', suffix: 'Standalone'),
  ),
)
class StandaloneApproachUser {
  final String name;
  const StandaloneApproachUser({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('StandaloneApproachUser')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForClass(
          element: classElement,
          annotation: ConstantReader(annotation.computeConstantValue()),
          inputFileName: 'standalone_approach_user.dart',
        );

        expect(
            output,
            contains(
                'extension SoloStandaloneApproachUserStandaloneExtension on StandaloneApproachUser {'));
        expect(output, contains('StandaloneApproachUser Function({'));
        expect(output, isNot(contains('typedef')));
      });
    });

    test('generateForClass respects inLibrary affix in inLibrary approach',
        () async {
      const source = r'''
library test_lib;

enum CloneableOutput {
  auto,
  part,
  standalone,
  inLibrary,
  inClass;
}

class CloneableAffix {
  final String prefix;
  final String suffix;
  const CloneableAffix({this.prefix = '', this.suffix = ''});
}

class CloneableNaming {
  final CloneableAffix inLibrary;
  const CloneableNaming({
    this.inLibrary = const CloneableAffix(),
  });
}

class Cloneable {
  final CloneableOutput output;
  final CloneableNaming naming;
  const Cloneable({
    this.output = CloneableOutput.auto,
    this.naming = const CloneableNaming(),
  });
}

const cloneableUndefined = Object();

@Cloneable(
  output: CloneableOutput.inLibrary,
  naming: CloneableNaming(
    inLibrary: CloneableAffix(prefix: 'In', suffix: 'Block'),
  ),
)
class InlineApproachUser {
  final String name;
  const InlineApproachUser({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('InlineApproachUser')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForClass(
          element: classElement,
          annotation: ConstantReader(annotation.computeConstantValue()),
          inputFileName: 'inline_approach_user.dart',
          isInline: true,
        );

        expect(
            output,
            contains(
                'extension InInlineApproachUserBlockExtension on InlineApproachUser {'));
        expect(output, contains('InlineApproachUser Function({'));
        expect(output, isNot(contains('typedef')));
      });
    });

    test(
        'generateForClass automatically detects inLibrary in annotation without explicit isInline param',
        () async {
      const source = r'''
library test_lib;

enum CloneableOutput {
  auto,
  part,
  standalone,
  inLibrary,
  inClass;
}

class CloneableAffix {
  final String prefix;
  final String suffix;
  const CloneableAffix({this.prefix = '', this.suffix = ''});
}

class CloneableNaming {
  final CloneableAffix inLibrary;
  const CloneableNaming({
    this.inLibrary = const CloneableAffix(),
  });
}

class Cloneable {
  final CloneableOutput output;
  final CloneableNaming naming;
  const Cloneable({
    this.output = CloneableOutput.auto,
    this.naming = const CloneableNaming(),
  });
}

const cloneableUndefined = Object();

@Cloneable(
  output: CloneableOutput.inLibrary,
  naming: CloneableNaming(
    inLibrary: CloneableAffix(prefix: 'AutoIn', suffix: 'Scope'),
  ),
)
class AutoInlineUser {
  final String name;
  const AutoInlineUser({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('AutoInlineUser')!;
        final annotation = classElement.metadata.first;

        // Note: isInline parameter is omitted (defaults to false)
        final output = generator.generateForClass(
          element: classElement,
          annotation: ConstantReader(annotation.computeConstantValue()),
          inputFileName: 'auto_inline_user.dart',
        );

        expect(
            output,
            contains(
                'extension AutoInAutoInlineUserScopeExtension on AutoInlineUser {'));
        expect(output, contains('AutoInlineUser Function({'));
        expect(output, isNot(contains('typedef')));
      });
    });

    test('generator defaultSuffix is used when suffix is not set in annotation',
        () async {
      const customSuffixGen = CloneableGenerator(defaultSuffix: 'Replica');
      const source = '''
library test_lib;

class Cloneable {
  const Cloneable();
}

const cloneableUndefined = Object();

@Cloneable()
class FallbackSuffixUser {
  final String name;
  const FallbackSuffixUser({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('FallbackSuffixUser')!;
        final annotation = classElement.metadata.first;

        final output = customSuffixGen.generateForClass(
          element: classElement,
          annotation: ConstantReader(annotation.computeConstantValue()),
          inputFileName: 'fallback_suffix_user.dart',
        );

        expect(
            output,
            contains(
                'extension \$FallbackSuffixUserReplicaExtension on FallbackSuffixUser {'));
      });
    });

    test(
        'strategy mixin error message includes customized suffix recommendation',
        () async {
      const source = r'''
library test_lib;

part 'test_lib.g.dart';

enum CloneableStrategy { auto, extension, mixin }

class CloneableAffix {
  final String prefix;
  final String suffix;
  const CloneableAffix({this.prefix = '', this.suffix = ''});
}

class CloneableNaming {
  final CloneableAffix mixin;
  const CloneableNaming({
    this.mixin = const CloneableAffix(prefix: r'_$', suffix: 'Cloneable'),
  });
}

class Cloneable {
  final CloneableStrategy strategy;
  final CloneableNaming naming;
  const Cloneable({
    this.strategy = CloneableStrategy.auto,
    this.naming = const CloneableNaming(),
  });
}

@Cloneable(
  strategy: CloneableStrategy.mixin,
  naming: CloneableNaming(mixin: CloneableAffix(prefix: r'_$', suffix: 'Copyable')),
)
class MissingMixinUser {
  final String name;
  const MissingMixinUser({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('MissingMixinUser')!;
        final annotation = classElement.metadata.first;

        expect(
          () => generator.generateForClass(
            element: classElement,
            annotation: ConstantReader(annotation.computeConstantValue()),
            inputFileName: 'test_lib.dart',
          ),
          throwsA(
            isA<InvalidGenerationSourceError>().having(
              (e) => e.message,
              'message',
              contains('_\$MissingMixinUserCopyable'),
            ),
          ),
        );
      });
    });

    test('fieldsConflict error throws when both annotation and getter exist',
        () async {
      const source = '''
library test_lib;

enum CloneableFieldsConflict { error, merge, inClass, inAnnotation }

class Cloneable {
  final List<String>? fields;
  final CloneableFieldsConflict fieldsConflict;
  const Cloneable({
    this.fields,
    this.fieldsConflict = CloneableFieldsConflict.error,
  });
}

const cloneableUndefined = Object();

@Cloneable(fields: ['name'])
class ConflictedClass {
  final String name;
  final int age;
  const ConflictedClass({required this.name, required this.age});

  List<Object?> get cloneableFields => [age];
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('ConflictedClass')!;
        final annotation = classElement.metadata.first;

        expect(
          () => generator.generateForClass(
            element: classElement,
            annotation: ConstantReader(annotation.computeConstantValue()),
            inputFileName: 'conflicted_class.dart',
          ),
          throwsA(
            isA<InvalidGenerationSourceError>().having(
              (e) => e.message,
              'message',
              contains(
                  "cannot be specified in both @Cloneable(fields: ...) and the 'cloneableFields' getter"),
            ),
          ),
        );
      });
    });

    test(
        'fieldsConflict merge combines fields from annotation and in-class getter',
        () async {
      const source = '''
library test_lib;

enum CloneableFieldsConflict { error, merge, inClass, inAnnotation }

class Cloneable {
  final List<String>? fields;
  final CloneableFieldsConflict fieldsConflict;
  const Cloneable({
    this.fields,
    this.fieldsConflict = CloneableFieldsConflict.error,
  });
}

const cloneableUndefined = Object();

@Cloneable(fields: ['id'], fieldsConflict: CloneableFieldsConflict.merge)
class MergedClass {
  final String id;
  final String name;
  final int age;
  const MergedClass({required this.id, required this.name, required this.age});

  List<Object?> get cloneableFields => [name];
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('MergedClass')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForClass(
          element: classElement,
          annotation: ConstantReader(annotation.computeConstantValue()),
          inputFileName: 'merged_class.dart',
        );

        expect(output, contains('String id,'));
        expect(output, contains('String name,'));
        expect(output, isNot(contains('int age,')));
      });
    });

    test('fieldsConflict inClass prefers in-class getter over annotation',
        () async {
      const source = '''
library test_lib;

enum CloneableFieldsConflict { error, merge, inClass, inAnnotation }

class Cloneable {
  final List<String>? fields;
  final CloneableFieldsConflict fieldsConflict;
  const Cloneable({
    this.fields,
    this.fieldsConflict = CloneableFieldsConflict.error,
  });
}

const cloneableUndefined = Object();

@Cloneable(fields: ['id'], fieldsConflict: CloneableFieldsConflict.inClass)
class InClassPreferenceClass {
  final String id;
  final String name;
  const InClassPreferenceClass({required this.id, required this.name});

  List<Object?> get cloneableFields => [name];
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('InClassPreferenceClass')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForClass(
          element: classElement,
          annotation: ConstantReader(annotation.computeConstantValue()),
          inputFileName: 'in_class_preference_class.dart',
        );

        expect(output, contains('String name,'));
        expect(output, isNot(contains('String id,')));
      });
    });

    test(
        'fieldsConflict inAnnotation prefers annotation list over in-class getter',
        () async {
      const source = '''
library test_lib;

enum CloneableFieldsConflict { error, merge, inClass, inAnnotation }

class Cloneable {
  final List<String>? fields;
  final CloneableFieldsConflict fieldsConflict;
  const Cloneable({
    this.fields,
    this.fieldsConflict = CloneableFieldsConflict.error,
  });
}

const cloneableUndefined = Object();

@Cloneable(fields: ['id'], fieldsConflict: CloneableFieldsConflict.inAnnotation)
class InAnnotationPreferenceClass {
  final String id;
  final String name;
  const InAnnotationPreferenceClass({required this.id, required this.name});

  List<Object?> get cloneableFields => [name];
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('InAnnotationPreferenceClass')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForClass(
          element: classElement,
          annotation: ConstantReader(annotation.computeConstantValue()),
          inputFileName: 'in_annotation_preference_class.dart',
        );

        expect(output, contains('String id,'));
        expect(output, isNot(contains('String name,')));
      });
    });

    test('raw class name with empty suffix generates and matches raw mixin',
        () async {
      const source = r'''
library test_lib;

part 'test_lib.g.dart';

class CloneableAffix {
  final String prefix;
  final String suffix;
  const CloneableAffix({this.prefix = '', this.suffix = ''});
}

class CloneableNaming {
  final CloneableAffix mixin;
  const CloneableNaming({
    this.mixin = const CloneableAffix(prefix: r'_$', suffix: 'Cloneable'),
  });
}

class Cloneable {
  final CloneableNaming naming;
  const Cloneable({this.naming = const CloneableNaming()});
}

const cloneableUndefined = Object();

@Cloneable(naming: CloneableNaming(mixin: CloneableAffix(suffix: '')))
class RawUser with _$RawUser {
  final String name;
  const RawUser({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('RawUser')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('mixin _\$RawUser {'));
        expect(output, contains('RawUser Function({'));
        expect(output, isNot(contains('typedef')));
      });
    });

    test('CloneableNaming configuration generates expected symbols', () async {
      const source = r'''
library test_lib;

part 'test_lib.g.dart';

class CloneableAffix {
  final String prefix;
  final String suffix;
  const CloneableAffix({this.prefix = '', this.suffix = ''});
}

class CloneableNaming {
  final CloneableAffix mixin;
  final CloneableAffix extension;
  const CloneableNaming({
    this.mixin = const CloneableAffix(prefix: r'_$', suffix: 'Cloneable'),
    this.extension = const CloneableAffix(prefix: r'$', suffix: 'Extension'),
  });
}

class Cloneable {
  final CloneableNaming naming;
  const Cloneable({this.naming = const CloneableNaming()});
}

const cloneableUndefined = Object();

@Cloneable(
  naming: CloneableNaming(
    extension: CloneableAffix(prefix: 'Ext', suffix: 'Extension'),
  ),
)
class NamingTestUser {
  final String title;
  const NamingTestUser({required this.title});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('NamingTestUser')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output,
            contains('extension ExtNamingTestUserExtension on NamingTestUser'));
        expect(output, contains('NamingTestUser Function({'));
        expect(output, isNot(contains('typedef')));
      });
    });

    test(
        'Diagnostics: throws when private class is used with standalone output',
        () async {
      const source = '''
library test_lib;

class Cloneable {
  const Cloneable();
}

@Cloneable()
class _PrivateUser {
  final String name;
  const _PrivateUser({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('_PrivateUser')!;
        final annotation = classElement.metadata.first;

        expect(
          () => generator.generateForAnnotatedElement(
            classElement,
            ConstantReader(annotation.computeConstantValue()),
            _MockBuildStep('test_lib.dart'),
          ),
          throwsA(
            isA<InvalidGenerationSourceError>().having(
              (e) => e.message,
              'message',
              contains('Class \'_PrivateUser\' is private'),
            ),
          ),
        );
      });
    });

    test(
        'Diagnostics: throws when private constructor is used with standalone output',
        () async {
      const source = '''
library test_lib;

class Cloneable {
  final String? constructor;
  const Cloneable({this.constructor});
}

@Cloneable(constructor: '_internal')
class UserWithPrivateCtor {
  final String name;
  const UserWithPrivateCtor._internal({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('UserWithPrivateCtor')!;
        final annotation = classElement.metadata.first;

        expect(
          () => generator.generateForAnnotatedElement(
            classElement,
            ConstantReader(annotation.computeConstantValue()),
            _MockBuildStep('test_lib.dart'),
          ),
          throwsA(
            isA<InvalidGenerationSourceError>().having(
              (e) => e.message,
              'message',
              contains(
                  'Constructor \'_internal\' of class \'UserWithPrivateCtor\' is private'),
            ),
          ),
        );
      });
    });

    test('accepts part file located in configured custom directory', () async {
      const source = '''
library test_lib;

part 'generated/test_lib.cloneable.g.dart';

class CloneableAffix {
  final String? prefix;
  final String? suffix;
  const CloneableAffix({this.prefix, this.suffix});
}

class CloneableNaming {
  final String? directory;
  final CloneableAffix file;
  const CloneableNaming({
    this.directory,
    this.file = const CloneableAffix(prefix: '', suffix: '.cloneable.g'),
  });
}

class Cloneable {
  final CloneableNaming? naming;
  const Cloneable({this.naming});
}

@Cloneable(
  naming: CloneableNaming(directory: 'generated'),
)
class SubdirUser {
  final String name;
  const SubdirUser({required this.name});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('SubdirUser')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(
            output, contains('extension \$SubdirUserExtension on SubdirUser'));
      });
    });

    test('built-in Uint8List deep cloning when deepCopy is true', () async {
      const source = '''
library test_lib;
import 'dart:typed_data';

class Cloneable {
  final bool deepCopyCollections;
  const Cloneable({this.deepCopyCollections = false});
}

class CloneableField {
  final bool? deepCopy;
  final Function? cloner;
  const CloneableField({this.deepCopy, this.cloner});
}

const \$undefined = Object();

@Cloneable(deepCopyCollections: true)
class BufferModel {
  final Uint8List bytes;
  const BufferModel({required this.bytes});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('BufferModel')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('Uint8List.fromList(self.bytes)'));
        expect(output, contains('Uint8List.fromList(bytes as Uint8List)'));
      });
    });

    test('built-in Queue deep cloning when deepCopy is true', () async {
      const source = '''
library test_lib;
import 'dart:collection';

class Cloneable {
  final bool deepCopyCollections;
  const Cloneable({this.deepCopyCollections = false});
}

class CloneableField {
  final bool? deepCopy;
  final Function? cloner;
  const CloneableField({this.deepCopy, this.cloner});
}

const \$undefined = Object();

@Cloneable(deepCopyCollections: true)
class QueueModel {
  final Queue<String> tasks;
  const QueueModel({required this.tasks});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('QueueModel')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('Queue.of(self.tasks)'));
        expect(output, contains('Queue.of(tasks as Queue<String>)'));
      });
    });

    test('custom cloner has priority over built-in deep copy', () async {
      const source = '''
library test_lib;
import 'dart:typed_data';

class Cloneable {
  final bool deepCopyCollections;
  const Cloneable({this.deepCopyCollections = false});
}

class CloneableField {
  final bool? deepCopy;
  final Function? cloner;
  const CloneableField({this.deepCopy, this.cloner});
}

const \$undefined = Object();

Uint8List customCloner(Uint8List val) => val;

@Cloneable(deepCopyCollections: true)
class CustomClonerModel {
  @CloneableField(cloner: customCloner)
  final Uint8List bytes;
  const CustomClonerModel({required this.bytes});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('CustomClonerModel')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains('customCloner(self.bytes)'));
        expect(output, contains('customCloner(bytes as Uint8List)'));
        expect(output, isNot(contains('Uint8List.fromList')));
      });
    });

    test(
        'standalone output imports dart:typed_data only when needed and deepCopy is true',
        () async {
      const sourceWithDeepCopy = '''
library test_lib;

enum CloneableOutput { auto, part, standalone, inLibrary, inClass }

class Cloneable {
  final CloneableOutput output;
  final bool deepCopyCollections;
  const Cloneable({this.output = CloneableOutput.auto, this.deepCopyCollections = false});
}

class CloneableField {
  final bool? deepCopy;
  final Function? cloner;
  const CloneableField({this.deepCopy, this.cloner});
}

abstract class Uint8List {}

const \$undefined = Object();

@Cloneable(output: CloneableOutput.standalone, deepCopyCollections: true)
class StandaloneTypedData {
  final Uint8List buffer;
  const StandaloneTypedData({required this.buffer});
}
''';

      await resolveSource(sourceWithDeepCopy, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('StandaloneTypedData')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib.dart'),
        );

        expect(output, contains("import 'dart:typed_data';"));
      });

      const sourceWithoutDeepCopy = '''
library test_lib2;

enum CloneableOutput { auto, part, standalone, inLibrary, inClass }

class Cloneable {
  final CloneableOutput output;
  final bool deepCopyCollections;
  const Cloneable({this.output = CloneableOutput.auto, this.deepCopyCollections = false});
}

const \$undefined = Object();

@Cloneable(output: CloneableOutput.standalone, deepCopyCollections: false)
class StandaloneNoDeepCopy {
  final String text;
  const StandaloneNoDeepCopy({required this.text});
}
''';

      await resolveSource(sourceWithoutDeepCopy, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib2');
        final classElement = library!.getClass('StandaloneNoDeepCopy')!;
        final annotation = classElement.metadata.first;

        final output = generator.generateForAnnotatedElement(
          classElement,
          ConstantReader(annotation.computeConstantValue()),
          _MockBuildStep('test_lib2.dart'),
        );

        expect(output, isNot(contains("import 'dart:typed_data';")));
      });
    });

    test('standalone output throws when private cloner is used', () async {
      const source = '''
library test_lib;

enum CloneableOutput { auto, part, standalone, inLibrary, inClass }

class Cloneable {
  final CloneableOutput output;
  const Cloneable({this.output = CloneableOutput.auto});
}

class CloneableField {
  final Function? cloner;
  const CloneableField({this.cloner});
}

const \$undefined = Object();

String _privateCloner(String val) => val;

@Cloneable(output: CloneableOutput.standalone)
class PrivateClonerModel {
  @CloneableField(cloner: _privateCloner)
  final String text;
  const PrivateClonerModel({required this.text});
}
''';

      await resolveSource(source, (resolver) async {
        final library = await resolver.findLibraryByName('test_lib');
        final classElement = library!.getClass('PrivateClonerModel')!;
        final annotation = classElement.metadata.first;

        expect(
          () => generator.generateForAnnotatedElement(
            classElement,
            ConstantReader(annotation.computeConstantValue()),
            _MockBuildStep('test_lib.dart'),
          ),
          throwsA(isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains(
                "Cloner function '_privateCloner' on field 'text' of class 'PrivateClonerModel' is private"),
          )),
        );
      });
    });
  });
}

// ignore: subtype_of_sealed_class
class _MockBuildStep implements BuildStep {
  final String fileName;
  _MockBuildStep(this.fileName);

  @override
  AssetId get inputId => AssetId('test_pkg', 'lib/$fileName');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
