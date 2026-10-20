// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_models.dart';

/// Generated cloneable mixin for [DeepCopyModel].
mixin _$DeepCopyModelCloneable {
  DeepCopyModel Function({
    List<String> tags,
    Set<int> ids,
    Map<String, dynamic> metadata,
    List<String>? optionalTags,
    Map<String, int>? optionalScores,
    List<String> shallowList,
  }) get copyWith => _copyWith;

  DeepCopyModel _copyWith({
    Object? tags = $undefined,
    Object? ids = $undefined,
    Object? metadata = $undefined,
    Object? optionalTags = $undefined,
    Object? optionalScores = $undefined,
    Object? shallowList = $undefined,
  }) {
    final self = this as DeepCopyModel;
    return DeepCopyModel(
      tags: identical(tags, $undefined)
          ? List.of(self.tags)
          : List.of(tags as List<String>),
      ids: identical(ids, $undefined)
          ? Set.of(self.ids)
          : Set.of(ids as Set<int>),
      metadata: identical(metadata, $undefined)
          ? Map.of(self.metadata)
          : Map.of(metadata as Map<String, dynamic>),
      optionalTags: identical(optionalTags, $undefined)
          ? (self.optionalTags == null ? null : List.of(self.optionalTags!))
          : (optionalTags == null
              ? null
              : List.of(optionalTags as List<String>)),
      optionalScores: identical(optionalScores, $undefined)
          ? (self.optionalScores == null ? null : Map.of(self.optionalScores!))
          : (optionalScores == null
              ? null
              : Map.of(optionalScores as Map<String, int>)),
      shallowList: identical(shallowList, $undefined)
          ? self.shallowList
          : shallowList as List<String>,
    );
  }
}

/// Generated cloneable mixin for [SelectiveDeepCopyModel].
mixin _$SelectiveDeepCopyModelCloneable {
  SelectiveDeepCopyModel Function({
    List<String> defaultTags,
    List<String> deepTags,
    Map<String, String>? deepMap,
  }) get copyWith => _copyWith;

  SelectiveDeepCopyModel _copyWith({
    Object? defaultTags = $undefined,
    Object? deepTags = $undefined,
    Object? deepMap = $undefined,
  }) {
    final self = this as SelectiveDeepCopyModel;
    return SelectiveDeepCopyModel(
      defaultTags: identical(defaultTags, $undefined)
          ? self.defaultTags
          : defaultTags as List<String>,
      deepTags: identical(deepTags, $undefined)
          ? List.of(self.deepTags)
          : List.of(deepTags as List<String>),
      deepMap: identical(deepMap, $undefined)
          ? (self.deepMap == null ? null : Map.of(self.deepMap!))
          : (deepMap == null ? null : Map.of(deepMap as Map<String, String>)),
    );
  }
}
