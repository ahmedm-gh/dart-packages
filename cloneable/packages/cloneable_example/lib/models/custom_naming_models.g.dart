// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_naming_models.dart';

/// Strongly-typed copyWith function signature for [CustomSuffixModel].
typedef $CustomSuffixModelCopyWithFn = CustomSuffixModel Function({
  String name,
  int count,
});

/// Generated cloneable mixin for [CustomSuffixModel].
mixin _$CustomSuffixModelCopyable {
  $CustomSuffixModelCopyWithFn get copyWith => _copyWith;

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

/// Strongly-typed copyWith function signature for [CustomGranularModel].
typedef SignatureCustomGranularModelFn = CustomGranularModel Function({
  String title,
});

/// Generated cloneable extension for [CustomGranularModel].
extension ExtCustomGranularModelExtension on CustomGranularModel {
  SignatureCustomGranularModelFn get copyWith => _copyWith;

  CustomGranularModel _copyWith({
    Object? title = $undefined,
  }) {
    final self = this;
    return CustomGranularModel(
      title: identical(title, $undefined) ? self.title : title as String,
    );
  }
}
