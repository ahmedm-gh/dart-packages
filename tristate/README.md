# tristate

[![pub package](https://img.shields.io/pub/v/tristate.svg)](https://pub.dev/packages/tristate)
[![GitHub](https://img.shields.io/badge/GitHub-ahmedm--gh-blue?logo=github)](https://github.com/ahmedm-gh)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-pink?logo=github)](https://github.com/sponsors/ahmedm-gh)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

An ultra-fast, zero-overhead Dart container for tri-state optional values—cleanly separating absent from explicitly null at sub-nanosecond speeds (~0.21 ns/op).

Used to represent optional values, cleanly separating the state of a value being **unset (absent)** from a value being **explicitly null** (e.g. for `copyWith` methods, patch requests, and optional parameters).

---

## Features

- **Accurate Tri-State Handling**: Cleanly separates *omitted (absent)* from *explicitly null* without ambiguous sentinel values.
- **Fully Generic with Automatic Type Inference**: Infers type parameter `T` automatically from surrounding context (e.g. named parameter types in `copyWith`). When `T` is inferred, explicit type arguments can be omitted.
- **`Val<T>(value)`**: Wraps a given value (pass `null` to explicitly clear).
- **`Val<T>.absent()`**: Represents an absent / omitted value.
- **Callable Instance Syntax**: `bioVal(current)` resolves fallback values when absent in a single, concise expression.
- **Zero Dependencies**: Pure Dart with no third-party runtime dependencies.
- **Blazing Fast**: Sub-nanosecond resolution (~0.21 ns/op) with zero GC pressure.

---

## Getting Started

### Installation

Add `tristate` to your `pubspec.yaml`:

```yaml
dependencies:
  tristate: ^1.0.4
```

Or run:

```bash
dart pub add tristate
# or for Flutter
flutter pub add tristate
```

### Import

```dart
import 'package:tristate/tristate.dart';
```

---

## Usage

### 1. Basic Usage: The `copyWith` Pattern

> **Note**: `Val` is primarily intended for **nullable fields** (`Val<T?>`). Non-nullable fields typically do not need `Val` because a standard nullable parameter (`String? name`) already uses `null` to mean "keep current value" (`name ?? this.name`). Passing `null` to a non-nullable `Val<T>` is rejected at compile time.

```dart
import 'package:tristate/tristate.dart';

class User {
  final String name; // non-nullable: uses standard Dart
  final String? bio;  // nullable: uses Val to distinguish absent vs null

  User({required this.name, this.bio});

  User copyWith({
    String? name,
    Val<String?> bio = const Val.absent(),
  }) {
    return User(
      name: name ?? this.name,
      bio: bio(this.bio),
    );
  }
}

void main() {
  final user = User(name: 'Ahmed', bio: 'Developer');

  // Update non-nullable field directly
  final u1 = user.copyWith(name: 'Bob');
  print(u1.name); // Bob
  print(u1.bio);  // Developer

  // Clear bio explicitly to null
  final u2 = user.copyWith(bio: const Val(null));
  print(u2.bio);  // null

  // Update bio with a new value
  final u3 = user.copyWith(bio: const Val('Designer'));
  print(u3.bio);  // Designer
}
```

### 2. Automatic Type Inference & Compile-Time Safety

Because `Val<T>` is fully generic, Dart's type system automatically infers `T` from the target context (e.g. method or constructor parameters and typed variable assignments). You never need to write `Val<Type>` manually when the context type is known:

```dart
// Type `T` is automatically inferred as `String?` from User.copyWith's bio parameter:
user.copyWith(bio: const Val(null));       // Inferred as Val<String?>
user.copyWith(bio: const Val('Designer')); // Inferred as Val<String?>
user.copyWith(bio: const Val.absent());    // Inferred as Val<String?>

// No need to write:
// user.copyWith(bio: const Val<String?>(null));
```

---

## Performance Notes

- **Sub-Nanosecond Resolution**: Resolving values via `val(current)` compiles to devirtualized inlined leaf operations in AOT release mode, executing in **~0.21 ns/op** without generic type-table lookup overhead.
- **Zero-Field Absent Instance**: `Val.absent()` contains zero instance fields, minimizing memory footprint and instance overhead.
- **Canonical `const` Allocations**: `const Val.absent()` and `const Val(...)` reuse canonical instances at compile time, eliminating heap allocations and garbage collection pressure.

---

## Pros & Cons

### Pros

- **Accurate Tri-State Handling**: Cleanly separates *omitted (absent)* from *explicitly null* without ambiguity.
- **Fully Generic & Inferred**: Seamlessly works with any type `T`. Dart infers `T` automatically from function and constructor parameter types, keeping call sites clean.
- **Zero Dependencies**: Pure Dart utility with zero external dependencies.
- **No Code Generation**: Works immediately in plain Dart without `build_runner`, `freezed`, or reflection.
- **Full `const` Support**: All constructors are `const`-constructible for maximum efficiency.
- **Ergonomic Callable Syntax**: `bio(this.bio)` resolves values and fallback defaults in a single, concise expression.

### Cons

- **Call-Site Wrapping**: Dart lacks union types (`T | Val<T>`), requiring callers to wrap arguments (`Val(value)` or `const Val(null)`) for nullable fields.
- **Unnecessary for Non-Nullable Fields**: Non-nullable fields (`String name`) do not need `Val`, as standard Dart `String? name` with `name ?? this.name` already handles the omitted state cleanly.

---

## Supporting & Contributing

If you find `tristate` helpful, here are several ways you can support the project:

### 🌟 Community Support

- **Star the Repository**: Star [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages) on GitHub to help others discover it.
- **Report Issues & Ideas**: Found a bug or need an improvement? Open an issue on [GitHub Issues](https://github.com/ahmedm-gh/dart-packages/issues).
- **Contribute**: Pull requests for optimizations, documentation, or examples are always welcome.
- **Spread the Word**: Recommend `tristate` in your Flutter/Dart teams, blogs, or communities.

### ☕ Sponsorship & Backing

- **Sponsor on GitHub**: If this package brings value to your commercial apps, consider supporting its maintenance via [GitHub Sponsors](https://github.com/sponsors/ahmedm-gh).

## Author & Maintainer

Created and maintained by **[AHMED M.](https://github.com/ahmedm-gh)**  

- GitHub: [@ahmedm-gh](https://github.com/ahmedm-gh)
- Repository: [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages)

## License

This package is licensed under the [MIT License](./LICENSE).

