/// Annotations for the `cloneable` code generator.
library;

/// A unique sentinel value used by generated `copyWith` implementations
/// to distinguish omitted arguments from explicitly passed `null` values.
const $undefined = Object();

/// The code generation strategy to use for generating `copyWith`.
enum CloneableStrategy {
  /// Automatically detect strategy:
  /// - If the class mixes in a supported mixin (`_$ClassNameCloneable`,
  ///   `_$ClassNameCopyWith`, or a prefix-customized mixin), only the written mixin is generated.
  /// - If no mixin is present, a clean Extension is generated (no `with ...` needed).
  auto,

  /// Generates a Dart Extension on the annotated class.
  /// Does not require any `with ...` mixin in the class declaration.
  extension,

  /// Generates a Dart Mixin.
  /// Requires mixing in `_$ClassNameCloneable` or `_$ClassNameCopyWith`
  /// (or a prefix-customized mixin) in the class declaration (only the written one is generated).
  mixin;
}

/// The sentinel strategy used to distinguish omitted arguments from explicit `null`s
/// in generated `copyWith` implementations.
enum CloneableSentinel {
  /// Automatically resolves the sentinel:
  /// - If `package:cloneable` is imported with a prefix (`import ... as c;`),
  ///   uses `${prefix}.$undefined`.
  /// - If `package:cloneable` is imported without a prefix, uses `$undefined`.
  /// - In test environments or standalone files, falls back gracefully.
  auto,

  /// Generates a self-contained private sentinel (`const _$undefined = Object();`)
  /// inside the generated mixin, extension, or library.
  ///
  /// Completely immune to import prefixes, `show`/`hide` combinators, and namespace shadowing.
  private,

  /// Always references the canonical [$undefined] constant from `package:cloneable`.
  package;
}

/// The resolution strategy when fields are specified in both [@Cloneable(fields: ...)]
/// and an in-class getter (`cloneableFields` / `copyWithFields`).
enum CloneableFieldsConflict {
  /// Throws a compile-time build error if fields are specified in both places (default).
  error,

  /// Merges fields from both the annotation and the in-class getter (union of allowed fields).
  merge,

  /// Prefers and uses only the fields defined in the in-class getter.
  inClass,

  /// Prefers and uses only the fields defined in the [@Cloneable(fields: ...)] annotation.
  inAnnotation;
}

/// The destination output format for generated code.
enum CloneableOutput {
  /// Automatically detect the output destination:
  /// - If the file contains a `part '...';` directive matching the generated file, emits part code (`part of`).
  /// - If `strategy` is [CloneableStrategy.mixin], defaults to part file generation (or inLibrary if configured).
  /// - Otherwise, emits standalone non-part code or part code based on runner context.
  auto,

  /// Generates code into a `part of` file (e.g. `*.g.dart` or `*.cloneable.dart`).
  /// Requires a `part '...';` directive in the declaring source file.
  part,

  /// Generates code into a standalone non-part library file (e.g. `*.cloneable.dart`).
  /// Does not require `part '...';` or `part of`.
  standalone,

  /// Generates code directly inside the same library that contains the class
  /// (top-level extension) wrapped between marker comments.
  inLibrary,

  /// Generates the `copyWith` method directly inside the class body itself
  /// between marker comments.
  inClass;

  /// Whether code is generated inline directly into the source file
  /// (either [inLibrary] or [inClass]).
  bool get isInline => this == inLibrary || this == inClass;
}

/// The cleanup action to perform on source annotations after code generation.
enum CloneableCleanup {
  /// Do not modify or remove source annotations after code generation (default).
  none,

  /// Deactivates the [@Cloneable] annotation by rewriting it with `active: false` in place,
  /// preserving developer configurations (fields, naming, etc.) while disabling
  /// redundant future code generation passes.
  deactivate,

  /// Automatically removes all [@Cloneable] and [@CloneableField] annotations
  /// and the `package:cloneable` import line after code generation.
  ///
  /// This action is **only active** when [sentinel] is set to [CloneableSentinel.private],
  /// ensuring the generated code is 100% self-contained and free of runtime dependencies.
  remove;
}

/// The activation state and override precedence for code generation.
enum CloneableActiveness {
  /// Code generation is active. Can be overridden by child or parent configurations.
  active,

  /// Code generation is inactive. Can be overridden by explicit child activation.
  inactive,

  /// Forces code generation to be active, overriding parent deactivations.
  forceActive,

  /// Master kill-switch: forces code generation to be inactive across its scope,
  /// overriding child configurations.
  forceInactive;

