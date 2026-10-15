# Changelog

All notable changes to the `cloneable` project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-10-15

### Added

- Initial release of `cloneable` and `cloneable_generator`.
- Annotation-driven `@Cloneable()` code generation with zero-allocation mixin pattern.
- Strongly-typed `copyWith` method generation distinguishing omitted parameters from explicit `null`.
- Compile-time error enforcement preventing `null` assignment to non-nullable fields.
- Full support for generic classes with type parameters and bounds (`Box<T>`, `BoundedBox<T extends num>`).
- Full support for enums, nested cloneable objects, records, and collections.
- Constructor flexibility: unnamed constructors, custom named constructors, positional and named parameters.
- `@CloneableField(ignore: true)` for excluding fields from `copyWith`.
- Comprehensive benchmark suite (runtime, build-time, footprint).
