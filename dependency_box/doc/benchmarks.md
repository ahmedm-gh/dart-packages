# DependencyBox Performance & Benchmarks

This document provides the authoritative, reproducible performance report and architectural analysis for the `dependency_box` Dart package. It details both the standalone microbenchmarks (including child container lifecycle, scoping, and cascading disposal) and the head-to-head comparison against `get_it 9.3.0`.

---

## Executive Summary

| Category | JIT Runtime | AOT Runtime | Throughput (AOT) |
| :--- | :---: | :---: | :---: |
| **Unkeyed Singleton `get<T>()`** | **12.71 ns/op** | **14.83 ns/op** | ~67.4 Million ops/sec |
| **Keyed Singleton `get<T>(key: ...)`** | **19.92 ns/op** | **22.29 ns/op** | ~44.9 Million ops/sec |
| **Cached Lazy Singleton `get<T>()`** | **16.13 ns/op** | **15.95 ns/op** | ~62.7 Million ops/sec |
| **Inherited Resolution `[Child -> Parent]`** | **22.61 ns/op** | **23.68 ns/op** | ~42.2 Million ops/sec |
| **Missing Dependency `tryGet<T>()`** | **9.26 ns/op** | **6.39 ns/op** | ~156.4 Million ops/sec |
| **Child Creation `createChild()` [First]** | **70.13 ns/op** | **46.84 ns/op** | ~21.3 Million ops/sec |
| **Child Creation `createChild()` [Subsequent]** | **127.85 ns/op** | **109.92 ns/op** | ~9.1 Million ops/sec |
| **Leaf Container Disposal** | **330.26 ns/op** | **281.65 ns/op** | ~3.5 Million ops/sec |
| **Parent Disposal with 10 Children** | **1.05 µs/op** | **0.78 µs/op** | ~1.28 Million ops/sec |
| **Deep Hierarchy Disposal (20 Cascaded Scopes)** | **1.50 µs/op** | **1.45 µs/op** | ~688,000 ops/sec |
| **Wide Hierarchy Disposal (100 Direct Children)** | **6.33 µs/op** | **5.83 µs/op** | ~171,000 ops/sec |
| **Overall Geometric Mean vs `get_it 9.3.0`** | **5.39× faster** | **6.53× faster** | Up to **26.7× faster** |

---

## 1. Test Environment & Methodology

- **Dart SDK:** 3.13.4 (stable)
- **Host OS:** Windows 11 Pro (10.0 Build 26300), x64
- **Hardware:** 16 logical processors, high-performance NVMe
- **Execution Modes:**
  - **JIT Mode:** Executed via `dart run tool/benchmark/benchmark.dart` and `dart run bin/run_benchmark_suite.dart --samples 20 --mode JIT`
  - **AOT Mode:** Native executable compiled via `dart compile exe tool/benchmark/benchmark.dart -o tool/benchmark/benchmark.exe` and `dart compile exe bin/run_benchmark_suite.dart -o bin/benchmark_suite.exe`
- **Measurement Methodology:**
  - Standalone suite: 50,000 warmup iterations, monotonic `Stopwatch` over 2,000 to 5,000,000 operations per scenario.
  - Head-to-head campaign: 20 independent randomized samples per workload, statistical dispersion (median, mean, stddev, IQR) reported.
  - Zero-allocation assertions: Verified identity preservation and empty-collection deallocations.

---

## 2. Complete Microbenchmark Suite (`tool/benchmark/benchmark.dart`)

The table below reports all 23 scenarios evaluated in both JIT and native AOT compilation:

