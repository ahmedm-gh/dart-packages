import 'package:caster/caster.dart';

class User {
  final int id;
  final String name;
  final bool isAdmin;

  const User({required this.id, required this.name, this.isAdmin = false});

  @override
  String toString() => 'User(id: $id, name: "$name", isAdmin: $isAdmin)';
}

void main() {
  print('--- 1. Safe Casting with Primitives & Fallbacks ---');
  // Safe cast with fallback
  final age = safeCast<int>('not_a_number', fallback: 18);
  print('Age (with fallback): $age'); // 18

  // Built-in default values (0 for int, '' for String, false for bool)
  final defaultInt = safeCast<int>('invalid');
  final defaultString = safeCast<String>(12345);
  final defaultBool = safeCast<bool>(null);
  print('Default int: $defaultInt'); // 0
  print('Default String: "$defaultString"'); // ""
  print('Default bool: $defaultBool'); // false

  // Safe cast or null
  final maybeInt = safeCastOrNull<int>('invalid');
  print('Safe cast or null: $maybeInt'); // null

  print('\n--- 2. Custom Type Defaults ---');
  Caster.registerDefaultValues({User: const User(id: 0, name: 'Guest')});

  final guestUser = safeCast<User>('corrupted_user_data');
  print(
    'Resolved custom default: $guestUser',
  ); // User(id: 0, name: "Guest", isAdmin: false)

  print('\n--- 3. MapCaster Extensions for Untrusted Payloads ---');
  final apiResponse = <String, dynamic>{
    'user_id': 101,
    'user_name': 'Ahmed',
    'scores': [95, 87, 'invalid', 100],
    'settings': {'notifications': true},
  };

  // Extract values safely
  final userId = apiResponse.safeCast<int>('user_id');
  final userName = apiResponse.safeCast<String>('user_name');
  final role = apiResponse.safeCast<String>('role', fallback: 'standard_user');
  final maybeToken = apiResponse.safeCastOrNull<String>('auth_token');
  print(
    'Extracted userId: $userId, name: $userName, role: $role, token: $maybeToken',
  );

  // Key fallbacks (e.g., legacy or alternative API key names)
  final displayName = apiResponse.safeCastFirst<String>([
    'nickname',
    'display_name',
    'user_name',
  ], fallback: 'Anonymous');
  print('Display name (fallback chain): $displayName');

  // Filtering collections safely
  final validScores = apiResponse.safeCastList<int>('scores');
  print('Filtered valid scores: $validScores'); // [95, 87, 100]

  final scoresWithDefault = apiResponse.safeCastList<int>(
    'scores',
    fallback: 0,
  );
  print('Scores with element fallback: $scoresWithDefault'); // [95, 87, 0, 100]

  // Value converters
  final createdDate = apiResponse.convert<DateTime>(
    'created_at',
    converter: (v) => v is String ? DateTime.tryParse(v) : null,
    fallback: DateTime(2026, 1, 1),
  );
  print('Converted creation date: $createdDate');

  // Optional conversion (returns T? without requiring a fallback)
  final maybeDate = apiResponse.tryConvert<DateTime>(
    'updated_at',
    converter: (v) => v is String ? DateTime.tryParse(v) : null,
  );
  print('Try converted date: $maybeDate'); // null

  // Convert list elements into parsed types with element fallback
  final doubledScores = apiResponse.convertList<int>(
    'scores',
    converter: (v) => v is num ? (v * 2).toInt() : null,
    fallback: 0,
  );
  print('Doubled scores: $doubledScores'); // [190, 174, 0, 200]

  // Safe list extraction or null when key is absent/not an iterable
  final maybeTags = apiResponse.safeCastListOrNull<String>('missing_tags');
  final maybeItems = apiResponse.convertListOrNull<int>(
    'missing_items',
    converter: (v) => v is num ? v.toInt() : null,
  );
  print('Missing list extraction: $maybeTags, $maybeItems'); // null, null
}
