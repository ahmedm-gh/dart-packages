# dependency_box

[![pub package](https://img.shields.io/pub/v/dependency_box.svg)](https://pub.dev/packages/dependency_box)
[![Star on GitHub](https://img.shields.io/badge/Star_on_GitHub-★-deeppink?style=flat&logo=github)](https://github.com/ahmedm-gh/dart-packages)
[![GitHub](https://img.shields.io/badge/GitHub-ahmedm--gh-blue?logo=github)](https://github.com/ahmedm-gh)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-pink?logo=github)](https://github.com/sponsors/ahmedm-gh)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A high-performance, lightweight, zero-dependency Inversion-of-Control (IoC) container and service locator for Dart and Flutter applications.

Engineered with a zero-allocation unkeyed lookup path, `dependency_box` achieves sub-15ns resolution latency while offering hierarchical child scopes, lock-free async initialization deduplication, circular dependency detection, and deterministic lifecycle management.

---

## Table of Contents

- [Overview](#overview)
- [Features](#-features)
- [Installation & Quick Start](#-installation--quick-start)
- [Core Concepts](#-core-concepts)
  - [The 6 Registration Lifetimes](#1-the-6-registration-lifetimes)
  - [Resolution Mechanics & Type Inference](#2-resolution-mechanics--type-inference)
  - [Keyed Registrations](#3-keyed-registrations)
  - [Hierarchical Scopes & Child Containers](#4-hierarchical-scopes--child-containers)
  - [Root-Anchored Shared Bindings](#5-root-anchored-shared-bindings)
  - [Multi-Registrations & Resolution Strategies](#6-multi-registrations--resolution-strategies)
  - [Lifecycle Management & Disposal](#7-lifecycle-management--disposal)
- [Public API Reference](#-public-api-reference)
- [Practical Usage Patterns](#-practical-usage-patterns)
- [Advanced Features](#-advanced-features)
- [Verified Performance & Benchmarks](#-verified-performance--benchmarks)
- [Best Practices & Troubleshooting](#-best-practices--troubleshooting)
- [Progressive Examples Suite](#-progressive-examples-suite)
- [AI Agent Integration Guide](#-ai-agent-integration-guide)
- [Supporting & Contributing](#supporting--contributing)
- [Author & Maintainer](#author--maintainer)
- [License](#license)

---

## Overview

Modern Dart and Flutter architectures require clean separation of concerns, testability, and efficient resource lifecycles. Traditional dependency injection solutions often introduce substantial overhead: heavy reflection layers, verbose angle-bracket type boilerplate, complex code generation pipelines, or global singleton pollution that undermines test isolation.

`dependency_box` addresses these challenges with a clean, ergonomic, and ultra-fast container design:

- **What it is**: A pure Dart IoC container and service locator supporting both manual dependency injection (composition roots) and service locator patterns.
- **Design Philosophy**: Zero runtime dependencies, zero code generation, explicit constructor wiring, zero-overhead type resolution, and strictly scoped container hierarchies.
- **Primary Use Cases**: Server-side microservices, CLI tools, Flutter application feature scopes, clean architecture use case composition, and modular plugin systems.
- **Distinguishing Capabilities**: Sub-15ns hot-path resolution, bidirectional type inference (no repetitive `<Type>` annotations), 6 distinct registration lifetimes (including `WeakReference` caching and async deduplication), hierarchical child scopes with root-anchoring, and ASCII container diagnostic trees.
- **When You Might Not Need It**: Very small scripts or simple apps where passing dependencies directly through constructors without a container is sufficient.

---

## ✨ Features

- 🎯 **Bidirectional Type Inference**: Clean registration and resolution without typing `<Type>` angle brackets everywhere.
- 🪶 **Zero Runtime Dependencies**: Pure Dart code compatible with Flutter, Dart VM, Web, and WebAssembly (WASM).
- ⚡ **Sub-15ns Resolution**: Over 75 Million ops/sec on the hot path via direct `Type` literal map keys.
- ⏳ **6 Registration Lifetimes**: Eager singletons, lazy singletons, weak-reference caches, transient factories, parameterized factories, and async singletons.
- 🌳 **Hierarchical Child Scopes**: Isolated sub-containers (`createChild()`) that inherit parent registrations while shielding parents from child mutations.
- 🌐 **Root-Anchored Shared Singletons**: Register singletons from within a child scope (`addShared*`) anchored directly to the root container.
- 🔄 **Async Concurrency Deduplication**: In-flight `Future` deduplication ensuring expensive asynchronous initializers execute only once.
- 🔍 **Circular Dependency Protection**: Debug-mode cycle detection preventing infinite recursion loops.
- 🧹 **Automatic Resource Disposal**: Deterministic cleanup via `DependencyDisposable` and inline `onDispose` hooks.
- 📊 **Diagnostic Introspection**: ASCII tree visualization (`printContainer()`) displaying registered lifetimes, keys, instances, and shadowed scopes.

---

## 📦 Installation & Quick Start

Add `dependency_box` to your `pubspec.yaml`:

```bash
dart pub add dependency_box
# or for Flutter
flutter pub add dependency_box
```

Import the package in your Dart code:

```dart
import 'package:dependency_box/dependency_box.dart';
```

### Minimal Runnable Example

```dart
import 'package:dependency_box/dependency_box.dart';

class ApiConfig {
  final String baseUrl;
  const ApiConfig(this.baseUrl);
}

class ApiClient {
  final ApiConfig config;
  ApiClient(this.config);
}

class UserRepository {
  final ApiClient client;
  UserRepository(this.client);

  String fetchUser(String id) => 'User $id from ${client.config.baseUrl}';
}

void main() {
  // 1. Create a container
  final box = DependencyBox.main();

  // 2. Register dependencies (types are automatically inferred!)
  box.addSingleton(const ApiConfig('https://api.example.com'));
  box.addLazySingleton((b) => ApiClient(b.get()));
  box.addFactory((b) => UserRepository(b.get()));

  // 3. Resolve dependencies
  final UserRepository repo = box.get();
  print(repo.fetchUser('42')); // User 42 from https://api.example.com
}
```

---

## 💡 Core Concepts

### 1. The 6 Registration Lifetimes

`dependency_box` supports 6 distinct instance lifetimes to precisely model application resource requirements:

| Lifetime | Method | Instantiation Timing | Reused? | Typical Use Cases |
| --- | --- | --- | :---: | --- |
| **Eager Singleton** | `addSingleton<T>()` | Immediately upon registration | Yes | Pre-calculated configuration, constants, existing clients |
| **Lazy Singleton** | `addLazySingleton<T>()` | On first call to `get<T>()` | Yes | Database connections, heavy services, lazy engines |
| **Weak-Reference Cache** | `addCachedFactory<T>()` | On `get<T>()`, held in `WeakReference` | Yes (while in memory) | Bitmaps, parsed files, large models collected under memory pressure |
| **Transient Factory** | `addFactory<T>()` | Every call to `get<T>()` | No | View models, stateful controllers, request handlers |
| **Parameterized Factory** | `addFactoryWith<T, A>()` | Every call to `get<T>(args: ...)` | No | Dynamic services parameterized with runtime inputs/records |
| **Async Singleton** | `addAsyncSingleton<T>()` | On first call to `getAsync<T>()` | Yes | Token authenticators, remote config loaders, async handshakes |

```dart
final box = DependencyBox.main();

// Eager Singleton
box.addSingleton(DatabaseConfig('postgres://localhost:5432'));

// Lazy Singleton
box.addLazySingleton((b) => AuthService(b.get()));

// Weak-Reference Cached Factory
box.addCachedFactory((b) => HeavyDocumentParser());

// Transient Factory
box.addFactory((b) => OrderController(b.get()));

// Parameterized Factory (accepts runtime arguments)
box.addFactoryWith<UserSession, String>((b, userId) => UserSession(userId, b.get()));

// Asynchronous Singleton
box.addAsyncSingleton((b) async {
  final credentials = await loadSecureCredentials();
  return CloudStorageClient(credentials);
});
```

### 2. Resolution Mechanics & Type Inference

Resolving dependencies is performed via `get<T>()`, `tryGet<T>()`, `getAsync<T>()`, and `tryGetAsync<T>()`:

- **Bidirectional Type Inference**: Dart's type inference automatically determines `T` from the receiving variable type.
- **Fail-Fast Resolution (`get`)**: Throws a `StateError` if type `T` (or the specified `key`) is not registered in the container hierarchy.
- **Safe Resolution (`tryGet`)**: Returns `null` if the dependency is not registered, avoiding exceptions for optional plugins.
- **Presence Check (`contains`)**: Returns `true` if `T` (and optional `key`) exists in the container or any parent scope.

```dart
// Type inferred from variable declaration
final AuthService auth = box.get();

// Explicit type parameter
final client = box.get<ApiClient>();

// Safe optional resolution
final AnalyticsService? analytics = box.tryGet();
if (analytics != null) {
  analytics.track('app_opened');
}
```

### 3. Keyed Registrations

When multiple instances or configurations of the same type are needed, distinguish them with a qualifier `key`. Keys can be any Dart `Object` (commonly `Enum`, `String`, or `Symbol`):

```dart
enum Environment { dev, prod }

box.addSingleton(DatabaseConfig('db_dev'), key: Environment.dev);
box.addSingleton(DatabaseConfig('db_prod'), key: Environment.prod);

// Resolving by key
final devDb = box.get<DatabaseConfig>(key: Environment.dev);
final prodDb = box.get<DatabaseConfig>(key: Environment.prod);
```

### 4. Hierarchical Scopes & Child Containers

Call `createChild()` to instantiate an isolated sub-container. Child containers:

- Inherit all registrations from their parent container.
- Can register new local dependencies without exposing them to the parent.
- Can **shadow** parent registrations locally with a scoped override.
- Shield the parent container completely when disposed: calling `child.dispose()` tears down child singletons and listeners while leaving the parent container 100% intact.

```dart
final rootBox = DependencyBox.main(name: 'AppRoot');
rootBox.addSingleton(GlobalConfig());

// Create an isolated child scope for a user session or screen
final sessionBox = rootBox.createChild(name: 'UserSession');
sessionBox.addSingleton(UserSessionData('usr_42'));

// sessionBox can resolve both GlobalConfig (from parent) and UserSessionData (local)
final config = sessionBox.get<GlobalConfig>();
final session = sessionBox.get<UserSessionData>();

// Disposing sessionBox cleans up UserSessionData without touching rootBox
await sessionBox.dispose();
print(rootBox.isDisposed); // false
```

### 5. Root-Anchored Shared Bindings

When working inside a child scope, you may want to register a service that must survive the child scope's lifecycle and be shared globally across all scopes.

`addSharedSingleton`, `addSharedLazySingleton`, and `addSharedCachedFactory` anchor the registration directly onto the root container:

```dart
final sessionBox = rootBox.createChild();

// Registered on rootBox, NOT on sessionBox!
sessionBox.addSharedSingleton(SharedAuditLog());

// When sessionBox is disposed, SharedAuditLog remains alive on rootBox
await sessionBox.dispose();
final auditLog = rootBox.get<SharedAuditLog>(); // Still available!
```

### 6. Multi-Registrations & Resolution Strategies

By default, registering a duplicate type throws an `AssertionError` to prevent accidental overwrites. When you intentionally need multiple implementations of an abstraction (e.g. logging interceptors, validators, plugins), configure multi-registration via `allowMulti<T>()` or `allowMultiple()`:

```dart
// Enable multi-registration with a default resolution strategy
box.allowMulti<Interceptor>(resolution: MultiResolution.last);

box.addSingleton<Interceptor>(AuthInterceptor());
box.addSingleton<Interceptor>(LoggingInterceptor());
box.addSingleton<Interceptor>(MetricsInterceptor());

// 1. Resolve all registered instances as an Iterable<T>
final List<Interceptor> all = box.getAll<Interceptor>().toList();

// 2. get<T>() resolves according to the chosen MultiResolution strategy:
// - MultiResolution.first: Resolves AuthInterceptor
// - MultiResolution.last:  Resolves MetricsInterceptor
// - MultiResolution.at(1): Resolves LoggingInterceptor
// - MultiResolution.key(k): Resolves instance registered under key k
final Interceptor primary = box.get();
```

### 7. Lifecycle Management & Disposal

Managing resource disposal is critical for preventing memory and connection leaks in production:

1. **`DependencyDisposable` Interface**: Implement `DependencyDisposable` on classes that require teardown. When the owning container is disposed, its `dispose()` method is automatically awaited.
2. **Inline `onDispose` Hooks**: For classes you do not control (e.g. `StreamController`, `HttpClient`), pass an `onDispose: (instance) => ...` callback during registration.
3. **Selective Removal**: Use `box.remove<T>(dispose: true)` to remove a registration and dispose its active instance immediately.
4. **Container Teardown**: Calling `await box.dispose()` executes all disposal hooks, cancels active states, and prevents future resolutions.

```dart
class EventBroker implements DependencyDisposable {
  final _controller = StreamController<String>.broadcast();

  @override
  FutureOr<void> dispose() async {
    await _controller.close();
  }
}

// 1. Using DependencyDisposable
box.addSingleton(EventBroker());

// 2. Using inline onDispose hook
box.addSingleton(
  StreamController<int>(),
  onDispose: (controller) => controller.close(),
);

// 3. Full container disposal
await box.dispose();
```

---

## 📖 Public API Reference

### Container Creation & Hierarchy

| API | Return Type | Description |
| --- | --- | --- |
| `DependencyBox.main({String? name})` | `DependencyBox` | Creates a new root container. `name` is displayed in diagnostics. |
| `DependencyBox.child({required DependencyBox parent, String? name})` | `DependencyBox` | Creates a child container attached to the specified `parent`. |
| `box.createChild({String? name})` | `DependencyBox` | Convenience method to create a child container inheriting from `box`. |
| `box.name` | `String?` | The optional diagnostic name identifying this container. |
| `box.parent` | `DependencyBox?` | The immediate parent container, or `null` if this is root. |
| `box.root` | `DependencyBox` | The root container across any nesting depth. |
| `box.isDisposed` | `bool` | `true` if this container has been disposed. |
| `box.length` | `int` | Number of direct registrations in this container. |
| `box.registeredKeys` | `Iterable<Object>` | All keys/types registered in this container and its parent chain. |

### Dependency Registration

| Method | Description |
| --- | --- |
| `addSingleton<T>(instance, {key, onDispose})` | Registers an eager singleton. `instance` is stored immediately. |
| `addSingletons<T>(instances, {key})` | Batch registers multiple instances. Requires `allowMulti<T>()`. |
| `addLazySingleton<T>((box) => T, {key, onDispose})` | Registers a lazy singleton created on first `get<T>()`. |
| `addCachedFactory<T>((box) => T, {key, onDispose})` | Registers a factory cached in a `WeakReference<T>` while referenced. |
| `addFactory<T>((box) => T, {key})` | Registers a transient factory creating a new instance every `get<T>()`. |
| `addFactoryWith<T, A>((box, A args) => T, {key})` | Parameterized factory accepting runtime argument of type `A`. |
| `addAsyncSingleton<T>((box) => Future<T>, {key, onDispose})` | Registers an asynchronous singleton resolved via `getAsync<T>()`. |
| `addSharedSingleton<T>(instance, {key, onDispose})` | Registers an eager singleton directly on `root`, surviving child disposal. |
| `addSharedLazySingleton<T>((box) => T, {key, onDispose})` | Registers a lazy singleton directly on `root`. |
| `addSharedCachedFactory<T>((box) => T, {key, onDispose})` | Registers a `WeakReference` factory directly on `root`. |

### Dependency Resolution

| Method | Return Type | Error Behavior |
| --- | --- | --- |
| `get<T>({key, args})` | `T` | Throws `StateError` if not found or circular dependency detected. |
| `tryGet<T>({key, args})` | `T?` | Returns `null` if not found. Throws on circular dependency. |
| `getAsync<T>({key})` | `Future<T>` | Resolves async singleton with in-flight deduplication. |
| `tryGetAsync<T>({key})` | `Future<T?>` | Resolves async singleton, or returns `null` if not registered. |
| `getAll<T>({key})` | `Iterable<T>` | Returns all registered instances for a multi-registration type. |
| `contains<T>({key})` | `bool` | Returns `true` if `T` exists in this container or any parent. |

### Multi-Registration & Modules

| Method | Description |
| --- | --- |
| `allowMulti<T>({resolution})` | Configures type `T` for multiple registrations with a `MultiResolution` strategy. |
| `allowMultiple(Set<MultiRegistration>)` | Batch configures multiple registrations using `MultiRegistration` descriptors. |
| `install(DependencyModule module)` | Installs a modular registration group implementing `DependencyModule`. |
| `installAll(Iterable<DependencyModule>)` | Installs multiple modules in sequence. |

### Lifecycle, Overrides & Diagnostics

| Method | Description |
| --- | --- |
| `replaceSingleton<T>(instance, {key, disposeOld, onDispose})` | Swaps an existing registration with a new singleton (ideal for test mocks). |
| `remove<T>({key, dispose})` | Removes a registration. If `dispose: true`, disposes active instance immediately. |
| `dispose()` | Disposes container, running all `DependencyDisposable` and `onDispose` hooks. |
| `printContainer({showInherited, printer})` | Prints formatted ASCII hierarchy tree showing scopes, lifetimes, and shadowed keys. |

---

## 🛠 Practical Usage Patterns

### Pattern 1: Interface-to-Implementation Binding

Decouple business logic from concrete infrastructure by registering concrete classes against abstract interface contracts:

```dart
abstract interface class NotificationService {
  void send(String recipient, String message);
}

class EmailNotificationService implements NotificationService {
  @override
  void send(String recipient, String message) => print('Email to $recipient: $message');
}

// Register concrete implementation under the interface type
box.addSingleton<NotificationService>(EmailNotificationService());

// Resolve by interface type
final NotificationService notifications = box.get();
notifications.send('alice@example.com', 'Hello!');
```

### Pattern 2: Constructor Injection with Nested Dependencies

Wire complex dependency graphs explicitly in factory closures. Dependencies are resolved on demand from the container passed into the factory:

```dart
class DatabaseClient { ... }
class CacheManager { ... }

class UserRepository {
  final DatabaseClient db;
  final CacheManager cache;
  UserRepository(this.db, this.cache);
}

class UserService {
  final UserRepository repo;
  UserService(this.repo);
}

// Composition Root
box.addLazySingleton((b) => DatabaseClient());
box.addLazySingleton((b) => CacheManager());
box.addFactory((b) => UserRepository(b.get(), b.get()));
box.addFactory((b) => UserService(b.get()));

final service = box.get<UserService>();
```

### Pattern 3: Modular Architecture with `DependencyModule`

Organize large applications into feature modules rather than maintaining a monolithic registration file:

```dart
class NetworkModule implements DependencyModule {
  @override
  void register(DependencyBox box) {
    box.addSingleton(HttpClient());
    box.addLazySingleton((b) => ApiGateway(b.get()));
  }
}

class AuthModule implements DependencyModule {
  @override
  void register(DependencyBox box) {
    box.addFactory((b) => AuthController(b.get()));
  }
}

void main() {
  final box = DependencyBox.main();
  box.installAll([NetworkModule(), AuthModule()]);
}
```

### Pattern 4: Unit Testing with Isolated Containers & `replaceSingleton`

Avoid shared state across unit tests by creating a fresh container per test and swapping dependencies with fakes:

```dart
void main() {
  test('processes order with fake payment gateway', () async {
    final testBox = DependencyBox.main();
    testBox.install(ProductionOrderModule());

    // Swap production gateway with in-memory fake
    final fakeGateway = FakePaymentGateway();
    testBox.replaceSingleton<PaymentGateway>(fakeGateway, disposeOld: true);

    final checkout = testBox.get<OrderCheckoutService>();
    await checkout.processOrder('ORD-123', 99.0);

    expect(fakeGateway.processedTransactions, contains('ORD-123'));
    await testBox.dispose(); // Clean test teardown
  });
}
```

---

## 🚀 Advanced Features

### 1. In-Flight Async Deduplication

When multiple asynchronous callers simultaneously request an async singleton via `getAsync<T>()`, `dependency_box` deduplicates the in-flight `Future`. The underlying async factory executes exactly once, and all callers receive the identical resolved instance:

```dart
box.addAsyncSingleton<TokenSession>((b) async {
  print('Executing expensive remote token exchange...');
  return await exchangeTokenWithServer();
});

// 5 concurrent callers triggered simultaneously
final results = await Future.wait([
  box.getAsync<TokenSession>(),
  box.getAsync<TokenSession>(),
  box.getAsync<TokenSession>(),
  box.getAsync<TokenSession>(),
  box.getAsync<TokenSession>(),
]);

// "Executing expensive remote token exchange..." logged ONCE.
// All 5 callers receive the identical TokenSession instance.
```

### 2. Automatic Memory Management with `WeakReference` Caching

Use `addCachedFactory<T>()` for memory-intensive resources (e.g. large images, document caches, parsed ASTs). While an external variable retains a reference to the instance, `get<T>()` returns the cached instance. Once all external references are cleared, the instance can be garbage collected by Dart VM, and the next `get<T>()` re-instantiates it:

```dart
box.addCachedFactory<HeavyBitmap>((b) => HeavyBitmap.fromDisk('hero.png'));

var img = box.get<HeavyBitmap>(); // Instantiated
var img2 = box.get<HeavyBitmap>(); // Reuses cached instance (identical(img, img2) == true)

img = null;
img2 = null;
// Under memory pressure, Dart GC collects the unreferenced bitmap.
// Subsequent box.get<HeavyBitmap>() cleanly recreates it without crashes!
```

### 3. Diagnostic Introspection (`printContainer`)

Inspect your container hierarchy, registrations, multi-registration strategies, and shadowed bindings at runtime with formatted ASCII output:

```dart
final rootBox = DependencyBox.main(name: 'AppRoot');
rootBox.addSingleton<Logger>(ConsoleLogger());
rootBox.addSingleton<Database>(PostgresDatabase());

final featureBox = rootBox.createChild(name: 'CheckoutScope');
featureBox.addSingleton<Logger>(FileLogger()); // Shadows root Logger

featureBox.printContainer();
```

Output:

```
DependencyBox: 'CheckoutScope' [active]
├── Hierarchy: 'CheckoutScope' -> 'AppRoot'
├── Direct Registrations (1):
│   └── Logger -> Singleton (instance: Instance of 'FileLogger')
└── Inherited Registrations (2):
    ├── Database -> Singleton (instance: Instance of 'PostgresDatabase') (from 'AppRoot')
    └── Logger -> Singleton (from 'AppRoot') [shadowed by child]
```

### 4. Debug-Mode Circular Dependency Protection

If Service A depends on Service B, and Service B depends on Service A, synchronous lazy resolution detects the cycle in debug mode (`DependencyBoxConfig.isDebug`) and immediately throws a clear `StateError` rather than crashing with an unrecoverable `StackOverflowError`:

```dart
box.addLazySingleton<ServiceA>((b) => ServiceA(b.get<ServiceB>()));
box.addLazySingleton<ServiceB>((b) => ServiceB(b.get<ServiceA>()));

// Throws: StateError: Circular dependency detected in synchronous lazy resolution: ServiceA
box.get<ServiceA>();
```

---

## ⚡ Verified Performance & Benchmarks

`dependency_box` is engineered around a zero-allocation unkeyed lookup path using direct `Type` literal map keys without wrapper objects or reflection layers.

### Verified Benchmark Comparison: `dependency_box` vs. `get_it 9.3.0`

- **Head-to-Head Resolution**: `dependency_box` delivers up to **27.71× faster** dependency resolution than `get_it 9.3.0` (e.g. Singleton: 13 ns vs 362 ns in AOT; 15 ns vs 239 ns in JIT).
- **Container Setup**: **2.30×–6.35× faster** initialization and dependency binding setup.
- **Complex Architectures**: **13.87×–19.74× faster** across deep dependency graphs and application lifecycles, with weak-reference caching reaching **27.32×**.
- **Verified Suite Advantage**: **5.57× geometric-mean speedup in JIT** and **6.67× in AOT** across comprehensive multi-workload benchmarking.

#### 1. JIT Resolution Workloads

![JIT Resolution Workloads](doc/benchmark_jit_resolution.svg)

#### 2. JIT Registration & Scaling

![JIT Registration & Scaling](doc/benchmark_jit_registration.svg)

#### 3. AOT Resolution Workloads

![AOT Resolution Workloads](doc/benchmark_aot_resolution.svg)

#### 4. AOT Registration & Scaling

![AOT Registration & Scaling](doc/benchmark_aot_registration.svg)

> [!TIP]
> A consolidated 4-in-1 chart is also available at [doc/benchmark_comparison.svg](doc/benchmark_comparison.svg), along with suite overviews for [JIT](doc/benchmark_jit.svg) and [AOT](doc/benchmark_aot.svg).

### 🔬 Reproducing the Benchmarks

All benchmark suites and measurement harnesses are 100% open source and reproducible:

- **Comparative Benchmark Suite**: [`tool/comparison_benchmark/`](https://github.com/ahmedm-gh/dart-packages/tree/main/dependency_box/tool/comparison_benchmark)

  ```bash
  # Run head-to-head microbenchmarks (dependency_box vs get_it 9.3.0)
  dart run tool/comparison_benchmark/bin/compare_benchmark.dart

  # Run real-world production architecture simulation suite
  dart run tool/comparison_benchmark/bin/real_world_benchmark.dart
  ```

- **Standalone Package Microbenchmarks**: [`tool/benchmark/`](https://github.com/ahmedm-gh/dart-packages/tree/main/dependency_box/tool/benchmark)

  ```bash
  dart run tool/benchmark/benchmark.dart
  ```

> [!NOTE]
> - Benchmarks were run on Dart SDK 3.13.4 on Windows x64.
> - Comparison harness sources are located in [`tool/comparison_benchmark/`](https://github.com/ahmedm-gh/dart-packages/tree/main/dependency_box/tool/comparison_benchmark) and internal benchmarks in [`tool/benchmark/`](https://github.com/ahmedm-gh/dart-packages/tree/main/dependency_box/tool/benchmark).

---

## 🎯 Best Practices & Troubleshooting

### Choosing the Right Lifetime

- **Use Eager Singletons (`addSingleton`)** for configuration records, immutable value objects, or pre-constructed services that must be ready at boot.
- **Use Lazy Singletons (`addLazySingleton`)** for services that are expensive to instantiate (database pools, HTTP clients, crypto providers) so they only initialize if actually used.
- **Use Transient Factories (`addFactory`)** for stateful components (controllers, view models, form presenters) where each caller requires independent state.
- **Use Weak-Reference Caches (`addCachedFactory`)** for heavy, reusable objects that can safely be reclaimed by garbage collection if memory is tight.
- **Use Async Singletons (`addAsyncSingleton`)** when initialization involves asynchronous I/O (network handshakes, disk reads).

### Avoiding Common Errors

1. **`StateError: No registration found for type T`**:
   - Cause: Attempting to `get<T>()` a type that was never registered.
   - Fix: Ensure registrations are configured in your composition root before resolving, or use `box.tryGet<T>()` for optional services.
2. **`AssertionError: Duplicate registration for type T`**:
   - Cause: Calling `addSingleton<T>()` or `addFactory<T>()` more than once for the same type and key.
   - Fix: Use `box.allowMulti<T>()` if multiple registrations are intended, or `box.replaceSingleton<T>()` in tests.
3. **`StateError: Cannot resolve dependency from a disposed DependencyBox`**:
   - Cause: Attempting to resolve a service from a container that has already called `dispose()`.
   - Fix: Check `box.isDisposed` or review scope lifecycle wiring to ensure child containers are not disposed prematurely.
4. **`ArgumentError: Cannot create a WeakReference to primitive value`**:
   - Cause: Registering a value type (`String`, `int`, `Record`, `bool`) with `addCachedFactory`.
   - Fix: Dart's runtime prohibits weak references to primitives. Use `addSingleton` or `addFactory` for value types.

---

## 📂 Progressive Examples Suite

The `example/` directory contains 13 progressive, standalone examples demonstrating every capability:

### Level 1: Beginner Fundamentals
- [simple_registration.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/basic/simple_registration.dart): Eager/lazy singletons, transient factories, constructor injection, `tryGet`, and `contains`.
- [interface_mapping.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/basic/interface_mapping.dart): Decoupling interface contracts from concrete implementations.
- [keyed_dependencies.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/basic/keyed_dependencies.dart): Differentiating instances using Enum, String, and Symbol keys.
- [parameterized_factory.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/basic/parameterized_factory.dart): Parameterized factories (`addFactoryWith`) with runtime arguments.

### Level 2: Intermediate Patterns
- [modules_and_composition.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/intermediate/modules_and_composition.dart): Organizing registrations into cohesive `DependencyModule` classes.
- [hierarchical_scopes.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/intermediate/hierarchical_scopes.dart): Child scopes (`createChild()`), inheritance, and root-anchored shared singletons.
- [multi_registrations.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/intermediate/multi_registrations.dart): Plugin/interceptor collections with `allowMulti` and resolution strategies (`first`, `last`, `at`, `key`).
- [async_and_deduplication.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/intermediate/async_and_deduplication.dart): Asynchronous singletons and lock-free in-flight concurrency deduplication.
- [weak_reference_cache.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/intermediate/weak_reference_cache.dart): Memory-efficient caching with `addCachedFactory` and Dart's `WeakReference`.

### Level 3: Advanced Architectures
- [clean_architecture.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/advanced/clean_architecture.dart): Complete Clean Architecture with Domain, Data, Use Cases, and Controller composition.
- [lifecycle_and_disposal.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/advanced/lifecycle_and_disposal.dart): Deterministic lifecycle: `DependencyDisposable`, inline `onDispose`, and child scope teardown.
- [testing_and_overrides.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/advanced/testing_and_overrides.dart): Test isolation, fake repositories, and test swaps with `replaceSingleton`.
- [diagnostics_and_debugging.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/advanced/diagnostics_and_debugging.dart): Visualizing container trees with `printContainer()` and diagnosing circular dependencies.

> [!TIP]
> See [example/README.md](file:///d:/Private/Packages/dart-packages/dependency_box/example/README.md) for complete instructions and runnable commands for all 13 examples.

---

## 🤖 AI Agent Integration Guide

If you use AI coding agents (such as Google Antigravity, Claude Code, Cursor, Copilot, or Roo Code) on projects that use `dependency_box`, copy the code block below directly into your project's root `AGENTS.md` (or `agents.md`).

This provides your AI assistant with verified API constraints, lifecycle semantics, and architectural rules to prevent hallucinations:

````markdown
# Dependency Injection Guidelines: `dependency_box`

This project uses [`dependency_box`](https://pub.dev/packages/dependency_box) as its primary Inversion-of-Control (IoC) container and service locator. When generating, modifying, reviewing, or refactoring code involving dependency registration or resolution, you MUST follow the verified guidelines below.

---

## 1. Core Principles & Architecture

1. **Verify Installed API**: Inspect `pubspec.yaml` to confirm `dependency_box` is installed. Never assume methods, parameters, or behaviors from other DI libraries (`get_it`, `provider`, `riverpod`, `injectable`).
2. **Explicit Composition Root**: Keep registrations centralized in a dedicated composition root or modular `DependencyModule` implementations (e.g., `lib/src/di/`, `lib/core/injection/`).
3. **Prefer Constructor Injection**: Application classes, use cases, and repositories must accept their dependencies as explicit constructor parameters. Never sprinkle container locator lookups (`box.get()`) deep inside domain logic.
4. **No Secondary DI Libraries**: Do not introduce a second dependency injection or service locator package unless explicitly requested.

---

## 2. Registration Rules & Lifetime Selection

Select the exact lifetime matching the resource's operational requirement:

- **Eager Singleton (`box.addSingleton<T>(instance, {key, onDispose})`)**: Use for immutable configuration, environment flags, or pre-constructed services.
- **Lazy Singleton (`box.addLazySingleton<T>((b) => T, {key, onDispose})`)**: Use for expensive infrastructure services (database pools, HTTP clients, analytics) that should instantiate on first access.
- **Transient Factory (`box.addFactory<T>((b) => T, {key})`)**: Use for stateful presenters, controllers, or use cases requiring independent state per call.
- **Parameterized Factory (`box.addFactoryWith<T, A>((b, A args) => T, {key})`)**: Use when a factory requires runtime arguments (e.g., user session ID, pagination criteria).
- **Weak-Reference Cache (`box.addCachedFactory<T>((b) => T, {key, onDispose})`)**: Use for heavy memory objects (parsed templates, image buffers) that can be garbage-collected when unreferenced. Do NOT use on primitive value types (`String`, `num`, `bool`, `Record`).
- **Async Singleton (`box.addAsyncSingleton<T>((b) async => T, {key, onDispose})`)**: Use for services requiring asynchronous boot logic. Resolve with `await box.getAsync<T>()`.

### Registration Best Practices

- **Interface Decoupling**: Register concrete classes against their abstract interface types:
  ```dart
  box.addSingleton<UserRepository>(SqlUserRepository(box.get()));
  ```
- **Avoid Accidental Overwrites**: By default, duplicate registrations throw an `AssertionError`. Use `box.allowMulti<T>()` only when intentional multiple registrations (e.g. plugins) are required.
- **Keyed Registrations**: Differentiate multiple bindings of the same type using Enum, String, or Symbol keys:
  ```dart
  box.addSingleton<String>('https://api.dev.com', key: Environment.dev);
  box.addSingleton<String>('https://api.prod.com', key: Environment.prod);
  ```

---

## 3. Resolution & Scoping Rules

- **Resolution APIs**:
  - `box.get<T>({key, args})`: Fast synchronous resolution. Throws `StateError` if `T` is not registered.
  - `box.tryGet<T>({key, args})`: Returns `null` if not found. Use for optional plugins or feature flags.
  - `box.getAsync<T>({key})`: Resolves an async singleton with automatic in-flight concurrency deduplication.
  - `box.getAll<T>({key})`: Resolves an `Iterable<T>` of all registered instances under a multi-registration.
- **Child Scopes (`createChild()`)**:
  - Use child scopes for bounded lifecycles (e.g., authenticated user sessions, HTTP requests, Flutter navigation flows).
  - Child containers inherit all parent dependencies.
  - Disposing a child container (`await childBox.dispose()`) cleans up child resources without affecting the parent.
- **Root-Anchored Shared Singletons**:
  - Use `childBox.addSharedSingleton<T>()` only when a binding registered inside a child scope must outlive the child and be accessible globally on `box.root`.

---

## 4. Lifecycle & Disposal Rules

- **Resource Teardown**: Classes holding streams, sockets, timers, or native handles should implement `DependencyDisposable`:
  ```dart
  class ClientManager implements DependencyDisposable {
    @override
    FutureOr<void> dispose() async {
      await _client.close();
    }
  }
  ```
- **Inline Hooks**: For third-party types, provide `onDispose: (instance) => instance.close()`.
- **Safe Teardown**: Calling `await box.dispose()` executes all disposal hooks in reverse registration order and invalidates future resolutions.

---

## 5. Testing & Test Isolation

- **Zero Test Leakage**: Never share a global mutable container across test cases. Create a fresh container inside each test group or `setUp`:
  ```dart
  setUp(() {
    testBox = DependencyBox.main();
    testBox.install(AppModule());
  });
  tearDown(() => testBox.dispose());
  ```
- **Test Overrides with `replaceSingleton`**:
  ```dart
  testBox.replaceSingleton<PaymentGateway>(FakePaymentGateway(), disposeOld: true);
  ```
- **Child Scope Shadowing**: Alternatively, create a child scope in the test (`testBox.createChild()`) and register mock implementations to shadow parent bindings non-destructively.

---

## 6. Verification Workflow for Generated Code

After creating or modifying dependency injection code:

1. **Format**: Run `dart format .`
2. **Analyze**: Run `dart analyze` (must produce 0 errors, 0 warnings, 0 lints).
3. **Test**: Run `dart test` to verify complete resolution and lifecycle cleanliness.
4. **Inspect Diagnostics**: If resolution fails unexpectedly, call `box.printContainer()` to inspect the active registration tree.
````

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
