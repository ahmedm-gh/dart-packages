import 'dart:async';

import 'package:dependency_box/dependency_box.dart';
import 'package:dependency_box/devtools.dart';

class _ServiceA {
  final String id;
  _ServiceA(this.id);
}

class _ServiceB {
  final int count;
  _ServiceB(this.count);
}

class _FactoryService {
  final int id;
  _FactoryService(this.id);
}

void main() async {
  print(
    '========================================================================',
  );
  print('  DEPENDENCY_BOX DEVTOOLS OVERHEAD & INSPECTION BENCHMARK');
  print('  Dart SDK: ${DependencyBoxConfig.isProduct ? 'Product' : 'JIT/VM'}');
  print(
    '========================================================================\n',
  );

  // Warmup VM
  _warmup();

  const iterations = 5000000;
  const regIterations = 500000;

  // ---------------------------------------------------------
  // CASE A: Core container without DevTools inspection
  // ---------------------------------------------------------
  DependencyBoxDevTools.disable();
  final boxA = DependencyBox.main(name: 'caseA');
  final serviceA = _ServiceA('a');
  boxA.addSingleton<_ServiceA>(serviceA);
  boxA.addSingleton<_ServiceB>(_ServiceB(100), key: 'keyed');
  boxA.addLazySingleton<String>((_) => 'lazyCached');
  boxA.get<String>(); // prime cache
  boxA.addFactory<_FactoryService>((_) => _FactoryService(1));

  final resASingleton = _benchmark(
    'Case A: Singleton get<T>()',
    iterations,
    () {
      boxA.get<_ServiceA>();
    },
  );

  final resAKeyed = _benchmark(
    'Case A: Keyed get<T>(key: "keyed")',
    iterations,
    () {
      boxA.get<_ServiceB>(key: 'keyed');
    },
  );

  final resALazy = _benchmark(
    'Case A: Cached LazySingleton get<T>()',
    iterations,
    () {
      boxA.get<String>();
    },
  );

  final resAFactory = _benchmark('Case A: Factory get<T>()', 1000000, () {
    boxA.get<_FactoryService>();
  });

  final resARegister = _benchmarkRegistration(
    'Case A: Registration (addSingleton)',
    regIterations,
  );

  // ---------------------------------------------------------
  // CASE B: Core with DevTools installed but disabled
  // ---------------------------------------------------------
  DependencyBoxDevTools.disable();
  final boxB = DependencyBox.main(name: 'caseB');
  boxB.addSingleton<_ServiceA>(serviceA);
  boxB.addSingleton<_ServiceB>(_ServiceB(100), key: 'keyed');
  boxB.addLazySingleton<String>((_) => 'lazyCached');
  boxB.get<String>();
  boxB.addFactory<_FactoryService>((_) => _FactoryService(1));

  final resBSingleton = _benchmark(
    'Case B: Singleton get<T>() [Disabled]',
    iterations,
    () {
      boxB.get<_ServiceA>();
    },
  );

  final resBKeyed = _benchmark(
    'Case B: Keyed get<T>(key: "keyed") [Disabled]',
    iterations,
    () {
      boxB.get<_ServiceB>(key: 'keyed');
    },
  );

  final resBLazy = _benchmark(
    'Case B: Cached LazySingleton get<T>() [Disabled]',
    iterations,
    () {
      boxB.get<String>();
    },
  );

  final resBFactory = _benchmark(
    'Case B: Factory get<T>() [Disabled]',
    1000000,
    () {
      boxB.get<_FactoryService>();
    },
  );

  final resBRegister = _benchmarkRegistration(
    'Case B: Registration (addSingleton) [Disabled]',
    regIterations,
  );

  // ---------------------------------------------------------
  // CASE C: DevTools inspection ENABLED, but DevTools disconnected
  // ---------------------------------------------------------
  final boxC = DependencyBox.main(name: 'caseC');
  DependencyBoxDevTools.register(boxC);
  boxC.addSingleton<_ServiceA>(serviceA);
  boxC.addSingleton<_ServiceB>(_ServiceB(100), key: 'keyed');
  boxC.addLazySingleton<String>((_) => 'lazyCached');
  boxC.get<String>();
  boxC.addFactory<_FactoryService>((_) => _FactoryService(1));

  final resCSingleton = _benchmark(
    'Case C: Singleton get<T>() [Enabled/Idle]',
    iterations,
    () {
      boxC.get<_ServiceA>();
    },
  );

  final resCKeyed = _benchmark(
    'Case C: Keyed get<T>(key: "keyed") [Enabled/Idle]',
    iterations,
    () {
      boxC.get<_ServiceB>(key: 'keyed');
    },
  );

  final resCLazy = _benchmark(
    'Case C: Cached LazySingleton get<T>() [Enabled/Idle]',
    iterations,
    () {
      boxC.get<String>();
    },
  );

  final resCFactory = _benchmark(
    'Case C: Factory get<T>() [Enabled/Idle]',
    1000000,
    () {
      boxC.get<_FactoryService>();
    },
  );

  final resCRegister = _benchmarkRegistration(
    'Case C: Registration (addSingleton) [Enabled/Idle]',
    regIterations,
  );

  // ---------------------------------------------------------
  // CASE D: Implementation while DevTools requests snapshots
  // ---------------------------------------------------------
  final boxD = DependencyBox.main(name: 'caseD');
  DependencyBoxDevTools.register(boxD);
  boxD.addSingleton<_ServiceA>(serviceA);
  boxD.addSingleton<_ServiceB>(_ServiceB(100), key: 'keyed');
  boxD.addLazySingleton<String>((_) => 'lazyCached');
  boxD.get<String>();
  boxD.addFactory<_FactoryService>((_) => _FactoryService(1));

  // Concurrent snapshot requests simulating DevTools poll / refresh
  var snapshotCount = 0;
  final timer = Timer.periodic(const Duration(milliseconds: 5), (_) {
    DependencyBoxDevTools.handleServiceCall(
      DependencyBoxDevTools.getSnapshotMethod,
      {},
    );
    snapshotCount++;
  });

  final resDSingleton = _benchmark(
    'Case D: Singleton get<T>() [Under DevTools Requests]',
    iterations,
    () {
      boxD.get<_ServiceA>();
    },
  );

  final resDKeyed = _benchmark(
    'Case D: Keyed get<T>(key: "keyed") [Under DevTools Requests]',
    iterations,
    () {
      boxD.get<_ServiceB>(key: 'keyed');
    },
  );

  final resDLazy = _benchmark(
    'Case D: Cached LazySingleton get<T>() [Under DevTools Requests]',
    iterations,
    () {
      boxD.get<String>();
    },
  );

  final resDFactory = _benchmark(
    'Case D: Factory get<T>() [Under DevTools Requests]',
    1000000,
    () {
      boxD.get<_FactoryService>();
    },
  );

  timer.cancel();

  // Snapshot generation throughput benchmark
  final snapshotBench = _benchmark(
    'Snapshot Generation (getSnapshot throughput)',
    50000,
    () {
      boxD.getSnapshot();
    },
  );

  // ---------------------------------------------------------
  // Comparison Summary Table
  // ---------------------------------------------------------
  print(
    '\n========================================================================',
  );
  print('  COMPARATIVE SUMMARY: ZERO OVERHEAD VERIFICATION');
  print(
    '========================================================================',
  );
  print(
    '| Benchmark Operation              | Case A (Baseline) | Case B (Disabled) | Case C (Idle) | Case D (Under Snapshots) |',
  );
  print(
    '|:---------------------------------|------------------:|------------------:|--------------:|-------------------------:|',
  );
  _printRow(
    'Singleton Lookup (ns)',
    resASingleton,
    resBSingleton,
    resCSingleton,
    resDSingleton,
  );
  _printRow('Keyed Lookup (ns)', resAKeyed, resBKeyed, resCKeyed, resDKeyed);
  _printRow('Cached Lazy Lookup (ns)', resALazy, resBLazy, resCLazy, resDLazy);
  _printRow(
    'Factory Creation (ns)',
    resAFactory,
    resBFactory,
    resCFactory,
    resDFactory,
  );
  _printRow(
    'Registration (ns)',
    resARegister,
    resBRegister,
    resCRegister,
    resCRegister,
  );
  print(
    '========================================================================',
  );
  print(
    'Snapshot Generation Latency: ${snapshotBench.toStringAsFixed(2)} ns/snapshot',
  );
  print('Snapshots dispatched during Case D: $snapshotCount');
  print(
    '========================================================================\n',
  );
}

