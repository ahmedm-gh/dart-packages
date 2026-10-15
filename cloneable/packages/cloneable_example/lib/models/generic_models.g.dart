// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generic_models.dart';

// **************************************************************************
// CloneableGenerator
// **************************************************************************

/// Strongly-typed copyWith function signature for [Box].
typedef $BoxCopyWith<T> = Box<T> Function({
  T value,
  T? optionalValue,
  String tag,
});

/// Generated cloneable mixin for [Box].
mixin _$BoxCloneable<T> {
  $BoxCopyWith<T> get copyWith => _copyWith;

  Box<T> _copyWith({
    Object? value = cloneableUndefined,
    Object? optionalValue = cloneableUndefined,
    Object? tag = cloneableUndefined,
  }) {
    final self = this as Box<T>;
    return Box<T>(
      value: identical(value, cloneableUndefined) ? self.value : value as T,
      optionalValue: identical(optionalValue, cloneableUndefined)
          ? self.optionalValue
          : optionalValue as T?,
      tag: identical(tag, cloneableUndefined) ? self.tag : tag as String,
    );
  }
}

/// Strongly-typed copyWith function signature for [BoundedBox].
typedef $BoundedBoxCopyWith<T extends num> = BoundedBox<T> Function({
  T number,
  String label,
});

/// Generated cloneable mixin for [BoundedBox].
mixin _$BoundedBoxCloneable<T extends num> {
  $BoundedBoxCopyWith<T> get copyWith => _copyWith;

  BoundedBox<T> _copyWith({
    Object? number = cloneableUndefined,
    Object? label = cloneableUndefined,
  }) {
    final self = this as BoundedBox<T>;
    return BoundedBox<T>(
      number: identical(number, cloneableUndefined) ? self.number : number as T,
      label:
          identical(label, cloneableUndefined) ? self.label : label as String,
    );
  }
}

/// Strongly-typed copyWith function signature for [Pair].
typedef $PairCopyWith<A, B> = Pair<A, B> Function({
  A first,
  B second,
});

/// Generated cloneable mixin for [Pair].
mixin _$PairCloneable<A, B> {
  $PairCopyWith<A, B> get copyWith => _copyWith;

  Pair<A, B> _copyWith({
    Object? first = cloneableUndefined,
    Object? second = cloneableUndefined,
  }) {
    final self = this as Pair<A, B>;
    return Pair<A, B>(
      first: identical(first, cloneableUndefined) ? self.first : first as A,
      second: identical(second, cloneableUndefined) ? self.second : second as B,
    );
  }
}
