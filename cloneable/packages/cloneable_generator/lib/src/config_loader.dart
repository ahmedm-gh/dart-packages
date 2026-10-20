import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:cloneable/cloneable.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

/// Resolved configuration values combining `@Cloneable.defaults` annotations
/// and built-in defaults.
class ResolvedCloneableConfig {
  final CloneableOutput output;
  final CloneableStrategy strategy;
  final CloneableSentinel sentinel;
  final bool deepCopyCollections;
  final bool ignoreNull;
  final CloneableActiveness activeness;
  final CloneableCleanup cleanup;
  final CloneableFieldsConflict fieldsConflict;
  final String method;
  final String sentinelName;
  final CloneableAffix mixin;
  final CloneableAffix extension;
  final CloneableAffix file;
  final String? directory;
  final CloneableAffix? part;
  final CloneableAffix? standalone;
  final CloneableAffix? inLibrary;
  final CloneableAffix? inClass;

  /// Whether code generation is active.
  bool get active => activeness.isActive;

  const ResolvedCloneableConfig({
    this.output = CloneableOutput.auto,
    this.strategy = CloneableStrategy.auto,
    this.sentinel = CloneableSentinel.auto,
    this.deepCopyCollections = false,
    this.ignoreNull = false,
    this.activeness = CloneableActiveness.active,
    this.cleanup = CloneableCleanup.none,
    this.fieldsConflict = CloneableFieldsConflict.error,
    this.method = CloneableNaming.defaultMethod,
    this.sentinelName = CloneableNaming.defaultSentinel,
    this.mixin = CloneableNaming.defaultMixin,
    this.extension = CloneableNaming.defaultExtension,
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
      activeness: defaults.activeness,
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
    CloneableActiveness? activeness,
    bool? active,
    CloneableCleanup? cleanup,
    CloneableFieldsConflict? fieldsConflict,
    String? method,
    String? sentinelName,
    CloneableAffix? mixin,
    CloneableAffix? extension,
    CloneableAffix? file,
    String? directory,
    CloneableAffix? part,
    CloneableAffix? standalone,
    CloneableAffix? inLibrary,
    CloneableAffix? inClass,
  }) {
    final effectiveActiveness = activeness ??
        (active != null
            ? (active
                ? CloneableActiveness.active
                : CloneableActiveness.inactive)
            : this.activeness);

    return ResolvedCloneableConfig(
      output: output ?? this.output,
      strategy: strategy ?? this.strategy,
      sentinel: sentinel ?? this.sentinel,
      deepCopyCollections: deepCopyCollections ?? this.deepCopyCollections,
      ignoreNull: ignoreNull ?? this.ignoreNull,
      activeness: effectiveActiveness,
      cleanup: cleanup ?? this.cleanup,
      fieldsConflict: fieldsConflict ?? this.fieldsConflict,
      method: method ?? this.method,
      sentinelName: sentinelName ?? this.sentinelName,
      mixin: mixin ?? this.mixin,
      extension: extension ?? this.extension,
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
      activeness: raw.activeness,
      active: raw.active,
      cleanup: raw.cleanup,
      fieldsConflict: raw.fieldsConflict,
      method: raw.method,
      sentinelName: raw.sentinelName,
      directory: raw.directory,
      mixin: mergeAffix(mixin, raw.mixin),
      extension: mergeAffix(extension, raw.extension),
      file: mergeAffix(file, raw.file),
      part: _mergeNullableAffix(part, raw.part),
      standalone: _mergeNullableAffix(standalone, raw.standalone),
      inLibrary: _mergeNullableAffix(inLibrary, raw.inLibrary),
      inClass: _mergeNullableAffix(inClass, raw.inClass),
    );
  }

