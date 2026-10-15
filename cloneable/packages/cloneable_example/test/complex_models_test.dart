import 'package:cloneable_example/models/complex_models.dart';
import 'package:test/test.dart';

void main() {
  group('Complex Models copyWith', () {
    test('Address copyWith preserves and clears zipCode', () {
      const address = Address(
        street: '123 Main St',
        city: 'Metropolis',
        zipCode: '10001',
      );

      final clearedZip = address.copyWith(zipCode: null);
      expect(clearedZip.street, equals('123 Main St'));
      expect(clearedZip.city, equals('Metropolis'));
      expect(clearedZip.zipCode, isNull);
    });

    test('Employee copyWith with enums, nested models, and collections', () {
      const initialAddress = Address(
        street: '456 Tech Blvd',
        city: 'Silicon City',
        zipCode: '94016',
      );

      const employee = Employee(
        id: 'EMP-001',
        name: 'Sarah Connor',
        role: Role.developer,
        address: initialAddress,
        tags: ['dart', 'flutter', 'backend'],
        metadata: {'level': 'Senior', 'active': true},
      );

      // 1. Update role enum and tags, preserve address and metadata
      final updatedRole = employee.copyWith(
        role: Role.manager,
        tags: ['management', 'architecture'],
      );
      expect(updatedRole.role, equals(Role.manager));
      expect(updatedRole.tags, equals(['management', 'architecture']));
      expect(updatedRole.address?.street, equals('456 Tech Blvd'));
      expect(updatedRole.metadata?['level'], equals('Senior'));

      // 2. Clear nullable nested address and metadata
      final clearedNested = employee.copyWith(
        address: null,
        metadata: null,
      );
      expect(clearedNested.address, isNull);
      expect(clearedNested.metadata, isNull);
      expect(clearedNested.name, equals('Sarah Connor'));

      // 3. Update nested address with newly cloned address
      final updatedAddress = employee.copyWith(
        address: employee.address?.copyWith(city: 'New Metropolis'),
      );
      expect(updatedAddress.address?.city, equals('New Metropolis'));
      expect(updatedAddress.address?.street, equals('456 Tech Blvd'));
      expect(employee.address?.city, equals('Silicon City')); // Unchanged
    });
  });
}
