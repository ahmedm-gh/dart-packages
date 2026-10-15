# Agent Guidelines: Dart Packages Repository

This repository is a monorepo for high-performance, idiomatic, zero-dependency Dart packages maintained by **AHMED M.** ([@ahmedm-gh](https://github.com/ahmedm-gh)).

Every package in this workspace (`caster`, `tristate`, `cloneable`, etc.) must adhere to the standard publishing rules, code quality conventions, and documentation templates defined below to achieve and maintain **160/160 Pub Points** on [pub.dev](https://pub.dev).

---

## 1. Pub.dev Scoring Rubric: Achieving 160/160 Points

Pana (the Package Analyzer tool) scores packages out of **160 points** across 5 distinct categories:

| Category | Points | Sub-Criteria & Point Breakdown |
| --- | :---: | --- |
| **1. Follow Dart file conventions** | **30 pts** | • `pubspec.yaml` valid, description 60–180 chars, secure `https` URLs (**10 pts**)<br>• OSI-approved open source `LICENSE` (**10 pts**)<br>• Root `README.md` present & non-empty (**5 pts**)<br>• Root `CHANGELOG.md` with current version section (**5 pts**) |
| **2. Provide documentation** | **20 pts** | • 20%+ public API documented with doc comments `///` (**10 pts**)<br>• Runnable code example in `example/` directory (**10 pts**) |
| **3. Support multiple platforms** | **20 pts** | • Support all 6 platforms (Android, iOS, Web, Windows, macOS, Linux) without unconditional `dart:io` (**20 pts**)<br>• WebAssembly (WASM) runtime compatibility |
| **4. Pass static analysis** | **50 pts** | • 0 compilation or analyzer errors (**30 pts**)<br>• 0 analyzer warnings, 0 linter violations, and 100% formatted via `dart format` (**20 pts**) |
| **5. Support up-to-date dependencies** | **40 pts** | • Supports modern/current stable Dart SDK constraint (**20 pts**)<br>• Up-to-date direct and transitive dependencies with valid semver bounds (**20 pts**) |
| **Total Maximum Score** | **160 pts** | **160 / 160 Guaranteed Quality Standard** |

---

## 2. Standard Rules for Publishing Packages on pub.dev

### 2.1. `pubspec.yaml` Specification

Every package must have a valid, fully configured `pubspec.yaml` containing:

```yaml
name: <package_name>
description: A concise, compelling summary between 60 and 180 characters describing the package's primary value.
version: 1.0.0
repository: https://github.com/ahmedm-gh/dart-packages/tree/main/<package_name>
issue_tracker: https://github.com/ahmedm-gh/dart-packages/issues

topics:
  - primary-topic
  - secondary-topic
  - utilities

environment:
  sdk: '>=3.0.0 <4.0.0'

dev_dependencies:
  lints: ^6.0.0
  test: ^1.25.6
```

#### Key Requirements

- **`name`**: Lowercase with underscores (`[a-z0-9_]`).
- **`description`**: Must be between **60 and 180 characters** without trailing punctuation or generic filler.
- **`version`**: Follow strict semantic versioning (`MAJOR.MINOR.PATCH`).
- **`repository`**: Point directly to the package's subdirectory within the monorepo (`.../tree/main/<package_name>`).
- **`issue_tracker`**: Point to `https://github.com/ahmedm-gh/dart-packages/issues`.
- **`topics`**: Provide 1 to 5 relevant topics (lowercase alphanumeric with hyphens) for search discovery on pub.dev.
- **`environment.sdk`**: Explicitly specify the supported Dart SDK range.

---

### 2.2. Directory Layout Convention

Pub enforces strict layout conventions. Deviations produce warnings that prevent automated scoring:

```
<package_name>/
├── .gitignore              # Ignores .dart_tool/, pubspec.lock, *.exe, etc.
├── analysis_options.yaml   # Includes package:lints/recommended.yaml
├── CHANGELOG.md            # Detailed release notes matching pubspec.yaml version
├── LICENSE                 # OSI-approved MIT License
├── pubspec.yaml            # Complete package metadata
├── README.md               # Standardized documentation (see Section 3)
├── lib/
│   ├── <package_name>.dart # Public barrel export file
│   └── src/                # Private implementation files
├── example/
│   └── <package_name>_example.dart  # Runnable example (powers the pub.dev Example tab)
├── doc/                    # MUST BE SINGULAR 'doc', NEVER 'docs' (plural triggers pub warning)
│   └── *.md                # Architecture/audit notes
├── benchmark/              # Official benchmarks (optional; clean of scratch files & binaries)
└── test/
    └── <package_name>_test.dart     # Comprehensive test suite
```

> [!IMPORTANT]
> **Never use `docs/` (plural)**. The official Dart Pub layout requires the documentation directory to be named **`doc/` (singular)**. Plural directory names trigger an immediate publication warning during `dart pub publish --dry-run`.

---

### 2.3. Multi-Platform & Web/WASM Readiness

For zero-dependency packages in this repository:

- Keep implementations pure Dart so they automatically score **20/20 platform points** across all 6 targets: Android, iOS, Windows, macOS, Linux, and Web (including WebAssembly / WASM).
- Never import `dart:io` unconditionally in libraries intended to support web/WASM environments. Use `dart:developer` or conditional exports when system features are needed.

---

### 2.4. Code Quality & Verification Gates

Before declaring any package ready or publishing, the following verification pipeline **must pass with zero errors**:

1. **Static Analysis**:

   ```bash
   dart analyze
   ```

   *Requirement*: 0 errors, 0 warnings, 0 lints.
2. **Code Formatting**:

   ```bash
   dart format --output=none --set-exit-if-changed .
   ```

   *Requirement*: 100% formatted according to standard Dart guidelines.
3. **Automated Tests**:

   ```bash
   dart test
   ```

   *Requirement*: 100% pass rate. Every feature and edge-case bug must have a dedicated test.
4. **Dry-Run Validation**:

   ```bash
   dart pub publish --dry-run
   ```

   *Requirement*: **Package has 0 warnings**.
5. **Local Pana Inspection** (optional local verification):

   ```bash
   dart pub global activate pana
   pana .
   ```

   *Requirement*: **160 / 160 points**.
6. **No Compiled Binaries or Scratch Files**:
   - Ensure `*.exe` is added to `.gitignore`.
   - Delete temporary scratch benchmarks or debugging scripts before publishing.
   - Archive size should be minimal (typically under 50 KB).

---

## 3. Standard `README.md` Template

Every package's `README.md` must adhere to the following visual hierarchy and structure. Replace placeholders like `<package_name>`, `<package_title>`, and `<package_description>` with package-specific data:

```markdown
# <package_name>

[![pub package](https://img.shields.io/pub/v/<package_name>.svg)](https://pub.dev/packages/<package_name>)
[![GitHub](https://img.shields.io/badge/GitHub-ahmedm--gh-blue?logo=github)](https://github.com/ahmedm-gh)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-pink?logo=github)](https://github.com/sponsors/ahmedm-gh)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

<A compelling, clear 1-2 sentence overview of what the package does and its primary value proposition.>

---

## Features

- **Feature 1**: Description.
- **Feature 2**: Description.
- **Zero Dependencies**: Pure Dart with no third-party runtime dependencies.
- **Blazing Fast**: Optimized for minimal latency and zero unnecessary allocations.

---

## Getting Started

### Installation

Add `<package_name>` to your `pubspec.yaml`:

```yaml
dependencies:
  <package_name>: ^<version>
```

Or run:

```bash
dart pub add <package_name>
# or for Flutter
flutter pub add <package_name>
```

### Import

```dart
import 'package:<package_name>/<package_name>.dart';
```

---

## Usage

### 1. Basic Usage

```dart
import 'package:<package_name>/<package_name>.dart';

void main() {
  // Clear, copy-pasteable example
}
```

### 2. Advanced Usage & Edge Cases

```dart
// Demonstrating specialized patterns, extensions, or error handling
```

---

## Supporting & Contributing

If you find `<package_name>` helpful, here are several ways you can support the project:

### 🌟 Community Support

- **Star the Repository**: Star [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages) on GitHub to help others discover it.
- **Report Issues & Ideas**: Found a bug or need an improvement? Open an issue on [GitHub Issues](https://github.com/ahmedm-gh/dart-packages/issues).
- **Contribute**: Pull requests for optimizations, documentation, or examples are always welcome.
- **Spread the Word**: Recommend `<package_name>` in your Flutter/Dart teams, blogs, or communities.

### ☕ Sponsorship & Backing

- **Sponsor on GitHub**: If this package brings value to your commercial apps, consider supporting its maintenance via [GitHub Sponsors](https://github.com/sponsors/ahmedm-gh).

## Author & Maintainer

Created and maintained by **[AHMED M.](https://github.com/ahmedm-gh)**  

- GitHub: [@ahmedm-gh](https://github.com/ahmedm-gh)
- Repository: [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages)

## License

This package is licensed under the [MIT License](./LICENSE).

```

---

## 4. Checklist for AI Agents Working on Any Package

Before completing a task or submitting changes for a package:

- [ ] `pubspec.yaml` has `name`, `description`, `version`, `repository`, `issue_tracker`, and `topics`.
- [ ] Documentation directory is named `doc/` (never `docs/`).
- [ ] `example/<package_name>_example.dart` exists, compiles, and runs cleanly.
- [ ] `README.md` includes the 4 standard badges, installation, usage, supporting & contributing, author & maintainer, and license sections.
- [ ] `CHANGELOG.md` documents the changes for the version specified in `pubspec.yaml`.
- [ ] `LICENSE` is present with the current year and author name (`AHMED M.`).
- [ ] `dart analyze` reports **0 issues**.
- [ ] `dart format` reports **0 files changed**.
- [ ] `dart test` passes **100% of tests**.
- [ ] `dart pub publish --dry-run` reports **0 warnings**.
- [ ] Package achieves or maintains **160/160 pub points** under `pana`.
