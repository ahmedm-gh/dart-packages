// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generic_models.dart';

/// Generated cloneable mixin for [Box].
mixin _$BoxCloneable<T> {
  Box<T> Function({T value, T? optionalValue, String tag}) get copyWith =>
      _copyWith;

  Box<T> _copyWith({
    Object? value = $undefined,
    Object? optionalValue = $undefined,
    Object? tag = $undefined,
  }) {
    final self = this as Box<T>;
    return Box<T>(
      value: identical(value, $undefined) ? self.value : value as T,
      optionalValue: identical(optionalValue, $undefined)
          ? self.optionalValue
          : optionalValue as T?,
      tag: identical(tag, $undefined) ? self.tag : tag as String,
    );
  }
}

/// Generated cloneable mixin for [BoundedBox].
mixin _$BoundedBoxCloneable<T extends num> {
  BoundedBox<T> Function({T number, String label}) get copyWith => _copyWith;

  BoundedBox<T> _copyWith({
    Object? number = $undefined,
    Object? label = $undefined,
  }) {
    final self = this as BoundedBox<T>;
    return BoundedBox<T>(
      number: identical(number, $undefined) ? self.number : number as T,
      label: identical(label, $undefined) ? self.label : label as String,
    );
  }
}

/// Generated cloneable mixin for [Pair].
mixin _$PairCloneable<A, B> {
  Pair<A, B> Function({A first, B second}) get copyWith => _copyWith;

  Pair<A, B> _copyWith({
    Object? first = $undefined,
    Object? second = $undefined,
  }) {
    final self = this as Pair<A, B>;
    return Pair<A, B>(
      first: identical(first, $undefined) ? self.first : first as A,
      second: identical(second, $undefined) ? self.second : second as B,
    );
  }
}
