import 'package:dependency_box/dependency_box.dart';

// --- Domain & Services ---
class DatabaseService {
  final String connectionString;
  DatabaseService(this.connectionString);
}

class AuthService {
  final DatabaseService db;
  AuthService(this.db);
  void authenticate(String user) => print('Authenticated $user');
}

class PaymentGateway {
  final String apiKey;
  PaymentGateway(this.apiKey);
  void charge(double amount) => print('Charged \$$amount successfully');
}

class OrderService {
  final PaymentGateway gateway;
  final DatabaseService db;
  OrderService(this.gateway, this.db);
  void createOrder(String item, double price) {
    gateway.charge(price);
    print('Order created for $item in database: ${db.connectionString}');
  }
}

// --- Modules ---

// 1. Core / Infrastructure Module
class CoreInfrastructureModule implements DependencyModule {
  final String dbUrl;
  const CoreInfrastructureModule({required this.dbUrl});

  @override
  void register(DependencyBox box) {
    box.addSingleton<DatabaseService>(DatabaseService(dbUrl));
  }
}

// 2. Authentication Feature Module
class AuthFeatureModule implements DependencyModule {
  @override
  void register(DependencyBox box) {
    box.addLazySingleton<AuthService>(
      (container) => AuthService(container.get<DatabaseService>()),
    );
  }
}

// 3. Billing Feature Module
class BillingFeatureModule implements DependencyModule {
  final String stripeKey;
  const BillingFeatureModule({required this.stripeKey});

  @override
  void register(DependencyBox box) {
    box.addSingleton<PaymentGateway>(PaymentGateway(stripeKey));
    box.addLazySingleton<OrderService>(
      (container) => OrderService(
        container.get<PaymentGateway>(),
        container.get<DatabaseService>(),
      ),
    );
  }
}

void main() {
  print('=== 01 Modules and Composition Example ===\n');

  final box = DependencyBox.main(name: 'application_root');

  // Install single module
  box.install(const CoreInfrastructureModule(
      dbUrl: 'postgres://app:secret@db:5432/main'));

  // Install multiple feature modules simultaneously
  box.installAll([
    AuthFeatureModule(),
    const BillingFeatureModule(stripeKey: 'sk_live_abc123xyz'),
  ]);

  print('Installed all modules. Direct registered count: ${box.length}');

  // Resolve and exercise services
  final auth = box.get<AuthService>();
  auth.authenticate('admin');

  final orders = box.get<OrderService>();
  orders.createOrder('Dart Architecture Book', 49.99);

  print('\nComposition root wiring completed cleanly.');
}
