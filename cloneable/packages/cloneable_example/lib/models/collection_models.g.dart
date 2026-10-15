// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_models.dart';

// **************************************************************************
// CloneableGenerator
// **************************************************************************

/// Strongly-typed copyWith function signature for [DeepCopyModel].
typedef $DeepCopyModelCopyWith = DeepCopyModel Function({
  List<String> tags,
  Set<int> ids,
  Map<String, dynamic> metadata,
  List<String>? optionalTags,
  Map<String, int>? optionalScores,
  List<String> shallowList,
});

/// Generated cloneable mixin for [DeepCopyModel].
mixin _$DeepCopyModelCloneable {
  $DeepCopyModelCopyWith get copyWith => _copyWith;

  DeepCopyModel _copyWith({
    Object? tags = cloneableUndefined,
    Object? ids = cloneableUndefined,
    Object? metadata = cloneableUndefined,
    Object? optionalTags = cloneableUndefined,
    Object? optionalScores = cloneableUndefined,
    Object? shallowList = cloneableUndefined,
  }) {
    final self = this as DeepCopyModel;
    return DeepCopyModel(
      tags: identical(tags, cloneableUndefined)
          ? List.of(self.tags)
          : List.of(tags as List<String>),
      ids: identical(ids, cloneableUndefined)
          ? Set.of(self.ids)
          : Set.of(ids as Set<int>),
      metadata: identical(metadata, cloneableUndefined)
          ? Map.of(self.metadata)
          : Map.of(metadata as Map<String, dynamic>),
      optionalTags: identical(optionalTags, cloneableUndefined)
          ? (self.optionalTags == null ? null : List.of(self.optionalTags!))
          : (optionalTags == null
              ? null
              : List.of(optionalTags as List<String>)),
      optionalScores: identical(optionalScores, cloneableUndefined)
          ? (self.optionalScores == null ? null : Map.of(self.optionalScores!))
          : (optionalScores == null
              ? null
              : Map.of(optionalScores as Map<String, int>)),
      shallowList: identical(shallowList, cloneableUndefined)
          ? self.shallowList
          : shallowList as List<String>,
    );
  }
}

/// Strongly-typed copyWith function signature for [SelectiveDeepCopyModel].
typedef $SelectiveDeepCopyModelCopyWith = SelectiveDeepCopyModel Function({
  List<String> defaultTags,
  List<String> deepTags,
  Map<String, String>? deepMap,
});

/// Generated cloneable mixin for [SelectiveDeepCopyModel].
mixin _$SelectiveDeepCopyModelCloneable {
  $SelectiveDeepCopyModelCopyWith get copyWith => _copyWith;

  SelectiveDeepCopyModel _copyWith({
    Object? defaultTags = cloneableUndefined,
    Object? deepTags = cloneableUndefined,
    Object? deepMap = cloneableUndefined,
  }) {
    final self = this as SelectiveDeepCopyModel;
    return SelectiveDeepCopyModel(
      defaultTags: identical(defaultTags, cloneableUndefined)
          ? self.defaultTags
          : defaultTags as List<String>,
      deepTags: identical(deepTags, cloneableUndefined)
          ? List.of(self.deepTags)
          : List.of(deepTags as List<String>),
      deepMap: identical(deepMap, cloneableUndefined)
          ? (self.deepMap == null ? null : Map.of(self.deepMap!))
          : (deepMap == null ? null : Map.of(deepMap as Map<String, String>)),
    );
  }
}
