import 'package:dependency_box/dependency_box.dart';
import 'package:get_it/get_it.dart';
import '../fixtures/models.dart';
import '../harness/benchmark_framework.dart';
import '../injectable/injectable_models.dart';
import '../injectable/injectable_setup.config.dart';

class BenchmarkSuiteScenarios {
  final BenchmarkRunner runner;
  final List<BenchmarkMetric> results = [];

  BenchmarkSuiteScenarios({required this.runner});

  // ===========================================================================
  // SCENARIO 0: Baseline Diagnostics (Empty Loop & Direct Variable)
  // ===========================================================================
  void runScenario0() {
    print(
        '\n>>> Running Scenario 0: Baselines (Empty Loop & Direct Variable Access)');

    // 0a: Raw inlined empty loop
    results.add(runner.runCustomLoopBatched(
      scenario: '0a. Baseline: Raw Empty For-Loop (no closure)',
      framework: 'baseline_raw_loop',
      registrations: 0,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 500000,
      loopAction: (n) {
        for (var i = 0; i < n; i++) {
          // empty iteration
        }
      },
    ));

    // 0b: Empty closure invocation
    results.add(runner.runBatched(
      scenario: '0b. Baseline: Empty Closure Invocation in Loop',
      framework: 'baseline_closure',
      registrations: 0,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 500000,
      action: () {
        // empty closure
      },
    ));

    // 0c: Direct variable access + consume (Speed of Light - No DI)
    final directConfig = AppConfig();
    results.add(runner.runBatched(
      scenario: '0c. Baseline: Direct Variable Access (Speed of Light - No DI)',
      framework: 'baseline_direct_var',
      registrations: 1,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 500000,
      action: () {
        consume(directConfig);
      },
    ));

    // 0d: Direct field property access on object (No DI)
    results.add(runner.runBatched(
      scenario: '0d. Baseline: Direct Field Access on Object (No DI)',
      framework: 'baseline_field_access',
      registrations: 1,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 500000,
      action: () {
        consume(directConfig.env);
      },
    ));
  }

