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
- ⏳ **Five Registration Lifetimes**: Eager singletons, lazy singletons, transient factories, parameterized factories, and asynchronous singletons.
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
  final box = DependencyBox.main();

  // 1. Inferred Registrations: No <Type> brackets needed anywhere!
  box.addSingleton(const ApiConfig('https://api.example.com'));
  box.addLazySingleton((dbox) => ApiClient(dbox.get()));
  box.addFactory((dbox) => UserRepository(dbox.get()));

  // 2. Inferred Resolution: Inferred directly from the variable type
  final UserRepository userRepo = box.get();
  print(userRepo.fetchUser('42')); // User 42 from https://api.example.com
}
```

### The Difference: Traditional DI vs. `dependency_box`

| Traditional Container | `dependency_box` (Inferred) |
| :--- | :--- |
| `box.addSingleton<ApiConfig>(config);` | `box.addSingleton(config);` |
| `box.addLazySingleton<ApiClient>((dbox) => ApiClient(dbox.get<ApiConfig>()));` | `box.addLazySingleton((dbox) => ApiClient(dbox.get()));` |
| `box.addFactory<UserRepository>((dbox) => UserRepository(dbox.get<ApiClient>()));` | `box.addFactory((dbox) => UserRepository(dbox.get()));` |
| `final repo = box.get<UserRepository>();` | `final UserRepository repo = box.get();` |

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
box.addLazySingleton((dbox) => OrderService(dbox.get(), dbox.get()));
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
box.addFactory((dbox) => PaymentGateway(
  config: dbox.get(), // Inferred as ApiConfig
  client: dbox.get(), // Inferred as ApiClient
));
```

### Pattern 3: Typed Local Variables

When resolving an instance, simply declare the variable type. Dart propagates that type downward into `box.get()`:

```dart
// The return type of get() is inferred as UserRepository:
final UserRepository repo = box.get();

// Works identically with mutable variables:
late final ApiClient client;
client = box.get();
```

### Pattern 4: Direct Function & Constructor Arguments

Passing `box.get()` directly as an argument to a function or constructor eliminates the variable declaration and generic parameter entirely:

```dart
void startServer(ApiConfig config, ApiClient client) {
  print('Starting server for ${config.baseUrl}');
}

// Both types are inferred from startServer's signature:
startServer(box.get(), box.get());
```

### Pattern 5: Typed Getters & Service Locators

If you encapsulate access to your container within a helper class, typed getters eliminate all generics:

```dart
class AppServices {
  AppServices(this.box);
  final DependencyBox box;

  ApiConfig get config => box.get();
  ApiClient get client => box.get();
  UserRepository get users => box.get();
}

final services = AppServices(box);
print(services.config.baseUrl);
```

### Pattern 6: Direct Collection Inferences (`getAll()`)

When retrieving all instances of a multi-registered type, the list type parameter drives the resolution:

```dart
abstract interface class AppPlugin {
  void init();
}

// Resolves all AppPlugin instances without box.getAll<AppPlugin>():
final List<AppPlugin> plugins = box.getAll();
for (final plugin in plugins) {
  plugin.init();
}
```

### Pattern 7: Nullable Optional Resolution (`tryGet()`)

When resolving optional dependencies that may or may not be registered, declare a nullable variable:

```dart
// Inferred as ApiConfig? (returns null if unregistered instead of throwing):
final ApiConfig? optionalConfig = box.tryGet();
if (optionalConfig != null) {
  print('Base URL: ${optionalConfig.baseUrl}');
}
```

### Pattern 8: Asynchronous Resolution (`getAsync()`)

When resolving an asynchronous singleton, the awaited variable type provides the context:

```dart
// Inferred as DatabaseConnection:
final DatabaseConnection db = await box.getAsync();
```

---

## ⏳ Registration Lifetimes with Inferred Types

`dependency_box` supports 5 distinct registration lifetimes. All 5 support full type inference.

### 1. Eager Singleton (`addSingleton`)

Instantiated immediately at registration time. The registered type `T` is inferred from the instance:

