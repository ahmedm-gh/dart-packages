import 'dart:async';

import 'box_config.dart';
import 'dependency.dart';
import 'dependency_box_implementation.dart';

/// A resource whose lifecycle is managed by a [DependencyBox].
abstract interface class DependencyDisposable {
  FutureOr<void> dispose();
}

/// Represents a modular collection of dependency registrations.
abstract interface class DependencyModule {
  /// Registers dependencies onto the provided [box].
  void register(DependencyBox box);
}

/// An inversion-of-control container managing dependency registrations,
/// lifecycles, and hierarchical scopes.
abstract class DependencyBox {
  /// Base constructor for [DependencyBox] implementations.
  const DependencyBox();

  /// Creates a new root dependency container.
  factory DependencyBox.main({String? name}) = DependencyBoxImpl;

  /// Creates a new child container with the specified [parent].
  factory DependencyBox.child({
    required DependencyBox parent,
    String? name,
  }) = DependencyBoxImpl.child;

  /// The optional name identifying this container.
  String? get name;

  /// The parent container of this child scope, or `null` if this is a root container.
  DependencyBox? get parent;

  /// Creates a scoped child container that inherits registrations from this container.
  DependencyBox createChild({String? name});

  /// Installs a modular collection of registrations via [module].
  void install(DependencyModule module) {
    module.register(this);
  }

  /// Installs multiple modular collections of registrations via [modules].
  void installAll(Iterable<DependencyModule> modules) {
    for (final module in modules) {
      module.register(this);
    }
  }

  /// Configures multiple registrations for the specified [types] using [Multi]
  /// value entities.
  void allowMultiple(Iterable<Multi> types);

  /// Enables multiple registrations for type [T] with an optional [resolution] strategy.
  void allowMulti<T extends Object>([
    MultiResolution resolution = BoxConfig.defaultMultiResolution,
  ]);

  /// Registers an eager [instance] of type [T] as a singleton, optionally qualified by [key].
  ///
  /// Optionally provide [onDispose] to clean up resources when the container is disposed.
  void addSingleton<T extends Object>(
    T instance, {
    Object? key,
    FutureOr<void> Function(T instance)? onDispose,
  });

  /// Registers multiple [instances] of type [T], optionally qualified by [key].
  ///
  /// Requires type [T] to be configured beforehand via [allowMultiple].
  void addSingletons<T extends Object>(
    Iterable<T> instances, {
    Object? key,
  });

  /// Registers a lazy singleton of type [T] constructed via [factory] on first access,
  /// optionally qualified by [key].
  ///
  /// Optionally provide [onDispose] to clean up resources when the container is disposed.
  void addLazySingleton<T extends Object>(
    T Function(DependencyBox container) factory, {
    Object? key,
    FutureOr<void> Function(T instance)? onDispose,
  });

  /// Registers a factory for type [T] that produces a new instance on every resolution,
  /// optionally qualified by [key].
  void addFactory<T extends Object>(
    T Function(DependencyBox container) factory, {
    Object? key,
  });

  /// Registers a factory for type [T] accepting arguments of type [A],
  /// optionally qualified by [key].
  void addFactoryWith<T extends Object, A>(
    T Function(DependencyBox container, A args) factory, {
    Object? key,
  });

  /// Registers an asynchronous singleton of type [T] constructed via [factory] on first access,
  /// optionally qualified by [key].
  ///
  /// Optionally provide [onDispose] to clean up resources when the container is disposed.
  void addAsyncSingleton<T extends Object>(
    Future<T> Function(DependencyBox container) factory, {
    Object? key,
    FutureOr<void> Function(T instance)? onDispose,
  });

  /// Replaces any existing registration of type [T] with [instance].
  ///
  /// If [disposeOld] is `true` and the replaced registration held an active instance,
  /// it is disposed immediately.
  void replaceSingleton<T extends Object>(
    T instance, {
    Object? key,
    bool disposeOld = BoxConfig.defaultDisposeOldOnReplace,
    FutureOr<void> Function(T instance)? onDispose,
  });

  /// Removes the dependency of type [T], optionally qualified by [key].
  ///
  /// If [dispose] is `true`, any active instance is disposed. Returns `true`
  /// if a registration was found and removed.
  Future<bool> remove<T extends Object>({
    Object? key,
    bool dispose = BoxConfig.defaultDisposeOnRemove,
  });

