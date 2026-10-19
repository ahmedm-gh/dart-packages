import 'package:cloneable/cloneable.dart';

/// An example model annotated with [@Cloneable] for code generation.
///
/// Running `dart run build_runner build` (or `dart run cloneable_generator`)
/// will generate a strongly typed `copyWith` method for this class.
@Cloneable()
class User {
  final String name;
  final int age;
  final String? nickname;

  const User({
    required this.name,
    required this.age,
    this.nickname,
  });
}

void main() {
  const user = User(
    name: 'Ahmed',
    age: 25,
    nickname: 'Dev',
  );

  print('Original user: ${user.name}, age ${user.age}, nick: ${user.nickname}');
  print('Sentinel for explicit null support: ${$undefined}');
}
