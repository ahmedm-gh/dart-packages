import 'dart:async';

import 'package:dependency_box/dependency_box.dart';

import '../models/fixtures.dart';
import 'adapter.dart';

/// Adapter implementation for [DependencyBox].
class DependencyBoxAdapter extends BenchmarkAdapter {
  DependencyBox _box = DependencyBox.main();
  DependencyBox? _activeChild;
  int _scopeCounter = 0;

  @override
  String get name => 'dependency_box';

  @override
  String get version => '0.1.1';

  @override
  Set<DiCapability> get capabilities => {
    DiCapability.singleton,
    DiCapability.lazySingleton,
    DiCapability.factory,
    DiCapability.cachedWeakReferenceFactory,
    DiCapability.interfaceMapping,
    DiCapability.keyedNamedRegistration,
    DiCapability.nonStringKeys,
    DiCapability.parameterizedFactory,
    DiCapability.asyncSingleton,
    DiCapability.hierarchicalContainerInstances,
    DiCapability.multiRegistrationList,
    DiCapability.circularDependencyDetection,
    DiCapability.targetedRemoval,
    DiCapability.testOverrideReplacement,
    DiCapability.containerIntrospection,
  };

  @override
  void reset() {
    _box = DependencyBox.main();
    _activeChild = null;
    _scopeCounter = 0;
  }

  // --- Registration Workloads ---

  @override
  void registerSingletons(int count) {
    final box = DependencyBox.main();
    for (var i = 0; i < count; i++) {
      box.addSingleton<SingleService>(SingleService(), key: 'singleton_$i');
    }
  }

  @override
  void registerLazySingletons(int count) {
    final box = DependencyBox.main();
    for (var i = 0; i < count; i++) {
      box.addLazySingleton<SingleService>(
        (_) => SingleService(),
        key: 'lazy_$i',
      );
    }
  }

  @override
  void registerFactories(int count) {
    final box = DependencyBox.main();
    for (var i = 0; i < count; i++) {
      box.addFactory<SingleService>((_) => SingleService(), key: 'factory_$i');
    }
  }

  @override
  void registerInterfaceMapping() {
    final box = DependencyBox.main();
    box.addSingleton<IService>(ServiceImpl());
  }

  @override
  void registerKeyedNamed() {
    final box = DependencyBox.main();
    box.addSingleton<KeyedService>(KeyedService('primary'), key: 'primary');
    box.addSingleton<KeyedService>(KeyedService('secondary'), key: 'secondary');
  }

  @override
  void registerParameterized() {
    final box = DependencyBox.main();
    box.addFactoryWith<ParameterizedService, (String, int)>(
      (_, args) => ParameterizedService(args.$1, args.$2),
    );
  }

  @override
  void registerAsyncSingleton() {
    final box = DependencyBox.main();
    box.addAsyncSingleton<AsyncDatabaseService>(
      (_) => AsyncDatabaseService.create('postgres://localhost:5432'),
    );
  }

  @override
  void registerRealisticGraph() {
    final box = DependencyBox.main();
    box.addSingleton<AppConfig>(AppConfig());
    box.addSingleton<TokenStorage>(TokenStorage());
    box.addSingleton<AnalyticsTracker>(AnalyticsTracker());
    box.addLazySingleton<NetworkClient>(
      (b) => NetworkClient(b.get<AppConfig>(), b.get<TokenStorage>()),
    );
    box.addLazySingleton<DatabaseConnection>(
      (b) => DatabaseConnection(b.get<AppConfig>()),
    );
    box.addLazySingleton<AuthRepository>(
      (b) => AuthRepository(b.get<NetworkClient>(), b.get<TokenStorage>()),
    );
    box.addLazySingleton<UserRepository>(
      (b) => UserRepository(
        b.get<DatabaseConnection>(),
        b.get<NetworkClient>(),
        b.get<AuthRepository>(),
      ),
    );
    box.addFactory<LoginUseCase>(
      (b) => LoginUseCase(b.get<AuthRepository>(), b.get<AnalyticsTracker>()),
    );
    box.addFactory<GetUserProfileUseCase>(
      (b) => GetUserProfileUseCase(
        b.get<UserRepository>(),
        b.get<AnalyticsTracker>(),
      ),
    );
    box.addFactory<UserProfileViewModel>(
      (b) => UserProfileViewModel(
        b.get<GetUserProfileUseCase>(),
        b.get<AnalyticsTracker>(),
      ),
    );
  }

