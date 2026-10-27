import 'dart:async';

import '../adapters/adapter.dart';

enum WorkloadCategory {
  registration,
  resolution,
  lifecycleAndScope,
  bulkAndScaling,
}

/// Defines a distinct benchmark scenario.
class BenchmarkWorkload {
  final String id;
  final String title;
  final String description;
  final WorkloadCategory category;
  final int operationsPerSample;
  final int warmupIterations;
  final bool isAsync;

  /// Setup callback run ONCE before timed iterations (outside timed section).
  final void Function(BenchmarkAdapter adapter)? setup;

  /// Teardown callback run after timed iterations.
  final void Function(BenchmarkAdapter adapter)? teardown;

  /// Timed synchronous body for one operation.
  final Object? Function(BenchmarkAdapter adapter)? runSync;

  /// Timed asynchronous body for one operation.
  final Future<Object?> Function(BenchmarkAdapter adapter)? runAsync;

  const BenchmarkWorkload({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.operationsPerSample,
    required this.warmupIterations,
    this.isAsync = false,
    this.setup,
    this.teardown,
    this.runSync,
    this.runAsync,
  });
}

/// Complete catalog of all benchmark workloads.
class WorkloadCatalog {
  static List<BenchmarkWorkload> getAllWorkloads() => [
    // ========================================================================
    // A. Registration & Container Setup Workloads
    // ========================================================================
    BenchmarkWorkload(
      id: 'reg_empty_container',
      title: 'Empty Container Instantiation',
      description:
          'Cost to allocate and initialize a fresh, isolated container.',
      category: WorkloadCategory.registration,
      operationsPerSample: 50000,
      warmupIterations: 5000,
      runSync: (adapter) {
        adapter.reset();
        return adapter;
      },
    ),
    BenchmarkWorkload(
      id: 'reg_single_singleton',
      title: 'Register 1 Singleton',
      description: 'Register a single pre-constructed instance into container.',
      category: WorkloadCategory.registration,
      operationsPerSample: 20000,
      warmupIterations: 2000,
      runSync: (adapter) {
        adapter.registerSingletons(1);
        return 1;
      },
    ),
    BenchmarkWorkload(
      id: 'reg_10_singletons',
      title: 'Register 10 Singletons',
      description: 'Register 10 unique singletons into a fresh container.',
      category: WorkloadCategory.registration,
      operationsPerSample: 5000,
      warmupIterations: 500,
      runSync: (adapter) {
        adapter.registerSingletons(10);
        return 10;
      },
    ),
    BenchmarkWorkload(
      id: 'reg_100_singletons',
      title: 'Register 100 Singletons',
      description: 'Register 100 unique singletons into a fresh container.',
      category: WorkloadCategory.registration,
      operationsPerSample: 1000,
      warmupIterations: 100,
      runSync: (adapter) {
        adapter.registerSingletons(100);
        return 100;
      },
    ),
    BenchmarkWorkload(
      id: 'reg_1000_singletons',
      title: 'Register 1,000 Singletons (Scaling)',
      description:
          'Scale test registering 1,000 singletons into a fresh container.',
      category: WorkloadCategory.bulkAndScaling,
      operationsPerSample: 100,
      warmupIterations: 10,
      runSync: (adapter) {
        adapter.registerSingletons(1000);
        return 1000;
      },
    ),
    BenchmarkWorkload(
      id: 'reg_10000_singletons',
      title: 'Register 10,000 Singletons (Large Scale)',
      description:
          'Scale test registering 10,000 singletons into a fresh container.',
      category: WorkloadCategory.bulkAndScaling,
      operationsPerSample: 20,
      warmupIterations: 2,
      runSync: (adapter) {
        adapter.registerSingletons(10000);
        return 10000;
      },
    ),
    BenchmarkWorkload(
      id: 'reg_10_lazy_singletons',
      title: 'Register 10 Lazy Singletons',
      description: 'Register 10 lazy singleton factory closures.',
      category: WorkloadCategory.registration,
      operationsPerSample: 5000,
      warmupIterations: 500,
      runSync: (adapter) {
        adapter.registerLazySingletons(10);
        return 10;
      },
    ),
    BenchmarkWorkload(
      id: 'reg_10_factories',
      title: 'Register 10 Factories',
      description: 'Register 10 transient factory closures.',
      category: WorkloadCategory.registration,
      operationsPerSample: 5000,
      warmupIterations: 500,
      runSync: (adapter) {
        adapter.registerFactories(10);
        return 10;
      },
    ),
    BenchmarkWorkload(
      id: 'reg_interface_mapping',
      title: 'Register Interface to Implementation',
      description:
          'Register an implementation bound to an abstract interface type.',
      category: WorkloadCategory.registration,
      operationsPerSample: 20000,
      warmupIterations: 2000,
      runSync: (adapter) {
        adapter.registerInterfaceMapping();
        return 1;
      },
    ),
    BenchmarkWorkload(
      id: 'reg_keyed_named',
      title: 'Register Keyed / Named Instances',
      description:
          'Register distinct instances under specific keys or instance names.',
      category: WorkloadCategory.registration,
      operationsPerSample: 15000,
      warmupIterations: 1500,
      runSync: (adapter) {
        adapter.registerKeyedNamed();
        return 2;
      },
    ),
    BenchmarkWorkload(
      id: 'reg_parameterized_factory',
      title: 'Register Parameterized Factory',
      description: 'Register a factory accepting runtime arguments.',
      category: WorkloadCategory.registration,
      operationsPerSample: 15000,
      warmupIterations: 1500,
      runSync: (adapter) {
        adapter.registerParameterized();
        return 1;
      },
    ),
    BenchmarkWorkload(
      id: 'reg_deep_chain_graph',
      title: 'Register Deep 10-Level Chain Graph',
      description:
          'Register 11 cascaded factories forming a deep dependency chain.',
      category: WorkloadCategory.registration,
      operationsPerSample: 5000,
      warmupIterations: 500,
      runSync: (adapter) {
        adapter.registerDeepChain();
        return 11;
      },
    ),
    BenchmarkWorkload(
      id: 'reg_realistic_enterprise_graph',
      title: 'Register Realistic Enterprise Application Graph',
      description: 'Register 10 mixed services (singletons, lazy singletons, use case factories).',
      category: WorkloadCategory.registration,
      operationsPerSample: 5000,
      warmupIterations: 500,
      runSync: (adapter) {
        adapter.registerRealisticGraph();
        return 10;
      },
    ),

    // ========================================================================
    // B. Resolution Workloads
    // ========================================================================
    BenchmarkWorkload(
      id: 'res_singleton_cached',
      title: 'Resolve Pre-Registered Singleton',
      description:
          'Zero-overhead lookup of an eager, already-instantiated singleton.',
      category: WorkloadCategory.resolution,
      operationsPerSample: 200000,
      warmupIterations: 20000,
      setup: (adapter) => adapter.setupSingletonResolution(),
      runSync: (adapter) => adapter.resolveSingleton(),
    ),
    BenchmarkWorkload(
      id: 'res_lazy_singleton_cached',
      title: 'Resolve Cached Lazy Singleton',
      description: 'Repeated subsequent lookup of a previously initialized lazy singleton.',
      category: WorkloadCategory.resolution,
      operationsPerSample: 200000,
      warmupIterations: 20000,
      setup: (adapter) {
        adapter.setupLazySingletonResolution();
        adapter.resolveLazySingleton(); // Prime cache
      },
      runSync: (adapter) => adapter.resolveLazySingleton(),
    ),
    BenchmarkWorkload(
      id: 'res_factory_transient',
      title: 'Resolve Transient Factory',
      description: 'Resolve a transient factory constructing a fresh instance on every call.',
      category: WorkloadCategory.resolution,
      operationsPerSample: 200000,
      warmupIterations: 20000,
      setup: (adapter) => adapter.setupFactoryResolution(),
      runSync: (adapter) => adapter.resolveFactory(),
    ),
    BenchmarkWorkload(
      id: 'res_interface_mapping',
      title: 'Resolve Interface Mapping',
      description:
          'Resolve an implementation instance via its abstract interface type.',
      category: WorkloadCategory.resolution,
      operationsPerSample: 200000,
      warmupIterations: 20000,
      setup: (adapter) => adapter.setupInterfaceResolution(),
      runSync: (adapter) => adapter.resolveInterface(),
    ),
    BenchmarkWorkload(
      id: 'res_keyed_named',
      title: 'Resolve Keyed / Named Registration',
      description:
          'Resolve a service qualified by a specific key or instance name.',
      category: WorkloadCategory.resolution,
      operationsPerSample: 200000,
      warmupIterations: 20000,
      setup: (adapter) => adapter.setupKeyedNamedResolution(),
      runSync: (adapter) => adapter.resolveKeyedNamed(),
    ),
    BenchmarkWorkload(
      id: 'res_parameterized_factory',
      title: 'Resolve Parameterized Factory',
      description:
          'Resolve a factory passing runtime arguments into constructor.',
      category: WorkloadCategory.resolution,
      operationsPerSample: 100000,
      warmupIterations: 10000,
      setup: (adapter) => adapter.setupParameterizedResolution(),
      runSync: (adapter) => adapter.resolveParameterized(),
    ),
    BenchmarkWorkload(
      id: 'res_shallow_graph',
      title: 'Resolve Shallow Graph (4 Direct Dependencies)',
      description: 'Resolve a root factory that injects 4 direct transient dependencies.',
      category: WorkloadCategory.resolution,
      operationsPerSample: 100000,
      warmupIterations: 10000,
      setup: (adapter) => adapter.setupShallowGraphResolution(),
      runSync: (adapter) => adapter.resolveShallowGraph(),
    ),
    BenchmarkWorkload(
      id: 'res_deep_chain_graph',
      title: 'Resolve Deep 10-Level Chain Graph',
      description: 'Resolve a root factory that cascades through 10 nested dependency nodes.',
      category: WorkloadCategory.resolution,
      operationsPerSample: 50000,
      warmupIterations: 5000,
      setup: (adapter) => adapter.setupDeepChainResolution(),
      runSync: (adapter) => adapter.resolveDeepChain(),
    ),
    BenchmarkWorkload(
      id: 'res_shared_graph',
      title: 'Resolve Shared Graph (Diamond / Multi-Root)',
      description: 'Resolve roots sharing intermediate and core singleton/transient dependencies.',
      category: WorkloadCategory.resolution,
      operationsPerSample: 100000,
      warmupIterations: 10000,
      setup: (adapter) => adapter.setupSharedGraphResolution(),
      runSync: (adapter) => adapter.resolveSharedGraph(),
    ),
    BenchmarkWorkload(
      id: 'res_realistic_enterprise_graph',
      title: 'Resolve Realistic Enterprise Graph (ViewModel Root)',
      description: 'Resolve UserProfileViewModel across mixed singletons, repos, and use cases.',
      category: WorkloadCategory.resolution,
      operationsPerSample: 100000,
      warmupIterations: 10000,
      setup: (adapter) => adapter.setupRealisticGraphResolution(),
      runSync: (adapter) => adapter.resolveRealisticGraph(),
    ),
    BenchmarkWorkload(
      id: 'res_async_singleton',
      title: 'Resolve Asynchronous Singleton',
      description: 'Resolve an asynchronous singleton Future.',
      category: WorkloadCategory.resolution,
      operationsPerSample: 20000,
      warmupIterations: 2000,
      isAsync: true,
      setup: (adapter) => adapter.setupAsyncResolution(),
      runAsync: (adapter) => adapter.resolveAsync(),
    ),
    BenchmarkWorkload(
      id: 'res_missing_failure_overhead',
      title: 'Missing Registration Failure Path',
      description: 'Overhead of querying an unregistered service type.',
      category: WorkloadCategory.resolution,
      operationsPerSample: 200000,
      warmupIterations: 20000,
      runSync: (adapter) => adapter.resolveMissing(),
    ),

    // ========================================================================
    // C. Lifecycle & Scoping Workloads
    // ========================================================================
    BenchmarkWorkload(
      id: 'scope_push_resolve_pop',
      title: 'Scoped Feature Lifecycle (Push, Resolve, Pop)',
      description: 'Complete lifecycle: create child scope, register, resolve, and dispose.',
      category: WorkloadCategory.lifecycleAndScope,
      operationsPerSample: 5000,
      warmupIterations: 500,
      isAsync: true,
      setup: (adapter) => adapter.setupScopeBenchmark(),
      runAsync: (adapter) async {
        adapter.pushScope();
        final res = adapter.resolveScoped();
        await adapter.popScope();
        return res;
      },
    ),
    BenchmarkWorkload(
      id: 'lifecycle_cached_factory_weak_ref',
      title: 'Weak-Reference Cached Factory Access',
      description: 'Measure cache hit and retrieval for weak-reference cached factories.',
      category: WorkloadCategory.lifecycleAndScope,
      operationsPerSample: 100000,
      warmupIterations: 10000,
      setup: (adapter) => adapter.setupCachedFactoryResolution(),
      runSync: (adapter) => adapter.resolveCachedFactory(),
    ),
  ];
}
