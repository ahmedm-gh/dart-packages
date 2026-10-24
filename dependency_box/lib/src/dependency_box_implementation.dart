import 'dart:async';

import 'box_config.dart';
import 'dependency.dart';
import 'dependency_box_base.dart';

class DependencyBoxImpl extends DependencyBox {
  final Map<Object, DependencyBoxRegistration> _container = {};

  Map<Object, List<DependencyBoxRegistration>>? _multiContainer;
  Map<Type, MultiResolution>? _multiTypes;

  final DependencyBoxImpl? _parent;
  final String? _name;

  DependencyBoxImpl({String? name})
      : _parent = null,
        _name = name;

  DependencyBoxImpl.child({
    required DependencyBox parent,
    String? name,
  })  : _parent = parent as DependencyBoxImpl,
        _name = name;

  @override
  String? get name {
    return _name;
  }

  @override
  DependencyBox? get parent {
    return _parent;
  }

  @override
  DependencyBox createChild({String? name}) {
    if (_isDisposed) {
      throw StateError(
        'Cannot create a child scope from a disposed DependencyBox.',
      );
    }
    return DependencyBoxImpl.child(parent: this, name: name);
  }

  bool get _canMultiTypes {
    return (_multiTypes?.isNotEmpty ?? false) ||
        (_parent?._canMultiTypes ?? false);
  }

  MultiResolution? _findMultiResolution(Type type) {
    if (_multiTypes?[type] case final res?) {
      return res;
    }
    return _parent?._findMultiResolution(type);
  }

  @override
  void allowMultiple(Iterable<Multi> types) {
    if (_isDisposed) {
      throw StateError(
        'Cannot configure multi-registration on a disposed DependencyBox.',
      );
    }
    final multiTypes = _multiTypes ??= {};
    for (final multi in types) {
      multiTypes[multi.type] = multi.resolution;
    }
  }

  @override
  void allowMulti<T extends Object>([
    MultiResolution resolution = BoxConfig.defaultMultiResolution,
  ]) {
    if (_isDisposed) {
      throw StateError(
        'Cannot configure multi-registration on a disposed DependencyBox.',
      );
    }
    final multiTypes = _multiTypes ??= {};
    multiTypes[T] = resolution;
  }

  void _register<T extends Object>(
    Object id,
    DependencyBoxRegistration registration, {
    Object? key,
  }) {
    if (_isDisposed) {
      throw StateError(
        'Cannot register dependencies on a disposed DependencyBox.',
      );
    }
    if (_canMultiTypes) {
      if (_findMultiResolution(T) case final resolution?) {
        final multiContainer = _multiContainer ??= {};
        final list = multiContainer.putIfAbsent(id, () {
          final existing = _container[id];
          return existing != null ? [existing] : [];
        });
        list.add(registration);

        switch (resolution) {
          case LastResolution():
            _resolveLast(id, registration);
          case FirstResolution():
            _resolveFirst(id, registration);
          case IndexResolution(:final index):
            _resolveIndex(id, registration, list, index);
          case KeyResolution(key: final targetKey):
            _resolveKey<T>(id, registration, key, targetKey);
        }
        return;
      }
    }

    assert(
      !_container.containsKey(id),
      'A dependency with id "$id" ($T) is already registered. '
      'To allow multiple instances for this type, enable it via allowMultiple({Multi<$T>()}).',
    );
    _multiContainer?.remove(id);
    _container[id] = registration;
  }

  void _resolveLast(
    Object id,
    DependencyBoxRegistration registration,
  ) {
    _container[id] = registration;
  }

  void _resolveFirst(
    Object id,
    DependencyBoxRegistration registration,
  ) {
    _container.putIfAbsent(id, () {
      return registration;
    });
  }

  void _resolveIndex(
    Object id,
    DependencyBoxRegistration registration,
    List<DependencyBoxRegistration> list,
    int index,
  ) {
    if (list.length - 1 == index) {
      _container[id] = registration;
    }
  }

  void _resolveKey<T extends Object>(
    Object id,
    DependencyBoxRegistration registration,
    Object? key,
    Object targetKey,
  ) {
    if (key != null) {
      _container[id] = registration;
    }
    if (key == targetKey) {
      _container[T] = registration;
    } else if (!_container.containsKey(T)) {
      _container[T] = registration;
    }
  }

