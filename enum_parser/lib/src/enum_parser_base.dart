import 'dart:typed_data';

/// Defines the strategy used by [EnumParser] to match values against enum names.
enum EnumParserMode {
  /// Strict, case-sensitive exact matching. Matches the input string directly
  /// against declared enum member names (`e.name == src`) without lowercasing,
  /// delimiter stripping, or prefix removal.
  strict,

  /// Simple, high-speed case-insensitive matching comparing lowercased strings
  /// directly against lowercased enum names (`e.name.toLowerCase()`).
  ///
  /// Delimiters (whitespace, underscores, hyphens) and class prefixes are not stripped.
  simple,

  /// Loose, delimiter-agnostic matching. Strips delimiters (whitespace,
  /// underscores, hyphens) and class prefixes (`'Enum.name'`).
  loose;

  /// Whether this mode is [strict].
  @pragma('vm:prefer-inline')
  bool get isStrict => this == EnumParserMode.strict;

  /// Whether this mode is [simple].
  @pragma('vm:prefer-inline')
  bool get isSimple => this == EnumParserMode.simple;

  /// Whether this mode is [loose].
  @pragma('vm:prefer-inline')
  bool get isLoose => this == EnumParserMode.loose;
}

/// A utility class for safely parsing and resolving enum values from dynamic input.
abstract final class EnumParser {
  /// Parses and returns an enum of type [T] from [src] using the specified [mode].
  ///
  /// Matching resolution order:
  /// 1. If [src] is already an instance of [T], returns [src] immediately.
  /// 2. If [src] is `null` or [values] is empty, returns [fallback].
  /// 3. Resolves [src] according to [mode]:
  ///    - Under [EnumParserMode.strict]: matches exact, case-sensitive [Enum.name].
  ///    - Under [EnumParserMode.simple]: compares lowercased input against lowercased [Enum.name].
  ///    - Under [EnumParserMode.loose]: normalizes delimiters (whitespace, underscores, hyphens), strips type prefixes, and compares case-insensitively.
  /// 4. If no match is found, invokes [converter] if provided.
  /// 5. Falls back to [fallback] if neither parsing nor [converter] yielded a match.
  ///
  /// If multiple enum declarations normalize to the same key under [mode]
  /// (e.g. `fooBar` and `foo_bar` in loose mode), resolution is deterministic:
  /// the first matching enum declared in [values] is returned across all modes
  /// and parsing paths.
  @pragma('vm:prefer-inline')
  static T? parse<T extends Enum>(
    Object? src, {
    required Iterable<T> values,
    EnumParserMode mode = EnumParserMode.loose,
    T? Function(Object src, Iterable<T> values)? converter,
    T? fallback,
  }) {
    if (src is T) return src;
    if (src == null || values.isEmpty) return fallback;

    switch (mode) {
      case EnumParserMode.strict:
        return _parseStrict<T>(
          src,
          values: values,
          converter: converter,
          fallback: fallback,
        );
      case EnumParserMode.simple:
        return _parseSimple<T>(
          src,
          values: values,
          converter: converter,
          fallback: fallback,
        );
      case EnumParserMode.loose:
        return _parseLoose<T>(
          src,
          values: values,
          converter: converter,
          fallback: fallback,
        );
    }
  }

  /// Parses and returns an enum of type [T] from [src] using strict matching ([EnumParserMode.strict]).
  ///
  /// Matches the exact case-sensitive declared member name without transformations.
  @pragma('vm:prefer-inline')
  static T? parseStrict<T extends Enum>(
    Object? src, {
    required Iterable<T> values,
    T? Function(Object src, Iterable<T> values)? converter,
    T? fallback,
  }) {
    return _parseStrict<T>(
      src,
      values: values,
      converter: converter,
      fallback: fallback,
    );
  }

  /// Parses and returns an enum of type [T] from [src] using simple matching ([EnumParserMode.simple]).
  ///
  /// Compares the lowercased input directly against lowercased enum names.
  @pragma('vm:prefer-inline')
  static T? parseSimple<T extends Enum>(
    Object? src, {
    required Iterable<T> values,
    T? Function(Object src, Iterable<T> values)? converter,
    T? fallback,
  }) {
    return _parseSimple<T>(
      src,
      values: values,
      converter: converter,
      fallback: fallback,
    );
  }

