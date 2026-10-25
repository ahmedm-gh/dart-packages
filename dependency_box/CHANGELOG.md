# Changelog

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
- Multiple instance registrations with `allowMulti<T>()` and `allowMultiple` supporting 4 resolution strategies (`first`, `last`, `at(index)`, `key(key)`).
- Automatic lifecycle management and disposal via `DependencyDisposable` with identity-based deduplication (`Set.identity`).
- Robust container lifecycle invariants preventing leaks or stale resolution across disposed root and child containers.
- Circular dependency detection across both synchronous lazy singletons and asynchronous singletons.
- Sub-15ns resolution latency with zero allocations on unkeyed hot path.
