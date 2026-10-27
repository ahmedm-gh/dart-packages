import 'dart:async';

import 'box_config.dart';
import 'dependency_box.dart';

/// Represents an internal registration entry in a [DependencyBox].
sealed class DependencyBoxRegistration<T extends Object, A> {
  const DependencyBoxRegistration();

  /// Creates an eager singleton registration.
  const factory DependencyBoxRegistration.singleton(
    T instance, {
    FutureOr<void> Function(T instance)? onDispose,
  }) = _SingletonRegistration<T, A>;

  /// Creates a lazy singleton registration deferred until first access.
  factory DependencyBoxRegistration.lazySingleton(
    T Function(DependencyBox) factory, {
    FutureOr<void> Function(T instance)? onDispose,
  }) = _LazySingletonRegistration<T, A>;

  /// Creates a cached factory registration whose instance is retained via a [WeakReference].
  factory DependencyBoxRegistration.cachedFactory(
    T Function(DependencyBox) factory, {
    FutureOr<void> Function(T instance)? onDispose,
  }) = _CachedFactoryRegistration<T, A>;

  /// Creates an un-cached factory registration.
  const factory DependencyBoxRegistration.factory(
    T Function(DependencyBox) factory,
  ) = _FactoryRegistration<T, A>;

  /// Creates a parameterized factory registration.
  const factory DependencyBoxRegistration.factoryWith(
    T Function(DependencyBox, A) factory,
  ) = _FactoryWithRegistration<T, A>;

  /// Creates an asynchronous singleton registration deferred until first access.
  factory DependencyBoxRegistration.asyncSingleton(
    Object id,
    Future<T> Function(DependencyBox) factory, {
    FutureOr<void> Function(T instance)? onDispose,
  }) = _AsyncSingletonRegistration<T, A>;

  /// The target dependency type [T].
  Type get targetType => T;

  /// The parameter type [A] for parameterized registrations, or `Object?`.
  Type get paramType => A;

  /// A descriptive string representing the lifecycle kind of this registration.
  String get kind;

  /// Returns `true` if this registration is currently in the process of resolving.
  bool get isResolving => false;

  /// Resolves the instance within [container], executing [onCreated] on initial instantiation.
  T resolve(
    DependencyBox container,
    void Function(T instance) onCreated, [
    Object? args,
  ]);

  /// Resolves the instance asynchronously within [container], executing [onCreated]
  /// on initial instantiation.
  Future<T> resolveAsync(
    DependencyBox container,
    void Function(T instance) onCreated, [
    Object? args,
  ]) {
    return Future<T>.sync(() => resolve(container, onCreated, args));
  }

  /// Returns the current instantiated object, if available.
  Object? get currentInstance;

  /// Disposes the held instance and executes any configured [onDispose] callbacks.
  FutureOr<void> dispose();
}

final class _SingletonRegistration<T extends Object, A>
    extends DependencyBoxRegistration<T, A> {
  const _SingletonRegistration(this.instance, {this.onDispose});

  final T instance;
  final FutureOr<void> Function(T instance)? onDispose;

  @override
  String get kind => 'Singleton';

  @override
  Object? get currentInstance {
    return instance;
  }

  @override
  T resolve(
    DependencyBox container,
    void Function(T instance) onCreated, [
    Object? args,
  ]) {
    return instance;
  }

  @override
  Future<T> resolveAsync(
    DependencyBox container,
    void Function(T instance) onCreated, [
    Object? args,
  ]) {
    return Future<T>.value(instance);
  }

  @override
  FutureOr<void> dispose() {
    FutureOr<void> r1;
    if (onDispose case final callback?) {
      r1 = callback(instance);
    }
    if (instance is DependencyDisposable) {
      final r2 = (instance as DependencyDisposable).dispose();
      if (r1 is Future<void> || r2 is Future<void>) {
        return _awaitBoth(r1, r2);
      }
      return null;
    }
    return r1;
  }
}

