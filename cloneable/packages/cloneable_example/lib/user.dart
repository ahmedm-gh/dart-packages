class User {
  final String name;
  final int age;
  final String? nickname;

  const User({required this.name, required this.age, this.nickname});
}

const _$undefined = Object();

/// Strongly-typed copyWith function signature for [User].
typedef $UserCopyWithFn = User Function({
  String name,
  int age,
  String? nickname,
});

/// Generated cloneable extension for [User].
extension $UserExtension on User {
  $UserCopyWithFn get copyWith => _copyWith;

  User _copyWith({
    Object? name = _$undefined,
    Object? age = _$undefined,
    Object? nickname = _$undefined,
  }) {
    final self = this;
    return User(
      name: identical(name, _$undefined) ? self.name : name as String,
      age: identical(age, _$undefined) ? self.age : age as int,
      nickname: identical(nickname, _$undefined)
          ? self.nickname
          : nickname as String?,
    );
  }
}
