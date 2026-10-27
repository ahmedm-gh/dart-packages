import 'package:caster/caster.dart';
import 'package:test/test.dart';

class CustomUser {
  final String name;
  const CustomUser(this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CustomUser && other.name == name);

  @override
  int get hashCode => name.hashCode;
}

void main() {
  tearDown(() {
    Caster.resetDefaultValues();
    Caster.debug = false;
  });

  group('safeCast', () {
    test('throws CasterArgumentException if T is Object', () {
      expect(
        () => safeCast<Object>('hello'),
        throwsA(
          isA<CasterArgumentException>().having(
            (e) => e.message,
            'message',
            contains('Type parameter T must be specified, got Object.'),
          ),
        ),
      );
    });

    test('returns direct match immediately', () {
      expect(safeCast<int>(42), equals(42));
      expect(safeCast<String>('dart'), equals('dart'));
      expect(safeCast<double>(3.14), equals(3.14));
      expect(safeCast<bool>(true), isTrue);
      expect(safeCast<List<int>>([1, 2, 3]), equals([1, 2, 3]));
      expect(
        safeCast<CustomUser>(const CustomUser('Alice')),
        equals(const CustomUser('Alice')),
      );
    });

    test('returns null when input is null and T is nullable', () {
      expect(safeCast<String?>(null), isNull);
      expect(safeCast<int?>(null), isNull);
    });

    test('uses explicit fallback when input cannot be cast', () {
      expect(safeCast<int>('not an int', fallback: 99), equals(99));
      expect(safeCast<String>(123, fallback: 'default'), equals('default'));
      expect(safeCast<bool>('yes', fallback: true), isTrue);
    });

    test('does not use fallback if input already matches T', () {
      expect(safeCast<int>(10, fallback: 99), equals(10));
      expect(safeCast<String?>('ok', fallback: 'fallback'), equals('ok'));
    });

    group('custom registered defaults', () {
      test('registers and resolves custom default', () {
        const defaultUser = CustomUser('Guest');
        Caster.registerDefaultValues({CustomUser: defaultUser});

        final result = safeCast<CustomUser>('invalid input');
        expect(result, equals(defaultUser));
      });

      test('resets registered defaults', () {
        const defaultUser = CustomUser('Guest');
        Caster.registerDefaultValues({CustomUser: defaultUser});
        Caster.resetDefaultValues();

        expect(
          () => safeCast<CustomUser>('invalid input'),
          throwsA(isA<CasterTypeException>()),
        );
      });

      test('unregisters specific default', () {
        const defaultUser = CustomUser('Guest');
        Caster.registerDefaultValues({CustomUser: defaultUser});

        final removed = Caster.unregisterDefaultValue<CustomUser>();
        expect(removed, isTrue);

        final removedAgain = Caster.unregisterDefaultValue<CustomUser>();
        expect(removedAgain, isFalse);

        expect(
          () => safeCast<CustomUser>('invalid input'),
          throwsA(isA<CasterTypeException>()),
        );
      });

      test(
        'explicit fallback takes precedence over custom registered default',
        () {
          const defaultUser = CustomUser('RegisteredDefault');
          const fallbackUser = CustomUser('ExplicitFallback');
          Caster.registerDefaultValues({CustomUser: defaultUser});

          final result = safeCast<CustomUser>(
            'invalid',
            fallback: fallbackUser,
          );
          expect(result, equals(fallbackUser));
        },
      );

      test('respects useDefaults flag for custom registered defaults', () {
        const defaultUser = CustomUser('Admin');
        Caster.registerDefaultValues({CustomUser: defaultUser});

        expect(safeCast<CustomUser>('invalid'), equals(defaultUser));
        expect(
          safeCast<CustomUser>('invalid', useDefaults: true),
          equals(defaultUser),
        );
        expect(
          () => safeCast<CustomUser>('invalid', useDefaults: false),
          throwsA(isA<CasterTypeException>()),
        );
      });

      test('registerDefaultValue and unregisterDefaultValues single/multiple registration', () {
        const defaultUser = CustomUser('SingleGuest');
        Caster.registerDefaultValue<CustomUser>(defaultUser);

        expect(safeCast<CustomUser>('invalid'), equals(defaultUser));

        Caster.unregisterDefaultValues([CustomUser]);
        expect(
          () => safeCast<CustomUser>('invalid'),
          throwsA(isA<CasterTypeException>()),
        );
      });
    });

    group('built-in type defaults', () {
      test('primitives default values', () {
        expect(safeCast<int>('bad'), equals(0));
        expect(safeCast<double>('bad'), equals(0.0));
        expect(safeCast<num>('bad'), equals(0));
        expect(safeCast<bool>('bad'), isFalse);
        expect(safeCast<String>(12345), equals(''));
      });

      test('list and iterable default values', () {
        expect(safeCast<Iterable>('bad'), equals([]));
        expect(safeCast<List>('bad'), equals([]));
        expect(safeCast<Iterable<int>>('bad'), equals(<int>[]));
        expect(safeCast<List<int>>('bad'), equals(<int>[]));
        expect(safeCast<Iterable<int?>>('bad'), equals(<int?>[]));
        expect(safeCast<List<int?>>('bad'), equals(<int?>[]));
        expect(safeCast<Iterable<String>>('bad'), equals(<String>[]));
        expect(safeCast<List<String>>('bad'), equals(<String>[]));
        expect(safeCast<Iterable<String?>>('bad'), equals(<String?>[]));
        expect(safeCast<List<String?>>('bad'), equals(<String?>[]));
        expect(safeCast<Iterable<double>>('bad'), equals(<double>[]));
        expect(safeCast<List<double>>('bad'), equals(<double>[]));
        expect(safeCast<Iterable<double?>>('bad'), equals(<double?>[]));
        expect(safeCast<List<double?>>('bad'), equals(<double?>[]));
        expect(safeCast<Iterable<num>>('bad'), equals(<num>[]));
        expect(safeCast<List<num>>('bad'), equals(<num>[]));
        expect(safeCast<Iterable<num?>>('bad'), equals(<num?>[]));
        expect(safeCast<List<num?>>('bad'), equals(<num?>[]));
        expect(safeCast<Iterable<bool>>('bad'), equals(<bool>[]));
        expect(safeCast<List<bool>>('bad'), equals(<bool>[]));
        expect(safeCast<Iterable<bool?>>('bad'), equals(<bool?>[]));
        expect(safeCast<List<bool?>>('bad'), equals(<bool?>[]));
      });

      test('set default values', () {
        expect(safeCast<Set>('bad'), equals(<Object?>{}));
        expect(safeCast<Set<int>>('bad'), equals(<int>{}));
        expect(safeCast<Set<int?>>('bad'), equals(<int?>{}));
        expect(safeCast<Set<String>>('bad'), equals(<String>{}));
        expect(safeCast<Set<String?>>('bad'), equals(<String?>{}));
        expect(safeCast<Set<double>>('bad'), equals(<double>{}));
        expect(safeCast<Set<double?>>('bad'), equals(<double?>{}));
        expect(safeCast<Set<num>>('bad'), equals(<num>{}));
        expect(safeCast<Set<num?>>('bad'), equals(<num?>{}));
        expect(safeCast<Set<bool>>('bad'), equals(<bool>{}));
        expect(safeCast<Set<bool?>>('bad'), equals(<bool?>{}));
      });

      test('map default values', () {
        expect(safeCast<Map>('bad'), equals(<Object?, Object?>{}));
        expect(
          safeCast<Map<Object?, Object?>>('bad'),
          equals(<Object?, Object?>{}),
        );
        expect(
          safeCast<Map<String, dynamic>>('bad'),
          equals(<String, dynamic>{}),
        );
        expect(
          safeCast<Map<String, Object?>>('bad'),
          equals(<String, Object?>{}),
        );
        expect(
          safeCast<Map<String, String>>('bad'),
          equals(<String, String>{}),
        );
      });

      test('respects useDefaults: false for built-in type defaults', () {
        expect(
          () => safeCast<int>('bad', useDefaults: false),
          throwsA(isA<CasterTypeException>()),
        );
        expect(
          () => safeCast<String>(123, useDefaults: false),
          throwsA(isA<CasterTypeException>()),
        );
        expect(
          () => safeCast<bool>('bad', useDefaults: false),
          throwsA(isA<CasterTypeException>()),
        );
        expect(
          () => safeCast<List<int>>('bad', useDefaults: false),
          throwsA(isA<CasterTypeException>()),
        );
      });

      test('Caster.builtInDefault returns built-in default values', () {
        expect(Caster.builtInDefault<int>(), equals(0));
        expect(Caster.builtInDefault<String>(), equals(''));
        expect(Caster.builtInDefault<bool>(), isFalse);
        expect(Caster.builtInDefault<double>(), equals(0.0));
        expect(Caster.builtInDefault<List<int>>(), equals(<int>[]));
        expect(Caster.builtInDefault<CustomUser>(), isNull);
      });
    });

    test(
      'returns null for uncastable input when T is nullable and has no default',
      () {
        expect(safeCast<CustomUser?>('bad'), isNull);
        expect(safeCast<DateTime?>('not a date'), isNull);
      },
    );

    test('throws CasterTypeException when input cannot be cast and no default exists', () {
      expect(
        () => safeCast<CustomUser>('bad'),
        throwsA(
          isA<CasterTypeException>().having(
            (e) => e.message,
            'message',
            contains('Can not cast String to CustomUser'),
          ),
        ),
      );
    });

    test('executes safely when Caster.debug is true', () {
      Caster.debug = true;
      expect(safeCast<int>('abc', fallback: 42), equals(42));
      expect(safeCast<int>('bad'), equals(0));
    });
  });

  group('safeCastOrNull', () {
    test('throws CasterArgumentException if T is Object', () {
      expect(
        () => safeCastOrNull<Object>('hello'),
        throwsA(isA<CasterArgumentException>()),
      );
    });

    test('returns direct match', () {
      expect(safeCastOrNull<int>(42), equals(42));
      expect(safeCastOrNull<String>('dart'), equals('dart'));
    });

    test('returns null for incompatible input without throwing', () {
      expect(safeCastOrNull<int>('123'), isNull);
      expect(safeCastOrNull<CustomUser>('not a user'), isNull);
      expect(safeCastOrNull<bool>(1), isNull);
    });

    test('executes safely when Caster.debug is true', () {
      Caster.debug = true;
      final result = safeCastOrNull<int>('invalid');
      expect(result, isNull);
    });
  });

  group('MapCaster', () {
    final map = <String, Object?>{
      'age': 25,
      'name': 'Bob',
      'scores': [90, 80, 70],
      'mixed': [1, 'two', 3],
      'active': true,
      'nullField': null,
    };

    test('safeCast extracts matching value', () {
      expect(map.safeCast<int>('age'), equals(25));
      expect(map.safeCast<String>('name'), equals('Bob'));
      expect(map.safeCast<bool>('active'), isTrue);
    });

    test('safeCast uses fallback or type default when missing or invalid', () {
      expect(map.safeCast<int>('non_existent', fallback: 100), equals(100));
      expect(map.safeCast<int>('name', fallback: -1), equals(-1));
      expect(map.safeCast<int>('name'), equals(0)); // Built-in default
    });

    test('safeCast and safeCastFirst respect useDefaults: false', () {
      expect(
        () => map.safeCast<int>('name', useDefaults: false),
        throwsA(isA<CasterTypeException>()),
      );
      expect(
        () => map.safeCastFirst<int>([
          'missing1',
          'missing2',
        ], useDefaults: false),
        throwsA(isA<CasterTypeException>()),
      );
    });

    test(
      'safeCastOrNull returns value or null on mismatch without throwing',
      () {
        expect(map.safeCastOrNull<int>('age'), equals(25));
        expect(map.safeCastOrNull<int>('name'), isNull);
        expect(map.safeCastOrNull<int>('missing_key'), isNull);
      },
    );

    test('safeCastFirst evaluates keys in order', () {
      expect(map.safeCastFirst<int>(['missing', 'age']), equals(25));
      expect(
        map.safeCastFirst<String>([
          'firstMissing',
          'secondMissing',
        ], fallback: 'def'),
        equals('def'),
      );
      expect(map.safeCastFirst<String?>(['nullField']), isNull);
    });

    test('safeCastList extracts matching collection elements', () {
      expect(map.safeCastList<int>('scores'), equals([90, 80, 70]));
      expect(map.safeCastList<int>('mixed'), equals([1, 3]));
      expect(map.safeCastList<int>('mixed', fallback: 0), equals([1, 0, 3]));
      expect(map.safeCastList<int>('non_existent'), equals([]));
      expect(map.safeCastList<int>('name'), equals([])); // not an iterable
    });

    test(
      'safeCastListOrNull returns collection or null if absent/non-iterable',
      () {
        expect(map.safeCastListOrNull<int>('scores'), equals([90, 80, 70]));
        expect(map.safeCastListOrNull<int>('mixed'), equals([1, 3]));
        expect(
          map.safeCastListOrNull<int>('mixed', fallback: 0),
          equals([1, 0, 3]),
        );
        expect(map.safeCastListOrNull<int>('non_existent'), isNull);
        expect(map.safeCastListOrNull<int>('name'), isNull); // not an iterable
        expect(map.safeCastListOrNull<int>('nullField'), isNull);
      },
    );

    test('tryConvert converts value or returns fallback/null', () {
      final parsed = map.tryConvert<DateTime>(
        'name',
        converter: (v) => DateTime.tryParse(v.toString()),
      );
      expect(parsed, isNull);

      final parsedWithFallback = map.tryConvert<DateTime>(
        'name',
        converter: (v) => DateTime.tryParse(v.toString()),
        fallback: DateTime(2026, 1, 1),
      );
      expect(parsedWithFallback, equals(DateTime(2026, 1, 1)));

      final stringLen = map.tryConvert<int>(
        'name',
        converter: (v) => v is String ? v.length : null,
      );
      expect(stringLen, equals(3));

      final missing = map.tryConvert<int>(
        'missing_key',
        converter: (v) => 42,
        fallback: 10,
      );
      expect(missing, equals(10)); // missing key returns fallback

      final presentNull = map.tryConvert<int>(
        'nullField',
        converter: (v) => 42,
        fallback: 10,
      );
      expect(presentNull, equals(42)); // present null key invokes converter
    });

    test('convert transforms existing value and falls back on null/absent', () {
      final parsed = map.convert<DateTime>(
        'name',
        converter: (v) => DateTime.tryParse(v.toString()),
        fallback: DateTime(2026, 1, 1),
      );
      expect(parsed, equals(DateTime(2026, 1, 1)));

      final stringLen = map.convert<int>(
        'name',
        converter: (v) => v is String ? v.length : null,
        fallback: 0,
      );
      expect(stringLen, equals(3));
    });

    test(
      'convertList transforms elements and filters nulls or applies fallback',
      () {
        final lengths = map.convertList<int>(
          'scores',
          converter: (v) => v is int ? v * 2 : null,
        );
        expect(lengths, equals([180, 160, 140]));

        final mixedWithFallback = map.convertList<int>(
          'mixed',
          converter: (v) => v is int ? v : null,
          fallback: 0,
        );
        expect(mixedWithFallback, equals([1, 0, 3]));

        final empty = map.convertList<int>('non_existent', converter: (v) => 1);
        expect(empty, isEmpty);

        final notIterable = map.convertList<int>('age', converter: (v) => 1);
        expect(notIterable, isEmpty);
      },
    );

    test(
      'convertListOrNull returns collection or null if absent/non-iterable',
      () {
        final valid = map.convertListOrNull<int>(
          'scores',
          converter: (v) => v is int ? v * 2 : null,
        );
        expect(valid, equals([180, 160, 140]));

        final mixedWithFallback = map.convertListOrNull<int>(
          'mixed',
          converter: (v) => v is int ? v : null,
          fallback: 0,
        );
        expect(mixedWithFallback, equals([1, 0, 3]));

        final absent = map.convertListOrNull<int>(
          'non_existent',
          converter: (v) => 1,
        );
        expect(absent, isNull);

        final notIterable = map.convertListOrNull<int>(
          'age',
          converter: (v) => 1,
        );
        expect(notIterable, isNull);

        final nullField = map.convertListOrNull<int>(
          'nullField',
          converter: (v) => 1,
        );
        expect(nullField, isNull);
      },
    );
  });

  group('Exceptions', () {
    test('CasterArgumentException properties and toString', () {
      const exception = CasterException.argument('custom arg error');
      expect(exception, isA<CasterArgumentException>());
      expect(exception, isA<CasterException>());
      expect(exception, isA<Exception>());
      expect(exception.message, equals('custom arg error'));
      expect(
        exception.toString(),
        equals('CasterArgumentException: custom arg error'),
      );
    });

    test('CasterTypeException properties and toString', () {
      const exception = CasterException.type('cannot cast');
      expect(exception, isA<CasterTypeException>());
      expect(exception, isA<CasterException>());
      expect(exception, isA<Exception>());
      expect(exception.message, equals('cannot cast'));
      expect(exception.toString(), equals('CasterTypeException: cannot cast'));
    });
  });

  group('Regression & 7-State Explicit Differentiation', () {
    test('State 1 vs State 5: candidate key does not exist with explicit fallback (safeCastFirst)', () {
      final result = <String, Object?>{}.safeCastFirst<int?>([
        'primary',
        'secondary',
      ], fallback: 42);
      expect(result, equals(42));
    });

    test(
      'State 2 vs State 3: key exists and its value is null (safeCastFirst)',
      () {
        final result = <String, Object?>{'primary': null}
            .safeCastFirst<int?>(['primary', 'secondary'], fallback: 42);
        expect(result, isNull);
      },
    );

    test(
      'State 1 vs State 5: MapCaster.safeCast on missing key with fallback',
      () {
        final result = <String, Object?>{}.safeCast<int?>(
          'missing',
          fallback: 42,
        );
        expect(result, equals(42));
      },
    );

    test('State 2 vs State 3: MapCaster.safeCast on present null key', () {
      final result = <String, Object?>{'null_key': null}
          .safeCast<int?>('null_key', fallback: 42);
      expect(result, isNull);
    });

    test('State 6: missing key resolves built-in default', () {
      expect(<String, Object?>{}.safeCast<int>('missing'), equals(0));
      expect(<String, Object?>{}.safeCast<String>('missing'), equals(''));
      expect(<String, Object?>{}.safeCast<bool>('missing'), isFalse);
    });

    test(
      'State 7: missing key with useDefaults: false throws CasterTypeException',
      () {
        expect(
          () =>
              <String, Object?>{}.safeCast<int>('missing', useDefaults: false),
          throwsA(isA<CasterTypeException>()),
        );
      },
    );

    test(
      'Type validation rejects Object, dynamic, and Object? across all methods',
      () {
        expect(
          () => safeCast<Object>('v'),
          throwsA(isA<CasterArgumentException>()),
        );
        expect(
          () => safeCast<dynamic>('v'),
          throwsA(isA<CasterArgumentException>()),
        );
        expect(
          () => safeCast<Object?>('v'),
          throwsA(isA<CasterArgumentException>()),
        );

        expect(
          () => safeCastOrNull<Object>('v'),
          throwsA(isA<CasterArgumentException>()),
        );
        expect(
          () => safeCastOrNull<dynamic>('v'),
          throwsA(isA<CasterArgumentException>()),
        );
        expect(
          () => safeCastOrNull<Object?>('v'),
          throwsA(isA<CasterArgumentException>()),
        );

        final map = <String, Object?>{'k': 123};
        expect(
          () => map.safeCast<Object>('k'),
          throwsA(isA<CasterArgumentException>()),
        );
        expect(
          () => map.safeCast<dynamic>('k'),
          throwsA(isA<CasterArgumentException>()),
        );
        expect(
          () => map.safeCast<Object?>('k'),
          throwsA(isA<CasterArgumentException>()),
        );

        expect(
          () => map.safeCastOrNull<Object>('k'),
          throwsA(isA<CasterArgumentException>()),
        );
        expect(
          () => map.safeCastOrNull<dynamic>('k'),
          throwsA(isA<CasterArgumentException>()),
        );
        expect(
          () => map.safeCastOrNull<Object?>('k'),
          throwsA(isA<CasterArgumentException>()),
        );

        expect(
          () => map.safeCastFirst<Object>(['k']),
          throwsA(isA<CasterArgumentException>()),
        );
        expect(
          () => map.safeCastFirst<dynamic>(['k']),
          throwsA(isA<CasterArgumentException>()),
        );
        expect(
          () => map.safeCastFirst<Object?>(['k']),
          throwsA(isA<CasterArgumentException>()),
        );
      },
    );

    test('safeCastList returns concrete List<T> with indexability and order preserved', () {
      final map = <String, Object?>{
        'items': [10, 20, 'skip', 30, 20],
      };
      final List<int> result = map.safeCastList<int>('items');
      expect(result, isA<List<int>>());
      expect(result, equals([10, 20, 30, 20]));
      expect(result[0], equals(10));
      expect(result.length, equals(4));

      final List<int> withFallback = map.safeCastList<int>(
        'items',
        fallback: -1,
      );
      expect(withFallback, equals([10, 20, -1, 30, 20]));
    });

    test('convertList returns concrete List<T>', () {
      final map = <String, Object?>{
        'tags': ['dart', 'flutter'],
      };
      final List<String> result = map.convertList<String>(
        'tags',
        converter: (v) => v?.toString().toUpperCase(),
      );
      expect(result, isA<List<String>>());
      expect(result, equals(['DART', 'FLUTTER']));
      expect(result[1], equals('FLUTTER'));
    });
  });
}
