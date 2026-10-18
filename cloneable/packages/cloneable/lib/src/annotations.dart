/// Annotations for the `cloneable` code generator.
library;

/// The code generation strategy to use for generating `copyWith`.
enum CloneableStrategy {
  /// Automatically detect strategy:
  /// - If the class mixes in a supported mixin (`_$ClassNameCloneable`
  ///   or `_$ClassNameCopyWith`), only the written mixin is generated.
  /// - If no mixin is present, a clean Extension is generated (no `with ...` needed).
  auto,

  /// Generates a Dart Extension on the annotated class.
  /// Does not require any `with ...` mixin in the class declaration.
  extension,

  /// Generates a Dart Mixin.
  /// Requires mixing in `_$ClassNameCloneable` or `_$ClassNameCopyWith`
  /// in the class declaration (only the written one is generated).
  mixin,
}

/// The sentinel strategy used to distinguish omitted arguments from explicit `null`s
/// in generated `copyWith` implementations.
enum CloneableSentinel {
  /// Automatically resolves the sentinel:
  /// - If `package:cloneable` is imported with a prefix (`import ... as c;`),
  ///   uses `${prefix}.cloneableUndefined`.
  /// - If `package:cloneable` is imported without a prefix, uses `cloneableUndefined`.
  /// - In test environments or standalone files, falls back gracefully.
  auto,

  /// Generates a self-contained private sentinel (`static const Object _undefined = Object();`)
  /// inside the generated mixin or extension.
  ///
  /// Completely immune to import prefixes, `show`/`hide` combinators, and namespace shadowing.
  private,

  /// Always references the canonical [cloneableUndefined] constant from `package:cloneable`.
  package,
}

/// Annotation to mark a Dart class for `copyWith` code generation.
///
/// Example with Extension (no mixin required):
/// ```dart
/// import 'package:cloneable/cloneable.dart';
///
/// part 'user.g.dart';
///
/// @Cloneable()
/// class User {
///   final String name;
///   final int age;
///   final String? nickname;
///
///   const User({
///     required this.name,
///     required this.age,
///     this.nickname,
///   });
/// }
/// ```
///
/// Example with Mixin (supports `_$UserCloneable` or `_$UserCopyWith`):
/// ```dart
/// @Cloneable(strategy: CloneableStrategy.mixin)
/// class User with _$UserCloneable { ... }
/// ```
class Cloneable {
  /// The default name for the generated copy method/getter (`'copyWith'`).
  ///
  /// To customize the method name for a specific class, specify [methodName]
  /// in the [@Cloneable] annotation (e.g. `@Cloneable(methodName: 'clone')`).
  static const defaultMethodName = 'copyWith';

  /// The default in-class getter names checked for the whitelist of fields.
  static const defaultCloneableFieldsGetters = [
    'cloneableFields',
    'copyWithFields',
  ];

  /// The constructor name to use for reconstruction.
  ///
  /// When `null` or empty, the default unnamed constructor is used.
  final String? constructor;

  /// Whether to deep copy collections (`List`, `Set`, `Map`) into new
  /// independent instances during `copyWith`.
  ///
  /// Defaults to `false` (shallow copy).
  final bool deepCopyCollections;

  /// The code generation strategy (auto, extension, or mixin).
  ///
  /// Defaults to [CloneableStrategy.auto].
  final CloneableStrategy strategy;

  /// Whether to ignore `null` values passed to nullable fields, falling back
  /// to the traditional/normal Dart `field ?? self.field` behavior.
  ///
  /// Defaults to `false` (explicit null support enabled).
  final bool ignoreNull;

  /// The name of the copy method/getter to generate.
  ///
  /// Defaults to [defaultMethodName] (`'copyWith'`).
  final String methodName;

  /// The sentinel strategy used for resolving the undefined sentinel in generated code.
  ///
  /// Defaults to [CloneableSentinel.auto].
  final CloneableSentinel sentinel;

  /// Whether code generation is active for this class.
  ///
  /// When `false`, the code generator completely ignores this annotation and
  /// emits no code.
  ///
  /// Defaults to `true`.
  final bool active;

