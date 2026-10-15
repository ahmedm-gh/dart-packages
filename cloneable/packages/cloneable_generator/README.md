# cloneable_generator

[![Pub Version](https://img.shields.io/pub/v/cloneable_generator.svg)](https://pub.dev/packages/cloneable_generator)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Dart SDK](https://img.shields.io/badge/Dart-%3E%3D3.5.0%20%3C4.0.0-blue.svg)](https://dart.dev)

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

Annotate your model:

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

Run code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or start a continuous file watcher during development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

---

## Generated Output Architecture

For each annotated class `User`, `cloneable_generator` produces:

1. **An abstract callable interface (`$UserCopyWith`)**: Declares optional named parameters matching the class constructor. Non-nullable parameters are declared without default values, giving the Dart static analyzer the exact signature required to reject `null` at compile time.
2. **A mixin (`_$UserCloneable`)**: Implements `$UserCopyWith<User>` and overrides the `call` method. The `copyWith` getter simply returns `this`, resulting in **zero heap allocations** for wrapper objects.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
