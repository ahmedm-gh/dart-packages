import 'package:analyzer/dart/element/element.dart';
import 'package:cloneable/cloneable.dart';
import 'package:source_gen/source_gen.dart';

/// Resolved configuration values combining `@Cloneable.defaults` annotations
/// and built-in defaults.
class ResolvedCloneableConfig {
  final CloneableOutput output;
  final CloneableStrategy strategy;
  final CloneableSentinel sentinel;
  final bool deepCopyCollections;
  final bool ignoreNull;
  final bool active;
  final CloneableCleanup cleanup;
  final CloneableFieldsConflict fieldsConflict;
  final String method;
  final String sentinelName;
  final CloneableAffix mixin;
  final CloneableAffix extension;
  final CloneableAffix typedef;
  final CloneableAffix file;
  final String? directory;
  final CloneableAffix? part;
  final CloneableAffix? standalone;
  final CloneableAffix? inLibrary;
  final CloneableAffix? inClass;

  const ResolvedCloneableConfig({
    this.output = CloneableOutput.auto,
    this.strategy = CloneableStrategy.auto,
    this.sentinel = CloneableSentinel.auto,
    this.deepCopyCollections = false,
    this.ignoreNull = false,
    this.active = true,
    this.cleanup = CloneableCleanup.none,
    this.fieldsConflict = CloneableFieldsConflict.error,
    this.method = CloneableNaming.defaultMethod,
    this.sentinelName = CloneableNaming.defaultSentinel,
    this.mixin = CloneableNaming.defaultMixin,
    this.extension = CloneableNaming.defaultExtension,
    this.typedef = CloneableNaming.defaultTypedef,
    this.file = CloneableNaming.defaultFile,
    this.directory,
    this.part,
    this.standalone,
    this.inLibrary,
    this.inClass,
  });

  /// Creates a [ResolvedCloneableConfig] from a [CloneableDefaults] instance.
  factory ResolvedCloneableConfig.fromDefaults(CloneableDefaults defaults) {
    return ResolvedCloneableConfig(
      output: defaults.output,
      strategy: defaults.strategy,
      sentinel: defaults.sentinel,
      deepCopyCollections: defaults.deepCopyCollections,
      ignoreNull: defaults.ignoreNull,
      active: defaults.active,
      cleanup: defaults.cleanup,
      fieldsConflict: defaults.fieldsConflict,
      method: defaults.naming.method,
      sentinelName: defaults.naming.sentinel,
      directory: defaults.naming.directory,
      mixin: CloneableAffix(
        prefix: defaults.naming.mixin.prefix ??
            CloneableNaming.defaultMixin.prefix ??
            '',
        suffix: defaults.naming.mixin.suffix ??
            CloneableNaming.defaultMixin.suffix ??
            '',
      ),
      extension: CloneableAffix(
        prefix: defaults.naming.extension.prefix ??
            CloneableNaming.defaultExtension.prefix ??
            '',
        suffix: defaults.naming.extension.suffix ??
            CloneableNaming.defaultExtension.suffix ??
            '',
      ),
      typedef: CloneableAffix(
        prefix: defaults.naming.typedef.prefix ??
            CloneableNaming.defaultTypedef.prefix ??
            '',
        suffix: defaults.naming.typedef.suffix ??
            CloneableNaming.defaultTypedef.suffix ??
            '',
      ),
      file: CloneableAffix(
        prefix: defaults.naming.file.prefix ??
            CloneableNaming.defaultFile.prefix ??
            '',
        suffix: defaults.naming.file.suffix ??
            CloneableNaming.defaultFile.suffix ??
            '',
      ),
      part: defaults.naming.part,
      standalone: defaults.naming.standalone,
      inLibrary: defaults.naming.inLibrary,
      inClass: defaults.naming.inClass,
    );
  }

  /// Copies this configuration overriding only non-null values.
  ResolvedCloneableConfig copyWith({
    CloneableOutput? output,
    CloneableStrategy? strategy,
    CloneableSentinel? sentinel,
    bool? deepCopyCollections,
    bool? ignoreNull,
    bool? active,
    CloneableCleanup? cleanup,
    CloneableFieldsConflict? fieldsConflict,
    String? method,
    String? sentinelName,
    CloneableAffix? mixin,
    CloneableAffix? extension,
    CloneableAffix? typedef,
    CloneableAffix? file,
    String? directory,
    CloneableAffix? part,
    CloneableAffix? standalone,
    CloneableAffix? inLibrary,
    CloneableAffix? inClass,
  }) {
    return ResolvedCloneableConfig(
      output: output ?? this.output,
      strategy: strategy ?? this.strategy,
      sentinel: sentinel ?? this.sentinel,
      deepCopyCollections: deepCopyCollections ?? this.deepCopyCollections,
      ignoreNull: ignoreNull ?? this.ignoreNull,
      active: active ?? this.active,
      cleanup: cleanup ?? this.cleanup,
      fieldsConflict: fieldsConflict ?? this.fieldsConflict,
      method: method ?? this.method,
      sentinelName: sentinelName ?? this.sentinelName,
      mixin: mixin ?? this.mixin,
      extension: extension ?? this.extension,
      typedef: typedef ?? this.typedef,
      file: file ?? this.file,
      directory: directory ?? this.directory,
      part: part ?? this.part,
      standalone: standalone ?? this.standalone,
      inLibrary: inLibrary ?? this.inLibrary,
      inClass: inClass ?? this.inClass,
    );
  }