  /// Parses and returns an enum of type [T] from [src] using loose matching ([EnumParserMode.loose]).
  ///
  /// Strips delimiters (spaces, underscores, hyphens) and class prefixes.
  @pragma('vm:prefer-inline')
  static T? parseLoose<T extends Enum>(
    Object? src, {
    required Iterable<T> values,
    T? Function(Object src, Iterable<T> values)? converter,
    T? fallback,
  }) {
    return _parseLoose<T>(
      src,
      values: values,
      converter: converter,
      fallback: fallback,
    );
  }

  /// Creates a reusable, immutable [EnumIndex] over [values] for high-throughput parsing.
  @pragma('vm:prefer-inline')
  static EnumIndex<T> index<T extends Enum>(
    Iterable<T> values, {
    EnumParserMode mode = EnumParserMode.loose,
  }) {
    return EnumIndex<T>(values, mode: mode);
  }

  /// Internal strict parsing implementation.
  @pragma('vm:prefer-inline')
  static T? _parseStrict<T extends Enum>(
    Object? src, {
    required Iterable<T> values,
    T? Function(Object src, Iterable<T> values)? converter,
    T? fallback,
  }) {
    if (src is T) return src;
    if (src == null || values.isEmpty) return fallback;

    final String? resolved;
    if (src is String) {
      resolved = src;
    } else if (src is Enum) {
      resolved = src.name;
    } else {
      resolved = null;
    }

    if (resolved != null) {
      for (final T e in values) {
        if (e.name == resolved) return e;
      }
    }

    return converter?.call(src, values) ?? fallback;
  }

  /// Internal simple parsing implementation.
  @pragma('vm:prefer-inline')
  static T? _parseSimple<T extends Enum>(
    Object? src, {
    required Iterable<T> values,
    T? Function(Object src, Iterable<T> values)? converter,
    T? fallback,
  }) {
    if (src is T) return src;
    if (src == null || values.isEmpty) return fallback;

    final String? resolved;
    if (src is String) {
      final trimmed = src.trim();
      resolved = trimmed.isEmpty ? null : trimmed.toLowerCase();
    } else if (src is Enum) {
      resolved = src.name.toLowerCase();
    } else {
      resolved = null;
    }

    if (resolved != null) {
      for (final T e in values) {
        if (_equalsIgnoreCase(e.name, resolved)) return e;
      }
    }

    return converter?.call(src, values) ?? fallback;
  }

  /// Internal loose parsing implementation.
  @pragma('vm:prefer-inline')
  static T? _parseLoose<T extends Enum>(
    Object? src, {
    required Iterable<T> values,
    T? Function(Object src, Iterable<T> values)? converter,
    T? fallback,
  }) {
    if (src is T) return src;
    if (src == null || values.isEmpty) return fallback;

    final String? resolved;
    if (src is String) {
      final normalized = _normalize(src);
      resolved = normalized.isEmpty ? null : normalized;
    } else if (src is Enum) {
      final normalized = _normalize(src.name);
      resolved = normalized.isEmpty ? null : normalized;
    } else {
      resolved = null;
    }

    if (resolved != null) {
      for (final T e in values) {
        if (_matchesLoose(e.name, resolved)) return e;
      }
    }

    return converter?.call(src, values) ?? fallback;
  }

