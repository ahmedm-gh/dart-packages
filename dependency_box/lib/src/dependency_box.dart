import 'dart:async';

import 'box_config.dart';
import 'dependency_box_impl.dart';
import 'multi_registration.dart';

/// Runtime error types for [DependencyBox].
enum _ErrorType {
  /// Errors that should be caught by assertions.
  assertion,

  /// Errors resulting from invalid arguments.
  argumentError,

  /// Errors resulting from the state of the container.
  stateError,
}

/// Categories of errors that can occur within a [DependencyBox].
enum DependencyBoxError {
  /// A dependency with the same type and key is already registered.
  duplicateRegistration(_ErrorType.assertion),

  /// An attempt was made to register multiple instances for a type where multi-registration was not enabled.
  multiNotAllowed(_ErrorType.assertion),

  /// A requested dependency was not found in the container hierarchy.
  notFound(_ErrorType.stateError),

  /// An operation was attempted on a disposed container.
  disposed(_ErrorType.stateError),

  /// A circular dependency was detected during resolution.
  circularDependency(_ErrorType.stateError),

  /// An invalid or unexpected argument was provided during parameterized resolution.
  invalidArgument(_ErrorType.argumentError);

  /// The type of error to throw.
  final _ErrorType _errorType;

  const DependencyBoxError(this._errorType);
}

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

  /// Creates an error for [DependencyBox] based on [error] category.
  static Object createError(String message, DependencyBoxError error) {
    return switch (error._errorType) {
      _ErrorType.assertion => AssertionError(message),
      _ErrorType.argumentError => ArgumentError(message),
      _ErrorType.stateError => StateError(message),
    };
  }

  /// Reports and throws an error for [DependencyBox].
  static Never throwError(String message, DependencyBoxError error) {
    throw createError(message, error);
  }

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

  /// The root container in this hierarchy, or `this` if this is already the root.
  DependencyBox get root;

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

  /// Configures multiple registrations for the specified [types] using [MultiRegistration]
  /// value entities.
  void allowMultiple(Iterable<MultiRegistration> types);

  /// Enables multiple registrations for type [T] with an optional [resolution] strategy.
  void allowMulti<T extends Object>({
    MultiResolution resolution = DependencyBoxConfig.defaultMultiResolution,
  });

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

  /// Registers a cached factory for type [T] that retains its created instance
  /// via a [WeakReference], optionally qualified by [key].
  ///
  /// The instance acts as an auto-expiring temporary singleton while retained by active callers,
  /// and is automatically garbage collected and re-created once all external references are released.
  ///
  /// Optionally provide [onDispose] to clean up resources when the container is disposed.
  void addCachedFactory<T extends Object>(
    T Function(DependencyBox container) factory, {
    Object? key,
    FutureOr<void> Function(T instance)? onDispose,
  });

  /// Registers an eager [instance] of type [T] as a shared singleton anchored to the root
  /// container, shared across all current and future child scopes, optionally qualified by [key].
  ///
  /// Optionally provide [onDispose] to clean up resources when the root container is disposed.
  void addSharedSingleton<T extends Object>(
    T instance, {
    Object? key,
    FutureOr<void> Function(T instance)? onDispose,
  });

  /// Registers a lazy singleton of type [T] anchored to the root container, constructed
  /// on first access and shared across all current and future child scopes,
  /// optionally qualified by [key].
  ///
  /// Optionally provide [onDispose] to clean up resources when the root container is disposed.
  void addSharedLazySingleton<T extends Object>(
    T Function(DependencyBox container) factory, {
    Object? key,
    FutureOr<void> Function(T instance)? onDispose,
  });

  /// Registers a weak-reference cached factory of type [T] anchored to the root container,
  /// shared across all current and future child scopes, optionally qualified by [key].
  ///
  /// The instance is shared while retained by active callers, and automatically
  /// re-created on next access once all external references are released.
  ///
  /// Optionally provide [onDispose] to clean up resources when the root container is disposed.
  void addSharedCachedFactory<T extends Object>(
    T Function(DependencyBox container) factory, {
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
    bool disposeOld = DependencyBoxConfig.defaultDisposeOldOnReplace,
    FutureOr<void> Function(T instance)? onDispose,
  });

  /// Removes the dependency of type [T], optionally qualified by [key].
  ///
  /// If [dispose] is `true`, any active instance is disposed. Returns `true`
  /// if a registration was found and removed.
  Future<bool> remove<T extends Object>({
    Object? key,
    bool dispose = DependencyBoxConfig.defaultDisposeOnRemove,
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

  /// Prints and returns a diagnostic overview of this container, including registered
  /// types, keys, lifecycle kinds, instance states, and scope hierarchy.
  ///
  /// Output is printed via [printer] (defaults to [print]) and returned as a formatted [String].
  /// Set [includeParent] to `false` to exclude registrations inherited from parent scopes.
  String printContainer({
    void Function(Object? object)? printer,
    bool includeParent = true,
  });
}
