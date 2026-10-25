import 'dart:async';
import 'package:dependency_box/dependency_box.dart';

// ============================================================================
// 1. DOMAIN ABSTRACTIONS & PRODUCTION SERVICES
// ============================================================================

abstract interface class PaymentGateway {
  Future<String> processPayment(
      {required String orderId, required double amount});
}

abstract interface class NotificationService {
  void sendConfirmation(String orderId, String recipient);
}

class RealStripeGateway implements PaymentGateway {
  final String apiKey;
  RealStripeGateway(this.apiKey);

  @override
  Future<String> processPayment(
      {required String orderId, required double amount}) async {
    // In real life, makes HTTPS call to Stripe API
    print(
        '[PROD STRIPE] Charging \$$amount on order $orderId with key ${apiKey.substring(0, 4)}...');
    return 'tx_live_${DateTime.now().millisecondsSinceEpoch}';
  }
}

class RealEmailService implements NotificationService {
  @override
  void sendConfirmation(String orderId, String recipient) {
    print(
        '[PROD EMAIL] Sending SMTP confirmation email for order $orderId to $recipient');
  }
}

class OrderCheckoutService {
  final PaymentGateway _gateway;
  final NotificationService _notifications;

  OrderCheckoutService(this._gateway, this._notifications);

  Future<String> checkout({
    required String orderId,
    required double amount,
    required String customerEmail,
  }) async {
    final transactionId = await _gateway.processPayment(
      orderId: orderId,
      amount: amount,
    );
    _notifications.sendConfirmation(orderId, customerEmail);
    return transactionId;
  }
}

/// Standard production module wiring real infrastructure
class ProductionOrderModule implements DependencyModule {
  @override
  void register(DependencyBox box) {
    box.addSingleton<PaymentGateway>(
        RealStripeGateway('sk_live_secret_key_12345'));
    box.addSingleton<NotificationService>(RealEmailService());
    box.addFactory<OrderCheckoutService>(
      (b) => OrderCheckoutService(
          b.get<PaymentGateway>(), b.get<NotificationService>()),
    );
  }
}

// ============================================================================
// 2. TEST FAKES & MOCKS
// ============================================================================

class FakePaymentGateway implements PaymentGateway, DependencyDisposable {
  final List<Map<String, dynamic>> processedTransactions = [];
  bool shouldFail = false;
  bool isDisposed = false;

  @override
  Future<String> processPayment(
      {required String orderId, required double amount}) async {
    if (shouldFail) {
      throw StateError('Simulated payment decline: Card rejected');
    }
    final txId = 'tx_fake_${processedTransactions.length + 1}';
    processedTransactions
        .add({'orderId': orderId, 'amount': amount, 'txId': txId});
    return txId;
  }

  @override
  FutureOr<void> dispose() {
    isDisposed = true;
    processedTransactions.clear();
  }
}

class FakeNotificationService implements NotificationService {
  final List<String> sentOrders = [];

  @override
  void sendConfirmation(String orderId, String recipient) {
    sentOrders.add(orderId);
  }
}

// ============================================================================
// 3. TESTING STRATEGIES & DEMONSTRATION WORKFLOW
// ============================================================================