  /// Parses each item in [src], which may be an iterable or a separated string.
  ///
  /// Strings are split on [separator] (`,` by default); empty segments are
  /// ignored. Unrecognized items are omitted from the returned list.
  /// Returns [fallback] (empty list by default) when [src] is `null` or is
  /// neither a string nor an iterable, or when no items could be parsed.
  ///
  /// Uses pre-indexed lookup maps for O(V + N) performance when resolving
  /// multiple items, avoiding repeated string normalizations and linear scans.
  static List<T> parseList<T extends Enum>(
    Object? src, {
    required Iterable<T> values,
    EnumParserMode mode = EnumParserMode.loose,
    String separator = ',',
    T? Function(Object src, Iterable<T> values)? converter,
    List<T> fallback = const [],
  }) {
    if (separator.isEmpty) {
      throw ArgumentError('Separator must not be empty');
    }

    // Fast path: already a typed List<T>
    if (src is List<T>) return src;
    if (src is Iterable<T>) return src.toList(growable: false);
    if (src == null || values.isEmpty) return fallback;

    final List<Object?> items;
    if (src is String) {
      final sepIdx = src.indexOf(separator);
      if (sepIdx == -1) {
        final item = mode == EnumParserMode.strict ? src : src.trim();
        if (item.isEmpty) return fallback;
        final parsed = parse<T>(
          item,
          values: values,
          mode: mode,
          converter: converter,
        );
        return parsed != null
            ? List<T>.filled(1, parsed, growable: false)
            : fallback;
      }
      items = _extractItemsFromString(
        src,
        separator,
        mode == EnumParserMode.strict,
      );
    } else if (src is Iterable<Object?>) {
      items = src is List<Object?> ? src : src.toList();
    } else {
      return fallback;
    }

    if (items.isEmpty) return fallback;

    // Fast path for 1 item: avoid any map allocations
    if (items.length == 1) {
      final parsed = parse<T>(
        items.first,
        values: values,
        mode: mode,
        converter: converter,
      );
      return parsed != null
          ? List<T>.filled(1, parsed, growable: false)
          : fallback;
    }

    // Direct linear parsing avoids EnumIndex and HashMap allocation churn
    // for small to medium lists (empirically faster up to 16 items)
    if (items.length <= 16) {
      final result = <T>[];
      for (final item in items) {
        final parsed = parse<T>(
          item,
          values: values,
          mode: mode,
          converter: converter,
        );
        if (parsed != null) result.add(parsed);
      }
      return result.isEmpty ? fallback : result.toList(growable: false);
    }

    // High-performance path for very large lists: delegate to EnumIndex
    final index = EnumIndex<T>(values, mode: mode);
    return index.parseList(
      items,
      converter: converter,
      fallback: fallback,
    );
  }

  /// Parses each item in [src] using strict matching ([EnumParserMode.strict]).
  static List<T> parseListStrict<T extends Enum>(
    Object? src, {
    required Iterable<T> values,
    String separator = ',',
    T? Function(Object src, Iterable<T> values)? converter,
    List<T> fallback = const [],
  }) =>
      parseList<T>(
        src,
        values: values,
        mode: EnumParserMode.strict,
        separator: separator,
        converter: converter,
        fallback: fallback,
      );

  /// Parses each item in [src] using simple matching ([EnumParserMode.simple]).
  static List<T> parseListSimple<T extends Enum>(
    Object? src, {
    required Iterable<T> values,
    String separator = ',',
    T? Function(Object src, Iterable<T> values)? converter,
    List<T> fallback = const [],
  }) =>
      parseList<T>(
        src,
        values: values,
        mode: EnumParserMode.simple,
        separator: separator,
        converter: converter,
        fallback: fallback,
      );

  /// Parses each item in [src] using loose matching ([EnumParserMode.loose]).
  static List<T> parseListLoose<T extends Enum>(
    Object? src, {
    required Iterable<T> values,
    String separator = ',',
    T? Function(Object src, Iterable<T> values)? converter,
    List<T> fallback = const [],
  }) =>
      parseList<T>(
        src,
        values: values,
        mode: EnumParserMode.loose,
        separator: separator,
        converter: converter,
        fallback: fallback,
      );

  /// Normalizes [source] by stripping type prefixes (`'Enum.name'`),
  /// removing delimiters (whitespace, underscores, hyphens), and converting to lowercase.
  static String _normalize(String source) {
    final len = source.length;
    if (len == 0) return '';

    final units = source.codeUnits;

    // 1. Trim whitespace from end
    var end = len - 1;
    while (end >= 0 && _isWhitespace(units[end])) {
      end--;
    }
    if (end < 0) return '';

    // 2. Trim whitespace from start
    var start = 0;
    while (start <= end && _isWhitespace(units[start])) {
      start++;
    }

    // 3. Find last '.' between start and end to strip type prefixes
    var dotIndex = -1;
    for (var i = end; i >= start; i--) {
      if (units[i] == 0x2E) {
        dotIndex = i;
        break;
      }
    }

    final actualStart = dotIndex != -1 ? dotIndex + 1 : start;
    if (actualStart > end) return '';

    var i = actualStart;
    var hasNonAscii = false;

    // Fast path: if bounds match source exactly, check if already normalized
    if (actualStart == 0 && end == len - 1) {
      while (i <= end) {
        final c = units[i];
        if (_isDelimiter(c) || (c >= 0x41 && c <= 0x5A) || c > 127) {
          break;
        }
        i++;
      }
      if (i > end) return source;
    }

    final maxLen = end - actualStart + 1;
    final buffer = Uint16List(maxLen);
    var outLen = 0;

    // Copy already-clean prefix up to i
    for (var j = actualStart; j < i; j++) {
      buffer[outLen++] = units[j];
    }

    // Process remainder
    for (; i <= end; i++) {
      final c = units[i];
      if (_isDelimiter(c)) continue;
      if (c >= 0x41 && c <= 0x5A) {
        buffer[outLen++] = c + 32; // fast ASCII lowercase
      } else {
        if (c > 127) hasNonAscii = true;
        buffer[outLen++] = c;
      }
    }

    final result = String.fromCharCodes(buffer, 0, outLen);
    return hasNonAscii ? result.toLowerCase() : result;
  }

