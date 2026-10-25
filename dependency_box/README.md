# dependency_box

[![pub package](https://img.shields.io/pub/v/dependency_box.svg)](https://pub.dev/packages/dependency_box)
[![Star on GitHub](https://img.shields.io/badge/Star_on_GitHub-★-deeppink?style=flat&logo=github)](https://github.com/ahmedm-gh/dart-packages)
[![GitHub](https://img.shields.io/badge/GitHub-ahmedm--gh-blue?logo=github)](https://github.com/ahmedm-gh)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-pink?logo=github)](https://github.com/sponsors/ahmedm-gh)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A lightweight, zero-dependency Inversion-of-Control (IoC) container and service locator for Dart and Flutter applications.

Engineered with a zero-allocation unkeyed lookup path, `dependency_box` achieves sub-15ns resolution latency while offering hierarchical child scopes, lock-free async initialization deduplication, circular dependency detection, and lifecycle management.

> [!NOTE]
> **Public Beta**: `dependency_box` is feature-complete, thoroughly tested, and stable for production use. The beta designation is to gather community feedback and real-world use cases on [GitHub Issues](https://github.com/ahmedm-gh/dart-packages/issues) before finalizing the API.

---

## ✨ Features

- 🎯 **Zero Boilerplate Type Inference**: Full bidirectional type inference across registrations, nested factory resolutions (`dbox.get()`), and lookups—no need to write `<Type>` generic parameters unless the type cannot be inferred.
- 🪶 **Zero Runtime Dependencies**: Pure Dart implementation compatible with Dart VM, Flutter, Web, and WebAssembly (WASM).
- ⚡ **Sub-15ns Resolution Latency**: Delivers over 75 Million ops/sec on the hot path by leveraging direct `Type` map keys without lookup allocations.
- ⏳ **Six Registration Lifetimes**: Eager singletons, lazy singletons, weak-reference cached factories, transient factories, parameterized factories, and asynchronous singletons.
- 🌐 **Root-Anchored Shared Registrations**: Register singletons and cached factories from any scope (`addShared*`) anchored directly to the root container.
- 🌳 **Hierarchical Child Scopes**: Create isolated sub-containers (`createChild()`) that inherit parent registrations with fallback resolution and scoped lifecycle disposal.
- 🔄 **Async Concurrency & Cycle Detection**: Multiple concurrent callers share a single in-flight initialization `Future`, with automatic circular dependency detection across both sync and async paths.
- 🧹 **Clean Lifecycle & Resource Management**: Automatic cleanup via `DependencyDisposable` and inline `onDispose` hooks for external resources, deduplicated by object identity.
- 🔑 **Flexible Qualification Keys**: Qualify registrations with type-safe `Enum` variants, `Symbol`s, or custom value objects alongside strings.
- 📚 **Multi-Instance Collections**: Register multiple instances per type (`allowMulti<T>()`) with customizable resolution strategies (`last`, `first`, `at(index)`, `key(key)`).
- 🛡️ **Safe Introspection & Test Overrides**: Swap dependencies in unit tests via `replaceSingleton()`, inspect containers via `contains()` and `registeredKeys`, or query optionally via `tryGet()`.

---

## 📦 Installation

Add `dependency_box` to your `pubspec.yaml`:

```yaml
dependencies:
  dependency_box: ^0.1.0
```

Or install via terminal:

```bash
dart pub add dependency_box
# or for Flutter
flutter pub add dependency_box
```

### Supported SDK

- **Dart SDK**: `>=3.0.0 <4.0.0`
- **Platforms**: Android, iOS, Windows, macOS, Linux, and Web (JS & WASM)

### Import

```dart
import 'package:dependency_box/dependency_box.dart';
```

---

## 🚀 Quick Start: Zero `<Type>` Boilerplate

In most dependency injection containers, you are forced to type class names repeatedly in angle brackets (`<Config>`, `<Client>`, `<Repository>`).

With `dependency_box`, Dart's bidirectional type inference automatically discovers types from values, closure signatures, and constructor parameters:

```dart
import 'package:dependency_box/dependency_box.dart';

class ApiConfig {
  const ApiConfig(this.baseUrl);
  final String baseUrl;
}

class ApiClient {
  ApiClient(this.config);
  final ApiConfig config;
}

class UserRepository {
  UserRepository(this.client);
  final ApiClient client;

  String fetchUser(String id) => 'User $id from ${client.config.baseUrl}';
}

void main() {
  final dbox = DependencyBox.main();

  // 1. Inferred Registrations: No <Type> brackets needed anywhere!
  dbox.addSingleton(const ApiConfig('https://api.example.com'));
  dbox.addLazySingleton((dbox) => ApiClient(dbox.get()));
  dbox.addFactory((dbox) => UserRepository(dbox.get()));

  // 2. Inferred Resolution: Inferred directly from the variable type
  final UserRepository userRepo = dbox.get();
  print(userRepo.fetchUser('42')); // User 42 from https://api.example.com
}
```

### The Difference: Traditional DI vs. `dependency_box`

| Traditional Container | `dependency_box` (Inferred) |
| :--- | :--- |
| `dbox.addSingleton<ApiConfig>(config);` | `dbox.addSingleton(config);` |
| `dbox.addLazySingleton<ApiClient>((dbox) => ApiClient(dbox.get<ApiConfig>()));` | `dbox.addLazySingleton((dbox) => ApiClient(dbox.get()));` |
| `dbox.addFactory<UserRepository>((dbox) => UserRepository(dbox.get<ApiClient>()));` | `dbox.addFactory((dbox) => UserRepository(dbox.get()));` |
| `final repo = dbox.get<UserRepository>();` | `final UserRepository repo = dbox.get();` |

---

## 💡 Mastering Type Inference

Dart uses **bidirectional type inference**. This means context flows **downward** into expressions as well as **upward** from values. `dependency_box` is designed around this capability so you never have to manually specify type arguments.

Here are the 8 primary patterns where you can omit types completely:

### Pattern 1: Nested Constructor Injection (`dbox.get()`)

When registering a class inside a factory closure, Dart inspects the constructor's parameter types. Each `dbox.get()` automatically resolves the exact type the constructor expects:

```dart
class OrderService {
  OrderService(this.users, this.client);
  final UserRepository users;
  final ApiClient client;
}

// dbox.get() infers UserRepository for the 1st parameter and ApiClient for the 2nd!
dbox.addLazySingleton((dbox) => OrderService(dbox.get(), dbox.get()));
```

### Pattern 2: Named Constructor Parameters

Dart also infers types through named parameters:

```dart
class PaymentGateway {
  PaymentGateway({required this.config, required this.client});
  final ApiConfig config;
  final ApiClient client;
}

// Inferred through named parameter signatures:
dbox.addFactory((dbox) => PaymentGateway(
  config: dbox.get(), // Inferred as ApiConfig
  client: dbox.get(), // Inferred as ApiClient
));
```

### Pattern 3: Typed Local Variables

When resolving an instance, simply declare the variable type. Dart propagates that type downward into `dbox.get()`:

```dart
// The return type of get() is inferred as UserRepository:
final UserRepository repo = dbox.get();

// Works identically with mutable variables:
late final ApiClient client;
client = dbox.get();
```

### Pattern 4: Direct Function & Constructor Arguments

Passing `dbox.get()` directly as an argument to a function or constructor eliminates the variable declaration and generic parameter entirely:

```dart
void startServer(ApiConfig config, ApiClient client) {
  print('Starting server for ${config.baseUrl}');
}

// Both types are inferred from startServer's signature:
startServer(dbox.get(), dbox.get());
```

### Pattern 5: Typed Getters & Service Locators

If you encapsulate access to your container within a helper class, typed getters eliminate all generics:

```dart
class AppServices {
  AppServices(this.dbox);
  final DependencyBox dbox;

  ApiConfig get config => dbox.get();
  ApiClient get client => dbox.get();
  UserRepository get users => dbox.get();
}

final services = AppServices(dbox);
print(services.config.baseUrl);
```

### Pattern 6: Direct Collection Inferences (`getAll()`)

When retrieving all instances of a multi-registered type, the list type parameter drives the resolution:

```dart
abstract interface class AppPlugin {
  void init();
}

// Resolves all AppPlugin instances without dbox.getAll<AppPlugin>():
final List<AppPlugin> plugins = dbox.getAll();
for (final plugin in plugins) {
  plugin.init();
}
```

### Pattern 7: Nullable Optional Resolution (`tryGet()`)

When resolving optional dependencies that may or may not be registered, declare a nullable variable:

```dart
// Inferred as ApiConfig? (returns null if unregistered instead of throwing):
final ApiConfig? optionalConfig = dbox.tryGet();
if (optionalConfig != null) {
  print('Base URL: ${optionalConfig.baseUrl}');
}
```

### Pattern 8: Asynchronous Resolution (`getAsync()`)

When resolving an asynchronous singleton, the awaited variable type provides the context:

```dart
// Inferred as DatabaseConnection:
final DatabaseConnection db = await dbox.getAsync();
```

---

## ⏳ Registration Lifetimes with Inferred Types

`dependency_box` supports 5 distinct registration lifetimes. All 5 support full type inference.

### 1. Eager Singleton (`addSingleton`)

Instantiated immediately at registration time. The registered type `T` is inferred from the instance:

```dart
// T inferred as ApiConfig:
dbox.addSingleton(const ApiConfig('https://api.example.com'));

// Resolve:
final ApiConfig config = dbox.get();
```

### 2. Lazy Singleton (`addLazySingleton`)

Instantiated once on first access and cached for the container's lifetime:

```dart
// T inferred as ApiClient, dbox.get() infers ApiConfig:
dbox.addLazySingleton((dbox) => ApiClient(dbox.get()));

final ApiClient client1 = dbox.get();
final ApiClient client2 = dbox.get();
assert(identical(client1, client2));
```

### 3. Transient Factory (`addFactory`)

Produces a new instance on every resolution:

```dart
// T inferred as UserRepository, dbox.get() infers ApiClient:
dbox.addFactory((dbox) => UserRepository(dbox.get()));

final UserRepository repo1 = dbox.get();
final UserRepository repo2 = dbox.get();
assert(!identical(repo1, repo2));
```

### 4. Parameterized Factory (`addFactoryWith`)

Produces a new instance using runtime call-site arguments passed via `dbox.get(args: ...)`:

```dart
class UserSession {
  UserSession(this.sessionId, this.client);
  final String sessionId;
  final ApiClient client;
}

// Types <UserSession, String> inferred from closure parameters:
dbox.addFactoryWith((dbox, String sessionId) => UserSession(sessionId, dbox.get()));

// Resolve with runtime arguments:
final UserSession session = dbox.get(args: 'session_token_xyz');
print(session.sessionId); // session_token_xyz
```

### 5. Asynchronous Singleton (`addAsyncSingleton` & `getAsync`)

For resources requiring asynchronous initialization (e.g. storage, credentials, remote configuration):

```dart
// T inferred as String:
dbox.addAsyncSingleton((dbox) async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
  return 'secret_jwt_token';
});

// Await async resolution:
final String token = await dbox.getAsync();
print(token); // secret_jwt_token

// Synchronous resolution once initialized:
final String cachedToken = dbox.get();
assert(identical(token, cachedToken));
```

### 6. Weak-Reference Cached Factory (`addCachedFactory`)

An auto-expiring temporary singleton that retains its instance using Dart's `WeakReference`. The instance acts as a singleton as long as active callers retain a strong reference to it. Once all references are dropped and garbage collection runs, it is automatically re-created on next access:

```dart
// Auto-expiring temporary singleton:
dbox.addCachedFactory((dbox) => HeavyImageCache());

// First call creates the cache:
final HeavyImageCache cache1 = dbox.get();

// While cache1 is held, returns identical instance:
final HeavyImageCache cache2 = dbox.get();
assert(identical(cache1, cache2));

// Once cache1 and cache2 are out of scope and GC runs,
// subsequent dbox.get() automatically re-instantiates a fresh cache.
```

---

## 🏗️ Dependency Injection in Practice

### Multi-Tier Architecture: Zero `<Type>` Declarations

Here is a realistic, multi-tier application architecture (Configuration -> Database -> DataSource -> Repository -> UseCase -> Controller) registered and resolved entirely with inferred types:

```dart
import 'dart:async';
import 'package:dependency_box/dependency_box.dart';

class DatabaseConfig {
  const DatabaseConfig(this.host, this.port);
  final String host;
  final int port;
}

class DatabaseConnection implements DependencyDisposable {
  DatabaseConnection(this.config);
  final DatabaseConfig config;
  bool isClosed = false;

  @override
  Future<void> dispose() async {
    isClosed = true;
    print('Database disconnected');
  }
}

class UserRemoteDataSource {
  UserRemoteDataSource(this.db);
  final DatabaseConnection db;

  String queryUser(String id) => 'User $id from ${db.config.host}';
}

class UserRepository {
  UserRepository(this.dataSource);
  final UserRemoteDataSource dataSource;

  String getUser(String id) => dataSource.queryUser(id);
}

class GetUserProfileUseCase {
  GetUserProfileUseCase(this.repository);
  final UserRepository repository;

  String execute(String id) => repository.getUser(id);
}

class ProfileController {
  ProfileController(this.useCase);
  final GetUserProfileUseCase useCase;

  void showProfile(String id) => print(useCase.execute(id));
}

void main() async {
  final dbox = DependencyBox.main();

  // Wire the complete 6-tier dependency graph with ZERO <Type> generics:
  dbox.addSingleton(const DatabaseConfig('postgres.internal', 5432));
  dbox.addLazySingleton((dbox) => DatabaseConnection(dbox.get()));
  dbox.addLazySingleton((dbox) => UserRemoteDataSource(dbox.get()));
  dbox.addLazySingleton((dbox) => UserRepository(dbox.get()));
  dbox.addLazySingleton((dbox) => GetUserProfileUseCase(dbox.get()));
  dbox.addFactory((dbox) => ProfileController(dbox.get()));

  // Resolve the root controller:
  final ProfileController controller = dbox.get();
  controller.showProfile('1001'); // User 1001 from postgres.internal

  // Clean disposal of disposable dependencies:
  await dbox.dispose();
}
```

### Flutter & UI Integration

In Flutter, pass `dbox.get()` directly to widget constructors or state management providers without specifying generic parameters:

```dart
// Composition Root in main.dart:
void main() {
  final dbox = DependencyBox.main();

  dbox.addSingleton(const ApiConfig('https://api.example.com'));
  dbox.addLazySingleton((dbox) => ApiClient(dbox.get()));
  dbox.addLazySingleton((dbox) => UserRepository(dbox.get()));
  dbox.addFactory((dbox) => ProfileController(dbox.get()));

  // Passing directly into Flutter widget tree:
  runApp(MyApp(
    controller: dbox.get(), // Inferred as ProfileController!
  ));
}

// In UI Widget:
class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.controller});
  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => controller.showProfile('42'),
            child: const Text('Load Profile'),
          ),
        ),
      ),
    );
  }
}
```

### Modular Feature Composition (`DependencyModule`)

Group related registrations into modular units:

```dart
class AuthModule implements DependencyModule {
  @override
  void register(DependencyBox dbox) {
    dbox.addSingleton('https://auth.example.com', key: 'auth_url');
    dbox.addLazySingleton((dbox) => ApiClient(ApiConfig(dbox.get(key: 'auth_url'))));
  }
}

void main() {
  final dbox = DependencyBox.main();
  dbox.install(AuthModule());

  final ApiClient client = dbox.get();
  print(client.config.baseUrl); // https://auth.example.com
}
```

---

## ⚙️ Advanced Scenarios with Inferred Types

### 1. Qualified Keys (Enums & Symbols)

Qualify registrations by type-safe `Enum`s or `Symbol`s, keeping types inferred:

```dart
enum Environment { production, development }

dbox.addSingleton(
  const ApiConfig('https://api.prod.example.com'),
  key: Environment.production,
);

dbox.addSingleton(
  const ApiConfig('https://api.dev.example.com'),
  key: Environment.development,
);

// Inferred from variable type:
final ApiConfig prod = dbox.get(key: Environment.production);
final ApiConfig dev = dbox.get(key: Environment.development);

print(prod.baseUrl); // https://api.prod.example.com
print(dev.baseUrl);  // https://api.dev.example.com
```

### 2. Multi-Instance Collections (`allowMulti` & `getAll`)

Register multiple instances of a type and resolve them as a collection:

```dart
abstract interface class AppPlugin {
  String get name;
}

class AnalyticsPlugin implements AppPlugin {
  @override
  String get name => 'analytics';
}

class LoggingPlugin implements AppPlugin {
  @override
  String get name => 'logging';
}

void main() {
  final dbox = DependencyBox.main();

  // Enable multi-registration for AppPlugin
  dbox.allowMulti<AppPlugin>();

  // Register a typed list of implementations:
  final plugins = <AppPlugin>[
    AnalyticsPlugin(),
    LoggingPlugin(),
  ];
  dbox.addSingletons(plugins); // Inferred as AppPlugin from the list!

  // Resolve all plugins with inferred List<AppPlugin>:
  final List<AppPlugin> activePlugins = dbox.getAll();
  for (final plugin in activePlugins) {
    print(plugin.name); // 'analytics', 'logging'
  }
}
```

### 3. Hierarchical Child Scopes

Create scoped sub-containers (e.g. for user sessions, tenant contexts, or HTTP requests) that inherit parent registrations:

```dart
final rootDbox = DependencyBox.main(name: 'root');
rootDbox.addSingleton(const ApiConfig('https://api.example.com'));
rootDbox.addLazySingleton((dbox) => ApiClient(dbox.get()));

// Create child scope for an active user request:
final requestScope = rootDbox.createChild(name: 'request_99');
requestScope.addSingleton(RequestContext('req-99', 'user-42'));
requestScope.addFactory((dbox) => RequestLogger(dbox.get(), dbox.get()));

// Inferred resolution inside the child scope:
final RequestLogger logger = requestScope.get();
print(logger.context.requestId); // req-99
print(logger.client.config.baseUrl); // https://api.example.com (inherited from root)

// Disposing the child scope leaves rootDbox intact:
await requestScope.dispose();
assert(requestScope.isDisposed);
assert(!rootDbox.isDisposed);
```

#### Shared Registrations Across Scopes (`addShared*`)

Need a dependency registered from a nested feature module or child scope to be shared globally across all scopes without holding onto the child scope's lifecycle?

Shared registrations are automatically anchored to the root container:

```dart
final root = DependencyBox.main();
final featureScope = root.createChild();

// Registered from child, but anchored to root:
featureScope.addSharedSingleton(AnalyticsService());
featureScope.addSharedLazySingleton((dbox) => AuthService(dbox.get()));
featureScope.addSharedCachedFactory((dbox) => SharedMediaCache());

// Available in root and any sibling/child scopes:
final otherScope = root.createChild();
final AuthService auth = otherScope.get(); // Resolved from root!

// Disposing featureScope leaves the shared instances intact in root:
await featureScope.dispose();
assert(root.contains<AuthService>());
```

### 4. Lifecycle Management & Automatic Disposal

#### `DependencyDisposable` Interface

Classes implementing `DependencyDisposable` are cleaned up automatically when the container or scope is disposed:

```dart
class DatabaseConnection implements DependencyDisposable {
  bool isClosed = false;

  @override
  Future<void> dispose() async {
    isClosed = true;
    print('Database connection closed cleanly.');
  }
}

dbox.addSingleton(DatabaseConnection());
await dbox.dispose(); // Automatically triggers dispose()
```

#### Inline `onDispose` Hooks

For classes you don't control, supply an inline disposal callback:

```dart
dbox.addSingleton(
  ApiClient(const ApiConfig('https://api.example.com')),
  onDispose: (client) => client.close(),
);

await dbox.dispose(); // Runs inline callback
```

> **Identity Deduplication**: If an identical object is registered under multiple keys or types, `dependency_box` deduplicates cleanup using object identity (`Set.identity`), guaranteeing `dispose()` runs exactly once.

### 5. Unit Testing and Mock Overrides

Replace registered services in unit tests without changing application code:

```dart
class MockApiClient implements ApiClient {
  @override
  ApiConfig get config => const ApiConfig('https://mock.example.com');

  @override
  bool isClosed = false;

  @override
  void close() {}
}

void main() {
  final dbox = DependencyBox.main();
  dbox.addSingleton(const ApiConfig('https://api.example.com'));
  dbox.addLazySingleton((dbox) => ApiClient(dbox.get()));
  dbox.addFactory((dbox) => UserRepository(dbox.get()));

  // In your test: override with mock using interface variable type
  ApiClient mock = MockApiClient();
  dbox.replaceSingleton(mock, disposeOld: true);

  // Inferred resolution uses the mock:
  final UserRepository repo = dbox.get();
  print(repo.fetchUser('1')); // User 1 from https://mock.example.com
}
```

### 6. Container Diagnostics (`printContainer`)

Inspect the entire container hierarchy, active/disposed status, registrations, lifecycle kinds, instance states, and multi-registrations as a formatted ASCII tree:

```dart
dbox.printContainer();
```

Output:
```text
DependencyBox: 'FeatureScope' [active]
├── Hierarchy: 'FeatureScope' -> 'RootScope'
├── Direct Registrations (2):
│   ├── String (key: 'apiUrl') -> Singleton (instance: "https://api.example.com")
│   └── HeavyController -> CachedFactory [cached: Instance of 'HeavyController']
└── Inherited Registrations (1):
    └── AuthService -> LazySingleton [initialized: Instance of 'AuthService'] (from 'RootScope')
```

---

## Lifetimes and Behavior

| Lifetime Mode | Registered Via | Instantiation | Reused / Cached | Cleanup on `dispose()` | Typical Use Cases |
| :--- | :--- | :--- | :---: | :---: | :--- |
| **Eager Singleton** | `addSingleton` | Immediate (call-site) | Yes | Yes (if initialized) | App configurations, global loggers, pre-created singletons |
| **Lazy Singleton** | `addLazySingleton` | First `get<T>()` access | Yes | Yes (if initialized) | Services, repositories, HTTP clients, expensive singletons |
| **Cached Factory** | `addCachedFactory` | First access / post-GC | While retained | Yes (if alive) | Temporary singletons, media caches, memory-sensitive heavy objects |
| **Transient Factory** | `addFactory` | Every `get<T>()` access | No | No | State controllers, BLoCs, use-cases, command objects |
| **Parameterized Factory** | `addFactoryWith` | Every `get<T>(args:)` | No | No | Entity controllers, session handlers, argument-dependent models |
| **Async Singleton** | `addAsyncSingleton` | First `getAsync<T>()` | Yes | Yes (if initialized) | Disk storage (Hive/Isar), remote configs, async token handshakes |

---

## Scopes and Resolution Rules

1. **Hierarchy**: Child containers are created via `dbox.createChild({String? name})`. A child holds a reference to its parent, creating an arbitrary scope tree.
2. **Lookup Precedence**:
   - The container checks its direct registrations first.
   - If not found locally, the query delegates up the parent chain.
   - If no registration is found at the root, a `StateError` is thrown.
3. **Shadowing**: A child registration of type `T` shadows the parent's registration of `T` within that child and its descendants, leaving the parent container unmodified.
4. **Disposal Isolation**:
   - Disposing a child container (`await child.dispose()`) disposes child-registered instances only. The parent container remains completely active.
   - Once disposed, a container rejects subsequent resolutions and registrations with a `StateError`.

---

## Error Handling and Edge Cases

- **Missing Registration**: Calling `dbox.get<T>()` on an unregistered type throws a descriptive `StateError`:

  ```
  StateError: No registration found for type T with key "k"
  ```

  Use `dbox.tryGet<T>()` to safely resolve optional dependencies.
- **Duplicate Registrations**: Registering the same type/key twice without configuring `allowMulti<T>()` triggers an `AssertionError` in debug mode. In test suites, use `replaceSingleton()` instead.
- **Synchronous Cycle Detection**: If lazy singletons form a circular dependency (`A -> B -> A`), `dependency_box` detects reentrancy and throws a `StateError`:

  ```
  StateError: Circular dependency detected in synchronous lazy resolution: A
  ```

- **Asynchronous Cycle Detection**: If async singletons form a cycle (`A -> B -> A`), `dependency_box` detects the cycle via zone tracking and rejects the future with:

  ```
  StateError: Circular dependency detected in async resolution: A -> B -> A
  ```

- **Async Deduplication & Retry**: Concurrent callers resolving the same async singleton await the exact same `Future`. If the factory throws an error, the failure is propagated to all waiting callers, and the internal state resets so subsequent calls can retry resolution.
- **Disposed Container Protection**: Calling `get`, `createChild`, or registration methods on a disposed container immediately throws a `StateError('Cannot ... on a disposed DependencyBox')`.

---

## ⚡ Performance

`dependency_box` is designed around a low-overhead dependency resolution path:

1. **Zero-Allocation Hot Path**: When registering and resolving unkeyed dependencies (the standard use case), `dependency_box` uses the `Type` literal directly as the lookup key. No intermediate wrapper objects are instantiated during resolution.
2. **Direct Hash Lookups**: Resolutions are backed by standard Dart hash maps optimized for rapid identity lookup without intermediate lock or reflection layers.
3. **Optimized Multi-Lifecycles**: Eager singletons, lazy instances, weak-reference caches, and transient factories all execute through specialized, dedicated resolution paths.

### Head-to-Head Benchmarks: `dependency_box` vs. `get_it 9.3.0`

Compared with `get_it 9.3.0` and `injectable 3.0.0` under identical test workloads on the Dart VM (Dart SDK 3.13.4, Windows x64):

| Benchmark Scenario | `dependency_box` | `get_it 9.3.0` | Speedup |
| :--- | :---: | :---: | :---: |
| **Singleton Resolution** | **12.96 ns/op** | 281.45 ns/op | **21.71× faster** |
| **Keyed / Named Singleton** | **17.63 ns/op** | 330.86 ns/op | **18.77× faster** |
| **Deep Hierarchy Graph (5 layers)** | **17.47 ns/op** | 292.66 ns/op | **16.75× faster** |
| **Cached LazySingleton** | **17.48 ns/op** | 284.57 ns/op | **16.28× faster** |
| **Cached Weak-Reference Factory** | **17.65 ns/op** | 286.89 ns/op | **16.26× faster** |
| **Factory Creation** | **18.27 ns/op** | 286.05 ns/op | **15.66× faster** |
| **Parameterized Factory** | **26.52 ns/op** | 328.04 ns/op | **12.37× faster** |
| **Child Scope Resolution** | **25.06 ns/op** | 286.20 ns/op | **11.42× faster** |
| **Mass Setup (1,000 Keyed Singletons)** | **94.54 µs** | 411.23 µs | **4.35× faster** |
| **Setup Overhead (100 Dependencies)** | **11.60 µs** | 45.13 µs *(injectable: 45.15 µs)* | **3.89× faster** |

---

### Real-World Architectural Workloads

Synthetic microbenchmarks measure raw single-instruction lookup speed. To evaluate end-to-end impact on real applications, six production architecture scenarios were measured:

Reported benchmark results show `dependency_box` performing **3.77×–18.83× faster** across the tested common real-world DI workloads, with a specialized weak-reference cache scenario reaching **63.72×**.

| Production Scenario | `dependency_box` | `get_it 9.3.0` | Throughput (`dependency_box`) | Speedup |
| :--- | :---: | :---: | :---: | :---: |
| **Screen Navigation & ViewModel** | **63.05 ns/op** | 1,187.41 ns/op | 15.86M ops/s | **18.83× faster** |
| **Interleaved Mixed Production** *(50% S, 25% F, 15% K, 10% P)* | **144.86 ns/op** | 2,388.22 ns/op | 6.90M ops/s | **16.49× faster** |
| **Plugin / Interceptor Pipeline** *(6 handlers)* | **53.99 ns/op** | 342.70 ns/op | 18.52M ops/s | **6.35× faster** |
| **Cold App Startup** *(50 registered, 15 resolved)* | **7.14 µs/boot** | 42.31 µs *(inj: 44.50 µs)* | 140,123 boots/s | **5.93× faster** |
| **Scoped Feature / Wizard Session** | **4.69 µs/session** | 17.68 µs/session | 213,068 sessions/s | **3.77× faster** |
| **Weak-Reference Screen Asset Cache** *(Specialized Cache)* | **15.93 ns/op** | 1,015.32 ns/op | 62.76M ops/s | **63.72× faster** |

> [!NOTE]
> **Technical Context & Methodology**
> - Benchmarks were run on Dart SDK 3.13.4 on Windows x64. Results are workload-specific and may vary by Dart version, platform, hardware, and benchmark implementation.
> - `injectable` generates registration code for `get_it`; runtime dependency resolution is performed by `get_it`.
> - Benchmark suites and harness sources are available in [`tool/comparison_benchmark/`](tool/comparison_benchmark/).

---

## 📱 Complete Example

A complete, end-to-end application demonstrating configurations, services, repositories, async initialization, child scopes, and disposal with clean type inference:

```dart
import 'dart:async';
import 'package:dependency_box/dependency_box.dart';

class ApiConfig {
  const ApiConfig(this.baseUrl);
  final String baseUrl;
}

class ApiClient {
  ApiClient(this.config);
  final ApiConfig config;
  bool isClosed = false;

  void close() {
    isClosed = true;
    print('ApiClient closed.');
  }
}

class UserRepository {
  UserRepository(this.client);
  final ApiClient client;

  Future<String> fetchUser(String id) async =>
      'User $id from ${client.config.baseUrl}';
}

class DatabaseService implements DependencyDisposable {
  bool isConnected = false;

  Future<void> connect() async {
    isConnected = true;
    print('Database connected.');
  }

  @override
  FutureOr<void> dispose() {
    isConnected = false;
    print('Database connection closed cleanly.');
  }
}

void main() async {
  final dbox = DependencyBox.main(name: 'app_root');

  // 1. Eager configuration (type is inferred from the instance)
  dbox.addSingleton(const ApiConfig('https://api.example.com'));

  // 2. Lazy singleton (dbox.get() infers ApiConfig from ApiClient constructor!)
  dbox.addLazySingleton(
    (dbox) => ApiClient(dbox.get()),
    onDispose: (client) => client.close(),
  );

  // 3. Disposable resource implementing DependencyDisposable
  final db = DatabaseService();
  await db.connect();
  dbox.addSingleton(db);

  // 4. Asynchronous singleton for auth credentials
  dbox.addAsyncSingleton((dbox) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return 'session_bearer_token_xyz';
  });

  // 5. Factory for repositories (dbox.get() infers ApiClient!)
  dbox.addFactory((dbox) => UserRepository(dbox.get()));

  // Resolve and use dependencies using inferred types
  final UserRepository userRepo = dbox.get();
  final user = await userRepo.fetchUser('101');
  print(user); // User 101 from https://api.example.com

  final String token = await dbox.getAsync();
  print('Auth token: $token');

  // 6. Hierarchical child scope for a user session
  final sessionScope = dbox.createChild(name: 'session_101');
  sessionScope.addSingleton('user_101_settings', key: 'settings');

  final ApiConfig inheritedConfig = sessionScope.get();
  final String sessionSettings = sessionScope.get(key: 'settings');
  print('Scope resolved parent config: ${inheritedConfig.baseUrl}');
  print('Scope resolved local settings: $sessionSettings');

  // Dispose scoped session (parent remains intact)
  await sessionScope.dispose();
  print('Session scope disposed. Root isDisposed: ${dbox.isDisposed}'); // false

  // 7. Dispose root container
  await dbox.dispose();
  print('Root dbox disposed. Root isDisposed: ${dbox.isDisposed}'); // true
}
```

---

## 📖 API Reference

| Method | Return Type | Description |
| :--- | :--- | :--- |
| `DependencyBox.main({String? name})` | `DependencyBox` | Creates a new root container. |
| `DependencyBox.child({required parent, String? name})` | `DependencyBox` | Creates a child container linked to [parent]. |
| `dbox.createChild({String? name})` | `DependencyBox` | Spawns a child container inheriting registrations from [dbox]. |
| `dbox.addSingleton<T>(instance, {key, onDispose})` | `void` | Registers an eager singleton. [T] inferred from [instance]. |
| `dbox.addLazySingleton<T>(factory, {key, onDispose})` | `void` | Registers a lazy singleton. [T] inferred from [factory]. |
| `dbox.addFactory<T>(factory, {key})` | `void` | Registers a transient factory. [T] inferred from [factory]. |
| `dbox.addFactoryWith<T, A>(factory, {key})` | `void` | Registers a factory taking runtime arguments of type `A`. |
| `dbox.addAsyncSingleton<T>(factory, {key, onDispose})` | `void` | Registers an async singleton. [T] inferred from [factory]. |
| `dbox.addSingletons<T>(instances, {key})` | `void` | Registers multiple instances of type `T`. Requires `allowMulti`. |
| `dbox.allowMulti<T>({resolution})` | `void` | Enables multi-registration for type `T` with a resolution strategy. |
| `dbox.allowMultiple(types)` | `void` | Enables multi-registration for an iterable of `MultiRegistration` specifications. |
| `dbox.replaceSingleton<T>(instance, {key, disposeOld})` | `void` | Replaces a registration cleanly for tests. |
| `dbox.remove<T>({key, dispose})` | `Future<bool>` | Removes a registration and optionally disposes its instance. |
| `dbox.get<T>({args, key})` | `T` | Resolves instance of type `T`. Inferred from call-site context. |
| `dbox.tryGet<T>({args, key})` | `T?` | Resolves instance of type `T` or returns `null` if not found. |
| `dbox.getAsync<T>({args, key})` | `Future<T>` | Asynchronously resolves instance of type `T`. |
| `dbox.tryGetAsync<T>({args, key})` | `Future<T?>` | Asynchronously resolves instance of type `T` or returns `null`. |
| `dbox.getAll<T>({args, key})` | `List<T>` | Returns all registered instances of type `T`. |
| `dbox.getAllAsync<T>({args, key})` | `Future<List<T>>` | Asynchronously returns all registered instances of type `T`. |
| `dbox.contains<T>({key})` | `bool` | Checks if type `T` is registered locally or in parent scopes. |
| `dbox.registeredKeys` | `Iterable<Object>` | Returns all registered keys (including parent keys). |
| `dbox.length` | `int` | The number of direct registrations in this container. |
| `dbox.isDisposed` | `bool` | Returns `true` if this container has been disposed. |
| `dbox.dispose()` | `Future<void>` | Disposes all instances and clears registrations. |
| `dbox.install(module)` | `void` | Installs a `DependencyModule`. |
| `dbox.installAll(modules)` | `void` | Installs an iterable of `DependencyModule`s. |

---

## Supporting & Contributing

If you find `dependency_box` helpful, here are several ways you can support the project:

### 🌟 Community Support

- **Star the Repository**: Star [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages) on GitHub to help others discover it.
- **Report Issues & Ideas**: Found a bug or need an improvement? Open an issue on [GitHub Issues](https://github.com/ahmedm-gh/dart-packages/issues).
- **Contribute**: Pull requests for optimizations, documentation, or examples are always welcome.
- **Spread the Word**: Recommend `dependency_box` in your Flutter/Dart teams, blogs, or communities.

### ☕ Sponsorship & Backing

- **Sponsor on GitHub**: If this package brings value to your commercial apps, consider supporting its maintenance via [GitHub Sponsors](https://github.com/sponsors/ahmedm-gh).
- **Buy Me a Coffee**: Support development with a one-time coffee or recurring donation via [Buy Me a Coffee](https://buymeacoffee.com/ahmeds1).

## Author & Maintainer

Created and maintained by **[AHMED M.](https://github.com/ahmedm-gh)**  

- GitHub: [@ahmedm-gh](https://github.com/ahmedm-gh)
- Repository: [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages)

## License

This package is licensed under the [MIT License](./LICENSE).
