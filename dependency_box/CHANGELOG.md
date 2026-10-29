# Changelog

## 1.2.1

- **Scope Hierarchy & Resolution Visuals**: Added detailed scope hierarchy and resolution boundaries diagram (`doc/scope_hierarchy.svg`) in `README.md`, visualizing upward resolution delegation, sibling scope isolation, and `LookupScope` boundaries.
- **Documentation**: Harmonized visual diagram styling and corner radii across documentation assets.

## 1.2.0

- **Flutter DevTools Extension Integration**: Added official DevTools inspection support via `package:dependency_box/devtools.dart` and companion package `dependency_box_devtools`. Enables interactive inspection of registrations, scopes, dependency graphs, and health diagnostics with verified zero runtime overhead when DevTools is inactive.
- **On-Demand Inspection Engine**: Added `getSnapshot()` and `ContainerInspector` to capture immutable serializable container state (`ContainerSnapshot`, `ScopeSnapshot`, `RegistrationSnapshot`, `DiagnosticNotice`) without instantiating lazy singletons or invoking factories.
- **VM Service Extensions**: Added `DependencyBoxDevTools.register()` to expose VM Service RPC endpoints (`ext.dependencyBox.getSnapshot`, `ext.dependencyBox.getScopes`, `ext.dependencyBox.getRegistrations`, `ext.dependencyBox.ping`) with automatic weak-reference container tracking.
- **Package Archive Optimization**: Streamlined `.pubignore` to exclude development tools, internal benchmarks, and offline docs, keeping published archive size minimal (<35 KB).

## 1.1.0

- **Hierarchy Boundary Resolution (`LookupScope`)**: Introduced the `LookupScope` enum (`inherited`, `local`, `parent`, `ancestors`, `root`) across `get()`, `tryGet()`, `getAsync()`, `tryGetAsync()`, `contains()`, `getAll()`, and `getAllAsync()`. Enables pinpoint resolution boundaries with zero heap allocation overhead, preserving sub-15ns hot paths.
- **Hierarchy Introspection**: Added `depth` (0-based scope depth level), `findOwner<T>()` (locates the container holding a registration for targeted replacement/removal), and `isShadowed<T>()` (detects if a child registration shadows an ancestor).
- **Child Container Lifecycle & Scoping**: Added direct-child scope tracking via `children`, recursive cascading downward disposal with pre-emptive ownership transfer to eliminate `ConcurrentModificationError`, and clean self-detachment on child scope disposal.
- **Performance Optimization**: Implemented hybrid synchronous fast-path container disposal with zero-allocation iteration, reducing scope teardown latency by up to 3.3× and achieving **16.96× faster** scoped feature wizard lifecycles than `get_it 9.3.0`.
- **Comparative Benchmarks & Visuals**: Added consolidated comparison chart (`doc/benchmark_comparison.svg`) and comprehensive performance report (`doc/benchmarks.md`) evaluating 27 workloads across JIT and Native AOT against `get_it 9.3.0`.
- **Documentation**: Comprehensive documentation for `LookupScope`, scope boundaries, `depth`, `findOwner`, and `isShadowed` in `README.md`.
- **Testing**: Added comprehensive unit test suites covering all `LookupScope` boundaries, companion methods, and child lifecycle contracts.

## 1.0.0

- **First Stable Release**: Production-ready, zero-dependency Inversion-of-Control (IoC) container and service locator for Dart and Flutter applications.
- **6 Registration Lifetimes**: Eager singletons, lazy singletons, weak-reference caches (`addCachedFactory`), transient factories, parameterized factories (`addFactoryWith`), and async singletons (`addAsyncSingleton`).
- **Hierarchical Child Scopes**: Isolated sub-containers (`createChild()`) inheriting parent bindings, with child scope disposal isolation and root-anchored shared singletons (`addShared*`).
- **Sub-15ns Resolution**: Zero-allocation hot path leveraging direct `Type` literal map lookups.
- **Async Concurrency Deduplication**: Lock-free in-flight `Future` deduplication across concurrent callers.
- **Automatic Resource Lifecycle**: Deterministic cleanup with `DependencyDisposable` and inline `onDispose` hooks.
- **Container Diagnostics**: ASCII tree introspection via `printContainer()` with scope hierarchy, lifetime details, and shadowed binding indicators.
- **Comprehensive Benchmarks**: Complete head-to-head performance benchmarks against `get_it 9.3.0` demonstrating up to 27.7× faster resolution in AOT.

## 0.1.2

- **Performance Optimization**: Optimized parameterized factory resolution (`addFactoryWith`) by streamlining type casting paths, reducing invocation overhead from ~674 ns to sub-25 ns.
- **Benchmarks & Documentation**: Added comprehensive, open-source performance benchmarking suite comparing `dependency_box` and `get_it 9.3.0` across 16 core resolution and production architecture workloads in both JIT and AOT modes.
- **Visuals**: Updated `doc/benchmark_comparison.svg` with native responsive light and dark theme styling.

## 0.1.1

- Initial beta release of `dependency_box`.
- Fast, zero-dependency IoC and dependency injection container for Dart and Flutter.
- Registration methods: `addSingleton`, `addSingletons`, `addLazySingleton`, `addFactory`, `addFactoryWith`, and `addAsyncSingleton`.
- Asynchronous singleton support (`addAsyncSingleton`, `getAsync`, `tryGetAsync`, `getAllAsync`) with lazy initialization, lock-free deduplication of concurrent callers, and circular dependency detection.
- Hierarchical child scopes via `box.createChild()` and `DependencyBox.child()`, enabling isolated lifecycle management and inheritance with zero overhead on the root path.
- Inline `onDispose` lifecycle hooks for zero-wrapper cleanup on third-party instances.
- Flexible qualification keys supporting `Enum`, `Symbol`, and custom `Object` keys alongside `String`.
- Fast targeted removal via `box.remove<T>()` with optional resource disposal.
- Test override support via `box.replaceSingleton<T>()` for clean mock injection without triggering duplicate registration asserts.
- Modular feature composition via `DependencyModule` and `box.install()`.
- Container introspection via `contains<T>()`, `registeredKeys`, `length`, `isEmpty`, and `isNotEmpty`.
- Centralized compile-time configuration constants via `DependencyBox`.
- Multiple instance registrations with `allowMulti<T>()` and `allowMultiAll` supporting 4 resolution strategies (`first`, `last`, `at(index)`, `key(key)`).
- Automatic lifecycle management and disposal via `DependencyDisposable` with identity-based deduplication (`Set.identity`).
- Robust container lifecycle invariants preventing leaks or stale resolution across disposed root and child containers.
- Circular dependency detection across both synchronous lazy singletons and asynchronous singletons.
- Sub-15ns resolution latency with zero allocations on unkeyed hot path.
