// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'imported_models.dart';

/// Strongly-typed copyWith function signature for [ImportedAccount].
typedef $ImportedAccountCopyWithFn = ImportedAccount Function({
  String id,
  ExternalStatus status,
  ExternalPriority priority,
  ExternalAddress address,
  ExternalAddress? secondaryAddress,
  ExternalProfile profile,
  ExternalConfig config,
  ExternalResult<String> payload,
  int maxRetries,
  DateTime createdAt,
  Uri profileUri,
  Duration sessionDuration,
  List<ExternalAddress> branchLocations,
  Map<String, ExternalStatus> statusHistory,
});

/// Generated cloneable mixin for [ImportedAccount].
mixin _$ImportedAccountCloneable {
  $ImportedAccountCopyWithFn get copyWith => _copyWith;

  ImportedAccount _copyWith({
    Object? id = $undefined,
    Object? status = $undefined,
    Object? priority = $undefined,
    Object? address = $undefined,
    Object? secondaryAddress = $undefined,
    Object? profile = $undefined,
    Object? config = $undefined,
    Object? payload = $undefined,
    Object? maxRetries = $undefined,
    Object? createdAt = $undefined,
    Object? profileUri = $undefined,
    Object? sessionDuration = $undefined,
    Object? branchLocations = $undefined,
    Object? statusHistory = $undefined,
  }) {
    final self = this as ImportedAccount;
    return ImportedAccount(
      id: identical(id, $undefined) ? self.id : id as String,
      status: identical(status, $undefined)
          ? self.status
          : status as ExternalStatus,
      priority: identical(priority, $undefined)
          ? self.priority
          : priority as ExternalPriority,
      address: identical(address, $undefined)
          ? self.address
          : address as ExternalAddress,
      secondaryAddress: identical(secondaryAddress, $undefined)
          ? self.secondaryAddress
          : secondaryAddress as ExternalAddress?,
      profile: identical(profile, $undefined)
          ? self.profile
          : profile as ExternalProfile,
      config: identical(config, $undefined)
          ? self.config
          : config as ExternalConfig,
      payload: identical(payload, $undefined)
          ? self.payload
          : payload as ExternalResult<String>,
      maxRetries: identical(maxRetries, $undefined)
          ? self.maxRetries
          : maxRetries as int,
      createdAt: identical(createdAt, $undefined)
          ? self.createdAt
          : createdAt as DateTime,
      profileUri: identical(profileUri, $undefined)
          ? self.profileUri
          : profileUri as Uri,
      sessionDuration: identical(sessionDuration, $undefined)
          ? self.sessionDuration
          : sessionDuration as Duration,
      branchLocations: identical(branchLocations, $undefined)
          ? self.branchLocations
          : branchLocations as List<ExternalAddress>,
      statusHistory: identical(statusHistory, $undefined)
          ? self.statusHistory
          : statusHistory as Map<String, ExternalStatus>,
    );
  }
}

/// Strongly-typed copyWith function signature for [PrefixedImportModel].
typedef $PrefixedImportModelCopyWithFn = PrefixedImportModel Function({
  String label,
  ext.ExternalStatus status,
  ext.ExternalAddress address,
  ext.ExternalConfig config,
});

/// Generated cloneable mixin for [PrefixedImportModel].
mixin _$PrefixedImportModelCloneable {
  $PrefixedImportModelCopyWithFn get copyWith => _copyWith;

  PrefixedImportModel _copyWith({
    Object? label = $undefined,
    Object? status = $undefined,
    Object? address = $undefined,
    Object? config = $undefined,
  }) {
    final self = this as PrefixedImportModel;
    return PrefixedImportModel(
      label: identical(label, $undefined) ? self.label : label as String,
      status: identical(status, $undefined)
          ? self.status
          : status as ext.ExternalStatus,
      address: identical(address, $undefined)
          ? self.address
          : address as ext.ExternalAddress,
      config: identical(config, $undefined)
          ? self.config
          : config as ext.ExternalConfig,
    );
  }
}

/// Strongly-typed copyWith function signature for [ExtensionImportedProduct].
typedef $ExtensionImportedProductCopyWithFn = ExtensionImportedProduct
    Function({
  String sku,
  ExternalStatus status,
  List<ExternalAddress> hubs,
  ExternalConfig? customConfig,
});

/// Generated cloneable extension for [ExtensionImportedProduct].
extension $ExtensionImportedProductExtension on ExtensionImportedProduct {
  $ExtensionImportedProductCopyWithFn get copyWith => _copyWith;

  ExtensionImportedProduct _copyWith({
    Object? sku = $undefined,
    Object? status = $undefined,
    Object? hubs = $undefined,
    Object? customConfig = $undefined,
  }) {
    final self = this;
    return ExtensionImportedProduct(
      sku: identical(sku, $undefined) ? self.sku : sku as String,
      status: identical(status, $undefined)
          ? self.status
          : status as ExternalStatus,
      hubs: identical(hubs, $undefined)
          ? List.of(self.hubs)
          : List.of(hubs as List<ExternalAddress>),
      customConfig: identical(customConfig, $undefined)
          ? self.customConfig
          : customConfig as ExternalConfig?,
    );
  }
}

/// Strongly-typed copyWith function signature for [IgnoreNullImportedModel].
typedef $IgnoreNullImportedModelCopyWithFn = IgnoreNullImportedModel Function({
  ExternalStatus? status,
  ExternalAddress? address,
});

/// Generated cloneable mixin for [IgnoreNullImportedModel].
mixin _$IgnoreNullImportedModelCloneable {
  $IgnoreNullImportedModelCopyWithFn get copyWith => _copyWith;

  IgnoreNullImportedModel _copyWith({
    Object? status = $undefined,
    Object? address = $undefined,
  }) {
    final self = this as IgnoreNullImportedModel;
    return IgnoreNullImportedModel(
      status: identical(status, $undefined) || status == null
          ? self.status
          : status as ExternalStatus,
      address: identical(address, $undefined) || address == null
          ? self.address
          : address as ExternalAddress?,
    );
  }
}

/// Strongly-typed copyWith function signature for [SelectiveImportedModel].
typedef $SelectiveImportedModelCopyWithFn = SelectiveImportedModel Function({
  String title,
  ExternalStatus status,
});

/// Generated cloneable mixin for [SelectiveImportedModel].
mixin _$SelectiveImportedModelCloneable {
  $SelectiveImportedModelCopyWithFn get copyWith => _copyWith;

  SelectiveImportedModel _copyWith({
    Object? title = $undefined,
    Object? status = $undefined,
  }) {
    final self = this as SelectiveImportedModel;
    return SelectiveImportedModel(
      title: identical(title, $undefined) ? self.title : title as String,
      status: identical(status, $undefined)
          ? self.status
          : status as ExternalStatus,
      internalConfig: self.internalConfig,
    );
  }
}