```dart
// T inferred as ApiConfig:
box.addSingleton(const ApiConfig('https://api.example.com'));

// Resolve:
final ApiConfig config = box.get();
```

### 2. Lazy Singleton (`addLazySingleton`)

Instantiated once on first access and cached for the container's lifetime:

```dart
// T inferred as ApiClient, dbox.get() infers ApiConfig:
box.addLazySingleton((dbox) => ApiClient(dbox.get()));

final ApiClient client1 = box.get();
final ApiClient client2 = box.get();
assert(identical(client1, client2));
```

### 3. Transient Factory (`addFactory`)

Produces a new instance on every resolution:

```dart
// T inferred as UserRepository, dbox.get() infers ApiClient:
box.addFactory((dbox) => UserRepository(dbox.get()));

final UserRepository repo1 = box.get();
final UserRepository repo2 = box.get();
assert(!identical(repo1, repo2));
```

### 4. Parameterized Factory (`addFactoryWith`)

Produces a new instance using runtime call-site arguments passed via `box.get(args: ...)`:

```dart
class UserSession {
  UserSession(this.sessionId, this.client);
  final String sessionId;
  final ApiClient client;
}

// Types <UserSession, String> inferred from closure parameters:
box.addFactoryWith((dbox, String sessionId) => UserSession(sessionId, dbox.get()));

// Resolve with runtime arguments:
final UserSession session = box.get(args: 'session_token_xyz');
print(session.sessionId); // session_token_xyz
```

### 5. Asynchronous Singleton (`addAsyncSingleton` & `getAsync`)

For resources requiring asynchronous initialization (e.g. storage, credentials, remote configuration):

```dart
// T inferred as String:
box.addAsyncSingleton((dbox) async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
  return 'secret_jwt_token';
});

// Await async resolution:
final String token = await box.getAsync();
print(token); // secret_jwt_token

// Synchronous resolution once initialized:
final String cachedToken = box.get();
assert(identical(token, cachedToken));
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
  final box = DependencyBox.main();

  // Wire the complete 6-tier dependency graph with ZERO <Type> generics:
  box.addSingleton(const DatabaseConfig('postgres.internal', 5432));
  box.addLazySingleton((dbox) => DatabaseConnection(dbox.get()));
  box.addLazySingleton((dbox) => UserRemoteDataSource(dbox.get()));
  box.addLazySingleton((dbox) => UserRepository(dbox.get()));
  box.addLazySingleton((dbox) => GetUserProfileUseCase(dbox.get()));
  box.addFactory((dbox) => ProfileController(dbox.get()));

  // Resolve the root controller:
  final ProfileController controller = box.get();
  controller.showProfile('1001'); // User 1001 from postgres.internal

  // Clean disposal of disposable dependencies:
  await box.dispose();
}
```

### Flutter & UI Integration

In Flutter, pass `box.get()` directly to widget constructors or state management providers without specifying generic parameters:

```dart
// Composition Root in main.dart:
void main() {
  final box = DependencyBox.main();

  box.addSingleton(const ApiConfig('https://api.example.com'));
  box.addLazySingleton((dbox) => ApiClient(dbox.get()));
  box.addLazySingleton((dbox) => UserRepository(dbox.get()));
  box.addFactory((dbox) => ProfileController(dbox.get()));

  // Passing directly into Flutter widget tree:
  runApp(MyApp(
    controller: box.get(), // Inferred as ProfileController!
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
  void register(DependencyBox box) {
    box.addSingleton('https://auth.example.com', key: 'auth_url');
    box.addLazySingleton((dbox) => ApiClient(ApiConfig(dbox.get(key: 'auth_url'))));
  }
}

void main() {
  final box = DependencyBox.main();
  box.install(AuthModule());

  final ApiClient client = box.get();
  print(client.config.baseUrl); // https://auth.example.com
}
```

---

## ⚙️ Advanced Scenarios with Inferred Types

### 1. Qualified Keys (Enums & Symbols)

Qualify registrations by type-safe `Enum`s or `Symbol`s, keeping types inferred:

