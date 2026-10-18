import 'package:cloneable_generator/cloneable_generator.dart';

/// CLI entry point for inline-only code generation:
/// `dart run cloneable_generator:inline [path]`
void main(List<String> args) => runCloneableCli(args, inlineOnly: true);
