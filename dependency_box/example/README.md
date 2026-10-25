# DependencyBox Examples Suite

This directory contains a complete, progressive example suite for **`dependency_box`**, demonstrating everything from introductory singletons and factories to enterprise-grade Clean Architecture and diagnostic inspection.

All examples are 100% standalone, runnable Dart console scripts with zero external dependencies.

---

## Example Progression

```
example/
├── dependency_box_example.dart             # Standard pub.dev runnable example
├── basic/                                  # Level 1: Beginner Fundamentals
│   ├── simple_registration.dart            # Eager/lazy singletons, factories, tryGet, contains
│   ├── interface_mapping.dart              # Abstract contracts mapped to concrete implementations
│   ├── keyed_dependencies.dart             # Enum, String, and Symbol keys
│   └── parameterized_factory.dart          # Dynamic factory injection with runtime arguments
├── intermediate/                           # Level 2: Real-World Patterns
│   ├── modules_and_composition.dart        # DependencyModule & composition root wiring
│   ├── hierarchical_scopes.dart            # Child scopes, parent inheritance & shared root bindings
│   ├── multi_registrations.dart            # MultiRegistration strategies (first, last, at, key) & getAll()
│   ├── async_and_deduplication.dart        # Async singletons, getAsync() & concurrent request deduplication
│   └── weak_reference_cache.dart           # WeakReference cached factories for automatic memory cleanup
└── advanced/                               # Level 3: Production Architecture
    ├── clean_architecture.dart             # Full Clean Architecture (Domain, Data, Use Cases, Controller)
    ├── lifecycle_and_disposal.dart         # DependencyDisposable, inline onDispose & hierarchical teardown
    ├── testing_and_overrides.dart          # Test container isolation, fakes, replaceSingleton & mocks
    └── diagnostics_and_debugging.dart      # ASCII container tree (printContainer) & circular checks
```

---

## Level 1 — Basic Examples

Focused, minimal examples introducing the core mechanics of registration and resolution:

| File | Concepts Covered | Command |
| --- | --- | --- |
| [simple_registration.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/basic/simple_registration.dart) | Eager singletons, lazy singletons, transient factories, constructor injection, `tryGet`, `contains`. | `dart run example/basic/simple_registration.dart` |
| [interface_mapping.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/basic/interface_mapping.dart) | Decoupling interfaces (`NotificationSender`) from concrete classes (`EmailNotificationSender`). | `dart run example/basic/interface_mapping.dart` |
| [keyed_dependencies.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/basic/keyed_dependencies.dart) | Registering multiple variations of the same type using Enum keys, String identifiers, and Symbol tags. | `dart run example/basic/keyed_dependencies.dart` |
| [parameterized_factory.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/basic/parameterized_factory.dart) | Parameterized factories (`addFactoryWith<T, A>`) accepting runtime arguments and records. | `dart run example/basic/parameterized_factory.dart` |

---

## Level 2 — Intermediate Examples

Realistic combinations of features for modular, scalable applications:

| File | Concepts Covered | Command |
| --- | --- | --- |
| [modules_and_composition.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/intermediate/modules_and_composition.dart) | Implementing `DependencyModule`, organizing code into cohesive modules, and installing them at the composition root. | `dart run example/intermediate/modules_and_composition.dart` |
| [hierarchical_scopes.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/intermediate/hierarchical_scopes.dart) | Hierarchical scopes via `createChild()`, parent inheritance, child disposal isolation, and `addSharedSingleton` (anchored to root). | `dart run example/intermediate/hierarchical_scopes.dart` |
| [multi_registrations.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/intermediate/multi_registrations.dart) | Registering collections of plugins/interceptors with `allowMulti<T>()` and resolving via `first`, `last`, `at(index)`, `key()`, and `getAll<T>()`. | `dart run example/intermediate/multi_registrations.dart` |
| [async_and_deduplication.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/intermediate/async_and_deduplication.dart) | Asynchronous singletons (`addAsyncSingleton`), `getAsync<T>()`, and automatic in-flight concurrency deduplication across simultaneous callers. | `dart run example/intermediate/async_and_deduplication.dart` |
| [weak_reference_cache.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/intermediate/weak_reference_cache.dart) | Memory-efficient singleton-like caching with `addCachedFactory<T>()` using Dart's `WeakReference<T>` to allow garbage collection when unused. | `dart run example/intermediate/weak_reference_cache.dart` |

---

## Level 3 — Advanced Real-World Examples

Complete, architectural blueprints reflecting production Dart application requirements:

| File | Concepts Covered | Command |
| --- | --- | --- |
| [clean_architecture.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/advanced/clean_architecture.dart) | End-to-end Clean Architecture: Domain entities & contracts, data layer repositories, application use cases, controller factory, and composition root. | `dart run example/advanced/clean_architecture.dart` |
| [lifecycle_and_disposal.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/advanced/lifecycle_and_disposal.dart) | Resource lifecycle: `DependencyDisposable` implementation, custom inline `onDispose` hooks, child scope disposal, and selective `remove(dispose: true)`. | `dart run example/advanced/lifecycle_and_disposal.dart` |
| [testing_and_overrides.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/advanced/testing_and_overrides.dart) | Unit testing strategies: Fresh isolated container setups, test fakes, mocks, and swapping production services using `replaceSingleton`. | `dart run example/advanced/testing_and_overrides.dart` |
| [diagnostics_and_debugging.dart](file:///d:/Private/Packages/dart-packages/dependency_box/example/advanced/diagnostics_and_debugging.dart) | Diagnostics & container introspection: Visualizing ASCII scope hierarchy with `printContainer()`, shadowed binding inspection, and circular dependency checks. | `dart run example/advanced/diagnostics_and_debugging.dart` |

---

## How to Run All Examples

To verify the entire suite at once, run:

```bash
# Basic examples
dart run example/basic/simple_registration.dart
dart run example/basic/interface_mapping.dart
dart run example/basic/keyed_dependencies.dart
dart run example/basic/parameterized_factory.dart

# Intermediate examples
dart run example/intermediate/modules_and_composition.dart
dart run example/intermediate/hierarchical_scopes.dart
dart run example/intermediate/multi_registrations.dart
dart run example/intermediate/async_and_deduplication.dart
dart run example/intermediate/weak_reference_cache.dart

# Advanced examples
dart run example/advanced/clean_architecture.dart
dart run example/advanced/lifecycle_and_disposal.dart
dart run example/advanced/testing_and_overrides.dart
dart run example/advanced/diagnostics_and_debugging.dart

# Standard pub.dev example
dart run example/dependency_box_example.dart
```
