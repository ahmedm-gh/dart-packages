import 'dart:async';
import 'package:dependency_box/dependency_box.dart';

// ============================================================================
// 1. Shallow Dependency Graph Fixtures
// ============================================================================

class ShallowRepository {
  final String source = 'memory';
}

class ShallowService {
  final ShallowRepository repository;
  ShallowService(this.repository);
}

// ============================================================================
// 2. Medium Dependency Graph Fixtures
// ============================================================================

class AppConfig {
  final String env;
  final String apiUrl;
  AppConfig({this.env = 'production', this.apiUrl = 'https://api.example.com'});
}

class LocalStorage {
  final String path = '/var/data.db';
}

class HttpClient {
  final AppConfig config;
  HttpClient(this.config);
}

class UserRepository {
  final AppConfig config;
  final LocalStorage storage;
  final HttpClient client;
  UserRepository(this.config, this.storage, this.client);
}

class UserService {
  final UserRepository repository;
  UserService(this.repository);
}

// ============================================================================
// 3. Deep Dependency Graph Fixtures (5 Levels)
// ============================================================================

class DeepLevel1Core {
  final int id = 1;
}

class DeepLevel2Storage {
  final DeepLevel1Core core;
  DeepLevel2Storage(this.core);
}

class DeepLevel3Client {
  final DeepLevel2Storage storage;
  DeepLevel3Client(this.storage);
}

class DeepLevel4Gateway {
  final DeepLevel3Client client;
  DeepLevel4Gateway(this.client);
}

class DeepLevel5Service {
  final DeepLevel4Gateway gateway;
  DeepLevel5Service(this.gateway);
}

// ============================================================================
// 4. Parameterized Fixtures
// ============================================================================

class ParameterizedService {
  final String name;
  final int code;
  ParameterizedService({required this.name, required this.code});
}

// ============================================================================
// 5. Multi-Registration Interface & Implementations
// ============================================================================

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

// ============================================================================
// 6. Asynchronous Singleton Fixtures
// ============================================================================

class AsyncDatabase {
  final String connectionString;
  AsyncDatabase(this.connectionString);

  static int factoryExecutionCount = 0;

  static Future<AsyncDatabase> connect([String url = 'db://primary']) async {
    factoryExecutionCount++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return AsyncDatabase(url);
  }
}

class AsyncAuthService {
  final AsyncDatabase database;
  AsyncAuthService(this.database);

  static int factoryExecutionCount = 0;

  static Future<AsyncAuthService> create(AsyncDatabase db) async {
    factoryExecutionCount++;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return AsyncAuthService(db);
  }
}

// ============================================================================
// 7. Lifecycle & Disposal Fixtures
// ============================================================================

class DisposableService implements DependencyDisposable {
  bool isDisposed = false;
  static int disposalCount = 0;

  @override
  FutureOr<void> dispose() {
    isDisposed = true;
    disposalCount++;
  }
}

class AsyncDisposableService {
  bool isDisposed = false;
  static int asyncDisposalCount = 0;

  Future<void> dispose() async {
    await Future<void>.delayed(const Duration(microseconds: 100));
    isDisposed = true;
    asyncDisposalCount++;
  }
}
