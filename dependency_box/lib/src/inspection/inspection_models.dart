import 'dart:convert';

/// Represents a point-in-time, read-only snapshot of a [DependencyBox] hierarchy.
final class ContainerSnapshot {
  /// The timestamp when this snapshot was captured.
  final DateTime timestamp;

  /// The root scope of the container hierarchy.
  final ScopeSnapshot rootScope;

  /// All scopes in the hierarchy (including root and all descendant scopes).
  final List<ScopeSnapshot> scopes;

  /// All registrations present in the hierarchy.
  final List<RegistrationSnapshot> registrations;

  /// Diagnostic warnings or notices detected during snapshot generation.
  final List<DiagnosticNotice> diagnostics;

  /// Creates a new [ContainerSnapshot].
  const ContainerSnapshot({
    required this.timestamp,
    required this.rootScope,
    required this.scopes,
    required this.registrations,
    this.diagnostics = const [],
  });

  /// The total number of unique registrations across all scopes.
  int get totalRegistrations => registrations.length;

  /// The number of registrations that have already instantiated an object.
  int get totalInstantiated => registrations.where((r) => r.isCreated).length;

  /// Serializes this snapshot into a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'rootScope': rootScope.toJson(),
    'scopes': scopes.map((s) => s.toJson()).toList(),
    'registrations': registrations.map((r) => r.toJson()).toList(),
    'diagnostics': diagnostics.map((d) => d.toJson()).toList(),
    'stats': {
      'totalRegistrations': totalRegistrations,
      'totalInstantiated': totalInstantiated,
      'scopeCount': scopes.length,
    },
  };

  /// Encodes this snapshot as a JSON string.
  String toJsonString({bool pretty = false}) {
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(toJson());
    }
    return jsonEncode(toJson());
  }

  /// Deserializes a [ContainerSnapshot] from a JSON map.
  factory ContainerSnapshot.fromJson(Map<String, dynamic> json) {
    final timestamp =
        DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now();
    final scopesList = (json['scopes'] as List<dynamic>? ?? [])
        .map((s) => ScopeSnapshot.fromJson(s as Map<String, dynamic>))
        .toList();
    final rootScope = json['rootScope'] != null
        ? ScopeSnapshot.fromJson(json['rootScope'] as Map<String, dynamic>)
        : (scopesList.isNotEmpty ? scopesList.first : ScopeSnapshot.empty);
    final registrationsList = (json['registrations'] as List<dynamic>? ?? [])
        .map((r) => RegistrationSnapshot.fromJson(r as Map<String, dynamic>))
        .toList();
    final diagnosticsList = (json['diagnostics'] as List<dynamic>? ?? [])
        .map((d) => DiagnosticNotice.fromJson(d as Map<String, dynamic>))
        .toList();

    return ContainerSnapshot(
      timestamp: timestamp,
      rootScope: rootScope,
      scopes: scopesList,
      registrations: registrationsList,
      diagnostics: diagnosticsList,
    );
  }
}

/// Represents the snapshot state of a single scope (or container level) in the hierarchy.
final class ScopeSnapshot {
  /// Unique identifier for this scope (e.g. scope memory hash or name-path).
  final String id;

  /// Human-readable name of this scope, or `"<unnamed>"`.
  final String name;

  /// 0-based depth level from root (0 = root).
  final int depth;

  /// Whether this scope is the root container.
  final bool isRoot;

  /// Whether this scope has been disposed.
  final bool isDisposed;

  /// The ID of the parent scope, or `null` if this is root.
  final String? parentId;

  /// The IDs of immediate child scopes.
  final List<String> childIds;

  /// Number of direct registrations in this scope.
  final int directRegistrationCount;

  /// Fallback empty scope.
  static const empty = ScopeSnapshot(
    id: 'empty',
    name: '<empty>',
    depth: 0,
    isRoot: true,
    isDisposed: false,
    childIds: [],
    directRegistrationCount: 0,
  );

  /// Creates a new [ScopeSnapshot].
  const ScopeSnapshot({
    required this.id,
    required this.name,
    required this.depth,
    required this.isRoot,
    required this.isDisposed,
    this.parentId,
    required this.childIds,
    required this.directRegistrationCount,
  });

  /// Serializes this scope snapshot into a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'depth': depth,
    'isRoot': isRoot,
    'isDisposed': isDisposed,
    'parentId': parentId,
    'childIds': childIds,
    'directRegistrationCount': directRegistrationCount,
  };

  /// Deserializes a [ScopeSnapshot] from a JSON map.
  factory ScopeSnapshot.fromJson(Map<String, dynamic> json) => ScopeSnapshot(
    id: json['id'] as String? ?? 'unknown',
    name: json['name'] as String? ?? '<unnamed>',
    depth: (json['depth'] as num?)?.toInt() ?? 0,
    isRoot: json['isRoot'] as bool? ?? false,
    isDisposed: json['isDisposed'] as bool? ?? false,
    parentId: json['parentId'] as String?,
    childIds: (json['childIds'] as List<dynamic>? ?? []).cast<String>(),
    directRegistrationCount:
        (json['directRegistrationCount'] as num?)?.toInt() ?? 0,
  );
}

