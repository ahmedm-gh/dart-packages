# Changelog

## [1.0.0] - 2026-10-15

### Added

- Initial release of `cloneable_generator`.
- Code generation using `source_gen` and `build_runner`.
- Generated abstract `$ClassNameCopyWith` callable interface enforcing non-nullable compile safety.
- Generated mixin `_$ClassNameCloneable` with zero-allocation `copyWith` getter.
- Full support for generic classes, bounds, enums, collections, and custom constructors.
- AST-level validation and clear diagnostics for invalid models.
