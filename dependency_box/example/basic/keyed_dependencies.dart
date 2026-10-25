import 'package:dependency_box/dependency_box.dart';

// Enum keys are type-safe and refactor-friendly
enum Environment { development, staging, production }

class DatabaseConfig {
  final String url;
  final int maxConnections;

  const DatabaseConfig({required this.url, required this.maxConnections});

  @override
  String toString() => 'DatabaseConfig(url: $url, max: $maxConnections)';
}

void main() {
  print('=== 03 Keyed Dependencies Example ===\n');

  final box = DependencyBox.main();

  // 1. Enum Keys (Recommended for environments / flavors)
  box.addSingleton<DatabaseConfig>(
    const DatabaseConfig(
      url: 'postgres://localhost:5432/dev_db',
      maxConnections: 5,
    ),
    key: Environment.development,
  );

  box.addSingleton<DatabaseConfig>(
    const DatabaseConfig(
      url: 'postgres://staging.internal:5432/stage_db',
      maxConnections: 20,
    ),
    key: Environment.staging,
  );

  box.addSingleton<DatabaseConfig>(
    const DatabaseConfig(
      url: 'postgres://prod-cluster.cloud:5432/app_prod',
      maxConnections: 100,
    ),
    key: Environment.production,
  );

  // 2. String Keys (Useful for named endpoints or dynamic identifiers)
  box.addSingleton<String>('https://api.github.com', key: 'github_api');
  box.addSingleton<String>('https://api.stripe.com', key: 'stripe_api');

  // 3. Symbol Keys
  box.addSingleton<int>(8080, key: #server_port);
  box.addSingleton<int>(9090, key: #admin_port);

  // Resolution by Key
  print('--- Resolving by Enum Key ---');
  final devDb = box.get<DatabaseConfig>(key: Environment.development);
  final prodDb = box.get<DatabaseConfig>(key: Environment.production);
  print('Dev Database: $devDb');
  print('Prod Database: $prodDb');

  print('\n--- Resolving by String Key ---');
  print('GitHub API: ${box.get<String>(key: 'github_api')}');
  print('Stripe API: ${box.get<String>(key: 'stripe_api')}');

  print('\n--- Resolving by Symbol Key ---');
  print('Server Port: ${box.get<int>(key: #server_port)}');
  print('Admin Port: ${box.get<int>(key: #admin_port)}');

  // Keyed registrations do not conflict with unkeyed ones
  box.addSingleton<String>('Default Keyless String');
  print('\nKeyless String: ${box.get<String>()}');
}
