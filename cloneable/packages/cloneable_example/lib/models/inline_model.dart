import 'package:cloneable/cloneable.dart';

/// Example of an inline cloneable class.
///
/// Running `dart run cloneable_generator:inline` generates the copyWith
/// implementation directly in this file between delimiter comments without
/// requiring a separate part or file.
@Cloneable(inline: true)
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

// cloneable:start (InlineUser) - GENERATED CODE - DO NOT MODIFY BY HAND
// (run: dart run cloneable_generator to regenerate)

/// Strongly-typed copyWith function signature for [InlineUser].
typedef $InlineUserCopyWith = InlineUser Function({
  String id,
  String name,
  String? email,
});

/// Generated cloneable extension for [InlineUser].
extension $InlineUserCloneableExtension on InlineUser {
  $InlineUserCopyWith get copyWith => _copyWith;

  InlineUser _copyWith({
    Object? id = cloneableUndefined,
    Object? name = cloneableUndefined,
    Object? email = cloneableUndefined,
  }) {
    final self = this;
    return InlineUser(
      id: identical(id, cloneableUndefined) ? self.id : id as String,
      name: identical(name, cloneableUndefined) ? self.name : name as String,
      email:
          identical(email, cloneableUndefined) ? self.email : email as String?,
    );
  }
}

// cloneable:end (InlineUser)
