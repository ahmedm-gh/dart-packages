import 'dart:io';

import 'package:dependency_box/dependency_box.dart';

// --- Domain Models for Real-World Simulation ---
class ConfigService {
  final String apiUrl = 'https://api.example.com';
}

class DatabaseService {
  final ConfigService config;
  DatabaseService(this.config);
}

class NetworkClient {
  final ConfigService config;
  NetworkClient(this.config);
}

class UserRepository {
  final DatabaseService db;
  final NetworkClient client;
  UserRepository(this.db, this.client);
}

class AuthService {
  final UserRepository userRepo;
  AuthService(this.userRepo);
}

abstract interface class Plugin {
  String get name;
}

class AuthPlugin implements Plugin {
  @override
  String get name {
    return 'auth';
  }
}

class LoggingPlugin implements Plugin {
  @override
  String get name {
    return 'logging';
  }
}

class MetricsPlugin implements Plugin {
  @override
  String get name {
    return 'metrics';
  }
}

class QueryEngine {
  final String query;
  QueryEngine(this.query);
}

// --- Benchmark Runner Helper ---
class BenchmarkResult {
  final String name;
  final int operations;
  final int elapsedMicros;

  BenchmarkResult({
    required this.name,
    required this.operations,
    required this.elapsedMicros,
  });

  double get opsPerSec {
    return (operations / (elapsedMicros / 1000000.0));
  }

  double get nsPerOp {
    return (elapsedMicros * 1000.0) / operations;
  }
}

BenchmarkResult measure(String name, int iterations, void Function() run) {
  // Warmup
  for (var i = 0; i < 50000; i++) {
    run();
  }

  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    run();
  }
  sw.stop();

  return BenchmarkResult(
    name: name,
    operations: iterations,
    elapsedMicros: sw.elapsedMicroseconds,
  );
}

Future<BenchmarkResult> measureAsync(
  String name,
  int iterations,
  Future<void> Function() run,
) async {
  // Warmup
  for (var i = 0; i < 2000; i++) {
    await run();
  }

  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    await run();
  }
  sw.stop();

  return BenchmarkResult(
    name: name,
    operations: iterations,
    elapsedMicros: sw.elapsedMicroseconds,
  );
}

