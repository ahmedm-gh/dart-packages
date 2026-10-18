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

const Object cloneableUndefined = Object();

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
        final enumElement = library!.definingCompilationUnit.getEnum('MyEnum')!;
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
        'generateForAnnotatedElement does not recognize short _\$Person as mixin (defaults to extension in auto)',
        () async {
      const source = '''
library test_lib;

part 'test_lib.g.dart';

class Cloneable {
  const Cloneable();
}

const Object cloneableUndefined = Object();

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
        expect(output,
            contains('extension \$PersonCloneableExtension on Person {'));
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

const Object cloneableUndefined = Object();

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

        expect(output, contains('typedef \$PersonClone = Person Function({'));
        expect(output, contains('mixin _\$PersonClone {'));
        expect(output, contains('\$PersonClone get clone => _clone;'));
        expect(output, contains('Person _clone({'));
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

const Object cloneableUndefined = Object();

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

const Object cloneableUndefined = Object();

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

const Object cloneableUndefined = Object();

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
        // Emits extension
        expect(
            output,
            contains(
                'extension \$StandalonePersonCloneableExtension on StandalonePerson {'));
        expect(output,
            contains('\$StandalonePersonCopyWith get copyWith => _copyWith;'));
      });
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

const Object cloneableUndefined = Object();

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

const Object cloneableUndefined = Object();

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

const Object cloneableUndefined = Object();

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

        expect(output, contains('static const Object _undefined = Object();'));
        expect(output, contains('Object? name = _undefined,'));
        expect(output, contains('identical(name, _undefined)'));
        expect(output, isNot(contains('cloneableUndefined')));
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

        expect(output, contains('Object? name = c.cloneableUndefined,'));
        expect(output, contains('identical(name, c.cloneableUndefined)'));
        expect(output, isNot(contains('static const Object _undefined')));
      });
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

const Object cloneableUndefined = Object();

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
        expect(output, isNot(contains('static const Object _undefined')));
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

const Object cloneableUndefined = Object();

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

        // Typedef includes allowed fields but NOT excluded field
        expect(output, contains('typedef \$UserCopyWith = User Function({'));
        expect(output, contains('String name,'));
        expect(output, contains('int age,'));
        expect(output, isNot(contains('String email,')));

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

const Object cloneableUndefined = Object();

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

        expect(output, contains('typedef \$UserCopyWith = User Function({'));
        expect(output, contains('String name,'));
        expect(output, contains('int age,'));
        expect(output, isNot(contains('String email,')));
        expect(output, contains('email: self.email,'));
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

const Object cloneableUndefined = Object();

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

        expect(output, contains('typedef \$UserCopyWith = User Function({'));
        expect(output, contains('String name,'));
        expect(output, contains('int age,'));
        expect(output, isNot(contains('String email,')));
        expect(output, contains('email: self.email,'));
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

const Object cloneableUndefined = Object();

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

const Object cloneableUndefined = Object();

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

const Object cloneableUndefined = Object();

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

const Object cloneableUndefined = Object();

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

        expect(output, contains('typedef \$AliasedModelCopyWith'));
        expect(output, contains('mixin _\$AliasedModelCloneable'));

        final cloneableType = library.getClass('Cloneable')!.thisType;
        final annotated = LibraryReader(library)
            .annotatedWith(TypeChecker.fromStatic(cloneableType));
        expect(annotated, isNotEmpty);
        expect(annotated.first.element.name, equals('AliasedModel'));
      });
    });

    test(
        'generateForAnnotatedElement produces empty string when inline is true',
        () async {
      const source = '''
library test_lib;

class Cloneable {
  final bool inline;
  const Cloneable({this.inline = false});
}

@Cloneable(inline: true)
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
