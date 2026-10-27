import 'package:cloneable/cloneable.dart';

part 'complex_models.g.dart';

enum Role { developer, designer, manager }

@Cloneable()
class Address with _$AddressCloneable {
  final String street;
  final String city;
  final String? zipCode;

  const Address({required this.street, required this.city, this.zipCode});
}

@Cloneable()
class Employee with _$EmployeeCloneable {
  final String id;
  final String name;
  final Role role;
  final Address? address;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  const Employee({
    required this.id,
    required this.name,
    required this.role,
    this.address,
    required this.tags,
    this.metadata,
  });
}
