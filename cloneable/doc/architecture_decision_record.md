# Architecture Decision Record (ADR): Dart `cloneable` Package

- **Status**: Accepted & Implemented
- **Date**: 2026-10-15
- **Deciders**: Ahmed & Antigravity (Senior Dart Language & Performance Engineering)
- **Context**: Design of a production-grade Dart package generating strongly-typed `copyWith` methods for ordinary classes with first-class support for explicit `null` assignments.

---

## 1. Problem Statement & Requirements

In Dart, immutable data modeling relies on the `copyWith` pattern. However, idiomatic Dart hand-written `copyWith` suffers from a fundamental limitation:

```dart
User copyWith({String? name, String? nickname}) => User(
  name: name ?? this.name,
  nickname: nickname ?? this.nickname, // Cannot differentiate between omitted and explicit null!
);
```

When calling `user.copyWith(nickname: null)`, `nickname ?? this.nickname` evaluates to `this.nickname`, making it impossible to clear a nullable field to `null`.

### Core Requirements
1. **Developer Experience**:
   - Clean annotation `@Cloneable()` on standard Dart classes with `with _$ClassCloneable`.
   - Natural call site: `user.copyWith(nickname: null)` to clear nullable fields; `user.copyWith(name: 'New')` to replace; `user.copyWith()` with omitted arguments preserving original values.
2. **Static Type Safety**:
   - Non-nullable fields cannot be assigned `null` at compile-time (e.g., `user.copyWith(name: null)` must produce a compile-time analyzer error).
3. **Zero Allocation Overhead**:
   - Calling `user.copyWith(...)` must avoid intermediate wrapper allocations where possible.
4. **Standard Tooling & Ecosystem Compatibility**:
   - Usable via standard `dart run build_runner build`.
   - 100% compatible with Dart VM, Flutter, Web, WASM, and AOT compilation.
   - Clean separation between runtime annotations and build-time generator dependencies.

---

## 2. Evaluation of Competing Architectures

| Criteria | Option 1: `source_gen` + `build_runner` (Selected) | Option 2: Standalone Custom CLI | Option 3: Dart Macros (Discontinued) | Option 4: Reflection (`dart:mirrors`) |
| :--- | :--- | :--- | :--- | :--- |
| **Type Safety** | High (full AST + element resolution) | High | Theoretical | Low / Runtime only |
| **Explicit-Null Semantics** | Perfect (via callable abstract interface) | Perfect | Unknown | Problematic |
| **Runtime Overhead** | **0 bytes** (zero-alloc mixin dispatch) | **0 bytes** | Zero | Severe |
| **Build-Time Performance** | Fast incremental builds | Fast single-run, poor cache integration | N/A | None |
| **Incremental Rebuild** | Native asset graph caching | Must write custom daemon/watcher | Broken | None |
| **IDE & Analyzer Compat** | Standard Dart Analysis Server & `.g.dart` | Requires external watcher | Failed in Flutter IDE | Poor |
| **Flutter Compatibility** | 100% | Requires custom terminal steps | Incompatible (broke hot reload) | Completely incompatible |
| **Generic Classes** | Fully supported (bounds, variance, T?) | Fully supported | Incomplete | Broken |
| **Maintenance Burden** | Low (standard Dart ecosystem APIs) | Very high (custom build graph) | Dead project | Deprecated |
| **Dependency Footprint** | Pure runtime package (0 deps); generator in dev | Heavy standalone CLI | N/A | Flutter forbids mirrors |
| **Long-Term SDK Support** | Stable since Dart 2.0 | High maintenance risk | Discontinued by Dart team in 2025 | Removed from AOT/Flutter |

### Detailed Evaluation of Option 3 (Dart Macros)
The Dart team prototyped macros across Dart 3.4–3.5 (e.g., experimental `@JsonCodable`). However, in **January 2025**, the Dart team officially announced the termination of the Macro experiment because deep semantic cross-file introspection critically degraded Flutter's sub-second stateful hot reload and IDE performance. Experimental macro documentation and flags were formally deprecated and removed from SDK releases. Relying on macros in 2026 is impossible for any published, production package.

### Detailed Evaluation of Option 2 (Custom Standalone CLI)
A custom CLI that invokes `package:analyzer` directly bypasses `build_runner`. However:
- It forfeits the shared asset graph, meaning every rebuild re-parses all files or requires rewriting an entire incremental build engine from scratch.
- It causes friction in Flutter and Dart projects that already run `build_runner` for `json_serializable`, `riverpod_generator`, or `drift`.
- Having two different build orchestration commands (`dart run cloneable:gen` alongside `dart run build_runner build`) degrades developer experience.