  /// Resolves the registered instance of type [T], optionally qualified by [key].
  ///
  /// For parameterized factories, provide [args]. Throws [StateError] if type [T]
  /// is not registered.
  T get<T extends Object>({Object? args, Object? key});

  /// Resolves the registered instance of type [T], or returns `null` if not registered.
  T? tryGet<T extends Object>({Object? args, Object? key});

  /// Resolves the registered instance of type [T] asynchronously, optionally qualified by [key].
  ///
  /// For parameterized factories, provide [args]. If type [T] is registered as a synchronous
  /// dependency, it is resolved immediately and returned as a completed [Future].
  /// Throws [StateError] if type [T] is not registered.
  Future<T> getAsync<T extends Object>({Object? args, Object? key});

  /// Resolves the registered instance of type [T] asynchronously, or returns `null` if not registered.
  Future<T?> tryGetAsync<T extends Object>({Object? args, Object? key});

  /// Returns a list of all registered instances of type [T], optionally qualified by [key].
  ///
  /// Returns an empty list if type [T] is not registered.
  List<T> getAll<T extends Object>({Object? args, Object? key});

  /// Returns a list of all registered instances of type [T] asynchronously, optionally qualified by [key].
  Future<List<T>> getAllAsync<T extends Object>({Object? args, Object? key});

  /// Returns `true` if an instance or factory of type [T] is registered with the optional [key].
  bool contains<T extends Object>({Object? key});

  /// Returns all registration keys present in this container (including parent registrations).
  Iterable<Object> get registeredKeys;

  /// The number of direct registrations in this container.
  int get length;

  /// Whether this container has no direct registrations.
  bool get isEmpty => length == 0;

  /// Whether this container has at least one direct registration.
  bool get isNotEmpty => length > 0;

  /// Returns `true` if this container has been disposed.
  bool get isDisposed;

  /// Clears all registrations in this container and invokes disposal hooks on any active instances.
  ///
  /// For child containers, parent registrations remain completely unaffected.
  Future<void> dispose();
}

/// Represents an internal registration entry in a [DependencyBox].
sealed class DependencyBoxRegistration<T extends Object, A> {
  const DependencyBoxRegistration();

  /// Creates a registration holding an eager [instance] value.
  const factory DependencyBoxRegistration.value(
    T instance, {
    FutureOr<void> Function(T instance)? onDispose,
  }) = _ValueRegistration<T, A>;

  /// Creates a lazy singleton registration deferred until first access.
  factory DependencyBoxRegistration.lazy(
    T Function(DependencyBox) factory, {
    FutureOr<void> Function(T instance)? onDispose,
  }) = _LazyRegistration<T, A>;

  /// Creates an un-cached factory registration.
  const factory DependencyBoxRegistration.factory(
    T Function(DependencyBox) factory,
  ) = _FactoryRegistration<T, A>;

  /// Creates a parameterized factory registration.
  const factory DependencyBoxRegistration.parameterized(
    T Function(DependencyBox, A) factory,
  ) = _ParameterizedFactoryRegistration<T, A>;

  /// Creates an asynchronous singleton registration deferred until first access.
  factory DependencyBoxRegistration.async(
    Object id,
    Future<T> Function(DependencyBox) factory, {
    FutureOr<void> Function(T instance)? onDispose,
  }) = _AsyncRegistration<T, A>;

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
  ]);

  /// Returns the current instantiated object, if available.
  Object? get currentInstance;

  /// Disposes the held instance and executes any configured [onDispose] callbacks.
  Future<void> dispose();
}

final class _ValueRegistration<T extends Object, A>
    extends DependencyBoxRegistration<T, A> {
  const _ValueRegistration(this.instance, {this.onDispose});

  final T instance;
  final FutureOr<void> Function(T instance)? onDispose;

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
  Future<void> dispose() async {
    if (onDispose case final callback?) {
      await callback(instance);
    }
    if (instance is DependencyDisposable) {
      await (instance as DependencyDisposable).dispose();
    }
  }
}

