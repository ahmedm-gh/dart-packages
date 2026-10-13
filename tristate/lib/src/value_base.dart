/// A container object which may or may not contain a value.
///
/// Used to represent optional values, separating the state of a value being
/// unset (absent) from a value being explicitly null.
///
/// **Note**: [Val] is primarily intended for nullable fields (e.g. `Val<String?>`)
/// to differentiate between keeping the existing value (absent) and explicitly
/// clearing it to `null`. Non-nullable fields typically do not require [Val]
/// in methods like `copyWith`, because a standard nullable parameter (`String? name`)
/// already uses `null` to indicate that the field should remain unchanged (`name ?? this.name`).
abstract class Val<T> {
  const Val._();

  /// Creates a [Val] wrapping the specified [value].
  const factory Val(T value) = _Val<T>._;

  /// Creates a [Val] representing an absent value.
  const factory Val.absent() = _Absent<T>._;

  /// Whether this [Val] is absent.
  bool get isAbsent;

  /// Resolves the value, returning [current] if this [Val] is absent.
  T call(T current);
}

class _Val<T> extends Val<T> {
  const _Val._(this.value) : super._();

  final T value;

  @override
  bool get isAbsent => false;

  @override
  T call(T current) => value;

  @override
  bool operator ==(Object other) {
    return other is _Val<Object?> && value == other.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Val<$T>($value)';
}

class _Absent<T> extends Val<T> {
  const _Absent._() : super._();

  @override
  bool get isAbsent => true;

  @override
  T call(T current) => current;

  @override
  bool operator ==(Object other) => other is _Absent<Object?>;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'Val<$T>.absent()';
}
