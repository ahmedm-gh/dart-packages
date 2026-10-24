import 'dart:async';

import 'package:dependency_box/dependency_box.dart';
import 'package:test/test.dart';

void main() {
  late DependencyBox box;

  setUp(() {
    box = DependencyBox.main();
  });

  tearDown(() async {
    await box.dispose();
  });

  group('singleton registration', () {
    test('stores and retrieves a value by type', () {
      box.addSingleton<String>('hello');

      expect(box.get<String>(), equals('hello'));
    });

    test(
        'registering the same type twice throws AssertionError in debug mode when not multi-registered',
        () {
      box.addSingleton<String>('first');
      expect(
        () {
          box.addSingleton<String>('second');
        },
        throwsA(isA<AssertionError>()),
      );
    });

    test('different types do not conflict', () {
      box.addSingleton<String>('hello');
      box.addSingleton<int>(42);

      expect(box.get<String>(), equals('hello'));
      expect(box.get<int>(), equals(42));
    });

    test('same type with different keys stores both independently', () {
      box.addSingleton<String>('default');
      box.addSingleton<String>('named', key: 'alt');

      expect(box.get<String>(), equals('default'));
      expect(box.get<String>(key: 'alt'), equals('named'));
    });

    test(
        'same type with same key throws AssertionError in debug mode when not multi-registered',
        () {
      box.addSingleton<String>('first', key: 'tag');
      expect(
        () {
          box.addSingleton<String>('second', key: 'tag');
        },
        throwsA(isA<AssertionError>()),
      );
    });

    test('keyed registration does not affect keyless', () {
      box.addSingleton<String>('keyless');
      box.addSingleton<String>('keyed', key: 'k');

      expect(box.get<String>(), equals('keyless'));
    });
  });

  group('lazySingleton registration', () {
    test('resolves and caches the instance on first get', () {
      var callCount = 0;
      box.addLazySingleton<String>((_) {
        callCount++;
        return 'lazy-value';
      });

      final first = box.get<String>();
      final second = box.get<String>();

      expect(first, equals('lazy-value'));
      expect(identical(first, second), isTrue);
      expect(callCount, equals(1));
    });

    test('factory receives the container', () {
      box.addSingleton<int>(42);
      box.addLazySingleton<String>((container) {
        return 'value-${container.get<int>()}';
      });

      expect(box.get<String>(), equals('value-42'));
    });

    test('same type with different keys resolves independently', () {
      box.addLazySingleton<String>((_) {
        return 'default';
      });
      box.addLazySingleton<String>((_) {
        return 'keyed';
      }, key: 'alt');

      expect(box.get<String>(), equals('default'));
      expect(box.get<String>(key: 'alt'), equals('keyed'));
    });

    test('keyed lazy singleton caches independently', () {
      var defaultCount = 0;
      var keyedCount = 0;

      box.addLazySingleton<String>((_) {
        defaultCount++;
        return 'default-$defaultCount';
      });
      box.addLazySingleton<String>((_) {
        keyedCount++;
        return 'keyed-$keyedCount';
      }, key: 'alt');

      // Each should only be created once.
      box.get<String>();
      box.get<String>();
      box.get<String>(key: 'alt');
      box.get<String>(key: 'alt');

      expect(defaultCount, equals(1));
      expect(keyedCount, equals(1));
    });
  });

  group('factory registration', () {
    test('creates a new instance on every get', () {
      var callCount = 0;
      box.addFactory<String>((_) {
        callCount++;
        return 'factory-$callCount';
      });

      final first = box.get<String>();
      final second = box.get<String>();

      expect(first, equals('factory-1'));
      expect(second, equals('factory-2'));
      expect(callCount, equals(2));
    });

    test('factory receives the container', () {
      box.addSingleton<int>(99);
      box.addFactory<String>((container) {
        return 'built-${container.get<int>()}';
      });

      expect(box.get<String>(), equals('built-99'));
    });

    test('same type with different keys creates independently', () {
      box.addFactory<String>((_) {
        return 'default';
      });
      box.addFactory<String>((_) {
        return 'keyed';
      }, key: 'alt');

      expect(box.get<String>(), equals('default'));
      expect(box.get<String>(key: 'alt'), equals('keyed'));
    });
  });

  group('parameterizedFactory registration', () {
    test('creates a new instance using supplied args', () {
      box.addFactoryWith<String, String>(
        (container, name) {
          return 'Hello, $name!';
        },
      );

      expect(box.get<String>(args: 'Alice'), equals('Hello, Alice!'));
      expect(box.get<String>(args: 'Bob'), equals('Hello, Bob!'));
    });

    test('supports class as args', () {
      box.addFactoryWith<String, ({String id, int age})>(
        (container, args) {
          return 'User ${args.id} is ${args.age}';
        },
      );

      final result = box.get<String>(args: (id: 'u1', age: 25));
      expect(result, equals('User u1 is 25'));
    });

    test('works with tryGet and call', () {
      box.addFactoryWith<int, int>(
        (container, multiplier) {
          return multiplier * 10;
        },
      );

      expect(box.tryGet<int>(args: 5), equals(50));
      expect(box.get<int>(args: 7), equals(70));
    });

    test('supports keys for parameterized factories', () {
      box.addFactoryWith<String, String>(
        (container, suffix) {
          return 'default-$suffix';
        },
      );
      box.addFactoryWith<String, String>(
        (container, suffix) {
          return 'keyed-$suffix';
        },
        key: 'custom',
      );

      expect(box.get<String>(args: 'test'), equals('default-test'));
      expect(
        box.get<String>(args: 'test', key: 'custom'),
        equals('keyed-test'),
      );
    });

    test('throws ArgumentError when wrong args type or null is provided', () {
      box.addFactoryWith<String, String>(
        (container, name) {
          return 'Hello, $name!';
        },
      );

      expect(
        () {
          box.get<String>();
        },
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () {
          box.get<String>(args: 123);
        },
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('check', () {
    test('returns false for unregistered type', () {
      expect(box.contains<String>(), isFalse);
    });

    test('returns true after registration', () {
      box.addSingleton<String>('value');
      expect(box.contains<String>(), isTrue);
    });

    test('returns false for unregistered key', () {
      box.addSingleton<String>('value');
      expect(box.contains<String>(key: 'missing'), isFalse);
    });

    test('returns true for registered key', () {
      box.addSingleton<String>('value', key: 'tag');
      expect(box.contains<String>(key: 'tag'), isTrue);
    });
  });

  group('tryGet', () {
    test('returns null for unregistered type', () {
      expect(box.tryGet<String>(), isNull);
    });

    test('returns value after registration', () {
      box.addSingleton<String>('value');
      expect(box.tryGet<String>(), equals('value'));
    });

    test('returns null for unregistered key', () {
      box.addSingleton<String>('value');
      expect(box.tryGet<String>(key: 'missing'), isNull);
    });

    test('returns value for registered key', () {
      box.addSingleton<String>('value', key: 'tag');
      expect(box.tryGet<String>(key: 'tag'), equals('value'));
    });
  });

  group('getAll & multiple instances', () {
    test('returns empty list when not registered', () {
      expect(box.getAll<String>(), isEmpty);
    });

    test('returns single item when registered without multiple flag', () {
      box.addSingleton<String>('single');
      expect(box.getAll<String>(), equals(['single']));
    });

    test('returns all instances when type is in allowMultiple', () {
      box.allowMultiple({const Multi<String>()});
      box.addSingleton<String>('first');
      box.addSingleton<String>('second');
      box.addSingleton<String>('third');

      expect(box.getAll<String>(), equals(['first', 'second', 'third']));
    });

    test('get returns last instance by default (MultiResolution.last)', () {
      box.allowMultiple({const Multi<String>()});
      box.addSingleton<String>('first');
      box.addSingleton<String>('second');

      expect(box.get<String>(), equals('second'));
    });

    test(
        'get returns first instance when configured with MultiResolution.first',
        () {
      box.allowMultiple({const Multi<String>(MultiResolution.first)});
      box.addSingleton<String>('first');
      box.addSingleton<String>('second');
      box.addSingleton<String>('third');

      expect(box.get<String>(), equals('first'));
      expect(box.getAll<String>(), equals(['first', 'second', 'third']));
    });

    test(
        'get returns instance at index when configured with MultiResolution.at',
        () {
      box.allowMultiple({Multi<String>.at(1)});
      box.addSingleton<String>('first');
      box.addSingleton<String>('second');
      box.addSingleton<String>('third');

      expect(box.get<String>(), equals('second'));
      expect(box.getAll<String>(), equals(['first', 'second', 'third']));
    });

    test('get returns instance by key when configured with MultiResolution.key',
        () {
      box.allowMultiple({Multi<String>.key('target')});
      box.addSingleton<String>('other_val', key: 'other');
      box.addSingleton<String>('target_val', key: 'target');
      box.addSingleton<String>('more_val', key: 'more');

      expect(box.get<String>(), equals('target_val'));
      expect(box.get<String>(key: 'other'), equals('other_val'));
      expect(box.get<String>(key: 'target'), equals('target_val'));
    });

    test('get returns last instance when configured with MultiResolution.last',
        () {
      box.allowMultiple({const Multi<String>.last()});
      box.addSingleton<String>('first');
      box.addSingleton<String>('second');

      expect(box.get<String>(), equals('second'));
    });

    test('configures distinct MultiResolution for each type in single call',
        () {
      box.allowMultiple({
        const Multi<String>(MultiResolution.first),
        const Multi<int>(MultiResolution.last),
      });

      box.addSingleton<String>('s1');
      box.addSingleton<String>('s2');

      box.addSingleton<int>(10);
      box.addSingleton<int>(20);

      expect(box.get<String>(), equals('s1'));
      expect(box.getAll<String>(), equals(['s1', 's2']));

      expect(box.get<int>(), equals(20));
      expect(box.getAll<int>(), equals([10, 20]));
    });

    test('supports multiple factories and lazy singletons', () {
      box.allowMultiple({const Multi<String>()});
      box.addFactory<String>((_) {
        return 'fact';
      });
      box.addLazySingleton<String>((_) {
        return 'lazy';
      });

      expect(box.getAll<String>(), equals(['fact', 'lazy']));
    });

    test('supports multiple parameterized factories with args', () {
      box.allowMultiple({const Multi<String>()});
      box.addFactoryWith<String, String>(
        (container, prefix) {
          return '$prefix-A';
        },
      );
      box.addFactoryWith<String, String>(
        (container, prefix) {
          return '$prefix-B';
        },
      );

      expect(
        box.getAll<String>(args: 'test'),
        equals(['test-A', 'test-B']),
      );
    });

    test('supports keys with multi-register types', () {
      box.allowMultiple({const Multi<String>()});
      box.addSingleton<String>('plugin1', key: 'plugins');
      box.addSingleton<String>('plugin2', key: 'plugins');

      expect(
        box.getAll<String>(key: 'plugins'),
        equals(['plugin1', 'plugin2']),
      );
    });

    test(
        'singletonAll throws AssertionError in debug mode when type is not in allowMultiple',
        () {
      expect(
        () {
          box.addSingletons<String>(['a', 'b', 'c']);
        },
        throwsA(isA<AssertionError>()),
      );
    });

    test('singletonAll registers multiple instances when type is enabled', () {
      box.allowMultiple({const Multi<String>()});
      box.addSingletons<String>(['a', 'b', 'c']);

      expect(box.getAll<String>(), equals(['a', 'b', 'c']));
      expect(box.get<String>(), equals('c'));
    });

    test(
        'enabling multi-register preserves previously registered single instance',
        () {
      box.addSingleton<String>('single');
      box.allowMultiple({const Multi<String>()});
      box.addSingleton<String>('multi');

      expect(box.getAll<String>(), equals(['single', 'multi']));
    });

    test('allowMultiple accepts a List instead of a Set', () {
      box.allowMultiple([const Multi<String>()]);
      box.addSingleton<String>('first');
      box.addSingleton<String>('second');

      expect(box.getAll<String>(), equals(['first', 'second']));
    });

    test(
        'allowMulti enables multi-registration for single type with default last resolution',
        () {
      box.allowMulti<String>();
      box.addSingleton<String>('one');
      box.addSingleton<String>('two');

      expect(box.getAll<String>(), equals(['one', 'two']));
      expect(box.get<String>(), equals('two'));
    });

    test('allowMulti supports custom resolution strategy', () {
      box.allowMulti<String>(MultiResolution.first);
      box.addSingleton<String>('one');
      box.addSingleton<String>('two');

      expect(box.get<String>(), equals('one'));
    });
  });

  group('dispose', () {
    test('clears all registrations', () async {
      box.addSingleton<String>('value');
      box.addSingleton<int>(42);

      await box.dispose();

      expect(box.contains<String>(), isFalse);
      expect(box.contains<int>(), isFalse);
    });

    test('clears keyed registrations', () async {
      box.addSingleton<String>('value', key: 'k');

      await box.dispose();

      expect(box.contains<String>(key: 'k'), isFalse);
    });

    test('invokes dispose on singletons implementing DependencyDisposable',
        () async {
      final disposable = _TestDisposable();
      box.addSingleton<_TestDisposable>(disposable);

      await box.dispose();

      expect(disposable.disposed, isTrue);
    });

    test(
        'invokes dispose on initialized lazySingletons implementing DependencyDisposable',
        () async {
      final disposable = _TestDisposable();
      box.addLazySingleton<_TestDisposable>((_) {
        return disposable;
      });

      // Initialize it:
      box.get<_TestDisposable>();

      await box.dispose();

      expect(disposable.disposed, isTrue);
    });

    test('does not invoke dispose on uninitialized lazySingletons', () async {
      var created = false;
      box.addLazySingleton<_TestDisposable>((_) {
        created = true;
        return _TestDisposable();
      });

      await box.dispose();

      expect(created, isFalse);
    });

    test('deduplicates disposal for identical instances', () async {
      var disposeCount = 0;
      final disposable = _CustomDisposable(() {
        disposeCount++;
      });

      box.addSingleton<_CustomDisposable>(disposable, key: 'first');
      box.addSingleton<_CustomDisposable>(disposable, key: 'second');

      await box.dispose();

      expect(disposeCount, equals(1));
    });

    test('invokes dispose on multi-registered instances', () async {
      final d1 = _TestDisposable();
      final d2 = _TestDisposable();

      box.allowMultiple({const Multi<_TestDisposable>()});
      box.addSingleton<_TestDisposable>(d1);
      box.addSingleton<_TestDisposable>(d2);

      await box.dispose();

      expect(d1.disposed, isTrue);
      expect(d2.disposed, isTrue);
    });
  });

  group('BoxDependency', () {
    test('instances with same type and key are equal and have same hashCode',
        () {
      const dep1 = BoxDependency<String>(key: 'test');
      const dep2 = BoxDependency<String>(key: 'test');

      expect(dep1, equals(dep2));
      expect(dep1.hashCode, equals(dep2.hashCode));
    });

    test('instances with same type and null key are equal', () {
      const dep1 = BoxDependency<String>();
      const dep2 = BoxDependency<String>();

      expect(dep1, equals(dep2));
      expect(dep1.hashCode, equals(dep2.hashCode));
    });

    test('identical instances are equal', () {
      const dep = BoxDependency<int>(key: 'k');

      expect(dep == dep, isTrue);
    });

    test('instances with different keys are not equal', () {
      const dep1 = BoxDependency<String>(key: 'key1');
      const dep2 = BoxDependency<String>(key: 'key2');

      expect(dep1, isNot(equals(dep2)));
    });

    test('instances with different types are not equal', () {
      const dep1 = BoxDependency<String>(key: 'common');
      const dep2 = BoxDependency<int>(key: 'common');

      expect(dep1, isNot(equals(dep2)));
    });

    test('BoxDependency.from returns canonical representation', () {
      expect(BoxDependency.from<String>(null), equals(String));
      expect(
        BoxDependency.from<String>('custom'),
        equals(const BoxDependency<String>(key: 'custom')),
      );
    });
  });

  group('Multi', () {
    test('defaults to MultiResolution.last', () {
      const multi = Multi<String>();
      expect(multi.resolution, equals(MultiResolution.last));
      expect(multi.type, equals(String));
    });

    test('accepts custom MultiResolution', () {
      const multi = Multi<String>(MultiResolution.first);
      expect(multi.resolution, equals(MultiResolution.first));
    });

    test('supports Multi.last()', () {
      const m1 = Multi<String>.last();
      expect(m1.resolution, equals(MultiResolution.last));
    });

    test('supports Multi.at() and Multi.key()', () {
      final m1 = Multi<String>.at(2);
      final m2 = Multi<String>.key('custom');
      expect(m1.resolution, equals(const MultiResolution.at(2)));
      expect(m2.resolution, equals(const MultiResolution.key('custom')));

      const constM1 = Multi<String>(MultiResolution.at(2));
      const constM2 = Multi<String>(MultiResolution.key('custom'));
      expect(constM1.resolution, equals(const MultiResolution.at(2)));
      expect(constM2.resolution, equals(const MultiResolution.key('custom')));
    });

    test('instances with same type are equal and have same hashCode', () {
      const m1 = Multi<String>(MultiResolution.last);
      const m2 = Multi<String>(MultiResolution.first);

      expect(m1, equals(m2));
      expect(m1.hashCode, equals(m2.hashCode));
    });

    test('instances with different types are not equal', () {
      const m1 = Multi<String>();
      const m2 = Multi<int>();

      expect(m1, isNot(equals(m2)));
    });
  });

  group('asyncSingleton registration & getAsync', () {
    test('factory is not executed during registration', () {
      var callCount = 0;
      box.addAsyncSingleton<String>((_) async {
        callCount++;
        return 'value';
      });

      expect(callCount, equals(0));
    });

    test('first resolution initializes and caches the instance', () async {
      var callCount = 0;
      box.addAsyncSingleton<String>((_) async {
        callCount++;
        return 'cached-value';
      });

      final first = await box.getAsync<String>();
      final second = await box.getAsync<String>();

      expect(first, equals('cached-value'));
      expect(identical(first, second), isTrue);
      expect(callCount, equals(1));
    });

    test('sync get throws on uninitialized asyncSingleton', () {
      box.addAsyncSingleton<String>((_) async {
        return 'val';
      });

      expect(
        () {
          box.get<String>();
        },
        throwsA(
          isA<StateError>().having(
            (e) {
              return e.message;
            },
            'message',
            contains(
                'Cannot synchronously resolve uninitialized async singleton'),
          ),
        ),
      );
    });

    test(
        'sync get returns cached instance after async initialization completes',
        () async {
      box.addAsyncSingleton<String>((_) async {
        return 'initialized';
      });

      final asyncRes = await box.getAsync<String>();
      final syncRes = box.get<String>();

      expect(syncRes, equals('initialized'));
      expect(identical(asyncRes, syncRes), isTrue);
    });

    test('isolated by type and key', () async {
      box.addAsyncSingleton<String>((_) async {
        return 'default';
      });
      box.addAsyncSingleton<String>((_) async {
        return 'keyed';
      }, key: 'alt');
      box.addAsyncSingleton<int>((_) async {
        return 123;
      });

      expect(await box.getAsync<String>(), equals('default'));
      expect(await box.getAsync<String>(key: 'alt'), equals('keyed'));
      expect(await box.getAsync<int>(), equals(123));
    });

    test(
        'tryGetAsync returns null for unregistered types and resolves registered',
        () async {
      expect(await box.tryGetAsync<String>(), isNull);

      box.addAsyncSingleton<String>((_) async {
        return 'found';
      });
      expect(await box.tryGetAsync<String>(), equals('found'));
    });

    test('getAsync resolves synchronous registrations as completed Future',
        () async {
      box.addSingleton<String>('sync-val');
      box.addLazySingleton<int>((_) {
        return 42;
      });

      expect(await box.getAsync<String>(), equals('sync-val'));
      expect(await box.getAsync<int>(), equals(42));
    });

    test(
        'getAsync propagates synchronous failure from lazy factory as rejected Future',
        () async {
      box.addLazySingleton<String>((_) {
        throw const FormatException('bad format');
      });

      expect(
        () async {
          await box.getAsync<String>();
        },
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('async concurrency & failure retry', () {
    test(
        'concurrent resolutions execute factory exactly once and return identical instance',
        () async {
      final completer = Completer<String>();
      var callCount = 0;

      box.addAsyncSingleton<String>((_) async {
        callCount++;
        return completer.future;
      });

      final f1 = box.getAsync<String>();
      final f2 = box.getAsync<String>();
      final f3 = box.getAsync<String>();

      completer.complete('shared-instance');

      final results = await Future.wait([f1, f2, f3]);
      expect(callCount, equals(1));
      expect(results[0], equals('shared-instance'));
      expect(identical(results[0], results[1]), isTrue);
      expect(identical(results[1], results[2]), isTrue);
    });

    test('concurrent callers observe the same initialization failure',
        () async {
      final completer = Completer<String>();
      var callCount = 0;

      box.addAsyncSingleton<String>((_) async {
        callCount++;
        return completer.future;
      });

      final f1 = box.getAsync<String>();
      final f2 = box.getAsync<String>();

      completer.completeError(const FormatException('failed to parse config'));

      await expectLater(f1, throwsA(isA<FormatException>()));
      await expectLater(f2, throwsA(isA<FormatException>()));
      expect(callCount, equals(1));
    });

    test(
        'failed initialization allows subsequent resolution to retry and succeed',
        () async {
      var callCount = 0;
      var shouldFail = true;

      box.addAsyncSingleton<String>((_) async {
        callCount++;
        if (shouldFail) {
          throw Exception('network timeout');
        }
        return 'success-after-retry';
      });

      await expectLater(box.getAsync<String>(), throwsA(isA<Exception>()));
      expect(callCount, equals(1));

      shouldFail = false;
      final retryResult = await box.getAsync<String>();
      expect(retryResult, equals('success-after-retry'));
      expect(callCount, equals(2));

      // Subsequent call uses cached instance without calling factory again.
      final thirdResult = await box.getAsync<String>();
      expect(thirdResult, equals('success-after-retry'));
      expect(callCount, equals(2));
    });
  });

  group('async dependency graphs & cycle detection', () {
    test('async singleton resolves another async singleton', () async {
      box.addAsyncSingleton<int>((_) async {
        return 100;
      });
      box.addAsyncSingleton<String>((container) async {
        final number = await container.getAsync<int>();
        return 'count-$number';
      });

      final result = await box.getAsync<String>();
      expect(result, equals('count-100'));
    });

    test('async singleton resolves a synchronous singleton', () async {
      box.addSingleton<int>(200);
      box.addAsyncSingleton<String>((container) async {
        final number = container.get<int>();
        return 'sync-$number';
      });

      final result = await box.getAsync<String>();
      expect(result, equals('sync-200'));
    });

    test('mixed multi-layer dependency graph resolves in correct order',
        () async {
      box.addSingleton<String>('https://api.test.com');
      box.addAsyncSingleton<int>((_) async {
        return 8080;
      });
      box.addAsyncSingleton<List<String>>((c) async {
        final host = c.get<String>();
        final port = await c.getAsync<int>();
        return ['$host:$port', 'ready'];
      });

      final result = await box.getAsync<List<String>>();
      expect(result, equals(['https://api.test.com:8080', 'ready']));
    });

    test(
        'detects direct circular async dependency (A -> A) and throws StateError',
        () async {
      box.addAsyncSingleton<String>((container) async {
        return await container.getAsync<String>();
      });

      await expectLater(
        box.getAsync<String>(),
        throwsA(
          isA<StateError>().having(
            (e) {
              return e.message;
            },
            'message',
            contains('Circular dependency detected'),
          ),
        ),
      );
    });

    test(
        'detects mutual circular async dependency (A -> B -> A) and throws StateError without hanging',
        () async {
      box.addAsyncSingleton<String>((container) async {
        final b = await container.getAsync<int>();
        return 'A:$b';
      });

      box.addAsyncSingleton<int>((container) async {
        final a = await container.getAsync<String>();
        return a.length;
      });

      await expectLater(
        box.getAsync<String>(),
        throwsA(
          isA<StateError>().having(
            (e) {
              return e.message;
            },
            'message',
            contains('Circular dependency detected'),
          ),
        ),
      );
    });

    test('detects 3-level circular async dependency (A -> B -> C -> A)',
        () async {
      box.addAsyncSingleton<String>((c) async {
        return 'str-${await c.getAsync<int>()}';
      });
      box.addAsyncSingleton<int>((c) async {
        return (await c.getAsync<double>()).toInt();
      });
      box.addAsyncSingleton<double>((c) async {
        final str = await c.getAsync<String>();
        return str.length.toDouble();
      });

      await expectLater(
        box.getAsync<String>(),
        throwsA(
          isA<StateError>().having(
            (e) {
              return e.message;
            },
            'message',
            contains('Circular dependency detected'),
          ),
        ),
      );
    });
  });

  group('async lifecycle & disposal', () {
    test(
        'disposes initialized async singleton implementing DependencyDisposable',
        () async {
      var disposed = false;
      box.addAsyncSingleton<_CustomDisposable>((_) async {
        return _CustomDisposable(() {
          disposed = true;
        });
      });

      await box.getAsync<_CustomDisposable>();
      expect(disposed, isFalse);

      await box.dispose();
      expect(disposed, isTrue);
    });

    test('does not dispose uninitialized async singleton', () async {
      var disposed = false;
      box.addAsyncSingleton<_CustomDisposable>((_) async {
        return _CustomDisposable(() {
          disposed = true;
        });
      });

      await box.dispose();
      expect(disposed, isFalse);
    });

    test('failed initialization does not dispose a nonexistent instance',
        () async {
      var disposed = false;
      box.addAsyncSingleton<_CustomDisposable>((_) async {
        throw Exception('failed init');
      });

      try {
        await box.getAsync<_CustomDisposable>();
      } catch (_) {}

      await box.dispose();
      expect(disposed, isFalse);
    });

    test('calling getAsync on a disposed box immediately returns StateError',
        () async {
      box.addAsyncSingleton<String>((_) async {
        return 'hello';
      });

      await box.dispose();
      expect(box.isDisposed, isTrue);

      await expectLater(
        box.getAsync<String>(),
        throwsA(
          isA<StateError>().having(
            (e) {
              return e.message;
            },
            'message',
            contains('Cannot resolve dependency from a disposed DependencyBox'),
          ),
        ),
      );
    });

    test(
        'disposal racing with in-flight initialization disposes the instance and rejects waiting caller',
        () async {
      final completer = Completer<_CustomDisposable>();
      var instanceDisposed = false;

      box.addAsyncSingleton<_CustomDisposable>((_) async {
        return completer.future;
      });

      final future = box.getAsync<_CustomDisposable>();

      // Dispose while initialization is in flight
      final disposeFuture = box.dispose();

      // Factory now completes
      completer.complete(_CustomDisposable(() {
        instanceDisposed = true;
      }));

      await disposeFuture;

      await expectLater(
        future,
        throwsA(
          isA<StateError>().having(
            (e) {
              return e.message;
            },
            'message',
            contains('disposed during initialization'),
          ),
        ),
      );

      expect(instanceDisposed, isTrue);
    });

    test(
        'cleanup failure in one disposable does not prevent remaining disposables from disposing',
        () async {
      var secondDisposed = false;

      box.addSingleton<_CustomDisposable>(
        _CustomDisposable(() {
          throw Exception('error disposing first');
        }),
        key: 'first',
      );

      box.addSingleton<_CustomDisposable>(
        _CustomDisposable(() {
          secondDisposed = true;
        }),
        key: 'second',
      );

      await expectLater(
        box.dispose(),
        throwsA(isA<Exception>()),
      );

      expect(secondDisposed, isTrue);
    });

    test('repeated disposal is idempotent', () async {
      box.addAsyncSingleton<String>((_) async {
        return 'hello';
      });

      await box.dispose();
      expect(box.isDisposed, isTrue);

      // Calling dispose again should complete cleanly
      await box.dispose();
      expect(box.isDisposed, isTrue);
    });
  });

  group('hierarchical child scopes', () {
    test('child inherits registrations from parent', () {
      box.addSingleton<String>('parent-data');
      final child = box.createChild(name: 'session-child');

      expect(child.name, equals('session-child'));
      expect(child.parent, equals(box));
      expect(child.get<String>(), equals('parent-data'));
      expect(child.contains<String>(), isTrue);
    });

    test(
        'child registration shadows parent registration without modifying parent',
        () {
      box.addSingleton<String>('parent-data');
      final child = box.createChild();
      child.addSingleton<String>('child-override');

      expect(child.get<String>(), equals('child-override'));
      expect(box.get<String>(), equals('parent-data'));
    });

    test('parent cannot resolve child-only registration', () {
      final child = box.createChild();
      child.addSingleton<int>(42);

      expect(child.get<int>(), equals(42));
      expect(box.contains<int>(), isFalse);
      expect(
        () {
          return box.get<int>();
        },
        throwsA(isA<StateError>()),
      );
    });

    test('multi-level hierarchy resolves up the chain', () {
      box.addSingleton<String>('root-value');
      final child = box.createChild(name: 'child');
      child.addSingleton<int>(100);
      final grandchild = child.createChild(name: 'grandchild');

      expect(grandchild.get<String>(), equals('root-value'));
      expect(grandchild.get<int>(), equals(100));
    });

    test('disposal of child container does not affect parent registrations',
        () async {
      box.addSingleton<String>('parent-kept');
      final childDisposable = _TestDisposable();
      final child = box.createChild();
      child.addSingleton<_TestDisposable>(childDisposable);

      await child.dispose();

      expect(child.isDisposed, isTrue);
      expect(childDisposable.disposed, isTrue);
      expect(box.isDisposed, isFalse);
      expect(box.get<String>(), equals('parent-kept'));
    });

    test('parent disposal does not throw if child is already disposed',
        () async {
      final child = box.createChild();
      await child.dispose();
      await box.dispose();
      expect(box.isDisposed, isTrue);
    });
  });

  group('inline onDispose hooks', () {
    test('singleton invokes custom onDispose on container disposal', () async {
      var disposed = false;
      final client = _NonDisposableResource('client');
      box.addSingleton<_NonDisposableResource>(
        client,
        onDispose: (resource) {
          disposed = true;
          resource.close();
        },
      );

      await box.dispose();
      expect(disposed, isTrue);
      expect(client.isClosed, isTrue);
    });

    test('lazySingleton invokes custom onDispose only when initialized',
        () async {
      var disposedCount = 0;
      box.addLazySingleton<_NonDisposableResource>(
        (c) {
          return _NonDisposableResource('lazy-used');
        },
        key: 'used',
        onDispose: (r) {
          disposedCount++;
        },
      );
      box.addLazySingleton<_NonDisposableResource>(
        (c) {
          return _NonDisposableResource('lazy-unused');
        },
        key: 'unused',
        onDispose: (r) {
          disposedCount++;
        },
      );

      box.get<_NonDisposableResource>(key: 'used');
      await box.dispose();

      expect(disposedCount, equals(1));
    });

    test('asyncSingleton invokes custom async onDispose', () async {
      var disposed = false;
      box.addAsyncSingleton<_NonDisposableResource>(
        (c) async {
          return _NonDisposableResource('async-res');
        },
        onDispose: (r) async {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          disposed = true;
        },
      );

      await box.getAsync<_NonDisposableResource>();
      await box.dispose();
      expect(disposed, isTrue);
    });

    test(
        'both onDispose callback and DependencyDisposable.dispose run on disposal',
        () async {
      var callbackRan = false;
      final disposable = _TestDisposable();
      box.addSingleton<_TestDisposable>(
        disposable,
        onDispose: (d) {
          callbackRan = true;
        },
      );

      await box.dispose();
      expect(callbackRan, isTrue);
      expect(disposable.disposed, isTrue);
    });
  });

  group('flexible key types (enums, symbols, objects)', () {
    test('supports enum keys for registration and resolution', () {
      box.addSingleton<String>('prod-url', key: _TestEnv.prod);
      box.addSingleton<String>('dev-url', key: _TestEnv.dev);

      expect(box.get<String>(key: _TestEnv.prod), equals('prod-url'));
      expect(box.get<String>(key: _TestEnv.dev), equals('dev-url'));
      expect(box.contains<String>(key: _TestEnv.prod), isTrue);
      expect(box.contains<String>(key: _TestEnv.staging), isFalse);
    });

    test('supports symbol keys', () {
      box.addSingleton<int>(1, key: #primary);
      box.addSingleton<int>(2, key: #secondary);

      expect(box.get<int>(key: #primary), equals(1));
      expect(box.get<int>(key: #secondary), equals(2));
    });

    test('supports custom object keys with value equality', () {
      final key1 = _CustomKey('db', 1);
      final key2 = _CustomKey('db', 1);

      box.addSingleton<String>('db-instance', key: key1);

      expect(box.get<String>(key: key2), equals('db-instance'));
    });
  });

  group('targeted removal (remove)', () {
    test('removes dependency and disposes its instance by default', () async {
      final disposable = _TestDisposable();
      box.addSingleton<_TestDisposable>(disposable);

      expect(box.contains<_TestDisposable>(), isTrue);

      final removed = await box.remove<_TestDisposable>();
      expect(removed, isTrue);
      expect(box.contains<_TestDisposable>(), isFalse);
      expect(disposable.disposed, isTrue);
      expect(
        () {
          return box.get<_TestDisposable>();
        },
        throwsA(isA<StateError>()),
      );
    });

    test('unregisters without disposing when dispose: false', () async {
      final disposable = _TestDisposable();
      box.addSingleton<_TestDisposable>(disposable);

      final removed = await box.remove<_TestDisposable>(dispose: false);
      expect(removed, isTrue);
      expect(disposable.disposed, isFalse);
      expect(box.contains<_TestDisposable>(), isFalse);
    });

    test('returns false when unregistering nonexistent dependency', () async {
      final removed = await box.remove<String>();
      expect(removed, isFalse);
    });

    test('child unregister does not affect parent registration', () async {
      box.addSingleton<String>('parent-val');
      final child = box.createChild();
      child.addSingleton<String>('child-val');

      final removed = await child.remove<String>();
      expect(removed, isTrue);
      expect(child.get<String>(), equals('parent-val'));
      expect(box.get<String>(), equals('parent-val'));
    });
  });

  group('test overrides (replaceSingleton)', () {
    test('replaces registration without throwing duplicate registration assert',
        () {
      box.addSingleton<String>('production');
      box.replaceSingleton<String>('mocked-test');

      expect(box.get<String>(), equals('mocked-test'));
    });

    test('disposes old instance when disposeOld is true', () async {
      final old = _TestDisposable();
      box.addSingleton<_TestDisposable>(old);

      final replacement = _TestDisposable();
      box.replaceSingleton<_TestDisposable>(replacement, disposeOld: true);

      await Future<void>.delayed(Duration.zero);

      expect(old.disposed, isTrue);
      expect(box.get<_TestDisposable>(), equals(replacement));
    });

    test('retains old instance without disposal when disposeOld is false',
        () async {
      final old = _TestDisposable();
      box.addSingleton<_TestDisposable>(old);

      final replacement = _TestDisposable();
      box.replaceSingleton<_TestDisposable>(replacement, disposeOld: false);

      await Future<void>.delayed(Duration.zero);

      expect(old.disposed, isFalse);
      expect(box.get<_TestDisposable>(), equals(replacement));
    });
  });

  group('modular feature composition (DependencyModule & install)', () {
    test('installs single module', () {
      final module = _AuthModule();
      box.install(module);

      expect(box.get<String>(key: 'auth_endpoint'),
          equals('https://auth.example.com'));
      expect(box.get<int>(key: 'token_timeout'), equals(3600));
    });

    test('installs multiple modules via installAll', () {
      box.installAll([_AuthModule(), _DatabaseModule()]);

      expect(box.get<String>(key: 'auth_endpoint'),
          equals('https://auth.example.com'));
      expect(box.get<String>(key: 'db_host'), equals('localhost'));
    });
  });

  group('container diagnostics & introspection', () {
    test('reports length, isEmpty, isNotEmpty, and registeredKeys', () {
      expect(box.isEmpty, isTrue);
      expect(box.isNotEmpty, isFalse);
      expect(box.length, equals(0));

      box.addSingleton<String>('hello');
      box.addSingleton<int>(123, key: 'count');

      expect(box.isEmpty, isFalse);
      expect(box.isNotEmpty, isTrue);
      expect(box.length, equals(2));
      expect(box.registeredKeys, contains(String));
    });

    test('child registeredKeys includes parent keys', () {
      box.addSingleton<String>('root');
      final child = box.createChild();
      child.addSingleton<int>(42);

      expect(child.length, equals(1));
      expect(child.registeredKeys, contains(String));
    });
  });

  group('async multi-resolution (getAllAsync)', () {
    test('resolves multiple async singletons', () async {
      box.allowMultiple({Multi<String>()});
      box.addAsyncSingleton<String>((c) async {
        return 'first';
      });
      box.addAsyncSingleton<String>((c) async {
        return 'second';
      });

      final results = await box.getAllAsync<String>();
      expect(results, equals(['first', 'second']));
    });

    test('child getAllAsync includes parent async registrations', () async {
      box.allowMultiple({Multi<String>()});
      box.addAsyncSingleton<String>((c) async {
        return 'parent-item';
      });

      final child = box.createChild();
      child.addAsyncSingleton<String>((c) async {
        return 'child-item';
      });

      final results = await child.getAllAsync<String>();
      expect(results, equals(['parent-item', 'child-item']));
    });
  });

  group('BoxConfig', () {
    test('provides compile-time constants for default behaviors', () {
      expect(BoxConfig.defaultMultiResolution, equals(MultiResolution.last));
      expect(BoxConfig.defaultDisposeOldOnReplace, isTrue);
      expect(BoxConfig.defaultDisposeOnRemove, isTrue);
    });
  });

  group('disposed container lifecycle & invariants', () {
    test('calling get on a disposed box throws StateError', () async {
      box.addSingleton<String>('hello');
      await box.dispose();

      expect(
        () => box.get<String>(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Cannot resolve dependency from a disposed DependencyBox'),
          ),
        ),
      );
    });

    test('calling tryGet on a disposed box returns null', () async {
      box.addSingleton<String>('hello');
      await box.dispose();

      expect(box.tryGet<String>(), isNull);
    });

    test('calling getAll on a disposed box returns empty list', () async {
      box.addSingleton<String>('hello');
      await box.dispose();

      expect(box.getAll<String>(), isEmpty);
    });

    test('calling contains on a disposed box returns false', () async {
      box.addSingleton<String>('hello');
      await box.dispose();

      expect(box.contains<String>(), isFalse);
    });

    test('calling registeredKeys on a disposed box returns empty', () async {
      box.addSingleton<String>('hello');
      await box.dispose();

      expect(box.registeredKeys, isEmpty);
    });

    test('creating a child from a disposed box throws StateError', () async {
      await box.dispose();

      expect(
        () => box.createChild(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains(
                'Cannot create a child scope from a disposed DependencyBox'),
          ),
        ),
      );
    });

    test('registering on a disposed box throws StateError', () async {
      await box.dispose();

      expect(
        () => box.addSingleton<String>('fail'),
        throwsA(isA<StateError>()),
      );
      expect(
        () => box.addLazySingleton<String>((_) => 'fail'),
        throwsA(isA<StateError>()),
      );
      expect(
        () => box.addFactory<String>((_) => 'fail'),
        throwsA(isA<StateError>()),
      );
      expect(
        () => box.addAsyncSingleton<String>((_) async => 'fail'),
        throwsA(isA<StateError>()),
      );
      expect(
        () => box.replaceSingleton<String>('fail'),
        throwsA(isA<StateError>()),
      );
      expect(
        () => box.allowMulti<String>(),
        throwsA(isA<StateError>()),
      );
      expect(
        () => box.allowMultiple({const Multi<String>()}),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('child container disposal isolation', () {
    test(
        'disposed child container does not resolve parent registrations via get',
        () async {
      box.addSingleton<String>('parent-val');
      final child = box.createChild();
      expect(child.get<String>(), equals('parent-val'));

      await child.dispose();
      expect(child.isDisposed, isTrue);

      expect(
        () => child.get<String>(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Cannot resolve dependency from a disposed DependencyBox'),
          ),
        ),
      );
      expect(child.tryGet<String>(), isNull);
      expect(child.contains<String>(), isFalse);
      expect(child.getAll<String>(), isEmpty);
      expect(child.registeredKeys, isEmpty);

      // Parent remains completely intact and functional
      expect(box.isDisposed, isFalse);
      expect(box.get<String>(), equals('parent-val'));
    });
  });

  group('identity-based disposal deduplication', () {
    test('disposes two distinct instances that have value equality (==)',
        () async {
      final obj1 = _ValueEqualDisposable('shared_id');
      final obj2 = _ValueEqualDisposable('shared_id');

      // Verify they have value equality but are distinct objects
      expect(obj1 == obj2, isTrue);
      expect(identical(obj1, obj2), isFalse);

      box.addSingleton<_ValueEqualDisposable>(obj1, key: 'first');
      box.addSingleton<_ValueEqualDisposable>(obj2, key: 'second');

      await box.dispose();

      expect(obj1.disposed, isTrue);
      expect(obj2.disposed, isTrue);
    });

    test(
        'deduplicates disposal for identical instance registered under multiple keys',
        () async {
      var disposeCount = 0;
      final obj = _CustomDisposable(() {
        disposeCount++;
      });

      box.addSingleton<_CustomDisposable>(obj, key: 'k1');
      box.addSingleton<_CustomDisposable>(obj, key: 'k2');

      await box.dispose();

      expect(disposeCount, equals(1));
    });
  });

  group('synchronous circular dependency detection in lazy singletons', () {
    test(
        'detects mutual circular dependency (A -> B -> A) and throws StateError',
        () {
      box.addLazySingleton<_CircularLazyA>(
          (c) => _CircularLazyA(c.get<_CircularLazyB>()));
      box.addLazySingleton<_CircularLazyB>(
          (c) => _CircularLazyB(c.get<_CircularLazyA>()));

      expect(
        () => box.get<_CircularLazyA>(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains(
                'Circular dependency detected in synchronous lazy resolution'),
          ),
        ),
      );
    });

    test('lazy factory error resets resolving flag and allows subsequent retry',
        () {
      var shouldThrow = true;
      box.addLazySingleton<String>((_) {
        if (shouldThrow) {
          throw FormatException('initial failure');
        }
        return 'recovered';
      });

      expect(() => box.get<String>(), throwsA(isA<FormatException>()));

      shouldThrow = false;
      expect(box.get<String>(), equals('recovered'));
    });
  });

  group('BoxDependency covariance symmetry and diagnostics', () {
    test(
        'BoxDependency<Object> and BoxDependency<String> with same key are not equal in both directions',
        () {
      const baseDep = BoxDependency<Object>(key: 'test');
      const derivedDep = BoxDependency<String>(key: 'test');

      expect(baseDep == derivedDep, isFalse);
      expect(derivedDep == baseDep, isFalse);
    });

    test('BoxDependency exposes type getter and readable toString', () {
      const depKeyed = BoxDependency<String>(key: 'my_key');
      const depUnkeyed = BoxDependency<int>();

      expect(depKeyed.type, equals(String));
      expect(depKeyed.toString(), equals('String(key: my_key)'));
      expect(depUnkeyed.type, equals(int));
      expect(depUnkeyed.toString(), equals('int'));
    });
  });

  group('targeted removal & replacement edge cases', () {
    test(
        'replaceSingleton with disposeOld: true disposes all instances in multiContainer',
        () async {
      final d1 = _TestDisposable();
      final d2 = _TestDisposable();

      box.allowMultiple({const Multi<_TestDisposable>()});
      box.addSingleton<_TestDisposable>(d1);
      box.addSingleton<_TestDisposable>(d2);

      final replacement = _TestDisposable();
      box.replaceSingleton<_TestDisposable>(replacement, disposeOld: true);

      expect(d1.disposed, isTrue);
      expect(d2.disposed, isTrue);
      expect(replacement.disposed, isFalse);
      expect(box.get<_TestDisposable>(), equals(replacement));
    });

    test('remove cleans up MultiResolution.key alias on unkeyed lookup',
        () async {
      final d1 = _TestDisposable();
      final d2 = _TestDisposable();

      box.allowMultiple({Multi<_TestDisposable>.key('target')});
      box.addSingleton<_TestDisposable>(d1, key: 'other');
      box.addSingleton<_TestDisposable>(d2, key: 'target');

      expect(box.get<_TestDisposable>(), equals(d2));

      final removed = await box.remove<_TestDisposable>(key: 'target');
      expect(removed, isTrue);
      expect(d2.disposed, isTrue);

      // Unkeyed lookup no longer returns the removed d2
      expect(() => box.get<_TestDisposable>(), throwsA(isA<StateError>()));
    });
  });

  group('README code examples & type inference verification', () {
    test('inferred types compile, resolve, and run cleanly', () async {
      final box = DependencyBox.main();

      // 1. Inferred registrations
      box.addSingleton(const _ReadmeApiConfig('https://api.example.com'));
      box.addLazySingleton((dbox) => _ReadmeApiClient(dbox.get()));
      box.addFactory((dbox) => _ReadmeUserRepository(dbox.get()));

      // 2. Inferred resolution
      final _ReadmeUserRepository userRepo = box.get();
      expect(userRepo.fetchUser('42'), 'User 42 from https://api.example.com');

      // 3. Parameterized factory
      box.addFactoryWith((dbox, String sessionId) =>
          _ReadmeUserSession(sessionId, dbox.get()));
      final _ReadmeUserSession session = box.get(args: 'session_token_xyz');
      expect(session.sessionId, 'session_token_xyz');

      // 4. Async singleton
      box.addAsyncSingleton((dbox) async {
        await Future<void>.delayed(const Duration(milliseconds: 1));
        return 'secret_jwt_token';
      });
      final String token = await box.getAsync();
      expect(token, 'secret_jwt_token');

      // 5. TryGet
      final _ReadmeApiConfig? optionalConfig = box.tryGet();
      expect(optionalConfig?.baseUrl, 'https://api.example.com');

      // 6. Direct function injection
      void startWithClient(_ReadmeApiClient client) {
        expect(client.config.baseUrl, 'https://api.example.com');
      }

      startWithClient(box.get());

      // 7. Typed getter class
      final appDeps = _ReadmeAppDependencies(box);
      expect(
          appDeps.users.fetchUser('1'), 'User 1 from https://api.example.com');

      // 8. Keyed with enum
      box.addSingleton(const _ReadmeApiConfig('https://api.prod.example.com'),
          key: _TestEnv.prod);
      box.addSingleton(const _ReadmeApiConfig('https://api.dev.example.com'),
          key: _TestEnv.dev);
      final _ReadmeApiConfig prod = box.get(key: _TestEnv.prod);
      final _ReadmeApiConfig dev = box.get(key: _TestEnv.dev);
      expect(prod.baseUrl, 'https://api.prod.example.com');
      expect(dev.baseUrl, 'https://api.dev.example.com');

      // 9. Multi singletons with inferred list
      final plugins = <_ReadmeAppPlugin>[
        _ReadmeAnalyticsPlugin(),
        _ReadmeLoggingPlugin()
      ];
      box.allowMulti<_ReadmeAppPlugin>();
      box.addSingletons(plugins);
      final List<_ReadmeAppPlugin> allPlugins = box.getAll();
      expect(allPlugins.length, 2);

      // 10. 5-Tier architecture
      box.addSingleton(const _ReadmeDatabaseConfig('localhost', 5432));
      box.addLazySingleton((dbox) => _ReadmeDatabaseConnection(dbox.get()));
      box.addLazySingleton((dbox) => _ReadmeUserRemoteDataSource(dbox.get()));
      box.addLazySingleton((dbox) => _ReadmeGetUserProfileUseCase(dbox.get()));
      box.addFactory((dbox) => _ReadmeProfileController(dbox.get()));
      final _ReadmeProfileController controller = box.get();
      expect(controller.useCase.repo.client.config.baseUrl,
          'https://api.example.com');

      // 11. Child scope
      final childScope = box.createChild();
      childScope.addSingleton(_ReadmeRequestContext('req-1', 'usr-1'));
      childScope
          .addFactory((dbox) => _ReadmeRequestLogger(dbox.get(), dbox.get()));
      final _ReadmeRequestLogger reqLogger = childScope.get();
      expect(reqLogger.context.requestId, 'req-1');

      await childScope.dispose();
      await box.dispose();
    });
  });
}

enum _TestEnv { prod, dev, staging }

class _CustomKey {
  const _CustomKey(this.name, this.id);
  final String name;
  final int id;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _CustomKey && other.name == name && other.id == id;
  }

  @override
  int get hashCode {
    return Object.hash(name, id);
  }
}

class _NonDisposableResource {
  _NonDisposableResource(this.name);
  final String name;
  bool isClosed = false;

  void close() {
    isClosed = true;
  }
}

class _AuthModule implements DependencyModule {
  @override
  void register(DependencyBox box) {
    box.addSingleton<String>('https://auth.example.com', key: 'auth_endpoint');
    box.addSingleton<int>(3600, key: 'token_timeout');
  }
}

class _DatabaseModule implements DependencyModule {
  @override
  void register(DependencyBox box) {
    box.addSingleton<String>('localhost', key: 'db_host');
  }
}

class _TestDisposable implements DependencyDisposable {
  bool disposed = false;

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class _CustomDisposable implements DependencyDisposable {
  _CustomDisposable(this.onDispose);

  final void Function() onDispose;

  @override
  void dispose() {
    onDispose();
  }
}

class _ValueEqualDisposable implements DependencyDisposable {
  _ValueEqualDisposable(this.id);
  final String id;
  bool disposed = false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ValueEqualDisposable && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  void dispose() {
    disposed = true;
  }
}

class _CircularLazyA {
  _CircularLazyA(this.b);
  final _CircularLazyB b;
}

class _CircularLazyB {
  _CircularLazyB(this.a);
  final _CircularLazyA a;
}

class _ReadmeApiConfig {
  const _ReadmeApiConfig(this.baseUrl);
  final String baseUrl;
}

class _ReadmeApiClient {
  _ReadmeApiClient(this.config);
  final _ReadmeApiConfig config;
  bool isClosed = false;
  void close() => isClosed = true;
}

class _ReadmeUserRepository {
  _ReadmeUserRepository(this.client);
  final _ReadmeApiClient client;
  String fetchUser(String id) => 'User $id from ${client.config.baseUrl}';
}

class _ReadmeUserSession {
  _ReadmeUserSession(this.sessionId, this.client);
  final String sessionId;
  final _ReadmeApiClient client;
}

abstract interface class _ReadmeAppPlugin {
  String get name;
  void initialize();
}

class _ReadmeAnalyticsPlugin implements _ReadmeAppPlugin {
  @override
  String get name => 'analytics';
  @override
  void initialize() {}
}

class _ReadmeLoggingPlugin implements _ReadmeAppPlugin {
  @override
  String get name => 'logging';
  @override
  void initialize() {}
}

class _ReadmeDatabaseConfig {
  const _ReadmeDatabaseConfig(this.host, this.port);
  final String host;
  final int port;
}

class _ReadmeDatabaseConnection implements DependencyDisposable {
  _ReadmeDatabaseConnection(this.config);
  final _ReadmeDatabaseConfig config;
  bool isClosed = false;

  @override
  Future<void> dispose() async {
    isClosed = true;
  }
}

class _ReadmeUserRemoteDataSource {
  _ReadmeUserRemoteDataSource(this.db);
  final _ReadmeDatabaseConnection db;
}

class _ReadmeGetUserProfileUseCase {
  _ReadmeGetUserProfileUseCase(this.repo);
  final _ReadmeUserRepository repo;
}

class _ReadmeProfileController {
  _ReadmeProfileController(this.useCase);
  final _ReadmeGetUserProfileUseCase useCase;
}

class _ReadmeRequestContext {
  _ReadmeRequestContext(this.requestId, this.userId);
  final String requestId;
  final String userId;
}

class _ReadmeRequestLogger {
  _ReadmeRequestLogger(this.context, this.client);
  final _ReadmeRequestContext context;
  final _ReadmeApiClient client;
}

class _ReadmeAppDependencies {
  _ReadmeAppDependencies(this.box);
  final DependencyBox box;

  _ReadmeApiConfig get config => box.get();
  _ReadmeApiClient get client => box.get();
  _ReadmeUserRepository get users => box.get();
}