  // ===========================================================================
  // SCENARIO SCALE: Multi-Scale Iteration Scaling (1e5, 1e6, 1e7, 1e8 ops)
  // ===========================================================================
  void runHotPathScalingSuite() {
    print(
        '\n>>> Running Scale Verification: Hot-Path Across 1e5, 1e6, 1e7, 1e8 Operations');

    final directConfig = AppConfig();
    final boxSingleton = DependencyBox.main();
    boxSingleton.addSingleton<AppConfig>(directConfig);

    final giSingleton = GetIt.asNewInstance();
    giSingleton.registerSingleton<AppConfig>(directConfig);

    final boxLazy = DependencyBox.main();
    boxLazy.addLazySingleton<LocalStorage>((_) => LocalStorage());
    boxLazy.get<LocalStorage>(); // prime

    final giLazy = GetIt.asNewInstance();
    giLazy.registerLazySingleton<LocalStorage>(() => LocalStorage());
    giLazy<LocalStorage>(); // prime

    // Scale tier configurations: [name, batchCount, iterationsPerBatch, totalOps]
    final tiers = <Map<String, dynamic>>[
      {'name': '1e5 ops', 'batches': 5, 'batchOps': 20000, 'total': 100000},
      {'name': '1e6 ops', 'batches': 5, 'batchOps': 200000, 'total': 1000000},
      {'name': '1e7 ops', 'batches': 5, 'batchOps': 2000000, 'total': 10000000},
    ];

    for (final tier in tiers) {
      final tierName = tier['name'] as String;
      final batches = tier['batches'] as int;
      final batchOps = tier['batchOps'] as int;

      // 1. Direct variable baseline
      results.add(runner.runBatched(
        scenario: 'Scale ($tierName): Direct Variable Access',
        framework: 'baseline_direct',
        registrations: 1,
        warmupIterations: 10000,
        batchCount: batches,
        iterationsPerBatch: batchOps,
        action: () {
          consume(directConfig);
        },
      ));

      // 2. dependency_box Eager Singleton
      results.add(runner.runBatched(
        scenario: 'Scale ($tierName): Eager Singleton Resolution',
        framework: 'dependency_box',
        registrations: 1,
        warmupIterations: 10000,
        batchCount: batches,
        iterationsPerBatch: batchOps,
        action: () {
          consume(boxSingleton.get<AppConfig>());
        },
      ));

      // 3. get_it Eager Singleton
      results.add(runner.runBatched(
        scenario: 'Scale ($tierName): Eager Singleton Resolution',
        framework: 'get_it',
        registrations: 1,
        warmupIterations: 10000,
        batchCount: batches,
        iterationsPerBatch: batchOps,
        action: () {
          consume(giSingleton<AppConfig>());
        },
      ));

      // 4. dependency_box Lazy Singleton
      results.add(runner.runBatched(
        scenario: 'Scale ($tierName): Cached Lazy Singleton Resolution',
        framework: 'dependency_box',
        registrations: 1,
        warmupIterations: 10000,
        batchCount: batches,
        iterationsPerBatch: batchOps,
        action: () {
          consume(boxLazy.get<LocalStorage>());
        },
      ));

      // 5. get_it Lazy Singleton
      results.add(runner.runBatched(
        scenario: 'Scale ($tierName): Cached Lazy Singleton Resolution',
        framework: 'get_it',
        registrations: 1,
        warmupIterations: 10000,
        batchCount: batches,
        iterationsPerBatch: batchOps,
        action: () {
          consume(giLazy<LocalStorage>());
        },
      ));
    }

    // 1e8 Tier (100 Million Operations) for sub-50ns operations & get_it verification
    print('  Executing 1e8 (100,000,000 ops) high-volume stress tier...');
    const tier1e8Batches = 2;
    const tier1e8BatchOps = 50000000; // 2 * 50M = 100M total ops

    // 1e8: Direct variable
    results.add(runner.runBatched(
      scenario: 'Scale (1e8 ops): Direct Variable Access',
      framework: 'baseline_direct',
      registrations: 1,
      warmupIterations: 50000,
      batchCount: tier1e8Batches,
      iterationsPerBatch: tier1e8BatchOps,
      action: () {
        consume(directConfig);
      },
    ));

    // 1e8: dependency_box Eager Singleton
    results.add(runner.runBatched(
      scenario: 'Scale (1e8 ops): Eager Singleton Resolution',
      framework: 'dependency_box',
      registrations: 1,
      warmupIterations: 50000,
      batchCount: tier1e8Batches,
      iterationsPerBatch: tier1e8BatchOps,
      action: () {
        consume(boxSingleton.get<AppConfig>());
      },
    ));

    // 1e8: dependency_box Lazy Singleton
    results.add(runner.runBatched(
      scenario: 'Scale (1e8 ops): Cached Lazy Singleton Resolution',
      framework: 'dependency_box',
      registrations: 1,
      warmupIterations: 50000,
      batchCount: tier1e8Batches,
      iterationsPerBatch: tier1e8BatchOps,
      action: () {
        consume(boxLazy.get<LocalStorage>());
      },
    ));

    // 1e8: get_it Eager Singleton (2 batches of 15M ops = 30M ops where practical to avoid multi-minute waits)
    results.add(runner.runBatched(
      scenario: 'Scale (3e7 ops practical max): Eager Singleton Resolution',
      framework: 'get_it',
      registrations: 1,
      warmupIterations: 20000,
      batchCount: 2,
      iterationsPerBatch: 15000000,
      action: () {
        consume(giSingleton<AppConfig>());
      },
    ));
  }

