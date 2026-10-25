import 'dart:async';
import 'package:dependency_box/dependency_box.dart';

class AppConfig {
  final String appVersion;
  AppConfig(this.appVersion);
}

class UserSession {
  final String userId;
  final String bearerToken;
  UserSession(this.userId, this.bearerToken);
}

class ScopedCartController implements DependencyDisposable {
  final String sessionId;
  final List<String> items = [];

  ScopedCartController(this.sessionId);

  void addItem(String item) {
    items.add(item);
    print(
        'Added $item to cart (Session: $sessionId). Items count: ${items.length}');
  }

  @override
  FutureOr<void> dispose() {
    print('ScopedCartController disposed for session $sessionId');
  }
}

class SharedAuditLedger {
  final List<String> auditEvents = [];
  void record(String event) {
    auditEvents.add(event);
    print('[AUDIT LEDGER] Recorded: "$event" (Total: ${auditEvents.length})');
  }
}

void main() async {
  print('=== 02 Hierarchical Scopes Example ===\n');

  // 1. Root Container
  final rootBox = DependencyBox.main(name: 'app_root');
  rootBox.addSingleton<AppConfig>(AppConfig('v2.4.0'));

  // 2. Child Scope: User Session A
  final userScopeA = rootBox.createChild(name: 'session_alice');
  userScopeA
      .addSingleton<UserSession>(UserSession('alice_1', 'token_alice_abc'));
  userScopeA.addLazySingleton<ScopedCartController>(
    (c) => ScopedCartController(c.get<UserSession>().userId),
  );

  // 3. Child Scope: User Session B
  final userScopeB = rootBox.createChild(name: 'session_bob');
  userScopeB.addSingleton<UserSession>(UserSession('bob_2', 'token_bob_xyz'));
  userScopeB.addLazySingleton<ScopedCartController>(
    (c) => ScopedCartController(c.get<UserSession>().userId),
  );

  // 4. Register a Shared Singleton from inside a child scope anchored directly to root:
  userScopeA.addSharedSingleton<SharedAuditLedger>(SharedAuditLedger());

  print('--- Resolving from User Session A ---');
  print(
      'App Version (inherited from root): ${userScopeA.get<AppConfig>().appVersion}');
  final cartA = userScopeA.get<ScopedCartController>();
  cartA.addItem('Mechanical Keyboard');

  print('\n--- Resolving from User Session B ---');
  print(
      'App Version (inherited from root): ${userScopeB.get<AppConfig>().appVersion}');
  final cartB = userScopeB.get<ScopedCartController>();
  cartB.addItem('Wireless Mouse');

  // 5. Shared Singleton is visible in child A, child B, and root!
  final ledgerA = userScopeA.get<SharedAuditLedger>();
  ledgerA.record('Alice added item');

  final ledgerB = userScopeB.get<SharedAuditLedger>();
  ledgerB.record('Bob added item');

  print(
      'Root ledger identical to child ledger: ${identical(rootBox.get<SharedAuditLedger>(), ledgerB)}');

  // 6. Child Scope Disposal: Disposing userScopeA cleans up Alice's cart, but leaves Bob and Root intact!
  print('\n--- Disposing Alice Session Scope ---');
  await userScopeA.dispose();
  print('Alice scope isDisposed: ${userScopeA.isDisposed}');
  print('Bob scope isDisposed: ${userScopeB.isDisposed}');
  print('Root scope isDisposed: ${rootBox.isDisposed}');

  // Root and Bob still function normally!
  cartB.addItem('USB-C Hub');

  // Clean up remaining scopes
  await userScopeB.dispose();
  await rootBox.dispose();
  print('\nAll scopes disposed cleanly.');
}
