# cloneable

[![pub package](https://img.shields.io/pub/v/cloneable.svg)](https://pub.dev/packages/cloneable)
[![Star on GitHub](https://img.shields.io/badge/Star_on_GitHub-★-deeppink?style=flat&logo=github)](https://github.com/ahmedm-gh/dart-packages)
[![GitHub](https://img.shields.io/badge/GitHub-ahmedm--gh-blue?logo=github)](https://github.com/ahmedm-gh)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-pink?logo=github)](https://github.com/sponsors/ahmedm-gh)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A lightweight, highly customizable, production-grade Dart package that generates **strongly typed** `copyWith` methods for ordinary Dart classes, with first-class support for explicitly setting nullable fields to `null`.

---

## Features

- **Intuitive Developer Experience**: Annotate ordinary Dart classes with `@Cloneable()` (clean extensions with zero boilerplate, or as mixin `with _$UserCloneable`).
- **First-Class Explicit `null`**: Distinguishes between omitting an argument (retaining existing value) and passing `null` (clearing a nullable field).
- **Compile-Time Type Safety**: Statically prevents passing `null` to non-nullable fields (`user.copyWith(name: null)` is an analyzer compile error).
- **Zero Runtime Allocations**: Unlike other generators that instantiate intermediate wrapper objects on each `copyWith` invocation, `cloneable` uses a zero-allocation mixin pattern (`get copyWith => this;`).
- **Universal Dart & Flutter Support**: 100% compatible with Flutter, Dart VM, Web, Server, WASM, and AOT compilation.
- **Pure Runtime Footprint**: Zero third-party runtime dependencies.

---

## Installation

Add `cloneable` to your `dependencies`, and `build_runner` and `cloneable_generator` to your `dev_dependencies`:

```yaml
dependencies:
  cloneable: ^1.0.0

dev_dependencies:
  build_runner: ^2.4.0
  cloneable_generator: ^1.0.0
```

---

## Quick Start

### 1. Define your model

With `cloneable`, there is **no need to type `with _$UserCloneable`**! You can write a completely clean, ordinary Dart class:

```dart
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

*(Note: If you prefer mixins for zero-allocation performance, you can still write `class User with _$UserCloneable` — `cloneable` auto-detects both!)*

### 2. Run the generator

Run the standard build_runner command in your terminal:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or for Flutter projects:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Use `copyWith`

```dart
final original = User(
  name: 'Ahmed',
  age: 25,
  nickname: 'Dev',
);

// 1. Update specific fields (unmodified fields are preserved)
final updated = original.copyWith(
  name: 'Mohamed',
  age: 26,
);
// updated.name == 'Mohamed'
// updated.age == 26
// updated.nickname == 'Dev'

// 2. Explicitly clear a nullable field to null
final cleared = original.copyWith(
  nickname: null,
);
// cleared.name == 'Ahmed'
// cleared.age == 25
// cleared.nickname == null

// 3. Statically caught errors at compile time:
// original.copyWith(name: null); // Compile error: The argument type 'Null' can't be assigned to 'String'
```

---

## Detailed Semantics

| Invocation | `name` (non-nullable) | `nickname` (nullable) | Semantics |
| :--- | :--- | :--- | :--- |
| `original.copyWith()` | Preserved (`Ahmed`) | Preserved (`Dev`) | No-op clone |
| `original.copyWith(name: 'Ali')` | Replaced (`Ali`) | Preserved (`Dev`) | Single field update |
| `original.copyWith(nickname: null)` | Preserved (`Ahmed`) | **Cleared (`null`)** | Explicit `null` assignment |
| `original.copyWith(name: null)` | **Compile Error** | N/A | Static analyzer rejects `null` |

---

## Supported Patterns

### Generation Strategy: Extension vs Mixin (`CloneableStrategy`)

`cloneable` supports generating `copyWith` as either a **Dart Extension** or a **Dart Mixin**:

```dart
enum CloneableStrategy {
  auto,      // Default: auto-detects based on presence of mixin
  extension, // Generates an Extension (zero boilerplate on class)
  mixin,     // Generates a Mixin (requires `with _$UserCloneable` or `with _$UserCopyWith`)
}
```

- **`CloneableStrategy.auto` (Default)**:
  - If your class omits any mixin, it automatically generates an **Extension**. Your class stays 100% clean with zero extra code.
  - If your class mixes in one of the 2 supported conventions, it automatically generates only that **Mixin**:
    - `with _$UserCloneable` (*Scoped style* — explicit, collision-proof)
    - `with _$UserCopyWith` (*Capability style* — self-documenting)
  - **Only the written mixin is generated** — no dead code, no duplicate mixins, and no IDE autocomplete pollution!
- **`CloneableStrategy.extension`**: Forces extension generation.
- **`CloneableStrategy.mixin`**: Forces mixin generation using whichever mixin name is written.

### Custom Method / Getter Name (`naming: CloneableNaming(method: ...)`)

By default, the generated method and getter is named `copyWith`. You can customize this name (e.g., to `clone`, `rebuild`, or `copy`) using the `method` parameter in `CloneableNaming`:

```dart
@Cloneable(naming: CloneableNaming(method: 'clone'))
class Document with _$DocumentClone {
  final String title;
  const Document({required this.title});
}

final doc = Document(title: 'Specs');
final cloned = doc.clone(title: 'New Specs');
```

### Customizable Symbol & File Naming (`CloneableNaming`)

By default, generated symbols use standard affixes (such as `_$` prefix for mixins, `$` prefix for extensions and typedefs). You can customize these affixes across all output modes via `naming: CloneableNaming(...)`:

```dart
// 1. Part approach with custom mixin affix
@Cloneable(
  strategy: CloneableStrategy.mixin,
  naming: CloneableNaming(
    mixin: CloneableAffix(prefix: '_', suffix: 'Cloneable'),
  ),
)
class User with _UserCloneable { ... }
// Generates:
// - typedef $UserCopyWithFn
// - mixin _UserCloneable

// 2. Standalone approach with custom extension affix
@Cloneable(
  strategy: CloneableStrategy.extension,
  naming: CloneableNaming(
    extension: CloneableAffix(prefix: 'Custom', suffix: 'Extension'),
  ),
)
class Order { ... }
// Generates (in order.cloneable.dart):
// - typedef $OrderCopyWithFn
// - extension CustomOrderExtension on Order

// 3. In-library approach with custom typedef and extension affixes
@Cloneable(
  output: CloneableOutput.inLibrary,
  naming: CloneableNaming(
    extension: CloneableAffix(prefix: '', suffix: 'CloneableExt'),
    typedef: CloneableAffix(prefix: '', suffix: 'CopySignature'),
  ),
)
class Product { ... }
// Generates (in-library between markers):
// - typedef ProductCopySignature
// - extension ProductCloneableExt on Product
```

### Selective Part File Naming & Standalone Files

`cloneable` gives you complete flexibility in how generated code is integrated into your project:

#### 1. Selective Part File Names

You are not restricted to `part 'foo.g.dart';`. `cloneable` dynamically detects and accepts any of the following part directives:

- `part 'foo.g.dart';` (*Shared part* — merges with other code generators like `json_serializable`)
- `part 'foo_cloneable.g.dart';` or `part 'foo.cloneable.g.dart';` (*Dedicated scoped part*)
- `part 'foo_copyWith.g.dart';` or `part 'foo.copyWith.g.dart';` (*Dedicated capability part*)
- `part 'foo_<methodName>.g.dart';` (*Matching your custom method name, e.g. `foo_clone.g.dart`*)

#### 2. Standalone Mode (No `part` or `part of` Required)

If you omit `part` directives altogether, `cloneable` **does not enforce `part` or emit `part of`**. Instead, it generates a clean standalone file (e.g. `foo_cloneable.dart`) with its own imports (`import 'package:cloneable/cloneable.dart';` and `import 'foo.dart';`) providing the extension methods. You can simply import it wherever needed!

### In-File Generation (`output: CloneableOutput.inLibrary` & `CloneableOutput.inClass`)

Prefer keeping the generated `copyWith` implementation directly inside the same file without creating a `part` or separate `.g.dart` file?

`cloneable` provides two dedicated in-file generation modes:

#### 1. In-Library Mode (`output: CloneableOutput.inLibrary`)

Generates the extension and copyWith signature typedef at the library top level:

```dart
import 'package:cloneable/cloneable.dart';

@Cloneable(output: CloneableOutput.inLibrary)
class User {
  final String name;
  final String? email;

  const User({required this.name, this.email});
}
```

#### 2. In-Class Mode (`output: CloneableOutput.inClass`)

Generates `copyWith` and `_copyWith` directly inside the class body itself (with the typedef signature placed at library top level):

```dart
import 'package:cloneable/cloneable.dart';

@Cloneable(output: CloneableOutput.inClass)
class User {
  final String name;
  final String? email;

  const User({required this.name, this.email});
}
```

Then run the code generator CLI:

```bash
dart run cloneable_generator
# or
dart run cloneable_generator:build
```

The generator will inject or update the implementation directly inside the file, delimited by identifiable scope comments:

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
    Object? name = $undefined,
    Object? email = $undefined,
  }) {
    final self = this;
    return User(
      name: identical(name, $undefined) ? self.name : name as String,
      email:
          identical(email, $undefined) ? self.email : email as String?,
    );
  }
}
// cloneable:end (User)
```

- **Scope-Protected**: The delimiters mark the exact boundary of the generated code. Any edits outside these comments remain intact.
- **Auto-Cleanup**: Removing the annotation and re-running `dart run cloneable_generator` automatically removes obsolete marker blocks.
- **Idempotent**: Re-running the command does not touch files that are already up to date.
- **Target Specific Paths**: You can pass directories or individual files:
  ```bash
  dart run cloneable_generator lib/models/user.dart
  ```

### Zero Residual Footprint: Clean Removal (`cleanup: CloneableCleanup.remove`)

If you want code generated directly into your source code and wish to eliminate `package:cloneable` from your codebase, use `cleanup: CloneableCleanup.remove` in conjunction with `sentinel: CloneableSentinel.private`:

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

When you run `dart run cloneable_generator`:
1. The generator emits 100% self-contained code (with a private `static const _$undefined = Object();`).
2. It automatically removes `@Cloneable` and `@CloneableField` annotations from the source file.
3. It automatically removes `import 'package:cloneable/cloneable.dart';` once all annotated classes in the file have been processed.

> [!NOTE]
> Only recommended if the developer intends to perform a one-time generation and maintain or regenerate the code manually, leaving zero residual annotations and imports in the codebase.

### Generic Classes & Type Bounds

`cloneable` fully preserves generic type variables and bounds:

```dart
@Cloneable()
class Box<T> with _$BoxCloneable<T> {
  final T value;
  final T? optionalValue;

  const Box({required this.value, this.optionalValue});
}

@Cloneable()
class BoundedContainer<T extends num> with _$BoundedContainerCloneable<T> {
  final T score;

  const BoundedContainer({required this.score});
}
```

### Custom Constructors

By default, the generator uses the unnamed constructor. To target a named constructor, specify the `constructor` parameter:

```dart
@Cloneable(constructor: 'create')
class ServiceConfig with _$ServiceConfigCloneable {
  final String host;
  final int port;

  const ServiceConfig.create({required this.host, required this.port});
}
```

### Positional Constructor Parameters

Generative constructors with positional parameters are fully supported:

```dart
@Cloneable()
class Coordinate with _$CoordinateCloneable {
  final double x;
  final double y;
  final double? z;

  const Coordinate(this.x, this.y, [this.z]);
}

final coord = Coordinate(10.0, 20.0, 30.0);
final flat = coord.copyWith(z: null); // coord.x and coord.y preserved!
```

### Deep Copy for Collections & Custom Types

By default, fields are shallow-copied (super fast, zero heap reallocation). If you need independent, mutable collection instances (so modifying `cloned.tags.add(...)` does not mutate `original.tags`), enable collection deep-copying:

#### 1. Class-Level Deep Copying

`cloneable` natively supports deep-copying across:
- **Standard Collections**: `List`, `Set`, `Map`, `Iterable`
- **Specialized Collections**: `Queue`, `ListQueue`, `HashMap`, `LinkedHashMap`, `SplayTreeMap`, `HashSet`, `LinkedHashSet`, `SplayTreeSet`
- **Typed Data Arrays (`dart:typed_data`)**: `Uint8List`, `Int8List`, `Uint8ClampedList`, `Int16List`, `Uint16List`, `Int32List`, `Uint32List`, `Int64List`, `Uint64List`, `Float32List`, `Float64List`, `Float32x4List`, `Int32x4List`, `Float64x2List`, and `ByteData`

```dart
@Cloneable(deepCopyCollections: true)
class Team with _$TeamCloneable {
  final List<String> members;
  final Set<int> badgeIds;
  final Map<String, dynamic> metadata;
  final Uint8List payload;
  final List<String>? optionalTags;

  const Team({
    required this.members,
    required this.badgeIds,
    required this.metadata,
    required this.payload,
    this.optionalTags,
  });
}

final team = Team(
  members: ['Alice', 'Bob'],
  badgeIds: {1, 2},
  metadata: {'lead': 'Alice'},
  payload: Uint8List.fromList([1, 2, 3]),
);

final cloned = team.copyWith();
cloned.members.add('Charlie');
cloned.payload[0] = 99;

// original is untouched!
// team.members == ['Alice', 'Bob']
// team.payload == [1, 2, 3]
```

#### 2. Field-Level Deep Copying (or Overrides)

You can enable deep copying for specific fields or disable it for select fields:

```dart
@Cloneable()
class Project with _$ProjectCloneable {
  final List<String> shallowTags; // shallow copy (default)

  @CloneableField(deepCopy: true)
  final List<String> deepTags; // independent copy via List.of

  const Project({required this.shallowTags, required this.deepTags});
}
```

#### 3. Custom Cloner Functions (`@CloneableField(cloner: ...)`)

For custom domain models, specialized third-party immutable collections (`BuiltList`, `IList`), or custom clone logic, provide a `cloner` function reference. **The `cloner` method always has highest priority over built-in deep-copy logic**:

```dart
static Address _cloneAddress(Address a) => a.copyWith();

@Cloneable()
class UserProfile with _$UserProfileCloneable {
  final String name;

  // Uses custom cloner for deep domain model duplication:
  @CloneableField(cloner: _cloneAddress)
  final Address address;

  // Uses Uint8List factory for defensive cloning:
  @CloneableField(cloner: Uint8List.fromList)
  final Uint8List rawBytes;

  const UserProfile({
    required this.name,
    required this.address,
    required this.rawBytes,
  });
}
```

> [!TIP]
> **Zero Unnecessary Imports**: When using standalone generation (`output: CloneableOutput.standalone`), `dart:typed_data` and `dart:collection` are **only imported if actually used and deepCopy is active**, keeping your generated files lean and minimal.

### IDE Hover & Parameter Autocompletion

`cloneable` generates strongly-typed typedef signatures for each class (e.g. `typedef $UserCopyWith = User Function({String name, int age, String? nickname})`).
When hovering over `.copyWith` in your editor (VS Code, Android Studio, IntelliJ), the tooltip displays the full parameter list with exact nullability and types.

### Excluding Fields

Use `@CloneableField(ignore: true)` to exclude a field from `copyWith`:

```dart
@Cloneable()
class AuditedEntity with _$AuditedEntityCloneable {
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

### Whitelisting Supported Fields (`fields`)

Instead of blacklisting individual fields with `@CloneableField(ignore: true)`, you can specify an allowlist of fields supported by `copyWith`. This is conceptually similar to `props` in `Equatable`.

You can configure the allowlist either via the `@Cloneable` annotation or directly inside the class:

#### 1. Via Annotation (`@Cloneable(fields: [...])`)

```dart
@Cloneable(fields: ['name', 'age'])
class User with _$UserCloneable {
  final String id;
  final String name;
  final int age;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.age,
    required this.createdAt,
  });
}

// Only `name` and `age` are exposed in copyWith:
final updated = user.copyWith(name: 'Ali');
// user.copyWith(id: 'new_id'); // Compile-time analyzer error!
```

#### 2. Via In-Class Getter (`cloneableFields` or `copyWithFields`)

When defining the whitelist directly inside the class, use **`cloneableFields`** or **`copyWithFields`**. It is intentionally named this way (rather than `fields`) so it never collides with domain model properties on the class itself (e.g. `final List<Field> fields;`):

```dart
@Cloneable()
class User with _$UserCloneable {
  final String id;
  final String name;
  final int age;

  const User({
    required this.id,
    required this.name,
    required this.age,
  });

  // Whitelist supported fields:
  List<Object?> get cloneableFields => [name, age];
  // Alternatively: List<Object?> get copyWithFields => [name, age];
}
```

#### 3. Custom In-Class Getter Name (`cloneableFieldsGetter`)

By default, the generator checks `const ['cloneableFields', 'copyWithFields']`. If your project follows a different naming convention (e.g. `props`), you can specify a custom getter name using `cloneableFieldsGetter`:

```dart
@Cloneable(cloneableFieldsGetter: 'props')
class User with _$UserCloneable {
  final String id;
  final String name;
  final int age;

  const User({required this.id, required this.name, required this.age});

  List<Object?> get props => [name, age];
}
```

> [!NOTE]
>
> - **Explicitly Empty List (`[]`)**: If `fields` (or the in-class getter) is explicitly empty (e.g. `@Cloneable(fields: [])` or `get cloneableFields => []`), code generation for the class is completely ignored and skipped (identical to setting `active: false`).
> - **Omitted fields are preserved**: Fields omitted from the whitelist (such as `id` or `createdAt`) are automatically passed into the constructor using their current instance values (`self.id`, `self.createdAt`).
> - **Conflict Resolution (`fieldsConflict`)**: When allowed fields are specified in both `@Cloneable(fields: ...)` and an in-class getter (`cloneableFields` / `copyWithFields`), `fieldsConflict` controls how the conflict is resolved:
>   - `CloneableFieldsConflict.error` (default): Raises an informative compile-time build error.
>   - `CloneableFieldsConflict.merge`: Combines fields from both the annotation and the getter (union of allowed fields).
>   - `CloneableFieldsConflict.inClass`: Prefers and uses only the fields defined in the in-class getter.
>   - `CloneableFieldsConflict.inAnnotation`: Prefers and uses only the fields defined in the `@Cloneable(fields: ...)` annotation.
> - **Compile-Time Validation**: If any name in the whitelist does not match a constructor parameter, `cloneable_generator` flags it with a clear compilation error.

### Ignoring Null Values (`ignoreNull: true`)

By default, `cloneable` supports explicitly clearing nullable fields to `null` (`user.copyWith(nickname: null)` sets `nickname = null`).

If you want normal/traditional Dart behavior where passing `null` is **ignored** (keeping the existing value):

#### 1. Field-Level (`@CloneableField(ignoreNull: true)`)

```dart
@Cloneable()
class Profile with _$ProfileCloneable {
  final String username;

  @CloneableField(ignoreNull: true)
  final String? bio;

  const Profile({required this.username, this.bio});
}

final profile = Profile(username: 'Ahmed', bio: 'Developer');
final updated = profile.copyWith(bio: null);
// updated.bio remains 'Developer'! (null was ignored)
```

#### 2. Class-Level (`@Cloneable(ignoreNull: true)`)

```dart
@Cloneable(ignoreNull: true)
class User with _$UserCloneable {
  final String name;
  final String? bio;
  final int? score;

  const User({required this.name, this.bio, this.score});
}
```

### Sentinel Strategy & Import Prefix Support (`CloneableSentinel`)

When generating `copyWith`, `cloneable` uses a sentinel value to distinguish between an omitted argument (retain current value) and an explicitly passed `null` (clear nullable field).

By default, `cloneable` uses `CloneableSentinel.auto`, which automatically detects whether you imported `package:cloneable` with an import prefix (e.g. `import 'package:cloneable/cloneable.dart' as c;`) or directly without a prefix, emitting the appropriate sentinel seamlessly:

```dart
enum CloneableSentinel {
  auto,    // Default: automatically detects import prefix or bare constant
  private, // Generates a self-contained, scoped private sentinel (_$undefined)
  package, // Strictly references the canonical package constant ($undefined)
}
```

- **`CloneableSentinel.auto` (Default)**:
  - If imported with a prefix (`import ... as c;`), generates `c.$undefined`.
  - If imported directly without a prefix, generates `$undefined`.
  - Seamlessly handles test, standalone, and in-library environments.
- **`CloneableSentinel.private`**:
  - Injects a private sentinel (defaulting to `const _$undefined = Object();` deduplicated once at the file level, or `static const _$undefined = Object();` for `inClass` output).
  - Customizable via `CloneableNaming.sentinel` (e.g., `naming: CloneableNaming(sentinel: r'_$unset')`).
  - 100% self-contained: works even if `package:cloneable` is hidden, removed via `cleanup: CloneableCleanup.remove`, or not imported.
- **`CloneableSentinel.package`**:
  - Explicitly references the canonical `$undefined` from `package:cloneable`.

Example:

```dart
@Cloneable(sentinel: CloneableSentinel.private)
class IsolatedUser {
  final String name;
  const IsolatedUser({required this.name});
}
```

### Disabling Code Generation (`active: false`)

To disable code generation for an annotated class without removing the annotation, set `active: false`:

```dart
@Cloneable(active: false)
class DraftModel {
  final String title;
  const DraftModel({required this.title});
}
```

When `active: false`, the generator completely ignores the class, runs no validations, and emits no code. Defaults to `true`.

### Type Alias / Custom Annotation Name (`typedef UseCopyWith = Cloneable`)

If your project conventions or team preferences favor an alternative annotation name (such as `@UseCopyWith`, `@CopyWith`, or any other custom name instead of `@Cloneable`), you can define a simple `typedef` alias anywhere in your project:

```dart
import 'package:cloneable/cloneable.dart';

/// Define your custom annotation alias:
typedef UseCopyWith = Cloneable;
// or: typedef CopyWith = Cloneable;
// or any other custom name (e.g. typedef GenerateCopyWith = Cloneable;)
```

Then annotate your classes directly using your preferred alias:

```dart
@UseCopyWith()
class User with _$UserCloneable {
  final String name;
  final int age;

  const User({required this.name, required this.age});
}
```

Because `cloneable_generator` inspects the underlying static type of the annotation, `typedef` aliases are fully recognized without any additional configuration or plugins.

### Generation Output Strategy (`CloneableOutput`)

Control how and where code generation is emitted for your class using `output: CloneableOutput`:

```dart
@Cloneable(output: CloneableOutput.part)
class User with _$UserCloneable { ... }
```

- **`CloneableOutput.auto`** (default): Automatically detects output mode:
  - If a matching `part '...';` directive exists, generates code into that part file.
  - If no `part` directive is present, generates code as a clean standalone file.
- **`CloneableOutput.part`**: Enforces generation into a separate `part of` file (e.g. `.g.dart` or `.cloneable.dart`).
  - *Build Runner*: Throws an `InvalidGenerationSourceError` if the required `part` directive is missing.
  - *CLI Runner*: Automatically injects the missing `part` directive into your source file!
- **`CloneableOutput.standalone`**: Generates independent standalone files with explicit imports (no `part of` directive required).
- **`CloneableOutput.inLibrary`**: Emits the extension and typedef directly inside your source file at the library top level between managed comment markers.
- **`CloneableOutput.inClass`**: Emits the `copyWith` and `_copyWith` implementation directly inside the class body between managed comment markers (with typedef at library top level).

> [!TIP]
> **CLI Auto-Injection**: When running the CLI runner (`dart run cloneable_generator`), missing mixin declarations (e.g. `with _$UserCloneable`) and missing `part` directives are automatically injected directly into your source code AST! In contrast, `build_runner` strictly enforces compile-time safety by reporting informative errors with exact resolution steps.

### Custom Prefix & Suffix Configuration (`CloneableNaming` & `CloneableAffix`)

Customize generated symbol and file names globally or per class via `naming: CloneableNaming(...)` using the reusable `CloneableAffix(prefix: ..., suffix: ...)` structure:

```dart
@Cloneable(
  naming: CloneableNaming(
    method: 'copyWith',
    mixin: CloneableAffix(prefix: r'_$', suffix: 'Cloneable'),
    extension: CloneableAffix(prefix: 'Ext', suffix: 'Extension'),
    typedef: CloneableAffix(prefix: 'Signature', suffix: 'Fn'),
    file: CloneableAffix(prefix: '', suffix: '.cloneable'),
  ),
)
class User {
  final String name;
  const User({required this.name});
}
```

#### 1. Method Name

- **`method`** (defaults to `'copyWith'`): sets the copy method and getter name (e.g. `method: 'clone'`).

#### 2. Target Affixes (`CloneableAffix`)

Symbol names follow the pattern `${prefix}${className}${suffix}`, where the raw core value in the middle is the annotated class name (`${className}`):

| Target | Parameter | Default Affix | Default Symbol for `User` | Description |
| --- | --- | --- | --- | --- |
| **Mixin** | `mixin` | `CloneableAffix(prefix: r'_$', suffix: 'Cloneable')` | `mixin _$UserCloneable` | Generated mixin definition |
| **Extension** | `extension` | `CloneableAffix(prefix: r'$', suffix: 'Extension')` | `extension $UserExtension on User` | Generated extension definition |
| **Typedef** | `typedef` | `CloneableAffix(prefix: r'$', suffix: 'CopyWithFn')` | `typedef $UserCopyWithFn = User Function(...)` | Strongly-typed copy function signature |
| **File** | `file` | `CloneableAffix(prefix: '', suffix: '.cloneable.g')` | `user.cloneable.g.dart` | Generated part / standalone file naming |

#### 3. Granular Approach Overrides

Apply specific affix overrides depending on the output approach:

- **`part`**: `CloneableAffix` applied when generating in `part of` files.
- **`standalone`**: `CloneableAffix` applied when generating standalone (non-part) files.
- **`inLibrary`**: `CloneableAffix` applied when generating inside the library at top level.
- **`inClass`**: `CloneableAffix` applied when generating inside the class body.

```dart
@Cloneable(
  naming: CloneableNaming(
    part: CloneableAffix(prefix: 'P', suffix: 'Part'),
    standalone: CloneableAffix(prefix: 'Solo', suffix: 'Standalone'),
    inLibrary: CloneableAffix(prefix: 'Lib', suffix: 'TopLevel'),
    inClass: CloneableAffix(prefix: 'Internal', suffix: 'Member'),
  ),
)
class ConfigModel { ... }
```

### Single Source of Truth (SSOT) & Project-Wide Defaults

Instead of repeating configuration options across every class, `cloneable` provides a unified **Single Source of Truth (SSOT)** in-code configuration architecture with zero third-party dependencies.

#### 1. The Full Built-In Defaults Set (`CloneableDefaults.instance`)

When no custom defaults or class-level overrides are provided, `cloneable` uses the following built-in defaults:

| Property | Type | Default Value | Description |
| :--- | :--- | :--- | :--- |
| `output` | `CloneableOutput` | `CloneableOutput.auto` | Auto-detects part file, standalone, or inline output based on context and directives. |
| `strategy` | `CloneableStrategy` | `CloneableStrategy.auto` | Auto-detects mixin vs extension based on whether class mixes in `_$Class...`. |
| `sentinel` | `CloneableSentinel` | `CloneableSentinel.auto` | Auto-detects import prefix (`c.$undefined` vs `$undefined`). |
| `deepCopyCollections` | `bool` | `false` | Shallow-copies collections for maximum speed and zero extra heap allocation. |
| `ignoreNull` | `bool` | `false` | Explicitly assigns `null` to nullable fields (supports clearing nullable fields). |
| `cleanup` | `CloneableCleanup` | `CloneableCleanup.none` | Controls post-generation cleanup: `none`, `deactivate`, or `remove`. |
| `fieldsConflict` | `CloneableFieldsConflict` | `CloneableFieldsConflict.error` | Reports a compile error if fields are specified in both annotation and getter. |
| `naming.method` | `String` | `'copyWith'` | The generated copy method and getter name. |
| `naming.mixin` | `CloneableAffix` | `CloneableAffix(prefix: r'_$', suffix: 'Cloneable')` | Mixin naming pattern (`_$ClassNameCloneable`). |
| `naming.extension` | `CloneableAffix` | `CloneableAffix(prefix: r'$', suffix: 'Extension')` | Extension naming pattern (`$ClassNameExtension`). |
| `naming.typedef` | `CloneableAffix` | `CloneableAffix(prefix: r'$', suffix: 'CopyWithFn')` | Typedef function signature pattern (`$ClassNameCopyWithFn`). |
| `naming.file` | `CloneableAffix` | `CloneableAffix(prefix: '', suffix: '.cloneable.g')` | Generated file naming pattern (`$className.cloneable.g.dart`). |
| `naming.sentinel` | `String` | `r'_$undefined'` | Private sentinel identifier name (`_$undefined`). |

#### 2. Clean Alternatives in Modern Dart (Dart 3+)

In modern Dart, you can declare project or library defaults using any of the following clean idioms:

##### Alternative A: Unnamed Library Directive (Recommended)

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

##### Alternative B: Modern Abstract Final Config Class

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

##### Alternative C: Top-Level Constant

Declare a top-level constant instance of `CloneableDefaults`:

```dart
import 'package:cloneable/cloneable.dart';

const cloneableConfig = CloneableDefaults(
  output: CloneableOutput.standalone,
  ignoreNull: true,
);
```

##### Alternative D: Shared Project Configuration

Place your defaults in a shared file (e.g. `lib/cloneable_defaults.dart`) and import it wherever models are declared. The generator automatically discovers defaults across imported libraries.

#### 3. Cascading Precedence

Settings resolve with deterministic, layered precedence:
1. **Class Annotation (`@Cloneable(...)`)**: Explicit per-class overrides take highest priority. Partial `CloneableAffix` overrides (e.g. specifying only `prefix`) preserve the underlying default suffix.
2. **File / Library In-Code Defaults (`@Cloneable.defaults(...)`)**: Applied to all annotated classes in the file or library.
3. **Imported / Shared In-Code Defaults**: Discovered from imported config files.
4. **Built-In Defaults (`CloneableDefaults.instance`)**: Standard fallbacks.

#### 4. First-Class Named Constructors

To eliminate parameter contradictions and enhance readability, `Cloneable` provides dedicated named constructors tailored to each output mode:

```dart
// 1. In-class copyWith (no mixin or separate files needed)
@Cloneable.inClass()
class User { ... }

// 2. In-library extension
@Cloneable.inLibrary()
class Product { ... }

// 3. Enforced part file generation
@Cloneable.part(strategy: CloneableStrategy.mixin)
class Order with _$OrderCloneable { ... }

// 4. Standalone file generation
@Cloneable.standalone()
class Invoice { ... }
```

#### 5. Programmatic Runtime Setter

For unit testing or dynamic environments, you can adjust default values programmatically:

```dart
Cloneable.setDefaults(
  deepCopyCollections: true,
  sentinel: CloneableSentinel.private,
);
```

---

## Performance Benchmarks

Measured on Windows x64 with Dart SDK 3.13.4 (stable) across 5 rounds of 500,000 iterations:

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

### Benchmark Insights: Extension vs Mixin

- **Sub-2 Nanosecond Difference**: The Extension strategy runs within **~1.2 ns** of the Mixin strategy (~13.3 ns vs ~12.1 ns), achieving over **75 million operations per second**.
- **The Trade-Off**:
  - **Extension Strategy**: Maximum ergonomics. Leaves your class 100% clean (`class User { ... }`) without any `with _$UserCloneable` mixin declaration.
  - **Mixin Strategy**: Maximum throughput. Avoids closure instantiation on the getter for zero-allocation dispatch.
- **10x Faster than Dynamic Alternatives**: Both strategies outperform map-based or dynamic data models by more than **10x**.

---

## Comparison with Existing Packages

| Feature | `cloneable` | `copy_with_extension` | `freezed` | `built_value` |
| :--- | :--- | :--- | :--- | :--- |
| **Explicit null in `copyWith`** | `user.copyWith(nick: null)` | Requires `copyWithNull(nick: true)` | Supported | Requires builder pattern |
| **Class syntax** | Ordinary Dart classes | Ordinary Dart classes | `factory Model(...) = _Model;` | Abstract classes & builders |
| **Compile-time non-null check** | Yes | Yes | Yes | Yes |
| **Runtime allocations** | **0 extra wrappers** | 0 extra wrappers | Allocates `_CopyImpl` | Allocates builder |
| **Runtime dependencies** | **0 dependencies** | 0 dependencies | Depends on annotations | Depends on built_value |
| **Focused scope** | Copying only | Copying only | All-in-one data classes | All-in-one immutable |

---

## Supporting & Contributing

If you find `cloneable` helpful, here are several ways you can support the project:

### 🌟 Community Support

- **Star the Repository**: Star [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages) on GitHub to help others discover it.
- **Report Issues & Ideas**: Found a bug or need an improvement? Open an issue on [GitHub Issues](https://github.com/ahmedm-gh/dart-packages/issues).
- **Contribute**: Pull requests for optimizations, documentation, or examples are always welcome.
- **Spread the Word**: Recommend `cloneable` in your Flutter/Dart teams, blogs, or communities.

### ☕ Sponsorship & Backing

- **Sponsor on GitHub**: If this package brings value to your commercial apps, consider supporting its maintenance via [GitHub Sponsors](https://github.com/sponsors/ahmedm-gh).
- **Buy Me a Coffee**: Support development with a one-time coffee or recurring donation via [Buy Me a Coffee](https://buymeacoffee.com/ahmeds1).

## Author & Maintainer

Created and maintained by **[AHMED M.](https://github.com/ahmedm-gh)**  

- GitHub: [@ahmedm-gh](https://github.com/ahmedm-gh)
- Repository: [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages)

## License

This package is licensed under the [MIT License](./LICENSE).
