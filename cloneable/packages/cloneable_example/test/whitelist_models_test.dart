import 'package:cloneable_example/models/whitelist_models.dart';
import 'package:test/test.dart';

void main() {
  group('Whitelist fields Models Tests', () {
    test('WhitelistAnnotationUser copyWith only allows name and nickname, preserves id', () {
      const user = WhitelistAnnotationUser(
        id: 'usr_123',
        name: 'Ahmed',
        nickname: 'Dev',
      );

      final updated = user.copyWith(name: 'Mohamed');
      expect(updated.id, equals('usr_123'));
      expect(updated.name, equals('Mohamed'));
      expect(updated.nickname, equals('Dev'));

      final cleared = user.copyWith(nickname: null);
      expect(cleared.id, equals('usr_123'));
      expect(cleared.name, equals('Ahmed'));
      expect(cleared.nickname, isNull);
    });

    test('WhitelistGetterUser copyWith only allows name and nickname from in-class cloneableFields getter', () {
      const user = WhitelistGetterUser(
        id: 'usr_456',
        name: 'Alice',
        nickname: 'Ali',
      );

      final updated = user.copyWith(name: 'Bob');
      expect(updated.id, equals('usr_456'));
      expect(updated.name, equals('Bob'));
      expect(updated.nickname, equals('Ali'));

      final cleared = user.copyWith(nickname: null);
      expect(cleared.id, equals('usr_456'));
      expect(cleared.name, equals('Alice'));
      expect(cleared.nickname, isNull);
    });

    test('WhitelistMixinUser copyWith with mixin only allows name from in-class copyWithFields getter', () {
      const user = WhitelistMixinUser(id: 'usr_789', name: 'Charlie');

      final updated = user.copyWith(name: 'David');
      expect(updated.id, equals('usr_789'));
      expect(updated.name, equals('David'));
    });

    test('WhitelistCustomGetterUser copyWith only allows name from in-class supportedProps getter', () {
      const user = WhitelistCustomGetterUser(id: 'usr_101', name: 'Eve');

      final updated = user.copyWith(name: 'Frank');
      expect(updated.id, equals('usr_101'));
      expect(updated.name, equals('Frank'));
    });
  });
}
