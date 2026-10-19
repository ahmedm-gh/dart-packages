// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clean_models.dart';

/// Strongly-typed copyWith function signature for [CleanUser].
typedef $CleanUserCopyWithFn = CleanUser Function({
  String id,
  String name,
  int age,
  String? bio,
});

/// Generated cloneable extension for [CleanUser].
extension $CleanUserExtension on CleanUser {
  $CleanUserCopyWithFn get copyWith => _copyWith;

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

/// Strongly-typed copyWith function signature for [CleanProduct].
typedef $CleanProductCopyWithFn = CleanProduct Function({
  String sku,
  double price,
  List<String> tags,
});

/// Generated cloneable extension for [CleanProduct].
extension $CleanProductExtension on CleanProduct {
  $CleanProductCopyWithFn get copyWith => _copyWith;

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

/// Strongly-typed copyWith function signature for [ExtensionUser].
typedef $ExtensionUserCopyWithFn = ExtensionUser Function({
  String name,
  int age,
  String? nickname,
});

/// Generated cloneable extension for [ExtensionUser].
extension $ExtensionUserExtension on ExtensionUser {
  $ExtensionUserCopyWithFn get copyWith => _copyWith;

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

/// Strongly-typed copyWith function signature for [AliasedUserModel].
typedef $AliasedUserModelCopyWithFn = AliasedUserModel Function({
  String name,
  int age,
});

/// Generated cloneable extension for [AliasedUserModel].
extension $AliasedUserModelExtension on AliasedUserModel {
  $AliasedUserModelCopyWithFn get copyWith => _copyWith;

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

/// Strongly-typed copyWith function signature for [CustomPrefixUser].
typedef $CustomPrefixUserCopyWithFn = CustomPrefixUser Function({
  String name,
  String email,
});

/// Generated cloneable extension for [CustomPrefixUser].
extension CustomCustomPrefixUserExtension on CustomPrefixUser {
  $CustomPrefixUserCopyWithFn get copyWith => _copyWith;

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

/// Strongly-typed copyWith function signature for [CustomMixinUser].
typedef $CustomMixinUserCopyWithFn = CustomMixinUser Function({
  String name,
  String email,
});

/// Generated cloneable mixin for [CustomMixinUser].
mixin _CustomMixinUserCloneable {
  $CustomMixinUserCopyWithFn get copyWith => _copyWith;

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
