// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generic_models.dart';

/// Strongly-typed copyWith function signature for [Box].
typedef $BoxCopyWithFn<T> = Box<T> Function({
  T value,
  T? optionalValue,
  String tag,
});

/// Generated cloneable mixin for [Box].
mixin _$BoxCloneable<T> {
  $BoxCopyWithFn<T> get copyWith => _copyWith;

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

/// Strongly-typed copyWith function signature for [BoundedBox].
typedef $BoundedBoxCopyWithFn<T extends num> = BoundedBox<T> Function({
  T number,
  String label,
});

/// Generated cloneable mixin for [BoundedBox].
mixin _$BoundedBoxCloneable<T extends num> {
  $BoundedBoxCopyWithFn<T> get copyWith => _copyWith;

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

/// Strongly-typed copyWith function signature for [Pair].
typedef $PairCopyWithFn<A, B> = Pair<A, B> Function({
  A first,
  B second,
});

/// Generated cloneable mixin for [Pair].
mixin _$PairCloneable<A, B> {
  $PairCopyWithFn<A, B> get copyWith => _copyWith;

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