| # | Scenario Description | Operations | JIT Latency | JIT Ops/sec | AOT Latency | AOT Ops/sec |
| :---: | :--- | ---: | ---: | ---: | ---: | ---: |
| **1** | **Singleton `get<T>()` [Unkeyed Hot Path]** | 5,000,000 | **12.71 ns** | 78,702,975 | **14.83 ns** | 67,419,972 |
| **2** | **Keyed `get<T>(key: "primary")`** | 5,000,000 | **19.92 ns** | 50,189,213 | **22.29 ns** | 44,865,985 |
| **3** | **Cached LazySingleton `get<T>()`** | 5,000,000 | **16.13 ns** | 61,996,280 | **15.95 ns** | 62,714,012 |
| **4** | **Multi `get<T>()` [`MultiResolution.last`]** | 5,000,000 | **14.07 ns** | 71,062,094 | **15.53 ns** | 64,398,135 |
| **5** | **Multi `get<T>()` [`MultiResolution.first`]** | 5,000,000 | **14.17 ns** | 70,551,714 | **16.30 ns** | 61,356,469 |
| **6** | **Multi `get<T>()` [`MultiResolution.at(1)`]** | 5,000,000 | **14.43 ns** | 69,278,945 | **16.78 ns** | 59,582,683 |
| **7** | **Multi `get<T>()` [`MultiResolution.key("logging")`]** | 5,000,000 | **17.09 ns** | 58,516,490 | **18.02 ns** | 55,478,502 |
| **8** | **`getAll<T>()` [3 instances into List]** | 1,000,000 | **30.87 ns** | 32,397,058 | **79.61 ns** | 12,561,867 |
| **9** | **Deep Hierarchy `get<AuthService>()` [5 layers]** | 5,000,000 | **17.48 ns** | 57,204,965 | **19.18 ns** | 52,127,859 |
| **10** | **Parameterized Factory `get<QueryEngine>(args)`** | 2,000,000 | **23.34 ns** | 42,841,230 | **22.46 ns** | 44,531,528 |
| **—** | **Factory `get<ConfigService>()` [Fresh Instance]** | 2,000,000 | **20.81 ns** | 48,049,202 | **17.59 ns** | 56,847,251 |
| **11** | **Mass Setup: Create Box + 1,000 Keyed Singletons** | 2,000 | **0.087 ms** | 11,456 | **0.084 ms** | 11,839 |
| **12** | **Async Singleton Cold Init (Create+Init+Dispose)** | 50,000 | **2.18 µs** | 459,166 | **0.78 µs** | 1,285,182 |
| **13** | **Async Singleton Cached `getAsync<ConfigService>()`** | 2,000,000 | **284.83 ns** | 3,510,872 | **320.24 ns** | 3,122,678 |
| **14** | **Concurrent `getAsync` (10 Callers Joining)** | 50,000 | **2.30 µs** | 435,324 | **2.82 µs** | 354,746 |
| **15** | **Async Graph `getAsync<AuthService>()` [5 layers]** | 1,000,000 | **309.05 ns** | 3,235,691 | **393.07 ns** | 2,544,050 |
| **16** | **Inherited `get<T>()` [`Child -> Parent`]** | 5,000,000 | **22.61 ns** | 44,219,612 | **23.68 ns** | 42,225,094 |
| **17** | **Missing Dependency `tryGet<T>()`** | 5,000,000 | **9.26 ns** | 108,047,368 | **6.39 ns** | 156,445,557 |
| **18** | **`createChild()` [First Child on Empty Parent]** | 200,000 | **70.13 ns** | 14,260,250 | **46.84 ns** | 21,349,274 |
| **19** | **`createChild()` [Subsequent Child on Active Parent]** | 100,000 | **127.85 ns** | 7,821,666 | **109.92 ns** | 9,097,525 |
| **20** | **Disposal: Leaf Container with 1 Singleton** | 100,000 | **330.26 ns** | 3,027,917 | **281.65 ns** | 3,550,506 |
| **21** | **Disposal: Parent with 10 Direct Children** | 20,000 | **1.05 µs** | 948,047 | **0.78 µs** | 1,278,364 |
| **22** | **Disposal: Deep Hierarchy (20 Scopes Cascade)** | 10,000 | **1.50 µs** | 664,761 | **1.45 µs** | 688,468 |
| **23** | **Disposal: Wide Hierarchy (100 Direct Children)** | 2,000 | **6.33 µs** | 157,916 | **5.83 µs** | 171,468 |

