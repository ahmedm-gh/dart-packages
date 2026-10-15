import 'package:cloneable/cloneable.dart';

part 'collection_models.g.dart';

/// Model demonstrating class-level collection deep-copying.
@Cloneable(deepCopyCollections: true)
class DeepCopyModel with _$DeepCopyModelCloneable {
  final List<String> tags;
  final Set<int> ids;
  final Map<String, dynamic> metadata;
  final List<String>? optionalTags;
  final Map<String, int>? optionalScores;

  /// Field-level override: shallow copy even though class has deepCopyCollections = true
  @CloneableField(deepCopy: false)
  final List<String> shallowList;

  const DeepCopyModel({
    required this.tags,
    required this.ids,
    required this.metadata,
    this.optionalTags,
    this.optionalScores,
    required this.shallowList,
  });
}

/// Model demonstrating field-level selective collection deep-copying.
@Cloneable()
class SelectiveDeepCopyModel with _$SelectiveDeepCopyModelCloneable {
  final List<String> defaultTags;

  @CloneableField(deepCopy: true)
  final List<String> deepTags;

  @CloneableField(deepCopy: true)
  final Map<String, String>? deepMap;

  const SelectiveDeepCopyModel({
    required this.defaultTags,
    required this.deepTags,
    this.deepMap,
  });
}