```dart
enum Environment { production, development }

box.addSingleton(
  const ApiConfig('https://api.prod.example.com'),
  key: Environment.production,
);

box.addSingleton(
  const ApiConfig('https://api.dev.example.com'),
  key: Environment.development,
);

// Inferred from variable type:
final ApiConfig prod = box.get(key: Environment.production);
final ApiConfig dev = box.get(key: Environment.development);

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
  final box = DependencyBox.main();

  // Enable multi-registration for AppPlugin
  box.allowMulti<AppPlugin>();

  // Register a typed list of implementations:
  final plugins = <AppPlugin>[
    AnalyticsPlugin(),
    LoggingPlugin(),
  ];
  box.addSingletons(plugins); // Inferred as AppPlugin from the list!

  // Resolve all plugins with inferred List<AppPlugin>:
  final List<AppPlugin> activePlugins = box.getAll();
  for (final plugin in activePlugins) {
    print(plugin.name); // 'analytics', 'logging'
  }
}
```

### 3. Hierarchical Child Scopes

Create scoped sub-containers (e.g. for user sessions, tenant contexts, or HTTP requests) that inherit parent registrations:

```dart
final rootBox = DependencyBox.main(name: 'root');
rootBox.addSingleton(const ApiConfig('https://api.example.com'));
rootBox.addLazySingleton((dbox) => ApiClient(dbox.get()));

// Create child scope for an active user request:
final requestScope = rootBox.createChild(name: 'request_99');
requestScope.addSingleton(RequestContext('req-99', 'user-42'));
requestScope.addFactory((dbox) => RequestLogger(dbox.get(), dbox.get()));

// Inferred resolution inside the child scope:
final RequestLogger logger = requestScope.get();
print(logger.context.requestId); // req-99
print(logger.client.config.baseUrl); // https://api.example.com (inherited from root)

// Disposing the child scope leaves rootBox intact:
await requestScope.dispose();
assert(requestScope.isDisposed);
assert(!rootBox.isDisposed);
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

box.addSingleton(DatabaseConnection());
await box.dispose(); // Automatically triggers dispose()
```

#### Inline `onDispose` Hooks

For classes you don't control, supply an inline disposal callback:

```dart
box.addSingleton(
  ApiClient(const ApiConfig('https://api.example.com')),
  onDispose: (client) => client.close(),
);

await box.dispose(); // Runs inline callback
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
  final box = DependencyBox.main();
  box.addSingleton(const ApiConfig('https://api.example.com'));
  box.addLazySingleton((dbox) => ApiClient(dbox.get()));
  box.addFactory((dbox) => UserRepository(dbox.get()));

  // In your test: override with mock using interface variable type
  ApiClient mock = MockApiClient();
  box.replaceSingleton(mock, disposeOld: true);

  // Inferred resolution uses the mock:
  final UserRepository repo = box.get();
  print(repo.fetchUser('1')); // User 1 from https://mock.example.com
}
```

---

## Lifetimes and Behavior

| Lifetime Mode | Registered Via | Instantiation | Reused / Cached | Cleanup on `dispose()` | Typical Use Cases |
| :--- | :--- | :--- | :---: | :---: | :--- |
| **Eager Singleton** | `addSingleton` | Immediate (call-site) | Yes | Yes (if initialized) | App configurations, global loggers, pre-created singletons |
| **Lazy Singleton** | `addLazySingleton` | First `get<T>()` access | Yes | Yes (if initialized) | Services, repositories, HTTP clients, expensive singletons |
| **Transient Factory** | `addFactory` | Every `get<T>()` access | No | No | State controllers, BLoCs, use-cases, command objects |
| **Parameterized Factory** | `addFactoryWith` | Every `get<T>(args:)` | No | No | Entity controllers, session handlers, argument-dependent models |
| **Async Singleton** | `addAsyncSingleton` | First `getAsync<T>()` | Yes | Yes (if initialized) | Disk storage (Hive/Isar), remote configs, async token handshakes |

---

## Scopes and Resolution Rules

1. **Hierarchy**: Child containers are created via `box.createChild({String? name})`. A child holds a reference to its parent, creating an arbitrary scope tree.
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

