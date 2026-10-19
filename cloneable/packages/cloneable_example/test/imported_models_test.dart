import 'package:cloneable_example/models/external_library.dart';
import 'package:cloneable_example/models/external_library.dart' as ext;
import 'package:cloneable_example/models/imported_models.dart';
import 'package:test/test.dart';

void main() {
  group('Imported Members, Values, and Types Tests', () {
    test(
        'ImportedAccount correctly utilizes imported types, default values, and members',
        () {
      final initial = ImportedAccount(
        id: 'acc-001',
        address: kDefaultAddress,
        profile: const ExternalProfile(
          username: 'ahmed',
          email: 'ahmed@example.com',
        ),
        payload: const ExternalResult('initial-payload'),
        createdAt: DateTime(2026, 10, 19),
        profileUri: Uri.parse('https://example.com/profile/acc-001'),
      );

      // Verify initial imported values and static members
      expect(initial.status, equals(ExternalStatus.active));
      expect(initial.status.isActive, isTrue);
      expect(initial.priority, equals(ExternalPriority.medium));
      expect(initial.address.fullAddress,
          equals('123 Tech Way, Metropolis, Earth'));
      expect(initial.secondaryAddress, isNull);
      expect(initial.config.timeout, equals(const Duration(seconds: 30)));
      expect(initial.config.maxRetries, equals(3));
      expect(initial.maxRetries, equals(ExternalConfig.globalMaxRetries));
      expect(initial.payload.data, equals('initial-payload'));
      expect(initial.payload.success, isTrue);
      expect(initial.sessionDuration, equals(kDefaultTimeout));
      expect(initial.branchLocations, isEmpty);
      expect(initial.statusHistory, isEmpty);

      // Verify copyWith with imported types, members, and values
      final updated = initial.copyWith(
        status: ExternalStatus.archived,
        priority: ExternalPriority.high,
        address: ExternalAddress.origin,
        secondaryAddress: const ExternalAddress(
          street: '456 Secondary Rd',
          city: 'SubCity',
        ),
        profile: initial.profile.copyWith(email: 'newemail@example.com'),
        config: ExternalConfig.productionConfig,
        payload: const ExternalResult('updated-payload', success: false),
        maxRetries: 5,
        sessionDuration: const Duration(minutes: 15),
        branchLocations: [kDefaultAddress, ExternalAddress.origin],
        statusHistory: {
          'step-1': ExternalStatus.pending,
          'step-2': ExternalStatus.active,
        },
      );

      // Verify updated instance has new values and member computations
      expect(updated.id, equals('acc-001'));
      expect(updated.status, equals(ExternalStatus.archived));
      expect(updated.status.isActive, isFalse);
      expect(updated.priority, equals(ExternalPriority.high));
      expect(updated.address.fullAddress,
          equals('0 Ground Zero, Origin City, Nowhere'));
      expect(updated.secondaryAddress?.fullAddress,
          equals('456 Secondary Rd, SubCity, USA'));
      expect(updated.profile.username, equals('ahmed'));
      expect(updated.profile.email, equals('newemail@example.com'));
      expect(updated.config.timeout, equals(const Duration(seconds: 10)));
      expect(updated.config.maxRetries, equals(5));
      expect(updated.payload.data, equals('updated-payload'));
      expect(updated.payload.success, isFalse);
      expect(updated.sessionDuration, equals(const Duration(minutes: 15)));
      expect(updated.branchLocations, hasLength(2));
      expect(updated.statusHistory['step-2'], equals(ExternalStatus.active));

      // Test clearing nullable imported type secondaryAddress to null
      final cleared = updated.copyWith(secondaryAddress: null);
      expect(cleared.secondaryAddress, isNull);
      expect(cleared.address, equals(ExternalAddress.origin));
    });

    test('PrefixedImportModel works with prefixed types, members, and values',
        () {
      const initial = PrefixedImportModel(
        label: 'Prefixed Sample',
        address: ext.ExternalAddress(
          street: '10 Alpha Blvd',
          city: 'Delta City',
        ),
      );

      expect(initial.label, equals('Prefixed Sample'));
      expect(initial.status, equals(ext.ExternalStatus.active));
      expect(initial.status.isActive, isTrue);
      expect(initial.config.timeout, equals(const Duration(seconds: 30)));
      expect(initial.address.fullAddress,
          equals('10 Alpha Blvd, Delta City, USA'));

      // copyWith using prefixed enum and static member values
      final updated = initial.copyWith(
        status: ext.ExternalStatus.pending,
        address: ext.ExternalAddress.origin,
        config: ext.ExternalConfig.productionConfig,
      );

      expect(updated.label, equals('Prefixed Sample'));
      expect(updated.status, equals(ext.ExternalStatus.pending));
      expect(updated.status.isActive, isFalse);
      expect(updated.address.fullAddress,
          equals('0 Ground Zero, Origin City, Nowhere'));
      expect(updated.config.timeout, equals(const Duration(seconds: 10)));
    });

    test(
        'ExtensionImportedProduct works with extension strategy and deep copying',
        () {
      const hub1 = ExternalAddress(street: 'Hub 1', city: 'City A');
      const hub2 = ExternalAddress(street: 'Hub 2', city: 'City B');
      final originalHubs = [hub1, hub2];

      final product = ExtensionImportedProduct(
        sku: 'SKU-999',
        hubs: originalHubs,
        customConfig: ExternalConfig.productionConfig,
      );

      expect(product.status, equals(kDefaultStatus));
      expect(product.hubs, hasLength(2));
      expect(product.customConfig?.maxRetries, equals(5));

      final cloned = product.copyWith(
        status: ExternalStatus.archived,
        customConfig: null,
      );

      // Verify deep collection copying creates independent instance
      expect(cloned.status, equals(ExternalStatus.archived));
      expect(cloned.customConfig, isNull);
      expect(cloned.hubs, equals(originalHubs));
      expect(identical(cloned.hubs, product.hubs), isFalse);

      // Modifying cloned list does not affect original product
      cloned.hubs.add(ExternalAddress.origin);
      expect(cloned.hubs, hasLength(3));
      expect(product.hubs, hasLength(2));
    });

    test('IgnoreNullImportedModel preserves values when null is passed', () {
      const model = IgnoreNullImportedModel(
        status: ExternalStatus.archived,
        address: kDefaultAddress,
      );

      final clonedWithNull = model.copyWith(
        status: null,
        address: null,
      );

      // Both fields preserved because of ignoreNull
      expect(clonedWithNull.status, equals(ExternalStatus.archived));
      expect(clonedWithNull.address, equals(kDefaultAddress));

      // Explicitly passing a new value updates correctly
      final updated = model.copyWith(
        status: ExternalStatus.active,
        address: ExternalAddress.origin,
      );
      expect(updated.status, equals(ExternalStatus.active));
      expect(updated.address, equals(ExternalAddress.origin));
    });

    test('SelectiveImportedModel preserves ignored imported member field', () {
      const model = SelectiveImportedModel(
        title: 'Original Title',
        status: ExternalStatus.pending,
        internalConfig: ExternalConfig.productionConfig,
      );

      final updated = model.copyWith(
        title: 'New Title',
        status: ExternalStatus.active,
      );

      expect(updated.title, equals('New Title'));
      expect(updated.status, equals(ExternalStatus.active));
      // Ignored field preserved from self
      expect(updated.internalConfig, equals(ExternalConfig.productionConfig));
      expect(updated.internalConfig.maxRetries, equals(5));
    });
  });
}
