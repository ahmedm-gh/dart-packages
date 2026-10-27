import 'dart:io';

import 'package:dependency_box/dependency_box.dart';
import 'package:get_it/get_it.dart';

// ============================================================================
// Real-world Test Models
// ============================================================================

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

class QueryEngine {
  final String query;
  QueryEngine(this.query);
}

// ============================================================================
// Benchmark Timing Harness
// ============================================================================

class BenchmarkScore {
  final int operations;
  final int elapsedMicros;

  BenchmarkScore(this.operations, this.elapsedMicros);

  double get opsPerSec {
    return (operations / (elapsedMicros / 1000000.0));
  }

  double get nsPerOp {
    return (elapsedMicros * 1000.0) / operations;
  }
}

BenchmarkScore runTimed(int iterations, void Function() fn) {
  // Warmup phase (ensure JIT compilation / branch prediction)
  for (var i = 0; i < 50000; i++) {
    fn();
  }

  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    fn();
  }
  sw.stop();

  return BenchmarkScore(iterations, sw.elapsedMicroseconds);
}

void main() {
  stdout.writeln(
    '=========================================================================================',
  );
  stdout.writeln(
    '  COMPREHENSIVE HEAD-TO-HEAD BENCHMARK: dependency_box vs get_it 9.3.0',
  );
  stdout.writeln(
    '  Dart SDK: ${Platform.version.split(' ').first} (${Platform.operatingSystem})',
  );
  stdout.writeln(
    '=========================================================================================\n',
  );

  const hotPathCount = 5000000; // 5 Million iterations
  const factoryCount = 2000000; // 2 Million iterations
  const setupRuns = 2000; // 2,000 complete setups of 1,000 dependencies

  // ---------------------------------------------------------------------------
  // 1. Singleton Resolution (Unkeyed / Default)
  // ---------------------------------------------------------------------------
  stdout.write('Running Test 1/10: Singleton Resolution (5M ops)... ');
  final box1 = DependencyBox.main();
  box1.addSingleton<ConfigService>(ConfigService());
  final scoreBox1 = runTimed(hotPathCount, () {
    final res = box1.get<ConfigService>();
    if (identical(res, null)) throw StateError('');
  });

  final getIt1 = GetIt.asNewInstance();
  getIt1.registerSingleton<ConfigService>(ConfigService());
  final scoreGetIt1 = runTimed(hotPathCount, () {
    final res = getIt1<ConfigService>();
    if (identical(res, null)) throw StateError('');
  });
  stdout.writeln('Done.');

  // ---------------------------------------------------------------------------
  // 2. Keyed / Named Singleton Resolution
  // ---------------------------------------------------------------------------
  stdout.write('Running Test 2/10: Keyed / Named Resolution (5M ops)... ');
  final box2 = DependencyBox.main();
  box2.addSingleton<ConfigService>(ConfigService(), key: 'primary');
  final scoreBox2 = runTimed(hotPathCount, () {
    final res = box2.get<ConfigService>(key: 'primary');
    if (identical(res, null)) throw StateError('');
  });

  final getIt2 = GetIt.asNewInstance();
  getIt2.registerSingleton<ConfigService>(
    ConfigService(),
    instanceName: 'primary',
  );
  final scoreGetIt2 = runTimed(hotPathCount, () {
    final res = getIt2<ConfigService>(instanceName: 'primary');
    if (identical(res, null)) throw StateError('');
  });
  stdout.writeln('Done.');

  // ---------------------------------------------------------------------------
  // 3. Cached Lazy Singleton Resolution
  // ---------------------------------------------------------------------------
  stdout.write(
    'Running Test 3/10: Cached LazySingleton Resolution (5M ops)... ',
  );
  final box3 = DependencyBox.main();
  box3.addLazySingleton<ConfigService>((_) {
    return ConfigService();
  });
  box3.get<ConfigService>(); // prime cache
  final scoreBox3 = runTimed(hotPathCount, () {
    final res = box3.get<ConfigService>();
    if (identical(res, null)) throw StateError('');
  });

  final getIt3 = GetIt.asNewInstance();
  getIt3.registerLazySingleton<ConfigService>(() {
    return ConfigService();
  });
  getIt3<ConfigService>(); // prime cache
  final scoreGetIt3 = runTimed(hotPathCount, () {
    final res = getIt3<ConfigService>();
    if (identical(res, null)) throw StateError('');
  });
  stdout.writeln('Done.');

  // ---------------------------------------------------------------------------
  // 4. Factory Resolution (Fresh Object Instantiation)
  // ---------------------------------------------------------------------------
  stdout.write('Running Test 4/10: Factory Creation (2M ops)... ');
  final box4 = DependencyBox.main();
  box4.addFactory<ConfigService>((_) {
    return ConfigService();
  });
  final scoreBox4 = runTimed(factoryCount, () {
    final res = box4.get<ConfigService>();
    if (identical(res, null)) throw StateError('');
  });

  final getIt4 = GetIt.asNewInstance();
  getIt4.registerFactory<ConfigService>(() {
    return ConfigService();
  });
  final scoreGetIt4 = runTimed(factoryCount, () {
    final res = getIt4<ConfigService>();
    if (identical(res, null)) throw StateError('');
  });
  stdout.writeln('Done.');

  // ---------------------------------------------------------------------------
  // 5. Parameterized Factory Resolution
  // ---------------------------------------------------------------------------
  stdout.write('Running Test 5/10: Parameterized Factory (2M ops)... ');
  final box5 = DependencyBox.main();
  box5.addFactoryWith<QueryEngine, String>((container, query) {
    return QueryEngine(query);
  });
  final scoreBox5 = runTimed(factoryCount, () {
    final res = box5.get<QueryEngine>(args: 'SELECT 1');
    if (identical(res, null)) throw StateError('');
  });

  final getIt5 = GetIt.asNewInstance();
  getIt5.registerFactoryParam<QueryEngine, String, dynamic>((param1, _) {
    return QueryEngine(param1);
  });
  final scoreGetIt5 = runTimed(factoryCount, () {
    final res = getIt5<QueryEngine>(param1: 'SELECT 1');
    if (identical(res, null)) throw StateError('');
  });
  stdout.writeln('Done.');

  // ---------------------------------------------------------------------------
  // 6. Deep Hierarchy Graph Resolution (5-level nested graph)
  // ---------------------------------------------------------------------------
  stdout.write(
    'Running Test 6/10: Deep Dependency Graph Resolution (5M ops)... ',
  );
  final box6 = DependencyBox.main();
  box6.addSingleton<ConfigService>(ConfigService());
  box6.addSingleton<DatabaseService>(
    DatabaseService(box6.get<ConfigService>()),
  );
  box6.addSingleton<NetworkClient>(NetworkClient(box6.get<ConfigService>()));
  box6.addSingleton<UserRepository>(
    UserRepository(box6.get<DatabaseService>(), box6.get<NetworkClient>()),
  );
  box6.addSingleton<AuthService>(AuthService(box6.get<UserRepository>()));
  final scoreBox6 = runTimed(hotPathCount, () {
    final res = box6.get<AuthService>();
    if (identical(res, null)) throw StateError('');
  });

  final getIt6 = GetIt.asNewInstance();
  getIt6.registerSingleton<ConfigService>(ConfigService());
  getIt6.registerSingleton<DatabaseService>(
    DatabaseService(getIt6<ConfigService>()),
  );
  getIt6.registerSingleton<NetworkClient>(
    NetworkClient(getIt6<ConfigService>()),
  );
  getIt6.registerSingleton<UserRepository>(
    UserRepository(getIt6<DatabaseService>(), getIt6<NetworkClient>()),
  );
  getIt6.registerSingleton<AuthService>(AuthService(getIt6<UserRepository>()));
  final scoreGetIt6 = runTimed(hotPathCount, () {
    final res = getIt6<AuthService>();
    if (identical(res, null)) throw StateError('');
  });
  stdout.writeln('Done.');

  // ---------------------------------------------------------------------------
  // 7. Setup Overhead: 100 Dependencies per Container
  // ---------------------------------------------------------------------------
  stdout.write(
    'Running Test 7/10: Setup Overhead: 100 Dependencies (2,000 setups of 100 deps)... ',
  );
  const setupCount = 2000;
  final swBoxSetup = Stopwatch()..start();
  for (var r = 0; r < setupCount; r++) {
    final box = DependencyBox.main();
    for (var i = 0; i < 100; i++) {
      box.addSingleton<int>(i, key: 'id_$i');
    }
  }
  swBoxSetup.stop();
  final scoreBoxSetup = BenchmarkScore(
    setupCount,
    swBoxSetup.elapsedMicroseconds,
  );

  final swGetItSetup = Stopwatch()..start();
  for (var r = 0; r < setupCount; r++) {
    final gi = GetIt.asNewInstance();
    for (var i = 0; i < 100; i++) {
      gi.registerSingleton<int>(i, instanceName: 'id_$i');
    }
  }
  swGetItSetup.stop();
  final scoreGetItSetup = BenchmarkScore(
    setupCount,
    swGetItSetup.elapsedMicroseconds,
  );
  stdout.writeln('Done.');

  // ---------------------------------------------------------------------------
  // 8. Mass Setup: Create Container + 1,000 Keyed Singletons
  // ---------------------------------------------------------------------------
  stdout.write(
    'Running Test 8/10: Mass Setup (2,000 setups of 1,000 deps)... ',
  );
  final swBoxMass = Stopwatch()..start();
  for (var r = 0; r < setupRuns; r++) {
    final box = DependencyBox.main();
    for (var i = 0; i < 1000; i++) {
      box.addSingleton<int>(i, key: 'id_$i');
    }
  }
  swBoxMass.stop();
  final scoreBoxMass = BenchmarkScore(setupRuns, swBoxMass.elapsedMicroseconds);

  final swGetItMass = Stopwatch()..start();
  for (var r = 0; r < setupRuns; r++) {
    final gi = GetIt.asNewInstance();
    for (var i = 0; i < 1000; i++) {
      gi.registerSingleton<int>(i, instanceName: 'id_$i');
    }
  }
  swGetItMass.stop();
  final scoreGetItMass = BenchmarkScore(
    setupRuns,
    swGetItMass.elapsedMicroseconds,
  );
  stdout.writeln('Done.');

  // ---------------------------------------------------------------------------
  // 9. Cached Weak-Reference Factory (Auto-Expiring Singleton)
  // ---------------------------------------------------------------------------
  stdout.write('Running Test 9/10: Cached Weak-Reference Factory (5M ops)... ');
  final box9 = DependencyBox.main();
  box9.addCachedFactory<ConfigService>((_) => ConfigService());
  // Keep reference alive in caller so weak-reference cache stays warm
  final heldInstance = box9.get<ConfigService>();
  final scoreBox9 = runTimed(hotPathCount, () {
    final res = box9.get<ConfigService>();
    if (identical(res, null)) throw StateError('');
  });

  // GetIt lacks weak-reference factories; standard factory is closest comparison
  final getIt9 = GetIt.asNewInstance();
  getIt9.registerFactory<ConfigService>(() => ConfigService());
  final scoreGetIt9 = runTimed(hotPathCount, () {
    final res = getIt9<ConfigService>();
    if (identical(res, null)) throw StateError('');
  });
  if (identical(heldInstance, null)) throw StateError('');
  stdout.writeln('Done.');

  // ---------------------------------------------------------------------------
  // 10. Hierarchical Child Scope with Shared Root Singleton
  // ---------------------------------------------------------------------------
  stdout.write(
    'Running Test 10/10: Hierarchical Child Scope Shared Resolution (5M ops)... ',
  );
  final rootBox10 = DependencyBox.main(name: 'root');
  final childBox10 = rootBox10.createChild(name: 'child_scope');
  childBox10.addSharedSingleton<ConfigService>(ConfigService());
  final scoreBox10 = runTimed(hotPathCount, () {
    final res = childBox10.get<ConfigService>();
    if (identical(res, null)) throw StateError('');
  });

  final getIt10 = GetIt.asNewInstance();
  getIt10.registerSingleton<ConfigService>(ConfigService());
  getIt10.pushNewScope(scopeName: 'child_scope');
  final scoreGetIt10 = runTimed(hotPathCount, () {
    final res = getIt10<ConfigService>();
    if (identical(res, null)) throw StateError('');
  });
  getIt10.popScope();
  stdout.writeln('Done.\n');

  // ===========================================================================
  // Formatted Output Results
  // ===========================================================================

  void printComparison(String title, BenchmarkScore box, BenchmarkScore getIt) {
    final speedup = getIt.nsPerOp / box.nsPerOp;
    final diffPercent = ((getIt.nsPerOp - box.nsPerOp) / getIt.nsPerOp) * 100.0;
    final winner = box.nsPerOp < getIt.nsPerOp
        ? 'dependency_box is ${speedup.toStringAsFixed(2)}x faster (${diffPercent.toStringAsFixed(1)}% less time)'
        : 'get_it is ${(1 / speedup).toStringAsFixed(2)}x faster';

    stdout.writeln('### $title');
    stdout.writeln('| Metric | dependency_box | get_it 9.3.0 | Advantage |');
    stdout.writeln('|:---|:---:|:---:|:---|');
    stdout.writeln(
      '| **Latency** | **${box.nsPerOp.toStringAsFixed(2)} ns/op** | ${getIt.nsPerOp.toStringAsFixed(2)} ns/op | **$winner** |',
    );
    stdout.writeln(
      '| **Throughput** | **${box.opsPerSec.toStringAsFixed(0)} ops/s** | ${getIt.opsPerSec.toStringAsFixed(0)} ops/s | |',
    );
    stdout.writeln('');
  }

  stdout.writeln('## Head-to-Head Performance Results\n');
  printComparison(
    '1. Singleton Resolution (Unkeyed Hot Path)',
    scoreBox1,
    scoreGetIt1,
  );
  printComparison(
    '2. Keyed / Named Singleton Resolution',
    scoreBox2,
    scoreGetIt2,
  );
  printComparison('3. Cached LazySingleton Resolution', scoreBox3, scoreGetIt3);
  printComparison(
    '4. Factory Creation (New Instance on Every Call)',
    scoreBox4,
    scoreGetIt4,
  );
  printComparison(
    '5. Parameterized Factory Resolution',
    scoreBox5,
    scoreGetIt5,
  );
  printComparison(
    '6. Deep Hierarchy Graph Resolution (5 nested layers)',
    scoreBox6,
    scoreGetIt6,
  );
  printComparison(
    '7. Setup Overhead: 100 Dependencies per Container',
    scoreBoxSetup,
    scoreGetItSetup,
  );
  printComparison(
    '8. Mass Setup: Create Container + 1,000 Keyed Singletons',
    scoreBoxMass,
    scoreGetItMass,
  );
  printComparison(
    '9. Cached Weak-Reference Factory (Auto-Expiring Singleton)',
    scoreBox9,
    scoreGetIt9,
  );
  printComparison(
    '10. Hierarchical Child Scope Shared Resolution',
    scoreBox10,
    scoreGetIt10,
  );
}