final class _LazyRegistration<T extends Object, A>
    extends DependencyBoxRegistration<T, A> {
  _LazyRegistration(this.factory, {this.onDispose});

  final T Function(DependencyBox container) factory;
  final FutureOr<void> Function(T instance)? onDispose;

  T? _instance;
  bool _isResolving = false;

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

    if (_isResolving) {
      throw StateError(
        'Circular dependency detected in synchronous lazy resolution: $T',
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

  @override
  Future<T> resolveAsync(
    DependencyBox container,
    void Function(T instance) onCreated, [
    Object? args,
  ]) {
    try {
      return Future<T>.value(resolve(container, onCreated, args));
    } catch (e, st) {
      return Future<T>.error(e, st);
    }
  }

  @override
  Future<void> dispose() async {
    if (_instance case final instance?) {
      if (onDispose case final callback?) {
        await callback(instance);
      }
      if (instance is DependencyDisposable) {
        await (instance as DependencyDisposable).dispose();
      }
    }
  }
}

final class _FactoryRegistration<T extends Object, A>
    extends DependencyBoxRegistration<T, A> {
  const _FactoryRegistration(this.factory);

  final T Function(DependencyBox container) factory;

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
    if (factory(container) case final instance) {
      onCreated(instance);
      return instance;
    }
  }

  @override
  Future<T> resolveAsync(
    DependencyBox container,
    void Function(T instance) onCreated, [
    Object? args,
  ]) {
    try {
      return Future<T>.value(resolve(container, onCreated, args));
    } catch (e, st) {
      return Future<T>.error(e, st);
    }
  }

  @override
  Future<void> dispose() async {}
}

final class _ParameterizedFactoryRegistration<T extends Object, A>
    extends DependencyBoxRegistration<T, A> {
  const _ParameterizedFactoryRegistration(this.factory);

  final T Function(DependencyBox container, A args) factory;

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
    if (args is! A) {
      throw ArgumentError(
        'Expected args of type $A for $T, but got ${args.runtimeType}',
      );
    }

    if (factory(container, args) case final instance) {
      onCreated(instance);
      return instance;
    }
  }

  @override
  Future<T> resolveAsync(
    DependencyBox container,
    void Function(T instance) onCreated, [
    Object? args,
  ]) {
    try {
      return Future<T>.value(resolve(container, onCreated, args));
    } catch (e, st) {
      return Future<T>.error(e, st);
    }
  }

  @override
  Future<void> dispose() async {}
}

final class _AsyncRegistration<T extends Object, A>
    extends DependencyBoxRegistration<T, A> {
  _AsyncRegistration(this.id, this.factory, {this.onDispose});

  final Object id;
  final Future<T> Function(DependencyBox container) factory;
  final FutureOr<void> Function(T instance)? onDispose;

  T? _instance;
  Completer<T>? _completer;

  static const _asyncChainKey = #_dependency_box_async_chain;

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
    throw StateError(
      'Cannot synchronously resolve uninitialized async singleton of type $T. '
      'Use getAsync<$T>() instead.',
    );
  }

  @override
  Future<T> resolveAsync(
    DependencyBox container,
    void Function(T instance) onCreated, [
    Object? args,
  ]) {
    if (container.isDisposed) {
      return Future<T>.error(
        StateError('Cannot resolve dependency from a disposed DependencyBox.'),
        StackTrace.current,
      );
    }

    if (_instance case final cached?) {
      return Future<T>.value(cached);
    }

    final currentChain = Zone.current[_asyncChainKey] as List<Object>?;
    if (currentChain != null && currentChain.contains(id)) {
      final cyclePath = [...currentChain, id].map((e) {
        return e.toString();
      }).join(' -> ');
      return Future<T>.error(
        StateError(
          'Circular dependency detected in async resolution: $cyclePath',
        ),
        StackTrace.current,
      );
    }

    if (_completer case final activeCompleter?) {
      return activeCompleter.future;
    }

    final completer = Completer<T>();
    _completer = completer;

    final nextChain = [...?currentChain, id];

    runZoned(
      () async {
        try {
          final instance = await factory(container);
          if (identical(instance, null)) {
            throw StateError(
              'Async factory for $T returned null, but $T is non-nullable.',
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
                StateError(
                  'DependencyBox was disposed during initialization of $T.',
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
      },
      zoneValues: {_asyncChainKey: nextChain},
    );

    return completer.future;
  }

  @override
  Future<void> dispose() async {
    if (_instance case final instance?) {
      if (onDispose case final callback?) {
        await callback(instance);
      }
      if (instance is DependencyDisposable) {
        await (instance as DependencyDisposable).dispose();
      }
    }
  }
}
