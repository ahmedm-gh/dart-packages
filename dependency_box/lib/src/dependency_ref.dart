/// Represents a unique dependency identifier combining a [type] and an optional [key].
final class BoxDependencyRef {
  /// Creates a dependency identifier for [type] with an optional [key].
  const BoxDependencyRef(this.type, {this.key});

  /// The target [Type] for this dependency.
  final Type type;

  /// Returns the canonical lookup key: [T] when [key] is null (zero allocation),
  /// or a [BoxDependencyRef] when [key] is provided.
  static Object from<T extends Object>(Object? key) {
    return key == null ? T : BoxDependencyRef(T, key: key);
  }

  /// The optional qualifying key for named dependencies (e.g. String or Enum).
  final Object? key;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BoxDependencyRef && other.type == type && other.key == key;
  }

  @override
  int get hashCode => type.hashCode ^ key.hashCode;

  @override
  String toString() => key == null ? '$type' : '$type(key: $key)';
}
