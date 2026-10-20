import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:cloneable/cloneable.dart';
import 'package:cloneable_generator/src/config_loader.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

extension _ClassDeclarationHelper on ClassDeclaration {
  String get className => declaredFragment?.name ?? namePart.toSource();
  BlockClassBody? get asBlockBody =>
      body is BlockClassBody ? body as BlockClassBody : null;
  List<ClassMember> get members => asBlockBody?.members ?? const [];
}

extension _NamedTypeHelper on NamedType {
  String get typeName => name.lexeme;
}

enum _CollectionKind {
  none,
  list,
  set,
  map,
  iterable,
  queue,
  listQueue,
  doubleLinkedQueue,
  hashMap,
  linkedHashMap,
  splayTreeMap,
  hashSet,
  linkedHashSet,
  splayTreeSet,
  uint8List,
  int8List,
  uint8ClampedList,
  int16List,
  uint16List,
  int32List,
  uint32List,
  int64List,
  uint64List,
  float32List,
  float64List,
  float32x4List,
  int32x4List,
  float64x2List,
  byteData;

  bool get isNone => this == _CollectionKind.none;

  bool get isTypedData {
    return switch (this) {
      uint8List ||
      int8List ||
      uint8ClampedList ||
      int16List ||
      uint16List ||
      int32List ||
      uint32List ||
      int64List ||
      uint64List ||
      float32List ||
      float64List ||
      float32x4List ||
      int32x4List ||
      float64x2List ||
      byteData =>
        true,
      _ => false,
    };
  }

  bool get isCollectionLibrary {
    return switch (this) {
      queue ||
      listQueue ||
      doubleLinkedQueue ||
      hashMap ||
      linkedHashMap ||
      splayTreeMap ||
      hashSet ||
      linkedHashSet ||
      splayTreeSet =>
        true,
      _ => false,
    };
  }
}

/// Code generator for creating strongly-typed `copyWith` methods with
/// explicit-null handling.
final class CloneableGenerator extends GeneratorForAnnotation<Cloneable> {
  static const _cloneableTypeChecker =
      TypeChecker.fromUrl('package:cloneable/cloneable.dart#Cloneable');
  static const _fieldAnnotationTypeChecker =
      TypeChecker.fromUrl('package:cloneable/cloneable.dart#CloneableField');

  /// The fallback symbol prefix when not specified in [@Cloneable].
  final String? defaultPrefix;

  /// The fallback symbol suffix when not specified in [@Cloneable].
  final String? defaultSuffix;

  const CloneableGenerator({
    this.defaultPrefix,
    this.defaultSuffix,
  });

  /// Returns the start marker comment for the specified [className].
  static String startMarker(String className) =>
      '\n// cloneable:start ($className) - GENERATED CODE - DO NOT MODIFY BY HAND\n'
      '// (run: dart run cloneable_generator to regenerate)\n';

  /// Returns the end marker comment for the specified [className].
  static String endMarker(String className) =>
      '\n// cloneable:end ($className)\n';

  /// Wraps [code] with the start and end markers for [className].
  static String wrapWithMarkers(String className, String code) {
    final trimmed = code.trim();
    return '${startMarker(className)}\n'
        '$trimmed\n'
        '${endMarker(className)}';
  }

  /// Returns a regex pattern that matches the inline generated block for [className].
  static RegExp markerPattern(String className) {
    final escaped = RegExp.escape(className);
    return RegExp(
      r'(?:\r?\n)?'
      '(?://\\s*={5,}\\s*\\r?\\n)?'
      '//\\s*cloneable:\\s*start\\s*\\($escaped\\)[^\\r\\n]*\\r?\\n'
      '(?://\\s*={5,}\\s*\\r?\\n)?'
      '[\\s\\S]*?'
      '(?://\\s*={5,}\\s*\\r?\\n)?'
      '//\\s*cloneable:\\s*end\\s*\\($escaped\\)[^\\r\\n]*'
      r'(?:\r?\n//\s*={5,}\s*)?',
      caseSensitive: false,
    );
  }

  /// Returns a regex pattern that matches the typedef generated block for [className].
  static RegExp typedefMarkerPattern(String className) {
    final escaped = RegExp.escape(className);
    return RegExp(
      r'(?:\r?\n)?'
      '(?://\\s*={5,}\\s*\\r?\\n)?'
      '//\\s*cloneable:\\s*typedef:\\s*start\\s*\\($escaped\\)[^\\r\\n]*\\r?\\n'
      '(?://\\s*={5,}\\s*\\r?\\n)?'
      '[\\s\\S]*?'
      '(?://\\s*={5,}\\s*\\r?\\n)?'
      '//\\s*cloneable:\\s*typedef:\\s*end\\s*\\($escaped\\)[^\\r\\n]*'
      r'(?:\r?\n//\s*={5,}\s*)?',
      caseSensitive: false,
    );
  }

  /// Regex pattern matching any inline Cloneable marker block.
  /// Captures the class name in group 1.
  static final RegExp allMarkersPattern = RegExp(
    r'(?:\r?\n)?'
    r'(?://\s*={5,}\s*\r?\n)?'
    r'//\s*cloneable:\s*start\s*\(([^)]+)\)[^\r\n]*\r?\n'
    r'(?://\s*={5,}\s*\r?\n)?'
    r'[\s\S]*?'
    r'(?://\s*={5,}\s*\r?\n)?'
    r'//\s*cloneable:\s*end\s*\(\1\)[^\r\n]*'
    r'(?:\r?\n//\s*={5,}\s*)?',
    caseSensitive: false,
  );

  /// Regex pattern matching any typedef Cloneable marker block.
  /// Captures the class name in group 1.
  static final RegExp allTypedefMarkersPattern = RegExp(
    r'(?:\r?\n)?'
    r'(?://\s*={5,}\s*\r?\n)?'
    r'//\s*cloneable:\s*typedef:\s*start\s*\(([^)]+)\)[^\r\n]*\r?\n'
    r'(?://\s*={5,}\s*\r?\n)?'
    r'[\s\S]*?'
    r'(?://\s*={5,}\s*\r?\n)?'
    r'//\s*cloneable:\s*typedef:\s*end\s*\(\1\)[^\r\n]*'
    r'(?:\r?\n//\s*={5,}\s*)?',
    caseSensitive: false,
  );

