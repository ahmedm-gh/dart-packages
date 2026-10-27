/// Defines which instance `DependencyBox.get` resolves when multiple
/// instances of a type are registered.
sealed class MultiResolution {
  const MultiResolution();

  /// Resolves the first (initial) registered instance.
  static const MultiResolution first = FirstResolution();

  /// Resolves the last (most recently) registered instance.
  static const MultiResolution last = LastResolution();

  /// Resolves the instance registered at the specified 0-based [index].
  const factory MultiResolution.at(int index) = IndexResolution;

  /// Resolves the instance registered with the specified [key].
  const factory MultiResolution.key(Object key) = KeyResolution;
}

/// Strategy that resolves the first (initial) registered instance.
final class FirstResolution extends MultiResolution {
  /// Creates a strategy that resolves the first registered instance.
  const FirstResolution();

  @override
  String toString() => 'first';
}

/// Strategy that resolves the last (most recently) registered instance.
final class LastResolution extends MultiResolution {
  /// Creates a strategy that resolves the last registered instance.
  const LastResolution();

  @override
  String toString() => 'last';
}

/// Strategy that resolves the instance registered at the specified 0-based [index].
final class IndexResolution extends MultiResolution {
  /// Creates a strategy that resolves the instance registered at [index].
  const IndexResolution(this.index)
    : assert(index >= 0, 'Index must be non-negative');

  /// The 0-based index of the registered instance to resolve.
  final int index;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IndexResolution && other.index == index;
  }

  @override
  int get hashCode => index.hashCode;

  @override
  String toString() => 'at($index)';
}

/// Strategy that resolves the instance registered with the specified [key].
final class KeyResolution extends MultiResolution {
  /// Creates a strategy that resolves the instance registered with [key].
  const KeyResolution(this.key);

  /// The key identifying which instance to resolve.
  final Object key;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KeyResolution && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'key($key)';
}

/// Represents the configuration for a type that allows multiple registrations
/// in a `DependencyBox`.
///
/// ### Compile-Time Constants
/// All constructors support 100% compile-time constants:
/// ```dart
/// const MultiRegistration()
/// const MultiRegistration.first()
/// const MultiRegistration.last()
/// const MultiRegistration.at(1)
/// const MultiRegistration.key('my_key')
/// const MultiRegistration(MultiResolution.at(1))
/// const MultiRegistration(MultiResolution.key('my_key'))
/// ```
sealed class MultiRegistration<T extends Object> {
  const MultiRegistration._();

  /// Creates a multi-instance configuration for type [T] with an optional
  /// [resolution] strategy (defaults to [MultiResolution.last]).
  const factory MultiRegistration([MultiResolution resolution]) =
      _DefaultMultiRegistration<T>;

  /// Resolves the first registered instance of [T].
  const factory MultiRegistration.first() = _FirstMultiRegistration<T>;

  /// Resolves the last registered instance of [T].
  const factory MultiRegistration.last() = _LastMultiRegistration<T>;

  /// Resolves the instance of [T] registered at the specified [index].
  const factory MultiRegistration.at(int index) = _IndexMultiRegistration<T>;

  /// Resolves the instance of [T] registered with the specified [key].
  const factory MultiRegistration.key(Object key) = _KeyMultiRegistration<T>;

  /// The target [Type] configured for multiple registrations.
  Type get type => T;

  /// The resolution strategy used by `DependencyBox.get` for type [T].
  MultiResolution get resolution;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MultiRegistration && other.type == type;
  }

  @override
  int get hashCode => T.hashCode;

  @override
  String toString() => 'MultiRegistration<$T>($resolution)';
}

final class _DefaultMultiRegistration<T extends Object>
    extends MultiRegistration<T> {
  @override
  final MultiResolution resolution;

  const _DefaultMultiRegistration([this.resolution = MultiResolution.last])
    : super._();
}

final class _FirstMultiRegistration<T extends Object>
    extends MultiRegistration<T> {
  const _FirstMultiRegistration() : super._();

  @override
  MultiResolution get resolution => MultiResolution.first;
}

final class _LastMultiRegistration<T extends Object>
    extends MultiRegistration<T> {
  const _LastMultiRegistration() : super._();

  @override
  MultiResolution get resolution => MultiResolution.last;
}

final class _IndexMultiRegistration<T extends Object>
    extends MultiRegistration<T> {
  final int index;

  const _IndexMultiRegistration(this.index)
    : assert(index >= 0, 'Index must be non-negative'),
      super._();

  @override
  MultiResolution get resolution => IndexResolution(index);
}

final class _KeyMultiRegistration<T extends Object>
    extends MultiRegistration<T> {
  final Object key;

  const _KeyMultiRegistration(this.key) : super._();

  @override
  MultiResolution get resolution => KeyResolution(key);
}
