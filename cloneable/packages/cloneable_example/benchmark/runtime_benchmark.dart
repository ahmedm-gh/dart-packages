import 'package:cloneable_example/models/benchmark_models.dart';
import 'package:cloneable_example/models/generic_models.dart';
import 'package:cloneable_example/user.dart';
import 'models_handwritten.dart';

class BenchmarkResult {
  final String name;
  final String scenario;
  final double medianNs;
  final double minNs;
  final double maxNs;
  final double opsPerSec;

  const BenchmarkResult({
    required this.name,
    required this.scenario,
    required this.medianNs,
    required this.minNs,
    required this.maxNs,
    required this.opsPerSec,
  });

  @override
  String toString() {
    return '${name.padRight(22)} | ${scenario.padRight(22)} | ${medianNs.toStringAsFixed(2).padLeft(8)} ns | ${opsPerSec.toStringAsFixed(0).padLeft(12)} ops/s | [${minNs.toStringAsFixed(2)} - ${maxNs.toStringAsFixed(2)}]';
  }
}

BenchmarkResult measure(
  String name,
  String scenario,
  void Function() action, {
  int warmupIterations = 20000,
  int benchmarkIterations = 500000,
  int rounds = 5,
}) {
  // Warmup
  for (int i = 0; i < warmupIterations; i++) {
    action();
  }

  final times = <double>[];

  for (int r = 0; r < rounds; r++) {
    final sw = Stopwatch()..start();
    for (int i = 0; i < benchmarkIterations; i++) {
      action();
    }
    sw.stop();
    final nsPerOp = (sw.elapsedMicroseconds * 1000.0) / benchmarkIterations;
    times.add(nsPerOp);
  }

  times.sort();
  final median = times[times.length ~/ 2];
  final min = times.first;
  final max = times.last;
  final ops = 1000000000.0 / median;

  return BenchmarkResult(
    name: name,
    scenario: scenario,
    medianNs: median,
    minNs: min,
    maxNs: max,
    opsPerSec: ops,
  );
}