void main() async {
  print('====================================================================');
  print('  Advanced 03: Testing, Dependency Overrides & Isolation');
  print(
      '====================================================================\n');

  // --------------------------------------------------------------------------
  // Scenario A: Isolated Container Setup (Best Practice)
  // Instead of a global container that pollutes across tests, each test creates
  // its own fresh instance of DependencyBox.main().
  // --------------------------------------------------------------------------
  print('Scenario A: Fresh Isolated Container per Test:');
  {
    final testBox = DependencyBox.main();
    final fakeGateway = FakePaymentGateway();
    final fakeNotifications = FakeNotificationService();

    testBox.addSingleton<PaymentGateway>(fakeGateway);
    testBox.addSingleton<NotificationService>(fakeNotifications);
    testBox.addFactory<OrderCheckoutService>(
      (b) => OrderCheckoutService(
          b.get<PaymentGateway>(), b.get<NotificationService>()),
    );

    final checkoutService = testBox.get<OrderCheckoutService>();
    final txId = await checkoutService.checkout(
      orderId: 'ORD-101',
      amount: 49.99,
      customerEmail: 'alice@example.com',
    );

    print('   [TEST] Checkout succeeded! Tx: $txId');
    print(
        '   [ASSERT] Recorded transactions: ${fakeGateway.processedTransactions.length} (expected 1)');
    print(
        '   [ASSERT] Notification received: ${fakeNotifications.sentOrders.contains('ORD-101')} (expected true)');

    await testBox.dispose();
    print(
        '   [TEARDOWN] Container disposed cleanly. Fake disposed: ${fakeGateway.isDisposed}\n');
  }

  // --------------------------------------------------------------------------
  // Scenario B: Module Reuse + replaceSingleton Override
  // Load standard production module, then swap out real gateway with a fake.
  // --------------------------------------------------------------------------
  print('Scenario B: Reusing Production Module with replaceSingleton:');
  {
    final testBox = DependencyBox.main();

    // 1. Install production module
    testBox.install(ProductionOrderModule());
    print(
        '   Initial gateway registered: ${testBox.get<PaymentGateway>().runtimeType}');

    // 2. Override PaymentGateway with fake implementation for test
    final fakeGateway = FakePaymentGateway();
    testBox.replaceSingleton<PaymentGateway>(fakeGateway, disposeOld: true);
    print(
        '   After replaceSingleton:     ${testBox.get<PaymentGateway>().runtimeType}');

    // 3. Verify OrderCheckoutService now uses the replaced fake
    final checkoutService = testBox.get<OrderCheckoutService>();
    final txId = await checkoutService.checkout(
      orderId: 'ORD-202',
      amount: 199.00,
      customerEmail: 'bob@example.com',
    );

    print('   [TEST] Order checked out: $txId');
    print(
        '   [ASSERT] Processed by fake: ${fakeGateway.processedTransactions.first['orderId']}');

    await testBox.dispose();
    print('   [TEARDOWN] Disposed testBox cleanly.\n');
  }

  // --------------------------------------------------------------------------
  // Scenario C: Testing Failure Scenarios with Configured Fakes
  // --------------------------------------------------------------------------
  print('Scenario C: Testing Simulated Error Scenarios:');
  {
    final testBox = DependencyBox.main();
    final fakeGateway = FakePaymentGateway()..shouldFail = true;
    final fakeNotifications = FakeNotificationService();

    testBox.addSingleton<PaymentGateway>(fakeGateway);
    testBox.addSingleton<NotificationService>(fakeNotifications);
    testBox.addFactory<OrderCheckoutService>(
      (b) => OrderCheckoutService(
          b.get<PaymentGateway>(), b.get<NotificationService>()),
    );

    final checkoutService = testBox.get<OrderCheckoutService>();

    try {
      await checkoutService.checkout(
        orderId: 'ORD-FAIL-99',
        amount: 500.00,
        customerEmail: 'eve@example.com',
      );
      print('   [ERROR] Should not have reached here!');
    } catch (e) {
      print('   [ASSERT] Expected exception caught: $e');
      print(
          '   [ASSERT] Notifications sent: ${fakeNotifications.sentOrders.length} (expected 0 due to payment failure)');
    }

    await testBox.dispose();
  }

  // --------------------------------------------------------------------------
  // Scenario D: Child Scope Overrides (Non-destructive Isolation)
  // --------------------------------------------------------------------------
  print('\nScenario D: Child Scope Overrides without mutating Base Container:');
  {
    final baseBox = DependencyBox.main();
    baseBox.addSingleton<PaymentGateway>(RealStripeGateway('sk_base'));

    // Create child scope and shadow PaymentGateway
    final testChild = baseBox.createChild();
    final fakeGateway = FakePaymentGateway();
    testChild.addSingleton<PaymentGateway>(fakeGateway);

    print(
        '   Child sees gateway: ${testChild.get<PaymentGateway>().runtimeType} (Fake)');
    print(
        '   Base sees gateway:  ${baseBox.get<PaymentGateway>().runtimeType} (Real Stripe)');

    await testChild.dispose();
    print(
        '   After child disposed, base is still intact: ${baseBox.get<PaymentGateway>().runtimeType}');
    await baseBox.dispose();
  }

  print('\n[SUCCESS] All testing and dependency override patterns verified!');
}
