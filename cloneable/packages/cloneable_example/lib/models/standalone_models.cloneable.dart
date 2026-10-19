// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:cloneable/cloneable.dart';
import 'standalone_models.dart';
import 'external_library.dart';
import 'external_library.dart' as ext;

/// Strongly-typed copyWith function signature for [StandaloneOrder].
typedef $StandaloneOrderCopyWithFn = StandaloneOrder Function({
  String id,
  ExternalStatus status,
  ExternalPriority priority,
  ExternalAddress address,
  ExternalConfig config,
  List<ExternalAddress> locations,
});

/// Generated cloneable extension for [StandaloneOrder].
extension $StandaloneOrderExtension on StandaloneOrder {
  $StandaloneOrderCopyWithFn get copyWith => _copyWith;

  StandaloneOrder _copyWith({
    Object? id = $undefined,
    Object? status = $undefined,
    Object? priority = $undefined,
    Object? address = $undefined,
    Object? config = $undefined,
    Object? locations = $undefined,
  }) {
    final self = this;
    return StandaloneOrder(
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
      config: identical(config, $undefined)
          ? self.config
          : config as ExternalConfig,
      locations: identical(locations, $undefined)
          ? self.locations
          : locations as List<ExternalAddress>,
    );
  }
}

/// Strongly-typed copyWith function signature for [StandalonePrefixedCustomer].
typedef $StandalonePrefixedCustomerCopyWithFn = StandalonePrefixedCustomer
    Function({
  String id,
  ext.ExternalStatus status,
  ext.ExternalAddress address,
  ext.ExternalConfig config,
});

/// Generated cloneable extension for [StandalonePrefixedCustomer].
extension $StandalonePrefixedCustomerExtension on StandalonePrefixedCustomer {
  $StandalonePrefixedCustomerCopyWithFn get copyWith => _copyWith;

  StandalonePrefixedCustomer _copyWith({
    Object? id = $undefined,
    Object? status = $undefined,
    Object? address = $undefined,
    Object? config = $undefined,
  }) {
    final self = this;
    return StandalonePrefixedCustomer(
      id: identical(id, $undefined) ? self.id : id as String,
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

/// Strongly-typed copyWith function signature for [StandaloneCustomProfile].
typedef $StandaloneCustomProfileCopyWithFn = StandaloneCustomProfile Function({
  String username,
  String? bio,
});

/// Generated cloneable extension for [StandaloneCustomProfile].
extension CustomStandaloneCustomProfileExtension on StandaloneCustomProfile {
  $StandaloneCustomProfileCopyWithFn get copyWith => _copyWith;

  StandaloneCustomProfile _copyWith({
    Object? username = $undefined,
    Object? bio = $undefined,
  }) {
    final self = this;
    return StandaloneCustomProfile(
      username:
          identical(username, $undefined) ? self.username : username as String,
      bio: identical(bio, $undefined) ? self.bio : bio as String?,
    );
  }
}
