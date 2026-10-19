import 'package:cloneable/cloneable.dart';

import 'external_library.dart';
import 'external_library.dart' as ext;

part 'imported_models.g.dart';

/// Model utilizing types, members, and values imported from another library.
@Cloneable()
class ImportedAccount with _$ImportedAccountCloneable {
  final String id;
  final ExternalStatus status;
  final ExternalPriority priority;
  final ExternalAddress address;
  final ExternalAddress? secondaryAddress;
  final ExternalProfile profile;
  final ExternalConfig config;
  final ExternalResult<String> payload;
  final int maxRetries;
  final DateTime createdAt;
  final Uri profileUri;
  final Duration sessionDuration;
  final List<ExternalAddress> branchLocations;
  final Map<String, ExternalStatus> statusHistory;

  const ImportedAccount({
    required this.id,
    this.status = kDefaultStatus,
    this.priority = kDefaultPriority,
    required this.address,
    this.secondaryAddress,
    required this.profile,
    this.config = ExternalConfig.defaultConfig,
    required this.payload,
    this.maxRetries = ExternalConfig.globalMaxRetries,
    required this.createdAt,
    required this.profileUri,
    this.sessionDuration = kDefaultTimeout,
    this.branchLocations = const [],
    this.statusHistory = const {},
  });
}

/// Model utilizing types and values imported with an import prefix (ext.Type).
@Cloneable()
class PrefixedImportModel with _$PrefixedImportModelCloneable {
  final String label;
  final ext.ExternalStatus status;
  final ext.ExternalAddress address;
  final ext.ExternalConfig config;

  const PrefixedImportModel({
    required this.label,
    this.status = ext.kDefaultStatus,
    required this.address,
    this.config = ext.ExternalConfig.defaultConfig,
  });
}

/// Model utilizing extension strategy and deep collection copying with imported types.
@Cloneable(strategy: CloneableStrategy.extension, deepCopyCollections: true)
class ExtensionImportedProduct {
  final String sku;
  final ExternalStatus status;
  final List<ExternalAddress> hubs;
  final ExternalConfig? customConfig;

  const ExtensionImportedProduct({
    required this.sku,
    this.status = kDefaultStatus,
    required this.hubs,
    this.customConfig,
  });
}

/// Model demonstrating ignoreNull with imported types and values.
@Cloneable(ignoreNull: true)
class IgnoreNullImportedModel with _$IgnoreNullImportedModelCloneable {
  final ExternalStatus status;
  final ExternalAddress? address;

  const IgnoreNullImportedModel({
    required this.status,
    this.address,
  });
}

/// Model demonstrating field-level ignore on an imported member type.
@Cloneable()
class SelectiveImportedModel with _$SelectiveImportedModelCloneable {
  final String title;
  final ExternalStatus status;

  @CloneableField(ignore: true)
  final ExternalConfig internalConfig;

  const SelectiveImportedModel({
    required this.title,
    required this.status,
    this.internalConfig = ExternalConfig.defaultConfig,
  });
}
