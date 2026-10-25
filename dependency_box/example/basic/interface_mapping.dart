import 'package:dependency_box/dependency_box.dart';

// 1. Abstract Interface
abstract interface class NotificationSender {
  void send(String recipient, String message);
}

// 2. Concrete Implementation A
class EmailNotificationSender implements NotificationSender {
  @override
  void send(String recipient, String message) {
    print('Sending EMAIL to $recipient: $message');
  }
}

// 3. Concrete Implementation B
class SmsNotificationSender implements NotificationSender {
  @override
  void send(String recipient, String message) {
    print('Sending SMS to $recipient: $message');
  }
}

// 4. Consuming Service: Depends only on the abstract interface!
class OrderAlertService {
  final NotificationSender _sender;
  OrderAlertService(this._sender);

  void alertOrderPlaced(String customer, String orderId) {
    _sender.send(customer, 'Your order #$orderId has been confirmed!');
  }
}

void main() {
  print('=== 02 Interface Mapping Example ===\n');

  final box = DependencyBox.main();

  // Register Email implementation under the abstract NotificationSender interface type:
  // Note: Specify <NotificationSender> as the generic type!
  box.addLazySingleton<NotificationSender>(
    (container) => EmailNotificationSender(),
  );

  // Inject the interface into OrderAlertService
  box.addLazySingleton<OrderAlertService>(
    (container) => OrderAlertService(container.get<NotificationSender>()),
  );

  // Resolve by interface type
  final sender = box.get<NotificationSender>();
  print('Resolved sender runtime type: ${sender.runtimeType}');

  final alertService = box.get<OrderAlertService>();
  alertService.alertOrderPlaced('customer@example.com', 'ORD-9872');

  // We can easily verify type compatibility
  assert(sender is EmailNotificationSender);
  print('\nInterface mapping verified successfully.');
}