final class _LazySingletonRegistration<T extends Object, A>
    extends DependencyBoxRegistration<T, A> {
  _LazySingletonRegistration(this.factory, {this.onDispose});

  final T Function(DependencyBox container) factory;
  final FutureOr<void> Function(T instance)? onDispose;

  T? _instance;
  bool _isResolving = false;

  @override
  String get kind => 'LazySingleton';

  @override
  bool get isResolving => _isResolving;

  @override
  Object? get currentInstance {
    return _instance;
  }

  @override
  T resolve(
    DependencyBox container,
    void Function(T instance) onCreated, [
    Object? args,
  ]) {
    if (_instance case final cached?) {
      return cached;
    }

    if (DependencyBoxConfig.isDebug) {
      if (_isResolving) {
        return DependencyBox.throwError(
          'Circular dependency detected in synchronous lazy resolution: $T',
          DependencyBoxError.circularDependency,
        );
      }
      _isResolving = true;
      try {
        final instance = factory(container);
        _instance = instance;
        onCreated(instance);
        return instance;
      } finally {
        _isResolving = false;
      }
    }

    final instance = factory(container);
    _instance = instance;
    onCreated(instance);
    return instance;
  }

  @override
  FutureOr<void> dispose() {
    if (_instance case final instance?) {
      FutureOr<void> r1;
      if (onDispose case final callback?) {
        r1 = callback(instance);
      }
      if (instance is DependencyDisposable) {
        final r2 = (instance as DependencyDisposable).dispose();
        if (r1 is Future<void> || r2 is Future<void>) {
          return _awaitBoth(r1, r2);
        }
        return null;
      }
      return r1;
    }
    return null;
  }
}

final class _CachedFactoryRegistration<T extends Object, A>
    extends DependencyBoxRegistration<T, A> {
  _CachedFactoryRegistration(this.factory, {this.onDispose});

  final T Function(DependencyBox container) factory;
  final FutureOr<void> Function(T instance)? onDispose;

  WeakReference<T>? _weakRef;
  bool _isResolving = false;

  @override
  String get kind => 'CachedFactory';

  @override
  bool get isResolving => _isResolving;

  @override
  Object? get currentInstance {
    return _weakRef?.target;
  }

  @override
  T resolve(
    DependencyBox container,
    void Function(T instance) onCreated, [
    Object? args,
  ]) {
    if (_weakRef?.target case final cached?) {
      return cached;
    }

    if (DependencyBoxConfig.isDebug) {
      if (_isResolving) {
        return DependencyBox.throwError(
          'Circular dependency detected in cached factory resolution: $T',
          DependencyBoxError.circularDependency,
        );
      }
      _isResolving = true;
      try {
        final instance = factory(container);
        if (instance is num ||
            instance is bool ||
            instance is String ||
            instance is Record) {
          return DependencyBox.throwError(
            'Cannot create WeakReference for type $T. '
            'Dart does not allow WeakReference on strings, numbers, booleans, records, or structs. '
            'Use addLazySingleton or addFactory instead.',
            DependencyBoxError.invalidArgument,
          );
        }
        _weakRef = WeakReference<T>(instance);
        onCreated(instance);
        return instance;
      } finally {
        _isResolving = false;
      }
    }

    final instance = factory(container);
    _weakRef = WeakReference<T>(instance);
    onCreated(instance);
    return instance;
  }

  @override
  FutureOr<void> dispose() {
    if (_weakRef?.target case final instance?) {
      _weakRef = null;
      FutureOr<void> r1;
      if (onDispose case final callback?) {
        r1 = callback(instance);
      }
      if (instance is DependencyDisposable) {
        final r2 = (instance as DependencyDisposable).dispose();
        if (r1 is Future<void> || r2 is Future<void>) {
          return _awaitBoth(r1, r2);
        }
        return null;
      }
      return r1;
    }
    return null;
  }
}

final class _FactoryRegistration<T extends Object, A>
    extends DependencyBoxRegistration<T, A> {
  const _FactoryRegistration(this.factory);

  final T Function(DependencyBox container) factory;

  @override
  String get kind => 'Factory';

  @override
  Object? get currentInstance {
    return null;
  }

  @override
  T resolve(
    DependencyBox container,
    void Function(T instance) onCreated, [
    Object? args,
  ]) {
    final instance = factory(container);
    onCreated(instance);
    return instance;
  }

  @override
  FutureOr<void> dispose() => null;
}

final class _FactoryWithRegistration<T extends Object, A>
    extends DependencyBoxRegistration<T, A> {
  const _FactoryWithRegistration(this.factory);

  final T Function(DependencyBox container, A args) factory;

  @override
  String get kind => 'FactoryWith<$A>';

  @override
  Object? get currentInstance {
    return null;
  }

  @override
  T resolve(
    DependencyBox container,
    void Function(T instance) onCreated, [
    Object? args,
  ]) {
    final A typedArgs;
    if (DependencyBoxConfig.isDebug) {
      try {
        typedArgs = args as A;
      } on TypeError {
        return DependencyBox.throwError(
          'Expected args of type $A for $T, but got ${args.runtimeType}',
          DependencyBoxError.invalidArgument,
        );
      }
    } else {
      typedArgs = args as A;
    }

    final instance = factory(container, typedArgs);
    onCreated(instance);
    return instance;
  }

  @override
  FutureOr<void> dispose() => null;
}