  // ===========================================================================
  // SCENARIO A: Registration & Initialization
  // ===========================================================================
  void runScenarioA() {
    print('\n>>> Running Scenario A: Registration & Initialization');

    // --- A1: Eager Singletons (10, 100, 1,000) ---
    for (final count in [10, 100, 1000]) {
      results.add(runner.runBatched(
        scenario: 'A1. Register Eager Singletons ($count)',
        framework: 'dependency_box',
        registrations: count,
        warmupIterations: 20,
        batchCount: 10,
        iterationsPerBatch: 100,
        isMicros: true,
        action: () {
          final box = DependencyBox.main();
          for (var i = 0; i < count; i++) {
            box.addSingleton<int>(i, key: 'k_$i');
          }
        },
      ));

      results.add(runner.runBatched(
        scenario: 'A1. Register Eager Singletons ($count)',
        framework: 'get_it',
        registrations: count,
        warmupIterations: 20,
        batchCount: 10,
        iterationsPerBatch: 100,
        isMicros: true,
        action: () {
          final gi = GetIt.asNewInstance();
          for (var i = 0; i < count; i++) {
            gi.registerSingleton<int>(i, instanceName: 'k_$i');
          }
        },
      ));
    }

    // --- A2: Lazy Singletons (10, 100, 1,000) ---
    for (final count in [10, 100, 1000]) {
      results.add(runner.runBatched(
        scenario: 'A2. Register Lazy Singletons ($count)',
        framework: 'dependency_box',
        registrations: count,
        warmupIterations: 20,
        batchCount: 10,
        iterationsPerBatch: 100,
        isMicros: true,
        action: () {
          final box = DependencyBox.main();
          for (var i = 0; i < count; i++) {
            box.addLazySingleton<int>((_) => i, key: 'k_$i');
          }
        },
      ));

      results.add(runner.runBatched(
        scenario: 'A2. Register Lazy Singletons ($count)',
        framework: 'get_it',
        registrations: count,
        warmupIterations: 20,
        batchCount: 10,
        iterationsPerBatch: 100,
        isMicros: true,
        action: () {
          final gi = GetIt.asNewInstance();
          for (var i = 0; i < count; i++) {
            gi.registerLazySingleton<int>(() => i, instanceName: 'k_$i');
          }
        },
      ));
    }

    // --- A3: Factories (10, 100, 1,000) ---
    for (final count in [10, 100, 1000]) {
      results.add(runner.runBatched(
        scenario: 'A3. Register Factories ($count)',
        framework: 'dependency_box',
        registrations: count,
        warmupIterations: 20,
        batchCount: 10,
        iterationsPerBatch: 100,
        isMicros: true,
        action: () {
          final box = DependencyBox.main();
          for (var i = 0; i < count; i++) {
            box.addFactory<int>((_) => i, key: 'k_$i');
          }
        },
      ));

      results.add(runner.runBatched(
        scenario: 'A3. Register Factories ($count)',
        framework: 'get_it',
        registrations: count,
        warmupIterations: 20,
        batchCount: 10,
        iterationsPerBatch: 100,
        isMicros: true,
        action: () {
          final gi = GetIt.asNewInstance();
          for (var i = 0; i < count; i++) {
            gi.registerFactory<int>(() => i, instanceName: 'k_$i');
          }
        },
      ));
    }

    // --- A4: Complete Graph Bootstrap ---
    results.add(runner.runBatched(
      scenario: 'A4. Complete Graph Bootstrap (Real-world Graph)',
      framework: 'dependency_box',
      registrations: 12,
      warmupIterations: 50,
      batchCount: 10,
      iterationsPerBatch: 500,
      isMicros: true,
      action: () {
        final box = DependencyBox.main();
        box.addSingleton<InjAppConfig>(InjAppConfig());
        box.addSingleton<InjDeepLevel1>(InjDeepLevel1());
        box.addLazySingleton<InjLocalStorage>((_) => InjLocalStorage());
        box.addSingleton<InjKeyedSecondary>(InjKeyedSecondary(),
            key: 'secondary');
        box.addSingleton<InjKeyedPrimary>(InjKeyedPrimary(), key: 'primary');
        box.addFactory<InjHttpClient>(
            (c) => InjHttpClient(c.get<InjAppConfig>()));
        box.addFactory<InjDeepLevel2>(
            (c) => InjDeepLevel2(c.get<InjDeepLevel1>()));
        box.addFactory<InjUserRepository>((c) => InjUserRepository(
            c.get<InjAppConfig>(),
            c.get<InjLocalStorage>(),
            c.get<InjHttpClient>()));
        box.addFactory<InjDeepLevel3>(
            (c) => InjDeepLevel3(c.get<InjDeepLevel2>()));
        box.addFactory<InjUserService>(
            (c) => InjUserService(c.get<InjUserRepository>()));
        box.addFactory<InjDeepLevel4>(
            (c) => InjDeepLevel4(c.get<InjDeepLevel3>()));
        box.addFactory<InjDeepLevel5>(
            (c) => InjDeepLevel5(c.get<InjDeepLevel4>()));
      },
    ));

    results.add(runner.runBatched(
      scenario: 'A4. Complete Graph Bootstrap (Real-world Graph)',
      framework: 'get_it',
      registrations: 12,
      warmupIterations: 50,
      batchCount: 10,
      iterationsPerBatch: 500,
      isMicros: true,
      action: () {
        final gi = GetIt.asNewInstance();
        gi.registerSingleton<InjAppConfig>(InjAppConfig());
        gi.registerSingleton<InjDeepLevel1>(InjDeepLevel1());
        gi.registerLazySingleton<InjLocalStorage>(() => InjLocalStorage());
        gi.registerSingleton<InjKeyedSecondary>(InjKeyedSecondary(),
            instanceName: 'secondary');
        gi.registerSingleton<InjKeyedPrimary>(InjKeyedPrimary(),
            instanceName: 'primary');
        gi.registerFactory<InjHttpClient>(
            () => InjHttpClient(gi<InjAppConfig>()));
        gi.registerFactory<InjDeepLevel2>(
            () => InjDeepLevel2(gi<InjDeepLevel1>()));
        gi.registerFactory<InjUserRepository>(() => InjUserRepository(
            gi<InjAppConfig>(), gi<InjLocalStorage>(), gi<InjHttpClient>()));
        gi.registerFactory<InjDeepLevel3>(
            () => InjDeepLevel3(gi<InjDeepLevel2>()));
        gi.registerFactory<InjUserService>(
            () => InjUserService(gi<InjUserRepository>()));
        gi.registerFactory<InjDeepLevel4>(
            () => InjDeepLevel4(gi<InjDeepLevel3>()));
        gi.registerFactory<InjDeepLevel5>(
            () => InjDeepLevel5(gi<InjDeepLevel4>()));
      },
    ));

    // Injectable Graph Init (Real generated code)
    results.add(runner.runBatched(
      scenario: 'A4. Complete Graph Bootstrap (Real-world Graph)',
      framework: 'injectable',
      registrations: 12,
      warmupIterations: 50,
      batchCount: 10,
      iterationsPerBatch: 500,
      isMicros: true,
      action: () {
        final gi = GetIt.asNewInstance();
        gi.init();
      },
    ));

    // --- A5: Lazy Singleton First Resolution vs Subsequent ---
    results.add(runner.runBatched(
      scenario: 'A5. Lazy Singleton First Access',
      framework: 'dependency_box',
      registrations: 1,
      warmupIterations: 100,
      batchCount: 10,
      iterationsPerBatch: 1000,
      action: () {
        final box = DependencyBox.main();
        box.addLazySingleton<LocalStorage>((_) => LocalStorage());
        consume(box.get<LocalStorage>());
      },
    ));

    results.add(runner.runBatched(
      scenario: 'A5. Lazy Singleton First Access',
      framework: 'get_it',
      registrations: 1,
      warmupIterations: 100,
      batchCount: 10,
      iterationsPerBatch: 1000,
      action: () {
        final gi = GetIt.asNewInstance();
        gi.registerLazySingleton<LocalStorage>(() => LocalStorage());
        consume(gi<LocalStorage>());
      },
    ));
  }

