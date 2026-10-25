import 'dart:async';
import 'package:dependency_box/dependency_box.dart';

class RemoteSessionConfig {
  final String sessionToken;
  final int expireMinutes;

  RemoteSessionConfig(this.sessionToken, this.expireMinutes);
}

class RemoteApiClient {
  final RemoteSessionConfig config;
  RemoteApiClient(this.config);

  void sendRequest() {
    print('Sending authenticated request with token: ${config.sessionToken}');
  }
}

void main() async {
  print('=== 04 Async Singletons & Deduplication Example ===\n');

  final box = DependencyBox.main();

  var factoryCallCount = 0;

  // 1. Register an Asynchronous Singleton (e.g. fetching credentials or remote configs)
  box.addAsyncSingleton<RemoteSessionConfig>((container) async {
    factoryCallCount++;
    print(
        '>>> [ASYNC FACTORY] Loading remote configuration from cloud server...');
    await Future<void>.delayed(
        const Duration(milliseconds: 100)); // Simulate network latency
    print('<<< [ASYNC FACTORY] Configuration loaded successfully.');
    return RemoteSessionConfig('jwt_secure_auth_token_999', 60);
  });

  // 2. Synchronous service that depends on the async singleton via getAsync
  box.addLazySingleton<RemoteApiClient>((container) {
    // When resolving synchronously, ensure the async dependency was already initialized!
    final config = container.get<RemoteSessionConfig>();
    return RemoteApiClient(config);
  });

  // 3. In-Flight Future Deduplication:
  // If 5 concurrent operations request RemoteSessionConfig simultaneously,
  // the factory will ONLY run once! All 5 awaiters share the same Future.
  print('--- Triggering 5 concurrent getAsync calls ---');
  final results = await Future.wait([
    box.getAsync<RemoteSessionConfig>(),
    box.getAsync<RemoteSessionConfig>(),
    box.getAsync<RemoteSessionConfig>(),
    box.getAsync<RemoteSessionConfig>(),
    box.getAsync<RemoteSessionConfig>(),
  ]);

  print('Received ${results.length} results.');
  print('Total async factory execution count: $factoryCallCount (Expected: 1)');

  // 4. Once initialized, synchronous get() can safely access the singleton
  final client = box.get<RemoteApiClient>();
  client.sendRequest();

  // 5. Resolving a synchronous dependency via getAsync returns Future.value immediately
  final sameClient = await box.getAsync<RemoteApiClient>();
  print(
      'getAsync on synchronous dependency succeeded: ${identical(client, sameClient)}');

  // 6. Safe tryGetAsync for un-registered dependencies
  final missing = await box.tryGetAsync<String>();
  print('tryGetAsync on missing dependency returned: $missing'); // null
}
