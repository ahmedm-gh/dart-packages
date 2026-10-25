# AI Agent Guidelines: `example/` Directory

This guide is for AI agents developing, modifying, or testing examples in the `dependency_box` repository.

---

## 1. Directory Structure & Organization

All examples are organized into three distinct tiers:

1. **`example/basic/`**: Minimal, single-concept demonstrations (e.g., registration lifetimes, interface mapping, keys, parameterized factories). Boilerplate must be kept minimal.
2. **`example/intermediate/`**: Realistic architectural combinations (modules, hierarchical scopes, multi-registrations, async deduplication, weak-reference caching).
3. **`example/advanced/`**: Full production-grade blueprints (Clean Architecture, resource disposal, testing overrides, container diagnostics).
4. **`example/dependency_box_example.dart`**: The primary, unified example that powers the pub.dev **Example** tab. It must remain concise, complete, and self-contained.

---

## 2. Mandatory Rules for Examples

1. **Zero External Dependencies**: All examples must run on standard Dart SDK (`>=3.0.0 <4.0.0`) without adding any third-party dependencies to `pubspec.yaml`.
2. **100% Runnable**: Every `.dart` file in `example/` must contain an executable `void main()` function that completes with exit code 0.
3. **Verified APIs Only**: Never hallucinate APIs or features not present in `package:dependency_box`. Verify signatures in `lib/dependency_box.dart` before writing code.
4. **Accurate Error Semantics**:
   - `DependencyBoxError.circularDependency`, `DependencyBoxError.notFound`, and `DependencyBoxError.disposed` throw standard Dart `StateError`.
   - `DependencyBoxError.duplicateRegistration` and `DependencyBoxError.multiNotAllowed` throw `AssertionError`.
   - `DependencyBoxError.invalidArgument` throws `ArgumentError`.
   - Do NOT attempt to catch `DependencyBoxError` as an exception type—it is an `enum` representing error categories!
5. **Clean Output**: Examples should log informative, cleanly formatted console output using clear section banners (`===`) and step indicators (`1.`, `2.`, `[LOG]`).
6. **Documentation Synchronization**: When adding or updating an example, always update `example/README.md` and the Examples Index in the root `README.md`.

---

## 3. Verification Commands

Before concluding any work on examples, execute:

```bash
# 1. Format all Dart files
dart format example/

# 2. Static analysis
dart analyze example/

# 3. Execute the example directly
dart run example/<path_to_example>.dart
```