  // ===========================================================================
  // SCENARIO B: Hot-Path Resolution
  // ===========================================================================
  void runScenarioB() {
    print('\n>>> Running Scenario B: Hot-Path Resolution');

    // --- B1: Eager Singleton Resolution (Unkeyed) with 10, 100, 1000 in container ---
    for (final size in [10, 100, 1000]) {
      final box = DependencyBox.main();
      final gi = GetIt.asNewInstance();

      final target = AppConfig();
      box.addSingleton<AppConfig>(target);
      gi.registerSingleton<AppConfig>(target);

      for (var i = 1; i < size; i++) {
        box.addSingleton<String>('val_$i', key: 'k_$i');
        gi.registerSingleton<String>('val_$i', instanceName: 'k_$i');
      }

      results.add(runner.runBatched(
        scenario: 'B1. Eager Singleton Hot-Path ($size items in container)',
        framework: 'dependency_box',
        registrations: size,
        warmupIterations: 100000,
        batchCount: 10,
        iterationsPerBatch: 500000,
        action: () {
          consume(box.get<AppConfig>());
        },
      ));

      results.add(runner.runBatched(
        scenario: 'B1. Eager Singleton Hot-Path ($size items in container)',
        framework: 'get_it',
        registrations: size,
        warmupIterations: 100000,
        batchCount: 10,
        iterationsPerBatch: 500000,
        action: () {
          consume(gi<AppConfig>());
        },
      ));
    }

    // --- B2: Cached Lazy Singleton Lookup ---
    final boxLazy = DependencyBox.main();
    final giLazy = GetIt.asNewInstance();
    boxLazy.addLazySingleton<LocalStorage>((_) => LocalStorage());
    giLazy.registerLazySingleton<LocalStorage>(() => LocalStorage());
    boxLazy.get<LocalStorage>(); // prime
    giLazy<LocalStorage>(); // prime

    results.add(runner.runBatched(
      scenario: 'B2. Cached Lazy Singleton Resolution',
      framework: 'dependency_box',
      registrations: 1,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 500000,
      action: () {
        consume(boxLazy.get<LocalStorage>());
      },
    ));

    results.add(runner.runBatched(
      scenario: 'B2. Cached Lazy Singleton Resolution',
      framework: 'get_it',
      registrations: 1,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 500000,
      action: () {
        consume(giLazy<LocalStorage>());
      },
    ));

    // --- B3: Factory Resolution (Clean creation on each call) ---
    final boxFactory = DependencyBox.main();
    final giFactory = GetIt.asNewInstance();
    boxFactory.addFactory<ShallowRepository>((_) => ShallowRepository());
    giFactory.registerFactory<ShallowRepository>(() => ShallowRepository());

    results.add(runner.runBatched(
      scenario: 'B3. Factory Instantiation',
      framework: 'dependency_box',
      registrations: 1,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 500000,
      action: () {
        consume(boxFactory.get<ShallowRepository>());
      },
    ));

    results.add(runner.runBatched(
      scenario: 'B3. Factory Instantiation',
      framework: 'get_it',
      registrations: 1,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 500000,
      action: () {
        consume(giFactory<ShallowRepository>());
      },
    ));

    // --- B4: Keyed / Named Singleton Resolution ---
    final boxKeyed = DependencyBox.main();
    final giKeyed = GetIt.asNewInstance();
    boxKeyed.addSingleton<String>('https://prod.api.com', key: 'primary');
    giKeyed.registerSingleton<String>('https://prod.api.com',
        instanceName: 'primary');

    results.add(runner.runBatched(
      scenario: 'B4. Keyed / Named Singleton Resolution',
      framework: 'dependency_box',
      registrations: 1,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 500000,
      action: () {
        consume(boxKeyed.get<String>(key: 'primary'));
      },
    ));

    results.add(runner.runBatched(
      scenario: 'B4. Keyed / Named Singleton Resolution',
      framework: 'get_it',
      registrations: 1,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 500000,
      action: () {
        consume(giKeyed<String>(instanceName: 'primary'));
      },
    ));

    // Injectable Keyed Resolution
    final giInj = GetIt.asNewInstance();
    giInj.init();

    results.add(runner.runBatched(
      scenario: 'B4. Keyed / Named Singleton Resolution',
      framework: 'injectable',
      registrations: 1,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 500000,
      action: () {
        consume(giInj<InjKeyedPrimary>(instanceName: 'primary'));
      },
    ));
  }

