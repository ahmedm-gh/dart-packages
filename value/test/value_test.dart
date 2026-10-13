import 'package:test/test.dart';
import 'package:value/value.dart';

void main() {
  group('Val', () {
    test('Val wraps value correctly', () {
      const val = Val<String>('hello');
      expect(val.isAbsent, isFalse);
      expect(val('default'), equals('hello'));
    });

    test('Val.absent returns current value on call', () {
      const val = Val<String>.absent();
      expect(val.isAbsent, isTrue);
      expect(val('fallback'), equals('fallback'));
    });

    test('Val wraps null explicitly', () {
      const val = Val<String?>(null);
      expect(val.isAbsent, isFalse);
      expect(val('fallback'), isNull);
    });

    group('Equality and HashCode', () {
      test('reflexivity: an instance equals itself', () {
        const present = Val<int>(42);
        const absent = Val<int>.absent();
        const nullVal = Val<int?>(null);

        expect(present == present, isTrue);
        expect(absent == absent, isTrue);
        expect(nullVal == nullVal, isTrue);
      });

      test('symmetry: a == b implies b == a', () {
        const valA = Val<int>(10);
        const valB = Val<int>(10);
        const valC = Val<int>(20);

        expect(valA == valB, isTrue);
        expect(valB == valA, isTrue);

        expect(valA == valC, isFalse);
        expect(valC == valA, isFalse);

        const absentA = Val<String>.absent();
        const absentB = Val<String>.absent();
        expect(absentA == absentB, isTrue);
        expect(absentB == absentA, isTrue);
      });

      test('transitivity: a == b and b == c implies a == c', () {
        const a = Val<int>(100);
        const b = Val<num>(100);
        const c = Val<Object>(100);

        expect(a == b, isTrue);
        expect(b == c, isTrue);
        expect(a == c, isTrue);
      });

      test('non-nullity: val == null is always false', () {
        const present = Val<String>('text');
        const nullVal = Val<String?>(null);
        const absent = Val<String>.absent();

        expect(present, isNot(equals(null)));
        expect(nullVal, isNot(equals(null)));
        expect(absent, isNot(equals(null)));
      });

      test('type-safety: val == foreign object is false', () {
        const Object present = Val<int>(42);
        const Object absent = Val<int>.absent();
        const Object nullVal = Val<int?>(null);

        expect(present == 42, isFalse);
        expect(present == '42', isFalse);
        expect(absent == 'absent', isFalse);
        expect(nullVal == 0, isFalse);
      });

      test('Val(null) vs Val.absent() are strictly NOT equal', () {
        const nullVal = Val<String?>(null);
        const absent = Val<String?>.absent();

        expect(nullVal == absent, isFalse);
        expect(absent == nullVal, isFalse);
        expect(nullVal, isNot(equals(absent)));
      });

      test('cross-type equality for absent and equivalent values', () {
        // Val.absent() is equivalent across all type parameters
        const Object a1 = Val<String>.absent();
        const Object a2 = Val<int>.absent();
        expect(a1 == a2, isTrue);

        const Object a3 = Val<Object?>.absent();
        const Object a4 = Val<bool>.absent();
        expect(a3 == a4, isTrue);

        // Val(value) with subtype numbers
        expect(const Val<num>(42), equals(const Val<int>(42)));
        expect(const Val<int>(42), equals(const Val<num>(42)));
      });

      test('hashCode contract: equal instances must have equal hashCodes', () {
        const v1 = Val<int>(42);
        const v2 = Val<int>(42);
        expect(v1 == v2, isTrue);
        expect(v1.hashCode, equals(v2.hashCode));

        const Object n1 = Val<String?>(null);
        const Object n2 = Val<int?>(null);
        expect(n1 == n2, isTrue);
        expect(n1.hashCode, equals(n2.hashCode));

        const Object a1 = Val<String>.absent();
        const Object a2 = Val<int>.absent();
        expect(a1 == a2, isTrue);
        expect(a1.hashCode, equals(a2.hashCode));

        const cross1 = Val<num>(42);
        const cross2 = Val<int>(42);
        expect(cross1 == cross2, isTrue);
        expect(cross1.hashCode, equals(cross2.hashCode));
      });

      test('hashCode consistency: multiple calls return identical value', () {
        const v = Val<String>('consistent');
        const a = Val<String>.absent();
        const n = Val<String?>(null);

        expect(v.hashCode, equals(v.hashCode));
        expect(a.hashCode, equals(a.hashCode));
        expect(n.hashCode, equals(n.hashCode));
      });

      test('custom objects with value equality are respected', () {
        const item1 = _CustomItem('test', 1);
        const item2 = _CustomItem('test', 1);
        const item3 = _CustomItem('test', 2);

        expect(const Val(item1), equals(const Val(item2)));
        expect(const Val(item1).hashCode, equals(const Val(item2).hashCode));
        expect(const Val(item1), isNot(equals(const Val(item3))));
      });

      test('Set deduplication and Map lookup works accurately', () {
        final set = <Val<Object?>>{}
          ..add(const Val<int>(42))
          ..add(const Val<num>(42)) // duplicate of Val<int>(42)
          ..add(const Val<String?>('apple'))
          ..add(const Val<String?>('apple')) // duplicate
          ..add(const Val<int?>(null))
          ..add(const Val<String?>(null)) // duplicate of null
          ..add(const Val<int>.absent())
          ..add(const Val<String>.absent()); // duplicate of absent

        // Distinct elements: Val(42), Val('apple'), Val(null), Val.absent()
        expect(set.length, equals(4));
        expect(set.contains(const Val<int>(42)), isTrue);
        expect(set.contains(const Val<String>('apple')), isTrue);
        expect(set.contains(const Val<Object?>(null)), isTrue);
        expect(set.contains(const Val<bool>.absent()), isTrue);

        final map = <Val<Object?>, String>{
          const Val<int>(1): 'one',
          const Val<String?>('key'): 'value',
          const Val<Object?>.absent(): 'is-absent',
          const Val<Object?>(null): 'is-null',
        };

        expect(map[const Val<num>(1)], equals('one'));
        expect(map[const Val<String>('key')], equals('value'));
        expect(map[const Val<int>.absent()], equals('is-absent'));
        expect(map[const Val<String?>(null)], equals('is-null'));
      });
    });

    test('toString representation', () {
      expect(const Val('hi').toString(), equals('Val<String>(hi)'));
      expect(
        const Val<String>.absent().toString(),
        equals('Val<String>.absent()'),
      );
    });
  });
}

class _CustomItem {
  const _CustomItem(this.name, this.id);
  final String name;
  final int id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CustomItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          id == other.id;

  @override
  int get hashCode => Object.hash(name, id);
}