  /// Merges a partial [RawCloneableConfig], overriding only non-null values.
  ResolvedCloneableConfig applyRaw(RawCloneableConfig raw) {
    return copyWith(
      output: raw.output,
      strategy: raw.strategy,
      sentinel: raw.sentinel,
      deepCopyCollections: raw.deepCopyCollections,
      ignoreNull: raw.ignoreNull,
      active: raw.active,
      cleanup: raw.cleanup,
      fieldsConflict: raw.fieldsConflict,
      method: raw.method,
      sentinelName: raw.sentinelName,
      directory: raw.directory,
      mixin: _mergeAffix(mixin, raw.mixin),
      extension: _mergeAffix(extension, raw.extension),
      typedef: _mergeAffix(typedef, raw.typedef),
      file: _mergeAffix(file, raw.file),
      part: _mergeNullableAffix(part, raw.part),
      standalone: _mergeNullableAffix(standalone, raw.standalone),
      inLibrary: _mergeNullableAffix(inLibrary, raw.inLibrary),
      inClass: _mergeNullableAffix(inClass, raw.inClass),
    );
  }

  static CloneableAffix _mergeAffix(
      CloneableAffix base, CloneableAffix? override) {
    if (override == null) return base;
    return CloneableAffix(
      prefix: override.prefix ?? base.prefix ?? '',
      suffix: override.suffix ?? base.suffix ?? '',
    );
  }

  static CloneableAffix? _mergeNullableAffix(
    CloneableAffix? base,
    CloneableAffix? override,
  ) {
    if (override == null) return base;
    if (base == null) return override;
    return CloneableAffix(
      prefix: override.prefix ?? base.prefix,
      suffix: override.suffix ?? base.suffix,
    );
  }
}

/// Represents a raw, partial configuration parsed from `@Cloneable.defaults`.
class RawCloneableConfig {
  final CloneableOutput? output;
  final CloneableStrategy? strategy;
  final CloneableSentinel? sentinel;
  final bool? deepCopyCollections;
  final bool? ignoreNull;
  final bool? active;
  final CloneableCleanup? cleanup;
  final CloneableFieldsConflict? fieldsConflict;
  final String? method;
  final String? sentinelName;
  final CloneableAffix? mixin;
  final CloneableAffix? extension;
  final CloneableAffix? typedef;
  final CloneableAffix? file;
  final String? directory;
  final CloneableAffix? part;
  final CloneableAffix? standalone;
  final CloneableAffix? inLibrary;
  final CloneableAffix? inClass;

  const RawCloneableConfig({
    this.output,
    this.strategy,
    this.sentinel,
    this.deepCopyCollections,
    this.ignoreNull,
    this.active,
    this.cleanup,
    this.fieldsConflict,
    this.method,
    this.sentinelName,
    this.mixin,
    this.extension,
    this.typedef,
    this.file,
    this.directory,
    this.part,
    this.standalone,
    this.inLibrary,
    this.inClass,
  });
}

/// Utility for discovering and loading `@Cloneable.defaults(...)` in-code annotations.
class ConfigLoader {
  /// Clears internal cache (maintained for backward-compatibility).
  static void clearCache() {}

