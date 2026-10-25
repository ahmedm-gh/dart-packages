import 'package:dependency_box/dependency_box.dart';

// Concrete services
class LoggerService {
  void log(String message) => print('[LOG] $message');
}

class UserService {
  final LoggerService _logger;
  UserService(this._logger);

  void createUser(String name) {
    _logger.log('User created: $name');
  }
}

class HeavyCalculationService {
  HeavyCalculationService() {
    print('HeavyCalculationService instantiated (expensive operation).');
  }

  int calculate() => 42 * 2;
}

class RequestContext {
  final DateTime timestamp = DateTime.now();
}

void main() {
  print('=== 01 Simple Registration Example ===\n');

  // 1. Create a root dependency container
  final box = DependencyBox.main(name: 'basic_root');

  // 2. Eager Singleton: Created immediately, cached forever
  final logger = LoggerService();
  box.addSingleton<LoggerService>(logger);

  // 3. Lazy Singleton: Created only on first get(), then cached
  box.addLazySingleton<HeavyCalculationService>(
    (container) => HeavyCalculationService(),
  );

  // 4. Transient Factory: Creates a fresh instance on EVERY get()
  box.addFactory<RequestContext>((container) => RequestContext());

  // 5. Service depending on another service (Constructor Injection)
  box.addLazySingleton<UserService>(
    (container) => UserService(container.get<LoggerService>()),
  );

  // 6. Resolution
  print('--- Resolving Eager Singleton ---');
  final resolvedLogger = box.get<LoggerService>();
  resolvedLogger.log('Container initialized.');

  print('\n--- Resolving Lazy Singleton (first time triggers constructor) ---');
  final calc1 = box.get<HeavyCalculationService>();
  final calc2 = box.get<HeavyCalculationService>();
  print('Calculation result: ${calc1.calculate()}');
  print('calc1 and calc2 are identical: ${identical(calc1, calc2)}');

  print(
      '\n--- Resolving Transient Factory (each call creates a new instance) ---');
  final req1 = box.get<RequestContext>();
  final req2 = box.get<RequestContext>();
  print('req1 and req2 are identical: ${identical(req1, req2)}'); // false

  print('\n--- Resolving Injected Service ---');
  final user = box.get<UserService>();
  user.createUser('Ada Lovelace');

  print('\n--- Safe Resolution with tryGet ---');
  final missing = box.tryGet<String>();
  print('Missing string resolved to: $missing'); // null

  // 7. Check existence
  print('Contains LoggerService: ${box.contains<LoggerService>()}');
  print('Contains String: ${box.contains<String>()}');
}
