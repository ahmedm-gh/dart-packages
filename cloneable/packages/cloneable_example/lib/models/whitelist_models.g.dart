// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whitelist_models.dart';

// **************************************************************************
// CloneableGenerator
// **************************************************************************

/// Strongly-typed copyWith function signature for [WhitelistAnnotationUser].
typedef $WhitelistAnnotationUserCopyWith = WhitelistAnnotationUser Function({
  String name,
  String? nickname,
});

/// Generated cloneable extension for [WhitelistAnnotationUser].
extension $WhitelistAnnotationUserCloneableExtension
    on WhitelistAnnotationUser {
  $WhitelistAnnotationUserCopyWith get copyWith => _copyWith;

  WhitelistAnnotationUser _copyWith({
    Object? name = cloneableUndefined,
    Object? nickname = cloneableUndefined,
  }) {
    final self = this;
    return WhitelistAnnotationUser(
      id: self.id,
      name: identical(name, cloneableUndefined) ? self.name : name as String,
      nickname: identical(nickname, cloneableUndefined)
          ? self.nickname
          : nickname as String?,
    );
  }
}

/// Strongly-typed copyWith function signature for [WhitelistGetterUser].
typedef $WhitelistGetterUserCopyWith = WhitelistGetterUser Function({
  String name,
  String? nickname,
});

/// Generated cloneable extension for [WhitelistGetterUser].
extension $WhitelistGetterUserCloneableExtension on WhitelistGetterUser {
  $WhitelistGetterUserCopyWith get copyWith => _copyWith;

  WhitelistGetterUser _copyWith({
    Object? name = cloneableUndefined,
    Object? nickname = cloneableUndefined,
  }) {
    final self = this;
    return WhitelistGetterUser(
      id: self.id,
      name: identical(name, cloneableUndefined) ? self.name : name as String,
      nickname: identical(nickname, cloneableUndefined)
          ? self.nickname
          : nickname as String?,
    );
  }
}

/// Strongly-typed copyWith function signature for [WhitelistMixinUser].
typedef $WhitelistMixinUserCopyWith = WhitelistMixinUser Function({
  String name,
});

/// Generated cloneable mixin for [WhitelistMixinUser].
mixin _$WhitelistMixinUserCloneable {
  $WhitelistMixinUserCopyWith get copyWith => _copyWith;

  WhitelistMixinUser _copyWith({
    Object? name = cloneableUndefined,
  }) {
    final self = this as WhitelistMixinUser;
    return WhitelistMixinUser(
      id: self.id,
      name: identical(name, cloneableUndefined) ? self.name : name as String,
    );
  }
}

/// Strongly-typed copyWith function signature for [WhitelistCustomGetterUser].
typedef $WhitelistCustomGetterUserCopyWith = WhitelistCustomGetterUser
    Function({
  String name,
});

/// Generated cloneable extension for [WhitelistCustomGetterUser].
extension $WhitelistCustomGetterUserCloneableExtension
    on WhitelistCustomGetterUser {
  $WhitelistCustomGetterUserCopyWith get copyWith => _copyWith;

  WhitelistCustomGetterUser _copyWith({
    Object? name = cloneableUndefined,
  }) {
    final self = this;
    return WhitelistCustomGetterUser(
      id: self.id,
      name: identical(name, cloneableUndefined) ? self.name : name as String,
    );
  }
}