  /// Scans [library] for a library-level or top-level `@Cloneable.defaults(...)` or
  /// `@CloneableDefaults(...)` annotation, or imported defaults.
  static RawCloneableConfig? findInCodeDefaults(
    LibraryElement library, [
    Set<LibraryElement>? visited,
  ]) {
    visited ??= <LibraryElement>{};
    if (!visited.add(library)) return null;

    const defaultsTypeChecker = TypeChecker.fromRuntime(CloneableDefaults);
    ConstantReader? defaultsReader;

    // 1. Check library directive metadata (e.g. @Cloneable.defaults(...) library;)
    if (defaultsTypeChecker.firstAnnotationOf(library) case final obj?) {
      defaultsReader = ConstantReader(obj);
    }

    // 2. Check top-level elements (classes, mixins, or top-level const variables)
    if (defaultsReader == null) {
      for (final el in library.topLevelElements) {
        if (defaultsTypeChecker.firstAnnotationOf(el) case final obj?) {
          defaultsReader = ConstantReader(obj);
          break;
        }
        if (el is TopLevelVariableElement && el.isConst) {
          if (el.computeConstantValue() case final val?
              when defaultsTypeChecker.isAssignableFromType(val.type!)) {
            defaultsReader = ConstantReader(val);
            break;
          }
        }
      }
    }

    // 3. Check imported libraries (e.g. import 'cloneable_defaults.dart';)
    if (defaultsReader == null) {
      for (final importedLib in library.importedLibraries) {
        if (importedLib.isInSdk) continue;
        final uriStr = importedLib.source.uri.toString();
        if (uriStr.startsWith('package:cloneable/')) continue;

        final importedConfig = findInCodeDefaults(importedLib, visited);
        if (importedConfig != null) {
          return importedConfig;
        }
      }
    }

    if (defaultsReader == null) return null;

    final output = switch (defaultsReader
        .peek('output')
        ?.objectValue
        .getField('index')
        ?.toIntValue()) {
      final index? when index >= 0 && index < CloneableOutput.values.length =>
        CloneableOutput.values[index],
      _ => null,
    };

    final strategy = switch (defaultsReader
        .peek('strategy')
        ?.objectValue
        .getField('index')
        ?.toIntValue()) {
      final index? when index >= 0 && index < CloneableStrategy.values.length =>
        CloneableStrategy.values[index],
      _ => null,
    };

    final sentinel = switch (defaultsReader
        .peek('sentinel')
        ?.objectValue
        .getField('index')
        ?.toIntValue()) {
      final index? when index >= 0 && index < CloneableSentinel.values.length =>
        CloneableSentinel.values[index],
      _ => null,
    };

    final fieldsConflict = switch (defaultsReader
        .peek('fieldsConflict')
        ?.objectValue
        .getField('index')
        ?.toIntValue()) {
      final index?
          when index >= 0 && index < CloneableFieldsConflict.values.length =>
        CloneableFieldsConflict.values[index],
      _ => null,
    };

    final deepCopy = defaultsReader.peek('deepCopyCollections')?.boolValue;
    final ignoreNull = defaultsReader.peek('ignoreNull')?.boolValue;
    final active = defaultsReader.peek('active')?.boolValue;
    final cleanup = switch (defaultsReader
        .peek('cleanup')
        ?.objectValue
        .getField('index')
        ?.toIntValue()) {
      final index? when index >= 0 && index < CloneableCleanup.values.length =>
        CloneableCleanup.values[index],
      _ => null,
    };

    final namingReader = defaultsReader.peek('naming');
    final method = switch (namingReader?.peek('method')?.stringValue) {
      CloneableNaming.defaultMethod => null,
      final m => m,
    };
    final sentinelName = switch (namingReader?.peek('sentinel')?.stringValue) {
      CloneableNaming.defaultSentinel => null,
      final s => s,
    };

    CloneableAffix? readAffix(String field, [CloneableAffix? defaultAffix]) {
      if (namingReader?.peek(field) case final affixReader?) {
        final p = affixReader.peek('prefix')?.stringValue;
        final s = affixReader.peek('suffix')?.stringValue;
        if (defaultAffix != null &&
            p == defaultAffix.prefix &&
            s == defaultAffix.suffix) {
          return null;
        }
        if (p == null && s == null) return null;
        return CloneableAffix(prefix: p, suffix: s);
      }
      return null;
    }

    return RawCloneableConfig(
      output: output,
      strategy: strategy,
      sentinel: sentinel,
      deepCopyCollections: deepCopy,
      ignoreNull: ignoreNull,
      active: active,
      cleanup: cleanup,
      fieldsConflict: fieldsConflict,
      method: method,
      sentinelName: sentinelName,
      directory: namingReader?.peek('directory')?.stringValue,
      mixin: readAffix('mixin', CloneableNaming.defaultMixin),
      extension: readAffix('extension', CloneableNaming.defaultExtension),
      typedef: readAffix('typedef', CloneableNaming.defaultTypedef),
      file: readAffix('file', CloneableNaming.defaultFile),
      part: readAffix('part'),
      standalone: readAffix('standalone'),
      inLibrary: readAffix('inLibrary'),
      inClass: readAffix('inClass'),
    );
  }

  /// Resolves effective project defaults by cascading:
  /// 1. In-code `@Cloneable.defaults(...)` in [library] or [classElement]
  /// 2. Built-in [CloneableDefaults.instance] (SSOT fallback)
  static ResolvedCloneableConfig resolveDefaults({
    LibraryElement? library,
    Element? element,
    ClassElement? classElement,
    String? searchDirectory,
    String? filePath,
  }) {
    var config = ResolvedCloneableConfig.fromDefaults(
      CloneableDefaults.instance,
    );

    final effectiveLib = library ??
        (element is LibraryElement
            ? element
            : (element?.library ?? classElement?.library));

    if (effectiveLib != null) {
      final inCodeConfig = findInCodeDefaults(effectiveLib);
      if (inCodeConfig != null) {
        config = config.applyRaw(inCodeConfig);
      }
    }

    return config;
  }
}