---

## 3. Hierarchy & Scoped Lifecycle Performance

### Key Architectural Findings

1. **Hot Path Isolation:**
   - Traversing from a child scope up to its parent during `get<T>()` requires only **22–23 ns** (over 42 million lookups/sec).
   - Local resolution remains completely unhindered at **12–14 ns**, since child-tracking data structures (`_children`) are never checked or traversed during dependency resolution.

2. **Lazy Allocation & Zero-Bloat Memory:**
   - Standalone parent containers maintain `_children = null`. No `Set` instance is allocated until `createChild()` is invoked.
   - When the final child of a parent is disposed, the parent immediately resets `_children = null`, releasing memory back to the GC.

3. **Safe Cascading Disposal Without Defensive Copies:**
   - Cascading disposal uses pre-emptive ownership transfer: the parent transfers its `_children` reference to a local variable and immediately clears `_children = null` before iterating child disposals.
   - This eliminates `ConcurrentModificationError` when children call `_parent?._detachChild(this)` without allocating defensive snapshot collections.
   - Even in deep (20 cascaded scopes) or wide (100 direct children) hierarchies, cleanup completes in **1.45 µs** and **5.83 µs** (AOT) / **1.50 µs** and **6.33 µs** (JIT) respectively.

4. **Fault Tolerance and Error Aggregation:**
   - If a disposable in child A throws an exception, sibling child B and parent registrations are still fully disposed before the caught error is re-thrown.

---

## 4. Head-to-Head Comparison vs. `get_it 9.3.0`

![dependency_box vs get_it 9.3.0 speedup ranges](benchmark_comparison.svg)

### 4.1 Resolution Workloads (Median Latency)

| Benchmark Workload | `dependency_box` (JIT) | `get_it` (JIT) | JIT Speedup | `dependency_box` (AOT) | `get_it` (AOT) | AOT Speedup |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Resolve Pre-Registered Singleton** | **30.2 ns** | 461.0 ns | **15.27×** | **14.1 ns** | 377.2 ns | **26.74×** |
| **Resolve Cached Lazy Singleton** | **36.1 ns** | 453.9 ns | **12.57×** | **15.1 ns** | 388.4 ns | **25.69×** |
| **Resolve Transient Factory** | **50.3 ns** | 522.4 ns | **10.40×** | **19.1 ns** | 388.7 ns | **20.31×** |
| **Resolve Interface Mapping** | **35.4 ns** | 467.2 ns | **13.19×** | **17.4 ns** | 322.3 ns | **18.58×** |
| **Resolve Keyed / Named Registration** | **53.8 ns** | 571.5 ns | **10.63×** | **25.7 ns** | 430.1 ns | **16.76×** |
| **Resolve Parameterized Factory** | **70.3 ns** | 546.7 ns | **7.78×** | **261.3 ns** | 446.1 ns | **1.71×** |
| **Resolve Shallow Graph (4 Direct Dependencies)** | **245.6 ns** | 2,669.7 ns | **10.87×** | **126.4 ns** | 1,944.9 ns | **15.39×** |
| **Resolve Deep 10-Level Chain Graph** | **574.5 ns** | 6,230.4 ns | **10.84×** | **287.2 ns** | 4,117.0 ns | **14.34×** |
| **Resolve Shared Graph (Diamond / Multi-Root)** | **262.2 ns** | 3,197.8 ns | **12.19×** | **191.1 ns** | 2,668.5 ns | **13.97×** |
| **Resolve Realistic Enterprise Graph (ViewModel Root)** | **189.4 ns** | 2,240.7 ns | **11.83×** | **103.8 ns** | 2,144.0 ns | **20.65×** |
| **Resolve Asynchronous Singleton** | **374.9 ns** | 1,169.9 ns | **3.12×** | **258.5 ns** | 611.8 ns | **2.37×** |
| **Missing Registration Failure Path** | **23.7 ns** | 35.9 ns | **1.52×** | **9.8 ns** | 14.5 ns | **1.48×** |

### 4.2 Registration & Scaling Workloads (Median Latency)