  // ===========================================================================
  // SCENARIO C: Dependency Graphs (Shallow, Medium, Deep)
  // ===========================================================================
  void runScenarioC() {
    print('\n>>> Running Scenario C: Dependency Graphs');

    // --- C1: Shallow Graph (1 dependency) ---
    final boxShallow = DependencyBox.main();
    final giShallow = GetIt.asNewInstance();
    boxShallow.addSingleton<ShallowRepository>(ShallowRepository());
    boxShallow.addFactory<ShallowService>(
        (c) => ShallowService(c.get<ShallowRepository>()));

    giShallow.registerSingleton<ShallowRepository>(ShallowRepository());
    giShallow.registerFactory<ShallowService>(
        () => ShallowService(giShallow<ShallowRepository>()));

    results.add(runner.runBatched(
      scenario: 'C1. Shallow Graph Factory Creation (1 dependency)',
      framework: 'dependency_box',
      registrations: 2,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 300000,
      action: () {
        consume(boxShallow.get<ShallowService>());
      },
    ));

    results.add(runner.runBatched(
      scenario: 'C1. Shallow Graph Factory Creation (1 dependency)',
      framework: 'get_it',
      registrations: 2,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 300000,
      action: () {
        consume(giShallow<ShallowService>());
      },
    ));

    // --- C2: Medium Graph (3 dependencies) ---
    final boxMedium = DependencyBox.main();
    final giMedium = GetIt.asNewInstance();

    boxMedium.addSingleton<AppConfig>(AppConfig());
    boxMedium.addSingleton<LocalStorage>(LocalStorage());
    boxMedium.addFactory<HttpClient>((c) => HttpClient(c.get<AppConfig>()));
    boxMedium.addFactory<UserRepository>((c) => UserRepository(
        c.get<AppConfig>(), c.get<LocalStorage>(), c.get<HttpClient>()));
    boxMedium
        .addFactory<UserService>((c) => UserService(c.get<UserRepository>()));

    giMedium.registerSingleton<AppConfig>(AppConfig());
    giMedium.registerSingleton<LocalStorage>(LocalStorage());
    giMedium
        .registerFactory<HttpClient>(() => HttpClient(giMedium<AppConfig>()));
    giMedium.registerFactory<UserRepository>(() => UserRepository(
        giMedium<AppConfig>(),
        giMedium<LocalStorage>(),
        giMedium<HttpClient>()));
    giMedium.registerFactory<UserService>(
        () => UserService(giMedium<UserRepository>()));

    results.add(runner.runBatched(
      scenario: 'C2. Medium Graph Factory Creation',
      framework: 'dependency_box',
      registrations: 5,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 300000,
      action: () {
        consume(boxMedium.get<UserService>());
      },
    ));

    results.add(runner.runBatched(
      scenario: 'C2. Medium Graph Factory Creation',
      framework: 'get_it',
      registrations: 5,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 300000,
      action: () {
        consume(giMedium<UserService>());
      },
    ));

    // Injectable Medium Graph
    final giInj = GetIt.asNewInstance();
    giInj.init();

    results.add(runner.runBatched(
      scenario: 'C2. Medium Graph Factory Creation',
      framework: 'injectable',
      registrations: 5,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 300000,
      action: () {
        consume(giInj<InjUserService>());
      },
    ));

    // --- C3: Deep Graph (5 levels chain) ---
    final boxDeep = DependencyBox.main();
    final giDeep = GetIt.asNewInstance();

    boxDeep.addSingleton<DeepLevel1Core>(DeepLevel1Core());
    boxDeep.addFactory<DeepLevel2Storage>(
        (c) => DeepLevel2Storage(c.get<DeepLevel1Core>()));
    boxDeep.addFactory<DeepLevel3Client>(
        (c) => DeepLevel3Client(c.get<DeepLevel2Storage>()));
    boxDeep.addFactory<DeepLevel4Gateway>(
        (c) => DeepLevel4Gateway(c.get<DeepLevel3Client>()));
    boxDeep.addFactory<DeepLevel5Service>(
        (c) => DeepLevel5Service(c.get<DeepLevel4Gateway>()));

    giDeep.registerSingleton<DeepLevel1Core>(DeepLevel1Core());
    giDeep.registerFactory<DeepLevel2Storage>(
        () => DeepLevel2Storage(giDeep<DeepLevel1Core>()));
    giDeep.registerFactory<DeepLevel3Client>(
        () => DeepLevel3Client(giDeep<DeepLevel2Storage>()));
    giDeep.registerFactory<DeepLevel4Gateway>(
        () => DeepLevel4Gateway(giDeep<DeepLevel3Client>()));
    giDeep.registerFactory<DeepLevel5Service>(
        () => DeepLevel5Service(giDeep<DeepLevel4Gateway>()));

    results.add(runner.runBatched(
      scenario: 'C3. Deep Graph Factory Creation',
      framework: 'dependency_box',
      registrations: 5,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 300000,
      action: () {
        consume(boxDeep.get<DeepLevel5Service>());
      },
    ));

    results.add(runner.runBatched(
      scenario: 'C3. Deep Graph Factory Creation',
      framework: 'get_it',
      registrations: 5,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 300000,
      action: () {
        consume(giDeep<DeepLevel5Service>());
      },
    ));

    // Injectable Deep Graph
    results.add(runner.runBatched(
      scenario: 'C3. Deep Graph Factory Creation',
      framework: 'injectable',
      registrations: 5,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 300000,
      action: () {
        consume(giInj<InjDeepLevel5>());
      },
    ));
  }