  static CloneableAffix mergeAffix(
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
  final CloneableActiveness? activeness;
  final CloneableCleanup? cleanup;
  final CloneableFieldsConflict? fieldsConflict;
  final String? method;
  final String? sentinelName;
  final CloneableAffix? mixin;
  final CloneableAffix? extension;
  final CloneableAffix? file;
  final String? directory;
  final CloneableAffix? part;
  final CloneableAffix? standalone;
  final CloneableAffix? inLibrary;
  final CloneableAffix? inClass;
  final String? constructor;
  final String? cloneableFieldsGetter;
  final List<String>? fields;

  const RawCloneableConfig({
    this.output,
    this.strategy,
    this.sentinel,
    this.deepCopyCollections,
    this.ignoreNull,
    this.active,
    this.activeness,
    this.cleanup,
    this.fieldsConflict,
    this.method,
    this.sentinelName,
    this.mixin,
    this.extension,
    this.file,
    this.directory,
    this.part,
    this.standalone,
    this.inLibrary,
    this.inClass,
    this.constructor,
    this.cloneableFieldsGetter,
    this.fields,
  });
}

/// Helper for extracting AST names, dot-shorthands, and values across analyzer versions.
class AstConfigReader {
  static String? readIdent(AstNode? expr) {
    if (expr == null) return null;
    if (expr case PrefixedIdentifier pi) {
      return pi.identifier.name;
    }
    if (expr case PropertyAccess pa) {
      return pa.propertyName.name;
    }
    if (expr case SimpleIdentifier si) {
      return si.name;
    }
    final src = expr.toSource().trim();
    if (src.startsWith('.')) {
      return src.substring(1);
    }
    if (src.contains('.')) {
      return src.split('.').last;
    }
    return src;
  }

  static CloneableSentinel? parseSentinel(String? name) => switch (name) {
        'auto' => CloneableSentinel.auto,
        'private' => CloneableSentinel.private,
        'package' => CloneableSentinel.package,
        _ => null,
      };

  static CloneableOutput? parseOutput(String? name) => switch (name) {
        'auto' => CloneableOutput.auto,
        'part' => CloneableOutput.part,
        'standalone' => CloneableOutput.standalone,
        'inLibrary' => CloneableOutput.inLibrary,
        'inClass' => CloneableOutput.inClass,
        _ => null,
      };

  static CloneableStrategy? parseStrategy(String? name) => switch (name) {
        'auto' => CloneableStrategy.auto,
        'extension' => CloneableStrategy.extension,
        'mixin' => CloneableStrategy.mixin,
        _ => null,
      };

  static CloneableCleanup? parseCleanup(String? name) => switch (name) {
        'none' => CloneableCleanup.none,
        'deactivate' => CloneableCleanup.deactivate,
        'remove' => CloneableCleanup.remove,
        _ => null,
      };

  static CloneableFieldsConflict? parseFieldsConflict(String? name) =>
      switch (name) {
        'error' => CloneableFieldsConflict.error,
        'merge' => CloneableFieldsConflict.merge,
        'inClass' => CloneableFieldsConflict.inClass,
        'inAnnotation' => CloneableFieldsConflict.inAnnotation,
        _ => null,
      };

  static CloneableActiveness? parseActiveness(String? name) => switch (name) {
        'active' => CloneableActiveness.active,
        'inactive' => CloneableActiveness.inactive,
        'forceActive' => CloneableActiveness.forceActive,
        'forceInactive' => CloneableActiveness.forceInactive,
        _ => null,
      };

  static bool? parseBool(AstNode? expr) {
    if (expr == null) return null;
    if (expr is BooleanLiteral) return expr.value;
    final src = expr.toSource().trim();
    if (src == 'true') return true;
    if (src == 'false') return false;
    return null;
  }

  static String? parseString(AstNode? expr) {
    if (expr == null) return null;
    if (expr is SimpleStringLiteral) return expr.value;
    if (expr is StringLiteral) return expr.stringValue;
    final src = expr.toSource().trim();
    if ((src.startsWith("'") && src.endsWith("'")) ||
        (src.startsWith('"') && src.endsWith('"'))) {
      return src.substring(1, src.length - 1);
    }
    return null;
  }

