// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complex_models.dart';

/// Generated cloneable mixin for [Address].
mixin _$AddressCloneable {
  Address Function({String street, String city, String? zipCode})
  get copyWith => _copyWith;

  Address _copyWith({
    Object? street = $undefined,
    Object? city = $undefined,
    Object? zipCode = $undefined,
  }) {
    final self = this as Address;
    return Address(
      street: identical(street, $undefined) ? self.street : street as String,
      city: identical(city, $undefined) ? self.city : city as String,
      zipCode: identical(zipCode, $undefined)
          ? self.zipCode
          : zipCode as String?,
    );
  }
}

/// Generated cloneable mixin for [Employee].
mixin _$EmployeeCloneable {
  Employee Function({
    String id,
    String name,
    Role role,
    Address? address,
    List<String> tags,
    Map<String, dynamic>? metadata,
  })
  get copyWith => _copyWith;

  Employee _copyWith({
    Object? id = $undefined,
    Object? name = $undefined,
    Object? role = $undefined,
    Object? address = $undefined,
    Object? tags = $undefined,
    Object? metadata = $undefined,
  }) {
    final self = this as Employee;
    return Employee(
      id: identical(id, $undefined) ? self.id : id as String,
      name: identical(name, $undefined) ? self.name : name as String,
      role: identical(role, $undefined) ? self.role : role as Role,
      address: identical(address, $undefined)
          ? self.address
          : address as Address?,
      tags: identical(tags, $undefined) ? self.tags : tags as List<String>,
      metadata: identical(metadata, $undefined)
          ? self.metadata
          : metadata as Map<String, dynamic>?,
    );
  }
}