void main() {
  print(
      '========================================================================================');
  print(
      '                    CLONEABLE RUNTIME PERFORMANCE BENCHMARK                              ');
  print(
      '========================================================================================');
  print(
      '${'Implementation'.padRight(22)} | ${'Scenario'.padRight(22)} | ${'Median'.padLeft(8)}    | ${'Ops/sec'.padLeft(12)}       | Variability [Min - Max]');
  print(
      '----------------------------------------------------------------------------------------');

  final results = <BenchmarkResult>[];

  // 1. Small Model - Preserved (Omitted argument)
  const cloneableUser = User(name: 'Ahmed', age: 25, nickname: 'Dev');
  const handwrittenUser =
      HandwrittenUser(name: 'Ahmed', age: 25, nickname: 'Dev');
  const freezedUser = FreezedStyleUser(name: 'Ahmed', age: 25, nickname: 'Dev');
  const mapUser = MapBasedUser({'name': 'Ahmed', 'age': 25, 'nickname': 'Dev'});

  Object? sink;

  // A. Cloneable (Generated) - Preserved
  results.add(measure('Cloneable (Generated)', 'Small: Preserved', () {
    sink = cloneableUser.copyWith(name: 'Mohamed');
  }));

  // B. Handwritten - Preserved
  results.add(measure('Handwritten Sentinel', 'Small: Preserved', () {
    sink = handwrittenUser.copyWith(name: 'Mohamed');
  }));

  // C. Freezed-Style (Wrapper) - Preserved
  results.add(measure('Freezed-Style (Alloc)', 'Small: Preserved', () {
    sink = freezedUser.copyWith(name: 'Mohamed');
  }));

  // D. Map-Based - Preserved
  results.add(measure('Map-Based (Dynamic)', 'Small: Preserved', () {
    sink = mapUser.copyWith({'name': 'Mohamed'});
  }));

  print(results[0]);
  print(results[1]);
  print(results[2]);
  print(results[3]);
  print(
      '----------------------------------------------------------------------------------------');

  // 2. Small Model - Explicit Null
  // A. Cloneable - Explicit Null
  final rNull1 = measure('Cloneable (Generated)', 'Small: Explicit Null', () {
    sink = cloneableUser.copyWith(nickname: null);
  });
  results.add(rNull1);
  print(rNull1);

  // B. Handwritten - Explicit Null
  final rNull2 = measure('Handwritten Sentinel', 'Small: Explicit Null', () {
    sink = handwrittenUser.copyWith(nickname: null);
  });
  results.add(rNull2);
  print(rNull2);

  // C. Freezed-Style - Explicit Null
  final rNull3 = measure('Freezed-Style (Alloc)', 'Small: Explicit Null', () {
    sink = freezedUser.copyWith(nickname: null);
  });
  results.add(rNull3);
  print(rNull3);

  // D. Map-Based - Explicit Null
  final rNull4 = measure('Map-Based (Dynamic)', 'Small: Explicit Null', () {
    sink = mapUser.copyWith({'nickname': null});
  });
  results.add(rNull4);
  print(rNull4);
  print(
      '----------------------------------------------------------------------------------------');

  // 3. Medium Model (10 fields)
  const cloneableMedium = MediumModel(
    f1: 'a',
    f2: 1,
    f3: 1.0,
    f4: true,
    f5: 'opt',
    f6: 6,
    f7: 7.0,
    f8: false,
    f9: ['x'],
    f10: {'k': 1},
  );
  const handwrittenMedium = HandwrittenMediumModel(
    f1: 'a',
    f2: 1,
    f3: 1.0,
    f4: true,
    f5: 'opt',
    f6: 6,
    f7: 7.0,
    f8: false,
    f9: ['x'],
    f10: {'k': 1},
  );

  final rMed1 = measure('Cloneable (Generated)', 'Medium: 10 fields', () {
    sink = cloneableMedium.copyWith(f1: 'b', f5: null, f6: null);
  });
  results.add(rMed1);
  print(rMed1);

  final rMed2 = measure('Handwritten Sentinel', 'Medium: 10 fields', () {
    sink = handwrittenMedium.copyWith(f1: 'b', f5: null, f6: null);
  });
  results.add(rMed2);
  print(rMed2);
  print(
      '----------------------------------------------------------------------------------------');

  // 4. Large Model (25 fields)
  const cloneableLarge = LargeModel(
    s1: '1',
    s2: '2',
    s3: '3',
    s4: '4',
    s5: '5',
    i1: 1,
    i2: 2,
    i3: 3,
    i4: 4,
    i5: 5,
    d1: 1.0,
    d2: 2.0,
    d3: 3.0,
    d4: 4.0,
    d5: 5.0,
    b1: true,
    b2: false,
    b3: true,
    b4: false,
    b5: true,
    opt1: 'a',
    opt2: 'b',
    opt3: 3,
    opt4: 4.0,
    opt5: true,
  );
  const handwrittenLarge = HandwrittenLargeModel(
    s1: '1',
    s2: '2',
    s3: '3',
    s4: '4',
    s5: '5',
    i1: 1,
    i2: 2,
    i3: 3,
    i4: 4,
    i5: 5,
    d1: 1.0,
    d2: 2.0,
    d3: 3.0,
    d4: 4.0,
    d5: 5.0,
    b1: true,
    b2: false,
    b3: true,
    b4: false,
    b5: true,
    opt1: 'a',
    opt2: 'b',
    opt3: 3,
    opt4: 4.0,
    opt5: true,
  );

  final rLarge1 = measure('Cloneable (Generated)', 'Large: 25 fields', () {
    sink =
        cloneableLarge.copyWith(s1: 'new', opt1: null, opt3: null, b1: false);
  });
  results.add(rLarge1);
  print(rLarge1);

  final rLarge2 = measure('Handwritten Sentinel', 'Large: 25 fields', () {
    sink =
        handwrittenLarge.copyWith(s1: 'new', opt1: null, opt3: null, b1: false);
  });
  results.add(rLarge2);
  print(rLarge2);
  print(
      '----------------------------------------------------------------------------------------');

  // 5. Generic Model (Box<int>)
  const cloneableBox =
      Box<int>(value: 42, optionalValue: 100, tag: 'benchmark');
  final rGen = measure('Cloneable (Generated)', 'Generic: Box<int>', () {
    sink = cloneableBox.copyWith(value: 84, optionalValue: null);
  });
  results.add(rGen);
  print(rGen);

  print(
      '========================================================================================');
  // Prevent dead code elimination
  if (sink == null) {
    print('Sink is null (never reached)');
  }
}
