# caster

[![pub package](https://img.shields.io/pub/v/caster.svg)](https://pub.dev/packages/caster)
[![Star on GitHub](https://img.shields.io/badge/Star_on_GitHub-★-deeppink?style=flat&logo=github)](https://github.com/ahmedm-gh/dart-packages)
[![GitHub](https://img.shields.io/badge/GitHub-ahmedm--gh-blue?logo=github)](https://github.com/ahmedm-gh)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-pink?logo=github)](https://github.com/sponsors/ahmedm-gh)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A zero-dependency, safe, and flexible casting toolkit for Dart with multi-tiered resolution policies, sensible type defaults, registered fallbacks, and safe `Map` extraction extensions.

---

## Features

- **Multi-Tiered Resolution Policy**:
  1. Direct type match fast path.
  2. Explicit `fallback` when provided.
  3. Custom registered default values via `Caster.registerDefaultValues`.
  4. Built-in defaults for common Dart types (`int`, `double`, `num`, `bool`, `String`, `List`, `Set`, `Map`).
  5. Safe `null` fallback when the target type is nullable (`null is T`).
  6. Descriptive `CasterTypeException` when non-nullable casting fails without a fallback.
- **Strict Type Checking**: Disallows ambiguous `safeCast<Object>`, `safeCast<Object?>`, or untyped `safeCast<dynamic>` calls by throwing a `CasterArgumentException`.
- **Fully Generic with Automatic Type Inference**: Functions and extensions automatically infer target type `T` from variable annotations, function parameters, or return types—omitting verbose generic arguments.
- **`safeCastOrNull<T>`**: Quick optional cast without default synthesis.
- **`MapCaster` Extensions**:
  - `map.safeCast<T>('key')`: Safely cast a value from a map.
  - `map.safeCastOrNull<T>('key')`: Safely cast a value or return null on mismatch.
  - `map.safeCastFirst<T>(['altKey', 'primaryKey'])`: Resolve the first valid key in a fallback list.
  - `map.safeCastList<T>('items')`: Extract and filter valid typed elements from raw iterables.
  - `map.safeCastListOrNull<T>('items')`: Extract valid typed elements or return null if key is absent or not an iterable.
  - `map.convert<T>('key', converter: ...)`: Parse values with custom transforms and required fallback.
  - `map.tryConvert<T>('key', converter: ...)`: Parse values with custom transforms returning `T?` with optional fallback.
  - `map.convertList<T>('items', converter: ...)`: Map and filter items with custom element converters and optional fallback.
  - `map.convertListOrNull<T>('items', converter: ...)`: Map and filter items or return null if key is absent or not an iterable.
- **Zero Dependencies**: Pure Dart with no third-party package dependencies.
- **Blazing Fast**: Optimized for minimal latency and zero unnecessary allocations.
- **Diagnostic Debug Logging**: Trace casting decisions with `debug: true` via standard `dart:developer` logging.

---

## Getting Started

### Installation

Add `caster` to your `pubspec.yaml`:

```yaml
dependencies:
  caster: ^1.0.0
```

Or run:

```bash
dart pub add caster
# or for Flutter
flutter pub add caster
```

### Import

```dart
import 'package:caster/caster.dart';
```

---

## Usage

### 1. Basic Safe Casting

```dart
import 'package:caster/caster.dart';

// 1. Direct match
final a = safeCast<int>(42); // 42

// 2. Explicit fallback
final b = safeCast<int>('not an int', fallback: 10); // 10

// 3. Built-in type defaults
final c = safeCast<int>('bad'); // 0
final s = safeCast<String>(123); // ''
final flag = safeCast<bool>(null); // false
final list = safeCast<List<int>>('invalid'); // <int>[]

// 4. Nullable target types
final n = safeCast<DateTime?>('uncastable'); // null

// 5. Disable default fallback (bypasses built-in/registered defaults)
// Throws CasterTypeException instead of returning 0:
// safeCast<int>('bad', useDefaults: false);

// 6. safeCastOrNull
final maybeString = safeCastOrNull<String>(123); // null
```

### 2. When to Use `safeCast` vs `safeCastOrNull`

Both functions offer type-safe conversions, but serve different requirements:

| Feature / Behavior | `safeCast<T>` | `safeCastOrNull<T>` |
| :--- | :--- | :--- |
| **Return Type** | `T` | `T?` |
| **Resolution Strategy** | Multi-tiered: Direct match → Fallback → Registered default → Built-in type default → Nullable fallback | Direct match → `null` |
| **Built-in Defaults** | Yes (`0`, `""`, `false`, `[]`, `{}`, etc.) | No (never synthesizes fake defaults) |
| **Explicit Fallback** | Supported via `fallback: ...` | None (always `null` on mismatch) |
| **Default Suppression** | Supported via `useDefaults: false` | N/A (defaults are never used) |
| **Throws On Mismatch** | Throws `CasterTypeException` if non-nullable and no default exists (or if defaults disabled) | Never throws type exception |

#### Use `safeCast<T>` when

- **You need guaranteed non-nullable data**: You want a sensible fallback default (e.g. `0` for numbers, `""` for strings, `[]` for collections) instead of handling `null`.
- **You want a specific custom fallback**: You need to provide an explicit fallback value with `fallback: defaultValue`.
- **You rely on registered domain defaults**: You have configured global defaults with `Caster.registerDefaultValues()`.
- **You want fail-fast type validation**: For domain entities without defaults (or with `useDefaults: false`), throwing `CasterTypeException` immediately reveals invalid or corrupted payloads during development.

```dart
// Guarantees non-nullable values with sensible defaults or fallbacks:
final count = safeCast<int>(rawJson['count']); // Defaults to 0 if missing or invalid
final role = safeCast<String>(rawJson['role'], fallback: 'viewer'); // 'viewer'
```

#### Use `safeCastOrNull<T>` when

- **The value is genuinely optional**: You want `null` if the input is missing or of the wrong type.
- **You do NOT want fabricated defaults**: For example, when `0` or `""` would be misleading because it wasn't the actual input.
- **Chaining with Dart's null-aware operators**: You want to seamlessly chain with `?.`, `??`, or `if-null` statements.
- **Lightweight type-narrowing**: You need a fast, zero-configuration cast without resolving default registries.

```dart
// Preserves absence without synthesizing defaults:
final DateTime? createdAt = safeCastOrNull(rawJson['created_at']);
final String? avatarUrl = safeCastOrNull(rawJson['avatar_url']);

// Clean chaining with null-aware operators:
final formatted = safeCastOrNull<DateTime>(rawJson['date'])?.toIso8601String() ?? 'N/A';
```

### 3. Automatic Type Inference

Because `caster` functions and extensions are fully generic, Dart automatically infers the target type `T` from the surrounding context (such as typed variable declarations, function arguments, or class fields). When `T` is inferred, you don't have to specify `<Type>` manually:

```dart
// 1. Inferred from typed variable declarations:
int id = safeCast(json['id']);                 // Infers safeCast<int>
String name = safeCast(json['name']);          // Infers safeCast<String>
String? bio = safeCastOrNull(json['bio']);     // Infers safeCastOrNull<String>

// 2. Inferred from function parameters:
void setProfile({required int id, required String name}) { ... }

setProfile(
  id: safeCast(json['id']),         // Infers <int> automatically
  name: safeCast(json['name']),     // Infers <String> automatically
);

// 3. Inferred with MapCaster extensions:
int age = json.safeCast('age');               // Infers safeCast<int>
List<String> tags = json.safeCastList('tags'); // Infers safeCastList<String>

// 4. Explicit type argument is only required when declaring untyped variables:
final count = safeCast<int>(json['count']);    // Explicit <int> needed for untyped 'final'
```

### 4. Custom Type Default Values

Register fallback defaults for domain models or complex types:

```dart
class User {
  final String name;
  const User(this.name);
}

// Register a single default
Caster.registerDefaultValue(const User('Guest'));

// Or register multiple defaults in batch
Caster.registerDefaultValues({
  User: const User('Guest'),
});

final user = safeCast<User>('invalid_payload');
print(user.name); // 'Guest'

// Unregister single or multiple defaults when no longer needed
Caster.unregisterDefaultValue<User>();
Caster.unregisterDefaultValues([User]);

// Or clear all registrations (e.g. in test tearDown)
Caster.resetDefaultValues();
```

### 5. `MapCaster` Extensions for Untrusted Payloads

Safely parse untrusted dynamic Maps, JSON responses, or query parameters:

```dart
final json = <String, dynamic>{
  'id': 101,
  'name': 'Ahmed',
  'tags': ['dart', 123, 'web'],
  'profile': null,
};

// Extract single value with automatic type default or fallback
final id = json.safeCast<int>('id'); // 101
final role = json.safeCast<String>('role', fallback: 'user'); // 'user'
final maybeProfile = json.safeCastOrNull<String>('profile'); // null

// Resolve first available key
final title = json.safeCastFirst<String>(
  ['title', 'headline', 'name'],
  fallback: 'Untitled',
); // 'Ahmed'

// Filter and extract typed elements from an iterable
final tags = json.safeCastList<String>('tags'); // ['dart', 'web']
final tagsWithFallback = json.safeCastList<String>('tags', fallback: 'unknown');
// ['dart', 'unknown', 'web']

// Extract collection or return null if key is absent/not an iterable
final maybeTags = json.safeCastListOrNull<String>('missing_key'); // null

// Custom transformation with required fallback
final parsedId = json.convert<String>(
  'id',
  converter: (val) => val != null ? 'USER_$val' : null,
  fallback: 'USER_0',
); // 'USER_101'

// Optional custom transformation returning T?
final maybeDate = json.tryConvert<DateTime>(
  'created_at',
  converter: (val) => val is String ? DateTime.tryParse(val) : null,
); // null if key missing or unparseable

// Convert collection elements into model objects or parsed values
final scores = json.convertList<int>(
  'scores',
  converter: (val) => val is num ? val.toInt() : null,
  fallback: 0,
);

// Convert collection or return null if key is absent/not an iterable
final maybeScores = json.convertListOrNull<int>(
  'missing_scores',
  converter: (val) => val is num ? val.toInt() : null,
); // null
```

### 6. Error Handling

`caster` throws specific exceptions under predictable failure conditions:

- **`CasterArgumentException`**: Thrown if `T` is unconstrained (`Object`, `Object?`, or `dynamic`) without specifying a concrete target type.
- **`CasterTypeException`**: Thrown when a non-nullable type cannot be cast, no fallback was passed, and no default value is defined.

Both classes inherit from `CasterException`, which implements Dart's `Exception`:

```dart
try {
  final result = safeCast<CustomType>('invalid');
} on CasterTypeException catch (e) {
  print('Type cast failed: ${e.message}');
} on CasterArgumentException catch (e) {
  print('Invalid type argument: ${e.message}');
} on CasterException catch (e) {
  print('General caster error: ${e.message}');
}
```

### 7. Debug Logging

Enable global diagnostic logging by setting `Caster.debug = true` (tagged with `Caster.loggerName`, which is `'caster'`):

```dart
Caster.debug = true;

safeCast<int>('hello', fallback: 5);
// Dispatches to dart:developer.log:
// name: 'caster', message: 'Trying to cast String (hello) to int'
// name: 'caster', message: 'Using fallback for int'
```

---

## Supporting & Contributing

If you find `caster` helpful, here are several ways you can support the project:

### 🌟 Community Support

- **Star the Repository**: Star [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages) on GitHub to help others discover it.
- **Report Issues & Ideas**: Found a bug or need an improvement? Open an issue on [GitHub Issues](https://github.com/ahmedm-gh/dart-packages/issues).
- **Contribute**: Pull requests for optimizations, documentation, or examples are always welcome.
- **Spread the Word**: Recommend `caster` in your Flutter/Dart teams, blogs, or communities.

### ☕ Sponsorship & Backing

- **Sponsor on GitHub**: If this package brings value to your commercial apps, consider supporting its maintenance via [GitHub Sponsors](https://github.com/sponsors/ahmedm-gh).
- **Buy Me a Coffee**: Support development with a one-time coffee or recurring donation via [Buy Me a Coffee](https://buymeacoffee.com/ahmeds1).

## Author & Maintainer

Created and maintained by **[AHMED M.](https://github.com/ahmedm-gh)**  

- GitHub: [@ahmedm-gh](https://github.com/ahmedm-gh)
- Repository: [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages)

## License

This package is licensed under the [MIT License](./LICENSE).
