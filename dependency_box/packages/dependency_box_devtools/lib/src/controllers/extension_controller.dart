import 'dart:async';

import 'package:dependency_box/devtools.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:vm_service/vm_service.dart' hide Event;

/// Refresh intervals available for optional auto-refresh.
enum AutoRefreshInterval {
  off(0, 'Off'),
  fast(3, '3 seconds'),
  normal(5, '5 seconds'),
  relaxed(10, '10 seconds');

  final int seconds;
  final String label;
  const AutoRefreshInterval(this.seconds, this.label);
}

/// Active navigation tab in the extension UI.
enum ExtensionTab {
  registrations('Registrations'),
  scopes('Scopes'),
  graph('Dependency Graph'),
  diagnostics('Diagnostics');

  final String label;
  const ExtensionTab(this.label);
}

/// Central state controller for the dependency_box DevTools extension.
class ExtensionController extends ChangeNotifier {
  ExtensionController() {
    _init();
  }

  bool _isLoading = false;
  String? _errorMessage;
  ContainerSnapshot? _snapshot;
  ExtensionTab _currentTab = ExtensionTab.registrations;

  // Search & Filter state
  String _searchQuery = '';
  String? _selectedScopeFilter;
  String? _selectedLifetimeFilter;
  bool? _isCreatedFilter;

  // Selection state
  RegistrationSnapshot? _selectedRegistration;
  ScopeSnapshot? _selectedScope;

  // Auto-refresh state
  AutoRefreshInterval _autoRefreshInterval = AutoRefreshInterval.off;
  Timer? _autoRefreshTimer;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ContainerSnapshot? get snapshot => _snapshot;
  ExtensionTab get currentTab => _currentTab;

  String get searchQuery => _searchQuery;
  String? get selectedScopeFilter => _selectedScopeFilter;
  String? get selectedLifetimeFilter => _selectedLifetimeFilter;
  bool? get isCreatedFilter => _isCreatedFilter;

  RegistrationSnapshot? get selectedRegistration => _selectedRegistration;
  ScopeSnapshot? get selectedScope => _selectedScope;
  AutoRefreshInterval get autoRefreshInterval => _autoRefreshInterval;

  void _init() {
    // Initial fetch
    fetchSnapshot();
  }

  void selectTab(ExtensionTab tab) {
    if (_currentTab != tab) {
      _currentTab = tab;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setScopeFilter(String? scopeId) {
    _selectedScopeFilter = scopeId;
    notifyListeners();
  }

  void setLifetimeFilter(String? lifetime) {
    _selectedLifetimeFilter = lifetime;
    notifyListeners();
  }

  void setIsCreatedFilter(bool? isCreated) {
    _isCreatedFilter = isCreated;
    notifyListeners();
  }

  void selectRegistration(RegistrationSnapshot? registration) {
    _selectedRegistration = registration;
    notifyListeners();
  }

  void selectScope(ScopeSnapshot? scope) {
    _selectedScope = scope;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedScopeFilter = null;
    _selectedLifetimeFilter = null;
    _isCreatedFilter = null;
    notifyListeners();
  }

  void setAutoRefreshInterval(AutoRefreshInterval interval) {
    if (_autoRefreshInterval == interval) return;
    _autoRefreshInterval = interval;
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;

    if (interval.seconds > 0) {
      _autoRefreshTimer = Timer.periodic(
        Duration(seconds: interval.seconds),
        (_) => fetchSnapshot(silent: true),
      );
    }
    notifyListeners();
  }

  /// Fetches a fresh point-in-time snapshot from the connected application.
  Future<void> fetchSnapshot({bool silent = false}) async {
    if (_isLoading && !silent) return;

    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final VmService? service = serviceManager.service;
      if (service == null) {
        // DevTools is not connected to a running VM service
        _handleDisconnectedState();
        return;
      }

      final isolate = serviceManager.isolateManager.selectedIsolate.value;
      final isolateId = isolate?.id;

      if (isolateId == null) {
        _errorMessage = 'No active isolate selected in DevTools.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      Response response;
      try {
        response = await service.callServiceExtension(
          DependencyBoxDevTools.getSnapshotMethod,
          isolateId: isolateId,
        );
      } catch (_) {
        // Fallback to snake_case alias
        response = await service.callServiceExtension(
          DependencyBoxDevTools.getSnapshotAlias,
          isolateId: isolateId,
        );
      }

      final jsonMap = response.json;
      if (jsonMap == null) {
        throw StateError('Service extension returned empty response.');
      }

      if (jsonMap['status'] == 'empty') {
        _errorMessage =
            jsonMap['message'] as String? ??
            'No DependencyBox instances registered for inspection.\n'
                'Call DependencyBoxDevTools.register(box) in your application to enable inspection.';
        _snapshot = null;
      } else {
        _snapshot = ContainerSnapshot.fromJson(jsonMap);
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage =
          'Failed to inspect DependencyBox: $e\n\n'
          'Ensure your application has called DependencyBoxDevTools.register(box).';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleDisconnectedState() {
    // If running in development / disconnected demo mode, construct a sample snapshot
    _errorMessage =
        'DevTools is not connected to a running Dart/Flutter application.\n'
        'Run your app with debugging enabled and connect Flutter DevTools.';
    _isLoading = false;
    notifyListeners();
  }

  /// Filtered list of registrations matching current search and filter settings.
  List<RegistrationSnapshot> get filteredRegistrations {
    final list = _snapshot?.registrations ?? [];
    if (list.isEmpty) return const [];

    return list.where((r) {
      if (_searchQuery.isNotEmpty) {
        final matchesType = r.typeName.toLowerCase().contains(_searchQuery);
        final matchesKey = r.key?.toLowerCase().contains(_searchQuery) ?? false;
        final matchesScope = r.scopeName.toLowerCase().contains(_searchQuery);
        if (!matchesType && !matchesKey && !matchesScope) return false;
      }

      if (_selectedScopeFilter != null && r.scopeId != _selectedScopeFilter) {
        return false;
      }

      if (_selectedLifetimeFilter != null &&
          r.lifetime != _selectedLifetimeFilter) {
        return false;
      }

      if (_isCreatedFilter != null && r.isCreated != _isCreatedFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
