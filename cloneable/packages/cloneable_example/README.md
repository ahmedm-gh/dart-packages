# cloneable_example

Demonstration and benchmarking package for [`cloneable`](https://pub.dev/packages/cloneable) and [`cloneable_generator`](https://pub.dev/packages/cloneable_generator).

---

## Models Included

- **`lib/user.dart`**: Primary user example from the specification.
- **`lib/models/generic_models.dart`**: Demonstrates `Box<T>`, `BoundedBox<T extends num>`, and `Pair<A, B>`.
- **`lib/models/complex_models.dart`**: Demonstrates enums (`Role`), nested models (`Address`), and collections (`List<String>`, `Map<String, dynamic>`).
- **`lib/models/constructor_models.dart`**: Demonstrates positional constructors (`Coordinate`), custom named constructors (`ServiceConfig.create`), and ignored fields (`AuditedEntity`).
- **`lib/models/benchmark_models.dart`**: 10-field (`MediumModel`) and 25-field (`LargeModel`) models for performance benchmarking.

---

## Running Code Generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Running Benchmarks

### Runtime Benchmark
```bash
dart run benchmark/runtime_benchmark.dart
```

### Build-Time Benchmark
```bash
dart run benchmark/build_time_benchmark.dart
```

### Binary Footprint Benchmark
```bash
dart run benchmark/footprint_benchmark.dart
```
