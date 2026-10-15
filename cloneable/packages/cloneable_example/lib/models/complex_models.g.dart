// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complex_models.dart';

// **************************************************************************
// CloneableGenerator
// **************************************************************************

/// Strongly-typed copyWith function signature for [Address].
typedef $AddressCopyWith = Address Function({
  String street,
  String city,
  String? zipCode,
});

/// Generated cloneable mixin for [Address].
mixin _$AddressCloneable {
  $AddressCopyWith get copyWith => _copyWith;

  Address _copyWith({
    Object? street = cloneableUndefined,
    Object? city = cloneableUndefined,
    Object? zipCode = cloneableUndefined,
  }) {
    final self = this as Address;
    return Address(
      street: identical(street, cloneableUndefined)
          ? self.street
          : street as String,
      city: identical(city, cloneableUndefined) ? self.city : city as String,
      zipCode: identical(zipCode, cloneableUndefined)
          ? self.zipCode
          : zipCode as String?,
    );
  }
}

/// Strongly-typed copyWith function signature for [Employee].
typedef $EmployeeCopyWith = Employee Function({
  String id,
  String name,
  Role role,
  Address? address,
  List<String> tags,
  Map<String, dynamic>? metadata,
});

/// Generated cloneable mixin for [Employee].
mixin _$EmployeeCloneable {
  $EmployeeCopyWith get copyWith => _copyWith;

  Employee _copyWith({
    Object? id = cloneableUndefined,
    Object? name = cloneableUndefined,
    Object? role = cloneableUndefined,
    Object? address = cloneableUndefined,
    Object? tags = cloneableUndefined,
    Object? metadata = cloneableUndefined,
  }) {
    final self = this as Employee;
    return Employee(
      id: identical(id, cloneableUndefined) ? self.id : id as String,
      name: identical(name, cloneableUndefined) ? self.name : name as String,
      role: identical(role, cloneableUndefined) ? self.role : role as Role,
      address: identical(address, cloneableUndefined)
          ? self.address
          : address as Address?,
      tags: identical(tags, cloneableUndefined)
          ? self.tags
          : tags as List<String>,
      metadata: identical(metadata, cloneableUndefined)
          ? self.metadata
          : metadata as Map<String, dynamic>?,
    );
  }
}
