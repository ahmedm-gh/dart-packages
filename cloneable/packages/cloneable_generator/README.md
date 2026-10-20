# cloneable_generator

[![pub package](https://img.shields.io/pub/v/cloneable_generator.svg)](https://pub.dev/packages/cloneable_generator)
[![Star on GitHub](https://img.shields.io/badge/Star_on_GitHub-★-deeppink?style=flat&logo=github)](https://github.com/ahmedm-gh/dart-packages)
[![GitHub](https://img.shields.io/badge/GitHub-ahmedm--gh-blue?logo=github)](https://github.com/ahmedm-gh)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-pink?logo=github)](https://github.com/sponsors/ahmedm-gh)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

The high-performance, developer-first code generator companion for [`cloneable`](https://pub.dev/packages/cloneable). It generates **strongly typed, compile-safe `copyWith` implementations** for ordinary Dart classes with first-class support for explicit `null` assignments, deep copying, and zero heap allocations.

`cloneable_generator` works seamlessly via either the **standalone high-speed CLI** (~1s execution, zero configuration) or the standard **`build_runner` pipeline**.

---

## Table of Contents

- [Why `cloneable_generator`?](#why-cloneable_generator)
- [Installation](#installation)
- [Quick Start](#quick-start)
  - [Approach 1: Clean Extension (Zero Boilerplate)](#approach-1-clean-extension-zero-boilerplate)
  - [Approach 2: In-Class Generation (Zero Extra Files)](#approach-2-in-class-generation-zero-extra-files)
  - [Approach 3: Zero-Allocation Mixin](#approach-3-zero-allocation-mixin)
- [How to Run Code Generation](#how-to-run-code-generation)
  - [Method A: Standalone High-Speed CLI Runner (Recommended)](#method-a-standalone-high-speed-cli-runner-recommended)
  - [Method B: `build_runner` Pipeline](#method-b-build_runner-pipeline)
- [Output Modes (`CloneableOutput`)](#output-modes-cloneableoutput)
  - [1. Part File Mode (`CloneableOutput.part`)](#1-part-file-mode-cloneableoutputpart)
  - [2. Standalone Mode (`CloneableOutput.standalone`)](#2-standalone-mode-cloneablestandalone)
  - [3. In-Library Mode (`CloneableOutput.inLibrary`)](#3-in-library-mode-cloneableinlibrary)
  - [4. In-Class Mode (`CloneableOutput.inClass`)](#4-in-class-mode-cloneableinclass)
- [Post-Generation Cleanup (`CloneableCleanup`)](#post-generation-cleanup-cloneablecleanup)
  - [1. `CloneableCleanup.none` (Default)](#1-cloneablecleanupnone-default)
  - [2. `CloneableCleanup.deactivate`](#2-cloneablecleanupdeactivate)
  - [3. `CloneableCleanup.remove` (Zero Residual Footprint)](#3-cloneablecleanupremove-zero-residual-footprint)
- [Project-Wide Defaults via In-Code SSOT (`@Cloneable.defaults`)](#project-wide-defaults-via-in-code-ssot-cloneabledefaults)
  - [1. Built-In Defaults Reference](#1-built-in-defaults-reference)
  - [2. Modern Dart 3+ Configuration Idioms](#2-modern-dart-3-configuration-idioms)
  - [3. Cascading Precedence Hierarchy](#3-cascading-precedence-hierarchy)
- [Advanced Features](#advanced-features)
  - [Deep Copying for Collections & Typed Data](#deep-copying-for-collections--typed-data)
  - [Custom Cloner Functions (`@CloneableField(cloner: ...)`)](#custom-cloner-functions-cloneablefieldcloner-)
  - [Field Whitelisting & Ignoring](#field-whitelisting--ignoring)
  - [Ignoring Null Values (`ignoreNull: true`)](#ignoring-null-values-ignorenull-true)
  - [Custom Constructors & Positional Parameters](#custom-constructors--positional-parameters)
  - [Generics & Type Bounds](#generics--type-bounds)
  - [Custom Symbol & File Affixes (`CloneableNaming`)](#custom-symbol--file-affixes-cloneablenaming)
  - [Smart Sentinel Resolution (`CloneableSentinel`)](#smart-sentinel-resolution-cloneablesentinel)
- [Troubleshooting & FAQ](#troubleshooting--faq)
- [Supporting & Contributing](#supporting--contributing)
- [Author & Maintainer](#author--maintainer)
- [License](#license)

---

## Why `cloneable_generator`?

| Challenge | Other Generators (`freezed`, `copy_with_extension`) | `cloneable_generator` |
| :--- | :--- | :--- |
| **Explicit `null` in `copyWith`** | Requires awkward methods like `copyWithNull(email: true)` or wrapper objects | **Natural**: `user.copyWith(email: null)` clears the nullable field |
| **Compile-time safety** | Allows passing `null` to non-nullable fields or crashes at runtime | **Compile Error**: Statically rejected by Dart analyzer |
| **Boilerplate overhead** | Requires abstract classes, private constructors, factories, and multiple mixins | **Zero**: Works on standard, clean Dart classes (`class User { ... }`) |
| **Speed & DX** | Tied strictly to slow `build_runner` (often 10–30s+ build times) | **Dual Execution**: Standalone CLI runs in **~1.5s**, or use standard `build_runner` |
| **File footprint** | Forces external part files for every single model | **Flexible**: Supports part files, standalone files, or **in-file injection** directly inside the class body |
| **Runtime allocations** | Instantiates helper wrapper objects on every single copy | **0 Extra Allocations**: Direct method execution or zero-allocation mixin |

---

## Installation

Add `cloneable` to your runtime `dependencies`, and `cloneable_generator` (along with `build_runner` if you use it) to your `dev_dependencies`:

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

### Approach 1: Clean Extension (Zero Boilerplate)

Annotate an ordinary Dart class with `@Cloneable()` and declare a `part` file:

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

Run the generator:
```bash
dart run cloneable_generator
```

Use `copyWith`:
```dart
final user = User(name: 'Ahmed', age: 25, nickname: 'Dev');

final updated = user.copyWith(age: 26);         // nickname preserved as 'Dev'
final cleared = user.copyWith(nickname: null);  // nickname explicitly cleared to null
// user.copyWith(name: null);                  // Compile-time analyzer error!
```

---

### Approach 2: In-Class Generation (Zero Extra Files)

If you don't want extra `.g.dart` or part files cluttering your directory tree, use `@Cloneable.inClass()`:

```dart
// lib/models/product.dart
import 'package:cloneable/cloneable.dart';

@Cloneable.inClass()
class Product {
  final String id;
  final String title;
  final double price;
  final String? description;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    this.description,
  });
}
```

Run the generator:
```bash
dart run cloneable_generator
```

The generator injects `copyWith` directly inside the class body between managed comment markers with zero top-of-file clutter:

```dart
// lib/models/product.dart
import 'package:cloneable/cloneable.dart';

@Cloneable.inClass()
class Product {
  final String id;
  final String title;
  final double price;
  final String? description;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    this.description,
  });

// cloneable:start (Product) - GENERATED CODE - DO NOT MODIFY BY HAND
// (run: dart run cloneable_generator to regenerate)
  static const _$undefined = Object();

  Product Function({
    String id,
    String title,
    double price,
    String? description,
  }) get copyWith => _copyWith;

  Product _copyWith({
    Object? id = _$undefined,
    Object? title = _$undefined,
    Object? price = _$undefined,
    Object? description = _$undefined,
  }) {
    final self = this;
    return Product(
      id: identical(id, _$undefined) ? self.id : id as String,
      title: identical(title, _$undefined) ? self.title : title as String,
      price: identical(price, _$undefined) ? self.price : price as double,
      description: identical(description, _$undefined)
          ? self.description
          : description as String?,
    );
  }
// cloneable:end (Product)
}
```

---

### Approach 3: Zero-Allocation Mixin

For high-throughput loops or performance-critical benchmarks (80M+ ops/s), mix in `_$ClassNameCloneable`:

```dart
import 'package:cloneable/cloneable.dart';

part 'order.g.dart';

@Cloneable()
class Order with _$OrderCloneable {
  final String orderId;
  final double total;

  const Order({required this.orderId, required this.total});
}
```

`cloneable_generator` automatically detects the mixin and generates only `mixin _$OrderCloneable` with zero heap allocation on dispatch.

---

## How to Run Code Generation

### Method A: Standalone High-Speed CLI Runner (Recommended)

`cloneable_generator` includes an optimized, standalone command-line executable that parses your Dart AST, resolves project defaults, and writes generated code directly **without invoking `build_runner`**.

```bash
# Run on all files in lib/ (short & ergonomic):
dart run cloneable
# or full command:
dart run cloneable_generator

# Build alias:
dart run cloneable:build
# or:
dart run cloneable:cbuild

# Inline-only alias (processes only inClass and inLibrary models):
dart run cloneable:inline
```

#### Targeting Specific Paths

Run on a specific directory or individual file for instantaneous (~100ms) execution:

```bash
# Target a specific directory:
dart run cloneable_generator lib/models/

# Target an individual file:
dart run cloneable_generator lib/models/user.dart

# Target multiple files or folders:
dart run cloneable_generator lib/models/ auth/ lib/domain/entity.dart
```

#### CLI Flags & Options

| Option | Shorthand | Description | Example |
| :--- | :--- | :--- | :--- |
| `[paths]` | Positional | One or more file or directory paths (defaults to `lib`) | `dart run cloneable_generator lib/models` |
| `--verbose` | `-v` | Prints detailed per-file scanning and generation diagnostics | `dart run cloneable_generator -v` |
| `--prefix=<name>` | `--prefix <name>` | Fallback global symbol prefix | `dart run cloneable_generator --prefix=M_` |
| `--suffix=<name>` | `--suffix <name>` | Fallback global symbol suffix | `dart run cloneable_generator --suffix=Copyable` |
| `--inline-only` | | Only processes in-file models (`inClass` and `inLibrary`) | `dart run cloneable_generator --inline-only` |
| `--part-only` | | Only processes part-file models | `dart run cloneable_generator --part-only` |

#### Smart AST Auto-Injection

When using the CLI runner:
- If a class uses `output: CloneableOutput.part` but is missing a `part '...';` directive, the CLI automatically detects the target filename and **injects the missing `part` directive** into your source file.
- If a class requests a mixin strategy (`CloneableStrategy.mixin`) but omits `with _$ClassNameCloneable`, the CLI **injects the mixin clause** into the class header automatically.

---

### Method B: `build_runner` Pipeline

If your workflow already uses `build_runner` alongside other generators (e.g. `json_serializable`, `riverpod_generator`):

```bash
# One-time build:
dart run build_runner build --delete-conflicting-outputs

# Continuous watch mode:
dart run build_runner watch --delete-conflicting-outputs
```

#### Builders Configured in `build.yaml`

`cloneable_generator` exposes 3 distinct builders in its `build.yaml`:

1. **`cloneable_generator` (Default)**:
   - Shared part builder contributing to `*.g.dart`.
   - Auto-applied to dependent packages.
2. **`cloneable_part_builder`**:
   - Dedicated part builder generating isolated `*_cloneable.g.dart` files.
   - Set `auto_apply: dependents` in your app's `build.yaml` if you want separate part files for copyWith.
3. **`cloneable_standalone_builder`**:
   - Generates standalone `*_cloneable.dart` files (with full imports, no `part of`).

#### Configuring Builder Options in `build.yaml`

In your application's root `build.yaml`:

```yaml
targets:
  $default:
    builders:
      cloneable_generator:
        options:
          prefix: ""
          suffix: "Cloneable"
```

---

## Output Modes (`CloneableOutput`)

`cloneable_generator` gives you four distinct architectural output modes configured via `output: CloneableOutput`:

| Mode | Annotation Constructor | Destination | Best For |
| :--- | :--- | :--- | :--- |
| **Part File** | `@Cloneable.part()` or `@Cloneable()` | Separate `*.g.dart` or `*.cloneable.g.dart` | Clean separation of generated code; projects already using `build_runner` |
| **In-Class** | `@Cloneable.inClass()` | Inside the class body of the source file | Zero extra files; self-contained classes; Flutter widgets or state models |
| **In-Library** | `@Cloneable.inLibrary()` | Top-level extension in the same source file | Single-file models with clean class bodies; no part files |
| **Standalone** | `@Cloneable.standalone()` | Independent `*.cloneable.dart` library file | Clean architecture; exporting extensions without `part` directives |

### 1. Part File Mode (`CloneableOutput.part`)

Generates code into a separate part file:

```dart
import 'package:cloneable/cloneable.dart';

part 'user.g.dart'; // or: part 'user.cloneable.g.dart';

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

### 2. Standalone Mode (`CloneableOutput.standalone`)

Generates an independent library file with its own imports. It does **not** use `part of`:

```dart
// lib/models/customer.dart
import 'package:cloneable/cloneable.dart';

@Cloneable.standalone()
class Customer {
  final String id;
  final String name;
  const Customer({required this.id, required this.name});
}
```

Generated in `customer.cloneable.dart`:
```dart
// lib/models/customer.cloneable.dart
import 'package:cloneable/cloneable.dart';
import 'customer.dart';

extension $CustomerExtension on Customer {
  Customer Function({String id, String name}) get copyWith => _copyWith;
  Customer _copyWith({Object? id = $undefined, Object? name = $undefined}) {
    final self = this;
    return Customer(
      id: identical(id, $undefined) ? self.id : id as String,
      name: identical(name, $undefined) ? self.name : name as String,
    );
  }
}
```

---

### 3. In-Library Mode (`CloneableOutput.inLibrary`)

Emits the extension directly inside your source file at the library top-level between comment markers:

```dart
import 'package:cloneable/cloneable.dart';

@Cloneable.inLibrary()
class Account {
  final String email;
  const Account({required this.email});
}
```

Generated directly in the same file:
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

### 4. In-Class Mode (`CloneableOutput.inClass`)

Emits the `copyWith` and `_copyWith` implementations directly inside the class body before the closing brace:

```dart
import 'package:cloneable/cloneable.dart';

@Cloneable.inClass()
class Settings {
  final bool darkMode;
  final String language;

  const Settings({required this.darkMode, required this.language});
}
```

Generated in-class:
```dart
@Cloneable.inClass()
class Settings {
  final bool darkMode;
  final String language;

  const Settings({required this.darkMode, required this.language});

// cloneable:start (Settings) - GENERATED CODE - DO NOT MODIFY BY HAND
// (run: dart run cloneable_generator to regenerate)
  static const _$undefined = Object();

  Settings Function({
    bool darkMode,
    String language,
  }) get copyWith => _copyWith;

  Settings _copyWith({
    Object? darkMode = _$undefined,
    Object? language = _$undefined,
  }) {
    final self = this;
    return Settings(
      darkMode:
          identical(darkMode, _$undefined) ? self.darkMode : darkMode as bool,
      language:
          identical(language, _$undefined) ? self.language : language as String,
    );
  }
// cloneable:end (Settings)
}
```

---

## Post-Generation Cleanup (`CloneableCleanup`)

`cloneable_generator` supports three post-generation cleanup policies via `cleanup: CloneableCleanup`:

| Policy | Behavior |
| :--- | :--- |
| `CloneableCleanup.none` | Retains all annotations and imports in the source file (default). |
| `CloneableCleanup.deactivate` | Rewrites `@Cloneable(...)` to `@Cloneable(active: false, ...)` in place to disable future regeneration. |
| `CloneableCleanup.remove` | Completely strips `@Cloneable`, `@CloneableField`, and `package:cloneable` imports from source code. |

### 1. `CloneableCleanup.none` (Default)

Leaves annotations intact so that subsequent CLI or build runs keep code updated whenever fields are added or changed.

### 2. `CloneableCleanup.deactivate`

When you want to lock generated code after initial creation:

```dart
@Cloneable(
  output: CloneableOutput.inClass,
  cleanup: CloneableCleanup.deactivate,
)
class ImmutableProfile { ... }
```

After running `dart run cloneable_generator`, the annotation in the source file becomes `@Cloneable(active: false, ...)`. The generator skips the class in all future runs.

### 3. `CloneableCleanup.remove` (Zero Residual Footprint)

Combine `cleanup: CloneableCleanup.remove` with `sentinel: CloneableSentinel.private` to eliminate `package:cloneable` completely from your codebase:

```dart
import 'package:cloneable/cloneable.dart';

@Cloneable(
  output: CloneableOutput.inClass,
  sentinel: CloneableSentinel.private,
  cleanup: CloneableCleanup.remove,
)
class CleanEntity {
  @CloneableField()
  final String id;
  final String name;

  const CleanEntity({required this.id, required this.name});
}
```

Run the generator:
```bash
dart run cloneable_generator
```

Result:
1. Emits the self-contained copy method with private sentinel `static const _$undefined = Object();`.
2. Strips `@Cloneable(...)` and all `@CloneableField(...)` annotations.
3. Removes `import 'package:cloneable/cloneable.dart';` automatically.
4. Your codebase now has **zero external runtime dependencies** and 100% standard Dart code!

> [!NOTE]
> `cleanup: CloneableCleanup.remove` requires `sentinel: CloneableSentinel.private`. If `sentinel` is `CloneableSentinel.package`, the generator preserves the import and annotations to avoid breaking references to canonical `$undefined`.

---

## Project-Wide Defaults via In-Code SSOT (`@Cloneable.defaults`)

Instead of repeating parameters on every model, define global defaults once using `cloneable`'s **Single Source of Truth (SSOT)** configuration architecture.

### 1. Built-In Defaults Reference

When no custom defaults are specified, `cloneable_generator` applies:

| Setting | Type | Built-in Default | Description |
| :--- | :--- | :--- | :--- |
| `output` | `CloneableOutput` | `CloneableOutput.auto` | Auto-detects part file, standalone, or inline output based on directives. |
| `strategy` | `CloneableStrategy` | `CloneableStrategy.auto` | Auto-detects extension vs mixin based on whether the class mixes in `_$Class...`. |
| `sentinel` | `CloneableSentinel` | `CloneableSentinel.auto` | Auto-detects import prefix (`c.$undefined` vs `$undefined`). |
| `deepCopyCollections` | `bool` | `false` | Shallow copies collections for optimal performance and zero heap allocation. |
| `ignoreNull` | `bool` | `false` | Explicitly assigns `null` to nullable fields (supports clearing nullable values). |
| `active` | `bool` | `true` | Code generation active for annotated classes. |
| `cleanup` | `CloneableCleanup` | `CloneableCleanup.none` | Controls post-generation cleanup: `none`, `deactivate`, or `remove`. |
| `fieldsConflict` | `CloneableFieldsConflict` | `CloneableFieldsConflict.error` | Reports a compile error if fields are specified in both annotation and getter. |
| `naming.method` | `String` | `'copyWith'` | Name of the generated copy method and getter. |
| `naming.sentinel` | `String` | `r'_$undefined'` | Private sentinel identifier name (`_$undefined`). |
| `naming.mixin` | `CloneableAffix` | `CloneableAffix(prefix: r'_$', suffix: 'Cloneable')` | Mixin naming pattern (`_$ClassNameCloneable`). |
| `naming.extension` | `CloneableAffix` | `CloneableAffix(prefix: r'$', suffix: 'Extension')` | Extension naming pattern (`$ClassNameExtension`). |
| `naming.file` | `CloneableAffix` | `CloneableAffix(prefix: '', suffix: '.cloneable.g')` | Generated file naming pattern (`$className.cloneable.g.dart`). |
| `naming.directory` | `String?` | `null` | Optional subfolder path for generated files (e.g. `'generated'`). |

### 2. Modern Dart 3+ Configuration Idioms

Declare library or project defaults using any of the following idioms:

#### Library Directive (Recommended)

Place `@Cloneable.defaults(...)` directly above an unnamed `library;` directive:

```dart
@Cloneable.defaults(
  output: CloneableOutput.inClass,
  sentinel: CloneableSentinel.private,
  deepCopyCollections: true,
  naming: CloneableNaming(method: 'copyWith'),
)
library;

import 'package:cloneable/cloneable.dart';
```

#### Shared Project Configuration

Put your defaults in `lib/cloneable_defaults.dart` and import it into your model files:

```dart
// lib/cloneable_defaults.dart
@Cloneable.defaults(
  output: CloneableOutput.part,
  deepCopyCollections: true,
)
library;

import 'package:cloneable/cloneable.dart';
```

`cloneable_generator` automatically discovers defaults across imported files!

### 3. Cascading Precedence Hierarchy

Settings resolve in deterministic order:
1. **Class-Level Annotation (`@Cloneable(...)`)**: Explicit per-class overrides take highest priority. Partial `CloneableAffix` overrides (e.g. specifying only `prefix`) preserve the default suffix.
2. **File / Library In-Code Defaults (`@Cloneable.defaults(...)`)**: Applied to all models declared in that file.
3. **Imported / Shared In-Code Defaults**: Discovered from imported config files.
4. **Built-In Defaults (`CloneableDefaults.instance`)**: Standard fallbacks.

---

## Advanced Features

### Deep Copying for Collections & Typed Data

By default, collections are shallow-copied for speed. Enable `deepCopyCollections: true` to create independent mutable collection copies:

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

`cloneable_generator` supports deep copying across:
- **Standard Collections**: `List`, `Set`, `Map`, `Iterable`
- **Specialized Collections**: `Queue`, `ListQueue`, `DoubleLinkedQueue`, `HashMap`, `LinkedHashMap`, `SplayTreeMap`, `HashSet`, `LinkedHashSet`, `SplayTreeSet`
- **Typed Data Arrays (`dart:typed_data`)**: `Uint8List`, `Int8List`, `Uint8ClampedList`, `Int16List`, `Uint16List`, `Int32List`, `Uint32List`, `Int64List`, `Uint64List`, `Float32List`, `Float64List`, `Float32x4List`, `Int32x4List`, `Float64x2List`, and `ByteData`

---

### Custom Cloner Functions (`@CloneableField(cloner: ...)`)

For custom domain models, nested objects, or third-party immutable collections (`BuiltList`, `IList`), supply a `cloner` tear-off function. **The custom cloner always takes priority over built-in collection copying**:

```dart
static Address _cloneAddress(Address a) => a.copyWith();

@Cloneable()
class UserProfile {
  final String name;

  @CloneableField(cloner: _cloneAddress)
  final Address address;

  @CloneableField(cloner: Uint8List.fromList)
  final Uint8List token;

  const UserProfile({
    required this.name,
    required this.address,
    required this.token,
  });
}
```

---

### Field Whitelisting & Ignoring

#### 1. Blacklisting Fields (`@CloneableField(ignore: true)`)

```dart
@Cloneable()
class Account {
  final String id;
  final String email;

  @CloneableField(ignore: true)
  final DateTime createdAt;

  const Account({required this.id, required this.email, required this.createdAt});
}
```

#### 2. Whitelisting Fields via Annotation (`@Cloneable(fields: [...])`)

```dart
@Cloneable(fields: ['email', 'phone'])
class User {
  final String id;
  final String email;
  final String phone;

  const User({required this.id, required this.email, required this.phone});
}
```

#### 3. Whitelisting Fields via In-Class Getter (`cloneableFields` or `copyWithFields`)

```dart
@Cloneable()
class User {
  final String id;
  final String email;

  const User({required this.id, required this.email});

  List<Object?> get cloneableFields => [email];
}
```

#### 4. Handling Conflict Resolution (`fieldsConflict`)

If fields are declared in both the annotation and the in-class getter, `fieldsConflict` controls resolution:
- `CloneableFieldsConflict.error` (default): Raises a compile-time build error.
- `CloneableFieldsConflict.merge`: Unites fields from both locations.
- `CloneableFieldsConflict.inClass`: Uses fields from the getter.
- `CloneableFieldsConflict.inAnnotation`: Uses fields from the annotation.

---

### Ignoring Null Values (`ignoreNull: true`)

If you want traditional Dart `copyWith` behavior where passing `null` is ignored (preserving the existing value):

```dart
// Field-level:
@CloneableField(ignoreNull: true)
final String? bio;

// Class-level:
@Cloneable(ignoreNull: true)
class User { ... }
```

---

### Custom Constructors & Positional Parameters

#### Named Constructors (`constructor: 'create'`)

```dart
@Cloneable(constructor: 'create')
class Service {
  final String endpoint;
  const Service.create({required this.endpoint});
}
```

#### Positional Constructor Parameters

```dart
@Cloneable()
class Point {
  final double x;
  final double y;
  final double? z;

  const Point(this.x, this.y, [this.z]);
}

final point = Point(10, 20, 30);
final flat = point.copyWith(z: null); // x and y preserved!
```

---

### Generics & Type Bounds

`cloneable_generator` fully preserves generic type variables and bounds:

```dart
@Cloneable()
class Cache<K, V extends Comparable<V>> {
  final K key;
  final V value;

  const Cache({required this.key, required this.value});
}
```

---

### Custom Symbol & File Affixes (`CloneableNaming`)

Customize symbol generation patterns across all targets:

```dart
@Cloneable(
  naming: CloneableNaming(
    method: 'clone',
    mixin: CloneableAffix(prefix: r'_$', suffix: 'Cloneable'),
    extension: CloneableAffix(prefix: 'Ext', suffix: 'Methods'),
    file: CloneableAffix(prefix: '', suffix: '.cloneable'),
    directory: 'generated',
  ),
)
class Config { ... }
```

---

### Smart Sentinel Resolution (`CloneableSentinel`)

- **`CloneableSentinel.auto` (Default)**: Automatically detects if `package:cloneable` was imported with a prefix (`import ... as c;` $\rightarrow$ `c.$undefined`) or bare (`$undefined`). In `inClass` mode, automatically injects a self-contained private sentinel.
- **`CloneableSentinel.private`**: Emits a self-contained private sentinel `static const _$undefined = Object();` (or `const _$undefined = Object();`). Works with zero external imports.
- **`CloneableSentinel.package`**: Always targets canonical `$undefined`.

---

## Troubleshooting & FAQ

### 1. `Compile error: The argument type 'Null' can't be assigned to 'String'`

**Cause**: You called `.copyWith(name: null)` on a non-nullable field `final String name;`.  
**Fix**: `cloneable_generator` intentionally enforces non-nullable type safety at compile time. Only nullable fields (`String? nickname`) accept `null`.

### 2. `Missing 'part' directive in source file` (when using `build_runner`)

**Cause**: A class uses `CloneableOutput.part` (the default) without declaring `part '<filename>.g.dart';`.  
**Fix**: Add `part '<filename>.g.dart';` to your source file, or switch to `@Cloneable.inClass()` for in-file generation. When using the CLI (`dart run cloneable_generator`), this directive is injected automatically!

### 3. `Cannot use private cloner function across standalone library boundary`

**Cause**: A private top-level cloner function `_clone(...)` was passed to `@CloneableField(cloner: _clone)` on a class using `output: CloneableOutput.standalone`.  
**Fix**: Standalone files cannot access private members of other libraries. Make the cloner public (e.g. `cloneAddress`) or use `output: CloneableOutput.part` / `inClass`.

---

## Supporting & Contributing

If you find `cloneable_generator` helpful, here are several ways you can support the project:

### 🌟 Community Support

- **Star the Repository**: Star [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages) on GitHub to help others discover it.
- **Report Issues & Ideas**: Found a bug or need an improvement? Open an issue on [GitHub Issues](https://github.com/ahmedm-gh/dart-packages/issues).
- **Contribute**: Pull requests for optimizations, documentation, or examples are always welcome.
- **Spread the Word**: Recommend `cloneable_generator` in your Flutter/Dart teams, blogs, or communities.

### ☕ Sponsorship & Backing

- **Sponsor on GitHub**: Support ongoing maintenance via [GitHub Sponsors](https://github.com/sponsors/ahmedm-gh).
- **Buy Me a Coffee**: Support development with a one-time coffee or recurring donation via [Buy Me a Coffee](https://buymeacoffee.com/ahmeds1).

## Author & Maintainer

Created and maintained by **[AHMED M.](https://github.com/ahmedm-gh)**  

- GitHub: [@ahmedm-gh](https://github.com/ahmedm-gh)
- Repository: [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages)

## License

This package is licensed under the [MIT License](./LICENSE).
