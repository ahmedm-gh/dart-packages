// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ignore_null_models.dart';

/// Generated cloneable mixin for [IgnoreNullModel].
mixin _$IgnoreNullModelCloneable {
  IgnoreNullModel Function({String normalField, String? ignoredNullField})
  get copyWith => _copyWith;

  IgnoreNullModel _copyWith({
    Object? normalField = $undefined,
    Object? ignoredNullField = $undefined,
  }) {
    final self = this as IgnoreNullModel;
    return IgnoreNullModel(
      normalField: identical(normalField, $undefined)
          ? self.normalField
          : normalField as String,
      ignoredNullField:
          identical(ignoredNullField, $undefined) || ignoredNullField == null
          ? self.ignoredNullField
          : ignoredNullField as String?,
    );
  }
}

/// Generated cloneable mixin for [ClassLevelIgnoreNullModel].
mixin _$ClassLevelIgnoreNullModelCloneable {
  ClassLevelIgnoreNullModel Function({String? name, String? bio, int? score})
  get copyWith => _copyWith;

  ClassLevelIgnoreNullModel _copyWith({
    Object? name = $undefined,
    Object? bio = $undefined,
    Object? score = $undefined,
  }) {
    final self = this as ClassLevelIgnoreNullModel;
    return ClassLevelIgnoreNullModel(
      name: identical(name, $undefined) || name == null
          ? self.name
          : name as String,
      bio: identical(bio, $undefined) || bio == null
          ? self.bio
          : bio as String?,
      score: identical(score, $undefined) || score == null
          ? self.score
          : score as int?,
    );
  }
}
