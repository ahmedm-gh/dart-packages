import 'package:cloneable_example/models/collection_models.dart';
import 'package:test/test.dart';

void main() {
  group('DeepCopyModel (Class-level deepCopyCollections: true)', () {
    test('copyWith creates independent copies of List, Set, and Map', () {
      final originalList = ['apple', 'banana'];
      final originalSet = {1, 2, 3};
      final originalMap = {'count': 42, 'role': 'admin'};
      final originalShallow = ['shallow1', 'shallow2'];

      final original = DeepCopyModel(
        tags: originalList,
        ids: originalSet,
        metadata: originalMap,
        shallowList: originalShallow,
      );

      // Clone without providing new arguments (pure copy)
      final cloned = original.copyWith();

      // Values should match
      expect(cloned.tags, equals(['apple', 'banana']));
      expect(cloned.ids, equals({1, 2, 3}));
      expect(cloned.metadata, equals({'count': 42, 'role': 'admin'}));
      expect(cloned.shallowList, equals(['shallow1', 'shallow2']));

      // Deep copied collections must be independent instances (not identical)
      expect(identical(original.tags, cloned.tags), isFalse);
      expect(identical(original.ids, cloned.ids), isFalse);
      expect(identical(original.metadata, cloned.metadata), isFalse);

      // Shallow list must be identical because of @CloneableField(deepCopy: false)
      expect(identical(original.shallowList, cloned.shallowList), isTrue);

      // Mutating cloned collections must NOT mutate original collections
      cloned.tags.add('cherry');
      cloned.ids.add(99);
      cloned.metadata['newKey'] = 'newValue';

      expect(original.tags, equals(['apple', 'banana']));
      expect(cloned.tags, equals(['apple', 'banana', 'cherry']));

      expect(original.ids, equals({1, 2, 3}));
      expect(cloned.ids, equals({1, 2, 3, 99}));

      expect(original.metadata.containsKey('newKey'), isFalse);
      expect(cloned.metadata['newKey'], equals('newValue'));
    });

    test('copyWith creates defensive copies of passed collections', () {
      const original = DeepCopyModel(
        tags: ['a'],
        ids: {1},
        metadata: {'k': 'v'},
        shallowList: ['s'],
      );

      final externalList = ['x', 'y'];
      final externalMap = {'score': 100};

      final cloned = original.copyWith(
        tags: externalList,
        optionalScores: externalMap,
      );

      expect(identical(externalList, cloned.tags), isFalse);
      expect(identical(externalMap, cloned.optionalScores), isFalse);

      // Mutating external collection does not affect cloned
      externalList.add('z');
      expect(cloned.tags, equals(['x', 'y']));
    });

    test('supports nullable collections and explicit null assignments', () {
      const original = DeepCopyModel(
        tags: ['a'],
        ids: {1},
        metadata: {},
        optionalTags: ['tag1', 'tag2'],
        optionalScores: {'math': 95},
        shallowList: [],
      );

      // Explicit null
      final withNulls = original.copyWith(
        optionalTags: null,
        optionalScores: null,
      );

      expect(withNulls.optionalTags, isNull);
      expect(withNulls.optionalScores, isNull);

      // Passing non-null values to optional collections
      final withValues = withNulls.copyWith(optionalTags: ['newTag']);

      expect(withValues.optionalTags, equals(['newTag']));
      expect(withValues.optionalScores, isNull);
    });
  });

  group('SelectiveDeepCopyModel (Field-level deepCopy: true)', () {
    test('only fields annotated with deepCopy: true are copied', () {
      final defaultList = ['def1', 'def2'];
      final deepList = ['deep1', 'deep2'];
      final map = {'env': 'prod'};

      final original = SelectiveDeepCopyModel(
        defaultTags: defaultList,
        deepTags: deepList,
        deepMap: map,
      );

      final cloned = original.copyWith();

      // defaultTags is shallow (identical)
      expect(identical(original.defaultTags, cloned.defaultTags), isTrue);

      // deepTags and deepMap are deep copied (not identical)
      expect(identical(original.deepTags, cloned.deepTags), isFalse);
      expect(identical(original.deepMap, cloned.deepMap), isFalse);

      // Mutating deepTags doesn't affect original
      cloned.deepTags.add('deep3');
      expect(original.deepTags, equals(['deep1', 'deep2']));
      expect(cloned.deepTags, equals(['deep1', 'deep2', 'deep3']));
    });
  });
}
