import 'package:cloneable/cloneable.dart';

import 'external_library.dart';
import 'external_library.dart' as ext;

/// Standalone model demonstrating the non-part approach (no part directive).
/// Generates an independent standalone extension file without `part of`.
@Cloneable(strategy: CloneableStrategy.extension)
class StandaloneOrder {
  final String id;
  final ExternalStatus status;
  final ExternalPriority priority;
  final ExternalAddress address;
  final ExternalConfig config;
  final List<ExternalAddress> locations;

  const StandaloneOrder({
    required this.id,
    this.status = kDefaultStatus,
    this.priority = kDefaultPriority,
    required this.address,
    this.config = ExternalConfig.defaultConfig,
    this.locations = const [],
  });
}

/// Standalone model demonstrating prefixed types in the non-part approach.
@Cloneable(strategy: CloneableStrategy.extension)
class StandalonePrefixedCustomer {
  final String id;
  final ext.ExternalStatus status;
  final ext.ExternalAddress address;
  final ext.ExternalConfig config;

  const StandalonePrefixedCustomer({
    required this.id,
    this.status = ext.kDefaultStatus,
    required this.address,
    this.config = ext.ExternalConfig.defaultConfig,
  });
}

/// Standalone model demonstrating custom prefix in the non-part approach.
@Cloneable(
  strategy: CloneableStrategy.extension,
  naming: CloneableNaming(
    extension: CloneableAffix(prefix: 'Custom'),
  ),
)
class StandaloneCustomProfile {
  final String username;
  final String? bio;

  const StandaloneCustomProfile({
    required this.username,
    this.bio,
  });
}
