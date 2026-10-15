const _sentinel = Object();

typedef UserCopyWith = User Function({
  String name,
  int age,
  String? nickname,
});

class User {
  final String name;
  final int age;
  final String? nickname;

  const User({required this.name, required this.age, this.nickname});

  UserCopyWith get copyWith => _copyWith;

  User _copyWith({
    Object? name = _sentinel,
    Object? age = _sentinel,
    Object? nickname = _sentinel,
  }) {
    return User(
      name: identical(name, _sentinel) ? this.name : name as String,
      age: identical(age, _sentinel) ? this.age : age as int,
      nickname:
          identical(nickname, _sentinel) ? this.nickname : nickname as String?,
    );
  }
}
