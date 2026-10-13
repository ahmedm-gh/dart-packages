import 'package:value/value.dart';

/// A typical immutable data model with non-nullable and nullable fields.
class UserProfile {
  final String id;
  final String name; // Non-nullable
  final String? bio; // Nullable: can be set, cleared to null, or omitted
  final String? avatarUrl; // Nullable: can be set, cleared to null, or omitted

  const UserProfile({
    required this.id,
    required this.name,
    this.bio,
    this.avatarUrl,
  });

  /// Real-world copyWith method:
  /// - Non-nullable fields use standard Dart nullable parameters (`name`).
  /// - Nullable fields use [Val] to distinguish omitted (absent) from null.
  UserProfile copyWith({
    String? name,
    Val<String?> bio = const Val.absent(),
    Val<String?> avatarUrl = const Val.absent(),
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      bio: bio(this.bio),
      avatarUrl: avatarUrl(this.avatarUrl),
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, bio: $bio, avatarUrl: $avatarUrl)';
  }
}

void main() {
  final initialUser = UserProfile(
    id: 'u_123',
    name: 'Ahmed',
    bio: 'Mobile Developer',
    avatarUrl: 'https://example.com/ahmed.png',
  );

  print('Initial User:');
  print('  $initialUser\n');

  // 1. Partial update: Only change the name (bio & avatarUrl preserved)
  final updatedName = initialUser.copyWith(name: 'Ahmed M.');
  print('1. Updated name (bio & avatarUrl preserved):');
  print('  $updatedName\n');

  // 2. Explicitly clear a nullable field to null using Val(null)
  final clearedBio = initialUser.copyWith(bio: const Val(null));
  print('2. Cleared bio explicitly to null:');
  print('  $clearedBio\n');

  // 3. Update a nullable field with a new value using Val(...)
  final newAvatar = initialUser.copyWith(
    avatarUrl: const Val('https://example.com/new-avatar.png'),
  );
  print('3. Updated avatarUrl:');
  print('  $newAvatar\n');

  // 4. Dynamic API / JSON patch update (handles both string and null dynamically)
  final apiResponse = <String, dynamic>{
    'bio': null, // API explicitly wants to remove the bio
  };

  final patchedUser = initialUser.copyWith(
    bio: Val(apiResponse['bio'] as String?),
  );
  print('4. Dynamically patched from API response:');
  print('  $patchedUser\n');
}