  @override
  void addSingleton<T extends Object>(
    T instance, {
    Object? key,
    FutureOr<void> Function(T instance)? onDispose,
  }) {
    _register<T>(
      BoxDependency.from<T>(key),
      DependencyBoxRegistration<T, dynamic>.value(
        instance,
        onDispose: onDispose,
      ),
      key: key,
    );
  }

  @override
  void addSingletons<T extends Object>(
    Iterable<T> instances, {
    Object? key,
  }) {
    assert(
      _findMultiResolution(T) != null,
      'Cannot call addSingletons for type $T without enabling it first via allowMultiple({Multi<$T>()}).',
    );
    final id = BoxDependency.from<T>(key);
    for (final instance in instances) {
      _register<T>(
        id,
        DependencyBoxRegistration.value(instance),
        key: key,
      );
    }
  }

  @override
  void addLazySingleton<T extends Object>(
    T Function(DependencyBox container) factory, {
    Object? key,
    FutureOr<void> Function(T instance)? onDispose,
  }) {
    _register<T>(
      BoxDependency.from<T>(key),
      DependencyBoxRegistration<T, dynamic>.lazy(
        factory,
        onDispose: onDispose,
      ),
      key: key,
    );
  }

  @override
  void addFactory<T extends Object>(
    T Function(DependencyBox container) factory, {
    Object? key,
  }) {
    _register<T>(
      BoxDependency.from<T>(key),
      DependencyBoxRegistration.factory(factory),
      key: key,
    );
  }

  bool _isDisposed = false;

  @override
  bool get isDisposed {
    return _isDisposed;
  }

  @override
  void addAsyncSingleton<T extends Object>(
    Future<T> Function(DependencyBox container) factory, {
    Object? key,
    FutureOr<void> Function(T instance)? onDispose,
  }) {
    final id = BoxDependency.from<T>(key);
    _register<T>(
      id,
      DependencyBoxRegistration<T, dynamic>.async(
        id,
        factory,
        onDispose: onDispose,
      ),
      key: key,
    );
  }

  @override
  void addFactoryWith<T extends Object, A>(
    T Function(DependencyBox container, A args) factory, {
    Object? key,
  }) {
    _register<T>(
      BoxDependency.from<T>(key),
      DependencyBoxRegistration<T, A>.parameterized(factory),
      key: key,
    );
  }

  @override
  void replaceSingleton<T extends Object>(
    T instance, {
    Object? key,
    bool disposeOld = BoxConfig.defaultDisposeOldOnReplace,
    FutureOr<void> Function(T instance)? onDispose,
  }) {
    if (_isDisposed) {
      throw StateError(
        'Cannot register dependencies on a disposed DependencyBox.',
      );
    }
    final id = BoxDependency.from<T>(key);
    if (disposeOld) {
      final old = _container[id];
      if (old != null) {
        unawaited(old.dispose());
      }
      if (_multiContainer?.remove(id) case final multiList?) {
        for (final r in multiList) {
          if (!identical(r, old)) {
            unawaited(r.dispose());
          }
        }
      }
    } else {
      _multiContainer?.remove(id);
    }
    _container[id] = DependencyBoxRegistration<T, dynamic>.value(
      instance,
      onDispose: onDispose,
    );
  }

  @override
  Future<bool> remove<T extends Object>({
    Object? key,
    bool dispose = BoxConfig.defaultDisposeOnRemove,
  }) async {
    final id = BoxDependency.from<T>(key);
    final reg = _container.remove(id);
    final multiList = _multiContainer?.remove(id);

    if (reg == null && (multiList == null || multiList.isEmpty)) {
      return false;
    }

    if (reg != null && identical(_container[T], reg)) {
      _container.remove(T);
    }

    if (dispose) {
      if (reg != null) {
        await reg.dispose();
      }
      if (multiList != null) {
        for (final r in multiList) {
          if (!identical(r, reg)) {
            await r.dispose();
          }
        }
      }
    }
    return true;
  }

  @override
  Iterable<Object> get registeredKeys {
    if (_isDisposed) {
      return const [];
    }

    final keys = <Object>{..._container.keys};
    if (_multiContainer case final multiContainer?) {
      keys.addAll(multiContainer.keys);
    }
    if (_parent case final parent?) {
      keys.addAll(parent.registeredKeys);
    }
    return keys;
  }

  @override
  int get length => _container.length;

