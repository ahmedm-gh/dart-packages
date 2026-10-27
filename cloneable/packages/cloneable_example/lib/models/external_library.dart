import 'package:cloneable/cloneable.dart';

part 'external_library.g.dart';

/// An external enum type imported from another library.
enum ExternalStatus {
  pending,
  active,
  archived;

  /// Instance member getter on imported enum.
  bool get isActive => this == ExternalStatus.active;
}

/// An external priority enum.
enum ExternalPriority { low, medium, high }

/// An external class type imported from another library.
class ExternalAddress {
  final String street;
  final String city;
  final String country;

  const ExternalAddress({
    required this.street,
    required this.city,
    this.country = 'USA',
  });

  /// Static member: constant origin address.
  static const ExternalAddress origin = ExternalAddress(
    street: '0 Ground Zero',
    city: 'Origin City',
    country: 'Nowhere',
  );

  /// Instance member getter.
  String get fullAddress => '$street, $city, $country';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExternalAddress &&
          runtimeType == other.runtimeType &&
          street == other.street &&
          city == other.city &&
          country == other.country;

  @override
  int get hashCode => Object.hash(street, city, country);
}

/// An external configuration class with static members.
class ExternalConfig {
  final Duration timeout;
  final int maxRetries;
  final bool enableCache;

  const ExternalConfig({
    required this.timeout,
    this.maxRetries = 3,
    this.enableCache = true,
  });

  /// Static member: default configuration constant.
  static const ExternalConfig defaultConfig = ExternalConfig(
    timeout: Duration(seconds: 30),
    maxRetries: 3,
    enableCache: true,
  );

  /// Static member: production configuration constant.
  static const ExternalConfig productionConfig = ExternalConfig(
    timeout: Duration(seconds: 10),
    maxRetries: 5,
    enableCache: true,
  );

  /// Static member: maximum allowed retries value.
  static const int globalMaxRetries = 10;
}

/// External generic container type.
class ExternalResult<T> {
  final T data;
  final bool success;

  const ExternalResult(this.data, {this.success = true});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExternalResult<T> &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          success == other.success;

  @override
  int get hashCode => Object.hash(data, success);
}

/// External cloneable model that can be nested and cloned.
@Cloneable()
class ExternalProfile with _$ExternalProfileCloneable {
  final String username;
  final String email;

  const ExternalProfile({required this.username, required this.email});
}

/// External typedef / function signature type.
typedef ExternalFormatter = String Function(String value);

/// External top-level constant values imported from another library.
const kDefaultStatus = ExternalStatus.active;
const kDefaultPriority = ExternalPriority.medium;
const kDefaultTimeout = Duration(seconds: 60);
const kDefaultTag = 'external-default';
const kDefaultAddress = ExternalAddress(
  street: '123 Tech Way',
  city: 'Metropolis',
  country: 'Earth',
);
