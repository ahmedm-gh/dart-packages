// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ignore_null_models.dart';

// **************************************************************************
// CloneableGenerator
// **************************************************************************

/// Strongly-typed copyWith function signature for [IgnoreNullModel].
typedef $IgnoreNullModelCopyWith = IgnoreNullModel Function({
  String normalField,
  String? ignoredNullField,
});

/// Generated cloneable mixin for [IgnoreNullModel].
mixin _$IgnoreNullModelCloneable {
  $IgnoreNullModelCopyWith get copyWith => _copyWith;

  IgnoreNullModel _copyWith({
    Object? normalField = cloneableUndefined,
    Object? ignoredNullField = cloneableUndefined,
  }) {
    final self = this as IgnoreNullModel;
    return IgnoreNullModel(
      normalField: identical(normalField, cloneableUndefined)
          ? self.normalField
          : normalField as String,
      ignoredNullField: identical(ignoredNullField, cloneableUndefined) ||
              ignoredNullField == null
          ? self.ignoredNullField
          : ignoredNullField as String?,
    );
  }
}

/// Strongly-typed copyWith function signature for [ClassLevelIgnoreNullModel].
typedef $ClassLevelIgnoreNullModelCopyWith = ClassLevelIgnoreNullModel
    Function({
  String? name,
  String? bio,
  int? score,
});

/// Generated cloneable mixin for [ClassLevelIgnoreNullModel].
mixin _$ClassLevelIgnoreNullModelCloneable {
  $ClassLevelIgnoreNullModelCopyWith get copyWith => _copyWith;

  ClassLevelIgnoreNullModel _copyWith({
    Object? name = cloneableUndefined,
    Object? bio = cloneableUndefined,
    Object? score = cloneableUndefined,
  }) {
    final self = this as ClassLevelIgnoreNullModel;
    return ClassLevelIgnoreNullModel(
      name: identical(name, cloneableUndefined) || name == null
          ? self.name
          : name as String,
      bio: identical(bio, cloneableUndefined) || bio == null
          ? self.bio
          : bio as String?,
      score: identical(score, cloneableUndefined) || score == null
          ? self.score
          : score as int?,
    );
  }
}
