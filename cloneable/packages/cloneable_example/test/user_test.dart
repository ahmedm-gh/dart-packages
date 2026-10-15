import 'package:cloneable_example/user.dart';
import 'package:test/test.dart';

void main() {
  group('User copyWith - Primary Developer Experience', () {
    test('User copyWith updates fields and preserves omitted fields', () {
      const original = User(
        name: 'Ahmed',
        age: 25,
        nickname: 'Dev',
      );

      final updated = original.copyWith(
        name: 'Mohamed',
        age: 26,
      );

      expect(updated.name, equals('Mohamed'));
      expect(updated.age, equals(26));
      expect(updated.nickname, equals('Dev')); // Preserved!

      // Original remains unchanged
      expect(original.name, equals('Ahmed'));
      expect(original.age, equals(25));
      expect(original.nickname, equals('Dev'));
    });

    test('User copyWith explicitly clears nullable field to null', () {
      const original = User(
        name: 'Ahmed',
        age: 25,
        nickname: 'Dev',
      );

      final cleared = original.copyWith(
        nickname: null,
      );

      expect(cleared.name, equals('Ahmed')); // Preserved
      expect(cleared.age, equals(25)); // Preserved
      expect(cleared.nickname, isNull); // Explicitly set to null!

      // Original remains unchanged
      expect(original.nickname, equals('Dev'));
    });

    test('User copyWith replaces nullable field with new non-null value', () {
      const original = User(
        name: 'Ahmed',
        age: 25,
        nickname: null,
      );

      final updated = original.copyWith(
        nickname: 'SuperDev',
      );

      expect(updated.nickname, equals('SuperDev'));
      expect(original.nickname, isNull);
    });

    test(
        'User copyWith with no arguments returns identical data in new instance',
        () {
      const original = User(
        name: 'Ahmed',
        age: 25,
        nickname: 'Dev',
      );

      final clone = original.copyWith();

      expect(clone.name, equals('Ahmed'));
      expect(clone.age, equals(25));
      expect(clone.nickname, equals('Dev'));
    });
  });
}