  /// Fast delimiter check matching `[\s_-]` without invoking RegExp engine.
  @pragma('vm:prefer-inline')
  static bool _isDelimiter(int c) {
    if (c <= 0x20) {
      return c == 0x20 || (c >= 0x09 && c <= 0x0D);
    }
    if (c == 0x5F || c == 0x2D) return true; // '_' or '-'
    if (c == 0xA0) return true;
    if (c >= 0x2000 && c <= 0x200A) return true;
    if (c == 0x2028 ||
        c == 0x2029 ||
        c == 0x202F ||
        c == 0x205F ||
        c == 0x3000 ||
        c == 0xFEFF) {
      return true;
    }
    return false;
  }

  /// Fast whitespace check for trimming.
  @pragma('vm:prefer-inline')
  static bool _isWhitespace(int c) {
    return c <= 0x20 && (c == 0x20 || (c >= 0x09 && c <= 0x0D));
  }

  /// Fast ASCII case-insensitive comparison avoiding `.toLowerCase()` string allocations.
  @pragma('vm:prefer-inline')
  static bool _equalsIgnoreCase(String a, String b) {
    if (identical(a, b)) return true;
    final len = a.length;
    if (len != b.length) return false;

    for (var i = 0; i < len; i++) {
      var ca = a.codeUnitAt(i);
      var cb = b.codeUnitAt(i);
      if (ca == cb) continue;
      if (ca >= 0x41 && ca <= 0x5A) ca += 32;
      if (cb >= 0x41 && cb <= 0x5A) cb += 32;
      if (ca != cb) {
        // Fast-path: ASCII mismatch can never match under case conversion
        if (ca > 127 || cb > 127) {
          return a.toLowerCase() == b.toLowerCase();
        }
        return false;
      }
    }
    return true;
  }

  /// Fast loose match comparing an enum identifier directly against a normalized string.
  ///
  /// Eliminates all regex executions, prefix checks, and string allocations on the enum name.
  @pragma('vm:prefer-inline')
  static bool _matchesLoose(String enumName, String normalized) {
    var normIdx = 0;
    final normLen = normalized.length;
    final nameLen = enumName.length;

    for (var i = 0; i < nameLen; i++) {
      final c = enumName.codeUnitAt(i);
      if (c == 0x5F || c == 0x2D || c == 0x20 || (c >= 0x09 && c <= 0x0D)) {
        continue; // skip delimiters in enum name
      }
      if (normIdx >= normLen) return false;
      var nameC = c;
      if (nameC >= 0x41 && nameC <= 0x5A) nameC += 32;
      final normC = normalized.codeUnitAt(normIdx);
      if (nameC != normC) {
        // Fast-path: ASCII mismatch can never match under loose normalization
        if (nameC > 127 || normC > 127) {
          return _normalize(enumName) == normalized;
        }
        return false;
      }
      normIdx++;
    }
    return normIdx == normLen;
  }

  /// Splits [s] by [separator] in a single pass without intermediate iterable allocations.
  static List<Object?> _extractItemsFromString(
    String s,
    String separator,
    bool isStrict,
  ) {
    final items = <Object?>[];
    var start = 0;
    final sepLen = separator.length;
    final sLen = s.length;

    while (start <= sLen) {
      final nextSep = s.indexOf(separator, start);
      final seg =
          (nextSep == -1) ? s.substring(start) : s.substring(start, nextSep);
      final item = isStrict ? seg : seg.trim();
      if (item.isNotEmpty) {
        items.add(item);
      }
      if (nextSep == -1) break;
      start = nextSep + sepLen;
    }
    return items;
  }
}