  @override
  void registerDeepChain() {
    final box = DependencyBox.main();
    box.addFactory<ChainNode0>((_) => ChainNode0());
    box.addFactory<ChainNode1>((b) => ChainNode1(b.get<ChainNode0>()));
    box.addFactory<ChainNode2>((b) => ChainNode2(b.get<ChainNode1>()));
    box.addFactory<ChainNode3>((b) => ChainNode3(b.get<ChainNode2>()));
    box.addFactory<ChainNode4>((b) => ChainNode4(b.get<ChainNode3>()));
    box.addFactory<ChainNode5>((b) => ChainNode5(b.get<ChainNode4>()));
    box.addFactory<ChainNode6>((b) => ChainNode6(b.get<ChainNode5>()));
    box.addFactory<ChainNode7>((b) => ChainNode7(b.get<ChainNode6>()));
    box.addFactory<ChainNode8>((b) => ChainNode8(b.get<ChainNode7>()));
    box.addFactory<ChainNode9>((b) => ChainNode9(b.get<ChainNode8>()));
    box.addFactory<ChainRoot>((b) => ChainRoot(b.get<ChainNode9>()));
  }

  // --- Resolution Setups & Workloads ---

  @override
  void setupSingletonResolution() {
    _box = DependencyBox.main();
    _box.addSingleton<SingleService>(SingleService());
  }

  @override
  Object resolveSingleton() => _box.get<SingleService>();

  @override
  void setupLazySingletonResolution() {
    _box = DependencyBox.main();
    _box.addLazySingleton<SingleService>((_) => SingleService());
  }

  @override
  Object resolveLazySingleton() => _box.get<SingleService>();

  @override
  void setupFactoryResolution() {
    _box = DependencyBox.main();
    _box.addFactory<SingleService>((_) => SingleService());
  }

  @override
  Object resolveFactory() => _box.get<SingleService>();

  @override
  void setupInterfaceResolution() {
    _box = DependencyBox.main();
    _box.addSingleton<IService>(ServiceImpl());
  }

  @override
  Object resolveInterface() => _box.get<IService>();

  @override
  void setupKeyedNamedResolution() {
    _box = DependencyBox.main();
    _box.addSingleton<KeyedService>(KeyedService('primary'), key: 'primary');
  }

  @override
  Object resolveKeyedNamed() => _box.get<KeyedService>(key: 'primary');

  @override
  void setupParameterizedResolution() {
    _box = DependencyBox.main();
    _box.addFactoryWith<ParameterizedService, (String, int)>(
      (_, args) => ParameterizedService(args.$1, args.$2),
    );
  }

  @override
  Object resolveParameterized() =>
      _box.get<ParameterizedService>(args: ('tenant_benchmark', 42));

  @override
  void setupShallowGraphResolution() {
    _box = DependencyBox.main();
    _box.addFactory<ShallowDepA>((_) => ShallowDepA());
    _box.addFactory<ShallowDepB>((_) => ShallowDepB());
    _box.addFactory<ShallowDepC>((_) => ShallowDepC());
    _box.addFactory<ShallowDepD>((_) => ShallowDepD());
    _box.addFactory<ShallowRoot>(
      (b) => ShallowRoot(
        b.get<ShallowDepA>(),
        b.get<ShallowDepB>(),
        b.get<ShallowDepC>(),
        b.get<ShallowDepD>(),
      ),
    );
  }

  @override
  Object resolveShallowGraph() => _box.get<ShallowRoot>();

  @override
  void setupDeepChainResolution() {
    _box = DependencyBox.main();
    _box.addFactory<ChainNode0>((_) => ChainNode0());
    _box.addFactory<ChainNode1>((b) => ChainNode1(b.get<ChainNode0>()));
    _box.addFactory<ChainNode2>((b) => ChainNode2(b.get<ChainNode1>()));
    _box.addFactory<ChainNode3>((b) => ChainNode3(b.get<ChainNode2>()));
    _box.addFactory<ChainNode4>((b) => ChainNode4(b.get<ChainNode3>()));
    _box.addFactory<ChainNode5>((b) => ChainNode5(b.get<ChainNode4>()));
    _box.addFactory<ChainNode6>((b) => ChainNode6(b.get<ChainNode5>()));
    _box.addFactory<ChainNode7>((b) => ChainNode7(b.get<ChainNode6>()));
    _box.addFactory<ChainNode8>((b) => ChainNode8(b.get<ChainNode7>()));
    _box.addFactory<ChainNode9>((b) => ChainNode9(b.get<ChainNode8>()));
    _box.addFactory<ChainRoot>((b) => ChainRoot(b.get<ChainNode9>()));
  }

