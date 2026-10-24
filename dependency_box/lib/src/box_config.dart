import 'dependency.dart';

/// Centralized configuration defaults and constants for `dependency_box`.
abstract final class BoxConfig {
  /// Default resolution strategy for multi-instance registrations.
  static const MultiResolution defaultMultiResolution = MultiResolution.last;

  /// Default behavior for whether to dispose the replaced instance during replacement.
  static const bool defaultDisposeOldOnReplace = true;

  /// Default behavior for whether to dispose the removed instance during removal.
  static const bool defaultDisposeOnRemove = true;
}