/// An immutable, pre-indexed lookup index for high-throughput enum parsing.
///
/// Pre-computes normalized name lookups once upon creation into an internal
/// hash map, allowing subsequent [parse] and [parseList] calls to execute
/// with amortized O(1) map lookup time, avoiding repetitive linear scans.
///
/// Takes an immutable snapshot of [values] at construction time, isolating
/// the index from external mutations to the source collection.
///
/// ```dart
/// static final statusIndex = EnumIndex(Status.values, mode: EnumParserMode.loose);
///
/// final status = statusIndex.parse('in_progress');
/// ```
final class EnumIndex<T extends Enum> {
  /// Creates an [EnumIndex] over [values] for the specified [mode].
  EnumIndex(Iterable<T> values, {this.mode = EnumParserMode.loose})
      : values = List<T>.unmodifiable(values),
        _nameMap = _buildNameMap(values, mode);

  /// The immutable snapshot of enum values indexed by this instance.
  final List<T> values;

  /// The parsing mode used for string normalization and lookup.
  final EnumParserMode mode;

  final Map<String, T> _nameMap;

  static Map<String, T> _buildNameMap<T extends Enum>(
    Iterable<T> values,
    EnumParserMode mode,
  ) {
    final map = <String, T>{};
    for (final e in values) {
      final key = switch (mode) {
        EnumParserMode.strict => e.name,
        EnumParserMode.simple => e.name.toLowerCase(),
        EnumParserMode.loose => EnumParser._normalize(e.name),
      };
      if (key.isNotEmpty) {
        map.putIfAbsent(key, () => e);
      }
    }
    return map;
  }

  /// Parses and returns an enum of type [T] from [src] using this pre-indexed lookup in O(1) time.
  @pragma('vm:prefer-inline')
  T? parse(
    Object? src, {
    T? Function(Object src, Iterable<T> values)? converter,
    T? fallback,
  }) {
    if (src is T) return src;
    if (src == null || values.isEmpty) return fallback;

    final String? resolved;
    if (src is String) {
      if (mode == EnumParserMode.strict) {
        resolved = src;
      } else if (mode == EnumParserMode.simple) {
        final trimmed = src.trim();
        resolved = trimmed.isEmpty ? null : trimmed.toLowerCase();
      } else {
        final n = EnumParser._normalize(src);
        resolved = n.isEmpty ? null : n;
      }
    } else if (src is Enum) {
      if (mode == EnumParserMode.strict) {
        resolved = src.name;
      } else if (mode == EnumParserMode.simple) {
        resolved = src.name.toLowerCase();
      } else {
        final n = EnumParser._normalize(src.name);
        resolved = n.isEmpty ? null : n;
      }
    } else {
      resolved = null;
    }

    final match = resolved != null ? _nameMap[resolved] : null;

    return match ?? converter?.call(src, values) ?? fallback;
  }

  /// Parses each item in [src] using this pre-indexed lookup.
  List<T> parseList(
    Object? src, {
    String separator = ',',
    T? Function(Object src, Iterable<T> values)? converter,
    List<T> fallback = const [],
  }) {
    if (separator.isEmpty) {
      throw ArgumentError('Separator must not be empty');
    }

    // Fast path: already a typed List<T>
    if (src is List<T>) return src;
    if (src is Iterable<T>) return src.toList(growable: false);
    if (src == null || values.isEmpty) return fallback;

    final List<Object?> items;
    if (src is String) {
      final sepIdx = src.indexOf(separator);
      if (sepIdx == -1) {
        final item = mode == EnumParserMode.strict ? src : src.trim();
        if (item.isEmpty) return fallback;
        final parsed = parse(item, converter: converter);
        return parsed != null
            ? List<T>.filled(1, parsed, growable: false)
            : fallback;
      }
      items = EnumParser._extractItemsFromString(
        src,
        separator,
        mode == EnumParserMode.strict,
      );
    } else if (src is Iterable<Object?>) {
      items = src is List<Object?> ? src : src.toList();
    } else {
      return fallback;
    }

    if (items.isEmpty) return fallback;

    final result = <T>[];
    for (final item in items) {
      final parsed = parse(item, converter: converter);
      if (parsed != null) {
        result.add(parsed);
      }
    }

    return result.isEmpty ? fallback : result.toList(growable: false);
  }
}