  /// An optional whitelist of field names to include in the generated `copyWith`.
  ///
  /// When specified, only constructor fields whose names are listed in [fields]
  /// are exposed as parameters in the generated `copyWith` signature. All other
  /// fields are automatically reconstructed using their current values (`self.field`).
  ///
  /// If explicitly empty (`[]`), code generation for this class is ignored
  /// (identical to setting [active] to `false`).
  ///
  /// Alternatively, you can specify this whitelist directly inside the class
  /// using an in-class getter named `cloneableFields` or `copyWithFields` (or the
  /// custom name configured via [cloneableFieldsGetter]).
  ///
  /// Note: [fields] cannot be specified simultaneously in both the [@Cloneable]
  /// annotation and as an in-class getter.
  final List<String>? fields;

  /// An optional custom name for the in-class whitelist getter.
  ///
  /// When `null`, the generator automatically checks for the default conventions
  /// [defaultCloneableFieldsGetters] (`['cloneableFields', 'copyWithFields']`).
  final String? cloneableFieldsGetter;

  /// Whether to generate the `copyWith` implementation inline inside the
  /// declaring file rather than in a separate `part` file.
  ///
  /// When `true`, `build_runner` skips generating this class into `.g.dart`,
  /// and the inline CLI tool (`dart run cloneable_generator:inline`) generates
  /// and updates the code directly inside the source file wrapped between
  /// special comment markers (`// Cloneable: start (...)` / `// Cloneable: end (...)`).
  ///
  /// Defaults to `false`.
  final bool inline;

  /// Creates a new [Cloneable] annotation.
  const Cloneable({
    this.constructor,
    this.deepCopyCollections = false,
    this.strategy = CloneableStrategy.auto,
    this.ignoreNull = false,
    this.methodName = defaultMethodName,
    this.sentinel = CloneableSentinel.auto,
    this.active = true,
    this.inline = false,
    this.fields,
    this.cloneableFieldsGetter,
  });

  /// Creates a global or class-level [Cloneable] configuration.
  ///
  /// Can be used as an annotation `@Cloneable.config(...)` or `@cloneable.config(...)`
  /// above `main()` in `lib/main.dart` or across your application to establish
  /// project-wide code generation defaults:
  ///
  /// ```dart
  /// @Cloneable.config(
  ///   inline: true,
  ///   deepCopyCollections: false,
  ///   ignoreNull: false,
  ///   methodName: 'copyWith',
  ///   strategy: CloneableStrategy.auto,
  ///   sentinel: CloneableSentinel.auto,
  /// )
  /// void main() {
  ///   runApp(...);
  /// }
  /// ```
  const Cloneable.config({
    this.constructor,
    this.deepCopyCollections = false,
    this.strategy = CloneableStrategy.auto,
    this.ignoreNull = false,
    this.methodName = defaultMethodName,
    this.sentinel = CloneableSentinel.auto,
    this.active = true,
    this.inline = false,
    this.fields,
    this.cloneableFieldsGetter,
  });
}

/// Annotation to customize code generation for an individual class field.
class CloneableField {
  /// Whether to exclude this field from the generated `copyWith` parameters.
  final bool ignore;

  /// Whether to deep copy this specific collection field (`List`, `Set`, `Map`)
  /// into a new independent instance during `copyWith`.
  ///
  /// When `null`, inherits the class-level [Cloneable.deepCopyCollections] setting.
  final bool? deepCopy;

  /// Whether to ignore `null` values for this field, treating `null` as omitted
  /// (the traditional/normal Dart `field ?? self.field` behavior).
  ///
  /// When `null`, inherits the class-level [Cloneable.ignoreNull] setting.
  final bool? ignoreNull;

  /// Creates a new [CloneableField] annotation.
  const CloneableField({
    this.ignore = false,
    this.deepCopy,
    this.ignoreNull,
  });
}

/// A unique sentinel value used by generated `copyWith` implementations
/// to distinguish omitted arguments from explicitly passed `null` values.
const undefined = Object();

/// Backwards-compatible alias for [undefined].
const cloneableUndefined = undefined;
