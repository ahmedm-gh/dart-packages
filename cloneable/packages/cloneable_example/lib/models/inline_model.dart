import 'package:cloneable/cloneable.dart';

/// Example of an inline cloneable class.
///
/// Running `dart run cloneable_generator:inline` generates the copyWith
/// implementation directly in this file between delimiter comments without
/// requiring a separate part or file.
@Cloneable(output: CloneableOutput.inLibrary)
class InlineUser {
  final String id;
  final String name;
  final String? email;

  const InlineUser({
    required this.id,
    required this.name,
    this.email,
  });
}

/// Example of an inline cloneable class with custom prefix.
@Cloneable(
  output: CloneableOutput.inLibrary,
  naming: CloneableNaming(
    extension: CloneableAffix(prefix: 'Custom'),
    typedef: CloneableAffix(prefix: 'Custom'),
  ),
)
class CustomInlineConfig {
  final String key;
  final String value;

  const CustomInlineConfig({
    required this.key,
    required this.value,
  });
}

// cloneable:start (InlineUser) - GENERATED CODE - DO NOT MODIFY BY HAND
// (run: dart run cloneable_generator to regenerate)

/// Strongly-typed copyWith function signature for [InlineUser].
typedef $InlineUserCopyWithFn = InlineUser Function({
  String id,
  String name,
  String? email,
});

/// Generated cloneable extension for [InlineUser].
extension $InlineUserExtension on InlineUser {
  $InlineUserCopyWithFn get copyWith => _copyWith;

  InlineUser _copyWith({
    Object? id = $undefined,
    Object? name = $undefined,
    Object? email = $undefined,
  }) {
    final self = this;
    return InlineUser(
      id: identical(id, $undefined) ? self.id : id as String,
      name: identical(name, $undefined) ? self.name : name as String,
      email: identical(email, $undefined) ? self.email : email as String?,
    );
  }
}

// cloneable:end (InlineUser)

// cloneable:start (CustomInlineConfig) - GENERATED CODE - DO NOT MODIFY BY HAND
// (run: dart run cloneable_generator to regenerate)

/// Strongly-typed copyWith function signature for [CustomInlineConfig].
typedef CustomCustomInlineConfigCopyWithFn = CustomInlineConfig Function({
  String key,
  String value,
});

/// Generated cloneable extension for [CustomInlineConfig].
extension CustomCustomInlineConfigExtension on CustomInlineConfig {
  CustomCustomInlineConfigCopyWithFn get copyWith => _copyWith;

  CustomInlineConfig _copyWith({
    Object? key = $undefined,
    Object? value = $undefined,
  }) {
    final self = this;
    return CustomInlineConfig(
      key: identical(key, $undefined) ? self.key : key as String,
      value: identical(value, $undefined) ? self.value : value as String,
    );
  }
}

// cloneable:end (CustomInlineConfig)
