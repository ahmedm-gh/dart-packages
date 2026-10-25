import 'dart:async';
import 'package:get_it/get_it.dart';
import '../models/fixtures.dart';
import 'adapter.dart';

/// Adapter implementation for [GetIt] version 9.3.0.
class GetItAdapter extends BenchmarkAdapter {
  GetIt _getIt = GetIt.asNewInstance();
  int _scopeCounter = 0;

  @override
  String get name => 'get_it';

  @override
  String get version => '9.3.0';

  @override
  Set<DiCapability> get capabilities => {
        DiCapability.singleton,
        DiCapability.lazySingleton,
        DiCapability.factory,
        DiCapability.cachedWeakReferenceFactory,
        DiCapability.interfaceMapping,
        DiCapability.keyedNamedRegistration,
        DiCapability.parameterizedFactory,
        DiCapability.asyncSingleton,
        DiCapability.stackBasedScopes,
        DiCapability.targetedRemoval,
        DiCapability.testOverrideReplacement,
      };

  @override
  void reset() {
    _getIt = GetIt.asNewInstance();
    _scopeCounter = 0;
  }

  // --- Registration Workloads ---

  @override
  void registerSingletons(int count) {
    final getIt = GetIt.asNewInstance();
    for (var i = 0; i < count; i++) {
      getIt.registerSingleton<SingleService>(
        SingleService(),
        instanceName: 'singleton_$i',
      );
    }
  }

  @override
  void registerLazySingletons(int count) {
    final getIt = GetIt.asNewInstance();
    for (var i = 0; i < count; i++) {
      getIt.registerLazySingleton<SingleService>(
        () => SingleService(),
        instanceName: 'lazy_$i',
      );
    }
  }

  @override
  void registerFactories(int count) {
    final getIt = GetIt.asNewInstance();
    for (var i = 0; i < count; i++) {
      getIt.registerFactory<SingleService>(
        () => SingleService(),
        instanceName: 'factory_$i',
      );
    }
  }

  @override
  void registerInterfaceMapping() {
    final getIt = GetIt.asNewInstance();
    getIt.registerSingleton<IService>(ServiceImpl());
  }

  @override
  void registerKeyedNamed() {
    final getIt = GetIt.asNewInstance();
    getIt.registerSingleton<KeyedService>(
      KeyedService('primary'),
      instanceName: 'primary',
    );
    getIt.registerSingleton<KeyedService>(
      KeyedService('secondary'),
      instanceName: 'secondary',
    );
  }

  @override
  void registerParameterized() {
    final getIt = GetIt.asNewInstance();
    getIt.registerFactoryParam<ParameterizedService, String, int>(
      (tenant, partition) => ParameterizedService(tenant, partition),
    );
  }

  @override
  void registerAsyncSingleton() {
    final getIt = GetIt.asNewInstance();
    getIt.registerSingletonAsync<AsyncDatabaseService>(
      () => AsyncDatabaseService.create('postgres://localhost:5432'),
    );
  }

