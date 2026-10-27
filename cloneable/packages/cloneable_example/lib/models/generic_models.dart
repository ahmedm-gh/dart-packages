import 'package:cloneable/cloneable.dart';

part 'generic_models.g.dart';

@Cloneable()
class Box<T> with _$BoxCloneable<T> {
  final T value;
  final T? optionalValue;
  final String tag;

  const Box({required this.value, this.optionalValue, required this.tag});
}

@Cloneable()
class BoundedBox<T extends num> with _$BoundedBoxCloneable<T> {
  final T number;
  final String label;

  const BoundedBox({required this.number, required this.label});
}

@Cloneable()
class Pair<A, B> with _$PairCloneable<A, B> {
  final A first;
  final B second;

  const Pair({required this.first, required this.second});
}
