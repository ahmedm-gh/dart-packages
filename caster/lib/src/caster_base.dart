import 'dart:developer' as developer;
import 'exceptions.dart';

/// The central namespace for [caster] configuration, custom type defaults,
/// and built-in type default resolution.
abstract class Caster {
  const Caster._();

  /// The name used for developer logging tags.
  static const String loggerName = 'caster';

  /// Global flag to enable diagnostic logging via [developer.log].
  static bool debug = false;

  static final Map<Type, Object> _customDefaults = {};

  /// Registers a custom default [value] for [T] to be used by [safeCast]
  /// when no fallback is provided and casting fails.
  ///
  /// An existing registration for the same [T] key is replaced.
  static void registerDefaultValue<T extends Object>(T value) {
    _customDefaults[T] = value;
  }

  /// Registers custom default values for specific types to be used by [safeCast]
  /// when no fallback is provided and casting fails.
  ///
  /// Existing registrations for the same [Type] key are replaced.
  static void registerDefaultValues(Map<Type, Object> values) {
    _customDefaults.addAll(values);
  }

  /// Clears all custom defaults registered via [registerDefaultValue] or [registerDefaultValues].
  ///
  /// Primarily used to ensure test isolation between unit tests.
  static void resetDefaultValues() => _customDefaults.clear();

  /// Removes a registered custom default value for [T].
  ///
  /// Returns `true` if an entry was removed, `false` otherwise.
  static bool unregisterDefaultValue<T>() {
    return _customDefaults.remove(T) != null;
  }

  /// Removes registered custom default values for multiple [types].
  static void unregisterDefaultValues(Iterable<Type> types) {
    for (final type in types) {
      _customDefaults.remove(type);
    }
  }

  /// Pre-built map of built-in type defaults for O(1) lookup.
  static const Map<Type, Object?> _builtInDefaults = {
    Iterable: <Object?>[],
    List: <Object?>[],
    Iterable<int>: <int>[],
    List<int>: <int>[],
    Iterable<int?>: <int?>[],
    List<int?>: <int?>[],
    Iterable<String>: <String>[],
    List<String>: <String>[],
    Iterable<String?>: <String?>[],
    List<String?>: <String?>[],
    Iterable<double>: <double>[],
    List<double>: <double>[],
    Iterable<double?>: <double?>[],
    List<double?>: <double?>[],
    Iterable<num>: <num>[],
    List<num>: <num>[],
    Iterable<num?>: <num?>[],
    List<num?>: <num?>[],
    Iterable<bool>: <bool>[],
    List<bool>: <bool>[],
    Iterable<bool?>: <bool?>[],
    List<bool?>: <bool?>[],
    Set: <Object?>{},
    Set<int>: <int>{},
    Set<int?>: <int?>{},
    Set<String>: <String>{},
    Set<String?>: <String?>{},
    Set<double>: <double>{},
    Set<double?>: <double?>{},
    Set<num>: <num>{},
    Set<num?>: <num?>{},
    Set<bool>: <bool>{},
    Set<bool?>: <bool?>{},
    Map: <Object?, Object?>{},
    Map<Object?, Object?>: <Object?, Object?>{},
    Map<String, dynamic>: <String, dynamic>{},
    Map<String, Object?>: <String, Object?>{},
    Map<String, String>: <String, String>{},
  };

  /// Returns the built-in type default value for [T], if one exists.
  ///
  /// Primitives ([int], [String], [bool], [double], [num]) use a direct fast-path,
  /// while collections and other types are looked up in [_builtInDefaults].
  static T? builtInDefault<T>() {
    return switch (T) {
      const (int) => 0 as T,
      const (String) => '' as T,
      const (bool) => false as T,
      const (double) => 0.0 as T,
      const (num) => 0 as T,
      _ => _builtInDefaults[T] as T?,
    };
  }
}

Type _typeOf<T>() => T;
final Type _objectNullableType = _typeOf<Object?>();

/// Checks if [T] is an unconstrained or non-concrete type parameter (`Object`, `Object?`, or `dynamic`).
@pragma('vm:prefer-inline')
bool isInvalidType<T>() {
  return switch (T) {
    const (Object) || const (dynamic) => true,
    _ when T == _objectNullableType => true,
    _ => false,
  };
}

