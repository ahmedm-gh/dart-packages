import 'package:cloneable/cloneable.dart';
import 'package:test/test.dart';

void main() {
  group('Cloneable Advanced Enums', () {
    test('CloneableOutput isInline', () {
      expect(CloneableOutput.auto.isInline, isFalse);
      expect(CloneableOutput.part.isInline, isFalse);
      expect(CloneableOutput.standalone.isInline, isFalse);
      expect(CloneableOutput.inLibrary.isInline, isTrue);
      expect(CloneableOutput.inClass.isInline, isTrue);
    });

    test('CloneableCleanup enum values', () {
      expect(CloneableCleanup.values, contains(CloneableCleanup.none));
      expect(CloneableCleanup.values, contains(CloneableCleanup.deactivate));
      expect(CloneableCleanup.values, contains(CloneableCleanup.remove));
    });
  });

  group('Cloneable Annotations', () {
    test('Cloneable constructor defaults to null for unassigned properties',
        () {
      const annotation = Cloneable();
      expect(annotation.constructor, isNull);
      expect(annotation.deepCopyCollections, isNull);
      expect(annotation.strategy, isNull);
      expect(annotation.ignoreNull, isNull);
      expect(annotation.sentinel, isNull);
      expect(annotation.active, isNull);
      expect(annotation.cleanup, isNull);
      expect(annotation.output, isNull);
      expect(annotation.fields, isNull);
      expect(annotation.cloneableFieldsGetter, isNull);
      expect(annotation.fieldsConflict, isNull);
      expect(annotation.naming, isNull);
      expect(CloneableNaming.defaultDirectory, isNull);
      expect(CloneableNaming.defaults, equals(const CloneableNaming()));
      expect(CloneableNaming.defaultSentinel, equals(r'_$undefined'));
      expect($undefined, isNotNull);
      expect(
        Cloneable.defaultCloneableFieldsGetters,
        equals(['cloneableFields', 'copyWithFields']),
      );
    });

    test('CloneableDefaults SSOT default values', () {
      const defaults = CloneableDefaults();
      expect(defaults.output, equals(CloneableOutput.auto));
      expect(defaults.strategy, equals(CloneableStrategy.auto));
      expect(defaults.sentinel, equals(CloneableSentinel.auto));
      expect(defaults.deepCopyCollections, isFalse);
      expect(defaults.ignoreNull, isFalse);
      expect(defaults.active, isTrue);
      expect(defaults.cleanup, equals(CloneableCleanup.none));
      expect(defaults.fieldsConflict, equals(CloneableFieldsConflict.error));
      expect(defaults.naming, equals(const CloneableNaming()));
      expect(CloneableDefaults.instance, equals(const CloneableDefaults()));
    });

    test('Cloneable.defaults instantiation and Cloneable.setDefaults', () {
      const customDefaults = Cloneable.defaults(
        output: CloneableOutput.inClass,
        sentinel: CloneableSentinel.private,
        cleanup: CloneableCleanup.deactivate,
        deepCopyCollections: true,
        ignoreNull: true,
        strategy: CloneableStrategy.extension,
        naming: CloneableNaming(
          method: 'clone',
          mixin: CloneableAffix(prefix: '_Gen', suffix: 'Mixin'),
        ),
      );
      expect(customDefaults.output, equals(CloneableOutput.inClass));
      expect(customDefaults.sentinel, equals(CloneableSentinel.private));
      expect(customDefaults.cleanup, equals(CloneableCleanup.deactivate));
      expect(customDefaults.deepCopyCollections, isTrue);
      expect(customDefaults.ignoreNull, isTrue);
      expect(customDefaults.strategy, equals(CloneableStrategy.extension));
      expect(customDefaults.naming?.method, equals('clone'));

      // Test programmatic runtime setter with cleanup
      Cloneable.setDefaults(
        output: CloneableOutput.inLibrary,
        cleanup: CloneableCleanup.remove,
      );
      expect(
          CloneableDefaults.instance.output, equals(CloneableOutput.inLibrary));
      expect(
          CloneableDefaults.instance.cleanup, equals(CloneableCleanup.remove));

      // Reset back to standard defaults
      CloneableDefaults.setDefaults(const CloneableDefaults());
      expect(CloneableDefaults.instance, equals(const CloneableDefaults()));
    });

    test('Cloneable named constructors', () {
      const inClass = Cloneable.inClass(
        cleanup: CloneableCleanup.remove,
        naming: CloneableNaming(
          method: 'clone',
        ),
      );
      expect(inClass.output, equals(CloneableOutput.inClass));
      expect(inClass.strategy, isNull);
      expect(inClass.cleanup, equals(CloneableCleanup.remove));
      expect(inClass.naming?.method, equals('clone'));

      const inLibrary = Cloneable.inLibrary(
        strategy: CloneableStrategy.mixin,
      );
      expect(inLibrary.output, equals(CloneableOutput.inLibrary));
      expect(inLibrary.strategy, equals(CloneableStrategy.mixin));

      const part = Cloneable.part(
        deepCopyCollections: true,
      );
      expect(part.output, equals(CloneableOutput.part));
      expect(part.deepCopyCollections, isTrue);

      const standalone = Cloneable.standalone();
      expect(standalone.output, equals(CloneableOutput.standalone));
      expect(standalone.strategy, equals(CloneableStrategy.extension));
    });

    test(
        'CloneableAffix partial overrides preserve null for unspecified affixes',
        () {
      const prefixOnly = CloneableAffix(prefix: 'Pre');
      expect(prefixOnly.prefix, equals('Pre'));
      expect(prefixOnly.suffix, isNull);

      const suffixOnly = CloneableAffix(suffix: 'Suf');
      expect(suffixOnly.prefix, isNull);
      expect(suffixOnly.suffix, equals('Suf'));

      const explicitEmpty = CloneableAffix(prefix: 'Pre', suffix: '');
      expect(explicitEmpty.prefix, equals('Pre'));
      expect(explicitEmpty.suffix, equals(''));

      expect(CloneableNaming.defaultFile.suffix, equals('.cloneable.g'));
    });

    test('Cloneables map configuration', () {
      const cloneables = Cloneables({
        String: Cloneable(deepCopyCollections: true),
        int: Cloneable.inClass(ignoreNull: true),
      });

      expect(cloneables.entities, hasLength(2));
      expect(cloneables.entities[String]?.deepCopyCollections, isTrue);
      expect(cloneables.entities[int]?.output, equals(CloneableOutput.inClass));
      expect(cloneables.entities[int]?.ignoreNull, isTrue);
    });

    test('CloneableField properties, cloner, and equality', () {
      const defaultField = CloneableField();
      expect(defaultField.ignore, isFalse);
      expect(defaultField.deepCopy, isNull);
      expect(defaultField.ignoreNull, isNull);
      expect(defaultField.cloner, isNull);

      int customCloner(int v) => v;
      final customField = CloneableField(
        ignore: true,
        deepCopy: true,
        ignoreNull: true,
        cloner: customCloner,
      );
      expect(customField.ignore, isTrue);
      expect(customField.deepCopy, isTrue);
      expect(customField.ignoreNull, isTrue);
      expect(customField.cloner, equals(customCloner));
      expect(customField.toString(), contains('cloner'));
    });
  });
}
