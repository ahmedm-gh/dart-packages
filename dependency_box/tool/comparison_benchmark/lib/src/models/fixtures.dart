/// Shared domain models and dependency graph fixtures for the benchmark suite.
library;

// ============================================================================
// 1. Minimal Graph: Single Service
// ============================================================================

class SingleService {
  static int instanceCounter = 0;
  final int id;
  SingleService() : id = ++instanceCounter;
}

abstract interface class IService {
  String get name;
}

class ServiceImpl implements IService {
  static int instanceCounter = 0;
  final int id;
  ServiceImpl() : id = ++instanceCounter;

  @override
  String get name => 'ServiceImpl-$id';
}

// ============================================================================
// 2. Shallow Graph: Root with multiple direct dependencies
// ============================================================================

class ShallowDepA {
  static int instanceCounter = 0;
  final int id = ++instanceCounter;
}

class ShallowDepB {
  static int instanceCounter = 0;
  final int id = ++instanceCounter;
}

class ShallowDepC {
  static int instanceCounter = 0;
  final int id = ++instanceCounter;
}

class ShallowDepD {
  static int instanceCounter = 0;
  final int id = ++instanceCounter;
}

class ShallowRoot {
  static int instanceCounter = 0;
  final int id = ++instanceCounter;
  final ShallowDepA a;
  final ShallowDepB b;
  final ShallowDepC c;
  final ShallowDepD d;

  ShallowRoot(this.a, this.b, this.c, this.d);
}

// ============================================================================
// 3. Deep Graph: Long linear chain of 10 dependencies
// ============================================================================

class ChainNode0 {
  static int instanceCounter = 0;
  final int id = ++instanceCounter;
}

class ChainNode1 {
  final ChainNode0 dep;
  ChainNode1(this.dep);
}

class ChainNode2 {
  final ChainNode1 dep;
  ChainNode2(this.dep);
}

class ChainNode3 {
  final ChainNode2 dep;
  ChainNode3(this.dep);
}

class ChainNode4 {
  final ChainNode3 dep;
  ChainNode4(this.dep);
}

class ChainNode5 {
  final ChainNode4 dep;
  ChainNode5(this.dep);
}

class ChainNode6 {
  final ChainNode5 dep;
  ChainNode6(this.dep);
}

class ChainNode7 {
  final ChainNode6 dep;
  ChainNode7(this.dep);
}

class ChainNode8 {
  final ChainNode7 dep;
  ChainNode8(this.dep);
}

class ChainNode9 {
  final ChainNode8 dep;
  ChainNode9(this.dep);
}

class ChainRoot {
  static int instanceCounter = 0;
  final int id = ++instanceCounter;
  final ChainNode9 dep;
  ChainRoot(this.dep);
}

// ============================================================================
// 4. Shared Graph: Multiple roots depending on common shared nodes
// ============================================================================

class SharedCoreA {
  static int instanceCounter = 0;
  final int id = ++instanceCounter;
}

class SharedCoreB {
  static int instanceCounter = 0;
  final int id = ++instanceCounter;
}

class SharedMidA {
  final SharedCoreA coreA;
  final SharedCoreB coreB;
  SharedMidA(this.coreA, this.coreB);
}

class SharedMidB {
  final SharedCoreA coreA;
  final SharedCoreB coreB;
  SharedMidB(this.coreA, this.coreB);
}

class SharedRoot1 {
  final SharedMidA midA;
  final SharedMidB midB;
  SharedRoot1(this.midA, this.midB);
}

class SharedRoot2 {
  final SharedMidA midA;
  final SharedCoreA coreA;
  SharedRoot2(this.midA, this.coreA);
}

// ============================================================================
// 5. Mixed Graph: Singleton, Lazy Singleton, and Factory Registrations
// ============================================================================

class MixedConfig {
  static int instanceCounter = 0;
  final int id = ++instanceCounter;
  final String host = '127.0.0.1';
}

class MixedDatabase {
  static int instanceCounter = 0;
  final int id = ++instanceCounter;
  final MixedConfig config;
  MixedDatabase(this.config);
}

class MixedQueryWorker {
  static int instanceCounter = 0;
  final int id = ++instanceCounter;
  final MixedDatabase db;
  MixedQueryWorker(this.db);
}

// ============================================================================
// 6. Realistic Application Graph (Enterprise Simulation)
// ============================================================================

class AppConfig {
  final String environment = 'production';
  final String apiUrl = 'https://api.benchmark.internal';
}

class TokenStorage {
  String token = 'jwt-token-sample';
}

class NetworkClient {
  final AppConfig config;
  final TokenStorage tokenStorage;
  NetworkClient(this.config, this.tokenStorage);
}

class DatabaseConnection {
  final AppConfig config;
  DatabaseConnection(this.config);
}

class AnalyticsTracker {
  int eventCount = 0;
  void track(String event) {
    eventCount++;
  }
}

class AuthRepository {
  final NetworkClient client;
  final TokenStorage tokenStorage;
  AuthRepository(this.client, this.tokenStorage);
}

class UserRepository {
  final DatabaseConnection db;
  final NetworkClient client;
  final AuthRepository authRepo;
  UserRepository(this.db, this.client, this.authRepo);
}

class LoginUseCase {
  final AuthRepository authRepo;
  final AnalyticsTracker tracker;
  LoginUseCase(this.authRepo, this.tracker);
}

class GetUserProfileUseCase {
  final UserRepository userRepo;
  final AnalyticsTracker tracker;
  GetUserProfileUseCase(this.userRepo, this.tracker);
}

class UserProfileViewModel {
  static int instanceCounter = 0;
  final int id = ++instanceCounter;
  final GetUserProfileUseCase getUserProfile;
  final AnalyticsTracker tracker;
  UserProfileViewModel(this.getUserProfile, this.tracker);
}

// ============================================================================
// 7. Parameterized and Keyed Fixtures
// ============================================================================

class ParameterizedService {
  final String tenantId;
  final int partition;
  ParameterizedService(this.tenantId, this.partition);
}

class KeyedService {
  final String tag;
  KeyedService(this.tag);
}

// ============================================================================
// 8. Lifecycle & Async Fixtures
// ============================================================================

class AsyncDatabaseService {
  final String connectionString;
  bool isConnected = false;

  AsyncDatabaseService(this.connectionString);

  static Future<AsyncDatabaseService> create(String conn) async {
    final service = AsyncDatabaseService(conn);
    service.isConnected = true;
    return service;
  }
}

class DisposableService {
  bool disposed = false;
  void dispose() {
    disposed = true;
  }
}

class NonExistentType {}

// Helper to reset counters for deterministic validation
void resetFixtureCounters() {
  SingleService.instanceCounter = 0;
  ServiceImpl.instanceCounter = 0;
  ShallowDepA.instanceCounter = 0;
  ShallowDepB.instanceCounter = 0;
  ShallowDepC.instanceCounter = 0;
  ShallowDepD.instanceCounter = 0;
  ShallowRoot.instanceCounter = 0;
  ChainNode0.instanceCounter = 0;
  ChainRoot.instanceCounter = 0;
  SharedCoreA.instanceCounter = 0;
  SharedCoreB.instanceCounter = 0;
  MixedConfig.instanceCounter = 0;
  MixedDatabase.instanceCounter = 0;
  MixedQueryWorker.instanceCounter = 0;
  UserProfileViewModel.instanceCounter = 0;
}
