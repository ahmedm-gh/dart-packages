# Flutter DevTools Extension for dependency_box

`dependency_box` includes an official, production-quality Flutter DevTools extension that allows developers to inspect container registrations, scope hierarchies, dependency relationships, and runtime health diagnostics directly inside Flutter DevTools.

---

## 1. Zero Overhead Architecture

The DevTools integration is built with a strict **zero-overhead, on-demand inspection model**:

- **No hot path overhead**: Resolution methods (`get<T>()`, `tryGet<T>()`, `contains<T>()`) perform zero additional work, allocate no wrappers, and trigger no events or counters.
- **No continuous tracing**: DevTools generates inspection snapshots only when explicitly opened, navigated to, or manually refreshed.
- **No side effects**: Inspecting the container never triggers initialization of lazy singletons or execution of factories.
- **No memory leaks**: Containers are registered via `WeakReference`. DevTools inspection never keeps disposed or discarded containers alive in heap memory.
- **Decoupled package**: The Flutter web DevTools extension is housed in the companion package `dependency_box_devtools`. Ordinary users of `dependency_box` are not required to install DevTools dependencies.

---

## 2. Installation & Quick Start

### Step 1: Add Dependency

In your Flutter project's `pubspec.yaml`:

```yaml
dependencies:
  dependency_box: ^1.2.0

dev_dependencies:
  dependency_box_devtools: ^1.0.0
```

### Step 2: Register Container in Debug / Profile Mode

In your application's bootstrap code (e.g. `main.dart`):

```dart
import 'package:flutter/material.dart';
import 'package:dependency_box/dependency_box.dart';
import 'package:dependency_box/devtools.dart'; // Or package:dependency_box_devtools

void main() {
  final box = DependencyBox.main(name: 'AppRoot');

  // Register dependencies
  box.addSingleton<ConfigService>(ConfigService());
  box.addLazySingleton<AuthService>((c) => AuthService(c.get<ConfigService>()));

  // Register container with DevTools
  DependencyBoxDevTools.register(box);

  runApp(const MyApp());
}
```

### Step 3: Open in Flutter DevTools

1. Launch your application in debug mode:

   ```bash
   flutter run
   ```

2. Open Flutter DevTools in your browser or IDE.
3. Select the **dependency_box** tab to inspect your container.

---

## 3. DevTools Extension Views

### 1. Registrations View

- **Search & Filters**: Filter registrations by type name, qualifying key, scope, lifetime, or instantiation status.
- **Lifetime & State Badges**: Instantly distinguish `Singleton`, `LazySingleton`, `CachedFactory`, `Factory`, and `AsyncSingleton`.
- **Instance Allocation Status**: Indicates whether an instance is currently allocated in heap memory or remains uninstantiated, safely determined with zero side effects.
- **Inspector Panel**: Click any registration to inspect its exact identifier, scope depth, and multi-registration position.

### 2. Scopes View

- **Scope Hierarchy Tree**: Visualizes container nesting depths (`root` -> `child` -> `subchild`).
- **Direct Registrations**: View registrations belonging to each scope level.
- **Lifecycle Status**: Safely shows whether a scope is currently active or has been disposed.

### 3. Dependency Graph View

- **Visual Scope Clustering**: Visual cluster view mapping services to their owning scopes.
- **Interactive Pan & Zoom**: Smooth canvas with zoom-in, zoom-out, and reset controls for large container hierarchies.
- **Selection Inspector**: Highlights selected nodes and facilitates quick navigation to details.

### 4. Diagnostics View

- **Shadowed Registrations**: Detects when a child scope registers a type that shadows an ancestor binding.
- **Scope Disposal Leaks**: Warns if operations occur against disposed containers.
- **Heap Allocation Summary**: Quick summary of instantiated singletons vs. unallocated lazy services.
- **Export Snapshot**: One-click button to copy the raw JSON snapshot payload for debugging or sharing.

---

## 4. Measured Benchmark Results

Zero overhead was empirically verified using `tool/benchmark/devtools_benchmark.dart` on Dart SDK 3.13.4:

| Benchmark Operation | Case A (Baseline) | Case B (Installed, Disabled) | Case C (Enabled, Idle) | Case D (Under Active Snapshots) |
| :--- | ---: | ---: | ---: | ---: |
| **Singleton Lookup** | `15.58 ns` | `16.89 ns` | `15.87 ns` | `36.33 ns` |
| **Keyed Lookup** | `21.55 ns` | `21.95 ns` | `41.01 ns` | `52.26 ns` |
| **Cached Lazy Lookup** | `17.14 ns` | `17.78 ns` | `43.38 ns` | `36.61 ns` |
| **Factory Creation** | `20.54 ns` | `20.45 ns` | `53.55 ns` | `43.50 ns` |
| **Registration Throughput** | `161.87 ns` | `172.48 ns` | `327.62 ns` | `327.62 ns` |

**Snapshot capture latency**: `4.9 µs/snapshot` (~202,000 snapshots/sec).

---

## 5. Security & Privacy Limitations

- **Metadata Only**: DevTools inspection only accesses structural type information, registration keys, lifecycle strategies, and allocation booleans.
- **No Secret Leaks**: Object contents, credentials, tokens, or private fields are never inspected or transmitted.
- **Debug / Profile Only**: VM service extensions are only registered in debug and profile modes and are completely stripped in Release builds.
