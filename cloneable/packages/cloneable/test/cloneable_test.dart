import 'package:cloneable/cloneable.dart';
import 'package:test/test.dart';

void main() {
  group('Cloneable Annotations', () {
    test(
        'Cloneable constructor defaults to null, deepCopyCollections to false, strategy to auto, ignoreNull to false, methodName to copyWith, sentinel to auto, active to true, fields to null, and cloneableFieldsGetter to null',
        () {
      const annotation = Cloneable();
      expect(annotation.constructor, isNull);
      expect(annotation.deepCopyCollections, isFalse);
      expect(annotation.strategy, equals(CloneableStrategy.auto));
      expect(annotation.ignoreNull, isFalse);
      expect(annotation.methodName, equals(Cloneable.defaultMethodName));
      expect(annotation.sentinel, equals(CloneableSentinel.auto));
      expect(annotation.active, isTrue);
      expect(annotation.inline, isFalse);
      expect(annotation.fields, isNull);
      expect(annotation.cloneableFieldsGetter, isNull);
      expect(
        Cloneable.defaultCloneableFieldsGetters,
        equals(['cloneableFields', 'copyWithFields']),
      );
      expect(Cloneable.defaultMethodName, equals('copyWith'));
    });

    test(
        'Cloneable custom constructor name, deepCopyCollections true, strategy extension, ignoreNull true, custom methodName, custom sentinel, active false, inline true, fields list, and custom cloneableFieldsGetter',
        () {
      const annotation = Cloneable(
        constructor: 'fromMap',
        deepCopyCollections: true,
        strategy: CloneableStrategy.extension,
        ignoreNull: true,
        methodName: 'clone',
        sentinel: CloneableSentinel.private,
        active: false,
        inline: true,
        fields: ['name', 'age'],
        cloneableFieldsGetter: 'customProps',
      );
      expect(annotation.constructor, equals('fromMap'));
      expect(annotation.deepCopyCollections, isTrue);
      expect(annotation.strategy, equals(CloneableStrategy.extension));
      expect(annotation.ignoreNull, isTrue);
      expect(annotation.methodName, equals('clone'));
      expect(annotation.sentinel, equals(CloneableSentinel.private));
      expect(annotation.active, isFalse);
      expect(annotation.inline, isTrue);
      expect(annotation.fields, equals(['name', 'age']));
      expect(annotation.cloneableFieldsGetter, equals('customProps'));
    });

    test('Cloneable accepts explicitly empty fields list', () {
      const a = Cloneable(fields: []);
      expect(a.fields, isEmpty);
      expect(a.fields, isNotNull);
    });

    test(
        'CloneableField defaults ignore to false, deepCopy to null, and ignoreNull to null',
        () {
      const field = CloneableField();
      expect(field.ignore, isFalse);
      expect(field.deepCopy, isNull);
      expect(field.ignoreNull, isNull);
    });

    test('CloneableField custom ignore, deepCopy, and ignoreNull', () {
      const field =
          CloneableField(ignore: true, deepCopy: true, ignoreNull: true);
      expect(field.ignore, isTrue);
      expect(field.deepCopy, isTrue);
      expect(field.ignoreNull, isTrue);
    });

    test('cloneableUndefined and undefined identity', () {
      expect(undefined, isNotNull);
      expect(identical(undefined, undefined), isTrue);
      expect(identical(undefined, cloneableUndefined), isTrue);
      expect(identical(undefined, null), isFalse);
      expect(identical(undefined, Object()), isFalse);
    });

    test('Cloneable.config and cloneable.config instantiation', () {
      const config1 = Cloneable.config(
        inline: true,
        deepCopyCollections: true,
        ignoreNull: true,
        methodName: 'clone',
        strategy: CloneableStrategy.extension,
        sentinel: CloneableSentinel.private,
      );
      expect(config1.inline, isTrue);
      expect(config1.deepCopyCollections, isTrue);
      expect(config1.ignoreNull, isTrue);
      expect(config1.methodName, equals('clone'));
      expect(config1.strategy, equals(CloneableStrategy.extension));
      expect(config1.sentinel, equals(CloneableSentinel.private));

      const config2 = Cloneable.config(inline: true);
      expect(config2.inline, isTrue);
      expect(config2.deepCopyCollections, isFalse);
    });
  });
}
