import 'package:test/test.dart';
import 'package:comparison_benchmark/src/adapters/adapters.dart';
import 'package:comparison_benchmark/src/models/fixtures.dart';

void main() {
  final adapters = <BenchmarkAdapter>[DependencyBoxAdapter(), GetItAdapter()];

  for (final adapter in adapters) {
    group('Conformance Suite: ${adapter.name} (${adapter.version})', () {
      setUp(() {
        resetFixtureCounters();
        adapter.reset();
      });

      test('Singleton identity preservation', () {
        adapter.setupSingletonResolution();
        final first = adapter.resolveSingleton();
        final second = adapter.resolveSingleton();
        expect(first, isA<SingleService>());
        expect(identical(first, second), isTrue);
      });

      test('Lazy singleton initialization exactly once', () {
        adapter.setupLazySingletonResolution();
        final first = adapter.resolveLazySingleton();
        final second = adapter.resolveLazySingleton();
        expect(first, isA<SingleService>());
        expect(identical(first, second), isTrue);
      });

      test('Factory creates distinct instances on every call', () {
        adapter.setupFactoryResolution();
        final first = adapter.resolveFactory();
        final second = adapter.resolveFactory();
        expect(first, isA<SingleService>());
        expect(identical(first, second), isFalse);
      });

      test('Interface to implementation mapping', () {
        adapter.setupInterfaceResolution();
        final instance = adapter.resolveInterface();
        expect(instance, isA<IService>());
        expect(instance, isA<ServiceImpl>());
      });

      test('Keyed and named dependency resolution', () {
        adapter.setupKeyedNamedResolution();
        final instance = adapter.resolveKeyedNamed();
        expect(instance, isA<KeyedService>());
        expect((instance as KeyedService).tag, equals('primary'));
      });

      test('Parameterized factory resolution', () {
        adapter.setupParameterizedResolution();
        final instance = adapter.resolveParameterized();
        expect(instance, isA<ParameterizedService>());
        final param = instance as ParameterizedService;
        expect(param.tenantId, equals('tenant_benchmark'));
        expect(param.partition, equals(42));
      });

      test('Shallow dependency graph resolution', () {
        adapter.setupShallowGraphResolution();
        final root = adapter.resolveShallowGraph();
        expect(root, isA<ShallowRoot>());
        final r = root as ShallowRoot;
        expect(r.a, isA<ShallowDepA>());
        expect(r.b, isA<ShallowDepB>());
        expect(r.c, isA<ShallowDepC>());
        expect(r.d, isA<ShallowDepD>());
      });

      test('Deep chain (10 levels) resolution', () {
        adapter.setupDeepChainResolution();
        final root = adapter.resolveDeepChain();
        expect(root, isA<ChainRoot>());
        final r = root as ChainRoot;
        expect(r.dep, isA<ChainNode9>());
        expect(r.dep.dep.dep.dep.dep.dep.dep.dep.dep.dep, isA<ChainNode0>());
      });

      test('Shared graph resolution with common dependencies', () {
        adapter.setupSharedGraphResolution();
        final root = adapter.resolveSharedGraph();
        expect(root, isA<SharedRoot1>());
        final r = root as SharedRoot1;
        expect(identical(r.midA.coreA, r.midB.coreA), isTrue);
        expect(identical(r.midA.coreB, r.midB.coreB), isTrue);
      });

      test('Realistic enterprise application graph resolution', () {
        adapter.setupRealisticGraphResolution();
        final vm = adapter.resolveRealisticGraph();
        expect(vm, isA<UserProfileViewModel>());
        final v = vm as UserProfileViewModel;
        expect(v.getUserProfile, isA<GetUserProfileUseCase>());
        expect(v.tracker, isA<AnalyticsTracker>());
        v.tracker.track('view_profile');
        expect(v.tracker.eventCount, equals(1));
      });

      test('Asynchronous singleton resolution', () async {
        adapter.setupAsyncResolution();
        final db = await adapter.resolveAsync();
        expect(db, isA<AsyncDatabaseService>());
        expect((db as AsyncDatabaseService).isConnected, isTrue);
      });

      test('Missing registration returns null without uncaught throw', () {
        final result = adapter.resolveMissing();
        expect(result, isNull);
      });

      test('Scope creation, scoped resolution, and teardown', () async {
        adapter.setupScopeBenchmark();
        adapter.pushScope();
        final scopedInstance = adapter.resolveScoped();
        expect(scopedInstance, isA<SingleService>());
        await adapter.popScope();
      });

      test('Cached factory weak reference behavior', () {
        adapter.setupCachedFactoryResolution();
        final instance = adapter.resolveCachedFactory();
        expect(instance, isA<SingleService>());
      });

      test('Bulk registration execution', () {
        expect(() => adapter.registerSingletons(10), returnsNormally);
        expect(() => adapter.registerLazySingletons(10), returnsNormally);
        expect(() => adapter.registerFactories(10), returnsNormally);
      });
    });
  }
}
