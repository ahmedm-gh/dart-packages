import 'package:cloneable/cloneable.dart';
import 'package:test/test.dart';

void main() {
  group('Cloneable Annotations', () {
    test(
        'Cloneable constructor defaults to null, deepCopyCollections to false, and strategy to auto',
        () {
      const annotation = Cloneable();
      expect(annotation.constructor, isNull);
      expect(annotation.deepCopyCollections, isFalse);
      expect(annotation.strategy, equals(CloneableStrategy.auto));
    });

    test(
        'Cloneable custom constructor name, deepCopyCollections true, and strategy extension',
        () {
      const annotation = Cloneable(
        constructor: 'fromMap',
        deepCopyCollections: true,
        strategy: CloneableStrategy.extension,
      );
      expect(annotation.constructor, equals('fromMap'));
      expect(annotation.deepCopyCollections, isTrue);
      expect(annotation.strategy, equals(CloneableStrategy.extension));
    });

    test('CloneableField defaults ignore to false and deepCopy to null', () {
      const field = CloneableField();
      expect(field.ignore, isFalse);
      expect(field.deepCopy, isNull);
    });

    test('CloneableField custom ignore and deepCopy', () {
      const field = CloneableField(ignore: true, deepCopy: true);
      expect(field.ignore, isTrue);
      expect(field.deepCopy, isTrue);
    });

    test('cloneableUndefined identity', () {
      expect(cloneableUndefined, isNotNull);
      expect(identical(cloneableUndefined, cloneableUndefined), isTrue);
      expect(identical(cloneableUndefined, null), isFalse);
      expect(identical(cloneableUndefined, Object()), isFalse);
    });
  });
}
