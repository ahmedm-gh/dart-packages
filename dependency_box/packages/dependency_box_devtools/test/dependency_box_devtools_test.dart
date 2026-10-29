import 'package:dependency_box_devtools/dependency_box_devtools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dependency_box_devtools exports', () {
    test('exports DependencyBoxDevTools and models from dependency_box', () {
      expect(
        DependencyBoxDevTools.getSnapshotMethod,
        equals('ext.dependencyBox.getSnapshot'),
      );
      expect(
        DependencyBoxDevTools.getSnapshotAlias,
        equals('ext.dependency_box.getSnapshot'),
      );
      expect(DependencyBoxDevTools.isEnabled, isFalse);
    });

    test('captures snapshot using core ContainerInspector', () {
      final box = DependencyBox.main(name: 'devtoolsTest');
      box.addSingleton<String>('hello');

      final snapshot = box.getSnapshot();
      expect(snapshot.rootScope.name, equals('devtoolsTest'));
      expect(snapshot.totalRegistrations, equals(1));
      expect(snapshot.registrations.first.typeName, equals('String'));
    });
  });
}