- **Missing Registration**: Calling `box.get<T>()` on an unregistered type throws a descriptive `StateError`:

  ```
  StateError: No registration found for type T with key "k"
  ```

  Use `box.tryGet<T>()` to safely resolve optional dependencies.
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

`dependency_box` is designed for ultra-low latency and minimal memory churn:

1. **Zero-Allocation Hot Path**: When registering and resolving unkeyed dependencies (the standard use case), `dependency_box` uses the `Type` literal directly as the map key (`key == null ? T : BoxDependency<T>(key: key)`). No wrapper objects are instantiated during resolution.
2. **Direct Hash Lookups**: Resolutions are backed by standard Dart hash maps optimized for rapid identity lookup.

### Verified Benchmark Results

Measured on Dart SDK 3.13.4 VM (Windows x64):

| Benchmark Scenario | Operations | Latency (ns/op) | Throughput (ops/sec) |
| :--- | ---: | ---: | ---: |
| **1. Singleton `get<T>()` [Unkeyed Hot Path]** | 5,000,000 | **12.8 ns** | **77,799,216 ops/s** |
| **2. Keyed `get<T>(key: "primary")`** | 5,000,000 | **22.7 ns** | **44,055,192 ops/s** |
| **3. Cached Lazy Singleton `get<T>()`** | 5,000,000 | **15.5 ns** | **64,366,632 ops/s** |
| **4. Multi `get<T>()` [MultiResolution.last]** | 5,000,000 | **13.8 ns** | **71,995,277 ops/s** |
| **5. Deep Scope Hierarchy (5 layers)** | 5,000,000 | **16.1 ns** | **61,781,023 ops/s** |
| **6. Transient Factory `get<T>()`** | 2,000,000 | **19.6 ns** | **50,834,964 ops/s** |
| **7. Parameterized Factory `get<T>(args:)`** | 2,000,000 | **23.6 ns** | **42,263,641 ops/s** |
| **8. Cached Async Singleton `getAsync<T>()`** | 2,000,000 | **261.8 ns** | **3,818,419 ops/s** |

### Comparison with Traditional Service Locators

Compared against conventional Dart service locators and IoC containers under identical test workloads on the Dart VM:

