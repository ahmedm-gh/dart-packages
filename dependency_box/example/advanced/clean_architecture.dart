import 'dart:async';
import 'package:dependency_box/dependency_box.dart';

// ============================================================================
// 1. DOMAIN LAYER (Zero external dependencies, pure business logic)
// ============================================================================

class User {
  final String id;
  final String email;
  final String displayName;
  const User(
      {required this.id, required this.email, required this.displayName});

  @override
  String toString() => 'User($id, $email, $displayName)';
}

abstract interface class UserRepository {
  Future<User?> findById(String id);
  Future<void> save(User user);
}

abstract interface class PasswordHasher {
  String hash(String rawPassword);
}

class RegisterUserUseCase {
  final UserRepository _repository;
  final PasswordHasher _hasher;

  RegisterUserUseCase(this._repository, this._hasher);

  Future<User> execute({
    required String id,
    required String email,
    required String displayName,
    required String rawPassword,
  }) async {
    final existing = await _repository.findById(id);
    if (existing != null) {
      throw StateError('User with id "$id" already exists!');
    }

    final hashedPassword = _hasher.hash(rawPassword);
    print('[USE CASE] Password hashed securely: $hashedPassword');

    final newUser = User(id: id, email: email, displayName: displayName);
    await _repository.save(newUser);
    return newUser;
  }
}

class GetUserProfileUseCase {
  final UserRepository _repository;
  GetUserProfileUseCase(this._repository);

  Future<User> execute(String id) async {
    final user = await _repository.findById(id);
    if (user == null) {
      throw StateError('User not found: $id');
    }
    return user;
  }
}

// ============================================================================
// 2. DATA LAYER (Infrastructure, databases, network implementations)
// ============================================================================

class Sha256PasswordHasher implements PasswordHasher {
  @override
  String hash(String rawPassword) {
    // Simulated hash algorithm
    return 'sha256_${rawPassword.split('').reversed.join()}_salt';
  }
}

class InMemoryUserRepository implements UserRepository {
  final Map<String, User> _store = {};

  @override
  Future<User?> findById(String id) async {
    return _store[id];
  }

  @override
  Future<void> save(User user) async {
    _store[user.id] = user;
    print('[DATA] Saved user to storage: ${user.id}');
  }
}

// ============================================================================
// 3. PRESENTATION / CONTROLLER LAYER
// ============================================================================

class UserController {
  final RegisterUserUseCase _registerUser;
  final GetUserProfileUseCase _getUserProfile;

  UserController(this._registerUser, this._getUserProfile);

  Future<void> handleSignUp(
      String id, String email, String name, String password) async {
    print('--> User controller handling registration for: $name');
    final user = await _registerUser.execute(
      id: id,
      email: email,
      displayName: name,
      rawPassword: password,
    );
    print('<-- Registration completed for: $user');
  }

  Future<void> handleGetProfile(String id) async {
    final user = await _getUserProfile.execute(id);
    print('Fetched profile: ${user.displayName} (${user.email})');
  }
}

// ============================================================================
// 4. COMPOSITION ROOT (Dependency Injection Wiring)
// ============================================================================

class UserFeatureModule implements DependencyModule {
  @override
  void register(DependencyBox box) {
    // 1. Bind abstractions to implementations
    box.addLazySingleton<PasswordHasher>((c) => Sha256PasswordHasher());
    box.addLazySingleton<UserRepository>((c) => InMemoryUserRepository());

    // 2. Wire Use Cases with constructor injection
    box.addLazySingleton<RegisterUserUseCase>(
      (c) => RegisterUserUseCase(
        c.get<UserRepository>(),
        c.get<PasswordHasher>(),
      ),
    );

    box.addLazySingleton<GetUserProfileUseCase>(
      (c) => GetUserProfileUseCase(c.get<UserRepository>()),
    );

    // 3. Controller is a factory (created per screen or request lifecycle)
    box.addFactory<UserController>(
      (c) => UserController(
        c.get<RegisterUserUseCase>(),
        c.get<GetUserProfileUseCase>(),
      ),
    );
  }
}

void main() async {
  print('=== 01 Clean Architecture Real-World Example ===\n');

  final container = DependencyBox.main(name: 'app_container');

  // Install feature module
  container.install(UserFeatureModule());

  // Resolve presentation controller
  final controller = container.get<UserController>();

  // Run business flows
  await controller.handleSignUp(
    'usr_101',
    'grace.hopper@nanoseconds.io',
    'Grace Hopper',
    'CompilerPioneer1952!',
  );

  await controller.handleGetProfile('usr_101');

  print('\nClean Architecture flow executed successfully.');
}
