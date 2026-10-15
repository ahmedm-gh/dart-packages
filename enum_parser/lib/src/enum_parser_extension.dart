import 'enum_parser_base.dart';

/// Extension on [Iterable] of enums for ergonomic parsing syntax.
extension EnumParserX<T extends Enum> on Iterable<T> {
  /// Creates a reusable [EnumIndex] for high-throughput repeated parsing.
  EnumIndex<T> toEnumIndex({EnumParserMode mode = EnumParserMode.loose}) {
    return EnumIndex<T>(this, mode: mode);
  }

  /// Parses and returns an enum of type [T] from [src].
  ///
  /// See [EnumParser.parse] for matching resolution order, modes, and options.
  T? parse(
    Object? src, {
    EnumParserMode mode = EnumParserMode.loose,
    T? Function(Object src, Iterable<T> values)? converter,
    T? fallback,
  }) {
    return EnumParser.parse<T>(
      src,
      values: this,
      mode: mode,
      converter: converter,
      fallback: fallback,
    );
  }

  /// Parses and returns an enum of type [T] from [src] using strict matching.
  T? parseStrict(
    Object? src, {
    T? Function(Object src, Iterable<T> values)? converter,
    T? fallback,
  }) {
    return EnumParser.parseStrict<T>(
      src,
      values: this,
      converter: converter,
      fallback: fallback,
    );
  }

  /// Parses and returns an enum of type [T] from [src] using simple matching.
  T? parseSimple(
    Object? src, {
    T? Function(Object src, Iterable<T> values)? converter,
    T? fallback,
  }) {
    return EnumParser.parseSimple<T>(
      src,
      values: this,
      converter: converter,
      fallback: fallback,
    );
  }

  /// Parses and returns an enum of type [T] from [src] using loose matching.
  T? parseLoose(
    Object? src, {
    T? Function(Object src, Iterable<T> values)? converter,
    T? fallback,
  }) {
    return EnumParser.parseLoose<T>(
      src,
      values: this,
      converter: converter,
      fallback: fallback,
    );
  }

  /// Parses each item in [src] using this iterable as the enum values.
  ///
  /// See [EnumParser.parseList] for supported input types, modes, and options.
  List<T> parseList(
    Object? src, {
    EnumParserMode mode = EnumParserMode.loose,
    String separator = ',',
    T? Function(Object src, Iterable<T> values)? converter,
    List<T> fallback = const [],
  }) {
    return EnumParser.parseList<T>(
      src,
      values: this,
      mode: mode,
      separator: separator,
      converter: converter,
      fallback: fallback,
    );
  }

  /// Parses each item in [src] using strict matching.
  List<T> parseListStrict(
    Object? src, {
    String separator = ',',
    T? Function(Object src, Iterable<T> values)? converter,
    List<T> fallback = const [],
  }) {
    return EnumParser.parseListStrict<T>(
      src,
      values: this,
      separator: separator,
      converter: converter,
      fallback: fallback,
    );
  }

  /// Parses each item in [src] using simple matching.
  List<T> parseListSimple(
    Object? src, {
    String separator = ',',
    T? Function(Object src, Iterable<T> values)? converter,
    List<T> fallback = const [],
  }) {
    return EnumParser.parseListSimple<T>(
      src,
      values: this,
      separator: separator,
      converter: converter,
      fallback: fallback,
    );
  }

  /// Parses each item in [src] using loose matching.
  List<T> parseListLoose(
    Object? src, {
    String separator = ',',
    T? Function(Object src, Iterable<T> values)? converter,
    List<T> fallback = const [],
  }) {
    return EnumParser.parseListLoose<T>(
      src,
      values: this,
      separator: separator,
      converter: converter,
      fallback: fallback,
    );
  }
}
