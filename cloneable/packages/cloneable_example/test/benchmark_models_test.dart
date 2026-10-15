import 'package:cloneable_example/models/benchmark_models.dart';
import 'package:test/test.dart';

void main() {
  group('MediumModel (10 fields) and LargeModel (25 fields) Tests', () {
    test('MediumModel copyWith works with 10 fields and explicit nulls', () {
      const model = MediumModel(
        f1: 'hello',
        f2: 42,
        f3: 3.14,
        f4: true,
        f5: 'nullable',
        f6: 10,
        f7: 2.5,
        f8: false,
        f9: ['a', 'b'],
        f10: {'k': 1},
      );

      final updated = model.copyWith(
        f1: 'world',
        f5: null, // explicit null
        f6: null, // explicit null
        f9: ['c', 'd'],
      );

      expect(updated.f1, equals('world'));
      expect(updated.f2, equals(42));
      expect(updated.f3, equals(3.14));
      expect(updated.f4, isTrue);
      expect(updated.f5, isNull);
      expect(updated.f6, isNull);
      expect(updated.f7, equals(2.5));
      expect(updated.f8, isFalse);
      expect(updated.f9, equals(['c', 'd']));
      expect(updated.f10, equals({'k': 1}));
    });

    test('LargeModel copyWith works with 25 fields and explicit nulls', () {
      const model = LargeModel(
        s1: 's1',
        s2: 's2',
        s3: 's3',
        s4: 's4',
        s5: 's5',
        i1: 1,
        i2: 2,
        i3: 3,
        i4: 4,
        i5: 5,
        d1: 1.1,
        d2: 2.2,
        d3: 3.3,
        d4: 4.4,
        d5: 5.5,
        b1: true,
        b2: false,
        b3: true,
        b4: false,
        b5: true,
        opt1: 'opt1',
        opt2: 'opt2',
        opt3: 33,
        opt4: 4.4,
        opt5: true,
      );

      final updated = model.copyWith(
        s1: 's1_updated',
        i3: 300,
        d5: 55.55,
        opt1: null, // explicit null
        opt3: null, // explicit null
        opt5: false,
      );

      expect(updated.s1, equals('s1_updated'));
      expect(updated.s2, equals('s2'));
      expect(updated.i3, equals(300));
      expect(updated.d5, equals(55.55));
      expect(updated.opt1, isNull);
      expect(updated.opt2, equals('opt2'));
      expect(updated.opt3, isNull);
      expect(updated.opt4, equals(4.4));
      expect(updated.opt5, isFalse);
    });
  });
}
