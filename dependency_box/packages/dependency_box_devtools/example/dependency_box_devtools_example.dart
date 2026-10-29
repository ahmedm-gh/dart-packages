import 'package:dependency_box_devtools/dependency_box_devtools.dart';

void main() {
  // 1. Create a root dependency container
  final box = DependencyBox.main(name: 'AppRoot');

  // 2. Register dependencies
  box.addSingleton<String>('https://api.example.com', key: 'api_url');
  box.addLazySingleton<int>((_) => 42);

  // 3. Register the container with Flutter DevTools
  // This enables the "dependency_box" DevTools extension tab in your running app
  DependencyBoxDevTools.register(box);

  print('DependencyBox registered with Flutter DevTools!');
  print('Open Flutter DevTools to inspect registrations, scopes, and health.');

  // Clean up when shutting down
  DependencyBoxDevTools.unregister(box);
}
