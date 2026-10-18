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

- **Inline models** (`@Cloneable(inline: true)`): Injects/updates `copyWith` directly inside the file between markers.
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

## In-File (Inline) Generation Mode

If you prefer keeping the generated `copyWith` code directly inside your source files instead of creating separate `.g.dart` or part files:

1. Annotate your class with `@Cloneable(inline: true)`:

```dart
import 'package:cloneable/cloneable.dart';

@Cloneable(inline: true)
class User {
  final String name;
  final String? email;

  const User({required this.name, this.email});
}
```

2. Run the code generator CLI:

```bash
dart run cloneable_generator
```

The generator detects all classes marked with `inline: true` and injects or updates the generated definitions between special delimiter comments:

```dart
// cloneable:start (User) - GENERATED CODE - DO NOT MODIFY BY HAND
// (run: dart run cloneable_generator to regenerate)
typedef $UserCopyWith = User Function({
  String name,
  String? email,
});

extension $UserCloneableExtension on User {
  $UserCopyWith get copyWith => _copyWith;

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

- **Clean & Scope-Protected**: Easily identified, updated, or safely edited.
- **Fast & Incremental**: Only files needing updates are modified.
- **Auto-Cleanup**: Removing `@Cloneable(inline: true)` automatically strips the obsolete marker block on the next run.

---

## Generated Output Architecture

For each annotated class `User`, `cloneable_generator` produces:

1. **A strongly-typed signature typedef (`$UserCopyWith`)**: Declares optional named parameters matching the class constructor. Non-nullable parameters are declared without default values, giving the Dart static analyzer the exact signature required to reject `null` at compile time.
2. **A mixin (`_$UserCloneable` / `_$UserCopyWith`) or Extension (`$UserCloneableExtension`)**: Implements or extends `$UserCopyWith<User>` and overrides the copy method. The getter simply returns the implementation method, resulting in **zero heap allocations** for wrapper objects.
3. **Smart Sentinel Resolution (`CloneableSentinel`)**: Automatically detects import prefixes (e.g. `import 'package:cloneable/cloneable.dart' as c;` $\rightarrow$ `c.cloneableUndefined`) or generates self-contained private sentinels (`static const Object _undefined = Object();`) when configured with `CloneableSentinel.private`.
4. **Field Whitelisting (`fields`)**: Respects explicit field allowlists defined either in `@Cloneable(fields: [...])` or via in-class getters (`cloneableFields`, `copyWithFields`, or a custom name configured via `cloneableFieldsGetter`), exposing only allowed fields in `copyWith` while preserving omitted fields via `self.$field`. If explicitly empty (`[]`), code generation for the class is completely ignored (identical to `active: false`).

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
