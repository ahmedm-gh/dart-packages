import 'package:build/build.dart';
import 'package:cloneable_generator/src/cloneable_generator.dart';
import 'package:source_gen/source_gen.dart';

/// Default SharedPartBuilder for `part 'foo.g.dart';`.
Builder cloneableBuilder(BuilderOptions options) {
  return SharedPartBuilder(
    const [CloneableGenerator()],
    'cloneable',
  );
}

/// Dedicated part builder for `part 'foo_cloneable.g.dart';` or `part 'foo.cloneable.g.dart';`.
Builder cloneablePartBuilder(BuilderOptions options) {
  return PartBuilder(
    const [CloneableGenerator()],
    '_cloneable.g.dart',
  );
}

/// Standalone file builder for files without part directives (generates `foo_cloneable.dart` without `part of`).
Builder cloneableStandaloneBuilder(BuilderOptions options) {
  return LibraryBuilder(
    const CloneableGenerator(),
    generatedExtension: '_cloneable.dart',
  );
}
