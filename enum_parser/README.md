# enum_parser

[![pub package](https://img.shields.io/pub/v/enum_parser.svg)](https://pub.dev/packages/enum_parser)
[![Star on GitHub](https://img.shields.io/badge/Star_on_GitHub-★-deeppink?style=flat&logo=github)](https://github.com/ahmedm-gh/dart-packages)
[![GitHub](https://img.shields.io/badge/GitHub-ahmedm--gh-blue?logo=github)](https://github.com/ahmedm-gh)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-pink?logo=github)](https://github.com/sponsors/ahmedm-gh)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

An ultra-fast, zero-dependency Dart utility for safely parsing and resolving enums from strings and dynamic values with multiple matching modes.

---

## Features

- **Three Flexible Parsing Modes**:
  - `EnumParserMode.strict`: Exact case-sensitive member name matching.
  - `EnumParserMode.simple`: High-speed case-insensitive matching with trimmed whitespace.
  - `EnumParserMode.loose` *(default)*: Delimiter-agnostic (strips spaces, underscores, hyphens) and enum type prefix stripping (`'Status.active'`).
- **Enum-to-Enum Mapping**: Seamlessly convert between different enum types, automatically reconciling naming conventions (e.g. `SCREAMING_SNAKE_CASE` to `camelCase`).
- **List & Delimited String Parsing**: High-performance batch resolution from separated strings (`'low, medium, high'`) or dynamic iterables.
- **Pre-Indexed Lookups**: Pre-compute immutable lookup tables with `EnumIndex` for amortized $O(1)$ expected lookup times in high-throughput serialization pipelines.
- **Ergonomic Extension Methods**: Parse directly on any enum values collection via `values.parse(...)`.
- **Zero Dependencies**: Pure Dart with 100% platform compatibility across Android, iOS, Web/WASM, macOS, Linux, and Windows.
- **Blazing Fast**: Optimized ASCII case checks, zero-regex delimiter stripping, and tiered batch list processing to minimize allocations.

---

## Getting Started

### Installation

Add `enum_parser` to your `pubspec.yaml`:

```yaml
dependencies:
  enum_parser: ^1.0.0
```

Or run:

```bash
dart pub add enum_parser
# or for Flutter
flutter pub add enum_parser
```

### Import

```dart
import 'package:enum_parser/enum_parser.dart';
```

---

## Usage

### 1. Basic Usage

By default, `EnumParser` uses loose matching, making it resilient to varied input formats, casing differences, delimiters, and enum class prefixes:

```dart
import 'package:enum_parser/enum_parser.dart';

enum Status {
  pendingPayment,
  inProgress,
  completed,
  failed;
}

void main() {
  // Parsing with fluent extension methods
  final a = Status.values.parse('pending_payment');       // Status.pendingPayment
  final b = Status.values.parse('in-progress');           // Status.inProgress
  final c = Status.values.parse('Status.completed');       // Status.completed
  final d = Status.values.parse('FAILED');                // Status.failed

  // Safe fallback when input cannot be resolved
  final fallback = Status.values.parse('unknown', fallback: Status.failed);
}
```

---

### 2. Matching Modes Comparison

| Mode | Facilities & Matching Behavior | Performance Profile | When to Use |
| :--- | :--- | :--- | :--- |
| **`strict`** | • Exact case-sensitive match against `e.name`<br>• Linear scan or indexed map lookup<br>• No casing conversion or delimiter stripping | **High Speed**<br>• Zero string allocations<br>• Fast string identity/equality comparison | Ideal for APIs and databases where casing matches Dart enum declarations exactly, providing safe resolution without throwing exceptions on misses. |
| **`simple`** | • Case-insensitive matching<br>• Trims leading and trailing whitespace<br>• Preserves delimiters (no underscore/hyphen stripping) | **Very Fast**<br>• Single lowercase pass<br>• Inlined ASCII case comparisons | Ideal for query parameters, HTTP headers, or text inputs where casing may vary (e.g. `'ACTIVE'`, `'active'`, `'Active'`) while formatting remains identical. |
| **`loose`** *(default)* | • Delimiter-agnostic (normalizes spaces, `_`, `-`, and Unicode whitespace)<br>• Case-insensitive<br>• Strips enum/class type prefixes (`'Status.active'` $\to$ `'active'`) | **Optimized Delimiter Normalizer**<br>• Zero regex evaluation<br>• Inlined code unit scanning with fast ASCII lowercasing | Recommended default for external JSON APIs, enum-to-enum conversions, user input, CLI options, and YAML/config files with inconsistent naming conventions. |

#### Benchmark Results

Measured on Dart 3 (Windows x64) with 200,000 iterations per scenario across 7 measurement rounds:

| Mode / Strategy | Test Scenario | Latency (Median) | Throughput | Memory Allocations |
| :--- | :--- | :---: | :---: | :---: |
| **`strict`** | Exact case-sensitive member match | **~15.7 ns** | **~63.6 M ops/s** | Zero allocations |
| **`simple`** | Case-insensitive match (`'URGENT'`) | **~39.5 ns** | **~25.3 M ops/s** | Zero allocations (ASCII) |
| **`loose`** | Delimited / prefixed string (`'Priority.urgent'`) | **~221.5 ns** | **~4.5 M ops/s** | Single pass buffer |
| **`loose (enum)`** | Enum-to-enum cross-mapping | **~571.6 ns** | **~1.8 M ops/s** | Single pass buffer |
| **`EnumIndex (loose)`** | Pre-indexed $O(1)$ loose lookup | **~75.2 ns** | **~13.3 M ops/s** | Single pass buffer |
| **`EnumIndex (strict)`** | Pre-indexed strict $O(1)$ lookup | **~19.3 ns** | **~51.7 M ops/s** | Zero allocations |

> [!TIP]
> For high-throughput scenarios (such as decoding thousands of JSON rows or database results in tight loops), using `EnumIndex` via `values.toEnumIndex()` yields a **~3x throughput speedup** over non-indexed loose parsing.

#### Code Examples by Mode

```dart
// 1. Strict Mode: Exact case-sensitive match
final strict = Status.values.parseStrict('inProgress'); // Status.inProgress
final strictMiss = Status.values.parseStrict('in_progress'); // null

// 2. Simple Mode: High-speed case-insensitive matching (no delimiter stripping)
final simple = Status.values.parseSimple('INPROGRESS'); // Status.inProgress

// 3. Loose Mode (Default): Normalizes case, delimiters (-, _, space), and type prefixes
final loose = Status.values.parseLoose('Status.pending-payment'); // Status.pendingPayment
```

---

### 3. Enum-to-Enum Mapping

`EnumParser` directly accepts instances of any `Enum` as the parsing input (`src`), automatically resolving and converting between different enum types by matching member names.

This provides a generalized enum-to-enum transformation that eliminates repetitive `switch` or `map` boilerplate when converting between any two enum types (for example, mapping API DTO enums to domain entity enums, third-party library enums to internal models, or differing microservice schemas) while gracefully reconciling differences in casing and conventions:

```dart
enum SourceStatus {
  PENDING_PAYMENT,
  IN_PROGRESS,
  SHIPPED,
  DELIVERED,
  CANCELLED,
}

enum TargetStatus {
  pendingPayment,
  inProgress,
  shipped,
  delivered,
  cancelled;
}

void main() {
  // 1. Single enum conversion (loose mode handles delimiters and casing)
  final SourceStatus source = SourceStatus.PENDING_PAYMENT;
  final TargetStatus? target = TargetStatus.values.parse(source);
  print(target); // TargetStatus.pendingPayment

  // 2. Batch converting a collection of enums to another enum type
  final List<SourceStatus> sourceList = [
    SourceStatus.IN_PROGRESS,
    SourceStatus.SHIPPED,
    SourceStatus.DELIVERED,
  ];
  final List<TargetStatus> targetList = TargetStatus.values.parseList(sourceList);
  print(targetList); // [TargetStatus.inProgress, TargetStatus.shipped, TargetStatus.delivered]

  // 3. High-throughput enum-to-enum conversion with EnumIndex
  final targetIndex = TargetStatus.values.toEnumIndex(mode: EnumParserMode.loose);
  final mapped = targetIndex.parse(SourceStatus.CANCELLED);
  print(mapped); // TargetStatus.cancelled
}
```

---

### 4. Parsing Lists and Separated Strings

Resolve collections of enums from comma-separated strings or heterogeneous lists:

```dart
enum Priority {
  low,
  medium,
  high;
}

void main() {
  // Parse from separated strings
  final priorities = Priority.values.parseList('low, medium, high');
  // [Priority.low, Priority.medium, Priority.high]

  // Custom separator
  final statuses = Status.values.parseList(
    'pending_payment|in_progress',
    separator: '|',
  );

  // Mixed raw inputs
  final mixed = Priority.values.parseList(['low', 'Priority.high', 'medium']);
  // [Priority.low, Priority.high, Priority.medium]
}
```

---

### 5. High-Throughput Pre-Indexing with `EnumIndex`

When parsing high volumes of data (e.g., inside loops, database mappers, or network deserializers), pre-index the enum once for amortized $O(1)$ hash map lookups without repetitive linear scans:

```dart
final statusIndex = Status.values.toEnumIndex(mode: EnumParserMode.loose);

// O(1) single-item lookup
final status = statusIndex.parse('in_progress');

// O(1) list lookup
final list = statusIndex.parseList('pending_payment, completed');
```

---

### 6. Custom Converters

Provide a custom fallback converter callback to handle domain-specific aliases or legacy identifiers:

```dart
final status = Status.values.parse(
  'p1',
  converter: (src, values) => src == 'p1' ? Status.inProgress : null,
  fallback: Status.pendingPayment,
);
```

---

## Supporting & Contributing

If you find `enum_parser` helpful, here are several ways you can support the project:

### 🌟 Community Support

- **Star the Repository**: Star [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages) on GitHub to help others discover it.
- **Report Issues & Ideas**: Found a bug or need an improvement? Open an issue on [GitHub Issues](https://github.com/ahmedm-gh/dart-packages/issues).
- **Contribute**: Pull requests for optimizations, documentation, or examples are always welcome.
- **Spread the Word**: Recommend `enum_parser` in your Flutter/Dart teams, blogs, or communities.

### ☕ Sponsorship & Backing

- **Sponsor on GitHub**: If this package brings value to your commercial apps, consider supporting its maintenance via [GitHub Sponsors](https://github.com/sponsors/ahmedm-gh).
- **Buy Me a Coffee**: Support development with a one-time coffee or recurring donation via [Buy Me a Coffee](https://buymeacoffee.com/ahmeds1).

## Author & Maintainer

Created and maintained by **[AHMED M.](https://github.com/ahmedm-gh)**  

- GitHub: [@ahmedm-gh](https://github.com/ahmedm-gh)
- Repository: [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages)

## License

This package is licensed under the [MIT License](./LICENSE).