  @override
  T get<T extends Object>({Object? args, Object? key}) {
    if (_isDisposed) {
      throw StateError(
        'Cannot resolve dependency from a disposed DependencyBox.',
      );
    }

    final id = BoxDependency.from<T>(key);
    if (_container[id] case final registration?) {
      return registration.resolve(this, (_) {}, args) as T;
    }
    if (_parent case final parent?) {
      return parent.get<T>(args: args, key: key);
    }
    throw StateError(
      'No registration found for type $T${key != null ? ' with key "$key"' : ''}',
    );
  }

  @override
  Future<T> getAsync<T extends Object>({Object? args, Object? key}) async {
    if (_isDisposed) {
      throw StateError(
        'Cannot resolve dependency from a disposed DependencyBox.',
      );
    }

    final id = BoxDependency.from<T>(key);
    if (_container[id] case final registration?) {
      final instance = await registration.resolveAsync(this, (_) {}, args);
      return instance as T;
    }
    if (_parent case final parent?) {
      return parent.getAsync<T>(args: args, key: key);
    }

    throw StateError(
      'No registration found for type $T${key != null ? ' with key "$key"' : ''}',
    );
  }

  @override
  T? tryGet<T extends Object>({Object? args, Object? key}) {
    if (_isDisposed) {
      return null;
    }

    final id = BoxDependency.from<T>(key);
    if (_container[id] case final registration?) {
      return registration.resolve(this, (_) {}, args) as T;
    }
    if (_parent case final parent?) {
      return parent.tryGet<T>(args: args, key: key);
    }
    return null;
  }

  @override
  Future<T?> tryGetAsync<T extends Object>({Object? args, Object? key}) async {
    if (_isDisposed) {
      return null;
    }

    final id = BoxDependency.from<T>(key);
    if (_container[id] case final registration?) {
      final instance = await registration.resolveAsync(this, (_) {}, args);
      return instance as T;
    }
    if (_parent case final parent?) {
      return parent.tryGetAsync<T>(args: args, key: key);
    }

    return null;
  }

  @override
  List<T> getAll<T extends Object>({Object? args, Object? key}) {
    if (_isDisposed) {
      return const [];
    }

    final id = BoxDependency.from<T>(key);
    final local = <T>[];
    if (_multiContainer?[id] case final list?) {
      for (final r in list) {
        local.add(r.resolve(this, (_) {}, args) as T);
      }
    } else if (_container[id] case final registration?) {
      local.add(registration.resolve(this, (_) {}, args) as T);
    }

    if (_parent case final parent?) {
      final parentList = parent.getAll<T>(args: args, key: key);
      if (local.isEmpty) {
        return parentList;
      }
      return [...parentList, ...local];
    }
    return local;
  }

  @override
  Future<List<T>> getAllAsync<T extends Object>({
    Object? args,
    Object? key,
  }) async {
    if (_isDisposed) {
      return const [];
    }

    final id = BoxDependency.from<T>(key);
    final local = <T>[];
    if (_multiContainer?[id] case final list?) {
      for (final r in list) {
        final instance = await r.resolveAsync(this, (_) {}, args);
        local.add(instance as T);
      }
    } else if (_container[id] case final registration?) {
      final instance = await registration.resolveAsync(this, (_) {}, args);
      local.add(instance as T);
    }

    if (_parent case final parent?) {
      final parentList = await parent.getAllAsync<T>(args: args, key: key);
      if (local.isEmpty) {
        return parentList;
      }
      return [...parentList, ...local];
    }
    return local;
  }

  @override
  bool contains<T extends Object>({Object? key}) {
    if (_isDisposed) {
      return false;
    }

    final id = BoxDependency.from<T>(key);
    final existsLocally = _container.containsKey(id) ||
        (_multiContainer?.containsKey(id) ?? false);
    if (existsLocally) {
      return true;
    }
    return _parent?.contains<T>(key: key) ?? false;
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;

    final toDispose = <DependencyBoxRegistration>{};
    for (final reg in _container.values) {
      toDispose.add(reg);
    }

    if (_multiContainer case final multiContainer?) {
      for (final list in multiContainer.values) {
        for (final reg in list) {
          toDispose.add(reg);
        }
      }
    }

    Object? firstError;
    StackTrace? firstStackTrace;

    final disposedInstances = Set<Object>.identity();
    for (final reg in toDispose) {
      final inst = reg.currentInstance;
      if (inst != null && !disposedInstances.add(inst)) {
        continue;
      }
      try {
        await reg.dispose();
      } catch (e, st) {
        firstError ??= e;
        firstStackTrace ??= st;
      }
    }

    _container.clear();
    _multiContainer?.clear();
    _multiTypes?.clear();

    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStackTrace!);
    }
  }
}
