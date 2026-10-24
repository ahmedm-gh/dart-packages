import 'dart:io';
import 'package:dependency_box/dependency_box.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

// ============================================================================
// Real-world Enterprise / Clean Architecture Models
// ============================================================================

abstract class HttpInterceptor {
  String process(String url);
}

class AuthHeaderInterceptor implements HttpInterceptor {
  @override
  String process(String url) {
    return 'auth:$url';
  }
}

class CompressionInterceptor implements HttpInterceptor {
  @override
  String process(String url) {
    return 'gzip:$url';
  }
}

class RateLimitInterceptor implements HttpInterceptor {
  @override
  String process(String url) {
    return 'rate:$url';
  }
}

class LoggingInterceptor implements HttpInterceptor {
  @override
  String process(String url) {
    return 'log:$url';
  }
}

class RetryInterceptor implements HttpInterceptor {
  @override
  String process(String url) {
    return 'retry:$url';
  }
}

class TelemetryInterceptor implements HttpInterceptor {
  @override
  String process(String url) {
    return 'telemetry:$url';
  }
}

class AppConfig {
  final String env;
  final String apiBaseUrl;
  AppConfig(
      {this.env = 'production', this.apiBaseUrl = 'https://api.store.com'});
}

class SecureTokenStorage {
  String? token = 'jwt_secret_token_abc123';
}

class TelemetryLogger {
  void log(String event) {}
}

class ApiClient {
  final AppConfig config;
  final SecureTokenStorage tokenStorage;
  final TelemetryLogger logger;

  ApiClient(this.config, this.tokenStorage, this.logger);
}

class LocalDatabase {
  final String path;
  LocalDatabase({this.path = '/data/app.db'});
}

class UserRemoteDataSource {
  final ApiClient client;
  UserRemoteDataSource(this.client);
}

class UserLocalDataSource {
  final LocalDatabase db;
  UserLocalDataSource(this.db);
}

class ProductRemoteDataSource {
  final ApiClient client;
  ProductRemoteDataSource(this.client);
}

class ProductLocalDataSource {
  final LocalDatabase db;
  ProductLocalDataSource(this.db);
}

class OrderRemoteDataSource {
  final ApiClient client;
  OrderRemoteDataSource(this.client);
}

class UserRepository {
  final UserRemoteDataSource remote;
  final UserLocalDataSource local;
  final TelemetryLogger logger;
  UserRepository(this.remote, this.local, this.logger);
}

class ProductRepository {
  final ProductRemoteDataSource remote;
  final ProductLocalDataSource local;
  ProductRepository(this.remote, this.local);
}

class OrderRepository {
  final OrderRemoteDataSource remote;
  final TelemetryLogger logger;
  OrderRepository(this.remote, this.logger);
}

class SessionManager {
  final SecureTokenStorage tokenStorage;
  final UserRepository userRepo;
  SessionManager(this.tokenStorage, this.userRepo);
}

class AuthenticateUserUseCase {
  final UserRepository userRepo;
  final SessionManager sessionManager;
  final TelemetryLogger logger;
  AuthenticateUserUseCase(this.userRepo, this.sessionManager, this.logger);
}

class LoadCatalogUseCase {
  final ProductRepository productRepo;
  final TelemetryLogger logger;
  LoadCatalogUseCase(this.productRepo, this.logger);
}

class ProcessCheckoutUseCase {
  final UserRepository userRepo;
  final OrderRepository orderRepo;
  final SessionManager sessionManager;
  final TelemetryLogger logger;
  ProcessCheckoutUseCase(
      this.userRepo, this.orderRepo, this.sessionManager, this.logger);
}

class DynamicQueryEngine {
  final String query;
  DynamicQueryEngine(this.query);
}

// Feature Controllers (Instantiated per screen / navigation)
class LoginScreenController {
  final AuthenticateUserUseCase authUseCase;
  final TelemetryLogger logger;
  LoginScreenController(this.authUseCase, this.logger);
}

class CatalogScreenController {
  final LoadCatalogUseCase catalogUseCase;
  final TelemetryLogger logger;
  CatalogScreenController(this.catalogUseCase, this.logger);
}

class CheckoutScreenController {
  final ProcessCheckoutUseCase checkoutUseCase;
  final AuthenticateUserUseCase authUseCase;
  final TelemetryLogger logger;
  CheckoutScreenController(this.checkoutUseCase, this.authUseCase, this.logger);
}