### Detailed Evaluation of Existing Packages
1. **`copy_with_extension`**:
   - Forces a separate method `copyWithNull(field: true)` for clearing nullable values, splitting the API into two distinct method calls (`copyWith` and `copyWithNull`).
2. **`freezed`**:
   - Heavyweight framework generating unions, pattern matching, `toJson`/`fromJson`, equality, `hashCode`, etc.
   - Requires `factory Model(...) = _Model;` syntax, which does not work on ordinary Dart classes with standard generative constructors.
   - For `copyWith`, it allocates an intermediate `_$ModelCopyWithImpl` instance on each invocation, introducing heap allocations.
3. **`equatable`**:
   - Solves value equality (`==` and `hashCode`), but provides no `copyWith` generation.
4. **`json_serializable`**:
   - Specializes exclusively in JSON serialization and does not generate `copyWith`.

---

## 3. Selected Architecture: Zero-Allocation Mixin with Callable Abstract Interface

### Architectural Insights

#### 1. The Typing Dilemma in Dart
In Dart null safety:
- A concrete method parameter cannot be optional and non-nullable without a default value or `required`.
- If parameter is `Object? name = _sentinel`, the static analyzer permits passing `null` to `name` even when `name` is non-nullable `String` (failing compile-time null safety).

#### 2. The Solution: Interface-Mixin Separation
Dart allows an **abstract method** to declare optional non-nullable parameters without default values:
```dart
abstract class $UserCopyWith<$Result> {
  $Result call({
    String name,     // Non-nullable! Statically rejects `null`
    int age,         // Non-nullable! Statically rejects `null`
    String? nickname,// Nullable! Statically accepts `null` or String
  });
}
```

A concrete class or mixin can implement this interface by widening the parameter types to `Object?` with the sentinel default value:
```dart
mixin _$UserCloneable implements $UserCopyWith<User> {
  // Returns `this` directly: ZERO heap allocation!
  $UserCopyWith<User> get copyWith => this;

  @override
  User call({
    Object? name = cloneableUndefined,
    Object? age = cloneableUndefined,
    Object? nickname = cloneableUndefined,
  }) {
    final self = this as User;
    return User(
      name: identical(name, cloneableUndefined) ? self.name : name as String,
      age: identical(age, cloneableUndefined) ? self.age : age as int,
      nickname: identical(nickname, cloneableUndefined) ? self.nickname : nickname as String?,
    );
  }
}
```

#### 3. Why this achieves all design goals:
1. **Static Type Safety**: When calling `user.copyWith(...)`, the static return type of getter `copyWith` is `$UserCopyWith<User>`. The compiler checks the argument types against `call(...)` in `$UserCopyWith<User>`.
   - `user.copyWith(name: null)` -> `The argument type 'Null' can't be assigned to the parameter type 'String'.` (Compile Error!)
   - `user.copyWith(nickname: null)` -> Valid (Nullable field)
   - `user.copyWith(name: 'Alice')` -> Valid
   - `user.copyWith()` -> Valid (Omitted parameters are optional in the interface)
2. **Zero Allocation**: `get copyWith => this;` returns `this`. Unlike `freezed`, no intermediate wrapper class is instantiated on the heap. In Dart VM and AOT, the getter and call method are inlined directly.
3. **No Dynamic / No Reflection**: Everything is statically resolved with strong typing.
4. **Natural User Syntax**:
   ```dart
   @Cloneable()
   class User with _$UserCloneable {
     final String name;
     final int age;
     final String? nickname;

     const User({required this.name, required this.age, this.nickname});
   }
   ```

---

## 4. Multi-Package Structure

To adhere to Dart publishing best practices:
- **`packages/cloneable`**: The runtime library. Contains annotations (`@Cloneable`, `@CloneableField`), runtime sentinel constant `cloneableUndefined`. It has **0 dependencies** and an ultra-lightweight footprint.
- **`packages/cloneable_generator`**: The code generator. Contains the `GeneratorForAnnotation<Cloneable>`, the `SharedPartBuilder`, and AST visitors using `analyzer` and `source_gen`.
- **`packages/cloneable_example`**: Full integration and demonstration package with tests and benchmarks.

---

## 5. Decision Outcome
- Proceed with `source_gen` + `build_runner` and the zero-allocation mixin pattern.
- Implement comprehensive validation, error reporting for unsupported constructors or ambiguous fields, and benchmark performance against hand-written code and alternative packages.
