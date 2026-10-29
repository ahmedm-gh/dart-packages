/// DevTools runtime integration and inspection APIs for `dependency_box`.
///
/// This library provides opt-in integration with Flutter DevTools and Dart VM Service
/// protocol extensions. It does not introduce any third-party dependencies or runtime
/// overhead unless explicitly enabled via [DependencyBoxDevTools.register].
library;

export 'src/devtools/devtools_service.dart';
export 'src/inspection/container_inspector.dart';
export 'src/inspection/inspection_models.dart';