  // ===========================================================================
  // SCENARIO D: Keyed & Multi-Registration Lookups
  // ===========================================================================
  void runScenarioD() {
    print('\n>>> Running Scenario D: Keyed & Multi-Registration Lookups');

    final box = DependencyBox.main();
    final gi = GetIt.asNewInstance();

    box.allowMulti<Plugin>();
    box.addSingletons<Plugin>([
      AuthPlugin(),
      LoggingPlugin(),
      MetricsPlugin(),
    ]);

    gi.registerSingleton<Plugin>(AuthPlugin(), instanceName: 'p1');
    gi.registerSingleton<Plugin>(LoggingPlugin(), instanceName: 'p2');
    gi.registerSingleton<Plugin>(MetricsPlugin(), instanceName: 'p3');

    // D1: Single Lookup from Multi-Registration
    results.add(runner.runBatched(
      scenario: 'D1. Single Lookup from Multi-Registration',
      framework: 'dependency_box',
      registrations: 3,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 500000,
      action: () {
        consume(box.get<Plugin>());
      },
    ));

    results.add(runner.runBatched(
      scenario: 'D1. Single Lookup from Multi-Registration',
      framework: 'get_it',
      registrations: 3,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 500000,
      action: () {
        consume(gi<Plugin>(instanceName: 'p3'));
      },
    ));

    // D2: Bulk Retrieval of All Registered Implementations (getAll)
    results.add(runner.runBatched(
      scenario: 'D2. Bulk Retrieval of All Implementations (getAll)',
      framework: 'dependency_box',
      registrations: 3,
      warmupIterations: 50000,
      batchCount: 10,
      iterationsPerBatch: 200000,
      action: () {
        consume(box.getAll<Plugin>());
      },
    ));

    results.add(runner.runBatched(
      scenario: 'D2. Bulk Retrieval of All Implementations (getAll)',
      framework: 'get_it',
      registrations: 3,
      warmupIterations: 50000,
      batchCount: 10,
      iterationsPerBatch: 200000,
      action: () {
        consume(gi.getAll<Plugin>());
      },
    ));
  }

