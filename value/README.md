# value

A lightweight Dart utility container object which may or may not contain a value.

Used to represent optional values, cleanly separating the state of a value being **unset (absent)** from a value being **explicitly null** (e.g. for `copyWith` methods, patch requests, and optional parameters).

## Features

- **`Val<T>(value)`**: Wraps a given value.
- **`Val<T>.absent()`**: Represents an absent / omitted value.
- **`Val<T>.clear()`**: Represents an explicitly cleared value (`null`).
- **`asVal`**: Convenient extension getter on any type to wrap it into a `Val<T>`.
- Callable instance `val(current)` to conveniently resolve fallback values when absent.

## Usage

```dart
import 'package:value/value.dart';

class User {
  final String name;
  final String? bio;

  User({required this.name, this.bio});

  User copyWith({
    Val<String> name = const Val.absent(),
    Val<String?> bio = const Val.absent(),
  }) {
    return User(
      name: name(this.name),
      bio: bio(this.bio),
    );
  }
}

void main() {
  final user = User(name: 'Alice', bio: 'Developer');

  // Keep existing bio
  final u1 = user.copyWith(name: 'Bob'.asVal);
  print(u1.bio); // Developer

  // Clear bio explicitly to null
  final u2 = user.copyWith(bio: const Val.clear());
  print(u2.bio); // null
}
```
