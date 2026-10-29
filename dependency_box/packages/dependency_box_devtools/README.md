# dependency_box_devtools

[![pub package](https://img.shields.io/pub/v/dependency_box_devtools.svg)](https://pub.dev/packages/dependency_box_devtools)
[![Star on GitHub](https://img.shields.io/badge/Star_on_GitHub-★-deeppink?style=flat&logo=github)](https://github.com/ahmedm-gh/dart-packages)
[![GitHub](https://img.shields.io/badge/GitHub-ahmedm--gh-blue?logo=github)](https://github.com/ahmedm-gh)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-pink?logo=github)](https://github.com/sponsors/ahmedm-gh)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

Official Flutter DevTools extension for [dependency_box](https://pub.dev/packages/dependency_box) providing interactive container inspection, scope hierarchy trees, dependency graph visualization, and health diagnostics.

---

## Features

- **Interactive Registrations Table**: Search and filter by type name, qualifying key, lifetime strategy, owning scope, and heap allocation state.
- **Scope Hierarchy Tree**: Inspect root and child scope nesting depths, direct registration counts, and disposal lifecycles.
- **Dependency Graph Viewer**: Interactive pan-and-zoom visual cluster viewer mapping services to their owning scopes.
- **Diagnostics & Health Audits**: Automatic detection of shadowed registrations, disposed scope access, and multi-registration strategies.
- **Zero Runtime Overhead**: On-demand inspection model. Absolutely zero work or allocation is performed on hot resolution paths when DevTools is inactive.
- **Memory-Safe Weak References**: DevTools holds weak references to containers, completely eliminating memory leaks.

---

## Getting Started

### Installation

Add `dependency_box` to your dependencies and `dependency_box_devtools` to your `dev_dependencies`:

```yaml
dependencies:
  dependency_box: ^1.2.0

dev_dependencies:
  dependency_box_devtools: ^1.0.0
```

Or run:

```bash
flutter pub add dependency_box
flutter pub add --dev dependency_box_devtools
```

### Import

```dart
import 'package:dependency_box/dependency_box.dart';
import 'package:dependency_box_devtools/dependency_box_devtools.dart';
```

---

## Usage

### 1. Register Container for DevTools Inspection

In your Flutter application's initialization code (typically in `main.dart`):

```dart
import 'package:flutter/material.dart';
import 'package:dependency_box/dependency_box.dart';
import 'package:dependency_box_devtools/dependency_box_devtools.dart';

void main() {
  final box = DependencyBox.main(name: 'AppRoot');

  // Register dependencies
  box.addSingleton<ApiClient>(ApiClient());
  box.addLazySingleton<AuthService>((c) => AuthService(c.get<ApiClient>()));

  // Register with DevTools (zero overhead in production)
  DependencyBoxDevTools.register(box);

  runApp(const MyApp());
}
```

### 2. Connect with Flutter DevTools

1. Run your Flutter application in debug or profile mode:
   ```bash
   flutter run
   ```
2. Open Flutter DevTools (from VS Code, Android Studio, or via `flutter run` terminal URL).
3. Select the **dependency_box** tab in DevTools.
4. Explore registrations, inspect scopes, and view the dependency layout!

---

## Supporting & Contributing

If you find `dependency_box_devtools` helpful, here are several ways you can support the project:

### 🌟 Community Support

- **Star the Repository**: Star [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages) on GitHub to help others discover it.
- **Report Issues & Ideas**: Found a bug or need an improvement? Open an issue on [GitHub Issues](https://github.com/ahmedm-gh/dart-packages/issues).
- **Contribute**: Pull requests for optimizations, documentation, or examples are always welcome.
- **Spread the Word**: Recommend `dependency_box` in your Flutter/Dart teams, blogs, or communities.

### ☕ Sponsorship & Backing

- **Sponsor on GitHub**: If this package brings value to your commercial apps, consider supporting its maintenance via [GitHub Sponsors](https://github.com/sponsors/ahmedm-gh).
- **Buy Me a Coffee**: Support development with a one-time coffee or recurring donation via [Buy Me a Coffee](https://buymeacoffee.com/ahmeds1).

## Author & Maintainer

Created and maintained by **[AHMED M.](https://github.com/ahmedm-gh)**  

- GitHub: [@ahmedm-gh](https://github.com/ahmedm-gh)
- Repository: [ahmedm-gh/dart-packages](https://github.com/ahmedm-gh/dart-packages)

## License

This package is licensed under the [MIT License](./LICENSE).