  @override
  void registerRealisticGraph() {
    final getIt = GetIt.asNewInstance();
    getIt.registerSingleton<AppConfig>(AppConfig());
    getIt.registerSingleton<TokenStorage>(TokenStorage());
    getIt.registerSingleton<AnalyticsTracker>(AnalyticsTracker());
    getIt.registerLazySingleton<NetworkClient>(
      () => NetworkClient(getIt<AppConfig>(), getIt<TokenStorage>()),
    );
    getIt.registerLazySingleton<DatabaseConnection>(
      () => DatabaseConnection(getIt<AppConfig>()),
    );
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepository(getIt<NetworkClient>(), getIt<TokenStorage>()),
    );
    getIt.registerLazySingleton<UserRepository>(
      () => UserRepository(
        getIt<DatabaseConnection>(),
        getIt<NetworkClient>(),
        getIt<AuthRepository>(),
      ),
    );
    getIt.registerFactory<LoginUseCase>(
      () => LoginUseCase(getIt<AuthRepository>(), getIt<AnalyticsTracker>()),
    );
    getIt.registerFactory<GetUserProfileUseCase>(
      () => GetUserProfileUseCase(
        getIt<UserRepository>(),
        getIt<AnalyticsTracker>(),
      ),
    );
    getIt.registerFactory<UserProfileViewModel>(
      () => UserProfileViewModel(
        getIt<GetUserProfileUseCase>(),
        getIt<AnalyticsTracker>(),
      ),
    );
  }

  @override
  void registerDeepChain() {
    final getIt = GetIt.asNewInstance();
    getIt.registerFactory<ChainNode0>(() => ChainNode0());
    getIt.registerFactory<ChainNode1>(() => ChainNode1(getIt<ChainNode0>()));
    getIt.registerFactory<ChainNode2>(() => ChainNode2(getIt<ChainNode1>()));
    getIt.registerFactory<ChainNode3>(() => ChainNode3(getIt<ChainNode2>()));
    getIt.registerFactory<ChainNode4>(() => ChainNode4(getIt<ChainNode3>()));
    getIt.registerFactory<ChainNode5>(() => ChainNode5(getIt<ChainNode4>()));
    getIt.registerFactory<ChainNode6>(() => ChainNode6(getIt<ChainNode5>()));
    getIt.registerFactory<ChainNode7>(() => ChainNode7(getIt<ChainNode6>()));
    getIt.registerFactory<ChainNode8>(() => ChainNode8(getIt<ChainNode7>()));
    getIt.registerFactory<ChainNode9>(() => ChainNode9(getIt<ChainNode8>()));
    getIt.registerFactory<ChainRoot>(() => ChainRoot(getIt<ChainNode9>()));
  }

  // --- Resolution Setups & Workloads ---

  @override
  void setupSingletonResolution() {
    _getIt = GetIt.asNewInstance();
    _getIt.registerSingleton<SingleService>(SingleService());
  }

  @override
  Object resolveSingleton() => _getIt.get<SingleService>();

  @override
  void setupLazySingletonResolution() {
    _getIt = GetIt.asNewInstance();
    _getIt.registerLazySingleton<SingleService>(() => SingleService());
  }

  @override
  Object resolveLazySingleton() => _getIt.get<SingleService>();

  @override
  void setupFactoryResolution() {
    _getIt = GetIt.asNewInstance();
    _getIt.registerFactory<SingleService>(() => SingleService());
  }

  @override
  Object resolveFactory() => _getIt.get<SingleService>();

  @override
  void setupInterfaceResolution() {
    _getIt = GetIt.asNewInstance();
    _getIt.registerSingleton<IService>(ServiceImpl());
  }

  @override
  Object resolveInterface() => _getIt.get<IService>();

  @override
  void setupKeyedNamedResolution() {
    _getIt = GetIt.asNewInstance();
    _getIt.registerSingleton<KeyedService>(
      KeyedService('primary'),
      instanceName: 'primary',
    );
  }

  @override
  Object resolveKeyedNamed() =>
      _getIt.get<KeyedService>(instanceName: 'primary');

  @override
  void setupParameterizedResolution() {
    _getIt = GetIt.asNewInstance();
    _getIt.registerFactoryParam<ParameterizedService, String, int>(
      (tenant, partition) => ParameterizedService(tenant, partition),
    );
  }

  @override
  Object resolveParameterized() => _getIt.get<ParameterizedService>(
        param1: 'tenant_benchmark',
        param2: 42,
      );

  @override
  void setupShallowGraphResolution() {
    _getIt = GetIt.asNewInstance();
    _getIt.registerFactory<ShallowDepA>(() => ShallowDepA());
    _getIt.registerFactory<ShallowDepB>(() => ShallowDepB());
    _getIt.registerFactory<ShallowDepC>(() => ShallowDepC());
    _getIt.registerFactory<ShallowDepD>(() => ShallowDepD());
    _getIt.registerFactory<ShallowRoot>(
      () => ShallowRoot(
        _getIt<ShallowDepA>(),
        _getIt<ShallowDepB>(),
        _getIt<ShallowDepC>(),
        _getIt<ShallowDepD>(),
      ),
    );
  }

  @override
  Object resolveShallowGraph() => _getIt.get<ShallowRoot>();

  @override
  void setupDeepChainResolution() {
    _getIt = GetIt.asNewInstance();
    _getIt.registerFactory<ChainNode0>(() => ChainNode0());
    _getIt.registerFactory<ChainNode1>(() => ChainNode1(_getIt<ChainNode0>()));
    _getIt.registerFactory<ChainNode2>(() => ChainNode2(_getIt<ChainNode1>()));
    _getIt.registerFactory<ChainNode3>(() => ChainNode3(_getIt<ChainNode2>()));
    _getIt.registerFactory<ChainNode4>(() => ChainNode4(_getIt<ChainNode3>()));
    _getIt.registerFactory<ChainNode5>(() => ChainNode5(_getIt<ChainNode4>()));
    _getIt.registerFactory<ChainNode6>(() => ChainNode6(_getIt<ChainNode5>()));
    _getIt.registerFactory<ChainNode7>(() => ChainNode7(_getIt<ChainNode6>()));
    _getIt.registerFactory<ChainNode8>(() => ChainNode8(_getIt<ChainNode7>()));
    _getIt.registerFactory<ChainNode9>(() => ChainNode9(_getIt<ChainNode8>()));
    _getIt.registerFactory<ChainRoot>(() => ChainRoot(_getIt<ChainNode9>()));
  }

  @override
  Object resolveDeepChain() => _getIt.get<ChainRoot>();

  @override
  void setupSharedGraphResolution() {
    _getIt = GetIt.asNewInstance();
    _getIt.registerSingleton<SharedCoreA>(SharedCoreA());
    _getIt.registerSingleton<SharedCoreB>(SharedCoreB());
    _getIt.registerFactory<SharedMidA>(
      () => SharedMidA(_getIt<SharedCoreA>(), _getIt<SharedCoreB>()),
    );
    _getIt.registerFactory<SharedMidB>(
      () => SharedMidB(_getIt<SharedCoreA>(), _getIt<SharedCoreB>()),
    );
    _getIt.registerFactory<SharedRoot1>(
      () => SharedRoot1(_getIt<SharedMidA>(), _getIt<SharedMidB>()),
    );
    _getIt.registerFactory<SharedRoot2>(
      () => SharedRoot2(_getIt<SharedMidA>(), _getIt<SharedCoreA>()),
    );
  }

  @override
  Object resolveSharedGraph() => _getIt.get<SharedRoot1>();

  @override
  void setupRealisticGraphResolution() {
    _getIt = GetIt.asNewInstance();
    _getIt.registerSingleton<AppConfig>(AppConfig());
    _getIt.registerSingleton<TokenStorage>(TokenStorage());
    _getIt.registerSingleton<AnalyticsTracker>(AnalyticsTracker());
    _getIt.registerLazySingleton<NetworkClient>(
      () => NetworkClient(_getIt<AppConfig>(), _getIt<TokenStorage>()),
    );
    _getIt.registerLazySingleton<DatabaseConnection>(
      () => DatabaseConnection(_getIt<AppConfig>()),
    );
    _getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepository(_getIt<NetworkClient>(), _getIt<TokenStorage>()),
    );
    _getIt.registerLazySingleton<UserRepository>(
      () => UserRepository(
        _getIt<DatabaseConnection>(),
        _getIt<NetworkClient>(),
        _getIt<AuthRepository>(),
      ),
    );
    _getIt.registerFactory<LoginUseCase>(
      () => LoginUseCase(_getIt<AuthRepository>(), _getIt<AnalyticsTracker>()),
    );
    _getIt.registerFactory<GetUserProfileUseCase>(
      () => GetUserProfileUseCase(
        _getIt<UserRepository>(),
        _getIt<AnalyticsTracker>(),
      ),
    );
    _getIt.registerFactory<UserProfileViewModel>(
      () => UserProfileViewModel(
        _getIt<GetUserProfileUseCase>(),
        _getIt<AnalyticsTracker>(),
      ),
    );
  }

  @override
  Object resolveRealisticGraph() => _getIt.get<UserProfileViewModel>();

  @override
  void setupAsyncResolution() {
    _getIt = GetIt.asNewInstance();
    _getIt.registerSingletonAsync<AsyncDatabaseService>(
      () => AsyncDatabaseService.create('postgres://localhost:5432'),
    );
  }

  @override
  Future<Object> resolveAsync() => _getIt.getAsync<AsyncDatabaseService>();

  @override
  Object? resolveMissing() => _getIt.maybeGet<NonExistentType>();

  // --- Scope & Lifecycle ---

  @override
  void setupScopeBenchmark() {
    _getIt = GetIt.asNewInstance();
    _getIt.registerSingleton<AppConfig>(AppConfig());
    _scopeCounter = 0;
  }

  @override
  void pushScope() {
    _scopeCounter++;
    _getIt.pushNewScope(
      scopeName: 'session_$_scopeCounter',
      init: (getIt) {
        getIt.registerFactory<SingleService>(() => SingleService());
      },
    );
  }

  @override
  Object resolveScoped() => _getIt.get<SingleService>();

  @override
  Future<void> popScope() => _getIt.popScope();

  @override
  void setupCachedFactoryResolution() {
    _getIt = GetIt.asNewInstance();
    _getIt.registerCachedFactory<SingleService>(() => SingleService());
  }

  @override
  Object resolveCachedFactory() => _getIt.get<SingleService>();
}
