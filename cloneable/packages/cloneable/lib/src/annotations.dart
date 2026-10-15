/// Annotations for the `cloneable` code generator.
library cloneable.annotations;

/// The code generation strategy to use for generating `copyWith`.
enum CloneableStrategy {
  /// Automatically detect strategy:
  /// - If the class mixes in `_$ClassNameCloneable`, a zero-allocation Mixin is generated.
  /// - If no mixin is present, a clean Extension is generated (no `with ...` needed).
  auto,

  /// Generates a Dart Extension on the annotated class.
  /// Does not require `with _$ClassNameCloneable` in the class declaration.
  extension,

  /// Generates a Dart Mixin.
  /// Requires `with _$ClassNameCloneable` in the class declaration.
  mixin,
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
/// Example with Mixin (for zero-allocation mixin dispatch):
/// ```dart
/// @Cloneable(strategy: CloneableStrategy.mixin)
/// class User with _$UserCloneable { ... }
/// ```
class Cloneable {
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

  /// Creates a new [Cloneable] annotation.
  const Cloneable({
    this.constructor,
    this.deepCopyCollections = false,
    this.strategy = CloneableStrategy.auto,
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

  /// Creates a new [CloneableField] annotation.
  const CloneableField({
    this.ignore = false,
    this.deepCopy,
  });
}

/// A unique sentinel value used by generated `copyWith` implementations
/// to distinguish omitted arguments from explicitly passed `null` values.
const Object cloneableUndefined = Object();
