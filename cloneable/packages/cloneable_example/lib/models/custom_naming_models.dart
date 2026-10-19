import 'package:cloneable/cloneable.dart';

part 'custom_naming_models.g.dart';

/// Model demonstrating custom suffix ('Copyable' instead of 'Cloneable') in mixin.
@Cloneable(
  naming: CloneableNaming(
    mixin: CloneableAffix(suffix: 'Copyable'),
  ),
)
class CustomSuffixModel with _$CustomSuffixModelCopyable {
  final String name;
  final int count;

  const CustomSuffixModel({
    required this.name,
    this.count = 0,
  });
}

/// Model demonstrating granular prefix and suffix overrides.
@Cloneable(
  naming: CloneableNaming(
    extension: CloneableAffix(prefix: 'Ext', suffix: 'Extension'),
    typedef: CloneableAffix(prefix: 'Signature', suffix: 'Fn'),
  ),
)
class CustomGranularModel {
  final String title;

  const CustomGranularModel({
    required this.title,
  });
}
