import 'package:cloneable_example/models/inline_model.dart';
import 'package:test/test.dart';

void main() {
  group('InlineUser copyWith tests', () {
    test('updates properties and explicitly clears nullable email to null', () {
      const user = InlineUser(
        id: '1',
        name: 'Alice',
        email: 'alice@example.com',
      );

      final updated = user.copyWith(name: 'Bob');
      expect(updated.id, equals('1'));
      expect(updated.name, equals('Bob'));
      expect(updated.email, equals('alice@example.com'));

      final withoutEmail = user.copyWith(email: null);
      expect(withoutEmail.id, equals('1'));
      expect(withoutEmail.name, equals('Alice'));
      expect(withoutEmail.email, isNull);
    });

    test('CustomInlineConfig works with custom prefix in inline approach', () {
      const config = CustomInlineConfig(key: 'mode', value: 'dark');
      final updated = config.copyWith(value: 'light');
      expect(updated.key, equals('mode'));
      expect(updated.value, equals('light'));
    });
  });
}
