const _handwrittenUndefined = Object();

/// 1. Hand-written sentinel-based User with direct method
class HandwrittenUser {
  final String name;
  final int age;
  final String? nickname;

  const HandwrittenUser({required this.name, required this.age, this.nickname});

  HandwrittenUser copyWith({
    Object? name = _handwrittenUndefined,
    Object? age = _handwrittenUndefined,
    Object? nickname = _handwrittenUndefined,
  }) {
    return HandwrittenUser(
      name: identical(name, _handwrittenUndefined) ? this.name : name as String,
      age: identical(age, _handwrittenUndefined) ? this.age : age as int,
      nickname: identical(nickname, _handwrittenUndefined)
          ? this.nickname
          : nickname as String?,
    );
  }
}

/// 2. Freezed-style implementation (allocates an intermediate wrapper on every copyWith)
abstract class $FreezedUserCopyWith {
  FreezedStyleUser call({String name, int age, String? nickname});
}

class _$FreezedUserCopyWithImpl implements $FreezedUserCopyWith {
  final FreezedStyleUser _value;
  const _$FreezedUserCopyWithImpl(this._value);

  @override
  FreezedStyleUser call({
    Object? name = _handwrittenUndefined,
    Object? age = _handwrittenUndefined,
    Object? nickname = _handwrittenUndefined,
  }) {
    return FreezedStyleUser(
      name: identical(name, _handwrittenUndefined)
          ? _value.name
          : name as String,
      age: identical(age, _handwrittenUndefined) ? _value.age : age as int,
      nickname: identical(nickname, _handwrittenUndefined)
          ? _value.nickname
          : nickname as String?,
    );
  }
}

class FreezedStyleUser {
  final String name;
  final int age;
  final String? nickname;

  const FreezedStyleUser({
    required this.name,
    required this.age,
    this.nickname,
  });

  // Freezed allocates an intermediate copyWith object on every invocation:
  $FreezedUserCopyWith get copyWith => _$FreezedUserCopyWithImpl(this);
}

/// 3. Map-based dynamic representation (for reference)
class MapBasedUser {
  final Map<String, dynamic> _data;

  const MapBasedUser(this._data);

  String get name => _data['name'] as String;
  int get age => _data['age'] as int;
  String? get nickname => _data['nickname'] as String?;

  MapBasedUser copyWith(Map<String, dynamic> updates) {
    final copy = Map<String, dynamic>.from(_data);
    copy.addAll(updates);
    return MapBasedUser(copy);
  }
}

/// 4. Hand-written Medium Model (10 fields)
class HandwrittenMediumModel {
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

