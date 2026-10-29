import '../dependency_box.dart';
import '../dependency_box_impl.dart';
import '../dependency_ref.dart';
import '../registration.dart';
import 'inspection_models.dart';

/// Pure read-only inspector for [DependencyBox] container hierarchies.
///
/// This inspector operates completely on-demand and does not allocate tracking
/// structures, subscribe to streams, or invoke dependency factories.
abstract final class ContainerInspector {
  /// Captures a complete point-in-time [ContainerSnapshot] of the container hierarchy
  /// starting from the root of [box].
  ///
  /// Set [fromRoot] to `false` to capture only the subtree starting from [box].
  static ContainerSnapshot capture(DependencyBox box, {bool fromRoot = true}) {
    final startBox = fromRoot
        ? (box.root as DependencyBoxImpl)
        : (box as DependencyBoxImpl);

    final scopes = <ScopeSnapshot>[];
    final registrations = <RegistrationSnapshot>[];
    final diagnostics = <DiagnosticNotice>[];

    final visitedBoxes = <DependencyBoxImpl>{};
    final queue = <DependencyBoxImpl>[startBox];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (!visitedBoxes.add(current)) continue;

      final scopeId = _scopeId(current);
      final parentId = current.parent != null
          ? _scopeId(current.parent! as DependencyBoxImpl)
          : null;

      final childrenList = current.children.cast<DependencyBoxImpl>().toList();
      final childIds = childrenList.map(_scopeId).toList();
      queue.addAll(childrenList);

      final scopeSnapshot = ScopeSnapshot(
        id: scopeId,
        name: current.name ?? (current.parent == null ? 'root' : '<unnamed>'),
        depth: current.depth,
        isRoot: current.parent == null,
        isDisposed: current.isDisposed,
        parentId: parentId,
        childIds: childIds,
        directRegistrationCount: current.length,
      );
      scopes.add(scopeSnapshot);

      if (current.isDisposed) {
        diagnostics.add(
          DiagnosticNotice(
            severity: 'warning',
            title: 'Disposed Scope',
            message:
                'Scope "$scopeId" (${scopeSnapshot.name}) is disposed and cannot resolve dependencies.',
            relatedScope: scopeId,
          ),
        );
        continue;
      }

      // Inspect registrations inside this scope
      _inspectScopeRegistrations(
        current,
        scopeId,
        scopeSnapshot.name,
        current.depth,
        registrations,
        diagnostics,
      );
    }

    final rootScopeSnapshot = scopes.firstWhere(
      (s) => s.isRoot,
      orElse: () => scopes.isNotEmpty ? scopes.first : ScopeSnapshot.empty,
    );

    return ContainerSnapshot(
      timestamp: DateTime.now(),
      rootScope: rootScopeSnapshot,
      scopes: scopes,
      registrations: registrations,
      diagnostics: diagnostics,
    );
  }

  static void _inspectScopeRegistrations(
    DependencyBoxImpl box,
    String scopeId,
    String scopeName,
    int scopeDepth,
    List<RegistrationSnapshot> registrations,
    List<DiagnosticNotice> diagnostics,
  ) {
    final directSingles = <Object, DependencyBoxRegistration>{};
    final containerMap = box.inspectDirectContainer();
    final multiContainerMap = box.inspectMultiContainer();

    for (final entry in containerMap.entries) {
      if (multiContainerMap == null ||
          !multiContainerMap.containsKey(entry.key)) {
        directSingles[entry.key] = entry.value;
      }
    }

    // 1. Single registrations
    for (final entry in directSingles.entries) {
      final id = entry.key;
      final reg = entry.value;
      final (type: targetType, key: regKey) = _extractId(id);
      final keyString = regKey?.toString();
      final typeString = targetType.toString();

      final isShadowed =
          box.parent != null && box.parent!.registeredKeys.contains(id);

      if (isShadowed) {
        diagnostics.add(
          DiagnosticNotice(
            severity: 'info',
            title: 'Shadowed Registration',
            message:
                'Type "$typeString"${keyString != null ? ' with key "$keyString"' : ''} in scope "$scopeName" shadows an ancestor registration.',
            relatedType: typeString,
            relatedScope: scopeId,
          ),
        );
      }

      final currentInst = reg.currentInstance;
      final isCreated = currentInst != null;
      final instanceType = isCreated
          ? currentInst.runtimeType.toString()
          : null;

      registrations.add(
        RegistrationSnapshot(
          id: '${scopeId}_${_formatId(id)}',
          typeName: typeString,
          key: keyString,
          lifetime: reg.kind,
          paramType: reg.paramType != Never && reg.paramType != dynamic
              ? reg.paramType.toString()
              : null,
          scopeId: scopeId,
          scopeName: scopeName,
          scopeDepth: scopeDepth,
          isCreated: isCreated,
          isResolving: reg.isResolving,
          isShadowed: isShadowed,
          instanceRuntimeType: instanceType,
        ),
      );
    }

    // 2. Multi registrations
    if (multiContainerMap != null) {
      for (final entry in multiContainerMap.entries) {
        final id = entry.key;
        final list = entry.value;
        if (list.isEmpty) continue;

        final (type: targetType, key: regKey) = _extractId(id);
        final keyString = regKey?.toString();
        final typeString = targetType.toString();
        final resolution = box.inspectMultiResolution(targetType);
        final resolutionString = resolution?.toString() ?? 'default';

        final isShadowed =
            box.parent != null && box.parent!.registeredKeys.contains(id);

        for (var i = 0; i < list.length; i++) {
          final reg = list[i];
          final currentInst = reg.currentInstance;
          final isCreated = currentInst != null;
          final instanceType = isCreated
              ? currentInst.runtimeType.toString()
              : null;

          registrations.add(
            RegistrationSnapshot(
              id: '${scopeId}_${_formatId(id)}_#$i',
              typeName: typeString,
              key: keyString,
              lifetime: reg.kind,
              paramType: reg.paramType != Never && reg.paramType != dynamic
                  ? reg.paramType.toString()
                  : null,
              scopeId: scopeId,
              scopeName: scopeName,
              scopeDepth: scopeDepth,
              isCreated: isCreated,
              isResolving: reg.isResolving,
              isShadowed: isShadowed,
              isMulti: true,
              multiResolution: resolutionString,
              multiIndex: i,
              multiTotal: list.length,
              instanceRuntimeType: instanceType,
            ),
          );
        }
      }
    }
  }

  static String _scopeId(DependencyBoxImpl box) {
    final name = box.name ?? (box.parent == null ? 'root' : 'unnamed');
    return '${name}_${identityHashCode(box)}';
  }

  static ({Type type, Object? key}) _extractId(Object id) => switch (id) {
    BoxDependencyRef(:final type, :final key) => (type: type, key: key),
    Type type => (type: type, key: null),
    _ => (type: id.runtimeType, key: null),
  };

  static String _formatId(Object id) => switch (_extractId(id)) {
    (type: final type, key: final Object key) =>
      '${type}_key_${key is String ? key : key.toString()}',
    (type: final type, key: null) => '$type',
  };
}
