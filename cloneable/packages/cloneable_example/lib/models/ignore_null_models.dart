import 'package:cloneable/cloneable.dart';

part 'ignore_null_models.g.dart';

/// Demonstrates field-level [CloneableField.ignoreNull].
@Cloneable()
class IgnoreNullModel with _$IgnoreNullModelCloneable {
  final String normalField;

  @CloneableField(ignoreNull: true)
  final String? ignoredNullField;

  const IgnoreNullModel({
    required this.normalField,
    this.ignoredNullField,
  });
}

/// Demonstrates class-level [Cloneable.ignoreNull].
@Cloneable(ignoreNull: true)
class ClassLevelIgnoreNullModel with _$ClassLevelIgnoreNullModelCloneable {
  final String name;
  final String? bio;
  final int? score;

  const ClassLevelIgnoreNullModel({
    required this.name,
    this.bio,
    this.score,
  });
}
