import 'package:test/test.dart';
import 'package:value/value.dart';

void main() {
  group('Val', () {
    test('Val wraps value correctly', () {
      const val = Val<String>('hello');
      expect(val.value, equals('hello'));
      expect(val.isAbsent, isFalse);
      expect(val('default'), equals('hello'));
    });

    test('Val.absent returns current value on call', () {
      const val = Val<String>.absent();
      expect(val.value, isNull);
      expect(val.isAbsent, isTrue);
      expect(val('fallback'), equals('fallback'));
    });

    test('Val.clear explicitly sets null', () {
      const val = Val<String?>.clear();
      expect(val.value, isNull);
      expect(val.isAbsent, isFalse);
      expect(val('fallback'), isNull);
    });

    test('Val equality and hashCode', () {
      const val1 = Val<int>(42);
      const val2 = Val<int>(42);
      const val3 = Val<int>(7);
      const absent1 = Val<int>.absent();
      const absent2 = Val<int>.absent();
      const clear1 = Val<int?>.clear();

      expect(val1, equals(val2));
      expect(val1.hashCode, equals(val2.hashCode));
      expect(val1, isNot(equals(val3)));

      expect(absent1, equals(absent2));
      expect(absent1.hashCode, equals(absent2.hashCode));
      expect(absent1, isNot(equals(val1)));
      expect(absent1, isNot(equals(clear1)));

      expect(clear1, equals(const Val<int?>(null)));
    });

    test('toString representation', () {
      expect(const Val('hi').toString(), equals('Val<String>(hi)'));
      expect(const Val<String>.absent().toString(), equals('Absent<String>(null)'));
    });

    test('extension asVal', () {
      final val = 'example'.asVal;
      expect(val, isA<Val<String>>());
      expect(val.value, equals('example'));
      expect(val.isAbsent, isFalse);
    });
  });
}
