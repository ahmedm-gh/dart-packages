import 'dart:async';

import 'box_config.dart';
import 'dependency_box.dart';
import 'dependency_ref.dart';
import 'multi_registration.dart';
import 'registration.dart';

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
  DependencyBoxImpl get root {
    var current = this;
    while (current._parent != null) {
      current = current._parent!;
    }
    return current;
  }

  @override
  DependencyBox createChild({String? name}) {
    if (DependencyBoxConfig.isDebug && _isDisposed) {
      DependencyBox.throwError(
        'Cannot create a child scope from a disposed DependencyBox.',
        DependencyBoxError.disposed,
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
  void allowMultiple(Iterable<MultiRegistration> types) {
    if (DependencyBoxConfig.isDebug && _isDisposed) {
      DependencyBox.throwError(
        'Cannot configure multi-registration on a disposed DependencyBox.',
        DependencyBoxError.disposed,
      );
    }
    final multiTypes = _multiTypes ??= {};
    for (final multi in types) {
      multiTypes[multi.type] = multi.resolution;
    }
  }

  @override
  void allowMulti<T extends Object>({
    MultiResolution resolution = DependencyBoxConfig.defaultMultiResolution,
  }) {
    if (DependencyBoxConfig.isDebug && _isDisposed) {
      DependencyBox.throwError(
        'Cannot configure multi-registration on a disposed DependencyBox.',
        DependencyBoxError.disposed,
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
    if (DependencyBoxConfig.isDebug && _isDisposed) {
      DependencyBox.throwError(
        'Cannot register dependencies on a disposed DependencyBox.',
        DependencyBoxError.disposed,
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

    if (DependencyBoxConfig.isDebug && _container.containsKey(id)) {
      DependencyBox.throwError(
        'A dependency with id "$id" ($T) is already registered. '
        'To allow multiple instances for this type, enable it via allowMultiple({MultiRegistration<$T>()}).',
        DependencyBoxError.duplicateRegistration,
      );
    }
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
      BoxDependencyRef.from<T>(key),
      DependencyBoxRegistration<T, Never>.singleton(
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
    if (DependencyBoxConfig.isDebug && _findMultiResolution(T) == null) {
      DependencyBox.throwError(
        'Cannot call addSingletons for type $T without enabling it first via allowMultiple({MultiRegistration<$T>()}).',
        DependencyBoxError.multiNotAllowed,
      );
    }
    final id = BoxDependencyRef.from<T>(key);
    for (final instance in instances) {
      _register<T>(
        id,
        DependencyBoxRegistration<T, Never>.singleton(instance),
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
      BoxDependencyRef.from<T>(key),
      DependencyBoxRegistration<T, Never>.lazySingleton(
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
      BoxDependencyRef.from<T>(key),
      DependencyBoxRegistration<T, Never>.factory(factory),
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
    final id = BoxDependencyRef.from<T>(key);
    _register<T>(
      id,
      DependencyBoxRegistration<T, Never>.asyncSingleton(
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
      BoxDependencyRef.from<T>(key),
      DependencyBoxRegistration<T, A>.factoryWith(factory),
      key: key,
    );
  }

  @override
  void addCachedFactory<T extends Object>(
    T Function(DependencyBox container) factory, {
    Object? key,
    FutureOr<void> Function(T instance)? onDispose,
  }) {
    _register<T>(
      BoxDependencyRef.from<T>(key),
      DependencyBoxRegistration<T, Never>.cachedFactory(
        factory,
        onDispose: onDispose,
      ),
      key: key,
    );
  }

  @override
  void addSharedSingleton<T extends Object>(
    T instance, {
    Object? key,
    FutureOr<void> Function(T instance)? onDispose,
  }) {
    if (DependencyBoxConfig.isDebug && _isDisposed) {
      DependencyBox.throwError(
        'Cannot register dependencies on a disposed DependencyBox.',
        DependencyBoxError.disposed,
      );
    }
    root.addSingleton<T>(instance, key: key, onDispose: onDispose);
  }

  @override
  void addSharedLazySingleton<T extends Object>(
    T Function(DependencyBox container) factory, {
    Object? key,
    FutureOr<void> Function(T instance)? onDispose,
  }) {
    if (DependencyBoxConfig.isDebug && _isDisposed) {
      DependencyBox.throwError(
        'Cannot register dependencies on a disposed DependencyBox.',
        DependencyBoxError.disposed,
      );
    }
    root.addLazySingleton<T>(factory, key: key, onDispose: onDispose);
  }

  @override
  void addSharedCachedFactory<T extends Object>(
    T Function(DependencyBox container) factory, {
    Object? key,
    FutureOr<void> Function(T instance)? onDispose,
  }) {
    if (DependencyBoxConfig.isDebug && _isDisposed) {
      DependencyBox.throwError(
        'Cannot register dependencies on a disposed DependencyBox.',
        DependencyBoxError.disposed,
      );
    }
    root.addCachedFactory<T>(factory, key: key, onDispose: onDispose);
  }

  @override
  void replaceSingleton<T extends Object>(
    T instance, {
    Object? key,
    bool disposeOld = DependencyBoxConfig.defaultDisposeOldOnReplace,
    FutureOr<void> Function(T instance)? onDispose,
  }) {
    if (DependencyBoxConfig.isDebug && _isDisposed) {
      DependencyBox.throwError(
        'Cannot register dependencies on a disposed DependencyBox.',
        DependencyBoxError.disposed,
      );
    }
    final id = BoxDependencyRef.from<T>(key);
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
    _container[id] = DependencyBoxRegistration<T, Never>.singleton(
      instance,
      onDispose: onDispose,
    );
  }

  @override
  Future<bool> remove<T extends Object>({
    Object? key,
    bool dispose = DependencyBoxConfig.defaultDisposeOnRemove,
  }) async {
    final id = BoxDependencyRef.from<T>(key);
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
  Iterable<Object> get registeredKeys => switch (_isDisposed) {
        true => const [],
        false => <Object>{
            ..._container.keys,
            if (_multiContainer case final multiContainer?)
              ...multiContainer.keys,
            if (_parent case final parent?) ...parent.registeredKeys,
          },
      };

  @override
  int get length => _container.length;

  @override
  T get<T extends Object>({Object? args, Object? key}) {
    if (DependencyBoxConfig.isDebug && _isDisposed) {
      DependencyBox.throwError(
        'Cannot resolve dependency from a disposed DependencyBox.',
        DependencyBoxError.disposed,
      );
    }

    final id = BoxDependencyRef.from<T>(key);
    if (_container[id] case final registration?) {
      return registration.resolve(this, (_) {}, args) as T;
    }
    if (_parent case final parent?) {
      return parent.get<T>(args: args, key: key);
    }
    return DependencyBox.throwError(
      'No registration found for type $T${key != null ? ' with key "$key"' : ''}',
      DependencyBoxError.notFound,
    );
  }

  @override
  Future<T> getAsync<T extends Object>({Object? args, Object? key}) async {
    if (DependencyBoxConfig.isDebug && _isDisposed) {
      DependencyBox.throwError(
        'Cannot resolve dependency from a disposed DependencyBox.',
        DependencyBoxError.disposed,
      );
    }

    final id = BoxDependencyRef.from<T>(key);
    if (_container[id] case final registration?) {
      final instance = await registration.resolveAsync(this, (_) {}, args);
      return instance as T;
    }
    if (_parent case final parent?) {
      return parent.getAsync<T>(args: args, key: key);
    }

    return DependencyBox.throwError(
      'No registration found for type $T${key != null ? ' with key "$key"' : ''}',
      DependencyBoxError.notFound,
    );
  }

  @override
  T? tryGet<T extends Object>({Object? args, Object? key}) {
    if (_isDisposed) {
      return null;
    }

    final id = BoxDependencyRef.from<T>(key);
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

    final id = BoxDependencyRef.from<T>(key);
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

    final id = BoxDependencyRef.from<T>(key);
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

    final id = BoxDependencyRef.from<T>(key);
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

    final id = BoxDependencyRef.from<T>(key);
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

    final toDispose = <DependencyBoxRegistration>{
      ..._container.values,
      if (_multiContainer case final multiContainer?)
        for (final list in multiContainer.values) ...list,
    };

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

  @override
  String printContainer({
    void Function(Object? object)? printer,
    bool includeParent = true,
  }) {
    final buffer = StringBuffer();
    final boxName = _name != null ? "'$_name'" : '<unnamed>';
    final status = _isDisposed ? 'disposed' : 'active';
    buffer.writeln('DependencyBox: $boxName [$status]');

    final hierarchy = _formatHierarchy();

    if (_isDisposed) {
      buffer.writeln('├── Hierarchy: $hierarchy (disposed)');
      buffer.writeln('└── (empty - container disposed)');
      final result = buffer.toString().trimRight();
      (printer ?? print)(result);
      return result;
    }

    final directSingles = <Object, DependencyBoxRegistration>{};
    for (final entry in _container.entries) {
      if (_multiContainer == null || !_multiContainer!.containsKey(entry.key)) {
        directSingles[entry.key] = entry.value;
      }
    }

    final directMultis = <Object, List<DependencyBoxRegistration>>{};
    if (_multiContainer case final multiContainer?) {
      for (final entry in multiContainer.entries) {
        if (entry.value.isNotEmpty) {
          directMultis[entry.key] = entry.value;
        }
      }
    }

    final inheritedEntries = <_InheritedEntry>[];
    if (includeParent && _parent != null) {
      final seenKeys = <Object>{
        ..._container.keys,
        ...?_multiContainer?.keys,
      };
      final inheritedKeys = <Object>{};

      var current = _parent;
      while (current != null) {
        final parentScope =
            current._name != null ? "'${current._name}'" : '<unnamed>';

        for (final entry in current._container.entries) {
          if (current._multiContainer == null ||
              !current._multiContainer!.containsKey(entry.key)) {
            if (inheritedKeys.add(entry.key)) {
              inheritedEntries.add(
                _InheritedEntry(
                  id: entry.key,
                  sourceScope: parentScope,
                  singleReg: entry.value,
                  isShadowed: seenKeys.contains(entry.key),
                ),
              );
            }
          }
        }

        if (current._multiContainer case final pMulti?) {
          for (final entry in pMulti.entries) {
            if (entry.value.isNotEmpty && inheritedKeys.add(entry.key)) {
              inheritedEntries.add(
                _InheritedEntry(
                  id: entry.key,
                  sourceScope: parentScope,
                  multiList: entry.value,
                  multiResolution:
                      current._findMultiResolution(_typeFromId(entry.key)),
                  isShadowed: seenKeys.contains(entry.key),
                ),
              );
            }
          }
        }

        current = current._parent;
      }
    }

    final sections = <_DiagnosticSection>[];
    sections.add(_DiagnosticSection(title: 'Hierarchy: $hierarchy'));

    if (directSingles.isEmpty &&
        directMultis.isEmpty &&
        inheritedEntries.isEmpty) {
      sections.add(const _DiagnosticSection(title: '(empty)'));
    } else {
      if (directSingles.isNotEmpty) {
        final lines = <_DiagnosticLine>[];
        for (final entry in directSingles.entries) {
          final idLabel = _formatId(entry.key);
          final regDetails = _formatRegistration(entry.value);
          lines.add(_DiagnosticLine('$idLabel -> $regDetails'));
        }
        sections.add(
          _DiagnosticSection(
            title: 'Direct Registrations (${directSingles.length}):',
            lines: lines,
          ),
        );
      }

      if (directMultis.isNotEmpty) {
        final lines = <_DiagnosticLine>[];
        for (final entry in directMultis.entries) {
          final idLabel = _formatId(entry.key);
          final list = entry.value;
          final type = _typeFromId(entry.key);
          final resolution = _findMultiResolution(type);
          final resLabel = resolution?.toString() ?? 'default';
          final subLines = <String>[];
          for (var i = 0; i < list.length; i++) {
            final reg = list[i];
            final isActive = identical(_container[entry.key], reg);
            final itemDetails =
                _formatRegistration(reg, isActiveInMulti: isActive);
            subLines.add('[$i] $itemDetails');
          }
          lines.add(
            _DiagnosticLine(
              '$idLabel (strategy: $resLabel, ${list.length} ${list.length == 1 ? 'item' : 'items'}):',
              subLines: subLines,
            ),
          );
        }
        sections.add(
          _DiagnosticSection(
            title: 'Multi Registrations (${directMultis.length}):',
            lines: lines,
          ),
        );
      }

      if (inheritedEntries.isNotEmpty) {
        final lines = <_DiagnosticLine>[];
        for (final entry in inheritedEntries) {
          final idLabel = _formatId(entry.id);
          if (entry.isShadowed) {
            final kind = entry.singleReg?.kind ??
                'Multi(${entry.multiList?.length ?? 0} items)';
            lines.add(
              _DiagnosticLine(
                '$idLabel -> $kind (from ${entry.sourceScope}) [shadowed by child]',
              ),
            );
          } else if (entry.singleReg case final singleReg?) {
            final regDetails = _formatRegistration(singleReg);
            lines.add(
              _DiagnosticLine(
                '$idLabel -> $regDetails (from ${entry.sourceScope})',
              ),
            );
          } else if (entry.multiList case final multiList?) {
            final resLabel = entry.multiResolution?.toString() ?? 'default';
            lines.add(
              _DiagnosticLine(
                '$idLabel (strategy: $resLabel, ${multiList.length} items) (from ${entry.sourceScope})',
              ),
            );
          }
        }
        sections.add(
          _DiagnosticSection(
            title: 'Inherited Registrations (${inheritedEntries.length}):',
            lines: lines,
          ),
        );
      }
    }

    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      final isLastSection = i == sections.length - 1;
      final sectionPrefix = isLastSection ? '└── ' : '├── ';
      final childIndent = isLastSection ? '    ' : '│   ';

      buffer.writeln('$sectionPrefix${section.title}');

      for (var j = 0; j < section.lines.length; j++) {
        final line = section.lines[j];
        final isLastLine = j == section.lines.length - 1;
        final linePrefix = isLastLine ? '└── ' : '├── ';
        final subChildIndent = isLastLine ? '    ' : '│   ';

        buffer.writeln('$childIndent$linePrefix${line.text}');

        for (var k = 0; k < line.subLines.length; k++) {
          final subLine = line.subLines[k];
          final isLastSubLine = k == line.subLines.length - 1;
          final subPrefix = isLastSubLine ? '└── ' : '├── ';
          buffer.writeln('$childIndent$subChildIndent$subPrefix$subLine');
        }
      }
    }

    final result = buffer.toString().trimRight();
    (printer ?? print)(result);
    return result;
  }

  String _formatHierarchy() {
    if (_parent == null) {
      return '<root>';
    }
    final chain = <String>[_name != null ? "'$_name'" : '<unnamed>'];
    var current = _parent;
    while (current != null) {
      chain.add(current._name != null ? "'${current._name}'" : '<unnamed>');
      current = current._parent;
    }
    return chain.join(' -> ');
  }

  static ({Type type, Object? key}) _extractId(Object id) => switch (id) {
        BoxDependencyRef(:final type, :final key) => (type: type, key: key),
        Type type => (type: type, key: null),
        _ => (type: id.runtimeType, key: null),
      };

  static String _formatId(Object id) => switch (_extractId(id)) {
        (type: final type, key: final Object key) =>
          '$type (key: ${key is String ? "'$key'" : key})',
        (type: final type, key: null) => '$type',
      };

  static Type _typeFromId(Object id) => _extractId(id).type;

  static String _formatInstance(Object? instance) => switch (instance) {
        null => 'null',
        String s => '"$s"',
        _ => _safeToString(instance),
      };

  static String _safeToString(Object instance) {
    try {
      final str = instance.toString();
      return str.contains('\n')
          ? str.replaceAll(RegExp(r'\r?\n\s*'), ' ')
          : str;
    } catch (_) {
      return '<${instance.runtimeType}: error evaluating toString()>';
    }
  }

  static String _formatRegistration(
    DependencyBoxRegistration reg, {
    bool isActiveInMulti = false,
  }) {
    final activeTag = isActiveInMulti ? ' [active]' : '';
    final details = switch (reg.kind) {
      'Singleton' =>
        'Singleton (instance: ${_formatInstance(reg.currentInstance)})',
      'LazySingleton' => switch ((reg.isResolving, reg.currentInstance)) {
          (true, _) => 'LazySingleton [resolving...]',
          (false, final inst?) =>
            'LazySingleton [initialized: ${_formatInstance(inst)}]',
          _ => 'LazySingleton [uninitialized]',
        },
      'AsyncSingleton' => switch ((reg.isResolving, reg.currentInstance)) {
          (true, _) => 'AsyncSingleton [resolving...]',
          (false, final inst?) =>
            'AsyncSingleton [initialized: ${_formatInstance(inst)}]',
          _ => 'AsyncSingleton [uninitialized]',
        },
      'CachedFactory' => switch ((reg.isResolving, reg.currentInstance)) {
          (true, _) => 'CachedFactory [resolving...]',
          (false, final inst?) =>
            'CachedFactory [cached: ${_formatInstance(inst)}]',
          _ => 'CachedFactory [uninitialized/collected]',
        },
      final otherKind => otherKind,
    };
    return '$details$activeTag';
  }
}

final class _DiagnosticSection {
  final String title;
  final List<_DiagnosticLine> lines;

  const _DiagnosticSection({
    required this.title,
    this.lines = const [],
  });
}

final class _DiagnosticLine {
  final String text;
  final List<String> subLines;

  const _DiagnosticLine(
    this.text, {
    this.subLines = const [],
  });
}

final class _InheritedEntry {
  final Object id;
  final String sourceScope;
  final DependencyBoxRegistration? singleReg;
  final List<DependencyBoxRegistration>? multiList;
  final MultiResolution? multiResolution;
  final bool isShadowed;

  const _InheritedEntry({
    required this.id,
    required this.sourceScope,
    this.singleReg,
    this.multiList,
    this.multiResolution,
    required this.isShadowed,
  });
}
