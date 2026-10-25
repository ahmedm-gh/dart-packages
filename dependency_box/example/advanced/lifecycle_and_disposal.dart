import 'dart:async';
import 'package:dependency_box/dependency_box.dart';

// ============================================================================
// 1. RESOURCES WITH LIFECYCLE MANAGEMENT
// ============================================================================

/// A long-lived message broker implementing [DependencyDisposable].
/// [dispose] is automatically awaited when the owning container is disposed.
class MessageBroker implements DependencyDisposable {
  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;
  Stream<String> get stream => _controller.stream;

  void publish(String message) {
    if (_isDisposed) {
      throw StateError('Cannot publish to a disposed MessageBroker');
    }
    print('[BROKER] Publishing event: "$message"');
    _controller.add(message);
  }

  @override
  FutureOr<void> dispose() async {
    print('[BROKER] Disposing MessageBroker and closing broadcast stream...');
    _isDisposed = true;
    await _controller.close();
    print('[BROKER] MessageBroker successfully closed.');
  }
}

/// A cache service that does NOT implement DependencyDisposable directly,
/// but relies on an inline `onDispose` callback registered with DependencyBox.
class MemoryCache {
  final Map<String, String> _data = {};
  bool isFlushed = false;

  void put(String key, String value) => _data[key] = value;
  String? get(String key) => _data[key];

  Future<void> flushToDisk() async {
    print(
        '[CACHE] Flushing ${_data.length} cache entries to persistent storage...');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    isFlushed = true;
    _data.clear();
    print('[CACHE] Cache successfully flushed and cleared.');
  }
}

/// A short-lived user session resource tied to a child container / screen scope.
class UserSession implements DependencyDisposable {
  final String userId;
  final String authToken;
  final StreamSubscription<String>? _subscription;
  bool isClosed = false;

  UserSession({
    required this.userId,
    required this.authToken,
    StreamSubscription<String>? subscription,
  }) : _subscription = subscription;

  @override
  FutureOr<void> dispose() async {
    print(
        '[SESSION] Terminating session for user "$userId" (token: $authToken)...');
    await _subscription?.cancel();
    isClosed = true;
    print('[SESSION] UserSession closed and subscription cancelled.');
  }
}

/// A metrics tracker created inside a child scope, but anchored to the root container.
class SharedMetricsCollector {
  int totalEventsCount = 0;
  void record() => totalEventsCount++;
}

// ============================================================================
// 2. LIFECYCLE DEMONSTRATION WORKFLOW
// ============================================================================

void main() async {
  print('====================================================================');
  print('  Advanced 02: Lifecycle Management & Hierarchical Disposal');
  print(
      '====================================================================\n');

  // --------------------------------------------------------------------------
  // Step 1: Initialize Root Container with Long-Lived Singletons
  // --------------------------------------------------------------------------
  print('1. Initializing Root Container & Registrations:');
  final rootBox = DependencyBox.main();

  // A. Eager singleton implementing DependencyDisposable
  rootBox.addSingleton<MessageBroker>(MessageBroker());

  // B. Lazy singleton with custom inline onDispose hook
  rootBox.addLazySingleton<MemoryCache>(
    (_) => MemoryCache(),
    onDispose: (cache) async {
      print('[HOOK] Invoking inline onDispose hook for MemoryCache...');
      await cache.flushToDisk();
    },
  );

  print('   -> Root container initialized: isDisposed = ${rootBox.isDisposed}');
  final broker = rootBox.get<MessageBroker>();
  final cache = rootBox.get<MemoryCache>();
  cache.put('session_seed', 'abc-123');

  // --------------------------------------------------------------------------
  // Step 2: Create Child Scope (e.g., Authenticated Request / UI Screen)
  // --------------------------------------------------------------------------
  print('\n2. Creating Scoped Child Container (e.g. User Session):');
  final sessionBox = rootBox.createChild();

  // Listen to the broker inside the session
  final sub = broker.stream.listen((msg) {
    print('   [SESSION LISTENER] Received event: $msg');
  });

  // Register scoped session in the child container
  sessionBox.addSingleton<UserSession>(
    UserSession(userId: 'usr_42', authToken: 'jwt-sec-99', subscription: sub),
  );

  // Register a shared singleton anchored to root directly from child
  sessionBox
      .addSharedSingleton<SharedMetricsCollector>(SharedMetricsCollector());

  final session = sessionBox.get<UserSession>();
  final metrics = sessionBox.get<SharedMetricsCollector>();
  metrics.record();

  broker.publish('User usr_42 logged in successfully');
  print(
      '   -> Scoped session active: userId=${session.userId}, isClosed=${session.isClosed}');
  print(
      '   -> Metrics recorded on root: totalEvents=${rootBox.get<SharedMetricsCollector>().totalEventsCount}');

  // --------------------------------------------------------------------------
  // Step 3: Dispose Child Scope (Simulating Logout or Screen Exit)
  // --------------------------------------------------------------------------
  print('\n3. Disposing Child Scope (sessionBox.dispose()):');
  print('   Child isDisposed before: ${sessionBox.isDisposed}');
  await sessionBox.dispose();
  print('   Child isDisposed after:  ${sessionBox.isDisposed}');
  print('   UserSession isClosed:    ${session.isClosed}');

  // Verify child scope isolation: child cannot resolve, but parent remains fully functional
  print('\n4. Verifying Parent & Shared Bindings Isolation:');
  print(
      '   - childBox.tryGet<UserSession>() -> ${sessionBox.tryGet<UserSession>()} (null)');
  print('   - rootBox.isDisposed -> ${rootBox.isDisposed} (false, intact)');
  print(
      '   - rootBox broker isDisposed -> ${broker.isDisposed} (false, still active)');
  print(
      '   - SharedMetrics on root -> totalEvents=${rootBox.get<SharedMetricsCollector>().totalEventsCount} (survived child disposal!)');

  // --------------------------------------------------------------------------
  // Step 4: Selective Removal with Immediate Disposal
  // --------------------------------------------------------------------------
  print(
      '\n5. Targeted Removal with Immediate Disposal (await remove<T>(dispose: true)):');
  final removed = await rootBox.remove<MemoryCache>(dispose: true);
  print('   - MemoryCache removed ($removed). isFlushed = ${cache.isFlushed}');
  print(
      '   - rootBox.contains<MemoryCache>() -> ${rootBox.contains<MemoryCache>()}');

  // --------------------------------------------------------------------------
  // Step 5: Full Container Teardown
  // --------------------------------------------------------------------------
  print('\n6. Full Root Container Teardown (rootBox.dispose()):');
  await rootBox.dispose();
  print('   - rootBox.isDisposed: ${rootBox.isDisposed}');
  print('   - broker.isDisposed:  ${broker.isDisposed}');
  print('\n[SUCCESS] All container lifecycles and disposals executed cleanly!');
}
