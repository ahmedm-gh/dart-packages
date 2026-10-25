import 'package:dependency_box/dependency_box.dart';

class HeavyImageBuffer {
  final String imagePath;
  final List<int> rawBytes;

  HeavyImageBuffer(this.imagePath) : rawBytes = List<int>.filled(100000, 1) {
    print('HeavyImageBuffer allocated in memory for: $imagePath');
  }

  void render() {
    print('Rendering image "$imagePath" (${rawBytes.length} bytes)');
  }
}

void main() {
  print('=== 05 Weak-Reference Cached Factory Example ===\n');

  final box = DependencyBox.main();

  var factoryCallCount = 0;

  // Register a cached factory.
  // The container holds only a WeakReference<T> to the instance.
  box.addCachedFactory<HeavyImageBuffer>((container) {
    factoryCallCount++;
    return HeavyImageBuffer('assets/images/hero_banner_4k.png');
  });

  print('--- First Resolution ---');
  // First access: triggers factory
  HeavyImageBuffer? activeImage = box.get<HeavyImageBuffer>();
  activeImage.render();
  print('Factory executions so far: $factoryCallCount');

  print('\n--- Second Resolution (while active reference is retained) ---');
  // While activeImage is retained by caller, get() returns the same cached instance!
  final cachedImage = box.get<HeavyImageBuffer>();
  print('Returned identical instance: ${identical(activeImage, cachedImage)}');
  print('Factory executions so far: $factoryCallCount (no new allocation)');

  print('\n--- Simulating Lifecycle Release ---');
  // When activeImage is set to null, the only reference inside the container is a WeakReference.
  // When garbage collection runs, the memory is reclaimed automatically without needing manual disposal!
  activeImage = null;
  print('External reference released.');

  // If another part of the app requests it, the container cleanly re-allocates if needed.
  final freshAccess = box.get<HeavyImageBuffer>();
  freshAccess.render();
}
