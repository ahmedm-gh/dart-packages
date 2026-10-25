import 'package:dependency_box/dependency_box.dart';

// ============================================================================
// 1. SAMPLE SERVICES & CIRCULAR DEPENDENCY DEMONSTRATION CLASSES
// ============================================================================

class DatabaseConnection {
  final String host;
  DatabaseConnection(this.host);
}

class AuthService {
  final DatabaseConnection db;
  AuthService(this.db);
}

class Logger {
  final String tag;
  Logger(this.tag);
}

// Circular dependency pair:
// ServiceAlpha depends on ServiceBeta, and ServiceBeta depends on ServiceAlpha
class ServiceAlpha {
  final ServiceBeta beta;
  ServiceAlpha(this.beta);
}

class ServiceBeta {
  final ServiceAlpha alpha;
  ServiceBeta(this.alpha);
}

// ============================================================================
// 2. DIAGNOSTICS & DEBUGGING WORKFLOW
// ============================================================================

void main() {
  print('====================================================================');
  print('  Advanced 04: Diagnostics, ASCII Container Tree & Debugging');
  print(
      '====================================================================\n');

  // --------------------------------------------------------------------------
  // Step 1: Named Hierarchy & Multi-Registrations
  // --------------------------------------------------------------------------
  print('1. Creating Named Container Hierarchy (Root -> FeatureScope):');
  final rootBox = DependencyBox.main(name: 'RootContainer');

  // Register some dependencies in root
  rootBox.addSingleton<DatabaseConnection>(
      DatabaseConnection('postgres.internal'));
  rootBox.addLazySingleton<Logger>((_) => Logger('GlobalLogger'));

  // Configure a multi-registration on root
  rootBox.allowMulti<String>(resolution: MultiResolution.last);
  rootBox.addSingleton<String>('RootInterceptorA');
  rootBox.addSingleton<String>('RootInterceptorB');

  // Create a named child scope
  final featureBox = rootBox.createChild(name: 'CheckoutScope');

  // Register child-specific dependency and shadow the root Logger
  featureBox.addSingleton<AuthService>(
      AuthService(featureBox.get<DatabaseConnection>()));
  featureBox.addSingleton<Logger>(
      Logger('CheckoutScopedLogger')); // Shadows root Logger!

  // --------------------------------------------------------------------------
  // Step 2: Diagnostic ASCII Container Tree (printContainer)
  // --------------------------------------------------------------------------
  print('\n2. Inspecting Child Container Tree via printContainer():');
  print('--------------------------------------------------------------------');
  featureBox.printContainer();
  print(
      '--------------------------------------------------------------------\n');

  // --------------------------------------------------------------------------
  // Step 3: Inspecting Registered Keys
  // --------------------------------------------------------------------------
  print('3. Inspecting registeredKeys:');
  for (final key in featureBox.registeredKeys) {
    print('   - Key: $key');
  }

  // --------------------------------------------------------------------------
  // Step 4: Circular Dependency Detection & Error Reporting
  // --------------------------------------------------------------------------
  print('\n4. Circular Dependency Detection:');
  print(
      '   (Detected in debug mode for lazy singletons, cached factories & async singletons)');
  final testBox = DependencyBox.main(name: 'CircularTestBox');

  // Register two services that cyclically depend on each other as lazy singletons
  testBox.addLazySingleton<ServiceAlpha>(
      (b) => ServiceAlpha(b.get<ServiceBeta>()));
  testBox
      .addLazySingleton<ServiceBeta>((b) => ServiceBeta(b.get<ServiceAlpha>()));

  try {
    print('   Attempting to resolve ServiceAlpha...');
    testBox.get<ServiceAlpha>();
    print('   [ERROR] Expected circular dependency error was not thrown!');
  } on StateError catch (e) {
    print('   [CAUGHT EXPECTED STATE ERROR]');
    print('   -> ${e.message}');
  }

  // --------------------------------------------------------------------------
  // Step 5: Missing Dependency Diagnostic
  // --------------------------------------------------------------------------
  print('\n5. Missing Dependency Diagnostic:');
  try {
    print('   Attempting to resolve unregistered int...');
    testBox.get<int>();
  } on StateError catch (e) {
    print('   [CAUGHT EXPECTED STATE ERROR]');
    print('   -> ${e.message}');
  }

  print('\n[SUCCESS] Diagnostics and debugging suite completed cleanly!');
}
