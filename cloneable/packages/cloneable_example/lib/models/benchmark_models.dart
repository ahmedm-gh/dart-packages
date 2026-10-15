import 'package:cloneable/cloneable.dart';

part 'benchmark_models.g.dart';

@Cloneable()
class MediumModel with _$MediumModelCloneable {
  final String f1;
  final int f2;
  final double f3;
  final bool f4;
  final String? f5;
  final int? f6;
  final double? f7;
  final bool? f8;
  final List<String> f9;
  final Map<String, int>? f10;

  const MediumModel({
    required this.f1,
    required this.f2,
    required this.f3,
    required this.f4,
    this.f5,
    this.f6,
    this.f7,
    this.f8,
    required this.f9,
    this.f10,
  });
}

@Cloneable()
class LargeModel with _$LargeModelCloneable {
  final String s1;
  final String s2;
  final String s3;
  final String s4;
  final String s5;
  final int i1;
  final int i2;
  final int i3;
  final int i4;
  final int i5;
  final double d1;
  final double d2;
  final double d3;
  final double d4;
  final double d5;
  final bool b1;
  final bool b2;
  final bool b3;
  final bool b4;
  final bool b5;
  final String? opt1;
  final String? opt2;
  final int? opt3;
  final double? opt4;
  final bool? opt5;

  const LargeModel({
    required this.s1,
    required this.s2,
    required this.s3,
    required this.s4,
    required this.s5,
    required this.i1,
    required this.i2,
    required this.i3,
    required this.i4,
    required this.i5,
    required this.d1,
    required this.d2,
    required this.d3,
    required this.d4,
    required this.d5,
    required this.b1,
    required this.b2,
    required this.b3,
    required this.b4,
    required this.b5,
    this.opt1,
    this.opt2,
    this.opt3,
    this.opt4,
    this.opt5,
  });
}
