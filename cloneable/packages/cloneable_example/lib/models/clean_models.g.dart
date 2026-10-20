// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clean_models.dart';

/// Generated cloneable extension for [CleanUser].
extension $CleanUserExtension on CleanUser {
  CleanUser Function({String id, String name, int age, String? bio})
      get copyWith => _copyWith;

  CleanUser _copyWith({
    Object? id = $undefined,
    Object? name = $undefined,
    Object? age = $undefined,
    Object? bio = $undefined,
  }) {
    final self = this;
    return CleanUser(
      id: identical(id, $undefined) ? self.id : id as String,
      name: identical(name, $undefined) ? self.name : name as String,
      age: identical(age, $undefined) ? self.age : age as int,
      bio: identical(bio, $undefined) ? self.bio : bio as String?,
    );
  }
}

/// Generated cloneable extension for [CleanProduct].
extension $CleanProductExtension on CleanProduct {
  CleanProduct Function({String sku, double price, List<String> tags})
      get copyWith => _copyWith;

  CleanProduct _copyWith({
    Object? sku = $undefined,
    Object? price = $undefined,
    Object? tags = $undefined,
  }) {
    final self = this;
    return CleanProduct(
      sku: identical(sku, $undefined) ? self.sku : sku as String,
      price: identical(price, $undefined) ? self.price : price as double,
      tags: identical(tags, $undefined)
          ? List.of(self.tags)
          : List.of(tags as List<String>),
    );
  }
}

/// Generated cloneable extension for [ExtensionUser].
extension $ExtensionUserExtension on ExtensionUser {
  ExtensionUser Function({String name, int age, String? nickname})
      get copyWith => _copyWith;

  ExtensionUser _copyWith({
    Object? name = $undefined,
    Object? age = $undefined,
    Object? nickname = $undefined,
  }) {
    final self = this;
    return ExtensionUser(
      name: identical(name, $undefined) ? self.name : name as String,
      age: identical(age, $undefined) ? self.age : age as int,
      nickname:
          identical(nickname, $undefined) ? self.nickname : nickname as String?,
    );
  }
}

/// Generated cloneable extension for [AliasedUserModel].
extension $AliasedUserModelExtension on AliasedUserModel {
  AliasedUserModel Function({String name, int age}) get copyWith => _copyWith;

  AliasedUserModel _copyWith({
    Object? name = $undefined,
    Object? age = $undefined,
  }) {
    final self = this;
    return AliasedUserModel(
      name: identical(name, $undefined) ? self.name : name as String,
      age: identical(age, $undefined) ? self.age : age as int,
    );
  }
}

/// Generated cloneable extension for [CustomPrefixUser].
extension CustomCustomPrefixUserExtension on CustomPrefixUser {
  CustomPrefixUser Function({String name, String email}) get copyWith =>
      _copyWith;

  CustomPrefixUser _copyWith({
    Object? name = $undefined,
    Object? email = $undefined,
  }) {
    final self = this;
    return CustomPrefixUser(
      name: identical(name, $undefined) ? self.name : name as String,
      email: identical(email, $undefined) ? self.email : email as String,
    );
  }
}

/// Generated cloneable mixin for [CustomMixinUser].
mixin _CustomMixinUserCloneable {
  CustomMixinUser Function({String name, String email}) get copyWith =>
      _copyWith;

  CustomMixinUser _copyWith({
    Object? name = $undefined,
    Object? email = $undefined,
  }) {
    final self = this as CustomMixinUser;
    return CustomMixinUser(
      name: identical(name, $undefined) ? self.name : name as String,
      email: identical(email, $undefined) ? self.email : email as String,
    );
  }
}
