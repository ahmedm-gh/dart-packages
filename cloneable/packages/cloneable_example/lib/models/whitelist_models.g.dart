// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whitelist_models.dart';

/// Strongly-typed copyWith function signature for [WhitelistAnnotationUser].
typedef $WhitelistAnnotationUserCopyWithFn = WhitelistAnnotationUser Function({
  String name,
  String? nickname,
});

/// Generated cloneable extension for [WhitelistAnnotationUser].
extension $WhitelistAnnotationUserExtension on WhitelistAnnotationUser {
  $WhitelistAnnotationUserCopyWithFn get copyWith => _copyWith;

  WhitelistAnnotationUser _copyWith({
    Object? name = $undefined,
    Object? nickname = $undefined,
  }) {
    final self = this;
    return WhitelistAnnotationUser(
      id: self.id,
      name: identical(name, $undefined) ? self.name : name as String,
      nickname:
          identical(nickname, $undefined) ? self.nickname : nickname as String?,
    );
  }
}

/// Strongly-typed copyWith function signature for [WhitelistGetterUser].
typedef $WhitelistGetterUserCopyWithFn = WhitelistGetterUser Function({
  String name,
  String? nickname,
});

/// Generated cloneable extension for [WhitelistGetterUser].
extension $WhitelistGetterUserExtension on WhitelistGetterUser {
  $WhitelistGetterUserCopyWithFn get copyWith => _copyWith;

  WhitelistGetterUser _copyWith({
    Object? name = $undefined,
    Object? nickname = $undefined,
  }) {
    final self = this;
    return WhitelistGetterUser(
      id: self.id,
      name: identical(name, $undefined) ? self.name : name as String,
      nickname:
          identical(nickname, $undefined) ? self.nickname : nickname as String?,
    );
  }
}

/// Strongly-typed copyWith function signature for [WhitelistMixinUser].
typedef $WhitelistMixinUserCopyWithFn = WhitelistMixinUser Function({
  String name,
});

/// Generated cloneable mixin for [WhitelistMixinUser].
mixin _$WhitelistMixinUserCloneable {
  $WhitelistMixinUserCopyWithFn get copyWith => _copyWith;

  WhitelistMixinUser _copyWith({
    Object? name = $undefined,
  }) {
    final self = this as WhitelistMixinUser;
    return WhitelistMixinUser(
      id: self.id,
      name: identical(name, $undefined) ? self.name : name as String,
    );
  }
}

/// Strongly-typed copyWith function signature for [WhitelistCustomGetterUser].
typedef $WhitelistCustomGetterUserCopyWithFn = WhitelistCustomGetterUser
    Function({
  String name,
});

/// Generated cloneable extension for [WhitelistCustomGetterUser].
extension $WhitelistCustomGetterUserExtension on WhitelistCustomGetterUser {
  $WhitelistCustomGetterUserCopyWithFn get copyWith => _copyWith;

  WhitelistCustomGetterUser _copyWith({
    Object? name = $undefined,
  }) {
    final self = this;
    return WhitelistCustomGetterUser(
      id: self.id,
      name: identical(name, $undefined) ? self.name : name as String,
    );
  }
}
