import 'package:cloneable_example/models/clean_models.dart';
import 'package:test/test.dart';

void main() {
  group('Extension-Based Cloneable (No Mixin Required)', () {
    test('CleanUser works with copyWith generated as Extension', () {
      const user = CleanUser(
        id: 'u-1',
        name: 'Ahmed',
        age: 25,
        bio: 'Dart Engineer',
      );

      // Normal clone (no changes)
      final same = user.copyWith();
      expect(same.id, equals('u-1'));
      expect(same.name, equals('Ahmed'));
      expect(same.age, equals(25));
      expect(same.bio, equals('Dart Engineer'));

      // Partial update
      final updated = user.copyWith(name: 'Mohamed', age: 26);
      expect(updated.id, equals('u-1'));
      expect(updated.name, equals('Mohamed'));
      expect(updated.age, equals(26));
      expect(updated.bio, equals('Dart Engineer'));

      // Explicit null on nullable field
      final cleared = user.copyWith(bio: null);
      expect(cleared.id, equals('u-1'));
      expect(cleared.name, equals('Ahmed'));
      expect(cleared.age, equals(25));
      expect(cleared.bio, isNull);
    });

    test('CleanProduct works with extension and deepCopyCollections', () {
      const product = CleanProduct(
        sku: 'SKU-100',
        price: 49.99,
        tags: ['electronics', 'gadgets'],
      );

      final cloned = product.copyWith();
      expect(cloned.sku, equals('SKU-100'));
      expect(cloned.price, equals(49.99));
      expect(cloned.tags, equals(['electronics', 'gadgets']));

      // Deep copy verification
      expect(identical(product.tags, cloned.tags), isFalse);
      cloned.tags.add('new');
      expect(product.tags, equals(['electronics', 'gadgets']));
      expect(cloned.tags, equals(['electronics', 'gadgets', 'new']));
    });

    test('AliasedUserModel works with @UseCopyWith typedef alias', () {
      const user = AliasedUserModel(name: 'Ahmed', age: 25);
      final updated = user.copyWith(name: 'Ali', age: 26);
      expect(updated.name, equals('Ali'));
      expect(updated.age, equals(26));
    });

    test('CustomPrefixUser works with custom prefix in part file', () {
      const user = CustomPrefixUser(name: 'Ahmed', email: 'ahmed@test.com');
      final updated = user.copyWith(email: 'new@test.com');
      expect(updated.name, equals('Ahmed'));
      expect(updated.email, equals('new@test.com'));
    });

    test('CustomMixinUser works with custom prefix in mixin part file', () {
      const user = CustomMixinUser(name: 'Ahmed', email: 'ahmed@test.com');
      final updated = user.copyWith(name: 'Mohamed');
      expect(updated.name, equals('Mohamed'));
      expect(updated.email, equals('ahmed@test.com'));
    });
  });
}
