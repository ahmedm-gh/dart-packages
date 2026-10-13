# value

An ultra-fast, zero-overhead Dart container for tri-state optional values—cleanly separating absent from explicitly null at sub-nanosecond speeds (~0.21 ns/op).

Used to represent optional values, cleanly separating the state of a value being **unset (absent)** from a value being **explicitly null** (e.g. for `copyWith` methods, patch requests, and optional parameters).

## Features

- **Ultra-Fast & Zero-Overhead**: Sub-nanosecond resolution (~0.21 ns/op), zero external dependencies, fully `const`-constructible, and zero GC pressure.
- **`Val<T>(value)`**: Wraps a given value (pass `null` to explicitly clear).
- **`Val<T>.absent()`**: Represents an absent / omitted value.
- Callable instance `fooVal(current)` to conveniently resolve fallback values when absent.

## Usage

> **Note**: `Val` is primarily intended for **nullable fields** (`Val<T?>`). Non-nullable fields typically do not need `Val` because a standard nullable parameter (`String? name`) already uses `null` to mean "keep current value" (`name ?? this.name`). Passing `Val(null)` to a non-nullable `Val<T>` will fail fast with a `TypeError`.

```dart
import 'package:value/value.dart';

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

## Performance Notes

- **Sub-Nanosecond Resolution**: Resolving values via `val(current)` compiles to devirtualized inlined leaf operations in AOT release mode, executing in **~0.21 ns/op** without generic type-table lookup overhead.
- **Zero-Field Absent Instance**: `Val.absent()` contains zero instance fields, minimizing memory footprint and instance overhead.
- **Canonical `const` Allocations**: `const Val.absent()` and `const Val(...)` reuse canonical instances at compile time, eliminating heap allocations and garbage collection pressure.

## Pros & Cons

### Pros

- **Accurate Tri-State Handling**: Cleanly separates *omitted (absent)* from *explicitly null* without ambiguity.
- **Zero Dependencies**: Pure Dart utility with zero external dependencies.
- **No Code Generation**: Works immediately in plain Dart without `build_runner`, `freezed`, or reflection.
- **Full `const` Support**: All constructors are `const`-constructible for maximum efficiency.
- **Ergonomic Callable Syntax**: `bio(this.bio)` resolves values and fallback defaults in a single, concise expression.

### Cons

- **Call-Site Wrapping**: Dart lacks union types (`T | Val<T>`), requiring callers to wrap arguments (`Val(value)` or `const Val(null)`) for nullable fields.
- **Unnecessary for Non-Nullable Fields**: Non-nullable fields (`String name`) do not need `Val`, as standard Dart `String? name` with `name ?? this.name` already handles the omitted state cleanly.