Future<void> main() async {
  stdout.writeln(
    '========================================================================',
  );
  stdout.writeln('  DEPENDENCY_BOX HEAVY REAL-WORLD BENCHMARK');
  stdout.writeln(
    '  Dart SDK: ${Platform.version.split(' ').first} (${Platform.operatingSystem})',
  );
  stdout.writeln(
    '========================================================================\n',
  );

  final results = <BenchmarkResult>[];
  const heavyCount = 5000000; // 5 Million iterations per test

  // ---------------------------------------------------------------------------
  // Benchmark 1: Singleton Resolution (Hot Path)
  // ---------------------------------------------------------------------------
  {
    final box = DependencyBox.main();
    final config = ConfigService();
    box.addSingleton<ConfigService>(config);

    results.add(
      measure('1. Singleton get<T>() [Unkeyed Hot Path]', heavyCount, () {
        final res = box.get<ConfigService>();
        if (identical(res, null)) throw StateError('null');
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 2: Keyed Dependency Resolution
  // ---------------------------------------------------------------------------
  {
    final box = DependencyBox.main();
    final config = ConfigService();
    box.addSingleton<ConfigService>(config, key: 'primary');

    results.add(
      measure('2. Keyed get<T>(key: "primary")', heavyCount, () {
        final res = box.get<ConfigService>(key: 'primary');
        if (identical(res, null)) throw StateError('null');
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 3: Cached LazySingleton Resolution
  // ---------------------------------------------------------------------------
  {
    final box = DependencyBox.main();
    box.addLazySingleton<ConfigService>((_) {
      return ConfigService();
    });
    // Prime the lazy singleton
    box.get<ConfigService>();

    results.add(
      measure('3. Cached LazySingleton get<T>()', heavyCount, () {
        final res = box.get<ConfigService>();
        if (identical(res, null)) throw StateError('null');
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 4: Multi-Registration get<T>() (MultiResolution.last)
  // ---------------------------------------------------------------------------
  {
    final box = DependencyBox.main();
    box.allowMultiAll({const MultiRegistration<Plugin>.last()});
    box.addSingleton<Plugin>(AuthPlugin());
    box.addSingleton<Plugin>(LoggingPlugin());
    box.addSingleton<Plugin>(MetricsPlugin());

    results.add(
      measure('4. Multi get<T>() [MultiResolution.last]', heavyCount, () {
        final res = box.get<Plugin>();
        if (identical(res, null)) throw StateError('null');
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 5: Multi-Registration get<T>() (MultiResolution.first)
  // ---------------------------------------------------------------------------
  {
    final box = DependencyBox.main();
    box.allowMultiAll({const MultiRegistration<Plugin>.first()});
    box.addSingleton<Plugin>(AuthPlugin());
    box.addSingleton<Plugin>(LoggingPlugin());
    box.addSingleton<Plugin>(MetricsPlugin());

    results.add(
      measure('5. Multi get<T>() [MultiResolution.first]', heavyCount, () {
        final res = box.get<Plugin>();
        if (identical(res, null)) throw StateError('null');
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 6: Multi-Registration get<T>() (MultiResolution.at(1))
  // ---------------------------------------------------------------------------
  {
    final box = DependencyBox.main();
    box.allowMultiAll({MultiRegistration<Plugin>.at(1)});
    box.addSingleton<Plugin>(AuthPlugin());
    box.addSingleton<Plugin>(LoggingPlugin());
    box.addSingleton<Plugin>(MetricsPlugin());

    results.add(
      measure('6. Multi get<T>() [MultiResolution.at(1)]', heavyCount, () {
        final res = box.get<Plugin>();
        if (identical(res, null)) throw StateError('null');
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 7: Multi-Registration get<T>() (MultiResolution.key("logging"))
  // ---------------------------------------------------------------------------
  {
    final box = DependencyBox.main();
    box.allowMultiAll({MultiRegistration<Plugin>.key('logging')});
    box.addSingleton<Plugin>(AuthPlugin(), key: 'auth');
    box.addSingleton<Plugin>(LoggingPlugin(), key: 'logging');
    box.addSingleton<Plugin>(MetricsPlugin(), key: 'metrics');

    results.add(
      measure(
        '7. Multi get<T>() [MultiResolution.key("logging")]',
        heavyCount,
        () {
          final res = box.get<Plugin>();
          if (identical(res, null)) throw StateError('null');
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 8: getAll<T>() with 3 Multi-Registered Instances
  // ---------------------------------------------------------------------------
  {
    final box = DependencyBox.main();
    box.allowMultiAll({const MultiRegistration<Plugin>.last()});
    box.addSingleton<Plugin>(AuthPlugin());
    box.addSingleton<Plugin>(LoggingPlugin());
    box.addSingleton<Plugin>(MetricsPlugin());

    results.add(
      measure('8. getAll<T>() [3 instances allocated to List]', 1000000, () {
        final res = box.getAll<Plugin>();
        if (res.length != 3) throw StateError('invalid length');
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 9: Deep Dependency Graph Resolution (5 nested layers)
  // ---------------------------------------------------------------------------
  {
    final box = DependencyBox.main();
    box.addSingleton<ConfigService>(ConfigService());
    box.addSingleton<DatabaseService>(
      DatabaseService(box.get<ConfigService>()),
    );
    box.addSingleton<NetworkClient>(NetworkClient(box.get<ConfigService>()));
    box.addSingleton<UserRepository>(
      UserRepository(box.get<DatabaseService>(), box.get<NetworkClient>()),
    );
    box.addSingleton<AuthService>(AuthService(box.get<UserRepository>()));

    results.add(
      measure('9. Deep Hierarchy get<AuthService>()', heavyCount, () {
        final res = box.get<AuthService>();
        if (identical(res, null)) throw StateError('null');
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 10: Parameterized Factory Creation
  // ---------------------------------------------------------------------------
  {
    final box = DependencyBox.main();
    box.addFactoryWith<QueryEngine, String>((container, query) {
      return QueryEngine(query);
    });

    results.add(
      measure(
        '10. Parameterized Factory get<QueryEngine>(args: query)',
        2000000,
        () {
          final res = box.get<QueryEngine>(args: 'SELECT * FROM users');
          if (identical(res, null)) throw StateError('null');
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark: Factory Resolution (Un-cached Fresh Instance)
  // ---------------------------------------------------------------------------
  {
    final box = DependencyBox.main();
    box.addFactory<ConfigService>((_) {
      return ConfigService();
    });

    results.add(
      measure('Factory get<ConfigService>() [Un-cached Fresh]', 2000000, () {
        final res = box.get<ConfigService>();
        if (identical(res, null)) throw StateError('null');
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 11: Container Creation + 1,000 Registrations Mass Setup
  // ---------------------------------------------------------------------------
  {
    const setupRuns = 2000;
    final sw = Stopwatch()..start();
    for (var run = 0; run < setupRuns; run++) {
      final box = DependencyBox.main();
      for (var i = 0; i < 1000; i++) {
        box.addSingleton<int>(i, key: 'id_$i');
      }
    }
    sw.stop();

    results.add(
      BenchmarkResult(
        name: '11. Mass Setup: Create Box + 1,000 Keyed Singletons',
        operations: setupRuns,
        elapsedMicros: sw.elapsedMicroseconds,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 12: Async Singleton Cold Initialization
  // ---------------------------------------------------------------------------
  {
    const coldInits = 50000;
    final sw = Stopwatch()..start();
    for (var i = 0; i < coldInits; i++) {
      final box = DependencyBox.main();
      box.addAsyncSingleton<ConfigService>((_) async {
        return ConfigService();
      });
      final res = await box.getAsync<ConfigService>();
      if (identical(res, null)) throw StateError('null');
      await box.dispose();
    }
    sw.stop();

    results.add(
      BenchmarkResult(
        name: '12. Async Singleton Cold Init (Create + Init + Dispose)',
        operations: coldInits,
        elapsedMicros: sw.elapsedMicroseconds,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 13: Async Singleton Cached getAsync<T>() Resolution
  // ---------------------------------------------------------------------------
  {
    final box = DependencyBox.main();
    box.addAsyncSingleton<ConfigService>((_) async {
      return ConfigService();
    });
    // Prime cache
    await box.getAsync<ConfigService>();

    results.add(
      await measureAsync(
        '13. Async Singleton Cached getAsync<ConfigService>()',
        2000000,
        () async {
          final res = await box.getAsync<ConfigService>();
          if (identical(res, null)) throw StateError('null');
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 14: Concurrent Async Resolution (10 Concurrent Callers)
  // ---------------------------------------------------------------------------
  {
    final box = DependencyBox.main();
    box.addAsyncSingleton<ConfigService>((_) async {
      return ConfigService();
    });
    await box.getAsync<ConfigService>();

    results.add(
      await measureAsync(
        '14. Concurrent getAsync (10 Callers Joining Cache)',
        50000,
        () async {
          final futures = List.generate(10, (_) {
            return box.getAsync<ConfigService>();
          });
          final all = await Future.wait(futures);
          if (all.length != 10) throw StateError('invalid');
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 15: Async Dependency Graph Resolution (5 Nested Layers)
  // ---------------------------------------------------------------------------
  {
    final box = DependencyBox.main();
    box.addAsyncSingleton<ConfigService>((_) async {
      return ConfigService();
    });
    box.addAsyncSingleton<DatabaseService>((c) async {
      final config = await c.getAsync<ConfigService>();
      return DatabaseService(config);
    });
    box.addAsyncSingleton<NetworkClient>((c) async {
      final config = await c.getAsync<ConfigService>();
      return NetworkClient(config);
    });
    box.addAsyncSingleton<UserRepository>((c) async {
      final db = await c.getAsync<DatabaseService>();
      final client = await c.getAsync<NetworkClient>();
      return UserRepository(db, client);
    });
    box.addAsyncSingleton<AuthService>((c) async {
      final repo = await c.getAsync<UserRepository>();
      return AuthService(repo);
    });

    // Prime the graph
    await box.getAsync<AuthService>();

    results.add(
      await measureAsync(
        '15. Async Graph getAsync<AuthService>() (5 Layers)',
        1000000,
        () async {
          final res = await box.getAsync<AuthService>();
          if (identical(res, null)) throw StateError('null');
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 16: Inherited get<T>() Resolution (Child -> Parent)
  // ---------------------------------------------------------------------------
  {
    final parent = DependencyBox.main();
    parent.addSingleton<ConfigService>(ConfigService());
    final child = parent.createChild();

    results.add(
      measure('16. Inherited get<T>() [Child -> Parent]', heavyCount, () {
        final res = child.get<ConfigService>();
        if (identical(res, null)) throw StateError('null');
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 17: Missing Dependency Resolution (tryGet<T>())
  // ---------------------------------------------------------------------------
  {
    final box = DependencyBox.main();

    results.add(
      measure('17. Missing Dependency tryGet<T>()', heavyCount, () {
        final res = box.tryGet<ConfigService>();
        if (res != null) throw StateError('expected null');
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 18: createChild() on Container with No Existing Children
  // ---------------------------------------------------------------------------
  {
    const runs = 200000;
    final sw = Stopwatch()..start();
    for (var i = 0; i < runs; i++) {
      final parent = DependencyBox.main();
      parent.createChild();
    }
    sw.stop();

    results.add(
      BenchmarkResult(
        name: '18. createChild() [First Child on Empty Parent]',
        operations: runs,
        elapsedMicros: sw.elapsedMicroseconds,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 19: createChild() on Container with Existing Children
  // ---------------------------------------------------------------------------
  {
    const runs = 100000;
    final parent = DependencyBox.main();
    for (var i = 0; i < 5; i++) {
      parent.createChild();
    }
    final sw = Stopwatch()..start();
    for (var i = 0; i < runs; i++) {
      parent.createChild();
    }
    sw.stop();

    results.add(
      BenchmarkResult(
        name: '19. createChild() [Subsequent Child on Active Parent]',
        operations: runs,
        elapsedMicros: sw.elapsedMicroseconds,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 20: Disposal of Leaf Container
  // ---------------------------------------------------------------------------
  {
    const runs = 100000;
    final sw = Stopwatch()..start();
    for (var i = 0; i < runs; i++) {
      final leaf = DependencyBox.main();
      leaf.addSingleton<ConfigService>(ConfigService());
      await leaf.dispose();
    }
    sw.stop();

    results.add(
      BenchmarkResult(
        name: '20. Disposal: Leaf Container with 1 Singleton',
        operations: runs,
        elapsedMicros: sw.elapsedMicroseconds,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 21: Disposal of Parent with 10 Direct Children
  // ---------------------------------------------------------------------------
  {
    const runs = 20000;
    final sw = Stopwatch()..start();
    for (var i = 0; i < runs; i++) {
      final parent = DependencyBox.main();
      for (var c = 0; c < 10; c++) {
        parent.createChild();
      }
      await parent.dispose();
    }
    sw.stop();

    results.add(
      BenchmarkResult(
        name: '21. Disposal: Parent with 10 Direct Children',
        operations: runs,
        elapsedMicros: sw.elapsedMicroseconds,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 22: Disposal of Deeply Nested Hierarchy (20 Scopes)
  // ---------------------------------------------------------------------------
  {
    const runs = 10000;
    final sw = Stopwatch()..start();
    for (var i = 0; i < runs; i++) {
      final root = DependencyBox.main();
      var current = root;
      for (var d = 0; d < 20; d++) {
        current = current.createChild();
      }
      await root.dispose();
    }
    sw.stop();

    results.add(
      BenchmarkResult(
        name: '22. Disposal: Deep Hierarchy (20 Scopes Cascade)',
        operations: runs,
        elapsedMicros: sw.elapsedMicroseconds,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 23: Disposal of Wide Hierarchy (100 Direct Children)
  // ---------------------------------------------------------------------------
  {
    const runs = 2000;
    final sw = Stopwatch()..start();
    for (var i = 0; i < runs; i++) {
      final parent = DependencyBox.main();
      for (var c = 0; c < 100; c++) {
        parent.createChild();
      }
      await parent.dispose();
    }
    sw.stop();

    results.add(
      BenchmarkResult(
        name: '23. Disposal: Wide Hierarchy (100 Direct Children)',
        operations: runs,
        elapsedMicros: sw.elapsedMicroseconds,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 24: LookupScope.local get<T>() Resolution (O(1))
  // ---------------------------------------------------------------------------
  {
    final parent = DependencyBox.main();
    final child = parent.createChild();
    child.addSingleton<ConfigService>(ConfigService());

    results.add(
      measure(
        '24. LookupScope.local get<T>() [O(1) Local Only]',
        heavyCount,
        () {
          final res = child.get<ConfigService>(scope: LookupScope.local);
          if (identical(res, null)) throw StateError('null');
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 25: LookupScope.root get<T>() Resolution (O(1) Direct Jump)
  // ---------------------------------------------------------------------------
  {
    final root = DependencyBox.main();
    root.addSingleton<ConfigService>(ConfigService());
    var current = root;
    for (var i = 0; i < 10; i++) {
      current = current.createChild();
    }
    final leaf = current;

    results.add(
      measure(
        '25. LookupScope.root get<T>() [O(1) 10 Scopes Deep]',
        heavyCount,
        () {
          final res = leaf.get<ConfigService>(scope: LookupScope.root);
          if (identical(res, null)) throw StateError('null');
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 26: LookupScope.parent get<T>() Resolution (O(1) 1-Hop)
  // ---------------------------------------------------------------------------
  {
    final parent = DependencyBox.main();
    parent.addSingleton<ConfigService>(ConfigService());
    final child = parent.createChild();

    results.add(
      measure(
        '26. LookupScope.parent get<T>() [O(1) Direct Parent]',
        heavyCount,
        () {
          final res = child.get<ConfigService>(scope: LookupScope.parent);
          if (identical(res, null)) throw StateError('null');
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 27: LookupScope.ancestors get<T>() Resolution (O(d) Cascade)
  // ---------------------------------------------------------------------------
  {
    final parent = DependencyBox.main();
    parent.addSingleton<ConfigService>(ConfigService());
    final child = parent.createChild();
    child.addSingleton<ConfigService>(ConfigService()); // Shadows parent

    results.add(
      measure(
        '27. LookupScope.ancestors get<T>() [Skips Local]',
        heavyCount,
        () {
          final res = child.get<ConfigService>(scope: LookupScope.ancestors);
          if (identical(res, null)) throw StateError('null');
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 28: Hierarchy Introspection: depth Getter (O(1))
  // ---------------------------------------------------------------------------
  {
    final root = DependencyBox.main();
    var current = root;
    for (var i = 0; i < 10; i++) {
      current = current.createChild();
    }
    final leaf = current;

    results.add(
      measure(
        '28. Hierarchy Introspection: depth [O(1) Cached]',
        heavyCount,
        () {
          final d = leaf.depth;
          if (d != 10) throw StateError('unexpected depth');
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 29: Hierarchy Introspection: isShadowed<T>()
  // ---------------------------------------------------------------------------
  {
    final root = DependencyBox.main();
    root.addSingleton<ConfigService>(ConfigService());
    final child = root.createChild();
    child.addSingleton<ConfigService>(ConfigService());

    results.add(
      measure('29. Hierarchy Introspection: isShadowed<T>()', heavyCount, () {
        final shadowed = child.isShadowed<ConfigService>();
        if (!shadowed) throw StateError('expected true');
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Benchmark 30: Hierarchy Introspection: findOwner<T>() (Inherited)
  // ---------------------------------------------------------------------------
  {
    final root = DependencyBox.main();
    root.addSingleton<ConfigService>(ConfigService());
    var current = root;
    for (var i = 0; i < 5; i++) {
      current = current.createChild();
    }
    final leaf = current;

    results.add(
      measure(
        '30. Hierarchy Introspection: findOwner<T>() [5 Levels]',
        heavyCount,
        () {
          final owner = leaf.findOwner<ConfigService>();
          if (owner == null) throw StateError('expected owner');
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Print Formatted Output Table
  // ---------------------------------------------------------------------------
  stdout.writeln(
    '| Scenario                                         | Operations | Total Time |      Ops/sec |    Latency |',
  );
  stdout.writeln(
    '|:-------------------------------------------------|-----------:|-----------:|-------------:|-----------:|',
  );

  for (final r in results) {
    final opsStr = r.operations.toString().padLeft(10);
    final timeStr = '${(r.elapsedMicros / 1000).toStringAsFixed(1)} ms'.padLeft(
      10,
    );
    final opsSecStr = '${r.opsPerSec.toStringAsFixed(0)} ops/s'.padLeft(12);
    final latencyStr = r.name.startsWith('11.')
        ? '${(r.nsPerOp / 1000000).toStringAsFixed(3)} ms/setup'.padLeft(10)
        : r.name.startsWith('12.')
        ? '${(r.nsPerOp / 1000).toStringAsFixed(2)} µs/init'.padLeft(10)
        : r.nsPerOp >= 1000000
        ? '${(r.nsPerOp / 1000000).toStringAsFixed(3)} ms/op'.padLeft(10)
        : r.nsPerOp >= 1000
        ? '${(r.nsPerOp / 1000).toStringAsFixed(2)} µs/op'.padLeft(10)
        : '${r.nsPerOp.toStringAsFixed(2)} ns/op'.padLeft(10);
    final nameStr = r.name.padRight(54);

    stdout.writeln(
      '| $nameStr | $opsStr | $timeStr | $opsSecStr | $latencyStr |',
    );
  }

  stdout.writeln(
    '========================================================================\n',
  );
}