  @override
  Object resolveDeepChain() => _box.get<ChainRoot>();

  @override
  void setupSharedGraphResolution() {
    _box = DependencyBox.main();
    _box.addSingleton<SharedCoreA>(SharedCoreA());
    _box.addSingleton<SharedCoreB>(SharedCoreB());
    _box.addFactory<SharedMidA>(
      (b) => SharedMidA(b.get<SharedCoreA>(), b.get<SharedCoreB>()),
    );
    _box.addFactory<SharedMidB>(
      (b) => SharedMidB(b.get<SharedCoreA>(), b.get<SharedCoreB>()),
    );
    _box.addFactory<SharedRoot1>(
      (b) => SharedRoot1(b.get<SharedMidA>(), b.get<SharedMidB>()),
    );
    _box.addFactory<SharedRoot2>(
      (b) => SharedRoot2(b.get<SharedMidA>(), b.get<SharedCoreA>()),
    );
  }

  @override
  Object resolveSharedGraph() => _box.get<SharedRoot1>();

  @override
  void setupRealisticGraphResolution() {
    _box = DependencyBox.main();
    _box.addSingleton<AppConfig>(AppConfig());
    _box.addSingleton<TokenStorage>(TokenStorage());
    _box.addSingleton<AnalyticsTracker>(AnalyticsTracker());
    _box.addLazySingleton<NetworkClient>(
      (b) => NetworkClient(b.get<AppConfig>(), b.get<TokenStorage>()),
    );
    _box.addLazySingleton<DatabaseConnection>(
      (b) => DatabaseConnection(b.get<AppConfig>()),
    );
    _box.addLazySingleton<AuthRepository>(
      (b) => AuthRepository(b.get<NetworkClient>(), b.get<TokenStorage>()),
    );
    _box.addLazySingleton<UserRepository>(
      (b) => UserRepository(
        b.get<DatabaseConnection>(),
        b.get<NetworkClient>(),
        b.get<AuthRepository>(),
      ),
    );
    _box.addFactory<LoginUseCase>(
      (b) => LoginUseCase(b.get<AuthRepository>(), b.get<AnalyticsTracker>()),
    );
    _box.addFactory<GetUserProfileUseCase>(
      (b) => GetUserProfileUseCase(
        b.get<UserRepository>(),
        b.get<AnalyticsTracker>(),
      ),
    );
    _box.addFactory<UserProfileViewModel>(
      (b) => UserProfileViewModel(
        b.get<GetUserProfileUseCase>(),
        b.get<AnalyticsTracker>(),
      ),
    );
  }

  @override
  Object resolveRealisticGraph() => _box.get<UserProfileViewModel>();

  @override
  void setupAsyncResolution() {
    _box = DependencyBox.main();
    _box.addAsyncSingleton<AsyncDatabaseService>(
      (_) => AsyncDatabaseService.create('postgres://localhost:5432'),
    );
  }

  @override
  Future<Object> resolveAsync() => _box.getAsync<AsyncDatabaseService>();

  @override
  Object? resolveMissing() => _box.tryGet<NonExistentType>();

  // --- Scope & Lifecycle ---

  @override
  void setupScopeBenchmark() {
    _box = DependencyBox.main(name: 'root');
    _box.addSingleton<AppConfig>(AppConfig());
    _scopeCounter = 0;
  }

  @override
  void pushScope() {
    _scopeCounter++;
    _activeChild = _box.createChild(name: 'session_$_scopeCounter');
    _activeChild!.addFactory<SingleService>((_) => SingleService());
  }

  @override
  Object resolveScoped() {
    final active = _activeChild ?? _box;
    return active.get<SingleService>();
  }

  @override
  Future<void> popScope() async {
    if (_activeChild != null) {
      await _activeChild!.dispose();
      _activeChild = null;
    }
  }

  @override
  void setupCachedFactoryResolution() {
    _box = DependencyBox.main();
    _box.addCachedFactory<SingleService>((_) => SingleService());
  }

  @override
  Object resolveCachedFactory() => _box.get<SingleService>();
}
