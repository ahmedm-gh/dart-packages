// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'external_library.dart';

/// Strongly-typed copyWith function signature for [ExternalProfile].
typedef $ExternalProfileCopyWithFn = ExternalProfile Function({
  String username,
  String email,
});

/// Generated cloneable mixin for [ExternalProfile].
mixin _$ExternalProfileCloneable {
  $ExternalProfileCopyWithFn get copyWith => _copyWith;

  ExternalProfile _copyWith({
    Object? username = $undefined,
    Object? email = $undefined,
  }) {
    final self = this as ExternalProfile;
    return ExternalProfile(
      username:
          identical(username, $undefined) ? self.username : username as String,
      email: identical(email, $undefined) ? self.email : email as String,
    );
  }
}
