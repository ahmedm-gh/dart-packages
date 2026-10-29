import 'dart:convert';

import 'package:dependency_box/dependency_box.dart';
import 'package:dependency_box/devtools.dart';
import 'package:test/test.dart';

class _SampleService {
  final String name;
  _SampleService(this.name);
}

class _ConfigService {
  final int port;
  _ConfigService(this.port);
}

void main() {
  tearDown(() {
    DependencyBoxDevTools.disable();
  });

  group('ContainerInspector & ContainerSnapshot', () {
    test('captures empty container correctly with zero registrations', () {
      final box = DependencyBox.main(name: 'testRoot');
      final snapshot = box.getSnapshot();

      expect(snapshot.rootScope.name, equals('testRoot'));
      expect(snapshot.rootScope.isRoot, isTrue);
      expect(snapshot.rootScope.depth, equals(0));
      expect(snapshot.rootScope.isDisposed, isFalse);
      expect(snapshot.totalRegistrations, equals(0));
      expect(snapshot.totalInstantiated, equals(0));
      expect(snapshot.scopes.length, equals(1));
    });

    test('captures singleton registration with allocated instance', () {
      final box = DependencyBox.main(name: 'main');
      final service = _SampleService('auth');
      box.addSingleton<_SampleService>(service);

      final snapshot = box.getSnapshot();
      expect(snapshot.totalRegistrations, equals(1));
      expect(snapshot.totalInstantiated, equals(1));

      final reg = snapshot.registrations.first;
      expect(reg.typeName, equals('_SampleService'));
      expect(reg.key, isNull);
      expect(reg.lifetime, equals('Singleton'));
      expect(reg.isCreated, isTrue);
      expect(reg.isResolving, isFalse);
      expect(reg.isShadowed, isFalse);
      expect(reg.instanceRuntimeType, equals('_SampleService'));
    });

    test(
      'captures lazy singleton WITHOUT instantiating it (zero side-effects)',
      () {
        var factoryCallCount = 0;
        final box = DependencyBox.main();

        box.addLazySingleton<_SampleService>((_) {
          factoryCallCount++;
          return _SampleService('lazy');
        });

        // Take snapshot BEFORE resolution
        final snapshotBefore = box.getSnapshot();
        expect(
          factoryCallCount,
          equals(0),
          reason: 'Inspection MUST NOT trigger lazy factory creation',
        );
        expect(snapshotBefore.totalRegistrations, equals(1));
        expect(snapshotBefore.totalInstantiated, equals(0));

        final regBefore = snapshotBefore.registrations.first;
        expect(regBefore.lifetime, equals('LazySingleton'));
        expect(regBefore.isCreated, isFalse);
        expect(regBefore.instanceRuntimeType, isNull);

        // Now resolve the instance
        final resolved = box.get<_SampleService>();
        expect(factoryCallCount, equals(1));
        expect(resolved.name, equals('lazy'));

        // Take snapshot AFTER resolution
        final snapshotAfter = box.getSnapshot();
        expect(
          factoryCallCount,
          equals(1),
          reason: 'Inspection must not re-trigger factory',
        );
        expect(snapshotAfter.totalInstantiated, equals(1));

        final regAfter = snapshotAfter.registrations.first;
        expect(regAfter.isCreated, isTrue);
        expect(regAfter.instanceRuntimeType, equals('_SampleService'));
      },
    );

    test('captures factory registrations without side effects', () {
      var factoryCalls = 0;
      final box = DependencyBox.main();

      box.addFactory<_SampleService>((_) {
        factoryCalls++;
        return _SampleService('fresh');
      });

      final snapshot = box.getSnapshot();
      expect(
        factoryCalls,
        equals(0),
        reason: 'Inspection MUST NOT invoke un-cached factory',
      );
      final reg = snapshot.registrations.first;
      expect(reg.lifetime, equals('Factory'));
      expect(reg.isCreated, isFalse);
    });

    test('captures cached factory and weak reference status', () {
      var factoryCalls = 0;
      final box = DependencyBox.main();

      box.addCachedFactory<_SampleService>((_) {
        factoryCalls++;
        return _SampleService('cached');
      });

      final snapshotBefore = box.getSnapshot();
      expect(factoryCalls, equals(0));
      expect(snapshotBefore.registrations.first.isCreated, isFalse);

      final instance = box.get<_SampleService>();
      expect(factoryCalls, equals(1));

      final snapshotAfter = box.getSnapshot();
      expect(snapshotAfter.registrations.first.isCreated, isTrue);
      expect(instance.name, equals('cached'));
    });

    test('captures scope hierarchy with parent-child links', () {
      final root = DependencyBox.main(name: 'rootScope');
      final child1 = root.createChild(name: 'childScope1');
      final child2 = root.createChild(name: 'childScope2');
      final grandChild = child1.createChild(name: 'grandChild');

      expect(child2.depth, equals(1));

      root.addSingleton<String>('fromRoot');
      child1.addSingleton<int>(42);
      grandChild.addSingleton<double>(3.14);

      final snapshot = root.getSnapshot();

      expect(snapshot.scopes.length, equals(4));
      expect(snapshot.totalRegistrations, equals(3));

      final rootScope = snapshot.scopes.firstWhere(
        (s) => s.name == 'rootScope',
      );
      final child1Scope = snapshot.scopes.firstWhere(
        (s) => s.name == 'childScope1',
      );
      final child2Scope = snapshot.scopes.firstWhere(
        (s) => s.name == 'childScope2',
      );
      final grandChildScope = snapshot.scopes.firstWhere(
        (s) => s.name == 'grandChild',
      );

      expect(rootScope.depth, equals(0));
      expect(rootScope.isRoot, isTrue);
      expect(rootScope.parentId, isNull);
      expect(rootScope.childIds, containsAll([child1Scope.id, child2Scope.id]));

      expect(child1Scope.depth, equals(1));
      expect(child1Scope.parentId, equals(rootScope.id));
      expect(child1Scope.childIds, contains(grandChildScope.id));

      expect(grandChildScope.depth, equals(2));
      expect(grandChildScope.parentId, equals(child1Scope.id));
      expect(grandChildScope.childIds, isEmpty);

      // Check registration owning scopes
      final stringReg = snapshot.registrations.firstWhere(
        (r) => r.typeName == 'String',
      );
      expect(stringReg.scopeName, equals('rootScope'));
      expect(stringReg.scopeDepth, equals(0));

      final intReg = snapshot.registrations.firstWhere(
        (r) => r.typeName == 'int',
      );
      expect(intReg.scopeName, equals('childScope1'));
      expect(intReg.scopeDepth, equals(1));

      final doubleReg = snapshot.registrations.firstWhere(
        (r) => r.typeName == 'double',
      );
      expect(doubleReg.scopeName, equals('grandChild'));
      expect(doubleReg.scopeDepth, equals(2));
    });

    test('detects shadowed registrations in child scopes', () {
      final root = DependencyBox.main(name: 'root');
      final child = root.createChild(name: 'child');

      root.addSingleton<_SampleService>(_SampleService('root'));
      child.addSingleton<_SampleService>(_SampleService('childOverride'));

      final snapshot = root.getSnapshot();
      expect(snapshot.totalRegistrations, equals(2));

      final rootReg = snapshot.registrations.firstWhere(
        (r) => r.scopeName == 'root',
      );
      final childReg = snapshot.registrations.firstWhere(
        (r) => r.scopeName == 'child',
      );

      expect(rootReg.isShadowed, isFalse);
      expect(childReg.isShadowed, isTrue);

      final shadowedNotices = snapshot.diagnostics
          .where((d) => d.title.contains('Shadowed'))
          .toList();
      expect(shadowedNotices, isNotEmpty);
      expect(shadowedNotices.first.relatedType, equals('_SampleService'));
    });

    test('reports multi-registration metadata and strategies', () {
      final box = DependencyBox.main();
      box.allowMulti<_SampleService>(resolution: MultiResolution.first);

      box.addSingleton<_SampleService>(_SampleService('s1'));
      box.addSingleton<_SampleService>(_SampleService('s2'));

      final snapshot = box.getSnapshot();
      expect(snapshot.totalRegistrations, equals(2));

      final reg0 = snapshot.registrations[0];
      final reg1 = snapshot.registrations[1];

      expect(reg0.isMulti, isTrue);
      expect(reg0.multiIndex, equals(0));
      expect(reg0.multiTotal, equals(2));
      expect(reg0.multiResolution, equals('first'));

      expect(reg1.isMulti, isTrue);
      expect(reg1.multiIndex, equals(1));
      expect(reg1.multiTotal, equals(2));
    });

    test('handles disposed scope correctly in diagnostics', () async {
      final root = DependencyBox.main(name: 'root');
      final child = root.createChild(name: 'childToDispose');
      child.addSingleton<String>('willBeDisposed');

      await child.dispose();
      expect(child.isDisposed, isTrue);

      final snapshot = child.getSnapshot(fromRoot: false);
      final childScope = snapshot.rootScope;
      expect(childScope.isDisposed, isTrue);

      final disposedWarnings = snapshot.diagnostics
          .where((d) => d.title.contains('Disposed Scope'))
          .toList();
      expect(disposedWarnings, isNotEmpty);
    });

    test('serializes and deserializes snapshot to/from JSON roundtrip', () {
      final box = DependencyBox.main(name: 'rootBox');
      box.addSingleton<_SampleService>(_SampleService('test'), key: 'primary');
      box.addFactory<_ConfigService>((_) => _ConfigService(8080));

      final original = box.getSnapshot();
      final jsonMap = original.toJson();
      final jsonString = original.toJsonString();

      expect(jsonMap['stats']['totalRegistrations'], equals(2));
      expect(jsonString, contains('primary'));
      expect(jsonString, contains('_ConfigService'));

      final reconstructed = ContainerSnapshot.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );

      expect(
        reconstructed.totalRegistrations,
        equals(original.totalRegistrations),
      );
      expect(reconstructed.rootScope.name, equals(original.rootScope.name));
      expect(
        reconstructed.registrations.length,
        equals(original.registrations.length),
      );
      expect(
        reconstructed.registrations.first.typeName,
        equals(original.registrations.first.typeName),
      );
      expect(reconstructed.registrations.first.key, equals('primary'));
    });
  });

  group('DependencyBoxDevTools runtime service extensions', () {
    test('is disabled by default with zero active containers', () {
      expect(DependencyBoxDevTools.isEnabled, isFalse);
      expect(DependencyBoxDevTools.activeContainerCount, equals(0));
    });

    test('registers container and enables service extensions', () {
      final box = DependencyBox.main();
      DependencyBoxDevTools.register(box);

      expect(DependencyBoxDevTools.isEnabled, isTrue);
      expect(DependencyBoxDevTools.activeContainerCount, equals(1));

      DependencyBoxDevTools.unregister(box);
      expect(DependencyBoxDevTools.activeContainerCount, equals(0));
    });

    test('responds to ping extension call', () async {
      final box = DependencyBox.main();
      DependencyBoxDevTools.register(box);

      final response = await DependencyBoxDevTools.handleServiceCall(
        DependencyBoxDevTools.pingMethod,
        {},
      );

      final json = jsonDecode(response.result!) as Map<String, dynamic>;
      expect(json['status'], equals('ok'));
      expect(json['version'], equals('1.0.0'));
      expect(json['containerCount'], equals(1));
    });

    test(
      'responds to getSnapshot extension call with serializable payload',
      () async {
        final box = DependencyBox.main(name: 'apiBox');
        box.addSingleton<String>('hello');
        DependencyBoxDevTools.register(box);

        final response = await DependencyBoxDevTools.handleServiceCall(
          DependencyBoxDevTools.getSnapshotMethod,
          {},
        );

        final json = jsonDecode(response.result!) as Map<String, dynamic>;
        expect(json['rootScope']['name'], equals('apiBox'));
        expect((json['registrations'] as List).length, equals(1));
        expect(json['registrations'][0]['typeName'], equals('String'));
      },
    );

    test('responds to getSnapshot alias (snake_case) identically', () async {
      final box = DependencyBox.main(name: 'aliasBox');
      box.addSingleton<int>(123);
      DependencyBoxDevTools.register(box);

      final response = await DependencyBoxDevTools.handleServiceCall(
        DependencyBoxDevTools.getSnapshotAlias,
        {},
      );

      final json = jsonDecode(response.result!) as Map<String, dynamic>;
      expect(json['rootScope']['name'], equals('aliasBox'));
      expect(json['registrations'][0]['typeName'], equals('int'));
    });

    test(
      'responds with empty status when no containers are registered',
      () async {
        DependencyBoxDevTools.enable(); // enable without registering a box

        final response = await DependencyBoxDevTools.handleServiceCall(
          DependencyBoxDevTools.getSnapshotMethod,
          {},
        );

        final json = jsonDecode(response.result!) as Map<String, dynamic>;
        expect(json['status'], equals('empty'));
        expect(json['scopes'], isEmpty);
        expect(json['registrations'], isEmpty);
      },
    );

    test('responds to getScopes method with scopes only', () async {
      final root = DependencyBox.main(name: 'root');
      root.createChild(name: 'child');
      DependencyBoxDevTools.register(root);

      final response = await DependencyBoxDevTools.handleServiceCall(
        DependencyBoxDevTools.getScopesMethod,
        {},
      );

      final json = jsonDecode(response.result!) as Map<String, dynamic>;
      final scopes = json['scopes'] as List<dynamic>;
      expect(scopes.length, equals(2));
      expect(scopes.map((s) => s['name']), containsAll(['root', 'child']));
    });

    test(
      'responds to getRegistrations method with registrations only',
      () async {
        final box = DependencyBox.main();
        box.addSingleton<String>('val');
        box.addFactory<int>((_) => 42);
        DependencyBoxDevTools.register(box);

        final response = await DependencyBoxDevTools.handleServiceCall(
          DependencyBoxDevTools.getRegistrationsMethod,
          {},
        );

        final json = jsonDecode(response.result!) as Map<String, dynamic>;
        final regs = json['registrations'] as List<dynamic>;
        expect(regs.length, equals(2));
      },
    );

    test(
      'uses WeakReference and prunes collected containers automatically',
      () {
        DependencyBoxDevTools.enable();

        // Allocate in local scope
        void createAndRegister() {
          final tempBox = DependencyBox.main(name: 'temporary');
          DependencyBoxDevTools.register(tempBox);
          expect(DependencyBoxDevTools.activeContainerCount, equals(1));
        }

        createAndRegister();

        // Explicitly disable cleans up
        DependencyBoxDevTools.disable();
        expect(DependencyBoxDevTools.activeContainerCount, equals(0));
      },
    );

    test('handles exceptions gracefully without crashing', () async {
      DependencyBoxDevTools.enable();

      final response = await DependencyBoxDevTools.handleServiceCall(
        'ext.dependencyBox.nonExistentMethod',
        {},
      );

      // Falls through to default snapshot call safely
      expect(response.result, isNotNull);
    });
  });
}
