# Dart `cloneable` Monorepo

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Dart SDK](https://img.shields.io/badge/Dart-%3E%3D3.5.0%20%3C4.0.0-blue.svg)](https://dart.dev)

A modern, production-grade Dart multi-package workspace providing strongly-typed, annotation-driven `copyWith` code generation for ordinary Dart classes with first-class support for explicit `null` assignments.

---

## Workspace Packages

| Package | Description | Pub Status |
| :--- | :--- | :--- |
| [`packages/cloneable`](packages/cloneable) | Runtime annotations (`@Cloneable`, `@CloneableField`) and sentinel. **Zero dependencies**. | Ready for pub.dev |
| [`packages/cloneable_generator`](packages/cloneable_generator) | The code generator companion powered by `source_gen` and `build_runner`. | Ready for pub.dev |
| [`packages/cloneable_example`](packages/cloneable_example) | Real-world example models, automated test suites, and performance benchmarks. | Example / Internal |

---

## Architecture Overview

`cloneable` solves the longstanding Dart language dilemma of distinguishing omitted parameters from explicit `null` in `copyWith` methods:

```dart
import 'package:cloneable/cloneable.dart';

part 'user.g.dart';

@Cloneable()
class User with _$UserCloneable {
  final String name;
  final int age;
  final String? nickname;

  const User({
    required this.name,
    required this.age,
    this.nickname,
  });
}
```

```dart
final user = User(name: 'Ahmed', age: 25, nickname: 'Dev');

final updated = user.copyWith(name: 'Mohamed');  // nickname preserved as 'Dev'
final cleared = user.copyWith(nickname: null);   // nickname explicitly cleared to null
// user.copyWith(name: null);                   // Static compile-time analyzer error!
```

For full details, see the [Architecture Decision Record](doc/architecture_decision_record.md).

---

## Getting Started

### 1. Install Dependencies
From the repository root:
```bash
dart pub get
```

### 2. Run Tests
```bash
dart test packages/cloneable/test packages/cloneable_generator/test packages/cloneable_example/test
```

### 3. Run Code Generation in Example
```bash
cd packages/cloneable_example
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run Benchmarks
```bash
dart run packages/cloneable_example/benchmark/runtime_benchmark.dart
dart run packages/cloneable_example/benchmark/build_time_benchmark.dart
dart run packages/cloneable_example/benchmark/footprint_benchmark.dart
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.
