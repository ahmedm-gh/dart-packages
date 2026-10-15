import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:cloneable_generator/src/cloneable_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

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

const Object cloneableUndefined = Object();

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

        expect(
            output, contains('typedef \$PersonCopyWith = Person Function({'));
        expect(output, contains('String name,'));
        expect(output, contains('int age,'));
        expect(output, contains('String? bio,'));
        expect(output, contains('mixin _\$PersonCloneable {'));
        expect(output, contains('\$PersonCopyWith get copyWith => _copyWith;'));
        expect(output, contains('Object? name = cloneableUndefined,'));
        expect(
            output,
            contains(
                'identical(name, cloneableUndefined) ? self.name : name as String'));
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

const Object cloneableUndefined = Object();

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

const Object cloneableUndefined = Object();

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

        expect(output,
            contains('typedef \$CleanPersonCopyWith = CleanPerson Function({'));
        expect(
            output,
            contains(
                'extension \$CleanPersonCloneableExtension on CleanPerson {'));
        expect(output,
            contains('\$CleanPersonCopyWith get copyWith => _copyWith;'));
        expect(output, contains('CleanPerson _copyWith({'));
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

    test('Diagnostics: throws when file missing part directive', () async {
      const source = '''
library test_lib;

class Cloneable {
  final String? constructor;
  const Cloneable({this.constructor});
}

@Cloneable()
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
            contains('must include the part directive'),
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
