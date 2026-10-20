// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_naming_models.dart';

/// Generated cloneable mixin for [CustomSuffixModel].
mixin _$CustomSuffixModelCopyable {
  CustomSuffixModel Function({String name, int count}) get copyWith =>
      _copyWith;

  CustomSuffixModel _copyWith({
    Object? name = $undefined,
    Object? count = $undefined,
  }) {
    final self = this as CustomSuffixModel;
    return CustomSuffixModel(
      name: identical(name, $undefined) ? self.name : name as String,
      count: identical(count, $undefined) ? self.count : count as int,
    );
  }
}

/// Generated cloneable extension for [CustomGranularModel].
extension ExtCustomGranularModelExtension on CustomGranularModel {
  CustomGranularModel Function({String title}) get copyWith => _copyWith;

  CustomGranularModel _copyWith({Object? title = $undefined}) {
    final self = this;
    return CustomGranularModel(
      title: identical(title, $undefined) ? self.title : title as String,
    );
  }
}