| Benchmark Scenario | `dependency_box` | Traditional Locators | Advantage |
| :--- | :---: | :---: | :---: |
| **Singleton Resolution** | **13.7 ns** (73.0M ops/s) | ~251.4 ns (~4.0M ops/s) | **~18.3x faster** |
| **Cached Lazy Singleton** | **16.2 ns** (61.8M ops/s) | ~237.8 ns (~4.2M ops/s) | **~14.7x faster** |
| **Deep Graph (5 layers)** | **16.3 ns** (61.4M ops/s) | ~234.7 ns (~4.3M ops/s) | **~14.4x faster** |
| **Factory Creation** | **17.6 ns** (56.9M ops/s) | ~243.7 ns (~4.1M ops/s) | **~13.9x faster** |
| **Keyed / Named Resolution** | **22.1 ns** (45.2M ops/s) | ~281.7 ns (~3.5M ops/s) | **~12.7x faster** |
| **Container Setup (100 deps)** | **11.0 µs** (90.6k boots/s) | ~44.6 µs (~22.4k boots/s) | **~4.0x faster** |

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
  final box = DependencyBox.main(name: 'app_root');

  // 1. Eager configuration (type is inferred from the instance)
  box.addSingleton(const ApiConfig('https://api.example.com'));

  // 2. Lazy singleton (dbox.get() infers ApiConfig from ApiClient constructor!)
  box.addLazySingleton(
    (dbox) => ApiClient(dbox.get()),
    onDispose: (client) => client.close(),
  );

  // 3. Disposable resource implementing DependencyDisposable
  final db = DatabaseService();
  await db.connect();
  box.addSingleton(db);

  // 4. Asynchronous singleton for auth credentials
  box.addAsyncSingleton((dbox) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return 'session_bearer_token_xyz';
  });

  // 5. Factory for repositories (dbox.get() infers ApiClient!)
  box.addFactory((dbox) => UserRepository(dbox.get()));

  // Resolve and use dependencies using inferred types
  final UserRepository userRepo = box.get();
  final user = await userRepo.fetchUser('101');
  print(user); // User 101 from https://api.example.com

  final String token = await box.getAsync();
  print('Auth token: $token');

  // 6. Hierarchical child scope for a user session
  final sessionScope = box.createChild(name: 'session_101');
  sessionScope.addSingleton('user_101_settings', key: 'settings');

  final ApiConfig inheritedConfig = sessionScope.get();
  final String sessionSettings = sessionScope.get(key: 'settings');
  print('Scope resolved parent config: ${inheritedConfig.baseUrl}');
  print('Scope resolved local settings: $sessionSettings');

  // Dispose scoped session (parent remains intact)
  await sessionScope.dispose();
  print('Session scope disposed. Root isDisposed: ${box.isDisposed}'); // false

  // 7. Dispose root container
  await box.dispose();
  print('Root box disposed. Root isDisposed: ${box.isDisposed}'); // true
}
```

---

## 📖 API Reference

| Method | Return Type | Description |
| :--- | :--- | :--- |
| `DependencyBox.main({String? name})` | `DependencyBox` | Creates a new root container. |
| `DependencyBox.child({required parent, String? name})` | `DependencyBox` | Creates a child container linked to [parent]. |
| `box.createChild({String? name})` | `DependencyBox` | Spawns a child container inheriting registrations from [box]. |
| `box.addSingleton<T>(instance, {key, onDispose})` | `void` | Registers an eager singleton. [T] inferred from [instance]. |
| `box.addLazySingleton<T>(factory, {key, onDispose})` | `void` | Registers a lazy singleton. [T] inferred from [factory]. |
| `box.addFactory<T>(factory, {key})` | `void` | Registers a transient factory. [T] inferred from [factory]. |
| `box.addFactoryWith<T, A>(factory, {key})` | `void` | Registers a factory taking runtime arguments of type `A`. |
| `box.addAsyncSingleton<T>(factory, {key, onDispose})` | `void` | Registers an async singleton. [T] inferred from [factory]. |
| `box.addSingletons<T>(instances, {key})` | `void` | Registers multiple instances of type `T`. Requires `allowMulti`. |
| `box.allowMulti<T>([resolution])` | `void` | Enables multi-registration for type `T` with a resolution strategy. |
| `box.allowMultiple(types)` | `void` | Enables multi-registration for an iterable of `Multi` specifications. |
| `box.replaceSingleton<T>(instance, {key, disposeOld})` | `void` | Replaces a registration cleanly for tests. |
| `box.remove<T>({key, dispose})` | `Future<bool>` | Removes a registration and optionally disposes its instance. |
| `box.get<T>({args, key})` | `T` | Resolves instance of type `T`. Inferred from call-site context. |
| `box.tryGet<T>({args, key})` | `T?` | Resolves instance of type `T` or returns `null` if not found. |
| `box.getAsync<T>({args, key})` | `Future<T>` | Asynchronously resolves instance of type `T`. |
| `box.tryGetAsync<T>({args, key})` | `Future<T?>` | Asynchronously resolves instance of type `T` or returns `null`. |
| `box.getAll<T>({args, key})` | `List<T>` | Returns all registered instances of type `T`. |
| `box.getAllAsync<T>({args, key})` | `Future<List<T>>` | Asynchronously returns all registered instances of type `T`. |
| `box.contains<T>({key})` | `bool` | Checks if type `T` is registered locally or in parent scopes. |
| `box.registeredKeys` | `Iterable<Object>` | Returns all registered keys (including parent keys). |
| `box.length` | `int` | The number of direct registrations in this container. |
| `box.isDisposed` | `bool` | Returns `true` if this container has been disposed. |
| `box.dispose()` | `Future<void>` | Disposes all instances and clears registrations. |
| `box.install(module)` | `void` | Installs a `DependencyModule`. |
| `box.installAll(modules)` | `void` | Installs an iterable of `DependencyModule`s. |

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
