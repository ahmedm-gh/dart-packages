import 'package:dependency_box/dependency_box.dart';
import 'package:get_it/get_it.dart';
import '../fixtures/models.dart';
import '../harness/benchmark_framework.dart';
import '../injectable/injectable_models.dart';
import '../injectable/injectable_setup.config.dart';

class ConformanceSuite {
  static Future<bool> runAllTests() async {
    print('===============================================================');
    print('  RUNNING PRE-BENCHMARK CONFORMANCE & PARITY SUITE');
    print('===============================================================');

    var passed = 0;
    var total = 0;

    void assertTest(String name, bool condition) {
      total++;
      if (condition) {
        passed++;
        print('  [PASS] $name');
      } else {
        print('  [FAIL] $name');
        throw StateError('Conformance test failed: $name');
      }
    }

    // -------------------------------------------------------------------------
    // 0. Anti-Dead-Code & Volatile Sink Verification
    // -------------------------------------------------------------------------
    volatileSink = null;
    final testObj = AppConfig();
    consume(testObj);
    assertTest(
      'Anti-DCE: consume() writes value to volatile sink',
      identical(volatileSink, testObj),
    );

    var nullThrew = false;
    try {
      consume(null);
    } catch (_) {
      nullThrew = true;
    }
    assertTest(
      'Anti-DCE: consume(null) throws StateError',
      nullThrew,
    );

    // -------------------------------------------------------------------------
    // 1. Singleton Identity & Reuse
    // -------------------------------------------------------------------------
    final box1 = DependencyBox.main();
    final gi1 = GetIt.asNewInstance();
    final giInj1 = GetIt.asNewInstance();
    giInj1.init();

    final config = AppConfig();
    box1.addSingleton<AppConfig>(config);
    gi1.registerSingleton<AppConfig>(config);

    assertTest(
      'dependency_box singleton identity',
      identical(box1.get<AppConfig>(), config),
    );
    assertTest(
      'get_it singleton identity',
      identical(gi1<AppConfig>(), config),
    );
    assertTest(
      'injectable singleton reuse',
      identical(giInj1<InjAppConfig>(), giInj1<InjAppConfig>()),
    );

    // -------------------------------------------------------------------------
    // 2. Lazy Singleton First Resolution & Caching
    // -------------------------------------------------------------------------
    var boxLazyCount = 0;
    var giLazyCount = 0;

    box1.addLazySingleton<LocalStorage>((_) {
      boxLazyCount++;
      return LocalStorage();
    });
    gi1.registerLazySingleton<LocalStorage>(() {
      giLazyCount++;
      return LocalStorage();
    });

    assertTest('dependency_box lazy not called until get', boxLazyCount == 0);
    assertTest('get_it lazy not called until get', giLazyCount == 0);

    final boxL1 = box1.get<LocalStorage>();
    final boxL2 = box1.get<LocalStorage>();
    assertTest('dependency_box lazy factory called once', boxLazyCount == 1);
    assertTest(
      'dependency_box lazy returns identical instance',
      identical(boxL1, boxL2),
    );

    final giL1 = gi1<LocalStorage>();
    final giL2 = gi1<LocalStorage>();
    assertTest('get_it lazy factory called once', giLazyCount == 1);
    assertTest('get_it lazy returns identical instance', identical(giL1, giL2));

    final injL1 = giInj1<InjLocalStorage>();
    final injL2 = giInj1<InjLocalStorage>();
    assertTest(
      'injectable lazy returns identical instance',
      identical(injL1, injL2),
    );

    // -------------------------------------------------------------------------
    // 3. Factory Uniqueness
    // -------------------------------------------------------------------------
    box1.addFactory<ShallowRepository>((_) {
      return ShallowRepository();
    });
    gi1.registerFactory<ShallowRepository>(() {
      return ShallowRepository();
    });

    assertTest(
      'dependency_box factory creates unique instances',
      !identical(box1.get<ShallowRepository>(), box1.get<ShallowRepository>()),
    );
    assertTest(
      'get_it factory creates unique instances',
      !identical(gi1<ShallowRepository>(), gi1<ShallowRepository>()),
    );
    assertTest(
      'injectable factory creates unique instances',
      !identical(giInj1<InjHttpClient>(), giInj1<InjHttpClient>()),
    );

    // -------------------------------------------------------------------------
    // 4. Graph Construction Correctness (Medium & Deep)
    // -------------------------------------------------------------------------
    box1.addFactory<HttpClient>((c) {
      return HttpClient(c.get<AppConfig>());
    });
    box1.addFactory<UserRepository>((c) {
      return UserRepository(
        c.get<AppConfig>(),
        c.get<LocalStorage>(),
        c.get<HttpClient>(),
      );
    });
    box1.addFactory<UserService>((c) {
      return UserService(c.get<UserRepository>());
    });

    gi1.registerFactory<HttpClient>(() {
      return HttpClient(gi1<AppConfig>());
    });
    gi1.registerFactory<UserRepository>(() {
      return UserRepository(
        gi1<AppConfig>(),
        gi1<LocalStorage>(),
        gi1<HttpClient>(),
      );
    });
    gi1.registerFactory<UserService>(() {
      return UserService(gi1<UserRepository>());
    });

    final boxUser = box1.get<UserService>();
    final giUser = gi1<UserService>();
    final injUser = giInj1<InjUserService>();

    assertTest(
      'dependency_box graph dependency resolution',
      boxUser.repository.client.config.env == 'production',
    );
    assertTest(
      'get_it graph dependency resolution',
      giUser.repository.client.config.env == 'production',
    );
    assertTest(
      'injectable graph dependency resolution',
      injUser.repository.client.config.env == 'production',
    );

    // Deep 5-level graph test
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

    final deepBox = boxDeep.get<DeepLevel5Service>();
    final deepGi = giDeep<DeepLevel5Service>();
    final deepInj = giInj1<InjDeepLevel5>();

    assertTest(
      'dependency_box deep 5-level chain integrity',
      deepBox.gateway.client.storage.core.id == 1,
    );
    assertTest(
      'get_it deep 5-level chain integrity',
      deepGi.gateway.client.storage.core.id == 1,
    );
    assertTest(
      'injectable deep 5-level chain integrity',
      deepInj.level4.level3.level2.level1.id == 1,
    );

    // -------------------------------------------------------------------------
    // 5. Keyed Resolution
    // -------------------------------------------------------------------------
    box1.addSingleton<String>('prod-url', key: 'primary');
    box1.addSingleton<String>('backup-url', key: 'secondary');

    gi1.registerSingleton<String>('prod-url', instanceName: 'primary');
    gi1.registerSingleton<String>('backup-url', instanceName: 'secondary');

    assertTest(
      'dependency_box keyed separation',
      box1.get<String>(key: 'primary') != box1.get<String>(key: 'secondary'),
    );
    assertTest(
      'get_it keyed separation',
      gi1<String>(instanceName: 'primary') !=
          gi1<String>(instanceName: 'secondary'),
    );
    assertTest(
      'injectable named separation',
      giInj1<InjKeyedPrimary>(instanceName: 'primary').tag !=
          giInj1<InjKeyedSecondary>(instanceName: 'secondary').tag,
    );

    // -------------------------------------------------------------------------
    // 6. Multi-Registration Retrieval
    // -------------------------------------------------------------------------
    box1.allowMulti<Plugin>();
    box1.addSingletons<Plugin>(
      [AuthPlugin(), LoggingPlugin(), MetricsPlugin()],
    );

    gi1.registerSingleton<Plugin>(AuthPlugin(), instanceName: 'p1');
    gi1.registerSingleton<Plugin>(LoggingPlugin(), instanceName: 'p2');
    gi1.registerSingleton<Plugin>(MetricsPlugin(), instanceName: 'p3');

    final boxPlugins = box1.getAll<Plugin>();
    final giPlugins = gi1.getAll<Plugin>();

    assertTest(
      'dependency_box getAll returns all 3 plugins',
      boxPlugins.length == 3,
    );
    assertTest('get_it getAll returns all 3 plugins', giPlugins.length == 3);

    // -------------------------------------------------------------------------
    // 7. Async Singleton Concurrency & Deduplication
    // -------------------------------------------------------------------------
    AsyncDatabase.factoryExecutionCount = 0;
    box1.addAsyncSingleton<AsyncDatabase>((_) async {
      return await AsyncDatabase.connect('db://box');
    });

    final asyncResults = await Future.wait([
      box1.getAsync<AsyncDatabase>(),
      box1.getAsync<AsyncDatabase>(),
      box1.getAsync<AsyncDatabase>(),
    ]);

    assertTest(
      'dependency_box async deduplication executes factory once',
      AsyncDatabase.factoryExecutionCount == 1,
    );
    assertTest(
      'dependency_box async concurrent callers get identical instance',
      identical(asyncResults[0], asyncResults[1]) &&
          identical(asyncResults[1], asyncResults[2]),
    );

    // -------------------------------------------------------------------------
    // 8. Scopes & Hierarchies
    // -------------------------------------------------------------------------
    final parentBox = DependencyBox.main();
    parentBox.addSingleton<String>('parent_val', key: 'tok');
    final childBox = parentBox.createChild();
    childBox.addSingleton<String>('child_val', key: 'tok');

    final parentGi = GetIt.asNewInstance();
    parentGi.registerSingleton<String>('parent_val', instanceName: 'tok');
    parentGi.pushNewScope();
    parentGi.registerSingleton<String>('child_val', instanceName: 'tok');

    assertTest(
      'dependency_box child scope shadows parent key',
      childBox.get<String>(key: 'tok') == 'child_val' &&
          parentBox.get<String>(key: 'tok') == 'parent_val',
    );
    assertTest(
      'get_it scope shadows parent key',
      parentGi<String>(instanceName: 'tok') == 'child_val',
    );
    await parentGi.popScope();
    assertTest(
      'get_it restores parent key after popScope',
      parentGi<String>(instanceName: 'tok') == 'parent_val',
    );
    childBox.dispose();

    // -------------------------------------------------------------------------
    // 9. Lifecycle & Disposal Parity
    // -------------------------------------------------------------------------
    DisposableService.disposalCount = 0;
    final boxDisp = DependencyBox.main();
    final dispService1 = DisposableService();
    boxDisp.addSingleton<DisposableService>(dispService1);
    await boxDisp.dispose();

    assertTest(
      'dependency_box disposal executes dispose callback',
      dispService1.isDisposed && DisposableService.disposalCount == 1,
    );

    DisposableService.disposalCount = 0;
    final giDisp = GetIt.asNewInstance();
    final dispService2 = DisposableService();
    giDisp.registerSingleton<DisposableService>(
      dispService2,
      dispose: (s) {
        s.dispose();
      },
    );
    await giDisp.reset();

    assertTest(
      'get_it disposal executes dispose callback',
      dispService2.isDisposed && DisposableService.disposalCount == 1,
    );

    print('\nAll $passed / $total Conformance Tests Passed Successfully!\n');
    return true;
  }
}
