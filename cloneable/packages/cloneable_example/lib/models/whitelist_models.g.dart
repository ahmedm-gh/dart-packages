// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whitelist_models.dart';

/// Generated cloneable extension for [WhitelistAnnotationUser].
extension $WhitelistAnnotationUserExtension on WhitelistAnnotationUser {
  WhitelistAnnotationUser Function({String name, String? nickname})
      get copyWith => _copyWith;

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

/// Generated cloneable extension for [WhitelistGetterUser].
extension $WhitelistGetterUserExtension on WhitelistGetterUser {
  WhitelistGetterUser Function({String name, String? nickname}) get copyWith =>
      _copyWith;

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

/// Generated cloneable mixin for [WhitelistMixinUser].
mixin _$WhitelistMixinUserCloneable {
  WhitelistMixinUser Function({String name}) get copyWith => _copyWith;

  WhitelistMixinUser _copyWith({Object? name = $undefined}) {
    final self = this as WhitelistMixinUser;
    return WhitelistMixinUser(
      id: self.id,
      name: identical(name, $undefined) ? self.name : name as String,
    );
  }
}

/// Generated cloneable extension for [WhitelistCustomGetterUser].
extension $WhitelistCustomGetterUserExtension on WhitelistCustomGetterUser {
  WhitelistCustomGetterUser Function({String name}) get copyWith => _copyWith;

  WhitelistCustomGetterUser _copyWith({Object? name = $undefined}) {
    final self = this;
    return WhitelistCustomGetterUser(
      id: self.id,
      name: identical(name, $undefined) ? self.name : name as String,
    );
  }
}
