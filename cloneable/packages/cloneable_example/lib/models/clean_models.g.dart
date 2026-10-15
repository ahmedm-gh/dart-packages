// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clean_models.dart';

// **************************************************************************
// CloneableGenerator
// **************************************************************************

/// Strongly-typed copyWith function signature for [CleanUser].
typedef $CleanUserCopyWith = CleanUser Function({
  String id,
  String name,
  int age,
  String? bio,
});

/// Generated cloneable extension for [CleanUser].
extension $CleanUserCloneableExtension on CleanUser {
  $CleanUserCopyWith get copyWith => _copyWith;

  CleanUser _copyWith({
    Object? id = cloneableUndefined,
    Object? name = cloneableUndefined,
    Object? age = cloneableUndefined,
    Object? bio = cloneableUndefined,
  }) {
    final self = this;
    return CleanUser(
      id: identical(id, cloneableUndefined) ? self.id : id as String,
      name: identical(name, cloneableUndefined) ? self.name : name as String,
      age: identical(age, cloneableUndefined) ? self.age : age as int,
      bio: identical(bio, cloneableUndefined) ? self.bio : bio as String?,
    );
  }
}

/// Strongly-typed copyWith function signature for [CleanProduct].
typedef $CleanProductCopyWith = CleanProduct Function({
  String sku,
  double price,
  List<String> tags,
});

/// Generated cloneable extension for [CleanProduct].
extension $CleanProductCloneableExtension on CleanProduct {
  $CleanProductCopyWith get copyWith => _copyWith;

  CleanProduct _copyWith({
    Object? sku = cloneableUndefined,
    Object? price = cloneableUndefined,
    Object? tags = cloneableUndefined,
  }) {
    final self = this;
    return CleanProduct(
      sku: identical(sku, cloneableUndefined) ? self.sku : sku as String,
      price:
          identical(price, cloneableUndefined) ? self.price : price as double,
      tags: identical(tags, cloneableUndefined)
          ? List.of(self.tags)
          : List.of(tags as List<String>),
    );
  }
}
