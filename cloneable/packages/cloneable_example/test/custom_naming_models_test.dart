import 'package:cloneable_example/models/custom_naming_models.dart';
import 'package:test/test.dart';

void main() {
  group('Custom Naming & Granular Prefix/Suffix Tests', () {
    test('CustomSuffixModel uses custom suffix Copyable in mixin', () {
      const model = CustomSuffixModel(name: 'Alice', count: 42);
      final updated = model.copyWith(name: 'Bob', count: 100);

      expect(updated.name, 'Bob');
      expect(updated.count, 100);
      expect(updated, isA<CustomSuffixModel>());
    });

    test(
        'CustomGranularModel uses custom extension and inline copyWith function',
        () {
      const model = CustomGranularModel(title: 'Initial');
      final updated = model.copyWith(title: 'Updated');

      expect(updated.title, 'Updated');

      // Verify strongly-typed inline copyWith function assignment
      final CustomGranularModel Function({String title}) fn = model.copyWith;
      final viaFn = fn(title: 'Via Function');
      expect(viaFn.title, 'Via Function');
    });
  });
}