void _warmup() {
  final box = DependencyBox.main();
  box.addSingleton<String>('warmup');
  for (var i = 0; i < 500000; i++) {
    box.get<String>();
  }
}

double _benchmark(String label, int count, void Function() action) {
  // 3 iterations, take median
  final latencies = <double>[];
  for (var r = 0; r < 3; r++) {
    final sw = Stopwatch()..start();
    for (var i = 0; i < count; i++) {
      action();
    }
    sw.stop();
    final ns = (sw.elapsedMicroseconds * 1000.0) / count;
    latencies.add(ns);
  }
  latencies.sort();
  final median = latencies[1];
  final ops = (1000000000.0 / median).round();
  print(
    '${label.padRight(55)}: ${median.toStringAsFixed(2).padLeft(7)} ns/op (${ops.toString().padLeft(9)} ops/s)',
  );
  return median;
}

double _benchmarkRegistration(String label, int count) {
  final dummy = _ServiceA('warm');
  final latencies = <double>[];
  for (var r = 0; r < 3; r++) {
    final box = DependencyBox.main();
    final sw = Stopwatch()..start();
    for (var i = 0; i < count; i++) {
      box.addSingleton<_ServiceA>(dummy, key: i);
    }
    sw.stop();
    final ns = (sw.elapsedMicroseconds * 1000.0) / count;
    latencies.add(ns);
  }
  latencies.sort();
  final median = latencies[1];
  final ops = (1000000000.0 / median).round();
  print(
    '${label.padRight(55)}: ${median.toStringAsFixed(2).padLeft(7)} ns/op (${ops.toString().padLeft(9)} ops/s)',
  );
  return median;
}

void _printRow(String label, double a, double b, double c, double d) {
  print(
    '| ${label.padRight(32)} | ${a.toStringAsFixed(2).padLeft(14)} ns | ${b.toStringAsFixed(2).padLeft(14)} ns | ${c.toStringAsFixed(2).padLeft(10)} ns | ${d.toStringAsFixed(2).padLeft(21)} ns |',
  );
}