  // ===========================================================================
  // SCENARIO E: Asynchronous Singletons
  // ===========================================================================
  Future<void> runScenarioE() async {
    print('\n>>> Running Scenario E: Asynchronous Singletons');

    final boxAsync = DependencyBox.main();
    final giAsync = GetIt.asNewInstance();

    boxAsync.addAsyncSingleton<AsyncDatabase>((_) async {
      return await AsyncDatabase.connect('db://bench');
    });
    giAsync.registerSingletonAsync<AsyncDatabase>(() async {
      return await AsyncDatabase.connect('db://bench');
    });

    await boxAsync.getAsync<AsyncDatabase>();
    await giAsync.isReady<AsyncDatabase>();

    // Synchronous get on already-resolved async singleton
    results.add(runner.runBatched(
      scenario: 'E1. Cached Async Singleton Sync Access (Hot Path)',
      framework: 'dependency_box',
      registrations: 1,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 500000,
      action: () {
        consume(boxAsync.get<AsyncDatabase>());
      },
    ));

    results.add(runner.runBatched(
      scenario: 'E1. Cached Async Singleton Sync Access (Hot Path)',
      framework: 'get_it',
      registrations: 1,
      warmupIterations: 100000,
      batchCount: 10,
      iterationsPerBatch: 500000,
      action: () {
        consume(giAsync<AsyncDatabase>());
      },
    ));

    // E2: Asynchronous getAsync on resolved singleton
    for (var i = 0; i < 50; i++) {
      await boxAsync.getAsync<AsyncDatabase>();
      await giAsync.getAsync<AsyncDatabase>();
    }

    final swBox = Stopwatch()..start();
    const asyncCalls = 50000;
    for (var i = 0; i < asyncCalls; i++) {
      consume(await boxAsync.getAsync<AsyncDatabase>());
    }
    swBox.stop();

    final swGi = Stopwatch()..start();
    for (var i = 0; i < asyncCalls; i++) {
      consume(await giAsync.getAsync<AsyncDatabase>());
    }
    swGi.stop();

    final nsBox = (swBox.elapsedMicroseconds * 1000.0) / asyncCalls;
    final nsGi = (swGi.elapsedMicroseconds * 1000.0) / asyncCalls;

    results.add(BenchmarkMetric(
      scenario: 'E2. Cached Async Singleton Future Resolution (getAsync)',
      framework: 'dependency_box',
      runtimeMode: runner.runtimeMode,
      registrations: 1,
      totalOperations: asyncCalls,
      totalElapsedMicros: swBox.elapsedMicroseconds,
      medianNs: nsBox,
      p95Ns: nsBox,
      minNs: nsBox,
      maxNs: nsBox,
      stdDevNs: 0,
      variabilityPercent: 0,
      opsPerSec: asyncCalls / (swBox.elapsedMicroseconds / 1000000.0),
    ));

    results.add(BenchmarkMetric(
      scenario: 'E2. Cached Async Singleton Future Resolution (getAsync)',
      framework: 'get_it',
      runtimeMode: runner.runtimeMode,
      registrations: 1,
      totalOperations: asyncCalls,
      totalElapsedMicros: swGi.elapsedMicroseconds,
      medianNs: nsGi,
      p95Ns: nsGi,
      minNs: nsGi,
      maxNs: nsGi,
      stdDevNs: 0,
      variabilityPercent: 0,
      opsPerSec: asyncCalls / (swGi.elapsedMicroseconds / 1000000.0),
    ));
  }

