import 'package:cloneable_example/models/ignore_null_models.dart';
import 'package:test/test.dart';

void main() {
  group('Field-level ignoreNull', () {
    test('passing null to ignoreNull field preserves the existing value', () {
      const original = IgnoreNullModel(
        normalField: 'hello',
        ignoredNullField: 'initial',
      );

      // Passing null to ignoredNullField should ignore null and preserve 'initial'
      final withNull = original.copyWith(ignoredNullField: null);
      expect(withNull.ignoredNullField, equals('initial'));

      // Passing a non-null value updates it
      final withValue = original.copyWith(ignoredNullField: 'updated');
      expect(withValue.ignoredNullField, equals('updated'));
    });
  });

  group('Class-level ignoreNull', () {
    test(
        'passing null to nullable fields on class-level ignoreNull preserves values',
        () {
      const original = ClassLevelIgnoreNullModel(
        name: 'Ahmed',
        bio: 'Developer',
        score: 100,
      );

      // Passing null to both nullable fields
      final withNulls = original.copyWith(bio: null, score: null);
      expect(withNulls.bio, equals('Developer'));
      expect(withNulls.score, equals(100));

      // Updating one with a non-null value
      final withUpdate = original.copyWith(bio: 'Senior Dev');
      expect(withUpdate.bio, equals('Senior Dev'));
      expect(withUpdate.score, equals(100));
    });
  });
}
