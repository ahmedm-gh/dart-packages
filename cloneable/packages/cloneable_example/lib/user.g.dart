// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

/// Strongly-typed copyWith function signature for [User].
typedef $UserCopyWith = User Function({
  String name,
  int age,
  String? nickname,
});

/// Generated cloneable mixin for [User].
mixin _$UserCloneable {
  $UserCopyWith get copyWith => _copyWith;

  User _copyWith({
    Object? name = cloneableUndefined,
    Object? age = cloneableUndefined,
    Object? nickname = cloneableUndefined,
  }) {
    final self = this as User;
    return User(
      name: identical(name, cloneableUndefined) ? self.name : name as String,
      age: identical(age, cloneableUndefined) ? self.age : age as int,
      nickname: identical(nickname, cloneableUndefined)
          ? self.nickname
          : nickname as String?,
    );
  }
}