  // ===========================================================================
  // SCENARIO F: Scopes & Hierarchies
  // ===========================================================================
  void runScenarioF() {
    print('\n>>> Running Scenario F: Scopes & Hierarchies');

    results.add(runner.runBatched(
      scenario: 'F1. Scoped Session Lifecycle (Create, Register, Use, Destroy)',
      framework: 'dependency_box',
      registrations: 1,
      warmupIterations: 50,
      batchCount: 10,
      iterationsPerBatch: 1000,
      isMicros: true,
      action: () {
        final parent = DependencyBox.main();
        parent.addSingleton<String>('parent_token', key: 'auth');

        final child = parent.createChild();
        child.addSingleton<String>('child_token', key: 'auth');
        consume(child.get<String>(key: 'auth'));
        child.dispose();
      },
    ));

    results.add(runner.runBatched(
      scenario: 'F1. Scoped Session Lifecycle (Create, Register, Use, Destroy)',
      framework: 'get_it',
      registrations: 1,
      warmupIterations: 50,
      batchCount: 10,
      iterationsPerBatch: 1000,
      isMicros: true,
      action: () {
        final gi = GetIt.asNewInstance();
        gi.registerSingleton<String>('parent_token', instanceName: 'auth');

        gi.pushNewScope();
        gi.registerSingleton<String>('child_token', instanceName: 'auth');
        consume(gi<String>(instanceName: 'auth'));
        gi.popScope();
      },
    ));
  }

  // ===========================================================================
  // SCENARIO G: Disposal & Lifecycle
  // ===========================================================================
  void runScenarioG() {
    print('\n>>> Running Scenario G: Disposal & Lifecycle');

    results.add(runner.runBatched(
      scenario: 'G1. Bulk Disposal of 100 Instances',
      framework: 'dependency_box',
      registrations: 100,
      warmupIterations: 20,
      batchCount: 10,
      iterationsPerBatch: 100,
      isMicros: true,
      action: () {
        final box = DependencyBox.main();
        for (var i = 0; i < 100; i++) {
          box.addSingleton<DisposableService>(DisposableService(), key: 'd_$i');
        }
        box.dispose();
      },
    ));

    results.add(runner.runBatched(
      scenario: 'G1. Bulk Disposal of 100 Instances',
      framework: 'get_it',
      registrations: 100,
      warmupIterations: 20,
      batchCount: 10,
      iterationsPerBatch: 100,
      isMicros: true,
      action: () {
        final gi = GetIt.asNewInstance();
        for (var i = 0; i < 100; i++) {
          gi.registerSingleton<DisposableService>(
            DisposableService(),
            instanceName: 'd_$i',
            dispose: (s) => s.dispose(),
          );
        }
        gi.reset();
      },
    ));
  }
}
