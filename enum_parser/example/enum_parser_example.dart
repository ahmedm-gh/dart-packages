// ignore_for_file: constant_identifier_names

import 'package:enum_parser/enum_parser.dart';

/// An example source enum with SCREAMING_SNAKE_CASE naming.
enum SourceStatus { PENDING_PAYMENT, PROCESSING, SHIPPED, DELIVERED, CANCELLED }

/// Target enum with idiomatic Dart camelCase naming (e.g. domain entity or internal model).
enum OrderStatus { pendingPayment, processing, shipped, delivered, cancelled }

/// A regular enum representing task priority.
enum Priority { low, medium, high, critical }

void main() {
  print('=== EnumParser Demonstration ===\n');

  // 1. Strict Matching
  // Case-sensitive exact name matching.
  final strictMatch = OrderStatus.values.parseStrict('processing');
  final strictMiss = OrderStatus.values.parseStrict('PROCESSING');
  print('1. Strict Match:');
  print('   "processing" -> $strictMatch');
  print('   "PROCESSING" (misses in strict) -> $strictMiss\n');

  // 2. Simple Matching
  // Case-insensitive matching, no delimiter stripping.
  final simpleMatch = Priority.values.parseSimple('CRITICAL');
  print('2. Simple Match (Case-Insensitive):');
  print('   "CRITICAL" -> $simpleMatch\n');

  // 3. Loose Matching (Default Mode)
  // Strips delimiters (spaces, underscores, hyphens) and enum class prefixes.
  final loose1 = OrderStatus.values.parse('OrderStatus.shipped');
  final loose2 = OrderStatus.values.parse('pending-payment');
  final loose3 = OrderStatus.values.parse('DELIVERED');
  print('3. Loose Match (Delimiters & Type Prefixes):');
  print('   "OrderStatus.shipped" -> $loose1');
  print('   "pending-payment"     -> $loose2');
  print('   "DELIVERED"           -> $loose3\n');

  // 4. Enum-to-Enum Mapping
  // Directly resolves between different enum types and naming conventions.
  final SourceStatus source = SourceStatus.PENDING_PAYMENT;
  final OrderStatus target = OrderStatus.values.parse(source)!;
  final sourceList = [
    SourceStatus.PROCESSING,
    SourceStatus.SHIPPED,
    SourceStatus.DELIVERED,
  ];
  final targetList = OrderStatus.values.parseList(sourceList);
  print('4. Enum-to-Enum Mapping:');
  print('   $source -> $target');
  print('   $sourceList -> $targetList\n');

  // 5. Fallback and Custom Converters
  final fallback = Priority.values.parse(
    'ultra_urgent',
    fallback: Priority.critical,
  );
  final converted = Priority.values.parse(
    'p1',
    converter: (src, values) => src == 'p1' ? Priority.high : null,
  );
  print('5. Fallbacks and Custom Converters:');
  print('   "ultra_urgent" (fallback) -> $fallback');
  print('   "p1" (converter)          -> $converted\n');

  // 6. Parsing Lists & Delimited Strings
  final parsedList = Priority.values.parseList('low, medium, high');
  final mixedList = OrderStatus.values.parseList([
    'pendingPayment',
    'processing',
    'OrderStatus.delivered',
    'unknown',
  ]);
  print('6. List Parsing:');
  print('   "low, medium, high" -> $parsedList');
  print('   Mixed raw inputs    -> $mixedList\n');

  // 7. High-Throughput Pre-Indexed Parsing with EnumIndex
  final statusIndex = OrderStatus.values.toEnumIndex(
    mode: EnumParserMode.loose,
  );
  print('7. High-Throughput EnumIndex:');
  print('   O(1) parsed: ${statusIndex.parse('cancelled')}');
  print(
    '   O(1) batch:  ${statusIndex.parseList('pending_payment, shipped, cancelled')}',
  );
}
