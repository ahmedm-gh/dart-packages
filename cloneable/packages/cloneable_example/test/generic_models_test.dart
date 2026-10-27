import 'package:cloneable_example/models/generic_models.dart';
import 'package:test/test.dart';

void main() {
  group('Generic Models copyWith', () {
    test('Box<T> preserves and updates values with explicit null', () {
      const box = Box<String>(
        value: 'Dart',
        optionalValue: 'Flutter',
        tag: 'Frameworks',
      );

      final updated = box.copyWith(value: 'Rust', optionalValue: null);

      expect(updated.value, equals('Rust'));
      expect(updated.optionalValue, isNull);
      expect(updated.tag, equals('Frameworks'));

      // Original unchanged
      expect(box.value, equals('Dart'));
      expect(box.optionalValue, equals('Flutter'));
    });

    test('Box<int> with integer generic type', () {
      const box = Box<int>(value: 100, optionalValue: 200, tag: 'Numbers');

      final updated = box.copyWith(optionalValue: null);
      expect(updated.value, equals(100));
      expect(updated.optionalValue, isNull);
      expect(updated.tag, equals('Numbers'));
    });

    test(
      'BoundedBox<T extends num> preserves bounds and updates correctly',
      () {
        const doubleBox = BoundedBox<double>(number: 3.14159, label: 'Pi');

        final updated = doubleBox.copyWith(number: 2.71828);

        expect(updated.number, equals(2.71828));
        expect(updated.label, equals('Pi'));
        expect(doubleBox.number, equals(3.14159));
      },
    );

    test('Pair<A, B> handles multi-type generic parameters', () {
      const pair = Pair<int, String>(first: 1, second: 'One');

      final updated = pair.copyWith(second: 'First');
      expect(updated.first, equals(1));
      expect(updated.second, equals('First'));
      expect(pair.second, equals('One'));
    });
  });
}
