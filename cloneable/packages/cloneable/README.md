# cloneable

[![pub package](https://img.shields.io/pub/v/cloneable.svg)](https://pub.dev/packages/cloneable)
[![Star on GitHub](https://img.shields.io/badge/Star_on_GitHub-★-deeppink?style=flat&logo=github)](https://github.com/ahmedm-gh/dart-packages)
[![GitHub](https://img.shields.io/badge/GitHub-ahmedm--gh-blue?logo=github)](https://github.com/ahmedm-gh)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-pink?logo=github)](https://github.com/sponsors/ahmedm-gh)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A lightweight, zero-dependency, production-grade Dart package that provides annotations, sentinels, and configuration contracts for generating **strongly typed, compile-safe `copyWith` implementations** for ordinary Dart classes — with first-class support for explicitly setting nullable fields to `null`, deep copying collections, and zero runtime heap allocations.

Pairs directly with [`cloneable_generator`](https://pub.dev/packages/cloneable_generator) to deliver instant (~1s) standalone code generation or automated `build_runner` workflows.

---

## Table of Contents

- [The Dilemma: Why `cloneable`?](#the-dilemma-why-cloneable)
- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
  - [1. Define Your Model](#1-define-your-model)
  - [2. Generate Code](#2-generate-code)
  - [3. Use `copyWith`](#3-use-copywith)
- [Detailed Invocation Semantics](#detailed-invocation-semantics)
- [Output Strategies (`CloneableOutput`)](#output-strategies-cloneableoutput)
  - [1. Clean Extension (Part File)](#1-clean-extension-part-file)
  - [2. In-Class Mode (`@Cloneable.inClass()`)](#2-in-class-mode-cloneableinclass)
  - [3. In-Library Mode (`@Cloneable.inLibrary()`)](#3-in-library-mode-cloneableinlibrary)
  - [4. Standalone Mode (`@Cloneable.standalone()`)](#4-standalone-mode-cloneablestandalone)
  - [5. Zero-Allocation Mixin](#5-zero-allocation-mixin)
- [Post-Generation Cleanup (`CloneableCleanup`)](#post-generation-cleanup-cloneablecleanup)
  - [Zero Residual Footprint (`CloneableCleanup.remove`)](#zero-residual-footprint-cloneablecleanupremove)
- [Multi-Model Container (`@Cloneables`)](#multi-model-container-cloneables)
- [Deep Copying for Collections & Typed Data](#deep-copying-for-collections--typed-data)
  - [1. Class-Level Deep Copying](#1-class-level-deep-copying)
  - [2. Field-Level Deep Copying](#2-field-level-deep-copying)
  - [3. Custom Cloner Functions (`@CloneableField(cloner: ...)`)](#3-custom-cloner-functions-cloneablefieldcloner-)
- [Field Whitelisting & Ignoring](#field-whitelisting--ignoring)
  - [1. Excluding Fields (`@CloneableField(ignore: true)`)](#1-excluding-fields-cloneablefieldignore-true)
  - [2. Whitelisting Fields via Annotation (`@Cloneable(fields: [...])`)](#2-whitelisting-fields-via-annotation-cloneablefields-)
  - [3. Whitelisting Fields via In-Class Getter (`cloneableFields`)](#3-whitelisting-fields-via-in-class-getter-cloneablefields)
  - [4. Conflict Resolution (`fieldsConflict`)](#4-conflict-resolution-fieldsconflict)
- [Ignoring Null Values (`ignoreNull: true`)](#ignoring-null-values-ignorenull-true)
- [Custom Constructors & Positional Parameters](#custom-constructors--positional-parameters)
  - [Named Constructors (`constructor: 'create'`)](#named-constructors-constructor-create)
  - [Positional Constructor Parameters](#positional-constructor-parameters)
- [Generics & Type Bounds](#generics--type-bounds)
- [Single Source of Truth (SSOT) Project Defaults](#single-source-of-truth-ssot-project-defaults)
  - [1. Built-In Defaults Reference](#1-built-in-defaults-reference)
  - [2. Modern Dart 3+ Configuration Idioms](#2-modern-dart-3-configuration-idioms)
  - [3. Cascading Precedence](#3-cascading-precedence)
- [Custom Symbol & File Affixes (`CloneableNaming`)](#custom-symbol--file-affixes-cloneablenaming)
- [Smart Sentinel Resolution (`CloneableSentinel`)](#smart-sentinel-resolution-cloneablesentinel)
- [Type Aliases (`typedef UseCopyWith = Cloneable;`)](#type-aliases-typedef-usecopywith--cloneable)
- [Performance Benchmarks](#performance-benchmarks)
- [Comparison with Existing Packages](#comparison-with-existing-packages)
- [Supporting & Contributing](#supporting--contributing)
- [Author & Maintainer](#author--maintainer)
- [License](#license)

---

## The Dilemma: Why `cloneable`?

In Dart, creating immutable data models requires a `copyWith` method. However, traditional handwritten `copyWith` implementations suffer from a critical flaw: **distinguishing between omitting a parameter (keeping current value) and explicitly passing `null` (clearing a nullable field)**.

```dart
// Traditional handwritten copyWith:
User copyWith({String? name, String? nickname}) {
  return User(
    name: name ?? this.name,
    nickname: nickname ?? this.nickname, // If you pass nickname: null, it is IGNORED!
  );
}
```

Other packages attempt to solve this with compromises:
- Requiring extra boolean flags (`user.copyWithNull(nickname: true)`).
- Allocating intermediate wrapper objects (`user.copyWith(nickname: Value(null))`).
- Generating heavy data classes with complex metaprogramming (`freezed`).

### The `cloneable` Solution

`cloneable` solves this elegantly using a **zero-cost sentinel pattern combined with strongly-typed parameter signatures**:

1. **Explicit `null` Works Naturally**: `user.copyWith(nickname: null)` explicitly clears the nullable field.
2. **Compile-Time Type Safety**: `user.copyWith(name: null)` on a non-nullable `String name` is rejected by the Dart compiler at build time.
3. **Zero Extra Allocations**: Mixin pattern dispatches directly via `this` (zero intermediate object wrappers).
4. **Zero Runtime Dependencies**: Pure Dart code that compiles everywhere (VM, Flutter, Web, WASM, Server).

---

## Features

- **Clean Ordinary Classes**: Annotate standard Dart classes with `@Cloneable()`. No complex abstract classes, factory constructors, or boilerplate.
- **First-Class Explicit `null`**: Distinguishes between omitting an argument and passing `null`.
- **Compile-Time Type Safety**: Statically prevents passing `null` to non-nullable fields.
- **Dual Speed Code Generation**: Run via lightning-fast standalone CLI (`dart run cloneable_generator` in ~1.5s) or standard `build_runner`.
- **Flexible Output Destinations**:
  - `CloneableOutput.part`: Separate `.g.dart` or `.cloneable.g.dart` file.
  - `CloneableOutput.inClass`: Injected directly into the class body (zero extra files!).
  - `CloneableOutput.inLibrary`: Injected at the top-level of the source file.
  - `CloneableOutput.standalone`: Independent library file without `part of`.
- **Deep Copying Built-In**: Deep copies collections (`List`, `Set`, `Map`, `Queue`, `HashMap`, `SplayTreeMap`, etc.) and all `dart:typed_data` arrays (`Uint8List`, `Int32List`, `ByteData`, etc.).
- **Custom Cloner Tear-Offs**: Pass custom clone functions via `@CloneableField(cloner: ...)`.
- **Zero Residual Footprint Mode**: Eliminate annotations and imports after generation with `cleanup: CloneableCleanup.remove`.
- **Universal Multi-Platform Support**: 100% compatible with Flutter, Dart VM, Web, Server, WASM, and AOT compilation.

---

## Installation

Add `cloneable` to your runtime `dependencies` and `cloneable_generator` to your `dev_dependencies`:

```yaml
dependencies:
  cloneable: ^1.0.0

dev_dependencies:
  cloneable_generator: ^1.0.0
  # Optional: only if you prefer using build_runner instead of the standalone CLI
  build_runner: ^2.4.0
```

---

## Quick Start

### 1. Define Your Model

Annotate your class with `@Cloneable()` and declare a `part` file:

```dart
// lib/models/user.dart
import 'package:cloneable/cloneable.dart';

part 'user.g.dart';

@Cloneable()
class User {
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

### 2. Generate Code

Using the standalone CLI (recommended, runs in ~1.5s):
```bash
dart run cloneable_generator
```

Or using `build_runner`:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Use `copyWith`

```dart
final user = User(
  name: 'Ahmed',
  age: 25,
  nickname: 'Dev',
);

// 1. Update specific fields (unspecified fields are preserved)
final updated = user.copyWith(
  name: 'Mohamed',
  age: 26,
);
// updated.name == 'Mohamed'
// updated.age == 26
// updated.nickname == 'Dev'

// 2. Explicitly clear a nullable field to null
final cleared = user.copyWith(
  nickname: null,
);
// cleared.name == 'Ahmed'
// cleared.age == 25
// cleared.nickname == null

// 3. Static compile-time analyzer protection:
// user.copyWith(name: null); // Compile error: The argument type 'Null' can't be assigned to 'String'
```

---

## Detailed Invocation Semantics

| Invocation | `name` (`String`) | `nickname` (`String?`) | Semantics |
| :--- | :--- | :--- | :--- |
| `user.copyWith()` | Preserved (`Ahmed`) | Preserved (`Dev`) | No-op clone |
| `user.copyWith(name: 'Ali')` | Replaced (`Ali`) | Preserved (`Dev`) | Single field update |
| `user.copyWith(nickname: null)` | Preserved (`Ahmed`) | **Cleared (`null`)** | Explicit `null` assignment |
| `user.copyWith(name: null)` | **Compile Error** | N/A | Static analyzer rejects `null` |

---

## Output Strategies (`CloneableOutput`)

Configure how and where generated code is emitted using `output: CloneableOutput`:

| Mode | Annotation Constructor | Location | Best For |
| :--- | :--- | :--- | :--- |
| **Part File** | `@Cloneable.part()` or `@Cloneable()` | Separate `*.g.dart` or `*.cloneable.g.dart` | Clean separation of generated files |
| **In-Class** | `@Cloneable.inClass()` | Inside the class body | Zero extra files; self-contained classes |
| **In-Library** | `@Cloneable.inLibrary()` | Top-level extension in source file | Single-file models; clean class bodies |
| **Standalone** | `@Cloneable.standalone()` | Independent `*.cloneable.dart` library file | Clean architectures without `part` directives |

### 1. Clean Extension (Part File)

```dart
import 'package:cloneable/cloneable.dart';

part 'user.g.dart';

@Cloneable.part()
class User {
  final String name;
  const User({required this.name});
}
```

Generated in `user.g.dart`:
```dart
part of 'user.dart';

extension $UserExtension on User {
  User Function({String name}) get copyWith => _copyWith;
  User _copyWith({Object? name = $undefined}) {
    final self = this;
    return User(name: identical(name, $undefined) ? self.name : name as String);
  }
}
```

---

### 2. In-Class Mode (`@Cloneable.inClass()`)

Avoids creating any extra files by injecting `copyWith` directly inside the class:

```dart
import 'package:cloneable/cloneable.dart';

@Cloneable.inClass()
class Product {
  final String title;
  final double price;

  const Product({required this.title, required this.price});
}
```

Run `dart run cloneable_generator`. The generator injects `copyWith` directly inside the class body:

```dart
import 'package:cloneable/cloneable.dart';

@Cloneable.inClass()
class Product {
  final String title;
  final double price;

  const Product({required this.title, required this.price});

// cloneable:start (Product) - GENERATED CODE - DO NOT MODIFY BY HAND
// (run: dart run cloneable_generator to regenerate)
  static const _$undefined = Object();

  Product Function({
    String title,
    double price,
  }) get copyWith => _copyWith;

  Product _copyWith({
    Object? title = _$undefined,
    Object? price = _$undefined,
  }) {
    final self = this;
    return Product(
      title: identical(title, _$undefined) ? self.title : title as String,
      price: identical(price, _$undefined) ? self.price : price as double,
    );
  }
// cloneable:end (Product)
}
```

---

### 3. In-Library Mode (`@Cloneable.inLibrary()`)

Places the generated extension directly inside the declaring file between managed comment markers:

```dart
import 'package:cloneable/cloneable.dart';

@Cloneable.inLibrary()
class Account {
  final String email;
  const Account({required this.email});
}
```

Generated in the same file:
```dart
// cloneable:start (Account) - GENERATED CODE - DO NOT MODIFY BY HAND
// (run: dart run cloneable_generator to regenerate)
extension $AccountExtension on Account {
  Account Function({String email}) get copyWith => _copyWith;
  Account _copyWith({Object? email = $undefined}) {
    final self = this;
    return Account(
      email: identical(email, $undefined) ? self.email : email as String,
    );
  }
}
// cloneable:end (Account)
```

---

### 4. Standalone Mode (`@Cloneable.standalone()`)

Generates an independent file (e.g. `order.cloneable.dart`) with explicit imports and **without** `part of`:

```dart
// lib/order.dart
import 'package:cloneable/cloneable.dart';

@Cloneable.standalone()
class Order {
  final String orderId;
  const Order({required this.orderId});
}
```

Generated in `order.cloneable.dart`:
```dart
import 'package:cloneable/cloneable.dart';
import 'order.dart';

extension $OrderExtension on Order {
  Order Function({String orderId}) get copyWith => _copyWith;
  Order _copyWith({Object? orderId = $undefined}) {
    final self = this;
    return Order(
      orderId: identical(orderId, $undefined) ? self.orderId : orderId as String,
    );
  }
}
```

---

### 5. Zero-Allocation Mixin

If your application demands absolute maximum throughput (>80 million ops/sec), mix in `_$ClassNameCloneable`:

```dart
import 'package:cloneable/cloneable.dart';

part 'profile.g.dart';

@Cloneable()
class Profile with _$ProfileCloneable {
  final String username;
  const Profile({required this.username});
}
```

`cloneable_generator` auto-detects the mixin and generates `mixin _$ProfileCloneable`, which implements `get copyWith => this;` for zero allocation overhead.

---

## Post-Generation Cleanup (`CloneableCleanup`)

Controls what happens to source code annotations after generation:

| Option | Behavior |
| :--- | :--- |
| `CloneableCleanup.none` | Retains all annotations and imports (default). |
| `CloneableCleanup.deactivate` | Rewrites `@Cloneable(...)` to `@Cloneable(active: false, ...)` to skip future generation passes. |
| `CloneableCleanup.remove` | Strips all `@Cloneable`, `@CloneableField`, and `package:cloneable` imports completely. |

### Zero Residual Footprint (`CloneableCleanup.remove`)

For one-off generation leaving zero trace of `package:cloneable` in your codebase:

```dart
import 'package:cloneable/cloneable.dart';

@Cloneable(
  output: CloneableOutput.inClass,
  sentinel: CloneableSentinel.private,
  cleanup: CloneableCleanup.remove,
)
class CleanUser {
  final String name;
  const CleanUser({required this.name});
}
```

Run `dart run cloneable_generator`:
1. The self-contained method is injected inside `CleanUser`.
2. `@Cloneable(...)` is removed.
3. `import 'package:cloneable/cloneable.dart';` is stripped.
4. Your file now compiles as 100% pure Dart with **zero external dependencies**.

---

## Multi-Model Container (`@Cloneables`)

`package:cloneable` provides a declarative container annotation `@Cloneables` for grouping entity configurations in a single map:

```dart
import 'package:cloneable/cloneable.dart';

const modelConfigs = Cloneables({
  User: Cloneable(),
  Order: Cloneable(deepCopyCollections: true),
});
```

This container is available for declarative entity mappings, reflection, or custom toolchain pipelines.

---

## Deep Copying for Collections & Typed Data

### 1. Class-Level Deep Copying

Enable `deepCopyCollections: true` to create independent mutable collection copies:

```dart
@Cloneable(deepCopyCollections: true)
class Team {
  final List<String> members;
  final Set<int> ids;
  final Map<String, dynamic> metadata;
  final Uint8List payload;

  const Team({
    required this.members,
    required this.ids,
    required this.metadata,
    required this.payload,
  });
}
```

Built-in deep copying covers:
- **Standard Collections**: `List`, `Set`, `Map`, `Iterable`
- **Specialized Collections**: `Queue`, `ListQueue`, `DoubleLinkedQueue`, `HashMap`, `LinkedHashMap`, `SplayTreeMap`, `HashSet`, `LinkedHashSet`, `SplayTreeSet`
- **Typed Data Arrays (`dart:typed_data`)**: `Uint8List`, `Int8List`, `Uint8ClampedList`, `Int16List`, `Uint16List`, `Int32List`, `Uint32List`, `Int64List`, `Uint64List`, `Float32List`, `Float64List`, `Float32x4List`, `Int32x4List`, `Float64x2List`, and `ByteData`

### 2. Field-Level Deep Copying

Enable or disable deep copying per field using `@CloneableField`:

```dart
@Cloneable()
class Project {
  final List<String> shallowTags; // shallow copy (default)

  @CloneableField(deepCopy: true)
  final List<String> deepTags; // independent copy via List.of

  const Project({required this.shallowTags, required this.deepTags});
}
```

### 3. Custom Cloner Functions (`@CloneableField(cloner: ...)`)

Pass any function tear-off to deep-copy nested models or third-party collections (`BuiltList`, `IList`). Custom cloners always take priority over built-in collection copying:

```dart
static Address _cloneAddress(Address a) => a.copyWith();

@Cloneable()
class UserProfile {
  final String name;

  @CloneableField(cloner: _cloneAddress)
  final Address address;

  @CloneableField(cloner: Uint8List.fromList)
  final Uint8List rawBytes;

  const UserProfile({
    required this.name,
    required this.address,
    required this.rawBytes,
  });
}
```

---

## Field Whitelisting & Ignoring

### 1. Excluding Fields (`@CloneableField(ignore: true)`)

```dart
@Cloneable()
class AuditedEntity {
  final String id;
  final String title;

  @CloneableField(ignore: true)
  final DateTime createdAt;

  const AuditedEntity({
    required this.id,
    required this.title,
    required this.createdAt,
  });
}
```

### 2. Whitelisting Fields via Annotation (`@Cloneable(fields: [...])`)

```dart
@Cloneable(fields: ['name', 'age'])
class User {
  final String id;
  final String name;
  final int age;

  const User({required this.id, required this.name, required this.age});
}
// Only name and age are exposed in copyWith. id is preserved via self.id.
```

### 3. Whitelisting Fields via In-Class Getter (`cloneableFields`)

```dart
@Cloneable()
class User {
  final String id;
  final String name;
  final int age;

  const User({required this.id, required this.name, required this.age});

  List<Object?> get cloneableFields => [name, age];
  // Or: List<Object?> get copyWithFields => [name, age];
}
```

### 4. Conflict Resolution (`fieldsConflict`)

When fields are declared in both `@Cloneable(fields: ...)` and an in-class getter, `fieldsConflict` controls resolution:
- `CloneableFieldsConflict.error` (default): Raises a compile-time build error.
- `CloneableFieldsConflict.merge`: Unites fields from both locations.
- `CloneableFieldsConflict.inClass`: Uses fields from the getter.
- `CloneableFieldsConflict.inAnnotation`: Uses fields from the annotation.

---

## Ignoring Null Values (`ignoreNull: true`)

If you want traditional Dart `copyWith` behavior where passing `null` is ignored (retaining the existing value):

```dart
// Field-level:
@CloneableField(ignoreNull: true)
final String? bio;

// Class-level:
@Cloneable(ignoreNull: true)
class User { ... }
```

---

## Custom Constructors & Positional Parameters

### Named Constructors (`constructor: 'create'`)

```dart
@Cloneable(constructor: 'create')
class ServiceConfig {
  final String host;
  final int port;

  const ServiceConfig.create({required this.host, required this.port});
}
```

### Positional Constructor Parameters

Generative constructors with positional parameters are fully supported:

```dart
@Cloneable()
class Coordinate {
  final double x;
  final double y;
  final double? z;

  const Coordinate(this.x, this.y, [this.z]);
}

final coord = Coordinate(10.0, 20.0, 30.0);
final flat = coord.copyWith(z: null); // x and y preserved!
```

---

## Generics & Type Bounds

`cloneable` fully preserves generic type variables and bounds:

```dart
@Cloneable()
class Box<T> {
  final T value;
  const Box({required this.value});
}

@Cloneable()
class BoundedContainer<T extends num> {
  final T score;
  const BoundedContainer({required this.score});
}
```

---

## Single Source of Truth (SSOT) Project Defaults

Configure defaults across your entire project without repeating options on every class.

### 1. Built-In Defaults Reference

| Property | Type | Default Value | Description |
| :--- | :--- | :--- | :--- |
| `output` | `CloneableOutput` | `CloneableOutput.auto` | Auto-detects part file, standalone, or inline output based on context. |
| `strategy` | `CloneableStrategy` | `CloneableStrategy.auto` | Auto-detects mixin vs extension based on whether class mixes in `_$Class...`. |
| `sentinel` | `CloneableSentinel` | `CloneableSentinel.auto` | Auto-detects import prefix (`c.$undefined` vs `$undefined`). |
| `deepCopyCollections` | `bool` | `false` | Shallow copies collections for optimal speed and zero heap allocation. |
| `ignoreNull` | `bool` | `false` | Explicitly assigns `null` to nullable fields (supports clearing nullable fields). |
| `active` | `bool` | `true` | Code generation active for annotated classes. |
| `cleanup` | `CloneableCleanup` | `CloneableCleanup.none` | Controls post-generation cleanup: `none`, `deactivate`, or `remove`. |
| `fieldsConflict` | `CloneableFieldsConflict` | `CloneableFieldsConflict.error` | Reports a compile error if fields are specified in both annotation and getter. |
| `naming.method` | `String` | `'copyWith'` | The generated copy method and getter name. |
| `naming.sentinel` | `String` | `r'_$undefined'` | Private sentinel identifier name (`_$undefined`). |
| `naming.mixin` | `CloneableAffix` | `CloneableAffix(prefix: r'_$', suffix: 'Cloneable')` | Mixin naming pattern (`_$ClassNameCloneable`). |
| `naming.extension` | `CloneableAffix` | `CloneableAffix(prefix: r'$', suffix: 'Extension')` | Extension naming pattern (`$ClassNameExtension`). |
| `naming.file` | `CloneableAffix` | `CloneableAffix(prefix: '', suffix: '.cloneable.g')` | Generated file naming pattern (`$className.cloneable.g.dart`). |
| `naming.directory` | `String?` | `null` | Optional subfolder path for generated files (e.g. `'generated'`). |

### 2. Modern Dart 3+ Configuration

#### Library Directive (Recommended)

Place `@Cloneable.defaults(...)` directly above an unnamed `library;` directive:

```dart
@Cloneable.defaults(
  output: CloneableOutput.inClass,
  sentinel: CloneableSentinel.private,
  deepCopyCollections: true,
  naming: CloneableNaming(method: 'clone'),
)
library;

import 'package:cloneable/cloneable.dart';
```

#### Shared Project Configuration

Place your defaults in `lib/cloneable_defaults.dart` and import it into your model files. Defaults are automatically inherited across imported files:

```dart
// lib/cloneable_defaults.dart
@Cloneable.defaults(
  output: CloneableOutput.inClass,
  deepCopyCollections: true,
)
library;

import 'package:cloneable/cloneable.dart';
```

### 3. Cascading Precedence & Activeness

1. **Class Annotation (`@Cloneable(...)`)**: Explicit per-class overrides take priority. Supports `CloneableActiveness`:
   - `CloneableActiveness.forceActive`: Forces code generation even if parent/library defaults are inactive.
   - `CloneableActiveness.forceInactive`: Suppresses code generation for this class.
   - Partial `CloneableAffix` overrides (e.g. specifying only `prefix`) preserve the default suffix.
2. **File / Library In-Code Defaults (`@Cloneable.defaults(...)`)**: Applied to all models declared in the file.
3. **Imported / Shared In-Code Defaults**: Discovered from imported configuration files.
4. **Built-In Defaults (`CloneableDefaults.instance`)**: Standard fallbacks.

---

## Custom Symbol & File Affixes (`CloneableNaming`)

Customize symbol prefixes and suffixes across all targets using `naming: CloneableNaming(...)`:

```dart
@Cloneable(
  naming: CloneableNaming(
    method: 'copyWith',
    mixin: CloneableAffix(prefix: r'_$', suffix: 'Cloneable'),
    extension: CloneableAffix(prefix: 'Ext', suffix: 'Extension'),
    file: CloneableAffix(prefix: '', suffix: '.cloneable'),
    directory: 'generated',
  ),
)
class User { ... }
```

---

## Smart Sentinel Resolution (`CloneableSentinel`)

- **`CloneableSentinel.auto` (Default)**: Automatically detects if `package:cloneable` was imported with an alias (`import ... as c;` $\rightarrow$ `c.$undefined`) or directly (`$undefined`). In `inClass` mode, automatically injects a self-contained private sentinel.
- **`CloneableSentinel.private`**: Emits a private sentinel (`static const _$undefined = Object();` or `const _$undefined = Object();`). Self-contained, works with zero external imports.
- **`CloneableSentinel.package`**: Explicitly references canonical `$undefined`.

---

## Type Aliases (`typedef UseCopyWith = Cloneable;`)

If your team prefers an alternative annotation name (such as `@UseCopyWith` or `@CopyWith`), declare a simple `typedef`:

```dart
import 'package:cloneable/cloneable.dart';

typedef UseCopyWith = Cloneable;

@UseCopyWith()
class User {
  final String name;
  const User({required this.name});
}
```

Because `cloneable_generator` inspects static types, aliases work transparently without extra configuration.

---

## Performance Benchmarks

Measured on Windows x64 with Dart SDK 3.13.4 across 5 rounds of 500,000 iterations:

| Implementation | Strategy | Operation | Median (ns/op) | Throughput (ops/sec) |
| :--- | :--- | :--- | :--- | :--- |
| **Cloneable** | **Mixin Strategy** | Field Update (Preserved) | **12.13 ns** | **82,413,054 ops/s** |
| **Cloneable** | **Extension Strategy** | Field Update (Preserved) | **13.33 ns** | **75,030,012 ops/s** |
| Handwritten Sentinel | Mixin | Field Update (Preserved) | 4.52 ns | 221,141,088 ops/s |
| Freezed-Style | Wrapper Alloc | Field Update (Preserved) | 4.58 ns | 218,150,087 ops/s |
| Map-Based Reference | Dynamic Map | Field Update (Preserved) | 129.30 ns | 7,734,191 ops/s |
| **Cloneable** | **Mixin Strategy** | Explicit `null` | **10.57 ns** | **94,643,195 ops/s** |
| **Cloneable** | **Extension Strategy** | Explicit `null` | **11.54 ns** | **86,670,133 ops/s** |
| Handwritten Sentinel | Mixin | Explicit `null` | 4.32 ns | 231,481,481 ops/s |
| Freezed-Style | Wrapper Alloc | Explicit `null` | 4.54 ns | 220,361,393 ops/s |
| Map-Based Reference | Dynamic Map | Explicit `null` | 133.01 ns | 7,518,458 ops/s |
| **Cloneable** | Mixin (10 fields) | Multi-field update | **28.14 ns** | **35,539,129 ops/s** |
| **Cloneable** | Mixin (25 fields) | Multi-field update | **52.48 ns** | **19,054,152 ops/s** |
| **Cloneable** | Mixin (`Box<int>`) | Generic update | **18.34 ns** | **54,513,737 ops/s** |

---

## Comparison with Existing Packages

| Feature | `cloneable` | `copy_with_extension` | `freezed` | `built_value` |
| :--- | :--- | :--- | :--- | :--- |
| **Explicit null in `copyWith`** | `user.copyWith(nick: null)` | Requires `copyWithNull(nick: true)` | Supported | Requires builder pattern |
| **Class syntax** | Ordinary Dart classes | Ordinary Dart classes | `factory Model(...) = _Model;` | Abstract classes & builders |
| **Compile-time non-null check** | Yes | Yes | Yes | Yes |
| **Runtime allocations** | **0 extra wrappers** | 0 extra wrappers | Allocates `_CopyImpl` | Allocates builder |
| **Runtime dependencies** | **0 dependencies** | 0 dependencies | Depends on annotations | Depends on built_value |
| **Dual execution (CLI + build_runner)** | Yes (~1.5s CLI) | build_runner only | build_runner only | build_runner only |
| **In-class / in-file generation** | Yes (`inClass`, `inLibrary`) | No | No | No |
| **Zero residual footprint cleanup** | Yes (`cleanup: remove`) | No | No | No |

---

## Supporting & Contributing

If you find `cloneable` helpful, here are several ways you can support the project:

### 🌟 Community Support

- **Star the Repository**: Star [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages) on GitHub to help others discover it.
- **Report Issues & Ideas**: Found a bug or need an improvement? Open an issue on [GitHub Issues](https://github.com/ahmedm-gh/dart-packages/issues).
- **Contribute**: Pull requests for optimizations, documentation, or examples are always welcome.
- **Spread the Word**: Recommend `cloneable` in your Flutter/Dart teams, blogs, or communities.

### ☕ Sponsorship & Backing

- **Sponsor on GitHub**: Support ongoing maintenance via [GitHub Sponsors](https://github.com/sponsors/ahmedm-gh).
- **Buy Me a Coffee**: Support development with a one-time coffee or recurring donation via [Buy Me a Coffee](https://buymeacoffee.com/ahmeds1).

## Author & Maintainer

Created and maintained by **[AHMED M.](https://github.com/ahmedm-gh)**  

- GitHub: [@ahmedm-gh](https://github.com/ahmedm-gh)
- Repository: [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages)

## License

This package is licensed under the [MIT License](./LICENSE).
