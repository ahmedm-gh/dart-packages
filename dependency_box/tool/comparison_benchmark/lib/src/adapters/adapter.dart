import 'dart:async';

/// Capabilities exposed by DI containers.
enum DiCapability {
  singleton,
  lazySingleton,
  factory,
  cachedWeakReferenceFactory,
  interfaceMapping,
  keyedNamedRegistration,
  nonStringKeys,
  parameterizedFactory,
  asyncSingleton,
  hierarchicalContainerInstances,
  stackBasedScopes,
  multiRegistrationList,
  circularDependencyDetection,
  targetedRemoval,
  testOverrideReplacement,
  containerIntrospection,
}

/// Abstract adapter interface defining a standardized benchmarkable container.
abstract class BenchmarkAdapter {
  String get name;
  String get version;
  Set<DiCapability> get capabilities;

  bool supports(DiCapability capability) => capabilities.contains(capability);

  /// Resets and disposes the container to clean slate.
  void reset();

  // --- Registration Workloads ---

  /// Measures container creation + registration of [count] singletons.
  void registerSingletons(int count);

  /// Measures container creation + registration of [count] lazy singletons.
  void registerLazySingletons(int count);

  /// Measures container creation + registration of [count] factories.
  void registerFactories(int count);

  /// Registers interface to implementation mapping.
  void registerInterfaceMapping();

  /// Registers named or keyed dependencies.
  void registerKeyedNamed();

  /// Registers a parameterized factory accepting arguments.
  void registerParameterized();

  /// Registers an asynchronous singleton factory.
  void registerAsyncSingleton();

  /// Registers the realistic enterprise application graph.
  void registerRealisticGraph();

  /// Registers the deep 10-level dependency chain.
  void registerDeepChain();

  // --- Resolution Setups & Workloads ---

  /// Prepares the container for singleton resolution.
  void setupSingletonResolution();
  Object resolveSingleton();

  /// Prepares the container for lazy singleton resolution.
  void setupLazySingletonResolution();
  Object resolveLazySingleton();

  /// Prepares the container for factory resolution.
  void setupFactoryResolution();
  Object resolveFactory();

  /// Prepares container for interface resolution.
  void setupInterfaceResolution();
  Object resolveInterface();

  /// Prepares container for keyed/named resolution.
  void setupKeyedNamedResolution();
  Object resolveKeyedNamed();

  /// Prepares container for parameterized resolution.
  void setupParameterizedResolution();
  Object resolveParameterized();

  /// Prepares container for shallow graph resolution.
  void setupShallowGraphResolution();
  Object resolveShallowGraph();

  /// Prepares container for deep chain resolution.
  void setupDeepChainResolution();
  Object resolveDeepChain();

  /// Prepares container for shared/broad graph resolution.
  void setupSharedGraphResolution();
  Object resolveSharedGraph();

  /// Prepares container for realistic enterprise graph resolution.
  void setupRealisticGraphResolution();
  Object resolveRealisticGraph();

  /// Prepares container for async resolution.
  void setupAsyncResolution();
  Future<Object> resolveAsync();

  /// Attempts resolution of an unregistered service to measure failure handling overhead.
  Object? resolveMissing();

  // --- Scope and Lifecycle Setups & Workloads ---

  /// Sets up a base container ready for scope pushing/creation.
  void setupScopeBenchmark();

  /// Pushes/creates a scope with a registered scoped dependency.
  void pushScope();

  /// Resolves a dependency registered inside the active scope.
  Object resolveScoped();

  /// Pops/disposes the active scope.
  Future<void> popScope();

  /// Sets up weak-reference cached factory registration.
  void setupCachedFactoryResolution();

  /// Resolves the weak-reference cached factory.
  Object resolveCachedFactory();
}
