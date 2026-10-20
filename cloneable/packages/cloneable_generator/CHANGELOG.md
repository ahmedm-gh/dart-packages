# Changelog

## [1.1.0] - 2026-10-20

### Changed

- Replaced generated copyWith typedefs with direct, strongly-typed inline function signatures on getters with zero typedef boilerplate.
- Enforced strict, literal `$prefix$ClassName$suffix` across mixin and extension names without prepending synthetic prefixes like `_$`.

### Added

- Support for `CloneableActiveness` (`active`, `inactive`, `forceActive`, `forceInactive`) for granular code generation precedence and kill-switch control.
- Seamless fallback matching in candidate mixin resolution for legacy and custom prefix definitions.

## [1.0.0] - 2026-10-15

### Added

- Initial release of `cloneable_generator`.
- Code generation using `source_gen` and `build_runner`.
- In-code project-wide defaults resolution via `@Cloneable.defaults(...)` / `@CloneableDefaults(...)` supporting modern Dart 3+ alternatives (unnamed `library;`, abstract final config classes, top-level constants, and imported libraries).
- Layered precedence resolution: Class Annotation > In-code Defaults > Built-in Defaults.
- Removed `yaml` dependency completely for zero-dependency purity and optimal build performance.
- Support partial `CloneableAffix` overrides while preserving default prefixes and suffixes.
- Updated default file suffix to `.cloneable.g` (`$className.cloneable.g.dart`).
- Strongly-typed inline function signature for `copyWith` getter enforcing non-nullable compile safety with zero typedef indirection.
- Generated mixin `_$ClassNameCloneable` with zero-allocation `copyWith` getter, and extension `$ClassNameExtension`.
- Added standalone `cloneable_generator` CLI runner supporting:
  - `CloneableOutput.inLibrary`: emits extension directly at the library top-level.
  - `CloneableOutput.inClass`: emits `copyWith` implementation directly inside the class body.
  - `CloneableCleanup`: post-generation cleanup (`none`, `deactivate`, `remove`) eliminating `@Cloneable`, `@CloneableField`, and `package:cloneable` imports when generating self-contained code with private sentinels.
- Comprehensive built-in deep copying for standard Dart collections (`List`, `Set`, `Map`), specialized collections (`Queue`, `HashMap`, `SplayTreeMap`, etc.), and all `dart:typed_data` arrays (`Uint8List`, `Int32List`, `ByteData`, etc.).
- Support for `@CloneableField.cloner` function tear-offs with highest priority over built-in deep copy logic.
- Selective standalone imports: only imports `dart:typed_data` or `dart:collection` when actually used and deepCopy is active.
- Privacy validations preventing usage of private cloner functions across standalone library boundaries.
- Granular affix and naming configuration via `CloneableNaming` and `CloneableAffix`.
- Support for modern `$undefined` package sentinel and customizable private sentinel via `naming.sentinel`.
- File-level private sentinel deduplication for top-level generated code (emitted once per file across multiple classes).
- AST-level validation and clear diagnostics for invalid models.

