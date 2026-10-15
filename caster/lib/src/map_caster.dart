import 'caster_base.dart' as caster;
import 'exceptions.dart';

/// Extension methods for safely extracting and casting values from a [Map].
extension MapCaster<K, V> on Map<K, V> {
  /// Safely extracts and casts the value for [key] to type [T].
  ///
  /// If [key] is absent, or its value cannot be cast to [T], [fallback] is used.
  /// When [useDefaults] is `true` and no [fallback] is provided, built-in type defaults
  /// or registered custom defaults are used.
  ///
  /// Throws a [CasterArgumentException] if [T] is unconstrained (`Object`, `Object?`, or `dynamic`).
  T safeCast<T>(
    K key, {
    T? fallback,
    bool useDefaults = true,
  }) {
    if (caster.isInvalidType<T>()) {
      throw CasterException.argument(
        'Type parameter T must be specified, got $T.',
        stackTrace: StackTrace.current,
      );
    }

    final value = this[key];

    // Direct match fast path (non-null value)
    if (value != null) {
      if (value is T) return value as T;
    } else if (null is T && containsKey(key)) {
      // Key exists with null value, which is a valid instance of nullable T
      return null as T;
    }

    // Key is missing or value cannot be cast: resolve fallback or default
    return caster.resolveFallbackOrDefault<T>(
      fallback: fallback,
      useDefaults: useDefaults,
      failedInput: value,
    );
  }

  /// Safely extracts and casts the value for [key] to type [T], returning `null` if casting fails.
  ///
  /// Unlike [safeCast], this does not resolve built-in or registered type defaults
  /// and never throws a [CasterTypeException] for uncastable or missing input.
  ///
  /// Throws a [CasterArgumentException] if [T] is unconstrained (`Object`, `Object?`, or `dynamic`).
  T? safeCastOrNull<T>(K key) {
    if (caster.isInvalidType<T>()) {
      throw CasterException.argument(
        'Type parameter T must be specified, got $T.',
        stackTrace: StackTrace.current,
      );
    }

    final value = this[key];
    if (value != null) {
      if (value is T) return value as T;
    } else if (null is T && containsKey(key)) {
      return null as T;
    }
    return null;
  }

  /// Safely extracts and casts the first matching value for any of [keys] to type [T].
  ///
  /// Evaluates each key in order. The first value that successfully casts to [T]
  /// is returned. If no candidate key yields a castable value, returns [fallback]
  /// or the type default (via [resolveFallbackOrDefault]).
  ///
  /// Throws a [CasterArgumentException] if [T] is unconstrained (`Object`, `Object?`, or `dynamic`).
  T safeCastFirst<T>(
    Iterable<K> keys, {
    T? fallback,
    bool useDefaults = true,
  }) {
    if (caster.isInvalidType<T>()) {
      throw CasterException.argument(
        'Type parameter T must be specified, got $T.',
        stackTrace: StackTrace.current,
      );
    }

    for (final key in keys) {
      final value = this[key];
      if (value != null) {
        if (value is T) return value as T;
      } else if (null is T && containsKey(key)) {
        return null as T;
      }
    }

    return caster.resolveFallbackOrDefault<T>(
      fallback: fallback,
      useDefaults: useDefaults,
      failedInput: null,
    );
  }

  /// Safely extracts and casts a collection of values for [key] to type [T].
  ///
  /// Non-castable elements are filtered out unless a [fallback] is provided,
  /// in which case the [fallback] value is inserted in place of invalid elements.
  ///
  /// Returns an empty list if [key] is absent, null, or not an [Iterable].
  List<T> safeCastList<T>(K key, {T? fallback}) {
    final raw = this[key];
    if (raw is! Iterable) return const [];

    final result = <T>[];
    for (final element in raw) {
      if (element case final T match) {
        result.add(match);
      } else if (fallback != null) {
        result.add(fallback);
      }
    }
    return result;
  }

  /// Safely extracts and casts a collection of values for [key] to type [T],
  /// or returns `null` if [key] is absent, null, or not an [Iterable].
  ///
  /// Non-castable elements are filtered out unless a [fallback] is provided,
  /// in which case the [fallback] value is inserted in place of invalid elements.
  List<T>? safeCastListOrNull<T>(K key, {T? fallback}) {
    if (!containsKey(key)) return null;
    final raw = this[key];
    if (raw is! Iterable) return null;

    final result = <T>[];
    for (final element in raw) {
      if (element case final T match) {
        result.add(match);
      } else if (fallback != null) {
        result.add(fallback);
      }
    }
    return result;
  }

  /// Converts the value for [key] using [converter].
  ///
  /// Returns [fallback] if [converter] returns null or the key is absent.
  T convert<T>(
    K key, {
    required T? Function(Object?) converter,
    required T fallback,
  }) {
    final value = this[key];
    if (value != null || containsKey(key)) {
      return converter(value) ?? fallback;
    }
    return fallback;
  }

  /// Converts the value for [key] using [converter].
  ///
  /// Returns [fallback] (or `null`) if [converter] returns null or the key is absent.
  T? tryConvert<T>(
    K key, {
    required T? Function(Object?) converter,
    T? fallback,
  }) {
    final value = this[key];
    if (value != null || containsKey(key)) {
      return converter(value) ?? fallback;
    }
    return fallback;
  }

  /// Converts a collection of values for [key] using [converter].
  ///
  /// Non-convertible elements (where [converter] returns null) are filtered out
  /// unless a [fallback] is provided, in which case [fallback] is inserted.
  ///
  /// Returns an empty list if [key] is absent, null, or not an [Iterable].
  List<T> convertList<T>(
    K key, {
    required T? Function(Object?) converter,
    T? fallback,
  }) {
    final raw = this[key];
    if (raw is! Iterable) return const [];

    final result = <T>[];
    for (final element in raw) {
      final converted = converter(element);
      if (converted != null) {
        result.add(converted);
      } else if (fallback != null) {
        result.add(fallback);
      }
    }
    return result;
  }

  /// Converts a collection of values for [key] using [converter],
  /// or returns `null` if [key] is absent, null, or not an [Iterable].
  ///
  /// Non-convertible elements (where [converter] returns null) are filtered out
  /// unless a [fallback] is provided, in which case [fallback] is inserted.
  List<T>? convertListOrNull<T>(
    K key, {
    required T? Function(Object?) converter,
    T? fallback,
  }) {
    if (!containsKey(key)) return null;
    final raw = this[key];
    if (raw is! Iterable) return null;

    final result = <T>[];
    for (final element in raw) {
      final converted = converter(element);
      if (converted != null) {
        result.add(converted);
      } else if (fallback != null) {
        result.add(fallback);
      }
    }
    return result;
  }
}