/// Internal helper that resolves an explicit fallback, registered custom default,
/// built-in default, or nullable fallback according to the precedence policy.
///
/// Throws a [CasterTypeException] if no fallback or default is available and [T] is non-nullable.
T resolveFallbackOrDefault<T>({
  T? fallback,
  bool useDefaults = true,
  Object? failedInput,
}) {
  // 1. Explicit fallback
  if (fallback != null) {
    if (Caster.debug) {
      developer.log('Using fallback for $T', name: Caster.loggerName);
    }
    return fallback;
  }

  // 2. Custom registered default & built-in type default
  if (useDefaults) {
    if (Caster._customDefaults.isNotEmpty) {
      if (Caster._customDefaults[T] case final T custom) {
        if (Caster.debug) {
          developer.log(
            'Using custom registered default for $T',
            name: Caster.loggerName,
          );
        }
        return custom;
      }
    }

    if (Caster.builtInDefault<T>() case final T defaultVal) {
      if (Caster.debug) {
        developer.log('Using type default for $T', name: Caster.loggerName);
      }
      return defaultVal;
    }
  }

  // 3. Nullable target type fallback
  if (null is T) {
    if (Caster.debug) {
      developer.log(
        'Returning null for uncastable input ($failedInput) as $T',
        name: Caster.loggerName,
      );
    }
    return null as T;
  }

  // 4. Non-nullable type failure
  throw CasterException.type(
    'Can not cast ${failedInput.runtimeType} to $T',
    stackTrace: StackTrace.current,
  );
}

/// Safely casts the given [input] to type [T].
///
/// ### Resolution Policy:
/// 1. If [T] is unconstrained (`Object`, `Object?`, or `dynamic`), throws a [CasterArgumentException].
/// 2. If [input] is already valid for [T], it is returned immediately (including `null` when [T] is nullable).
/// 3. If an explicit [fallback] is provided, it is returned.
/// 4. If [useDefaults] is `true`:
///    a. If a custom default is registered via [Caster.registerDefaultValue] or [Caster.registerDefaultValues] and satisfies [T], it is returned.
///    b. If a built-in type default exists for [T] (e.g. `0` for [int], `""` for [String], empty collection for [List]/[Set]/[Map]), it is returned.
/// 5. If [T] is nullable (`null is T`), returns `null`.
/// 6. Otherwise, throws a [CasterTypeException].
///
/// Diagnostic logs are output to [developer.log] when [Caster.debug] is `true`.
T safeCast<T>(
  Object? input, {
  T? fallback,
  bool useDefaults = true,
}) {
  if (isInvalidType<T>()) {
    throw CasterException.argument(
      'Type parameter T must be specified, got $T.',
      stackTrace: StackTrace.current,
    );
  }

  // Direct match fast path (includes input == null when null is T)
  if (input case final T match) {
    return match;
  }

  if (Caster.debug) {
    developer.log(
      'Trying to cast ${input.runtimeType} ($input) to $T',
      name: Caster.loggerName,
    );
  }

  return resolveFallbackOrDefault<T>(
    fallback: fallback,
    useDefaults: useDefaults,
    failedInput: input,
  );
}

/// Safely casts the given [input] to type [T], returning `null` if casting fails.
///
/// Unlike [safeCast], this does not resolve built-in or registered type defaults
/// and never throws a [CasterTypeException] for uncastable input.
///
/// Throws a [CasterArgumentException] if [T] is `Object`, `Object?`, or `dynamic`.
/// Diagnostic logs are output to [developer.log] when [Caster.debug] is `true`.
T? safeCastOrNull<T>(Object? input) {
  if (isInvalidType<T>()) {
    throw CasterException.argument(
      'Type parameter T must be specified, got $T.',
      stackTrace: StackTrace.current,
    );
  }

  if (input case final T match) {
    return match;
  }

  if (Caster.debug) {
    developer.log(
      'safeCastOrNull: could not cast ${input.runtimeType} ($input) to $T, returning null',
      name: Caster.loggerName,
    );
  }

  return null;
}
