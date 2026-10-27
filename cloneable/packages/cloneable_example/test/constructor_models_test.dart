import 'package:cloneable_example/models/constructor_models.dart';
import 'package:test/test.dart';

void main() {
  group('Constructor & Field Customization copyWith', () {
    test('Coordinate with positional constructor parameters', () {
      const coord = Coordinate(10.5, 20.0, 30.5);

      // Update x and clear z
      final updated = coord.copyWith(x: 99.0, z: null);

      expect(updated.x, equals(99.0));
      expect(updated.y, equals(20.0)); // Preserved
      expect(updated.z, isNull); // Explicitly cleared to null

      // Original unchanged
      expect(coord.x, equals(10.5));
      expect(coord.z, equals(30.5));
    });

    test('ServiceConfig with custom named constructor (.create)', () {
      const config = ServiceConfig.create(
        host: 'localhost',
        port: 8080,
        enableSsl: false,
      );

      final prodConfig = config.copyWith(
        host: 'api.production.com',
        port: 443,
        enableSsl: true,
      );

      expect(prodConfig.host, equals('api.production.com'));
      expect(prodConfig.port, equals(443));
      expect(prodConfig.enableSsl, isTrue);

      final devConfig = prodConfig.copyWith(enableSsl: null);
      expect(devConfig.enableSsl, isNull);
    });

    test('AuditedEntity with @CloneableField(ignore: true) preserves ignored field', () {
      final now = DateTime(2026, 1, 1, 12, 0);
      final entity = AuditedEntity(
        id: 'ENT-42',
        title: 'Original Title',
        createdAt: now,
      );

      final updated = entity.copyWith(title: 'Updated Title');

      expect(updated.id, equals('ENT-42'));
      expect(updated.title, equals('Updated Title'));
      expect(
        updated.createdAt,
        equals(now),
      ); // Ignored field preserved automatically!
    });
  });
}