  /// Whether code generation is active.
  bool get isActive => this == active || this == forceActive;

  /// Whether code generation is forced.
  bool get isForced => this == forceActive || this == forceInactive;
}

/// Represents a configurable prefix and suffix pair for generated code symbols or files.
class CloneableAffix {
  /// The prefix to prepend.
  final String? prefix;

  /// The suffix to append.
  final String? suffix;

  /// Creates a new [CloneableAffix] with optional [prefix] and [suffix].
  const CloneableAffix({
    this.prefix,
    this.suffix,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CloneableAffix &&
          runtimeType == other.runtimeType &&
          prefix == other.prefix &&
          suffix == other.suffix;

  @override
  int get hashCode => Object.hash(prefix, suffix);

  @override
  String toString() => 'CloneableAffix(prefix: "$prefix", suffix: "$suffix")';
}

/// Configuration for naming patterns and symbol prefixes/suffixes
/// of generated code (mixins, extensions, and files).
class CloneableNaming {
  /// The default name for the copy method (`'copyWith'`).
  static const defaultMethod = 'copyWith';

  /// The default identifier for the private sentinel (`r'_$undefined'`).
  static const defaultSentinel = r'_$undefined';

  /// The default affix for generated mixins (`_$ClassNameCloneable`).
  static const defaultMixin = CloneableAffix(
    prefix: r'_$',
    suffix: 'Cloneable',
  );

  /// The default affix for generated extensions (`$ClassNameExtension`).
  static const defaultExtension = CloneableAffix(
    prefix: r'$',
    suffix: 'Extension',
  );

  /// The default affix for generated files (`$className.cloneable.g.dart`).
  static const defaultFile = CloneableAffix(
    prefix: '',
    suffix: '.cloneable.g',
  );

  /// The default target directory path for generated files (`null`, indicating the same folder level).
  static const String? defaultDirectory = null;

  /// The default naming configuration instance.
  static const defaults = CloneableNaming();

  /// The name of the copy method to generate.
  ///
  /// Defaults to [defaultMethod] (`'copyWith'`).
  final String method;

  /// The identifier name for the private sentinel when [CloneableSentinel.private] is used.
  ///
  /// Defaults to [defaultSentinel] (`r'_$undefined'`).
  final String sentinel;

  /// Configures prefix and suffix for generated mixins.
  final CloneableAffix mixin;

  /// Configures prefix and suffix for generated extensions.
  final CloneableAffix extension;

  /// Configures prefix and suffix for generated files (part files and standalone files).
  final CloneableAffix file;

  /// The optional target directory path where generated files should be written
  /// (e.g. `'generated'`, `'src/generated'`, or `null` for the same directory level).
  ///
  /// Only applies to file-based output formats ([CloneableOutput.part] and
  /// [CloneableOutput.standalone]). For inline formats ([CloneableOutput.inLibrary]
  /// and [CloneableOutput.inClass]), this setting is safely ignored.
  final String? directory;

  /// Specific affix overrides for symbols generated in part files (`part of`).
  final CloneableAffix? part;

  /// Specific affix overrides for symbols generated in standalone ("no part / no part of") files.
  final CloneableAffix? standalone;

  /// Specific affix overrides for symbols generated inside the containing library.
  final CloneableAffix? inLibrary;

  /// Specific affix overrides for symbols generated inside the class body.
  final CloneableAffix? inClass;

  /// Creates a new [CloneableNaming] configuration.
  const CloneableNaming({
    this.method = defaultMethod,
    this.sentinel = defaultSentinel,
    this.mixin = defaultMixin,
    this.extension = defaultExtension,
    this.file = defaultFile,
    this.directory = defaultDirectory,
    this.part,
    this.standalone,
    this.inLibrary,
    this.inClass,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CloneableNaming &&
          runtimeType == other.runtimeType &&
          method == other.method &&
          sentinel == other.sentinel &&
          mixin == other.mixin &&
          extension == other.extension &&
          file == other.file &&
          directory == other.directory &&
          part == other.part &&
          standalone == other.standalone &&
          inLibrary == other.inLibrary &&
          inClass == other.inClass;

  @override
  int get hashCode => Object.hash(
        method,
        sentinel,
        mixin,
        extension,
        file,
        directory,
        part,
        standalone,
        inLibrary,
        inClass,
      );

  @override
  String toString() =>
      'CloneableNaming(method: "$method", sentinel: "$sentinel", mixin: $mixin, extension: $extension, file: $file, directory: ${directory != null ? '"$directory"' : null}, part: $part, standalone: $standalone, inLibrary: $inLibrary, inClass: $inClass)';
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
/// Example with Mixin:
/// ```dart
/// @Cloneable(strategy: CloneableStrategy.mixin)
/// class User with _$UserCloneable { ... }
/// ```
class Cloneable {
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
  /// When `null`, inherits the setting from [CloneableDefaults.instance].
  final bool? deepCopyCollections;

  /// The code generation strategy (auto, extension, or mixin).
  ///
  /// When `null`, inherits the setting from [CloneableDefaults.instance].
  final CloneableStrategy? strategy;

  /// Whether to ignore `null` values passed to nullable fields, falling back
  /// to the traditional/normal Dart `field ?? self.field` behavior.
  ///
  /// When `null`, inherits the setting from [CloneableDefaults.instance].
  final bool? ignoreNull;

  /// The sentinel strategy used for resolving the undefined sentinel in generated code.
  ///
  /// When `null`, inherits the setting from [CloneableDefaults.instance].
  final CloneableSentinel? sentinel;

  /// Whether code generation is active for this class.
  ///
  /// When `false`, the code generator completely ignores this annotation and
  /// emits no code.
  ///
  /// When `null`, inherits the setting from [CloneableDefaults.instance].
  final bool? active;

  /// The activation state and override precedence for code generation.
  ///
  /// Takes precedence over [active]. Supports [CloneableActiveness.active],
  /// [CloneableActiveness.inactive], [CloneableActiveness.forceActive],
  /// and [CloneableActiveness.forceInactive].
  ///
  /// When `null`, falls back to [active] or inherits from [CloneableDefaults.instance].
  final CloneableActiveness? activeness;

  /// The cleanup action to perform on source annotations after code generation.
  ///
  /// - [CloneableCleanup.none]: Keeps annotations intact (default).
  /// - [CloneableCleanup.deactivate]: Rewrites the `@Cloneable` annotation to `active: false`,
  ///   preserving configuration while disabling future generation passes.
  /// - [CloneableCleanup.remove]: Removes all `@Cloneable` and `@CloneableField` annotations
  ///   as well as `package:cloneable` imports (requires [CloneableSentinel.private]).
  ///
  /// When `null`, inherits the setting from [CloneableDefaults.instance].
  final CloneableCleanup? cleanup;

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
  final List<String>? fields;

  /// An optional custom name for the in-class whitelist getter.
  ///
  /// When `null`, the generator automatically checks for the default conventions
  /// [defaultCloneableFieldsGetters] (`['cloneableFields', 'copyWithFields']`).
  final String? cloneableFieldsGetter;

  /// The conflict resolution strategy when fields are specified in both
  /// [fields] and an in-class whitelist getter.
  ///
  /// When `null`, inherits the setting from [CloneableDefaults.instance].
  final CloneableFieldsConflict? fieldsConflict;

  /// The destination output format for generated code.
  ///
  /// When `null`, inherits the setting from [CloneableDefaults.instance].
  final CloneableOutput? output;

  /// The naming configuration for generated symbol prefixes and suffixes.
  ///
  /// When `null`, inherits the setting from [CloneableDefaults.instance].
  final CloneableNaming? naming;

  /// Creates a new [Cloneable] annotation.
  ///
  /// Any parameter left `null` automatically inherits from [CloneableDefaults.instance].
  const Cloneable({
    this.constructor,
    this.deepCopyCollections,
    this.strategy,
    this.ignoreNull,
    this.sentinel,
    this.active,
    this.activeness,
    this.cleanup,
    this.output,
    this.fields,
    this.cloneableFieldsGetter,
    this.fieldsConflict,
    this.naming,
  });

  /// Defines project-wide code generation defaults (Single Source of Truth).
  ///
  /// Can be used as a top-level or library annotation:
  /// ```dart
  /// @Cloneable.defaults(
  ///   output: CloneableOutput.inClass,
  ///   sentinel: CloneableSentinel.private,
  ///   cleanup: CloneableCleanup.remove,
  /// )
  /// library;
  /// ```
  const factory Cloneable.defaults({
    CloneableOutput output,
    CloneableStrategy strategy,
    CloneableSentinel sentinel,
    bool deepCopyCollections,
    bool ignoreNull,
    bool active,
    CloneableActiveness activeness,
    CloneableCleanup cleanup,
    CloneableFieldsConflict fieldsConflict,
    CloneableNaming naming,
  }) = CloneableDefaults;

  /// Creates a [Cloneable] annotation configured for in-class code generation.
  ///
  /// Generated `copyWith` and `_copyWith` methods are injected directly into
  /// the class body before the closing brace `}`.
  ///
  /// Strategy and file affixes are omitted as they do not apply to in-class generation.
  const Cloneable.inClass({
    this.constructor,
    this.deepCopyCollections,
    this.ignoreNull,
    this.sentinel,
    this.active,
    this.activeness,
    this.cleanup,
    this.fields,
    this.cloneableFieldsGetter,
    this.fieldsConflict,
    this.naming,
  })  : output = CloneableOutput.inClass,
        strategy = null;

  /// Creates a [Cloneable] annotation configured for in-library code generation.
  ///
  /// Generates code at the top level of the declaring library file.
  const Cloneable.inLibrary({
    this.constructor,
    this.deepCopyCollections,
    this.strategy,
    this.ignoreNull,
    this.sentinel,
    this.active,
    this.activeness,
    this.cleanup,
    this.fields,
    this.cloneableFieldsGetter,
    this.fieldsConflict,
    this.naming,
  }) : output = CloneableOutput.inLibrary;

  /// Creates a [Cloneable] annotation configured for dedicated `part of` file generation.
  const Cloneable.part({
    this.constructor,
    this.deepCopyCollections,
    this.strategy,
    this.ignoreNull,
    this.sentinel,
    this.active,
    this.activeness,
    this.cleanup,
    this.fields,
    this.cloneableFieldsGetter,
    this.fieldsConflict,
    this.naming,
  }) : output = CloneableOutput.part;

  /// Creates a [Cloneable] annotation configured for standalone file generation.
  const Cloneable.standalone({
    this.constructor,
    this.deepCopyCollections,
    this.ignoreNull,
    this.sentinel,
    this.active,
    this.activeness,
    this.cleanup,
    this.fields,
    this.cloneableFieldsGetter,
    this.fieldsConflict,
    this.naming,
  })  : output = CloneableOutput.standalone,
        strategy = CloneableStrategy.extension;

  /// Programmatic setter to update default values at runtime (e.g. in test suites).
  static void setDefaults({
    CloneableOutput output = CloneableOutput.auto,
    CloneableStrategy strategy = CloneableStrategy.auto,
    CloneableSentinel sentinel = CloneableSentinel.auto,
    bool deepCopyCollections = false,
    bool ignoreNull = false,
    bool active = true,
    CloneableActiveness activeness = CloneableActiveness.active,
    CloneableCleanup cleanup = CloneableCleanup.none,
    CloneableFieldsConflict fieldsConflict = CloneableFieldsConflict.error,
    CloneableNaming naming = const CloneableNaming(),
  }) {
    CloneableDefaults.instance = CloneableDefaults(
      output: output,
      strategy: strategy,
      sentinel: sentinel,
      deepCopyCollections: deepCopyCollections,
      ignoreNull: ignoreNull,
      active: active,
      activeness: activeness,
      cleanup: cleanup,
      fieldsConflict: fieldsConflict,
      naming: naming,
    );
  }
}

/// The Single Source of Truth (SSOT) holding global default settings for `cloneable`.
///
/// Can be used as a top-level or library annotation `@Cloneable.defaults(...)` or
/// `@CloneableDefaults(...)` to establish project-wide code generation defaults.
class CloneableDefaults extends Cloneable {
  /// The default code generation output destination.
  @override
  CloneableOutput get output => super.output ?? CloneableOutput.auto;

  /// The default generation strategy (auto, extension, mixin).
  @override
  CloneableStrategy get strategy => super.strategy ?? CloneableStrategy.auto;

  /// The default sentinel strategy.
  @override
  CloneableSentinel get sentinel => super.sentinel ?? CloneableSentinel.auto;

  /// Whether to deep copy collections by default.
  @override
  bool get deepCopyCollections => super.deepCopyCollections ?? false;

  /// Whether to ignore null values by default.
  @override
  bool get ignoreNull => super.ignoreNull ?? false;

  /// The default activeness setting.
  @override
  CloneableActiveness get activeness =>
      super.activeness ??
      (super.active != null
          ? (super.active!
              ? CloneableActiveness.active
              : CloneableActiveness.inactive)
          : CloneableActiveness.active);

  /// Whether code generation is active by default.
  @override
  bool get active => activeness.isActive;

  /// The default cleanup action on source annotations.
  @override
  CloneableCleanup get cleanup => super.cleanup ?? CloneableCleanup.none;

  /// The default conflict resolution strategy for whitelisted fields.
  @override
  CloneableFieldsConflict get fieldsConflict =>
      super.fieldsConflict ?? CloneableFieldsConflict.error;

  /// The default naming and affix configuration.
  @override
  CloneableNaming get naming => super.naming ?? const CloneableNaming();

  /// Creates a new [CloneableDefaults] instance.
  const CloneableDefaults({
    super.output,
    super.strategy,
    super.sentinel,
    super.deepCopyCollections,
    super.ignoreNull,
    super.active,
    super.activeness,
    super.cleanup,
    super.fieldsConflict,
    super.naming,
  });

  /// The active global defaults instance (Single Source of Truth).
  static CloneableDefaults instance = const CloneableDefaults();

  /// Updates the global defaults instance at runtime (e.g. for testing environments).
  static void setDefaults(CloneableDefaults defaults) {
    instance = defaults;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CloneableDefaults &&
          runtimeType == other.runtimeType &&
          output == other.output &&
          strategy == other.strategy &&
          sentinel == other.sentinel &&
          deepCopyCollections == other.deepCopyCollections &&
          ignoreNull == other.ignoreNull &&
          active == other.active &&
          activeness == other.activeness &&
          cleanup == other.cleanup &&
          fieldsConflict == other.fieldsConflict &&
          naming == other.naming;

  @override
  int get hashCode => Object.hash(
        output,
        strategy,
        sentinel,
        deepCopyCollections,
        ignoreNull,
        active,
        activeness,
        cleanup,
        fieldsConflict,
        naming,
      );

  @override
  String toString() =>
      'CloneableDefaults(output: $output, strategy: $strategy, sentinel: $sentinel, deepCopyCollections: $deepCopyCollections, ignoreNull: $ignoreNull, active: $active, activeness: $activeness, cleanup: $cleanup, fieldsConflict: $fieldsConflict, naming: $naming)';
}

/// Annotation to customize code generation for an individual class field.
class CloneableField {
  /// Whether to exclude this field from the generated `copyWith` parameters.
  final bool ignore;

  /// Whether to deep copy this specific collection field (`List`, `Set`, `Map`,
  /// `Queue`, typed data arrays, etc.) into a new independent instance during `copyWith`.
  ///
  /// When `null`, inherits the class-level [Cloneable.deepCopyCollections] setting.
  final bool? deepCopy;

  /// Whether to ignore `null` values for this field, treating `null` as omitted
  /// (the traditional/normal Dart `field ?? self.field` behavior).
  ///
  /// When `null`, inherits the class-level [Cloneable.ignoreNull] setting.
  final bool? ignoreNull;

  /// An optional custom cloner function to deep copy or defensively duplicate this field.
  ///
  /// Can be any top-level or static function with the signature `T Function(T value)`:
  ///
  /// ```dart
  /// @CloneableField(cloner: Uint8List.fromList)
  /// final Uint8List bytes;
  ///
  /// @CloneableField(cloner: _deepCloneMetadata)
  /// final Map<String, dynamic> metadata;
  /// ```
  ///
  /// When provided, this cloner function always takes priority over built-in deep copy logic.
  final Function? cloner;

  /// Creates a new [CloneableField] annotation.
  const CloneableField({
    this.ignore = false,
    this.deepCopy,
    this.ignoreNull,
    this.cloner,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CloneableField &&
          runtimeType == other.runtimeType &&
          ignore == other.ignore &&
          deepCopy == other.deepCopy &&
          ignoreNull == other.ignoreNull &&
          cloner == other.cloner;

  @override
  int get hashCode => Object.hash(ignore, deepCopy, ignoreNull, cloner);

  @override
  String toString() =>
      'CloneableField(ignore: $ignore, deepCopy: $deepCopy, ignoreNull: $ignoreNull, cloner: $cloner)';
}

/// Container annotation declaring multiple cloneable entities in a single central configuration file.
///
/// Enables defining code generation configuration for multiple classes in a single
/// manifest file with zero annotations required on the model classes themselves:
///
/// ```dart
/// @Cloneables({
///   User: Cloneable(),
///   Order: Cloneable(deepCopyCollections: true),
///   Product: Cloneable.inClass(),
/// })
/// library;
/// ```
class Cloneables {
  /// Map of model [Type] to its respective [Cloneable] configuration.
  final Map<Type, Cloneable> entities;

  /// Creates a [Cloneables] annotation containing the specified [entities] map.
  const Cloneables(this.entities);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cloneables &&
          runtimeType == other.runtimeType &&
          entities == other.entities;

  @override
  int get hashCode => entities.hashCode;

  @override
  String toString() => 'Cloneables($entities)';
}
