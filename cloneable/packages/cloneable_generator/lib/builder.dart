import 'package:build/build.dart';
import 'package:cloneable_generator/src/cloneable_generator.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

final _formatter = DartFormatter(
  languageVersion: DartFormatter.latestLanguageVersion,
);
final _bannerRegex = RegExp(r'// \*+\s*(\n// [^\n]*)*\n// \*+');

String _cleanFormat(String code, [dynamic _]) {
  var cleaned = code.replaceAll(_bannerRegex, '');
  cleaned = cleaned.replaceAll(RegExp(r'// \*+\s*'), '');
  return _formatter.format(cleaned);
}

/// Default SharedPartBuilder for `part 'foo.g.dart';`.
Builder cloneableBuilder(BuilderOptions options) {
  final defaultPrefix = options.config['prefix'] as String?;
  final defaultSuffix = options.config['suffix'] as String?;
  return SharedPartBuilder(
    [
      CloneableGenerator(
        defaultPrefix: defaultPrefix,
        defaultSuffix: defaultSuffix,
      ),
    ],
    'cloneable',
    formatOutput: _cleanFormat,
  );
}

/// Dedicated part builder for `part 'foo_cloneable.g.dart';` or `part 'foo.cloneable.g.dart';`.
Builder cloneablePartBuilder(BuilderOptions options) {
  final defaultPrefix = options.config['prefix'] as String?;
  final defaultSuffix = options.config['suffix'] as String?;
  return PartBuilder(
    [
      CloneableGenerator(
        defaultPrefix: defaultPrefix,
        defaultSuffix: defaultSuffix,
      ),
    ],
    '_cloneable.g.dart',
    formatOutput: _cleanFormat,
  );
}

/// Standalone file builder for files without part directives (generates `foo_cloneable.dart` without `part of`).
Builder cloneableStandaloneBuilder(BuilderOptions options) {
  final defaultPrefix = options.config['prefix'] as String?;
  final defaultSuffix = options.config['suffix'] as String?;
  return LibraryBuilder(
    CloneableGenerator(
      defaultPrefix: defaultPrefix,
      defaultSuffix: defaultSuffix,
    ),
    generatedExtension: '_cloneable.dart',
    formatOutput: _cleanFormat,
  );
}