final class _AsyncSingletonRegistration<T extends Object, A>
    extends DependencyBoxRegistration<T, A> {
  _AsyncSingletonRegistration(this.id, this.factory, {this.onDispose});

  final Object id;
  final Future<T> Function(DependencyBox container) factory;
  final FutureOr<void> Function(T instance)? onDispose;

  T? _instance;
  Completer<T>? _completer;

  static const _asyncChainKey = #_dependency_box_async_chain;

  @override
  String get kind => 'AsyncSingleton';

  @override
  bool get isResolving => _completer != null;

  @override
  Object? get currentInstance {
    return _instance;
  }

  @override
  T resolve(
    DependencyBox container,
    void Function(T instance) onCreated, [
    Object? args,
  ]) {
    if (_instance case final cached?) {
      return cached;
    }
    return DependencyBox.throwError(
      'Cannot synchronously resolve uninitialized async singleton of type $T. '
      'Use getAsync<$T>() instead.',
      DependencyBoxError.notFound,
    );
  }

  @override
  Future<T> resolveAsync(
    DependencyBox container,
    void Function(T instance) onCreated, [
    Object? args,
  ]) {
    if (DependencyBoxConfig.isDebug && container.isDisposed) {
      return Future<T>.error(
        DependencyBox.createError(
          'Cannot resolve dependency from a disposed DependencyBox.',
          DependencyBoxError.disposed,
        ),
        StackTrace.current,
      );
    }

    if (_instance case final cached?) {
      return Future<T>.value(cached);
    }

    final currentChain = DependencyBoxConfig.isDebug
        ? Zone.current[_asyncChainKey] as List<Object>?
        : null;
    if (DependencyBoxConfig.isDebug &&
        currentChain != null &&
        currentChain.contains(id)) {
      final cyclePath = [...currentChain, id]
          .map((e) {
            return e.toString();
          })
          .join(' -> ');
      return Future<T>.error(
        DependencyBox.createError(
          'Circular dependency detected in async resolution: $cyclePath',
          DependencyBoxError.circularDependency,
        ),
        StackTrace.current,
      );
    }

    if (_completer case final activeCompleter?) {
      return activeCompleter.future;
    }

    final completer = Completer<T>();
    _completer = completer;

    final nextChain = DependencyBoxConfig.isDebug
        ? [...?currentChain, id]
        : null;

    runZoned(() async {
      try {
        final instance = await factory(container);
        if (DependencyBoxConfig.isDebug && identical(instance, null)) {
          DependencyBox.throwError(
            'Async factory for $T returned null, but $T is non-nullable.',
            DependencyBoxError.notFound,
          );
        }

        if (container.isDisposed) {
          _completer = null;
          if (onDispose case final callback?) {
            await callback(instance);
          }
          if (instance is DependencyDisposable) {
            await instance.dispose();
          }
          if (!completer.isCompleted) {
            completer.completeError(
              DependencyBox.createError(
                'DependencyBox was disposed during initialization of $T.',
                DependencyBoxError.disposed,
              ),
              StackTrace.current,
            );
          }
          return;
        }

        _instance = instance;
        _completer = null;
        onCreated(instance);
        if (!completer.isCompleted) {
          completer.complete(instance);
        }
      } catch (error, stackTrace) {
        _completer = null;
        _instance = null;
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      }
    }, zoneValues: nextChain != null ? {_asyncChainKey: nextChain} : null);

    return completer.future;
  }

  @override
  FutureOr<void> dispose() {
    if (_instance case final instance?) {
      FutureOr<void> r1;
      if (onDispose case final callback?) {
        r1 = callback(instance);
      }
      if (instance is DependencyDisposable) {
        final r2 = (instance as DependencyDisposable).dispose();
        if (r1 is Future<void> || r2 is Future<void>) {
          return _awaitBoth(r1, r2);
        }
        return null;
      }
      return r1;
    }
    return null;
  }
}

Future<void> _awaitBoth(FutureOr<void> r1, FutureOr<void> r2) async {
  if (r1 is Future<void>) await r1;
  if (r2 is Future<void>) await r2;
}
