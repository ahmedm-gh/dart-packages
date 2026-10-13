/// A container object which may or may not contain a value.
///
/// Used to represent optional values, separating the state of a value being
/// unset (absent) from a value being explicitly null.
class Val<T> {
  /// The wrapped value, or `null`.
  final T? value;

  const Val._() : value = null;

  /// Creates a [Val] wrapping the specified [value].
  const Val(this.value);

  /// Creates a [Val] representing an absent value.
  const factory Val.absent() = Absent<T>._;

  /// Creates a [Val] explicitly wrapping `null` to clear/reset a field.
  const Val.clear() : value = null;

  /// Whether this [Val] is absent.
  bool get isAbsent => false;

  /// Resolves the value, returning [current] if this [Val] is absent.
  T call(T current) => value as T;

  @override
  bool operator ==(Object other) {
    return other is Val<Object?> &&
        isAbsent == other.isAbsent &&
        value == other.value;
  }

  @override
  int get hashCode => isAbsent.hashCode ^ value.hashCode;

  @override
  String toString() => '$runtimeType($value)';
}

/// Represents an absent [Val] container.
class Absent<T> extends Val<T> {
  const Absent._() : super._();

  @override
  bool get isAbsent => true;

  @override
  T call(T current) => current;
}

/// Extension to convert any value of type [T] into a [Val].
extension ValX<T extends Object?> on T {
  /// Wraps this value into a [Val].
  Val<T> get asVal => Val<T>(this);
}
