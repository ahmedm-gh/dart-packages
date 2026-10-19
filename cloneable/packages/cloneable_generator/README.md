# cloneable_generator

[![pub package](https://img.shields.io/pub/v/cloneable_generator.svg)](https://pub.dev/packages/cloneable_generator)
[![Star on GitHub](https://img.shields.io/badge/Star_on_GitHub-★-deeppink?style=flat&logo=github)](https://github.com/ahmedm-gh/dart-packages)
[![GitHub](https://img.shields.io/badge/GitHub-ahmedm--gh-blue?logo=github)](https://github.com/ahmedm-gh)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-pink?logo=github)](https://github.com/sponsors/ahmedm-gh)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

The code generator companion for the [`cloneable`](https://pub.dev/packages/cloneable) package, providing automatic code generation for strongly typed `copyWith` methods with explicit `null` support via `build_runner`.

---

## Installation

In your application's `pubspec.yaml`:

```yaml
dependencies:
  cloneable: ^1.0.0

dev_dependencies:
  build_runner: ^2.4.0
  cloneable_generator: ^1.0.0
```

---

## Usage

### 1. Annotate your model

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

### 2. Run the Generator

#### Option A: Standalone CLI (Zero `build_runner`, ~1.5s)

You can generate code directly using the standalone CLI without needing `build_runner`:

```bash
dart run cloneable_generator
# or
dart run cloneable_generator:build
```

You can also target specific files or directories:

```bash
dart run cloneable_generator lib/models/user.dart
```

- **In-Library models** (`@Cloneable(output: CloneableOutput.inLibrary)`): Injects/updates top-level extension and typedef directly inside the file between markers.
- **In-Class models** (`@Cloneable(output: CloneableOutput.inClass)`): Injects/updates copyWith method directly inside the class body between markers.
- **Part-file models** (`@Cloneable()`): Generates clean `*.g.dart` or `*.cloneable.dart` files directly with zero clutter.

---

### Option B: `build_runner` Pipeline

If your project already uses `build_runner` for other packages (e.g. `json_serializable`):

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or continuous watch mode during development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

---

## In-File Generation Modes (`inLibrary` & `inClass`)

If you prefer keeping the generated `copyWith` code directly inside your source files instead of creating separate `.g.dart` or part files, you can choose between two output modes:

### 1. In-Library Mode (`output: CloneableOutput.inLibrary`)

Annotate your class with `@Cloneable(output: CloneableOutput.inLibrary)`:

```dart
import 'package:cloneable/cloneable.dart';

@Cloneable(output: CloneableOutput.inLibrary)
class User {
  final String name;
  final String? email;

  const User({required this.name, this.email});
}
```

The generator emits the top-level extension and signature typedef directly inside the file between managed comment markers:

```dart
// cloneable:start (User) - GENERATED CODE - DO NOT MODIFY BY HAND
// (run: dart run cloneable_generator to regenerate)
typedef $UserCopyWithFn = User Function({
  String name,
  String? email,
});

extension $UserExtension on User {
  $UserCopyWithFn get copyWith => _copyWith;

  User _copyWith({
    Object? name = cloneableUndefined,
    Object? email = cloneableUndefined,
  }) {
    final self = this;
    return User(
      name: identical(name, cloneableUndefined) ? self.name : name as String,
      email:
          identical(email, cloneableUndefined) ? self.email : email as String?,
    );
  }
}
// cloneable:end (User)
```

### 2. In-Class Mode (`output: CloneableOutput.inClass`)

Annotate your class with `@Cloneable(output: CloneableOutput.inClass)`:

```dart
import 'package:cloneable/cloneable.dart';

@Cloneable(output: CloneableOutput.inClass)
class User {
  final String name;
  final String? email;

  const User({required this.name, this.email});
}
```

The generator emits the typedef at the top of the file and the `copyWith` and `_copyWith` methods directly inside the class body before the closing brace:

```dart
class User {
  final String name;
  final String? email;

  const User({required this.name, this.email});

// cloneable:start (User) - GENERATED CODE - DO NOT MODIFY BY HAND
// (run: dart run cloneable_generator to regenerate)
  $UserCopyWithFn get copyWith => _copyWith;

  User _copyWith({
    Object? name = cloneableUndefined,
    Object? email = cloneableUndefined,
  }) {
    final self = this;
    return User(
      name: identical(name, cloneableUndefined) ? self.name : name as String,
      email:
          identical(email, cloneableUndefined) ? self.email : email as String?,
    );
  }
// cloneable:end (User)
}
```

### 3. Clean Removal of Annotations (`cleanup: CloneableCleanup.remove`)

Combine `cleanup: CloneableCleanup.remove` with `sentinel: CloneableSentinel.private` to eliminate `package:cloneable` completely from your codebase after generation:

```dart
import 'package:cloneable/cloneable.dart';

@Cloneable(
  output: CloneableOutput.inClass,
  sentinel: CloneableSentinel.private,
  cleanup: CloneableCleanup.remove,
)
class User {
  final String name;
  final String? email;

  const User({required this.name, this.email});
}
```

When run, the CLI generator injects the self-contained code, strips `@Cloneable` and `@CloneableField`, and removes the `import 'package:cloneable/cloneable.dart';` line.

> [!NOTE]
> Only recommended if the developer intends to perform a one-time generation and maintain or regenerate the code manually, leaving zero residual annotations and imports in the codebase.

---

## Project Defaults via In-Code SSOT (`@Cloneable.defaults`)

`cloneable_generator` supports in-code Single Source of Truth (SSOT) configuration with zero third-party dependencies.

### 1. The Full Built-In Defaults Set (`CloneableDefaults.instance`)

When no custom defaults or class-level overrides are provided, the generator uses the following built-in defaults:

| Property | Type | Default Value | Description |
| :--- | :--- | :--- | :--- |
| `output` | `CloneableOutput` | `CloneableOutput.auto` | Auto-detects part file, standalone, or inline output based on context and directives. |
| `strategy` | `CloneableStrategy` | `CloneableStrategy.auto` | Auto-detects mixin vs extension based on whether class mixes in `_$Class...`. |
| `sentinel` | `CloneableSentinel` | `CloneableSentinel.auto` | Auto-detects import prefix (`c.$undefined` vs `$undefined`). |
| `deepCopyCollections` | `bool` | `false` | Shallow-copies collections for maximum speed and zero extra heap allocation. |
| `ignoreNull` | `bool` | `false` | Explicitly assigns `null` to nullable fields (supports clearing nullable fields). |
| `active` | `bool` | `true` | Code generation active for annotated classes. |
| `cleanup` | `CloneableCleanup` | `CloneableCleanup.none` | Controls post-generation cleanup: `none`, `deactivate`, or `remove`. |
| `fieldsConflict` | `CloneableFieldsConflict` | `CloneableFieldsConflict.error` | Reports a compile error if fields are specified in both annotation and getter. |
| `naming.method` | `String` | `'copyWith'` | The generated copy method and getter name. |
| `naming.mixin` | `CloneableAffix` | `CloneableAffix(prefix: r'_$', suffix: 'Cloneable')` | Mixin naming pattern (`_$ClassNameCloneable`). |
| `naming.extension` | `CloneableAffix` | `CloneableAffix(prefix: r'$', suffix: 'Extension')` | Extension naming pattern (`$ClassNameExtension`). |
| `naming.typedef` | `CloneableAffix` | `CloneableAffix(prefix: r'$', suffix: 'CopyWithFn')` | Typedef function signature pattern (`$ClassNameCopyWithFn`). |
| `naming.file` | `CloneableAffix` | `CloneableAffix(prefix: '', suffix: '.cloneable.g')` | Generated file naming pattern (`$className.cloneable.g.dart`). |
| `naming.sentinel` | `String` | `r'_$undefined'` | Private sentinel identifier name (`_$undefined`). |

### 2. Clean Alternatives in Modern Dart (Dart 3+)

In modern Dart, you can declare project or library defaults using any of the following clean idioms:

#### Alternative A: Unnamed Library Directive (Recommended)

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

#### Alternative B: Modern Abstract Final Config Class

Create a dedicated, uninstantiable configuration class:

```dart
import 'package:cloneable/cloneable.dart';

@Cloneable.defaults(
  strategy: CloneableStrategy.extension,
  deepCopyCollections: true,
  naming: CloneableNaming(
    mixin: CloneableAffix(prefix: 'M_'),
  ),
)
abstract final class CloneableConfig {}
```

#### Alternative C: Top-Level Constant

Declare a top-level constant instance of `CloneableDefaults`:

```dart
import 'package:cloneable/cloneable.dart';

const cloneableConfig = CloneableDefaults(
  output: CloneableOutput.standalone,
  ignoreNull: true,
);
```

#### Alternative D: Shared Project Configuration

Place your defaults in a shared file (e.g. `lib/cloneable_defaults.dart`) and import it wherever models are declared. The generator automatically discovers defaults across imported libraries.

### 3. Cascading Precedence

1. **Class Annotation (`@Cloneable(...)`)**: Explicit per-class settings take highest priority. Partial `CloneableAffix` overrides (e.g. specifying only `prefix`) preserve the underlying default suffix.
2. **File / Library In-Code Defaults (`@Cloneable.defaults(...)`)**: Applied to all annotated classes in the file or library.
3. **Imported / Shared In-Code Defaults**: Discovered from imported config files.
4. **Built-In Defaults (`CloneableDefaults.instance`)**: Standard fallbacks.

---

## Generated Output Architecture

For each annotated class `User`, `cloneable_generator` produces:

1. **A strongly-typed signature typedef (`$UserCopyWithFn`)**: Declares optional named parameters matching the class constructor. Non-nullable parameters are declared without default values, giving the Dart static analyzer the exact signature required to reject `null` at compile time.
2. **A mixin (`_$UserCloneable`) or Extension (`$UserExtension`)**: Implements or extends `$UserCopyWithFn<User>` and overrides the copy method. The getter simply returns the implementation method, resulting in **zero heap allocations** for wrapper objects.
3. **Smart Sentinel Resolution (`CloneableSentinel`)**: Automatically detects import prefixes (e.g. `import 'package:cloneable/cloneable.dart' as c;` $\rightarrow$ `c.$undefined`) or generates self-contained private sentinels (`const _$undefined = Object();` or `static const _$undefined = Object();`) when configured with `CloneableSentinel.private`.
4. **Field Whitelisting (`fields`)**: Respects explicit field allowlists defined either in `@Cloneable(fields: [...])` or via in-class getters (`cloneableFields`, `copyWithFields`, or a custom name configured via `cloneableFieldsGetter`), exposing only allowed fields in `copyWith` while preserving omitted fields via `self.$field`. If explicitly empty (`[]`), code generation for the class is completely ignored (identical to `active: false`).
5. **Customizable Symbol & File Naming (`naming: CloneableNaming(...)`)**: Configurable symbol prefix and suffix for extensions, mixins, typedefs, and files via `CloneableAffix(prefix: ..., suffix: ...)`. Supports target affixes (`mixin`, `extension`, `typedef`, `file`), method name (`method: 'copyWith'`), and approach-specific affixes (`part`, `standalone`, `inLibrary`, `inClass`).

---

## Supporting & Contributing

If you find `cloneable_generator` helpful, here are several ways you can support the project:

### 🌟 Community Support

- **Star the Repository**: Star [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages) on GitHub to help others discover it.
- **Report Issues & Ideas**: Found a bug or need an improvement? Open an issue on [GitHub Issues](https://github.com/ahmedm-gh/dart-packages/issues).
- **Contribute**: Pull requests for optimizations, documentation, or examples are always welcome.
- **Spread the Word**: Recommend `cloneable_generator` in your Flutter/Dart teams, blogs, or communities.

### ☕ Sponsorship & Backing

- **Sponsor on GitHub**: If this package brings value to your commercial apps, consider supporting its maintenance via [GitHub Sponsors](https://github.com/sponsors/ahmedm-gh).
- **Buy Me a Coffee**: Support development with a one-time coffee or recurring donation via [Buy Me a Coffee](https://buymeacoffee.com/ahmeds1).

## Author & Maintainer

Created and maintained by **[AHMED M.](https://github.com/ahmedm-gh)**  

- GitHub: [@ahmedm-gh](https://github.com/ahmedm-gh)
- Repository: [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages)

## License

This package is licensed under the [MIT License](./LICENSE).