  static RawCloneableConfig? _findClassCloneableAst(
    ClassElement element,
    SomeParsedLibraryResult? parsedLibResult,
  ) {
    try {
      final unit = _findCompilationUnit(element, parsedLibResult);
      if (unit == null) return null;
      for (final decl in unit.declarations) {
        if (decl is ClassDeclaration && decl.className == element.name) {
          for (final meta in decl.metadata) {
            final name = meta.name.toSource();
            if (name == 'Cloneable' || name.startsWith('Cloneable.')) {
              return AstConfigReader.parseFromAnnotationAst(meta);
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static CompilationUnit? _findCompilationUnit(
    ClassElement element,
    SomeParsedLibraryResult? parsedLibResult,
  ) {
    if (parsedLibResult case ParsedLibraryResult parsedLib) {
      for (final u in parsedLib.units) {
        for (final decl in u.unit.declarations) {
          if (decl is ClassDeclaration && decl.className == element.name) {
            return u.unit;
          }
        }
      }
    }
    try {
      final content = element.library.firstFragment.source.contents.data;
      final parsed = parseString(content: content, throwIfDiagnostics: false);
      return parsed.unit;
    } catch (_) {}
    return null;
  }

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'The @Cloneable() annotation can only be applied to classes.',
        element: element,
      );
    }

    final resolvedDefaults = ConfigLoader.resolveDefaults(
      library: element.library,
      searchDirectory: p.dirname(buildStep.inputId.path),
    );

    final astConfig = _findClassCloneableAst(element, null);

    final rawActiveness = annotation.peek('activeness') != null
        ? switch (annotation
            .peek('activeness')!
            .objectValue
            .getField('index')
            ?.toIntValue()) {
            final index?
                when index >= 0 && index < CloneableActiveness.values.length =>
              CloneableActiveness.values[index],
            _ => null,
          }
        : astConfig?.activeness;

    final rawActive = annotation.peek('active')?.boolValue ?? astConfig?.active;

    final bool isActive;
    if (rawActiveness == CloneableActiveness.forceActive) {
      isActive = true;
    } else if (rawActiveness == CloneableActiveness.forceInactive) {
      isActive = false;
    } else if (resolvedDefaults.activeness ==
        CloneableActiveness.forceInactive) {
      isActive = false;
    } else if (rawActiveness != null) {
      isActive = rawActiveness.isActive;
    } else if (rawActive != null) {
      isActive = rawActive;
    } else {
      isActive = resolvedDefaults.active;
    }

    if (!isActive) {
      return '';
    }

    final output = switch (annotation
        .peek('output')
        ?.objectValue
        .getField('index')
        ?.toIntValue()) {
      final index? when index >= 0 && index < CloneableOutput.values.length =>
        CloneableOutput.values[index],
      _ => astConfig?.output ?? resolvedDefaults.output,
    };

    if (output.isInline) {
      log.info(
        "@Cloneable(output: CloneableOutput.${output.name}) detected on '${element.name}'. "
        'Run "dart run cloneable" to generate inline code.',
      );
      return '';
    }

    SomeParsedLibraryResult? parsedLibResult;
    try {
      parsedLibResult =
          element.session?.getParsedLibraryByElement(element.library);
    } catch (_) {
      // getParsedLibraryByElement can throw InconsistentAnalysisException during builds
    }

    final isFirst = _isFirstActiveCloneableClass(element);
    return generateForClass(
      element: element,
      annotation: annotation,
      inputFileName: buildStep.inputId.pathSegments.last,
      inputFilePath: buildStep.inputId.path,
      isInline: false,
      includeHeader: isFirst,
      parsedLibResult: parsedLibResult,
      defaultPrefix: defaultPrefix,
      defaultSuffix: defaultSuffix,
      resolvedDefaults: resolvedDefaults,
    );
  }

  bool _isFirstActiveCloneableClass(ClassElement element) {
    final resolvedDefaults = ConfigLoader.resolveDefaults(
      library: element.library,
    );
    for (final topCls in element.library.classes) {
      if (topCls == element) {
        return true;
      }
      ConstantReader? annotation;
      if (_cloneableTypeChecker.firstAnnotationOf(topCls) case final obj?) {
        annotation = ConstantReader(obj);
      } else {
        for (final meta in topCls.metadata.annotations) {
          if (meta.computeConstantValue() case final val?
              when val.type?.element?.name == 'Cloneable') {
            annotation = ConstantReader(val);
            break;
          }
        }
      }
      if (annotation != null) {
        final astConfig = _findClassCloneableAst(topCls, null);
        final rawActiveness = annotation.peek('activeness') != null
            ? switch (annotation
                .peek('activeness')!
                .objectValue
                .getField('index')
                ?.toIntValue()) {
                final index?
                    when index >= 0 &&
                        index < CloneableActiveness.values.length =>
                  CloneableActiveness.values[index],
                _ => null,
              }
            : astConfig?.activeness;
        final rawActive =
            annotation.peek('active')?.boolValue ?? astConfig?.active;
        final bool isActive;
        if (rawActiveness == CloneableActiveness.forceActive) {
          isActive = true;
        } else if (rawActiveness == CloneableActiveness.forceInactive) {
          isActive = false;
        } else if (resolvedDefaults.activeness ==
            CloneableActiveness.forceInactive) {
          isActive = false;
        } else if (rawActiveness != null) {
          isActive = rawActiveness.isActive;
        } else if (rawActive != null) {
          isActive = rawActive;
        } else {
          isActive = resolvedDefaults.active;
        }

        final output = switch (annotation
            .peek('output')
            ?.objectValue
            .getField('index')
            ?.toIntValue()) {
          final index?
              when index >= 0 && index < CloneableOutput.values.length =>
            CloneableOutput.values[index],
          _ => astConfig?.output ?? resolvedDefaults.output,
        };
        if (isActive && !output.isInline) {
          return false;
        }
      }
    }
    return true;
  }

  /// Generates the cloneable code for a single annotated class element.
  ///
  /// Can be used by both [CloneableGenerator] (during build_runner) and
  /// `CloneableGeneratorRunner` (during standalone in-file code generation).
  String generateForClass({
    required ClassElement element,
    required ConstantReader annotation,
    required String inputFileName,
    String? inputFilePath,
    String? sourceCode,
    bool isInline = false,
    bool includeHeader = true,
    SomeParsedLibraryResult? parsedLibResult,
    String? defaultPrefix,
    String? defaultSuffix,
    ResolvedCloneableConfig? resolvedDefaults,
    bool hasPartDirectiveOverride = false,
    bool hasMixinOverride = false,
    Set<String>? declaredSentinels,
  }) {
    resolvedDefaults ??= ConfigLoader.resolveDefaults(
      library: element.library,
      searchDirectory: inputFilePath != null ? p.dirname(inputFilePath) : null,
    );

    final astConfig = _findClassCloneableAst(element, parsedLibResult);

    final rawActiveness = annotation.peek('activeness') != null
        ? switch (annotation
            .peek('activeness')!
            .objectValue
            .getField('index')
            ?.toIntValue()) {
            final index?
                when index >= 0 && index < CloneableActiveness.values.length =>
              CloneableActiveness.values[index],
            _ => null,
          }
        : astConfig?.activeness;

    final rawActive = annotation.peek('active')?.boolValue ?? astConfig?.active;

    final bool isActive;
    if (rawActiveness == CloneableActiveness.forceActive) {
      isActive = true;
    } else if (rawActiveness == CloneableActiveness.forceInactive) {
      isActive = false;
    } else if (resolvedDefaults.activeness ==
        CloneableActiveness.forceInactive) {
      isActive = false;
    } else if (rawActiveness != null) {
      isActive = rawActiveness.isActive;
    } else if (rawActive != null) {
      isActive = rawActive;
    } else {
      isActive = resolvedDefaults.active;
    }

    if (!isActive) {
      return '';
    }

    final output = switch (annotation
        .peek('output')
        ?.objectValue
        .getField('index')
        ?.toIntValue()) {
      final index? when index >= 0 && index < CloneableOutput.values.length =>
        CloneableOutput.values[index],
      _ => astConfig?.output ?? resolvedDefaults.output,
    };

    final effectiveIsInline = isInline || output.isInline;

    if (element.isAbstract) {
      throw InvalidGenerationSourceError(
        'The @Cloneable() annotation cannot be applied to abstract classes.',
        element: element,
      );
    }

    // Resolve copy method name
    final namingReader = annotation.peek('naming');
    final rawMethod = namingReader?.peek('method')?.stringValue ??
        annotation.peek('method')?.stringValue ??
        annotation.peek('methodName')?.stringValue;
    final methodName =
        (rawMethod != null && rawMethod != CloneableNaming.defaultMethod)
            ? rawMethod
            : (astConfig?.method ?? resolvedDefaults.method);

    final capitalizedMethod = switch (methodName) {
      '' => '',
      final m => '${m[0].toUpperCase()}${m.substring(1)}',
    };

    (String prefix, String suffix) readAffix(
      String fieldName, {
      required CloneableAffix defaultAffix,
      CloneableAffix? constantDefaultAffix,
    }) {
      final affixReader = namingReader?.peek(fieldName);
      final rawP = affixReader?.peek('prefix')?.stringValue;
      final rawS = affixReader?.peek('suffix')?.stringValue;
      final isDefault = affixReader != null &&
          constantDefaultAffix != null &&
          rawP == constantDefaultAffix.prefix &&
          rawS == constantDefaultAffix.suffix;
      final p =
          (rawP != null && !isDefault) ? rawP : (defaultAffix.prefix ?? '');
      final s =
          (rawS != null && !isDefault) ? rawS : (defaultAffix.suffix ?? '');
      return (p, s);
    }

    final baseName = inputFileName.replaceAll(RegExp(r'\.dart$'), '');

    final (rawFilePrefix, rawFileSuffix) = readAffix(
      'file',
      defaultAffix: resolvedDefaults.file,
      constantDefaultAffix: CloneableNaming.defaultFile,
    );
    final cleanFileSuffix =
        rawFileSuffix.endsWith('.dart') ? rawFileSuffix : '$rawFileSuffix.dart';
    final customTargetFileName = '$rawFilePrefix$baseName$cleanFileSuffix';
    final customDir = namingReader?.peek('directory')?.stringValue ??
        astConfig?.directory ??
        resolvedDefaults.directory;
    final customDirClean =
        customDir?.replaceAll('\\', '/').replaceAll(RegExp(r'^/|/$'), '');

    final candidatePartNames = [
      '$baseName.g.dart',
      '${baseName}_cloneable.g.dart',
      '$baseName.cloneable.g.dart',
      '${baseName}_${CloneableNaming.defaultMethod}.g.dart',
      '$baseName.${CloneableNaming.defaultMethod}.g.dart',
      '$baseName.cloneable.dart',
      customTargetFileName,
      if (customDirClean != null) ...[
        '$customDirClean/$customTargetFileName',
        '$customDirClean/$baseName.cloneable.g.dart',
        '$customDirClean/$baseName.g.dart',
      ],
      if (methodName != CloneableNaming.defaultMethod)
        '${baseName}_$methodName.g.dart',
      if (methodName != CloneableNaming.defaultMethod)
        '$baseName.$methodName.g.dart',
      if (methodName != CloneableNaming.defaultMethod)
        '${baseName}_$capitalizedMethod.g.dart',
    ];

    String? matchedPartDirective;
    if (!effectiveIsInline) {
      final library = element.library;
      for (final part in library.firstFragment.partIncludes) {
        final partStr = part.uri.toString();
        for (final candidate in candidatePartNames) {
          if (partStr.endsWith(candidate) || partStr.contains(candidate)) {
            matchedPartDirective = candidate;
            break;
          }
        }
        if (matchedPartDirective != null) break;
      }

      if (matchedPartDirective == null) {
        if (parsedLibResult case ParsedLibraryResult parsedLib) {
          for (final unit in parsedLib.units) {
            for (final directive in unit.unit.directives) {
              if (directive case PartDirective(:final uri)
                  when uri.stringValue != null) {
                final uriStr = uri.stringValue!;
                for (final candidate in candidatePartNames) {
                  if (uriStr == candidate || uriStr.endsWith('/$candidate')) {
                    matchedPartDirective = candidate;
                    break;
                  }
                }
                if (matchedPartDirective != null) break;
              }
            }
            if (matchedPartDirective != null) break;
          }
        }
      }

      if (matchedPartDirective == null) {
        final source =
            sourceCode ?? element.library.firstFragment.source.contents.data;
        for (final candidate in candidatePartNames) {
          if (source.contains("part '$candidate';") ||
              source.contains('part "$candidate";')) {
            matchedPartDirective = candidate;
            break;
          }
        }
      }
    }

    final bool hasPartDirective =
        hasPartDirectiveOverride || matchedPartDirective != null;

    if (output == CloneableOutput.part &&
        !hasPartDirective &&
        !effectiveIsInline) {
      throw InvalidGenerationSourceError(
        "Class '${element.name}' is configured with CloneableOutput.part, which requires a part directive.\n"
        "Please add a part directive to '${inputFilePath ?? inputFileName}', for example:\n"
        "    part '$baseName.g.dart';\n"
        "    part '$customTargetFileName';\n",
        element: element,
      );
    }

    // Approach-specific overrides (inLibrary, inClass, part, standalone)
    final approachAffix = switch (output) {
      CloneableOutput.inLibrary => namingReader?.peek('inLibrary'),
      CloneableOutput.inClass => namingReader?.peek('inClass'),
      CloneableOutput.part => namingReader?.peek('part'),
      CloneableOutput.standalone => namingReader?.peek('standalone'),
      CloneableOutput.auto => effectiveIsInline
          ? namingReader?.peek('inLibrary')
          : (hasPartDirective
              ? namingReader?.peek('part')
              : namingReader?.peek('standalone')),
    };

    final defaultApproachAffix = switch (output) {
      CloneableOutput.inLibrary =>
        astConfig?.inLibrary ?? resolvedDefaults.inLibrary,
      CloneableOutput.inClass => astConfig?.inClass ?? resolvedDefaults.inClass,
      CloneableOutput.part => astConfig?.part ?? resolvedDefaults.part,
      CloneableOutput.standalone =>
        astConfig?.standalone ?? resolvedDefaults.standalone,
      CloneableOutput.auto => effectiveIsInline
          ? (astConfig?.inLibrary ?? resolvedDefaults.inLibrary)
          : (hasPartDirective
              ? (astConfig?.part ?? resolvedDefaults.part)
              : (astConfig?.standalone ?? resolvedDefaults.standalone)),
    };

    final approachPrefix = approachAffix?.peek('prefix')?.stringValue ??
        defaultApproachAffix?.prefix;
    final approachSuffix = approachAffix?.peek('suffix')?.stringValue ??
        defaultApproachAffix?.suffix;

    final cliPrefix = defaultPrefix ?? this.defaultPrefix;
    final cliSuffix = defaultSuffix ?? this.defaultSuffix;

    final defaultMixin = ResolvedCloneableConfig.mergeAffix(
      resolvedDefaults.mixin,
      astConfig?.mixin,
    );
    final defaultExtension = ResolvedCloneableConfig.mergeAffix(
      resolvedDefaults.extension,
      astConfig?.extension,
    );

    // Qualifiers from approach or CLI
    final prefixQualifier = approachPrefix ?? cliPrefix;
    final suffixQualifier = approachSuffix ?? cliSuffix;

    // Mixin:
    final mixinReader = namingReader?.peek('mixin');
    final rawMixinPrefix = mixinReader?.peek('prefix')?.stringValue;
    final rawMixinSuffix = mixinReader?.peek('suffix')?.stringValue;
    final defaultMixinPrefix = defaultMixin.prefix ?? '';
    final defaultMixinSuffix = defaultMixin.suffix ?? '';

    final isDefaultMixin = mixinReader != null &&
        rawMixinPrefix == CloneableNaming.defaultMixin.prefix &&
        rawMixinSuffix == CloneableNaming.defaultMixin.suffix;

    final effectiveMixinPrefix = isDefaultMixin
        ? (prefixQualifier ?? defaultMixinPrefix)
        : switch (rawMixinPrefix) {
            '' => '',
            final p? => p,
            _ => prefixQualifier ?? defaultMixinPrefix,
          };
    final effectiveMixinSuffix = isDefaultMixin
        ? (suffixQualifier ?? defaultMixinSuffix)
        : switch (rawMixinSuffix) {
            '' => '',
            final s? => s,
            _ => suffixQualifier ?? defaultMixinSuffix,
          };

    // Extension:
    final extensionReader = namingReader?.peek('extension');
    final rawExtensionPrefix = extensionReader?.peek('prefix')?.stringValue;
    final rawExtensionSuffix = extensionReader?.peek('suffix')?.stringValue;
    final defaultExtensionPrefix = defaultExtension.prefix ?? '';
    final defaultExtensionSuffix = defaultExtension.suffix ?? '';
    final qualifiedExtensionSuffix = switch (suffixQualifier) {
      final s? when s.isNotEmpty =>
        s.endsWith(defaultExtensionSuffix) ? s : '$s$defaultExtensionSuffix',
      _ => defaultExtensionSuffix,
    };

    final isDefaultExtension = extensionReader != null &&
        rawExtensionPrefix == CloneableNaming.defaultExtension.prefix &&
        rawExtensionSuffix == CloneableNaming.defaultExtension.suffix;

    var effectiveExtensionPrefix = isDefaultExtension
        ? (prefixQualifier ?? defaultExtensionPrefix)
        : switch (rawExtensionPrefix) {
            '' => '',
            final p? => p,
            _ => prefixQualifier ?? defaultExtensionPrefix,
          };
    final effectiveExtensionSuffix = isDefaultExtension
        ? (rawExtensionSuffix ?? qualifiedExtensionSuffix)
        : switch (rawExtensionSuffix) {
            '' => '',
            final s? => s,
            _ => qualifiedExtensionSuffix,
          };

    // Verify mixin (candidate names excluding short _$ClassName)
    final defaultCapitalizedMethod =
        '${CloneableNaming.defaultMethod[0].toUpperCase()}${CloneableNaming.defaultMethod.substring(1)}';

    final prefixScoped =
        '$effectiveMixinPrefix${element.name}$effectiveMixinSuffix';
    final prefixCapability =
        '$effectiveMixinPrefix${element.name}$capitalizedMethod';
    final prefixDefaultCapability =
        '$effectiveMixinPrefix${element.name}$defaultCapitalizedMethod';

    final candidateMixinNames = <String>{
      prefixScoped,
      prefixCapability,
      if (methodName != CloneableNaming.defaultMethod) prefixDefaultCapability,
      if (effectiveMixinPrefix.isNotEmpty &&
          !effectiveMixinPrefix.startsWith('_')) ...[
        '_$effectiveMixinPrefix${element.name}$effectiveMixinSuffix',
        '_\$$effectiveMixinPrefix${element.name}$effectiveMixinSuffix',
        '_$effectiveMixinPrefix${element.name}$capitalizedMethod',
        '_\$$effectiveMixinPrefix${element.name}$capitalizedMethod',
        if (methodName != CloneableNaming.defaultMethod) ...[
          '_$effectiveMixinPrefix${element.name}$defaultCapitalizedMethod',
          '_\$$effectiveMixinPrefix${element.name}$defaultCapitalizedMethod',
        ],
      ],
      '_\$${element.name}$effectiveMixinSuffix',
      if (effectiveMixinSuffix.isEmpty) '_\$${element.name}',
      '_\$${element.name}Cloneable',
      '_\$${element.name}$capitalizedMethod',
      if (methodName != CloneableNaming.defaultMethod)
        '_\$${element.name}$defaultCapitalizedMethod',
      if (effectiveMixinPrefix == '') ...[
        '${element.name}$effectiveMixinSuffix',
        if (effectiveMixinSuffix.isEmpty) element.name!,
        '${element.name}Cloneable',
        '${element.name}$capitalizedMethod',
      ],
    }.toList();

    String? detectedMixinName;

    // 1. Check AST node if available
    final classDecl = _findClassDeclaration(
      element: element,
      parsedLibResult: parsedLibResult,
    );

    if (classDecl != null && classDecl.withClause != null) {
      for (final mixinType in classDecl.withClause!.mixinTypes) {
        final name = mixinType.typeName;
        if (candidateMixinNames.contains(name)) {
          detectedMixinName = name;
          break;
        }
      }
    }

    // 2. Check element.mixins
    if (detectedMixinName == null) {
      for (final candidate in candidateMixinNames) {
        if (element.mixins.any((m) =>
            m.element.name == candidate ||
            m.getDisplayString().startsWith(candidate))) {
          detectedMixinName = candidate;
          break;
        }
      }
    }

    // 3. Fallback to source inspection
    if (detectedMixinName == null) {
      final source =
          sourceCode ?? element.library.firstFragment.source.contents.data;
      for (final candidate in candidateMixinNames) {
        final pattern =
            RegExp(r'\bwith\b[^;{]*\b' + RegExp.escape(candidate) + r'\b');
        if (pattern.hasMatch(source)) {
          detectedMixinName = candidate;
          break;
        }
      }
    }

    final bool hasMixin = hasMixinOverride || detectedMixinName != null;
    if (detectedMixinName == null && hasMixinOverride) {
      detectedMixinName = prefixScoped;
    }

    // Strategy configuration
    final strategy = switch (annotation
        .peek('strategy')
        ?.objectValue
        .getField('index')
        ?.toIntValue()) {
      final index? when index >= 0 && index < CloneableStrategy.values.length =>
        CloneableStrategy.values[index],
      _ => astConfig?.strategy ?? resolvedDefaults.strategy,
    };

    final useExtension = switch (strategy) {
      CloneableStrategy.mixin when !hasPartDirective && !effectiveIsInline =>
        throw InvalidGenerationSourceError(
          "Class '${element.name}' is configured with CloneableStrategy.mixin, which requires a part directive.\n"
          "Please add a part directive to '${inputFilePath ?? inputFileName}', for example:\n"
          "    part '$baseName.g.dart';\n"
          "    part '${baseName}_cloneable.g.dart';\n"
          "    part '${baseName}_copyWith.g.dart';\n"
          "Or use CloneableStrategy.auto / CloneableStrategy.extension to generate standalone extensions without a part directive.",
          element: element,
        ),
      CloneableStrategy.mixin when !hasMixin =>
        throw InvalidGenerationSourceError(
          "Class '${element.name}' is configured with CloneableStrategy.mixin but does not mix in any supported mixin.\n"
          "Please add one of the following to your class declaration:\n"
          "    class ${element.name} with $prefixScoped { ... }  (Scoped style)\n"
          "    class ${element.name} with $prefixCapability { ... }   (Capability style)\n"
          "Or use CloneableStrategy.extension / CloneableStrategy.auto to generate an extension without the mixin.",
          element: element,
        ),
      CloneableStrategy.mixin => false,
      CloneableStrategy.extension => true,
      CloneableStrategy.auto =>
        effectiveIsInline ? !hasMixin : (!hasMixin || !hasPartDirective),
    };

    // Sentinel configuration
    final sentinelStrategy = switch (annotation
        .peek('sentinel')
        ?.objectValue
        .getField('index')
        ?.toIntValue()) {
      final index? when index >= 0 && index < CloneableSentinel.values.length =>
        CloneableSentinel.values[index],
      _ => astConfig?.sentinel ?? resolvedDefaults.sentinel,
    };

    final rawSentinel = namingReader?.peek('sentinel')?.stringValue;
    final customSentinel =
        (rawSentinel != null && rawSentinel != CloneableNaming.defaultSentinel)
            ? rawSentinel
            : (astConfig?.sentinelName ?? resolvedDefaults.sentinelName);

    final importPrefix = _findCloneableImportPrefix(element);

    final shouldEmitTopLevelSentinel = output != CloneableOutput.inClass &&
        (declaredSentinels == null ||
            !declaredSentinels.contains(customSentinel));

    final (sentinelExpr, sentinelDeclaration) = switch (sentinelStrategy) {
      CloneableSentinel.private => (
          customSentinel,
          output == CloneableOutput.inClass
              ? '  static const $customSentinel = Object();\n\n'
              : (shouldEmitTopLevelSentinel
                  ? 'const $customSentinel = Object();\n\n'
                  : ''),
        ),
      CloneableSentinel.package => () {
          if (importPrefix != null) {
            return ('$importPrefix.\$undefined', '');
          }
          final sourceData = element.library.firstFragment.source.contents.data;
          final hasCloneableUndefined =
              sourceData.contains('cloneableUndefined') &&
                  !sourceData.contains(r'$undefined');
          if (hasCloneableUndefined) {
            return ('cloneableUndefined', '');
          }
          return (r'$undefined', '');
        }(),
      CloneableSentinel.auto => () {
          if (output == CloneableOutput.inClass) {
            return (
              customSentinel,
              '  static const $customSentinel = Object();\n\n',
            );
          }
          if (importPrefix != null) {
            return ('$importPrefix.\$undefined', '');
          }

          var importsPackageCloneable = false;
          var showsCloneableUndefined = false;
          var hidesUndefined = false;

          for (final imp in element.library.firstFragment.libraryImports) {
            final uri =
                imp.importedLibrary?.firstFragment.source.uri.toString() ??
                    imp.uri.toString();
            if (uri == 'package:cloneable/cloneable.dart' ||
                uri == 'package:cloneable/src/annotations.dart') {
              importsPackageCloneable = true;
              for (final comb in imp.combinators) {
                if (comb is ShowElementCombinator) {
                  if (comb.shownNames.contains('cloneableUndefined') &&
                      !comb.shownNames.contains(r'$undefined')) {
                    showsCloneableUndefined = true;
                  }
                } else if (comb is HideElementCombinator) {
                  if (comb.hiddenNames.contains(r'$undefined')) {
                    hidesUndefined = true;
                  }
                }
              }
            }
          }

          final sourceData = element.library.firstFragment.source.contents.data;
          final hasCloneableUndefined =
              sourceData.contains('cloneableUndefined') &&
                  !sourceData.contains(r'$undefined');
          if (hasCloneableUndefined) {
            return ('cloneableUndefined', '');
          }

          if (!importsPackageCloneable) {
            if (sourceData.contains('package:cloneable/cloneable.dart') ||
                sourceData.contains('package:cloneable/src/annotations.dart')) {
              importsPackageCloneable = true;
            }
          }

          if (importsPackageCloneable && !hidesUndefined) {
            if (showsCloneableUndefined) {
              return ('cloneableUndefined', '');
            }
            return (r'$undefined', '');
          }

          return (
            customSentinel,
            shouldEmitTopLevelSentinel
                ? 'const $customSentinel = Object();\n\n'
                : '',
          );
        }(),
    };

    if (shouldEmitTopLevelSentinel && sentinelDeclaration.isNotEmpty) {
      declaredSentinels?.add(customSentinel);
    }

    // Class-level configuration
    final constructorName =
        annotation.peek('constructor')?.stringValue ?? astConfig?.constructor;
    final classDeepCopy = annotation.peek('deepCopyCollections')?.boolValue ??
        astConfig?.deepCopyCollections ??
        resolvedDefaults.deepCopyCollections;
    final classIgnoreNull = annotation.peek('ignoreNull')?.boolValue ??
        astConfig?.ignoreNull ??
        resolvedDefaults.ignoreNull;

    // Resolve constructor
    final constructor = switch (constructorName) {
      null || '' => element.unnamedConstructor ??
          (throw InvalidGenerationSourceError(
            "Class '${element.name}' does not have an unnamed constructor.",
            element: element,
          )),
      final name => element.getNamedConstructor(name) ??
          (throw InvalidGenerationSourceError(
            "Class '${element.name}' does not have a constructor named '$name'.",
            element: element,
          )),
    };

    final isSeparateLibrary = output == CloneableOutput.standalone ||
        (!hasPartDirective && !effectiveIsInline);

    if (isSeparateLibrary) {
      if ((element.name ?? '').startsWith('_')) {
        throw InvalidGenerationSourceError(
          "Class '${element.name}' is private. Dart does not allow accessing private classes from standalone generated libraries.\n"
          "To generate copyWith for private classes, use 'CloneableOutput.part' with a part directive, or 'CloneableOutput.inLibrary' / 'CloneableOutput.inClass'.",
          element: element,
        );
      }
      final cName = constructor.name ?? '';
      if (cName.startsWith('_')) {
        throw InvalidGenerationSourceError(
          "Constructor '$cName' of class '${element.name}' is private. Standalone generated libraries cannot access private constructors across library boundaries.\n"
          "Use a public constructor, or switch to 'CloneableOutput.part' / 'CloneableOutput.inClass'.",
          element: element,
        );
      }

      // Standalone extensions on public classes must be public
      if (!(element.name ?? '').startsWith('_') &&
          effectiveExtensionPrefix.startsWith('_')) {
        effectiveExtensionPrefix =
            effectiveExtensionPrefix.replaceFirst(RegExp(r'^_+'), r'$');
        if (effectiveExtensionPrefix.isEmpty) {
          effectiveExtensionPrefix = r'$';
        }
      }
    }

    // Generic type parameters
    final (typeParamsWithBounds, typeParamsArgs) =
        switch (element.typeParameters) {
      [] => ('', ''),
      final params => (
          '<${params.map((p) => p.bound != null ? '${p.name} extends ${p.bound!.getDisplayString()}' : p.name).join(', ')}>',
          '<${params.map((p) => p.name).join(', ')}>',
        ),
    };

    // Resolve fields whitelist
    final annotationFields = switch (annotation.peek('fields')?.listValue) {
      null => astConfig?.fields,
      final list =>
        list.map((item) => item.toStringValue()).whereType<String>().toList(),
    };

    final customGetter =
        annotation.peek('cloneableFieldsGetter')?.stringValue ??
            astConfig?.cloneableFieldsGetter;

    final inClassResult = _findInClassFields(
      element: element,
      constructor: constructor,
      classDecl: classDecl,
      customGetter: customGetter,
      methodName: methodName,
    );

    final fieldsConflict = switch (annotation
        .peek('fieldsConflict')
        ?.objectValue
        .getField('index')
        ?.toIntValue()) {
      final index?
          when index >= 0 && index < CloneableFieldsConflict.values.length =>
        CloneableFieldsConflict.values[index],
      _ => astConfig?.fieldsConflict ?? resolvedDefaults.fieldsConflict,
    };

    final List<String>? allowedFields;
    final String? whitelistSource;

    if (annotationFields != null && inClassResult != null) {
      switch (fieldsConflict) {
        case CloneableFieldsConflict.error:
          throw InvalidGenerationSourceError(
            "Fields cannot be specified in both @Cloneable(fields: ...) and the '${inClassResult.getterName}' getter in class '${element.name}'.\n"
            "To resolve this conflict, configure `fieldsConflict`:\n"
            "  - CloneableFieldsConflict.merge (union of both field lists)\n"
            "  - CloneableFieldsConflict.inClass (prefer in-class getter)\n"
            "  - CloneableFieldsConflict.inAnnotation (prefer annotation list)",
            element: element,
          );
        case CloneableFieldsConflict.merge:
          allowedFields = {
            ...annotationFields,
            ...inClassResult.fields,
          }.toList();
          whitelistSource =
              "@Cloneable(fields: ...) and in-class '${inClassResult.getterName}'";
        case CloneableFieldsConflict.inClass:
          allowedFields = inClassResult.fields;
          whitelistSource = inClassResult.getterName;
        case CloneableFieldsConflict.inAnnotation:
          allowedFields = annotationFields;
          whitelistSource = '@Cloneable(fields: ...)';
      }
    } else {
      allowedFields = annotationFields ?? inClassResult?.fields;
      whitelistSource = annotationFields != null
          ? '@Cloneable(fields: ...)'
          : inClassResult?.getterName;
    }

    if (allowedFields != null && allowedFields.isEmpty) {
      return '';
    }

    if (allowedFields != null) {
      final constructorParamNames = constructor.formalParameters
          .map((FormalParameterElement p) => p.name)
          .toSet();
      for (final fieldName in allowedFields) {
        if (!constructorParamNames.contains(fieldName)) {
          throw InvalidGenerationSourceError(
            "Field '$fieldName' in '$whitelistSource' does not match any constructor parameter in class '${element.name}'.",
            element: element,
          );
        }
      }
    }

    // Process parameters
    final params = <_FieldInfo>[];
    for (final param in constructor.formalParameters) {
      final paramName = param.name!;
      final field = element.getField(paramName) ??
          element.getGetter(paramName)?.variable ??
          (throw InvalidGenerationSourceError(
            "Constructor parameter '$paramName' does not match any field or getter in class '${element.name}'.",
            element: param,
          ));

      if (isSeparateLibrary && paramName.startsWith('_')) {
        throw InvalidGenerationSourceError(
          "Constructor parameter '$paramName' in class '${element.name}' is private. Standalone generated libraries cannot access private fields across library boundaries.\n"
          "Make the field public, or switch to 'CloneableOutput.part' / 'CloneableOutput.inClass'.",
          element: param,
        );
      }

      final isWhitelisted =
          allowedFields == null || allowedFields.contains(paramName);
      final isIgnored = !isWhitelisted || _isFieldIgnored(param, field);
      final fieldDeepCopy = _getFieldDeepCopy(param, field);
      final fieldCloner = _getFieldCloner(param, field, classDecl: classDecl);
      final shouldDeepCopy =
          fieldDeepCopy ?? (fieldCloner != null ? true : classDeepCopy);
      final fieldIgnoreNull = _getFieldIgnoreNull(param, field);
      final shouldIgnoreNull = fieldIgnoreNull ?? classIgnoreNull;
      final collectionKind = _getCollectionKind(param.type);

      if (isSeparateLibrary && fieldCloner != null) {
        if (fieldCloner.startsWith('_') || fieldCloner.contains('._')) {
          throw InvalidGenerationSourceError(
            "Cloner function '$fieldCloner' on field '$paramName' of class '${element.name}' is private. Standalone generated libraries cannot access private cloner functions across library boundaries.\n"
            "Use a public cloner function, or switch to 'CloneableOutput.part' / 'CloneableOutput.inClass'.",
            element: element,
          );
        }
      }

      final resolvedType = _resolveFieldType(
        param: param,
        field: field,
        classDecl: classDecl,
        constructorName: constructorName,
      );

      final isNullable =
          param.type.nullabilitySuffix == NullabilitySuffix.question ||
              param.type is DynamicType ||
              param.type.isDartCoreNull ||
              resolvedType.endsWith('?');

      params.add(
        _FieldInfo(
          name: paramName,
          type: resolvedType,
          isNullable: isNullable,
          isNamed: param.isNamed,
          isRequired: param.isRequiredNamed || param.isRequiredPositional,
          isIgnored: isIgnored,
          shouldDeepCopy: shouldDeepCopy,
          shouldIgnoreNull: shouldIgnoreNull,
          collectionKind: collectionKind,
          cloner: fieldCloner,
        ),
      );
    }

    final fileImports = _extractFileImports(
      classDecl: classDecl,
      parsedLibResult: parsedLibResult,
      element: element,
      inputFileName: inputFileName,
    );

    final extensionName =
        '$effectiveExtensionPrefix${element.name}$effectiveExtensionSuffix';
    final resolvedMixinName = detectedMixinName ?? prefixScoped;

    return _generateCode(
      className: element.name!,
      constructorName: constructorName,
      typeParamsWithBounds: typeParamsWithBounds,
      typeParamsArgs: typeParamsArgs,
      fields: params,
      useExtension: useExtension,
      mixinName: resolvedMixinName,
      extensionName: extensionName,
      methodName: methodName,
      hasPartDirective: hasPartDirective,
      inputFileName: inputFileName,
      sentinelExpr: sentinelExpr,
      sentinelDeclaration: sentinelDeclaration,
      isInline: effectiveIsInline,
      includeHeader: includeHeader,
      fileImports: fileImports,
      output: output,
      sentinelStrategy: sentinelStrategy,
    );
  }

  /// Generates the class members for [CloneableOutput.inClass]:
  /// (sentinel, getter, and private copy method).
  String generateInClassMembers({
    required ClassElement element,
    required ConstantReader annotation,
    required String inputFileName,
    String? inputFilePath,
    String? sourceCode,
    SomeParsedLibraryResult? parsedLibResult,
    String? defaultPrefix,
    String? defaultSuffix,
    ResolvedCloneableConfig? resolvedDefaults,
  }) {
    final fullCode = generateForClass(
      element: element,
      annotation: annotation,
      inputFileName: inputFileName,
      inputFilePath: inputFilePath,
      sourceCode: sourceCode,
      isInline: true,
      includeHeader: false,
      parsedLibResult: parsedLibResult,
      defaultPrefix: defaultPrefix,
      defaultSuffix: defaultSuffix,
      resolvedDefaults: resolvedDefaults,
    );

    return fullCode.trim();
  }

  String? _findCloneableImportPrefix(ClassElement element) {
    for (final import in element.library.firstFragment.libraryImports) {
      final uri = import.importedLibrary?.firstFragment.source.uri.toString() ??
          import.uri.toString();
      if (uri == 'package:cloneable/cloneable.dart' ||
          uri == 'package:cloneable/src/annotations.dart') {
        final prefix = import.prefix?.element.name;
        if (prefix != null && prefix.isNotEmpty) {
          return prefix;
        }
      }
    }
    return null;
  }

  ConstantReader? _getFieldAnnotationReader(
      FormalParameterElement param, Element field) {
    if (_fieldAnnotationTypeChecker.firstAnnotationOf(param) case final obj?) {
      return ConstantReader(obj);
    }
    if (_fieldAnnotationTypeChecker.firstAnnotationOf(field) case final obj?) {
      return ConstantReader(obj);
    }

    // Fallback by element name for test environments / mock elements
    for (final meta in [
      ...param.metadata.annotations,
      ...field.metadata.annotations,
    ]) {
      if (meta.computeConstantValue() case final val?
          when val.type?.element?.name == 'CloneableField') {
        return ConstantReader(val);
      }
    }
    return null;
  }

  bool _isFieldIgnored(FormalParameterElement param, Element field) =>
      _getFieldAnnotationReader(param, field)?.peek('ignore')?.boolValue ==
      true;

  bool? _getFieldDeepCopy(FormalParameterElement param, Element field) =>
      _getFieldAnnotationReader(param, field)?.peek('deepCopy')?.boolValue;

  bool? _getFieldIgnoreNull(FormalParameterElement param, Element field) =>
      _getFieldAnnotationReader(param, field)?.peek('ignoreNull')?.boolValue;

  String? _getFieldCloner(
    FormalParameterElement param,
    Element field, {
    ClassDeclaration? classDecl,
  }) {
    if (classDecl != null) {
      for (final member in classDecl.members) {
        if (member is FieldDeclaration) {
          for (final variable in member.fields.variables) {
            if (variable.name.lexeme == param.name ||
                variable.name.lexeme == field.name) {
              for (final metadata in member.metadata) {
                final annName = metadata.name.toSource();
                if (annName == 'CloneableField' ||
                    annName.endsWith('.CloneableField')) {
                  final args = metadata.arguments?.arguments;
                  if (args != null) {
                    for (final arg in args) {
                      final (name, expr) = AstConfigReader.getArgumentInfo(arg);
                      if (name == 'cloner' && expr != null) {
                        return expr.toSource();
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    final reader = _getFieldAnnotationReader(param, field);
    if (reader != null) {
      final clonerField = reader.peek('cloner');
      if (clonerField != null && !clonerField.isNull) {
        final func = clonerField.objectValue.toFunctionValue();
        if (func != null) {
          final enclosing = func.enclosingElement;
          if (enclosing is ClassElement) {
            return '${enclosing.name}.${func.name}';
          }
          return func.name;
        }
      }
    }

    return null;
  }

  _CollectionKind _getCollectionKind(DartType type) {
    if (type.isDartCoreList || type.element?.name == 'List') {
      return _CollectionKind.list;
    }
    if (type.isDartCoreSet || type.element?.name == 'Set') {
      return _CollectionKind.set;
    }
    if (type.isDartCoreMap || type.element?.name == 'Map') {
      return _CollectionKind.map;
    }
    if (type.isDartCoreIterable || type.element?.name == 'Iterable') {
      return _CollectionKind.iterable;
    }

    final name =
        type.element?.name ?? type.getDisplayString().split('<').first.trim();

    return switch (name) {
      'Queue' => _CollectionKind.queue,
      'ListQueue' => _CollectionKind.listQueue,
      'DoubleLinkedQueue' => _CollectionKind.doubleLinkedQueue,
      'HashMap' => _CollectionKind.hashMap,
      'LinkedHashMap' => _CollectionKind.linkedHashMap,
      'SplayTreeMap' => _CollectionKind.splayTreeMap,
      'HashSet' => _CollectionKind.hashSet,
      'LinkedHashSet' => _CollectionKind.linkedHashSet,
      'SplayTreeSet' => _CollectionKind.splayTreeSet,
      'Uint8List' => _CollectionKind.uint8List,
      'Int8List' => _CollectionKind.int8List,
      'Uint8ClampedList' => _CollectionKind.uint8ClampedList,
      'Int16List' => _CollectionKind.int16List,
      'Uint16List' => _CollectionKind.uint16List,
      'Int32List' => _CollectionKind.int32List,
      'Uint32List' => _CollectionKind.uint32List,
      'Int64List' => _CollectionKind.int64List,
      'Uint64List' => _CollectionKind.uint64List,
      'Float32List' => _CollectionKind.float32List,
      'Float64List' => _CollectionKind.float64List,
      'Float32x4List' => _CollectionKind.float32x4List,
      'Int32x4List' => _CollectionKind.int32x4List,
      'Float64x2List' => _CollectionKind.float64x2List,
      'ByteData' => _CollectionKind.byteData,
      _ => _CollectionKind.none,
    };
  }

  String? _getBuiltInFactoryMethod(_CollectionKind kind) => switch (kind) {
        _CollectionKind.list || _CollectionKind.iterable => 'List.of',
        _CollectionKind.set => 'Set.of',
        _CollectionKind.map => 'Map.of',
        _CollectionKind.queue => 'Queue.of',
        _CollectionKind.listQueue => 'ListQueue.of',
        _CollectionKind.doubleLinkedQueue => 'DoubleLinkedQueue.of',
        _CollectionKind.hashMap => 'HashMap.of',
        _CollectionKind.linkedHashMap => 'LinkedHashMap.of',
        _CollectionKind.splayTreeMap => 'SplayTreeMap.of',
        _CollectionKind.hashSet => 'HashSet.of',
        _CollectionKind.linkedHashSet => 'LinkedHashSet.of',
        _CollectionKind.splayTreeSet => 'SplayTreeSet.of',
        _CollectionKind.uint8List => 'Uint8List.fromList',
        _CollectionKind.int8List => 'Int8List.fromList',
        _CollectionKind.uint8ClampedList => 'Uint8ClampedList.fromList',
        _CollectionKind.int16List => 'Int16List.fromList',
        _CollectionKind.uint16List => 'Uint16List.fromList',
        _CollectionKind.int32List => 'Int32List.fromList',
        _CollectionKind.uint32List => 'Uint32List.fromList',
        _CollectionKind.int64List => 'Int64List.fromList',
        _CollectionKind.uint64List => 'Uint64List.fromList',
        _CollectionKind.float32List => 'Float32List.fromList',
        _CollectionKind.float64List => 'Float64List.fromList',
        _CollectionKind.float32x4List => 'Float32x4List.fromList',
        _CollectionKind.int32x4List => 'Int32x4List.fromList',
        _CollectionKind.float64x2List => 'Float64x2List.fromList',
        _CollectionKind.byteData => 'ByteData.sublistView',
        _CollectionKind.none => null,
      };

  String _generateCode({
    required String className,
    required String? constructorName,
    required String typeParamsWithBounds,
    required String typeParamsArgs,
    required List<_FieldInfo> fields,
    required bool useExtension,
    required String mixinName,
    required String extensionName,
    required String methodName,
    required bool hasPartDirective,
    required String inputFileName,
    required String sentinelExpr,
    required String sentinelDeclaration,
    required bool isInline,
    required bool includeHeader,
    required List<String> fileImports,
    required CloneableOutput output,
    required CloneableSentinel sentinelStrategy,
  }) {
    final targetClassType = '$className$typeParamsArgs';
    final privateMethodName = '_$methodName';

    final needsTypedData = fields.any((f) =>
        (f.shouldDeepCopy && f.collectionKind.isTypedData) ||
        (f.cloner != null &&
            (f.cloner!.contains('Uint8List') ||
                f.cloner!.contains('ByteData') ||
                f.cloner!.contains('List')) &&
            f.collectionKind.isTypedData));
    final needsCollection = fields
        .any((f) => f.shouldDeepCopy && f.collectionKind.isCollectionLibrary);

    final standaloneHeader =
        switch (isInline || hasPartDirective || !includeHeader) {
      true => '',
      false => () {
          final buffer = StringBuffer();
          if (sentinelStrategy != CloneableSentinel.private) {
            buffer.writeln("import 'package:cloneable/cloneable.dart';");
          }
          if (needsTypedData &&
              !fileImports.any((i) =>
                  i.contains("'dart:typed_data'") ||
                  i.contains('"dart:typed_data"'))) {
            buffer.writeln("import 'dart:typed_data';");
          }
          if (needsCollection &&
              !fileImports.any((i) =>
                  i.contains("'dart:collection'") ||
                  i.contains('"dart:collection"'))) {
            buffer.writeln("import 'dart:collection';");
          }
          buffer.writeln("import '$inputFileName';");
          for (final imp in fileImports) {
            buffer.writeln(imp);
          }
          buffer.writeln();
          return buffer.toString();
        }(),
    };

    // Filter fields accepted in copyWith call (exclude ignored ones)
    final copyFields = fields.where((f) => !f.isIgnored).toList();

    // Generate function parameters
    final fnParamsBuffer = StringBuffer();
    for (final field in copyFields) {
      final paramType = field.shouldIgnoreNull && !field.isNullable
          ? '${field.type}?'
          : field.type;
      fnParamsBuffer.writeln('    $paramType ${field.name},');
    }

    // Generate mixin/extension/class private method parameters
    final callParamsBuffer = StringBuffer();
    for (final field in copyFields) {
      callParamsBuffer.writeln(
        '    Object? ${field.name} = $sentinelExpr,',
      );
    }

    // Generate constructor invocation arguments
    final constructorArgsBuffer = StringBuffer();
    final constructorCall = switch (constructorName) {
      null || '' => '$className$typeParamsArgs',
      final name => '$className$typeParamsArgs.$name',
    };

    final selfRef = output == CloneableOutput.inClass ? 'this' : 'self';

    for (final field in fields) {
      final valExpr = switch (field) {
        _ when field.isIgnored => '$selfRef.${field.name}',
        _
            when field.cloner != null ||
                (field.shouldDeepCopy &&
                    field.collectionKind != _CollectionKind.none) =>
          _generateDeepCopyExpression(
            field,
            sentinelExpr: sentinelExpr,
            selfRef: selfRef,
          ),
        _ when field.shouldIgnoreNull =>
          'identical(${field.name}, $sentinelExpr) || ${field.name} == null ? $selfRef.${field.name} : ${field.name} as ${field.type}',
        _ =>
          'identical(${field.name}, $sentinelExpr) ? $selfRef.${field.name} : ${field.name} as ${field.type}',
      };

      if (field.isNamed) {
        constructorArgsBuffer.writeln('      ${field.name}: $valExpr,');
      } else {
        constructorArgsBuffer.writeln('      $valExpr,');
      }
    }

    final getterReturnType = '$targetClassType Function({\n$fnParamsBuffer  })';

    final implementation = switch (output) {
      CloneableOutput.inClass => '''
$sentinelDeclaration  $getterReturnType get $methodName => $privateMethodName;

  $targetClassType $privateMethodName({
$callParamsBuffer  }) {
    return $constructorCall(
$constructorArgsBuffer    );
  }
''',
      _ => switch (useExtension) {
          true => '''
/// Generated cloneable extension for [$className].
extension $extensionName$typeParamsWithBounds on $targetClassType {
  $getterReturnType get $methodName => $privateMethodName;

  $targetClassType $privateMethodName({
$callParamsBuffer  }) {
    final self = this;
    return $constructorCall(
$constructorArgsBuffer    );
  }
}
''',
          false => '''
/// Generated cloneable mixin for [$className].
mixin $mixinName$typeParamsWithBounds {
  $getterReturnType get $methodName => $privateMethodName;

  $targetClassType $privateMethodName({
$callParamsBuffer  }) {
    final self = this as $targetClassType;
    return $constructorCall(
$constructorArgsBuffer    );
  }
}
''',
        },
    };

    if (output == CloneableOutput.inClass) {
      return implementation;
    }

    final topSentinel =
        output != CloneableOutput.inClass ? sentinelDeclaration : '';

    return '''
$standaloneHeader$topSentinel$implementation''';
  }

  String _generateDeepCopyExpression(
    _FieldInfo field, {
    required String sentinelExpr,
    String selfRef = 'self',
  }) {
    final name = field.name;
    final type = field.type;
    final nonNullableType =
        type.endsWith('?') ? type.substring(0, type.length - 1) : type;

    final String Function(String) cloneFn;
    if (field.cloner != null) {
      cloneFn = (expr) => '${field.cloner}($expr)';
    } else {
      final factoryMethod = _getBuiltInFactoryMethod(field.collectionKind);
      if (factoryMethod == null) {
        return 'identical($name, $sentinelExpr) ? $selfRef.$name : $name as $type';
      }
      cloneFn = (expr) => '$factoryMethod($expr)';
    }

    final cloneSelf = field.isNullable
        ? '($selfRef.$name == null ? null : ${cloneFn('$selfRef.$name!')})'
        : cloneFn('$selfRef.$name');

    final cloneArg = field.isNullable
        ? '($name == null ? null : ${cloneFn('$name as $nonNullableType')})'
        : cloneFn('$name as $type');

    return switch ((field.shouldIgnoreNull, field.isNullable)) {
      (true, _) => '''(identical($name, $sentinelExpr) || $name == null)
          ? $cloneSelf
          : $cloneArg''',
      (false, _) => '''identical($name, $sentinelExpr)
          ? $cloneSelf
          : $cloneArg''',
    };
  }

  ClassDeclaration? _findClassDeclaration({
    required ClassElement element,
    required SomeParsedLibraryResult? parsedLibResult,
  }) {
    if (parsedLibResult case ParsedLibraryResult parsedLib) {
      for (final u in parsedLib.units) {
        for (final decl in u.unit.declarations) {
          if (decl is ClassDeclaration && decl.className == element.name) {
            return decl;
          }
        }
      }
    }

    try {
      final parseResult = parseString(
        content: element.library.firstFragment.source.contents.data,
        throwIfDiagnostics: false,
      );
      for (final decl in parseResult.unit.declarations) {
        if (decl is ClassDeclaration && decl.className == element.name) {
          return decl;
        }
      }
    } catch (_) {
      // Fall back to null if parsing fails
    }

    return null;
  }

  List<String> _extractFileImports({
    required ClassDeclaration? classDecl,
    required SomeParsedLibraryResult? parsedLibResult,
    required ClassElement element,
    required String inputFileName,
  }) {
    final imports = <String>{};

    void collectFromUnit(CompilationUnit unit) {
      for (final directive in unit.directives) {
        if (directive is ImportDirective) {
          final uri = directive.uri.stringValue;
          if (uri != null &&
              uri != 'package:cloneable/cloneable.dart' &&
              uri != 'package:cloneable/src/annotations.dart' &&
              uri != inputFileName &&
              !uri.endsWith('/$inputFileName')) {
            imports.add(directive.toSource());
          }
        }
      }
    }

    if (parsedLibResult case ParsedLibraryResult parsedLib) {
      for (final unit in parsedLib.units) {
        collectFromUnit(unit.unit);
      }
    }

    if (imports.isEmpty && classDecl?.root is CompilationUnit) {
      collectFromUnit(classDecl!.root as CompilationUnit);
    }

    if (imports.isEmpty) {
      try {
        final parseResult = parseString(
          content: element.library.firstFragment.source.contents.data,
          throwIfDiagnostics: false,
        );
        collectFromUnit(parseResult.unit);
      } catch (_) {}
    }

    return imports.toList();
  }

  String _resolveFieldType({
    required FormalParameterElement param,
    required Element field,
    required ClassDeclaration? classDecl,
    required String? constructorName,
  }) {
    if (classDecl != null) {
      // 1. Check constructor parameter explicit type
      for (final member in classDecl.members) {
        if (member is ConstructorDeclaration) {
          final isTargetConstructor = switch (constructorName) {
            null || '' => member.name == null,
            final name => member.name?.lexeme == name,
          };
          if (isTargetConstructor) {
            for (final p in member.parameters.parameters) {
              if (p.name?.lexeme == param.name) {
                try {
                  final typeSource = (p as dynamic).type?.toSource() as String?;
                  if (typeSource != null && typeSource.isNotEmpty) {
                    return typeSource;
                  }
                } catch (_) {}
              }
            }
          }
        }
      }

      // 2. Check field declaration or getter type
      for (final member in classDecl.members) {
        if (member is FieldDeclaration) {
          for (final variable in member.fields.variables) {
            if (variable.name.lexeme == param.name) {
              final typeSource = member.fields.type?.toSource();
              if (typeSource != null && typeSource.isNotEmpty) {
                return typeSource;
              }
            }
          }
        } else if (member is MethodDeclaration && member.isGetter) {
          if (member.name.lexeme == param.name) {
            final typeSource = member.returnType?.toSource();
            if (typeSource != null && typeSource.isNotEmpty) {
              return typeSource;
            }
          }
        }
      }
    }

    return param.type.getDisplayString();
  }

  ({String getterName, List<String> fields})? _findInClassFields({
    required ClassElement element,
    required ConstructorElement constructor,
    required ClassDeclaration? classDecl,
    required String? customGetter,
    required String methodName,
  }) {
    if (classDecl == null) return null;

    final constructorParamNames = constructor.formalParameters
        .map((FormalParameterElement p) => p.name)
        .toSet();

    final (hasCustomName, candidateNames) = switch (customGetter?.trim()) {
      final name? when name.isNotEmpty => (true, [name]),
      _ => (false, Cloneable.defaultCloneableFieldsGetters),
    };

    final found = <String, List<String>>{};

    for (final member in classDecl.members) {
      // 1. Method / Getter declaration
      if (member is MethodDeclaration && member.isGetter) {
        final name = member.name.lexeme;
        if (candidateNames.contains(name)) {
          if (!constructorParamNames.contains(name)) {
            found[name] = _extractListNames(member.body, element, name);
          }
        }
      }

      // 2. Field declaration
      if (member is FieldDeclaration) {
        for (final variable in member.fields.variables) {
          final name = variable.name.lexeme;
          if (candidateNames.contains(name)) {
            if (!constructorParamNames.contains(name) &&
                variable.initializer != null) {
              found[name] = _extractListNamesFromExpr(
                variable.initializer!,
                element,
                name,
              );
            }
          }
        }
      }
    }

    if (hasCustomName && found.isEmpty) {
      throw InvalidGenerationSourceError(
        "Class '${element.name}' specifies cloneableFieldsGetter: '$customGetter', but no in-class getter or field named '$customGetter' was found.",
        element: element,
      );
    }

    if (found.isEmpty) return null;

    if (found.length > 1) {
      throw InvalidGenerationSourceError(
        "Multiple in-class field whitelist getters found (${found.keys.map((k) => "'$k'").join(', ')}) in class '${element.name}'. Please define only one.",
        element: element,
      );
    }

    final entry = found.entries.first;
    return (getterName: entry.key, fields: entry.value);
  }

  List<String> _extractListNames(
      FunctionBody body, ClassElement element, String getterName) {
    final Expression? expr = switch (body) {
      ExpressionFunctionBody(:final expression) => expression,
      BlockFunctionBody(:final block) => () {
          for (final statement in block.statements) {
            if (statement is ReturnStatement) {
              return statement.expression;
            }
          }
          return null;
        }(),
      _ => null,
    };

    if (expr == null) {
      throw InvalidGenerationSourceError(
        "The '$getterName' getter in class '${element.name}' must return a list literal (e.g. `[name, age]`).",
        element: element,
      );
    }

    return _extractListNamesFromExpr(expr, element, getterName);
  }

  List<String> _extractListNamesFromExpr(
      Expression expr, ClassElement element, String getterName) {
    if (expr is! ListLiteral) {
      throw InvalidGenerationSourceError(
        "The '$getterName' getter in class '${element.name}' must return a list literal (e.g. `['name', 'age']` or `[name, age]`).",
        element: element,
      );
    }

    final names = <String>[];
    for (final elem in expr.elements) {
      if (elem is SimpleStringLiteral) {
        names.add(elem.value);
      } else if (elem is SimpleIdentifier) {
        names.add(elem.name);
      } else {
        throw InvalidGenerationSourceError(
          "The '$getterName' list in class '${element.name}' must contain only field identifiers or field name strings.",
          element: element,
        );
      }
    }

    return names;
  }
}

final class _FieldInfo {
  final String name;
  final String type;
  final bool isNullable;
  final bool isNamed;
  final bool isRequired;
  final bool isIgnored;
  final bool shouldDeepCopy;
  final bool shouldIgnoreNull;
  final _CollectionKind collectionKind;
  final String? cloner;

  const _FieldInfo({
    required this.name,
    required this.type,
    required this.isNullable,
    required this.isNamed,
    required this.isRequired,
    required this.isIgnored,
    required this.shouldDeepCopy,
    required this.shouldIgnoreNull,
    required this.collectionKind,
    this.cloner,
  });
}