| Benchmark Workload | `dependency_box` (JIT) | `get_it` (JIT) | JIT Speedup | `dependency_box` (AOT) | `get_it` (AOT) | AOT Speedup |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Empty Container Instantiation** | **14.4 ns** | 29.3 ns | **2.04×** | **14.3 ns** | 19.1 ns | **1.33×** |
| **Register 1 Singleton** | **86.9 ns** | 224.6 ns | **2.58×** | **90.0 ns** | 196.5 ns | **2.18×** |
| **Register 10 Singletons** | **1,006.9 ns** | 4,413.8 ns | **4.38×** | **901.7 ns** | 4,989.0 ns | **5.53×** |
| **Register 100 Singletons** | **10.0 µs** | 46.0 µs | **4.58×** | **8,769.5 ns** | 53.5 µs | **6.11×** |
| **Register 1,000 Singletons (Scaling)** | **208.6 µs** | 842.6 µs | **4.04×** | **95.0 µs** | 573.2 µs | **6.03×** |
| **Register 10,000 Singletons (Large Scale)** | **4.32 ms** | 14.78 ms | **3.42×** | **3.10 ms** | 15.70 ms | **5.06×** |
| **Register 10 Lazy Singletons** | **2,135.4 ns** | 7,953.3 ns | **3.72×** | **1,518.6 ns** | 7,981.9 ns | **5.26×** |
| **Register 10 Factories** | **2,063.9 ns** | 7,433.6 ns | **3.60×** | **1,639.8 ns** | 8,581.0 ns | **5.23×** |
| **Register Interface to Implementation** | **143.1 ns** | 365.9 ns | **2.56×** | **92.1 ns** | 305.4 ns | **3.31×** |
| **Register Keyed / Named Instances** | **245.9 ns** | 1,315.9 ns | **5.35×** | **140.3 ns** | 1,154.4 ns | **8.23×** |
| **Register Parameterized Factory** | **104.3 ns** | 373.0 ns | **3.58×** | **81.1 ns** | 270.9 ns | **3.34×** |
| **Register Deep 10-Level Chain Graph** | **1,284.3 ns** | 3,193.7 ns | **2.49×** | **890.2 ns** | 3,017.4 ns | **3.39×** |
| **Register Realistic Enterprise Application Graph** | **1,262.8 ns** | 3,554.0 ns | **2.81×** | **832.5 ns** | 3,293.6 ns | **3.96×** |

### 4.3 Lifecycle & Scoping Workloads (Median Latency)

| Benchmark Workload | `dependency_box` (JIT) | `get_it` (JIT) | JIT Speedup | `dependency_box` (AOT) | `get_it` (AOT) | AOT Speedup |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Scoped Feature Lifecycle (Push, Resolve, Pop)** | **1,033.4 ns** | 4,044.0 ns | **3.91×** | **557.6 ns** | 1,323.6 ns | **2.37×** |
| **Weak-Reference Cached Factory Access** | **44.3 ns** | 546.7 ns | **12.33×** | **14.3 ns** | 370.6 ns | **25.84×** |

---

## 5. Visual Charts Reference

- Consolidated Head-to-Head Comparison & Speedup Ranges (27 Workloads across Resolution, Registration & Scaling, and Lifecycle & Scoping): [benchmark_comparison.svg](benchmark_comparison.svg)

---

## 6. How to Reproduce

All benchmark suites are open-source and included in the repository:

### Run Standalone Package Microbenchmarks

```bash
# JIT Mode
dart run tool/benchmark/benchmark.dart

# AOT Mode
dart compile exe tool/benchmark/benchmark.dart -o tool/benchmark/benchmark.exe
./tool/benchmark/benchmark.exe
```

### Run Comparative Head-to-Head Harness (`vs get_it 9.3.0`)

```bash
# Quick Smoke Test
dart run tool/comparison_benchmark/bin/run_all.dart --smoke

# Full 20-Sample Production Campaign
dart run tool/comparison_benchmark/bin/run_all.dart
```
