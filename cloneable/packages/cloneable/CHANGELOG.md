# Changelog

## [1.0.0] - 2026-10-15

### Added

- Initial release of `cloneable` runtime package.
- `@Cloneable()` annotation with constructor configuration, field allowlists, and deep copying.
- `CloneableDefaults` Single Source of Truth (SSOT) holding global project defaults with `@Cloneable.defaults(...)` / `@CloneableDefaults(...)` annotation.
- Dedicated named constructors: `@Cloneable.inClass()`, `@Cloneable.inLibrary()`, `@Cloneable.part()`, and `@Cloneable.standalone()`.
- Programmatic runtime setter `Cloneable.setDefaults(...)` and `CloneableDefaults.setDefaults(...)`.
- Advanced enums (`CloneableStrategy`, `CloneableSentinel`, `CloneableFieldsConflict`, `CloneableOutput`) with expressive capability getters.
- `CloneableOutput.inLibrary` and `CloneableOutput.inClass` output generation modes.
- `CloneableNaming` and `CloneableAffix` for granular target (`mixin`, `extension`, `typedef`, `file`) and approach-specific prefix/suffix customization.
- Configurable post-generation cleanup via `CloneableCleanup` (`none`, `deactivate`, `remove`).
- `@CloneableField()` annotation with field-level ignore, deep copy support, and optional `cloner` function reference.
- Built-in deep copying expanded for all Dart typed data (`Uint8List`, `Int32List`, `ByteData`, etc.) and collections (`Queue`, `HashMap`, `SplayTreeMap`, etc.).
- Custom `@CloneableField(cloner: ...)` priority execution over built-in deep-copy logic.
- `@Cloneables` container annotation for defining multi-model configurations via `Map<Type, Cloneable>`.
- `CloneableNaming.directory` for custom target directory paths (`CloneableNaming.defaultDirectory`).
- Modern `$undefined` package sentinel with zero JS/web conflicts and zero namespace pollution.
- Configurable private sentinel name via `CloneableNaming.sentinel` (defaulting to `r'_$undefined'`).
- `CloneableNaming.defaultFile` updated to `CloneableAffix(prefix: '', suffix: '.cloneable.g')` (`$className.cloneable.g.dart`).
- `CloneableAffix` now accepts nullable `prefix` and `suffix` parameters to support seamless partial overrides while preserving defaults.
- Added documentation for `CloneableDefaults.instance` and modern Dart 3 in-code configuration alternatives.
- Zero external runtime dependencies.

