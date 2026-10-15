import 'package:build/build.dart';
import 'package:cloneable_generator/src/cloneable_generator.dart';
import 'package:source_gen/source_gen.dart';

/// Builder factory function for `build_runner`.
Builder cloneableBuilder(BuilderOptions options) {
  return SharedPartBuilder(
    [const CloneableGenerator()],
    'cloneable',
  );
}
