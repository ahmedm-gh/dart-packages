# cloneable_example

Demonstration and benchmarking package for [`cloneable`](https://pub.dev/packages/cloneable) and [`cloneable_generator`](https://pub.dev/packages/cloneable_generator).

---

## Models Included

- **`lib/user.dart`**: Primary user example from the specification.
- **`lib/models/external_library.dart` & `lib/models/imported_models.dart`**: Demonstrates models utilizing members, values, and types imported from external libraries (enums, nested models, generics, standard library `DateTime`/`Uri`/`Duration`, static members, top-level constants as constructor defaults, and prefixed imports `as ext`).
- **`lib/models/standalone_models.dart`**: Demonstrates the non-part / standalone approach (no `part` directive) generating an independent standalone extension file (`standalone_models.cloneable.dart`) without `part of`, cleanly propagating imported types, prefixes, and members.
- **`lib/models/clean_models.dart`**: Demonstrates extension-based copyWith without mixin declarations and `@UseCopyWith` typedef alias.
- **`lib/models/collection_models.dart`**: Demonstrates class-level and field-level deep collection copying (`List`, `Set`, `Map`).
- **`lib/models/ignore_null_models.dart`**: Demonstrates preserving existing values when `null` is passed (`ignoreNull`).
- **`lib/models/whitelist_models.dart`**: Demonstrates whitelisting supported `copyWith` fields via annotations and in-class getters.
- **`lib/models/inline_model.dart`**: Demonstrates in-file inline code generation via `dart run cloneable_generator inline`.
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
