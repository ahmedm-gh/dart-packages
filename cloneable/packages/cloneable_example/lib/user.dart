import 'package:cloneable/cloneable.dart';

part 'user.g.dart';

@Cloneable()
class User with _$UserCloneable {
  final String name;
  final int age;
  final String? nickname;

  const User({
    required this.name,
    required this.age,
    this.nickname,
  });
}
