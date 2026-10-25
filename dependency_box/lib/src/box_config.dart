import 'multi_registration.dart';

/// Centralized configuration defaults and constants for `dependency_box`.
abstract final class DependencyBoxConfig {
  /// Default resolution strategy for multi-instance registrations.
  static const defaultMultiResolution = MultiResolution.last;

  /// Default behavior for whether to dispose the replaced instance during replacement.
  static const defaultDisposeOldOnReplace = true;

  /// Default behavior for whether to dispose the removed instance during removal.
  static const defaultDisposeOnRemove = true;

  /// Whether the runtime environment is in product mode.
  /// Evaluates to `true` if the application was compiled in product
  /// (`dart.vm.product`) mode.
  static const isProduct = bool.fromEnvironment('dart.vm.product');

  /// Evaluates to `true` if the application was compiled in profile
  /// (`dart.vm.profile`) mode.
  static const isProfile = bool.fromEnvironment('dart.vm.profile');

  /// Evaluates to `true` if the application was compiled in debug mode
  /// (neither product nor profile).
  static const isDebug = !isProduct && !isProfile;
}
