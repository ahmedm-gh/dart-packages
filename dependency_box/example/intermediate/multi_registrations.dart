import 'package:dependency_box/dependency_box.dart';

// Interface for multi-registered plugins
abstract interface class LogInterceptor {
  String get name;
  void onLog(String message);
}

class ConsoleInterceptor implements LogInterceptor {
  @override
  String get name => 'Console';

  @override
  void onLog(String message) => print('[Console] $message');
}

class FileInterceptor implements LogInterceptor {
  @override
  String get name => 'File';

  @override
  void onLog(String message) => print('[File /var/log/app.log] $message');
}

class RemoteTelemetryInterceptor implements LogInterceptor {
  @override
  String get name => 'RemoteTelemetry';

  @override
  void onLog(String message) => print('[Remote APM] $message');
}

void main() {
  print('=== 03 Multi-Registrations Example ===\n');

  final box = DependencyBox.main();

  // 1. Enable multiple registrations for LogInterceptor with default strategy (LastResolution)
  box.allowMulti<LogInterceptor>();

  // Register multiple implementations
  box.addSingleton<LogInterceptor>(ConsoleInterceptor());
  box.addSingleton<LogInterceptor>(FileInterceptor());
  box.addSingleton<LogInterceptor>(RemoteTelemetryInterceptor());

  // 2. Retrieve ALL registered instances via getAll()
  final allInterceptors = box.getAll<LogInterceptor>();
  print('Total interceptors registered: ${allInterceptors.length}');
  for (final interceptor in allInterceptors) {
    interceptor.onLog('System health check OK');
  }

  // 3. By default (MultiResolution.last), get() resolves the most recent one
  final activeInterceptor = box.get<LogInterceptor>();
  print(
      '\nDefault get() resolved active interceptor: ${activeInterceptor.name}'); // RemoteTelemetry

  // 4. Batch registration with addSingletons
  box.allowMultiple([
    const MultiRegistration<
        String>.first(), // Resolves the first registered instance
  ]);

  box.addSingletons<String>([
    'Primary Cluster Server',
    'Secondary Backup Server',
    'Tertiary Standby Server',
  ]);

  print('\n--- Resolving MultiRegistration.first ---');
  print(
      'Active Server via get(): ${box.get<String>()}'); // Primary Cluster Server
  print('All Servers via getAll(): ${box.getAll<String>()}');

  // 5. Custom Index Strategy
  final customBox = DependencyBox.main();
  customBox.allowMulti<int>(resolution: const MultiResolution.at(1));
  customBox.addSingletons<int>([10, 20, 30]);
  print('\nIndex Resolution (at index 1): ${customBox.get<int>()}'); // 20
}
