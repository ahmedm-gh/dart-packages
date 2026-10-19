// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ignore_null_models.dart';

/// Strongly-typed copyWith function signature for [IgnoreNullModel].
typedef $IgnoreNullModelCopyWithFn = IgnoreNullModel Function({
  String normalField,
  String? ignoredNullField,
});

/// Generated cloneable mixin for [IgnoreNullModel].
mixin _$IgnoreNullModelCloneable {
  $IgnoreNullModelCopyWithFn get copyWith => _copyWith;

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

/// Strongly-typed copyWith function signature for [ClassLevelIgnoreNullModel].
typedef $ClassLevelIgnoreNullModelCopyWithFn = ClassLevelIgnoreNullModel
    Function({
  String? name,
  String? bio,
  int? score,
});

/// Generated cloneable mixin for [ClassLevelIgnoreNullModel].
mixin _$ClassLevelIgnoreNullModelCloneable {
  $ClassLevelIgnoreNullModelCopyWithFn get copyWith => _copyWith;

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
      bio:
          identical(bio, $undefined) || bio == null ? self.bio : bio as String?,
      score: identical(score, $undefined) || score == null
          ? self.score
          : score as int?,
    );
  }
}