/// Represents the snapshot state of a single dependency registration.
final class RegistrationSnapshot {
  /// Unique identifier for this registration entry.
  final String id;

  /// The registered dependency type name (e.g. 'AuthService').
  final String typeName;

  /// The optional qualifying key (e.g. 'primary' or 'v2'), or `null` if unkeyed.
  final String? key;

  /// The lifecycle kind ('Singleton', 'LazySingleton', 'CachedFactory', 'Factory', 'FactoryWith', 'AsyncSingleton').
  final String lifetime;

  /// Parameter type if parameterized factory, or `null`.
  final String? paramType;

  /// ID of the scope that holds this registration.
  final String scopeId;

  /// Human-readable name of the scope that holds this registration.
  final String scopeName;

  /// Depth of the owning scope.
  final int scopeDepth;

  /// Whether an instance is currently created / allocated in memory.
  final bool isCreated;

  /// Whether this registration is currently in the process of resolving.
  final bool isResolving;

  /// Whether this registration shadows (overrides) an ancestor registration for the same type/key.
  final bool isShadowed;

  /// Whether this registration is part of a multi-registration for its type.
  final bool isMulti;

  /// The multi-resolution strategy, if part of a multi-registration.
  final String? multiResolution;

  /// 0-based index within the multi-registration list, if applicable.
  final int? multiIndex;

  /// Total number of registrations in the multi-registration list, if applicable.
  final int? multiTotal;

  /// Safe runtime type representation of the created instance (e.g. 'AuthServiceImpl'), or `null`.
  final String? instanceRuntimeType;

  /// List of dependency type names explicitly declared or inferred.
  final List<String> dependencies;

  /// Creates a new [RegistrationSnapshot].
  const RegistrationSnapshot({
    required this.id,
    required this.typeName,
    this.key,
    required this.lifetime,
    this.paramType,
    required this.scopeId,
    required this.scopeName,
    required this.scopeDepth,
    required this.isCreated,
    required this.isResolving,
    required this.isShadowed,
    this.isMulti = false,
    this.multiResolution,
    this.multiIndex,
    this.multiTotal,
    this.instanceRuntimeType,
    this.dependencies = const [],
  });

  /// Serializes this registration snapshot into a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'typeName': typeName,
    'key': key,
    'lifetime': lifetime,
    'paramType': paramType,
    'scopeId': scopeId,
    'scopeName': scopeName,
    'scopeDepth': scopeDepth,
    'isCreated': isCreated,
    'isResolving': isResolving,
    'isShadowed': isShadowed,
    'isMulti': isMulti,
    'multiResolution': multiResolution,
    'multiIndex': multiIndex,
    'multiTotal': multiTotal,
    'instanceRuntimeType': instanceRuntimeType,
    'dependencies': dependencies,
  };

  /// Deserializes a [RegistrationSnapshot] from a JSON map.
  factory RegistrationSnapshot.fromJson(Map<String, dynamic> json) =>
      RegistrationSnapshot(
        id: json['id'] as String? ?? '',
        typeName: json['typeName'] as String? ?? 'Object',
        key: json['key'] as String?,
        lifetime: json['lifetime'] as String? ?? 'Singleton',
        paramType: json['paramType'] as String?,
        scopeId: json['scopeId'] as String? ?? 'root',
        scopeName: json['scopeName'] as String? ?? 'root',
        scopeDepth: (json['scopeDepth'] as num?)?.toInt() ?? 0,
        isCreated: json['isCreated'] as bool? ?? false,
        isResolving: json['isResolving'] as bool? ?? false,
        isShadowed: json['isShadowed'] as bool? ?? false,
        isMulti: json['isMulti'] as bool? ?? false,
        multiResolution: json['multiResolution'] as String?,
        multiIndex: (json['multiIndex'] as num?)?.toInt(),
        multiTotal: (json['multiTotal'] as num?)?.toInt(),
        instanceRuntimeType: json['instanceRuntimeType'] as String?,
        dependencies: (json['dependencies'] as List<dynamic>? ?? [])
            .cast<String>(),
      );
}

/// Represents a diagnostic issue, warning, or notice about the container state.
final class DiagnosticNotice {
  /// Severity of this notice ('info', 'warning', 'error').
  final String severity;

  /// Short headline describing the issue.
  final String title;

  /// Detailed description and actionable guidance.
  final String message;

  /// Optional related type name or registration ID.
  final String? relatedType;

  /// Optional related scope name or ID.
  final String? relatedScope;

  /// Creates a new [DiagnosticNotice].
  const DiagnosticNotice({
    required this.severity,
    required this.title,
    required this.message,
    this.relatedType,
    this.relatedScope,
  });

  /// Serializes this notice into a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'severity': severity,
    'title': title,
    'message': message,
    'relatedType': relatedType,
    'relatedScope': relatedScope,
  };

  /// Deserializes a [DiagnosticNotice] from a JSON map.
  factory DiagnosticNotice.fromJson(Map<String, dynamic> json) =>
      DiagnosticNotice(
        severity: json['severity'] as String? ?? 'info',
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        relatedType: json['relatedType'] as String?,
        relatedScope: json['relatedScope'] as String?,
      );
}