  const HandwrittenMediumModel({
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

  HandwrittenMediumModel copyWith({
    Object? f1 = _handwrittenUndefined,
    Object? f2 = _handwrittenUndefined,
    Object? f3 = _handwrittenUndefined,
    Object? f4 = _handwrittenUndefined,
    Object? f5 = _handwrittenUndefined,
    Object? f6 = _handwrittenUndefined,
    Object? f7 = _handwrittenUndefined,
    Object? f8 = _handwrittenUndefined,
    Object? f9 = _handwrittenUndefined,
    Object? f10 = _handwrittenUndefined,
  }) {
    return HandwrittenMediumModel(
      f1: identical(f1, _handwrittenUndefined) ? this.f1 : f1 as String,
      f2: identical(f2, _handwrittenUndefined) ? this.f2 : f2 as int,
      f3: identical(f3, _handwrittenUndefined) ? this.f3 : f3 as double,
      f4: identical(f4, _handwrittenUndefined) ? this.f4 : f4 as bool,
      f5: identical(f5, _handwrittenUndefined) ? this.f5 : f5 as String?,
      f6: identical(f6, _handwrittenUndefined) ? this.f6 : f6 as int?,
      f7: identical(f7, _handwrittenUndefined) ? this.f7 : f7 as double?,
      f8: identical(f8, _handwrittenUndefined) ? this.f8 : f8 as bool?,
      f9: identical(f9, _handwrittenUndefined) ? this.f9 : f9 as List<String>,
      f10: identical(f10, _handwrittenUndefined)
          ? this.f10
          : f10 as Map<String, int>?,
    );
  }
}

/// 5. Hand-written Large Model (25 fields)
class HandwrittenLargeModel {
  final String s1, s2, s3, s4, s5;
  final int i1, i2, i3, i4, i5;
  final double d1, d2, d3, d4, d5;
  final bool b1, b2, b3, b4, b5;
  final String? opt1, opt2;
  final int? opt3;
  final double? opt4;
  final bool? opt5;

  const HandwrittenLargeModel({
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

  HandwrittenLargeModel copyWith({
    Object? s1 = _handwrittenUndefined,
    Object? s2 = _handwrittenUndefined,
    Object? s3 = _handwrittenUndefined,
    Object? s4 = _handwrittenUndefined,
    Object? s5 = _handwrittenUndefined,
    Object? i1 = _handwrittenUndefined,
    Object? i2 = _handwrittenUndefined,
    Object? i3 = _handwrittenUndefined,
    Object? i4 = _handwrittenUndefined,
    Object? i5 = _handwrittenUndefined,
    Object? d1 = _handwrittenUndefined,
    Object? d2 = _handwrittenUndefined,
    Object? d3 = _handwrittenUndefined,
    Object? d4 = _handwrittenUndefined,
    Object? d5 = _handwrittenUndefined,
    Object? b1 = _handwrittenUndefined,
    Object? b2 = _handwrittenUndefined,
    Object? b3 = _handwrittenUndefined,
    Object? b4 = _handwrittenUndefined,
    Object? b5 = _handwrittenUndefined,
    Object? opt1 = _handwrittenUndefined,
    Object? opt2 = _handwrittenUndefined,
    Object? opt3 = _handwrittenUndefined,
    Object? opt4 = _handwrittenUndefined,
    Object? opt5 = _handwrittenUndefined,
  }) {
    return HandwrittenLargeModel(
      s1: identical(s1, _handwrittenUndefined) ? this.s1 : s1 as String,
      s2: identical(s2, _handwrittenUndefined) ? this.s2 : s2 as String,
      s3: identical(s3, _handwrittenUndefined) ? this.s3 : s3 as String,
      s4: identical(s4, _handwrittenUndefined) ? this.s4 : s4 as String,
      s5: identical(s5, _handwrittenUndefined) ? this.s5 : s5 as String,
      i1: identical(i1, _handwrittenUndefined) ? this.i1 : i1 as int,
      i2: identical(i2, _handwrittenUndefined) ? this.i2 : i2 as int,
      i3: identical(i3, _handwrittenUndefined) ? this.i3 : i3 as int,
      i4: identical(i4, _handwrittenUndefined) ? this.i4 : i4 as int,
      i5: identical(i5, _handwrittenUndefined) ? this.i5 : i5 as int,
      d1: identical(d1, _handwrittenUndefined) ? this.d1 : d1 as double,
      d2: identical(d2, _handwrittenUndefined) ? this.d2 : d2 as double,
      d3: identical(d3, _handwrittenUndefined) ? this.d3 : d3 as double,
      d4: identical(d4, _handwrittenUndefined) ? this.d4 : d4 as double,
      d5: identical(d5, _handwrittenUndefined) ? this.d5 : d5 as double,
      b1: identical(b1, _handwrittenUndefined) ? this.b1 : b1 as bool,
      b2: identical(b2, _handwrittenUndefined) ? this.b2 : b2 as bool,
      b3: identical(b3, _handwrittenUndefined) ? this.b3 : b3 as bool,
      b4: identical(b4, _handwrittenUndefined) ? this.b4 : b4 as bool,
      b5: identical(b5, _handwrittenUndefined) ? this.b5 : b5 as bool,
      opt1: identical(opt1, _handwrittenUndefined)
          ? this.opt1
          : opt1 as String?,
      opt2: identical(opt2, _handwrittenUndefined)
          ? this.opt2
          : opt2 as String?,
      opt3: identical(opt3, _handwrittenUndefined) ? this.opt3 : opt3 as int?,
      opt4: identical(opt4, _handwrittenUndefined)
          ? this.opt4
          : opt4 as double?,
      opt5: identical(opt5, _handwrittenUndefined) ? this.opt5 : opt5 as bool?,
    );
  }
}
