import 'dart:async';
import 'package:dependency_box/dependency_box.dart';

enum Environment { production, development }

class ApiConfig {
  final String endpoint;
  const ApiConfig(this.endpoint);
}

class AuthService {
  final ApiConfig config;
  AuthService(this.config);

  void login(String username) {
    print('Logging in $username via ${config.endpoint}');
  }
}

class DatabaseConnection implements DependencyDisposable {
  bool isClosed = false;

  @override
  FutureOr<void> dispose() {
    isClosed = true;
    print('Database connection closed cleanly.');
  }
}

class NetworkClient {
  bool closed = false;
  void close() {
    closed = true;
    print('NetworkClient closed via inline onDispose hook.');
  }
}

class AppModule implements DependencyModule {
  @override
  void register(DependencyBox box) {
    box.addSingleton<String>('v1.0.0', key: 'app_version');
  }
}

abstract interface class Plugin {
  String get name;
}

class AnalyticsPlugin implements Plugin {
  @override
  String get name {
    return 'analytics';
  }
}

class LoggingPlugin implements Plugin {
  @override
  String get name {
    return 'logging';
  }
}

void main() async {
  // 1. Create a root dependency container
  final box = DependencyBox.main(name: 'app_root');

  // 2. Install feature modules
  box.install(AppModule());

  // 3. Register singletons with Enum keys
  box.addSingleton<ApiConfig>(
    const ApiConfig('https://api.prod.example.com'),
    key: Environment.production,
  );
  box.addSingleton<ApiConfig>(
    const ApiConfig('https://api.dev.example.com'),
    key: Environment.development,
  );

  // 4. Register lazy singletons (instantiated on first get)
  box.addLazySingleton<AuthService>((container) {
    return AuthService(
      container.get<ApiConfig>(key: Environment.production),
    );
  });

  // 5. Register resources with inline onDispose lifecycle hooks
  box.addSingleton<NetworkClient>(
    NetworkClient(),
    onDispose: (client) {
      client.close();
    },
  );

  // 6. Register disposable resources implementing DependencyDisposable
  box.addSingleton<DatabaseConnection>(DatabaseConnection());

  // 7. Multi-registration with custom resolution
  box.allowMulti<Plugin>();
  box.addSingleton<Plugin>(AnalyticsPlugin());
  box.addSingleton<Plugin>(LoggingPlugin());

  // 8. Register asynchronous singletons
  box.addAsyncSingleton<String>((container) async {
    return 'Async token: secret_jwt_123';
  });

  // 9. Retrieve dependencies
  final auth = box.get<AuthService>();
  auth.login('Alice');

  final token = await box.getAsync<String>();
  print('Resolved async: $token');

  // 10. Hierarchical child scopes
  final userScope = box.createChild(name: 'user_session');
  userScope.addSingleton<String>('user_session_token_xyz', key: 'token');

  // Child can resolve parent dependencies and its own scoped dependencies
  print(
      'User session has parent version: ${userScope.get<String>(key: 'app_version')}');
  print('User session token: ${userScope.get<String>(key: 'token')}');

  // Disposing child leaves parent intact
  await userScope.dispose();
  print('User session child disposed. Parent isDisposed: ${box.isDisposed}');

  // 11. Cleanup and dispose root container
  await box.dispose();
  print('Root box disposed cleanly.');
}
