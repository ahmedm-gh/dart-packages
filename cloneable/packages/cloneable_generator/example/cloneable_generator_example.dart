import 'package:cloneable/cloneable.dart';

/// Annotate any Dart class with `@Cloneable()`:
@Cloneable()
class Product {
  final String id;
  final String title;
  final double price;
  final String? description;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    this.description,
  });
}

void main() {
  print('Product model configured for cloneable_generator.');
  print('Generate copyWith code via:');
  print('  dart run cloneable_generator');
  print('or via build_runner:');
  print('  dart run build_runner build');
}