  static (String? name, AstNode? expr) getArgumentInfo(AstNode arg) {
    if (arg is NamedArgument) {
      return (arg.name.lexeme, arg.argumentExpression);
    }
    try {
      final name = (arg as dynamic).name.label.name as String?;
      final expr = (arg as dynamic).expression as AstNode?;
      return (name, expr);
    } catch (_) {
      try {
        final name = (arg as dynamic).name.lexeme as String?;
        final expr = (arg as dynamic).argumentExpression as AstNode?;
        return (name, expr);
      } catch (_) {
        return (null, null);
      }
    }
  }

  static Map<String, AstNode> extractNamedArguments(
      ArgumentList? argumentList) {
    final map = <String, AstNode>{};
    if (argumentList == null) return map;
    for (final arg in argumentList.arguments) {
      final (name, expr) = getArgumentInfo(arg);
      if (name != null && expr != null) {
        map[name] = expr;
      }
    }
    return map;
  }

  static RawCloneableConfig parseFromAnnotationAst(Annotation annotation) {
    return parseFromArguments(annotation.arguments, annotation.name.toSource());
  }

  static RawCloneableConfig parseFromInstanceCreationAst(
      InstanceCreationExpression expr) {
    return parseFromArguments(
        expr.argumentList, expr.constructorName.toSource());
  }

  static RawCloneableConfig parseFromArguments(
    ArgumentList? argumentList, [
    String? constructorOrAnnotationName,
  ]) {
    final args = extractNamedArguments(argumentList);

    final constructorOutput = switch (constructorOrAnnotationName) {
      'Cloneable.inClass' => CloneableOutput.inClass,
      'Cloneable.inLibrary' => CloneableOutput.inLibrary,
      'Cloneable.part' => CloneableOutput.part,
      'Cloneable.standalone' => CloneableOutput.standalone,
      _ => null,
    };

    final output = parseOutput(readIdent(args['output'])) ?? constructorOutput;
    final strategy = parseStrategy(readIdent(args['strategy']));
    final sentinel = parseSentinel(readIdent(args['sentinel']));
    final cleanup = parseCleanup(readIdent(args['cleanup']));
    final fieldsConflict =
        parseFieldsConflict(readIdent(args['fieldsConflict']));
    final activeness = parseActiveness(readIdent(args['activeness']));
    final active = parseBool(args['active']);
    final deepCopy = parseBool(args['deepCopyCollections']);
    final ignoreNull = parseBool(args['ignoreNull']);
    final constructor = parseString(args['constructor']);
    final cloneableFieldsGetter = parseString(args['cloneableFieldsGetter']);

    List<String>? fields;
    if (args['fields'] case final fieldsExpr?) {
      if (fieldsExpr is ListLiteral) {
        fields = fieldsExpr.elements
            .map((e) => parseString(e) ?? readIdent(e))
            .whereType<String>()
            .toList();
      }
    }

    String? method;
    String? sentinelName;
    String? directory;
    CloneableAffix? mixin;
    CloneableAffix? extension;
    CloneableAffix? file;
    CloneableAffix? part;
    CloneableAffix? standalone;
    CloneableAffix? inLibrary;
    CloneableAffix? inClass;

    if (args['naming'] case final namingExpr?) {
      if (namingExpr is InstanceCreationExpression ||
          namingExpr is MethodInvocation) {
        ArgumentList? namingArgs;
        if (namingExpr is InstanceCreationExpression) {
          namingArgs = namingExpr.argumentList;
        } else if (namingExpr is MethodInvocation) {
          namingArgs = namingExpr.argumentList;
        }
        final nMap = extractNamedArguments(namingArgs);

        method = parseString(nMap['method']);
        sentinelName = parseString(nMap['sentinel']);
        directory = parseString(nMap['directory']);

        CloneableAffix? parseAffixExpr(AstNode? aExpr) {
          if (aExpr == null) return null;
          ArgumentList? aArgs;
          if (aExpr is InstanceCreationExpression) {
            aArgs = aExpr.argumentList;
          } else if (aExpr is MethodInvocation) {
            aArgs = aExpr.argumentList;
          }
          final aMap = extractNamedArguments(aArgs);
          final p = parseString(aMap['prefix']);
          final s = parseString(aMap['suffix']);
          if (p == null && s == null) return null;
          return CloneableAffix(prefix: p, suffix: s);
        }

        mixin = parseAffixExpr(nMap['mixin']);
        extension = parseAffixExpr(nMap['extension']);
        file = parseAffixExpr(nMap['file']);
        part = parseAffixExpr(nMap['part']);
        standalone = parseAffixExpr(nMap['standalone']);
        inLibrary = parseAffixExpr(nMap['inLibrary']);
        inClass = parseAffixExpr(nMap['inClass']);
      }
    }

    return RawCloneableConfig(
      output: output,
      strategy: strategy,
      sentinel: sentinel,
      deepCopyCollections: deepCopy,
      ignoreNull: ignoreNull,
      active: active,
      activeness: activeness,
      cleanup: cleanup,
      fieldsConflict: fieldsConflict,
      method: method,
      sentinelName: sentinelName,
      directory: directory,
      mixin: mixin,
      extension: extension,
      file: file,
      part: part,
      standalone: standalone,
      inLibrary: inLibrary,
      inClass: inClass,
      constructor: constructor,
      cloneableFieldsGetter: cloneableFieldsGetter,
      fields: fields,
    );
  }
}

/// Utility for discovering and loading `@Cloneable.defaults(...)` in-code annotations.
class ConfigLoader {
  static const _defaultsTypeChecker = TypeChecker.any([
    TypeChecker.typeNamedLiterally('CloneableDefaults', inPackage: 'cloneable'),
    TypeChecker.typeNamedLiterally('Cloneable', inPackage: 'cloneable'),
    TypeChecker.fromUrl(
        'package:cloneable/src/annotations.dart#CloneableDefaults'),
    TypeChecker.fromUrl('package:cloneable/cloneable.dart#CloneableDefaults'),
  ]);

