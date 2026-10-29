import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import '../dependency_box.dart';
import '../inspection/container_inspector.dart';
import '../inspection/inspection_models.dart';

/// Service extension handler callback signature for testing without Dart VM service.
typedef ServiceExtensionCallback =
    Future<developer.ServiceExtensionResponse> Function(
      String method,
      Map<String, String> parameters,
    );

/// Optional runtime integration that exposes [DependencyBox] inspection data
/// via Dart VM Service extensions.
///
/// This integration is 100% opt-in. When not enabled, no service extensions are
/// registered, no timers or listeners are allocated, and zero overhead is incurred.
abstract final class DependencyBoxDevTools {
  /// The primary VM service extension method for retrieving a full container snapshot.
  static const getSnapshotMethod = 'ext.dependencyBox.getSnapshot';

  /// Snake_case alias for [getSnapshotMethod].
  static const getSnapshotAlias = 'ext.dependency_box.getSnapshot';

  /// VM service extension method for retrieving registered scopes only.
  static const getScopesMethod = 'ext.dependencyBox.getScopes';

  /// VM service extension method for retrieving registrations only.
  static const getRegistrationsMethod = 'ext.dependencyBox.getRegistrations';

  /// VM service extension method for pinging the inspection service.
  static const pingMethod = 'ext.dependencyBox.ping';

  /// Active container references stored as weak references to prevent memory retention.
  static final List<WeakReference<DependencyBox>> _trackedContainers = [];

  /// Registered extension methods.
  static final Set<String> _registeredMethods = {};

  /// Custom handler override (useful for unit tests without a real VM service).
  static final Map<String, ServiceExtensionCallback> _mockHandlers = {};

  /// Whether the DevTools inspection service is currently enabled.
  static bool get isEnabled {
    return _registeredMethods.isNotEmpty || _mockHandlers.isNotEmpty;
  }

  /// Returns the number of currently tracked living containers.
  static int get activeContainerCount {
    _pruneDeadReferences();
    return _trackedContainers.length;
  }

  /// Enables DevTools inspection and registers the specified [box].
  ///
  /// If [box] is provided, it is added to the list of inspected containers.
  /// If no container is provided, service extensions are registered and await
  /// future container registrations via [register].
  static void enable([DependencyBox? box]) {
    _ensureServiceExtensionsRegistered();
    if (box != null) {
      register(box);
    }
  }

  /// Registers [box] for DevTools inspection.
  ///
  /// The container is held via a [WeakReference] so this registration will not
  /// prevent the container from being garbage-collected.
  static void register(DependencyBox box) {
    _ensureServiceExtensionsRegistered();
    _pruneDeadReferences();

    for (final ref in _trackedContainers) {
      final target = ref.target;
      if (target != null && identical(target, box)) {
        return; // Already registered
      }
    }

    _trackedContainers.add(WeakReference(box));
  }

  /// Unregisters [box] from DevTools inspection.
  static void unregister(DependencyBox box) {
    _trackedContainers.removeWhere((ref) {
      final target = ref.target;
      return target == null || identical(target, box);
    });
  }

  /// Disables DevTools inspection and clears all tracked container references.
  static void disable() {
    _trackedContainers.clear();
    _registeredMethods.clear();
    _mockHandlers.clear();
  }

  /// Manually dispatches a service extension call (useful for unit testing and direct invocation).
  static Future<developer.ServiceExtensionResponse> handleServiceCall(
    String method,
    Map<String, String> parameters,
  ) {
    return _dispatchExtensionCall(method, parameters);
  }

  static void _ensureServiceExtensionsRegistered() {
    final methods = [
      getSnapshotMethod,
      getSnapshotAlias,
      getScopesMethod,
      getRegistrationsMethod,
      pingMethod,
    ];

    for (final method in methods) {
      if (_registeredMethods.contains(method)) continue;

      try {
        developer.registerExtension(method, (method, params) {
          return _dispatchExtensionCall(method, params);
        });
        _registeredMethods.add(method);
      } catch (_) {
        // Fallback for environments where registerExtension is not available or duplicate
        _mockHandlers[method] = (m, p) => _dispatchExtensionCall(m, p);
      }
    }
  }

  static Future<developer.ServiceExtensionResponse> _dispatchExtensionCall(
    String method,
    Map<String, String> parameters,
  ) async {
    try {
      _pruneDeadReferences();

      switch (method) {
        case pingMethod:
          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'status': 'ok',
              'version': '1.0.0',
              'containerCount': _trackedContainers.length,
            }),
          );

        case getScopesMethod:
          final snapshot = _getPrimarySnapshot();
          if (snapshot == null) {
            return _emptyResponse();
          }
          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'timestamp': snapshot.timestamp.toIso8601String(),
              'scopes': snapshot.scopes.map((s) => s.toJson()).toList(),
            }),
          );

        case getRegistrationsMethod:
          final snapshot = _getPrimarySnapshot();
          if (snapshot == null) {
            return _emptyResponse();
          }
          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'timestamp': snapshot.timestamp.toIso8601String(),
              'registrations': snapshot.registrations
                  .map((r) => r.toJson())
                  .toList(),
            }),
          );

        case getSnapshotMethod:
        case getSnapshotAlias:
        default:
          final snapshot = _getPrimarySnapshot();
          if (snapshot == null) {
            return _emptyResponse();
          }
          return developer.ServiceExtensionResponse.result(
            snapshot.toJsonString(),
          );
      }
    } catch (error, stackTrace) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.extensionError,
        jsonEncode({
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        }),
      );
    }
  }

  static ContainerSnapshot? _getPrimarySnapshot() {
    _pruneDeadReferences();
    if (_trackedContainers.isEmpty) {
      return null;
    }

    final box = _trackedContainers.first.target;
    if (box == null) {
      return null;
    }

    return ContainerInspector.capture(box);
  }

  static developer.ServiceExtensionResponse _emptyResponse() {
    return developer.ServiceExtensionResponse.result(
      jsonEncode({
        'status': 'empty',
        'message': 'No DependencyBox containers currently registered for DevTools inspection.',
        'timestamp': DateTime.now().toIso8601String(),
        'rootScope': ScopeSnapshot.empty.toJson(),
        'scopes': <dynamic>[],
        'registrations': <dynamic>[],
        'diagnostics': [
          {
            'severity': 'info',
            'title': 'No Active Containers',
            'message': 'No DependencyBox instances are currently registered with DependencyBoxDevTools.register(box).',
          },
        ],
        'stats': {
          'totalRegistrations': 0,
          'totalInstantiated': 0,
          'scopeCount': 0,
        },
      }),
    );
  }

  static void _pruneDeadReferences() {
    _trackedContainers.removeWhere((ref) => ref.target == null);
  }
}