class UserProfileController {
  final UserRepository userRepo;
  final SessionManager sessionManager;
  final TelemetryLogger logger;
  UserProfileController(this.userRepo, this.sessionManager, this.logger);
}

// Scoped Feature Classes (Multi-step checkout wizard)
class ScopedPaymentSession {
  final String sessionId;
  ScopedPaymentSession(this.sessionId);
}

class ScopedCartState {
  final int itemCount;
  ScopedCartState(this.itemCount);
}

class ScopedBillingValidator {
  bool validate() {
    return true;
  }
}

class ScopedPaymentGateway {
  final ScopedPaymentSession session;
  final ScopedBillingValidator validator;
  ScopedPaymentGateway(this.session, this.validator);
}

class ScopedCheckoutWizardController {
  final ScopedPaymentGateway gateway;
  final ScopedCartState cart;
  ScopedCheckoutWizardController(this.gateway, this.cart);
}

// ============================================================================
// Timing Harness
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

  double get microsPerOp {
    return elapsedMicros / operations;
  }
}

BenchmarkScore runTimed(int iterations, void Function() fn) {
  // Warmup phase (ensure JIT optimization / branch prediction)
  for (var i = 0; i < 30000; i++) {
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
      '=========================================================================================');
  stdout.writeln(
      '  REAL-WORLD SCENARIOS BENCHMARK: dependency_box vs get_it 9.3.0 vs injectable 3.0.0');
  stdout.writeln(
      '  Dart SDK: ${Platform.version.split(' ').first} (${Platform.operatingSystem})');
  stdout.writeln(
      '=========================================================================================\n');

  // ===========================================================================
  // SCENARIO 1: Clean Architecture Screen Navigation & ViewModel Resolution
  // Every time a user navigates to a screen, the DI container resolves a Factory
  // Controller that depends on multiple UseCases, Repositories, and Services.
  // ===========================================================================
  stdout.write(
      'Running Scenario 1/5: Screen Navigation & ViewModel Graph Resolution (2M ops)... ');
  const screenNavOps = 2000000;

  // 1. Setup DependencyBox Container
  final box1 = DependencyBox.main();
  box1.addSingleton<AppConfig>(AppConfig());
  box1.addSingleton<SecureTokenStorage>(SecureTokenStorage());
  box1.addSingleton<TelemetryLogger>(TelemetryLogger());
  box1.addSingleton<LocalDatabase>(LocalDatabase());
  box1.addLazySingleton<ApiClient>((c) {
    return ApiClient(c.get<AppConfig>(), c.get<SecureTokenStorage>(),
        c.get<TelemetryLogger>());
  });
  box1.addLazySingleton<UserRemoteDataSource>((c) {
    return UserRemoteDataSource(c.get<ApiClient>());
  });
  box1.addLazySingleton<UserLocalDataSource>((c) {
    return UserLocalDataSource(c.get<LocalDatabase>());
  });
  box1.addLazySingleton<OrderRemoteDataSource>((c) {
    return OrderRemoteDataSource(c.get<ApiClient>());
  });
  box1.addLazySingleton<UserRepository>((c) {
    return UserRepository(c.get<UserRemoteDataSource>(),
        c.get<UserLocalDataSource>(), c.get<TelemetryLogger>());
  });
  box1.addLazySingleton<OrderRepository>((c) {
    return OrderRepository(
        c.get<OrderRemoteDataSource>(), c.get<TelemetryLogger>());
  });
  box1.addLazySingleton<SessionManager>((c) {
    return SessionManager(c.get<SecureTokenStorage>(), c.get<UserRepository>());
  });
  box1.addLazySingleton<AuthenticateUserUseCase>((c) {
    return AuthenticateUserUseCase(c.get<UserRepository>(),
        c.get<SessionManager>(), c.get<TelemetryLogger>());
  });
  box1.addLazySingleton<ProcessCheckoutUseCase>((c) {
    return ProcessCheckoutUseCase(
        c.get<UserRepository>(),
        c.get<OrderRepository>(),
        c.get<SessionManager>(),
        c.get<TelemetryLogger>());
  });
  box1.addFactory<CheckoutScreenController>((c) {
    return CheckoutScreenController(
      c.get<ProcessCheckoutUseCase>(),
      c.get<AuthenticateUserUseCase>(),
      c.get<TelemetryLogger>(),
    );
  });

  // Prime singletons
  box1.get<CheckoutScreenController>();

  final scoreBox1 = runTimed(screenNavOps, () {
    final controller = box1.get<CheckoutScreenController>();
    if (identical(controller, null)) {
      throw StateError('Null controller');
    }
  });

  // 2. Setup GetIt Container
  final getIt1 = GetIt.asNewInstance();
  getIt1.registerSingleton<AppConfig>(AppConfig());
  getIt1.registerSingleton<SecureTokenStorage>(SecureTokenStorage());
  getIt1.registerSingleton<TelemetryLogger>(TelemetryLogger());
  getIt1.registerSingleton<LocalDatabase>(LocalDatabase());
  getIt1.registerLazySingleton<ApiClient>(() {
    return ApiClient(getIt1<AppConfig>(), getIt1<SecureTokenStorage>(),
        getIt1<TelemetryLogger>());
  });
  getIt1.registerLazySingleton<UserRemoteDataSource>(() {
    return UserRemoteDataSource(getIt1<ApiClient>());
  });
  getIt1.registerLazySingleton<UserLocalDataSource>(() {
    return UserLocalDataSource(getIt1<LocalDatabase>());
  });
  getIt1.registerLazySingleton<OrderRemoteDataSource>(() {
    return OrderRemoteDataSource(getIt1<ApiClient>());
  });
  getIt1.registerLazySingleton<UserRepository>(() {
    return UserRepository(getIt1<UserRemoteDataSource>(),
        getIt1<UserLocalDataSource>(), getIt1<TelemetryLogger>());
  });
  getIt1.registerLazySingleton<OrderRepository>(() {
    return OrderRepository(
        getIt1<OrderRemoteDataSource>(), getIt1<TelemetryLogger>());
  });
  getIt1.registerLazySingleton<SessionManager>(() {
    return SessionManager(
        getIt1<SecureTokenStorage>(), getIt1<UserRepository>());
  });
  getIt1.registerLazySingleton<AuthenticateUserUseCase>(() {
    return AuthenticateUserUseCase(getIt1<UserRepository>(),
        getIt1<SessionManager>(), getIt1<TelemetryLogger>());
  });
  getIt1.registerLazySingleton<ProcessCheckoutUseCase>(() {
    return ProcessCheckoutUseCase(
        getIt1<UserRepository>(),
        getIt1<OrderRepository>(),
        getIt1<SessionManager>(),
        getIt1<TelemetryLogger>());
  });
  getIt1.registerFactory<CheckoutScreenController>(() {
    return CheckoutScreenController(
      getIt1<ProcessCheckoutUseCase>(),
      getIt1<AuthenticateUserUseCase>(),
      getIt1<TelemetryLogger>(),
    );
  });

  // Prime singletons
  getIt1<CheckoutScreenController>();

  final scoreGetIt1 = runTimed(screenNavOps, () {
    final controller = getIt1<CheckoutScreenController>();
    if (identical(controller, null)) {
      throw StateError('Null controller');
    }
  });
  stdout.writeln('Done.');

  // ===========================================================================
  // SCENARIO 2: Scoped Feature / Wizard Session Lifecycle
  // Creating a scoped container / push scope, registering 6 scoped services,
  // resolving 10 times during wizard flow, and destroying the scope.
  // ===========================================================================
  stdout.write(
      'Running Scenario 2/5: Scoped Feature Lifecycle (50,000 complete sessions)... ');
  const scopeLifecycles = 50000;

  final scoreBox2 = runTimed(scopeLifecycles, () {
    final scope = DependencyBox.main();
    scope
        .addSingleton<ScopedPaymentSession>(ScopedPaymentSession('session_99'));
    scope.addSingleton<ScopedCartState>(ScopedCartState(3));
    scope.addSingleton<ScopedBillingValidator>(ScopedBillingValidator());
    scope.addLazySingleton<ScopedPaymentGateway>((c) {
      return ScopedPaymentGateway(
          c.get<ScopedPaymentSession>(), c.get<ScopedBillingValidator>());
    });
    scope.addFactory<ScopedCheckoutWizardController>((c) {
      return ScopedCheckoutWizardController(
          c.get<ScopedPaymentGateway>(), c.get<ScopedCartState>());
    });

    for (var i = 0; i < 10; i++) {
      final ctrl = scope.get<ScopedCheckoutWizardController>();
      if (identical(ctrl, null)) {
        throw StateError('');
      }
    }
    scope.dispose();
  });

  final getItParent = GetIt.asNewInstance();
  final scoreGetIt2 = runTimed(scopeLifecycles, () {
    getItParent.pushNewScope(scopeName: 'checkout_wizard');
    getItParent.registerSingleton<ScopedPaymentSession>(
        ScopedPaymentSession('session_99'));
    getItParent.registerSingleton<ScopedCartState>(ScopedCartState(3));
    getItParent
        .registerSingleton<ScopedBillingValidator>(ScopedBillingValidator());
    getItParent.registerLazySingleton<ScopedPaymentGateway>(() {
      return ScopedPaymentGateway(getItParent<ScopedPaymentSession>(),
          getItParent<ScopedBillingValidator>());
    });
    getItParent.registerFactory<ScopedCheckoutWizardController>(() {
      return ScopedCheckoutWizardController(
          getItParent<ScopedPaymentGateway>(), getItParent<ScopedCartState>());
    });

    for (var i = 0; i < 10; i++) {
      final ctrl = getItParent<ScopedCheckoutWizardController>();
      if (identical(ctrl, null)) {
        throw StateError('');
      }
    }
    getItParent.popScope();
  });
  stdout.writeln('Done.');

  // ===========================================================================
  // SCENARIO 3: Interleaved Production Traffic (Realistic Mixed Workload)
  // Simulates real-world unpredictable application runtime:
  // - 50% Core Singleton reads
  // - 25% Factory ViewModel instantiations
  // - 15% Keyed / Environment lookups
  // - 10% Parameterized queries
  // ===========================================================================
  stdout.write(
      'Running Scenario 3/5: Interleaved Mixed Production Traffic (3M ops)... ');
  const mixedOps = 3000000;

  // Box setup
  final box3 = DependencyBox.main();
  box3.addSingleton<AppConfig>(AppConfig());
  box3.addSingleton<TelemetryLogger>(TelemetryLogger());
  box3.addSingleton<LocalDatabase>(LocalDatabase(path: '/data/primary.db'),
      key: 'primary');
  box3.addSingleton<LocalDatabase>(LocalDatabase(path: '/data/analytics.db'),
      key: 'analytics');
  box3.addFactory<CatalogScreenController>((c) {
    return CatalogScreenController(
        LoadCatalogUseCase(
            ProductRepository(
                ProductRemoteDataSource(ApiClient(AppConfig(),
                    SecureTokenStorage(), c.get<TelemetryLogger>())),
                ProductLocalDataSource(LocalDatabase())),
            c.get<TelemetryLogger>()),
        c.get<TelemetryLogger>());
  });
  box3.addFactoryWith<DynamicQueryEngine, String>((c, q) {
    return DynamicQueryEngine(q);
  });

  // GetIt setup
  final getIt3 = GetIt.asNewInstance();
  getIt3.registerSingleton<AppConfig>(AppConfig());
  getIt3.registerSingleton<TelemetryLogger>(TelemetryLogger());
  getIt3.registerSingleton<LocalDatabase>(
      LocalDatabase(path: '/data/primary.db'),
      instanceName: 'primary');
  getIt3.registerSingleton<LocalDatabase>(
      LocalDatabase(path: '/data/analytics.db'),
      instanceName: 'analytics');
  getIt3.registerFactory<CatalogScreenController>(() {
    return CatalogScreenController(
        LoadCatalogUseCase(
            ProductRepository(
                ProductRemoteDataSource(ApiClient(AppConfig(),
                    SecureTokenStorage(), getIt3<TelemetryLogger>())),
                ProductLocalDataSource(LocalDatabase())),
            getIt3<TelemetryLogger>()),
        getIt3<TelemetryLogger>());
  });
  getIt3.registerFactoryParam<DynamicQueryEngine, String, dynamic>((q, _) {
    return DynamicQueryEngine(q);
  });

  final scoreBox3 = runTimed(mixedOps, () {
    // 50% Singleton (2 calls)
    final cfg = box3.get<AppConfig>();
    final log = box3.get<TelemetryLogger>();
    // 25% Factory (1 call)
    final ctrl = box3.get<CatalogScreenController>();
    // 15% Keyed (1 call alternating)
    final db = box3.get<LocalDatabase>(key: 'primary');
    // 10% Parameterized (1 call)
    final qe = box3.get<DynamicQueryEngine>(args: 'SELECT users');

    if (identical(cfg, null) ||
        identical(log, null) ||
        identical(ctrl, null) ||
        identical(db, null) ||
        identical(qe, null)) {
      throw StateError('');
    }
  });

  final scoreGetIt3 = runTimed(mixedOps, () {
    // 50% Singleton (2 calls)
    final cfg = getIt3<AppConfig>();
    final log = getIt3<TelemetryLogger>();
    // 25% Factory (1 call)
    final ctrl = getIt3<CatalogScreenController>();
    // 15% Keyed (1 call)
    final db = getIt3<LocalDatabase>(instanceName: 'primary');
    // 10% Parameterized (1 call)
    final qe = getIt3<DynamicQueryEngine>(param1: 'SELECT users');

    if (identical(cfg, null) ||
        identical(log, null) ||
        identical(ctrl, null) ||
        identical(db, null) ||
        identical(qe, null)) {
      throw StateError('');
    }
  });
  stdout.writeln('Done.');

  // ===========================================================================
  // SCENARIO 4: Plugin & Interceptor Pipeline (getAll<T>() Resolution)
  // Resolving an entire middleware / plugin pipeline of 6 interceptors.
  // ===========================================================================
  stdout.write(
      'Running Scenario 4/5: Middleware Pipeline (getAll<T>() Resolution) (2M ops)... ');
  const pipelineOps = 2000000;

  final box4 = DependencyBox.main();
  box4.allowMultiple({Multi<HttpInterceptor>()});
  box4.addSingleton<HttpInterceptor>(AuthHeaderInterceptor());
  box4.addSingleton<HttpInterceptor>(CompressionInterceptor());
  box4.addSingleton<HttpInterceptor>(RateLimitInterceptor());
  box4.addSingleton<HttpInterceptor>(LoggingInterceptor());
  box4.addSingleton<HttpInterceptor>(RetryInterceptor());
  box4.addSingleton<HttpInterceptor>(TelemetryInterceptor());

  final scoreBox4 = runTimed(pipelineOps, () {
    final interceptors = box4.getAll<HttpInterceptor>();
    if (interceptors.length != 6) {
      throw StateError('');
    }
  });

  final getIt4 = GetIt.asNewInstance();
  getIt4.registerSingleton<HttpInterceptor>(AuthHeaderInterceptor(),
      instanceName: 'i1');
  getIt4.registerSingleton<HttpInterceptor>(CompressionInterceptor(),
      instanceName: 'i2');
  getIt4.registerSingleton<HttpInterceptor>(RateLimitInterceptor(),
      instanceName: 'i3');
  getIt4.registerSingleton<HttpInterceptor>(LoggingInterceptor(),
      instanceName: 'i4');
  getIt4.registerSingleton<HttpInterceptor>(RetryInterceptor(),
      instanceName: 'i5');
  getIt4.registerSingleton<HttpInterceptor>(TelemetryInterceptor(),
      instanceName: 'i6');

  final scoreGetIt4 = runTimed(pipelineOps, () {
    final interceptors = getIt4.getAll<HttpInterceptor>();
    if (interceptors.length != 6) {
      throw StateError('');
    }
  });
  stdout.writeln('Done.');

  // ===========================================================================
  // SCENARIO 5: Full Application Cold Boot & Graph Initialization
  // Registering 50 production services (20 Singletons, 15 Lazy, 10 Factories,
  // 5 Parameterized) + resolving the 15 critical initial startup services.
  // ===========================================================================
  stdout.write(
      'Running Scenario 5/5: Cold App Startup & Container Bootstrapping (5,000 app boots)... ');
  const bootCycles = 5000;

  final swBoxBoot = Stopwatch()..start();
  for (var b = 0; b < bootCycles; b++) {
    final box = DependencyBox.main();
    // 20 Singletons
    for (var i = 0; i < 20; i++) {
      box.addSingleton<String>('val_$i', key: 's_$i');
    }
    // 15 LazySingletons
    for (var i = 0; i < 15; i++) {
      box.addLazySingleton<int>((c) {
        return i * 10;
      }, key: 'l_$i');
    }
    // 10 Factories
    for (var i = 0; i < 10; i++) {
      box.addFactory<double>((c) {
        return i * 1.5;
      }, key: 'f_$i');
    }
    // 5 Parameterized Factories
    for (var i = 0; i < 5; i++) {
      box.addFactoryWith<String, String>((c, a) {
        return '$a-$i';
      }, key: 'p_$i');
    }

    // Resolve 15 critical startup services
    for (var i = 0; i < 8; i++) {
      final s = box.get<String>(key: 's_$i');
      if (identical(s, null)) throw StateError('');
    }
    for (var i = 0; i < 5; i++) {
      final l = box.get<int>(key: 'l_$i');
      if (identical(l, null)) throw StateError('');
    }
    for (var i = 0; i < 2; i++) {
      final f = box.get<double>(key: 'f_$i');
      if (identical(f, null)) throw StateError('');
    }
  }
  swBoxBoot.stop();
  final scoreBoxBoot =
      BenchmarkScore(bootCycles, swBoxBoot.elapsedMicroseconds);

  final swGetItBoot = Stopwatch()..start();
  for (var b = 0; b < bootCycles; b++) {
    final gi = GetIt.asNewInstance();
    // 20 Singletons
    for (var i = 0; i < 20; i++) {
      gi.registerSingleton<String>('val_$i', instanceName: 's_$i');
    }
    // 15 LazySingletons
    for (var i = 0; i < 15; i++) {
      gi.registerLazySingleton<int>(() {
        return i * 10;
      }, instanceName: 'l_$i');
    }
    // 10 Factories
    for (var i = 0; i < 10; i++) {
      gi.registerFactory<double>(() {
        return i * 1.5;
      }, instanceName: 'f_$i');
    }
    // 5 Parameterized Factories
    for (var i = 0; i < 5; i++) {
      gi.registerFactoryParam<String, String, dynamic>((a, _) {
        return '$a-$i';
      }, instanceName: 'p_$i');
    }

    // Resolve 15 critical startup services
    for (var i = 0; i < 8; i++) {
      final s = gi<String>(instanceName: 's_$i');
      if (identical(s, null)) throw StateError('');
    }
    for (var i = 0; i < 5; i++) {
      final l = gi<int>(instanceName: 'l_$i');
      if (identical(l, null)) throw StateError('');
    }
    for (var i = 0; i < 2; i++) {
      final f = gi<double>(instanceName: 'f_$i');
      if (identical(f, null)) throw StateError('');
    }
  }
  swGetItBoot.stop();
  final scoreGetItBoot =
      BenchmarkScore(bootCycles, swGetItBoot.elapsedMicroseconds);

  // Also test with Injectable GetItHelper
  final swInjectableBoot = Stopwatch()..start();
  for (var b = 0; b < bootCycles; b++) {
    final gi = GetIt.asNewInstance();
    final gh = GetItHelper(gi);
    // 20 Singletons
    for (var i = 0; i < 20; i++) {
      gh.singleton<String>(() {
        return 'val_$i';
      }, instanceName: 's_$i');
    }
    // 15 LazySingletons
    for (var i = 0; i < 15; i++) {
      gh.lazySingleton<int>(() {
        return i * 10;
      }, instanceName: 'l_$i');
    }
    // 10 Factories
    for (var i = 0; i < 10; i++) {
      gh.factory<double>(() {
        return i * 1.5;
      }, instanceName: 'f_$i');
    }
    // 5 Parameterized Factories
    for (var i = 0; i < 5; i++) {
      gh.factoryParam<String, String, dynamic>((a, _) {
        return '$a-$i';
      }, instanceName: 'p_$i');
    }

    // Resolve 15 critical startup services
    for (var i = 0; i < 8; i++) {
      final s = gi<String>(instanceName: 's_$i');
      if (identical(s, null)) throw StateError('');
    }
    for (var i = 0; i < 5; i++) {
      final l = gi<int>(instanceName: 'l_$i');
      if (identical(l, null)) throw StateError('');
    }
    for (var i = 0; i < 2; i++) {
      final f = gi<double>(instanceName: 'f_$i');
      if (identical(f, null)) throw StateError('');
    }
  }
  swInjectableBoot.stop();
  final scoreInjectableBoot =
      BenchmarkScore(bootCycles, swInjectableBoot.elapsedMicroseconds);
  stdout.writeln('Done.\n');

  // ===========================================================================
  // Formatted Results Output
  // ===========================================================================

  void printResult(String title, BenchmarkScore box, BenchmarkScore getIt,
      {BenchmarkScore? injectable, bool isMicros = false}) {
    final speedup = isMicros
        ? (getIt.microsPerOp / box.microsPerOp)
        : (getIt.nsPerOp / box.nsPerOp);
    final diffPercent = isMicros
        ? (((getIt.microsPerOp - box.microsPerOp) / getIt.microsPerOp) * 100.0)
        : (((getIt.nsPerOp - box.nsPerOp) / getIt.nsPerOp) * 100.0);
    final winner = (isMicros
            ? box.microsPerOp < getIt.microsPerOp
            : box.nsPerOp < getIt.nsPerOp)
        ? 'dependency_box is ${speedup.toStringAsFixed(2)}x faster (${diffPercent.toStringAsFixed(1)}% less time)'
        : 'get_it is ${(1 / speedup).toStringAsFixed(2)}x faster';

    stdout.writeln('### $title');
    stdout.writeln(
        '| Metric | dependency_box | get_it 9.3.0 | injectable 3.0.0 | Advantage |');
    stdout.writeln('|:---|:---:|:---:|:---:|:---|');
    if (isMicros) {
      stdout.writeln(
          '| **Latency / Boot** | **${box.microsPerOp.toStringAsFixed(2)} µs** | ${getIt.microsPerOp.toStringAsFixed(2)} µs | ${injectable != null ? '${injectable.microsPerOp.toStringAsFixed(2)} µs' : '${getIt.microsPerOp.toStringAsFixed(2)} µs*'} | **$winner** |');
      stdout.writeln(
          '| **Boot Throughput** | **${box.opsPerSec.toStringAsFixed(0)} boots/s** | ${getIt.opsPerSec.toStringAsFixed(0)} boots/s | ${injectable != null ? '${injectable.opsPerSec.toStringAsFixed(0)} boots/s' : '${getIt.opsPerSec.toStringAsFixed(0)} boots/s*'} | |');
    } else {
      stdout.writeln(
          '| **Latency** | **${box.nsPerOp.toStringAsFixed(2)} ns/op** | ${getIt.nsPerOp.toStringAsFixed(2)} ns/op | ${injectable != null ? '${injectable.nsPerOp.toStringAsFixed(2)} ns/op' : '${getIt.nsPerOp.toStringAsFixed(2)} ns/op*'} | **$winner** |');
      stdout.writeln(
          '| **Throughput** | **${box.opsPerSec.toStringAsFixed(0)} ops/s** | ${getIt.opsPerSec.toStringAsFixed(0)} ops/s | ${injectable != null ? '${injectable.opsPerSec.toStringAsFixed(0)} ops/s' : '${getIt.opsPerSec.toStringAsFixed(0)} ops/s*'} | |');
    }
    stdout.writeln('');
  }

  stdout.writeln('## Real-World Production Architecture Scenarios\n');
  printResult('1. Clean Architecture Screen Navigation & ViewModel Resolution',
      scoreBox1, scoreGetIt1);
  printResult(
      '2. Scoped Feature / Wizard Session Flow (Create, Register, Use, Destroy)',
      scoreBox2,
      scoreGetIt2,
      isMicros: true);
  printResult(
      '3. Interleaved Mixed Production Traffic (50% Singletons, 25% Factory, 15% Keyed, 10% Param)',
      scoreBox3,
      scoreGetIt3);
  printResult(
      '4. Plugin / Interceptor Pipeline Resolution (getAll<T>() across 6 handlers)',
      scoreBox4,
      scoreGetIt4);
  printResult(
      '5. Cold App Startup & Container Bootstrapping (50 Services Registered + 15 Resolved)',
      scoreBoxBoot,
      scoreGetItBoot,
      injectable: scoreInjectableBoot,
      isMicros: true);

  stdout.writeln(
      '*(Note: injectable code generation uses GetItHelper to configure GetIt; runtime resolution delegates directly to get_it 9.3.0).*');
}