  /// Clears internal cache (maintained for backward-compatibility).
  static void clearCache() {}

  /// Scans Dart source code for a library-level or top-level `@Cloneable.defaults(...)` annotation
  /// or top-level const `CloneableDefaults` variable.
  static RawCloneableConfig? findInContentAst(String content) {
    try {
      if (!content.contains('Cloneable.defaults') &&
          !content.contains('CloneableDefaults')) {
        return null;
      }
      final parsed = parseString(content: content, throwIfDiagnostics: false);

      // Check library directives
      for (final directive in parsed.unit.directives) {
        for (final meta in directive.metadata) {
          final name = meta.name.toSource();
          if (name == 'Cloneable.defaults' || name == 'CloneableDefaults') {
            return AstConfigReader.parseFromAnnotationAst(meta);
          }
        }
      }

      // Check top-level elements (classes, mixins, const variables)
      for (final decl in parsed.unit.declarations) {
        for (final meta in decl.metadata) {
          final name = meta.name.toSource();
          if (name == 'Cloneable.defaults' || name == 'CloneableDefaults') {
            return AstConfigReader.parseFromAnnotationAst(meta);
          }
        }
        if (decl case TopLevelVariableDeclaration tlvd) {
          for (final v in tlvd.variables.variables) {
            final init = v.initializer;
            if (init != null) {
              final initSrc = init.toSource();
              if (initSrc.contains('CloneableDefaults') ||
                  initSrc.contains('Cloneable.defaults')) {
                if (init case InstanceCreationExpression ice) {
                  return AstConfigReader.parseFromInstanceCreationAst(ice);
                } else if (init case MethodInvocation mi) {
                  return AstConfigReader.parseFromArguments(
                    mi.argumentList,
                    mi.methodName.toSource(),
                  );
                }
              }
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Scans a file's AST for a library-level or top-level `@Cloneable.defaults(...)` annotation.
  static RawCloneableConfig? findInFileAst(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;
      return findInContentAst(file.readAsStringSync());
    } catch (_) {}
    return null;
  }

  /// Automatically discovers the project SSOT configuration (`lib/cloneable_defaults.dart`).
  static RawCloneableConfig? findProjectSsotDefaults(String? startPath) {
    if (startPath == null || startPath.isEmpty) return null;
    try {
      var currentDir =
          File(startPath).existsSync() ? p.dirname(startPath) : startPath;

      for (var i = 0; i < 15; i++) {
        final candidate1 = p.join(currentDir, 'lib', 'cloneable_defaults.dart');
        if (File(candidate1).existsSync()) {
          final cfg = findInFileAst(candidate1);
          if (cfg != null) return cfg;
        }

        final candidate2 = p.join(currentDir, 'cloneable_defaults.dart');
        if (File(candidate2).existsSync()) {
          final cfg = findInFileAst(candidate2);
          if (cfg != null) return cfg;
        }

        final pubspec = p.join(currentDir, 'pubspec.yaml');
        if (File(pubspec).existsSync()) {
          // Reached package root
          break;
        }

        final parent = p.dirname(currentDir);
        if (parent == currentDir) break;
        currentDir = parent;
      }
    } catch (_) {}
    return null;
  }

  /// Scans [library] for a library-level or top-level `@Cloneable.defaults(...)` or
  /// `@CloneableDefaults(...)` annotation, or imported defaults.
  static RawCloneableConfig? findInCodeDefaults(
    LibraryElement library, [
    Set<LibraryElement>? visited,
  ]) {
    visited ??= <LibraryElement>{};
    if (!visited.add(library)) return null;

    ConstantReader? defaultsReader;

    // 1. Check library directive metadata (e.g. @Cloneable.defaults(...) library;)
    try {
      if (_defaultsTypeChecker.firstAnnotationOf(library,
              throwOnUnresolved: false)
          case final obj?) {
        defaultsReader = ConstantReader(obj);
      }
    } catch (_) {}

    // 2. Check top-level elements (classes, mixins, or top-level const variables)
    if (defaultsReader == null) {
      for (final el in [
        ...library.classes,
        ...library.mixins,
        ...library.extensions,
      ]) {
        try {
          for (final meta in el.metadata.annotations) {
            final constructor = meta.element;
            if (constructor is ConstructorElement) {
              final enclosing = constructor.enclosingElement;
              final isCloneableDefaults = enclosing.name == 'CloneableDefaults';
              final isCloneableNamedDefaults = enclosing.name == 'Cloneable' &&
                  constructor.name == 'defaults';
              if (isCloneableDefaults || isCloneableNamedDefaults) {
                if (meta.computeConstantValue() case final obj?) {
                  defaultsReader = ConstantReader(obj);
                  break;
                }
              }
            } else if (meta.toSource().contains('Cloneable.defaults') ||
                meta.toSource().contains('CloneableDefaults')) {
              if (meta.computeConstantValue() case final obj?) {
                defaultsReader = ConstantReader(obj);
                break;
              }
            }
          }
          if (defaultsReader != null) break;
        } catch (_) {}
      }
      if (defaultsReader == null) {
        for (final el in library.topLevelVariables) {
          if (el.isConst) {
            try {
              if (el.computeConstantValue() case final val?
                  when val.type != null &&
                      _defaultsTypeChecker.isAssignableFromType(val.type!)) {
                defaultsReader = ConstantReader(val);
                break;
              }
            } catch (_) {}
          }
        }
      }
    }

    // 3. Fallback to AST scan for current file or source contents if ConstantReader could not be resolved (e.g. dot-shorthands or mock resolveSource)
    if (defaultsReader == null) {
      try {
        final content = library.firstFragment.source.contents.data;
        final astCfg = findInContentAst(content);
        if (astCfg != null) {
          return astCfg;
        }
      } catch (_) {}
      final sourcePath = library.firstFragment.source.fullName;
      final astCfg = findInFileAst(sourcePath);
      if (astCfg != null) {
        return astCfg;
      }
    }

    // 4. Check imported libraries (e.g. import 'cloneable_defaults.dart';)
    if (defaultsReader == null) {
      for (final imp in library.firstFragment.libraryImports) {
        final importedLib = imp.importedLibrary;
        if (importedLib == null || importedLib.isInSdk) continue;
        final uriStr = imp.uri.toString();
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

    final activeness = switch (defaultsReader
        .peek('activeness')
        ?.objectValue
        .getField('index')
        ?.toIntValue()) {
      final index?
          when index >= 0 && index < CloneableActiveness.values.length =>
        CloneableActiveness.values[index],
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

    final readerConfig = RawCloneableConfig(
      output: output,
      strategy: strategy,
      sentinel: sentinel,
      deepCopyCollections: deepCopy,
      ignoreNull: ignoreNull,
      active: active,
      activeness: activeness,
      cleanup: cleanup,
      fieldsConflict: fieldsConflict,
      method: method,
      sentinelName: sentinelName,
      directory: namingReader?.peek('directory')?.stringValue,
      mixin: readAffix('mixin', CloneableNaming.defaultMixin),
      extension: readAffix('extension', CloneableNaming.defaultExtension),
      file: readAffix('file', CloneableNaming.defaultFile),
      part: readAffix('part'),
      standalone: readAffix('standalone'),
      inLibrary: readAffix('inLibrary'),
      inClass: readAffix('inClass'),
    );

    // Complement with AST if any dot-shorthands were skipped by constant evaluation
    final sourcePath = library.firstFragment.source.fullName;
    final astConfig = findInFileAst(sourcePath);
    if (astConfig != null) {
      return RawCloneableConfig(
        output: readerConfig.output ?? astConfig.output,
        strategy: readerConfig.strategy ?? astConfig.strategy,
        sentinel: readerConfig.sentinel ?? astConfig.sentinel,
        deepCopyCollections:
            readerConfig.deepCopyCollections ?? astConfig.deepCopyCollections,
        ignoreNull: readerConfig.ignoreNull ?? astConfig.ignoreNull,
        active: readerConfig.active ?? astConfig.active,
        activeness: readerConfig.activeness ?? astConfig.activeness,
        cleanup: readerConfig.cleanup ?? astConfig.cleanup,
        fieldsConflict: readerConfig.fieldsConflict ?? astConfig.fieldsConflict,
        method: readerConfig.method ?? astConfig.method,
        sentinelName: readerConfig.sentinelName ?? astConfig.sentinelName,
        directory: readerConfig.directory ?? astConfig.directory,
        mixin: readerConfig.mixin ?? astConfig.mixin,
        extension: readerConfig.extension ?? astConfig.extension,
        file: readerConfig.file ?? astConfig.file,
        part: readerConfig.part ?? astConfig.part,
        standalone: readerConfig.standalone ?? astConfig.standalone,
        inLibrary: readerConfig.inLibrary ?? astConfig.inLibrary,
        inClass: readerConfig.inClass ?? astConfig.inClass,
      );
    }

    return readerConfig;
  }

  /// Resolves effective project defaults by cascading:
  /// 1. Built-in [CloneableDefaults.instance] (SSOT fallback)
  /// 2. Project SSOT (`cloneable_defaults.dart`)
  /// 3. In-code `@Cloneable.defaults(...)` in current [library] or file
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

    final effectivePath = filePath ??
        searchDirectory ??
        effectiveLib?.firstFragment.source.fullName;

    // 1. Cascade Project SSOT defaults (cloneable_defaults.dart)
    final projectSsot = findProjectSsotDefaults(effectivePath);
    if (projectSsot != null) {
      config = config.applyRaw(projectSsot);
    }

    // 2. Cascade In-library defaults (current file or explicitly imported defaults)
    if (effectiveLib != null) {
      final inCodeConfig = findInCodeDefaults(effectiveLib);
      if (inCodeConfig != null) {
        config = config.applyRaw(inCodeConfig);
      }
    } else if (effectivePath != null) {
      final fileConfig = findInFileAst(effectivePath);
      if (fileConfig != null) {
        config = config.applyRaw(fileConfig);
      }
    }

    return config;
  }
}
