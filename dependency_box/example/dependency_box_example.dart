import 'dart:async';

import 'package:dependency_box/dependency_box.dart';

enum Environment { production, development }

// ---------------------------------------------------------------------------
// Domain Services & Dependency Contracts
// ---------------------------------------------------------------------------

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

class NotificationService {
  final String channel;
  const NotificationService(this.channel);
}

class UserSession {
  final String userId;
  final String role;
  const UserSession({required this.userId, required this.role});
}

class DeviceInfoService {
  final String platform;
  const DeviceInfoService(this.platform);
}

class RemoteConfigService {
  final Map<String, dynamic> features;
  RemoteConfigService(this.features);
  bool isFeatureEnabled(String key) => features[key] == true;
}

class EventBus implements DependencyDisposable {
  bool isClosed = false;

  @override
  FutureOr<void> dispose() {
    isClosed = true;
    print('EventBus streams closed cleanly.');
  }
}

class NetworkMonitor {
  bool isStopped = false;
  void stop() {
    isStopped = true;
    print('NetworkMonitor stopped via inline onDispose hook.');
  }
}

class AppModule implements DependencyModule {
  @override
  void register(DependencyBox dbox) {
    dbox.addSingleton<DeviceInfoService>(
      const DeviceInfoService('Flutter/Dart VM'),
    );
  }
}

abstract interface class Plugin {
  String get name;
}

class AnalyticsPlugin implements Plugin {
  @override
  String get name => 'analytics';
}

class LoggingPlugin implements Plugin {
  @override
  String get name => 'logging';
}

void main() async {
  // 1. Create a root dependency container (IoC composition root)
  final dbox = DependencyBox.main(name: 'app_root');

  // 2. Install feature modules (modular dependency composition)
  dbox.install(AppModule());

  // 3. Register singletons with Enum qualification keys
  dbox.addSingleton<ApiConfig>(
    const ApiConfig('https://api.prod.example.com'),
    key: Environment.production,
  );
  dbox.addSingleton<ApiConfig>(
    const ApiConfig('https://api.dev.example.com'),
    key: Environment.development,
  );

  // 4. Register lazy singletons via constructor injection (instantiated on first get())
  dbox.addLazySingleton<AuthService>((dbox) {
    return AuthService(dbox.get<ApiConfig>(key: Environment.production));
  });

  // Global root notification service
  dbox.addSingleton<NotificationService>(
    const NotificationService('global_push_channel'),
  );

  // 5. Register resources with inline onDispose lifecycle hooks
  dbox.addSingleton<NetworkMonitor>(
    NetworkMonitor(),
    onDispose: (monitor) {
      monitor.stop();
    },
  );

  // 6. Register disposable services implementing DependencyDisposable
  dbox.addSingleton<EventBus>(EventBus());

  // 7. Multi-registration with custom resolution strategy
  dbox.allowMulti<Plugin>();
  dbox.addSingleton<Plugin>(AnalyticsPlugin());
  dbox.addSingleton<Plugin>(LoggingPlugin());

  // 8. Register asynchronous singletons (deduplicated Future resolution)
  dbox.addAsyncSingleton<RemoteConfigService>((dbox) async {
    // Simulating remote config / service initialization
    return RemoteConfigService({'new_checkout_flow': true});
  });

  // 9. Resolve dependencies (Service Location & Injection)
  final auth = dbox.get<AuthService>();
  auth.login('Alice');

  final remoteConfig = await dbox.getAsync<RemoteConfigService>();
  print(
    'Resolved async RemoteConfigService: new_checkout_flow = ${remoteConfig.isFeatureEnabled('new_checkout_flow')}',
  );

  final plugins = dbox.getAll<Plugin>();
  print(
    'Resolved ${plugins.length} active plugins: ${plugins.map((p) => p.name).join(', ')}',
  );

  // 10. Hierarchical child scopes & LookupScope boundary resolution
  final userScope = dbox.createChild(name: 'user_session');

  // Register scoped dependencies for this user session
  userScope.addSingleton<UserSession>(
    const UserSession(userId: 'usr_42', role: 'admin'),
  );

  // Scoped service override (shadows root NotificationService)
  userScope.addSingleton<NotificationService>(
    const NotificationService('user_session_channel'),
  );

  // Hierarchy introspection
  print('User session depth: ${userScope.depth}'); // 1
  print(
    'Is NotificationService shadowed: ${userScope.isShadowed<NotificationService>()}',
  ); // true

  // Scope boundary resolution
  final localNotifier = userScope.get<NotificationService>(
    scope: LookupScope.local,
  );
  final rootNotifier = userScope.get<NotificationService>(
    scope: LookupScope.root,
  );
  print(
    'Local scoped service: ${localNotifier.channel}',
  ); // user_session_channel
  print(
    'Root service via LookupScope.root: ${rootNotifier.channel}',
  ); // global_push_channel

  // Resolve inherited service from parent module
  final device = userScope.get<DeviceInfoService>();
  print('Inherited DeviceInfoService: ${device.platform}');

  // Resolve user-scoped session
  final session = userScope.get<UserSession>();
  print('Active user session: ${session.userId} (${session.role})');

  // Disposing child cleans up its scoped instances while leaving parent intact
  await userScope.dispose();
  print('User session child disposed. Parent isDisposed: ${dbox.isDisposed}');

  // 11. Cleanup and dispose root container and all active services
  await dbox.dispose();
  print('Root dbox and services disposed cleanly.');
}
