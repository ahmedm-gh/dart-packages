import 'package:cloneable_example/models/external_library.dart';
import 'package:cloneable_example/models/external_library.dart' as ext;
import 'package:cloneable_example/models/standalone_models.cloneable.dart';
import 'package:cloneable_example/models/standalone_models.dart';
import 'package:test/test.dart';

void main() {
  group('Standalone / Non-Part Approach Tests', () {
    test(
        'StandaloneOrder copyWith works cleanly without part directive and with imported members/values/types',
        () {
      const initial = StandaloneOrder(
        id: 'ord-100',
        address: kDefaultAddress,
      );

      // Verify default imported values and static members
      expect(initial.id, equals('ord-100'));
      expect(initial.status, equals(ExternalStatus.active));
      expect(initial.status.isActive, isTrue);
      expect(initial.priority, equals(ExternalPriority.medium));
      expect(initial.address.fullAddress,
          equals('123 Tech Way, Metropolis, Earth'));
      expect(initial.config.timeout, equals(const Duration(seconds: 30)));
      expect(initial.locations, isEmpty);

      // Call copyWith from standalone extension file
      final updated = initial.copyWith(
        status: ExternalStatus.archived,
        priority: ExternalPriority.high,
        address: ExternalAddress.origin,
        config: ExternalConfig.productionConfig,
        locations: const [ExternalAddress.origin, kDefaultAddress],
      );

      expect(updated.id, equals('ord-100'));
      expect(updated.status, equals(ExternalStatus.archived));
      expect(updated.status.isActive, isFalse);
      expect(updated.priority, equals(ExternalPriority.high));
      expect(updated.address.fullAddress,
          equals('0 Ground Zero, Origin City, Nowhere'));
      expect(updated.config.timeout, equals(const Duration(seconds: 10)));
      expect(updated.config.maxRetries, equals(5));
      expect(updated.locations, hasLength(2));
    });

    test(
        'StandalonePrefixedCustomer copyWith works with prefixed types in non-part approach',
        () {
      const initial = StandalonePrefixedCustomer(
        id: 'cust-200',
        address: ext.ExternalAddress(
          street: '10 Alpha Blvd',
          city: 'Delta City',
        ),
      );

      expect(initial.id, equals('cust-200'));
      expect(initial.status, equals(ext.ExternalStatus.active));
      expect(initial.status.isActive, isTrue);
      expect(initial.config.timeout, equals(const Duration(seconds: 30)));
      expect(initial.address.fullAddress,
          equals('10 Alpha Blvd, Delta City, USA'));

      // Call copyWith using prefixed types and members
      final updated = initial.copyWith(
        status: ext.ExternalStatus.pending,
        address: ext.ExternalAddress.origin,
        config: ext.ExternalConfig.productionConfig,
      );

      expect(updated.id, equals('cust-200'));
      expect(updated.status, equals(ext.ExternalStatus.pending));
      expect(updated.status.isActive, isFalse);
      expect(updated.address.fullAddress,
          equals('0 Ground Zero, Origin City, Nowhere'));
      expect(updated.config.timeout, equals(const Duration(seconds: 10)));
      expect(updated.config.maxRetries, equals(5));
    });

    test(
        'StandaloneCustomProfile copyWith works with custom prefix in standalone approach',
        () {
      const initial = StandaloneCustomProfile(
        username: 'ahmed',
        bio: 'Developer',
      );

      final updated = initial.copyWith(
        bio: null,
      );

      expect(updated.username, equals('ahmed'));
      expect(updated.bio, isNull);

      final updated2 = updated.copyWith(
        username: 'ahmedm',
        bio: 'Open Source Maintainer',
      );

      expect(updated2.username, equals('ahmedm'));
      expect(updated2.bio, equals('Open Source Maintainer'));
    });
  });
}
