/// Represents a unique dependency identifier combining a type [T] and an optional [key].
final class BoxDependency<T extends Object> {
  /// Creates a dependency identifier for type [T] with an optional [key].
  const BoxDependency({this.key});

  /// The target [Type] for this dependency.
  Type get type => T;

  /// Returns the canonical lookup key: [T] when [key] is null (zero allocation),
  /// or a [BoxDependency<T>] when [key] is provided.
  static Object from<T extends Object>(Object? key) {
    return key == null ? T : BoxDependency<T>(key: key);
  }

  /// The optional qualifying key for named dependencies (e.g. String or Enum).
  final Object? key;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is BoxDependency && other.type == T && other.key == key;
  }

  @override
  int get hashCode {
    return T.hashCode ^ key.hashCode;
  }

  @override
  String toString() => key == null ? '$T' : '$T(key: $key)';
}

/// Defines which instance [DependencyBox.get] resolves when multiple
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
}

/// Strategy that resolves the last (most recently) registered instance.
final class LastResolution extends MultiResolution {
  /// Creates a strategy that resolves the last registered instance.
  const LastResolution();
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
    if (identical(this, other)) {
      return true;
    }
    return other is IndexResolution && other.index == index;
  }

  @override
  int get hashCode {
    return index.hashCode;
  }
}

/// Strategy that resolves the instance registered with the specified [key].
final class KeyResolution extends MultiResolution {
  /// Creates a strategy that resolves the instance registered with [key].
  const KeyResolution(this.key);

  /// The key identifying which instance to resolve.
  final Object key;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is KeyResolution && other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

/// Represents the configuration for a type that allows multiple registrations
/// in a [DependencyBox].
final class Multi<T extends Object> {
  /// Creates a multi-instance configuration for type [T] with an optional
  /// [resolution] strategy (defaults to [MultiResolution.last]).
  const Multi([this.resolution = MultiResolution.last]);

  /// Resolves the first registered instance of [T].
  const Multi.first() : resolution = MultiResolution.first;

  /// Resolves the last registered instance of [T].
  const Multi.last() : resolution = MultiResolution.last;

  /// Resolves the instance of [T] registered at the specified [index].
  Multi.at(int index) : resolution = IndexResolution(index);

  /// Resolves the instance of [T] registered with the specified [key].
  Multi.key(Object key) : resolution = KeyResolution(key);

  /// The target [Type] configured for multiple registrations.
  Type get type {
    return T;
  }

  /// The resolution strategy used by [DependencyBox.get] for type [T].
  final MultiResolution resolution;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Multi && other.type == type;
  }

  @override
  int get hashCode {
    return T.hashCode;
  }
}
