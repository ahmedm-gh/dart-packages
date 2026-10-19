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

  /// Returns the start marker comment for typedef in [className].
  static String typedefStartMarker(String className) =>
      '\n// cloneable:typedef:start ($className) - GENERATED CODE - DO NOT MODIFY BY HAND\n'
      '// (run: dart run cloneable_generator to regenerate)\n';

  /// Returns the end marker comment for typedef in [className].
  static String typedefEndMarker(String className) =>
      '\n// cloneable:typedef:end ($className)\n';

  /// Wraps [code] with the typedef start and end markers for [className].
  static String wrapWithTypedefMarkers(String className, String code) {
    final trimmed = code.trim();
    return '${typedefStartMarker(className)}\n'
        '$trimmed\n'
        '${typedefEndMarker(className)}';
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
    '(?://\\s*={5,}\\s*\\r?\\n)?'
    r'//\s*cloneable:\s*start\s*\(([^)]+)\)[^\r\n]*\r?\n'
    '(?://\\s*={5,}\\s*\\r?\\n)?'
    r'[\s\S]*?'
    '(?://\\s*={5,}\\s*\\r?\\n)?'
    r'//\s*cloneable:\s*end\s*\(\1\)[^\r\n]*'
    r'(?:\r?\n//\s*={5,}\s*)?',
    caseSensitive: false,
  );

  /// Regex pattern matching any typedef Cloneable marker block.
  /// Captures the class name in group 1.
  static final RegExp allTypedefMarkersPattern = RegExp(
    r'(?:\r?\n)?'
    '(?://\\s*={5,}\\s*\\r?\\n)?'
    r'//\s*cloneable:\s*typedef:\s*start\s*\(([^)]+)\)[^\r\n]*\r?\n'
    '(?://\\s*={5,}\\s*\\r?\\n)?'
    r'[\s\S]*?'
    '(?://\\s*={5,}\\s*\\r?\\n)?'
    r'//\s*cloneable:\s*typedef:\s*end\s*\(\1\)[^\r\n]*'
    r'(?:\r?\n//\s*={5,}\s*)?',
    caseSensitive: false,
  );

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final isActive = annotation.peek('active')?.boolValue ?? true;

    if (!isActive) {
      return '';
    }

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

    final output = switch (annotation
        .peek('output')
        ?.objectValue
        .getField('index')
        ?.toIntValue()) {
      final index? when index >= 0 && index < CloneableOutput.values.length =>
        CloneableOutput.values[index],
      _ => resolvedDefaults.output,
    };

    if (output.isInline) {
      log.info(
        "@Cloneable(output: CloneableOutput.${output.name}) detected on '${element.name}'. "
        'Run "dart run cloneable_generator" to generate inline code.',
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
    );
  }

  bool _isFirstActiveCloneableClass(ClassElement element) {
    const typeChecker = TypeChecker.fromRuntime(Cloneable);
    final resolvedDefaults = ConfigLoader.resolveDefaults(
      library: element.library,
    );
    for (final topCls in element.library.topLevelElements) {
      if (topCls is! ClassElement) continue;
      if (topCls == element) {
        return true;
      }
      ConstantReader? annotation;
      if (typeChecker.firstAnnotationOf(topCls) case final obj?) {
        annotation = ConstantReader(obj);
      } else {
        for (final meta in topCls.metadata) {
          if (meta.computeConstantValue() case final val?
              when val.type?.element?.name == 'Cloneable') {
            annotation = ConstantReader(val);
            break;
          }
        }
      }
      if (annotation != null) {
        final isActive =
            annotation.peek('active')?.boolValue ?? resolvedDefaults.active;
        final output = switch (annotation
            .peek('output')
            ?.objectValue
            .getField('index')
            ?.toIntValue()) {
          final index?
              when index >= 0 && index < CloneableOutput.values.length =>
            CloneableOutput.values[index],
          _ => resolvedDefaults.output,
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
  /// `InlineGenerator` (during standalone in-file code generation).
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
  }) {
    resolvedDefaults ??= ConfigLoader.resolveDefaults(
      library: element.library,
      searchDirectory: inputFilePath != null ? p.dirname(inputFilePath) : null,
    );

    final isActive =
        annotation.peek('active')?.boolValue ?? resolvedDefaults.active;
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
      _ => resolvedDefaults.output,
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
    final methodName = namingReader?.peek('method')?.stringValue ??
        annotation.peek('method')?.stringValue ??
        annotation.peek('methodName')?.stringValue ??
        resolvedDefaults.method;

    final capitalizedMethod = switch (methodName) {
      '' => '',
      final m => '${m[0].toUpperCase()}${m.substring(1)}',
    };

    (String prefix, String suffix) readAffix(
      String fieldName, {
      required CloneableAffix defaultAffix,
    }) {
      final affixReader = namingReader?.peek(fieldName);
      final p = affixReader?.peek('prefix')?.stringValue;
      final s = affixReader?.peek('suffix')?.stringValue;
      return (
        p ?? defaultAffix.prefix ?? '',
        s ?? defaultAffix.suffix ?? '',
      );
    }

    final baseName = inputFileName.replaceAll(RegExp(r'\.dart$'), '');

    final (rawFilePrefix, rawFileSuffix) = readAffix(
      'file',
      defaultAffix: resolvedDefaults.file,
    );
    final cleanFileSuffix =
        rawFileSuffix.endsWith('.dart') ? rawFileSuffix : '$rawFileSuffix.dart';
    final customTargetFileName = '$rawFilePrefix$baseName$cleanFileSuffix';
    final customDir = namingReader?.peek('directory')?.stringValue ??
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
      for (final part in library.parts) {
        final partStr = part.toString();
        for (final candidate in candidatePartNames) {
          if (partStr.endsWith(candidate) || partStr.contains(candidate)) {
            matchedPartDirective = candidate;
            break;
          }
        }
        if (matchedPartDirective != null) break;
      }

      if (matchedPartDirective == null) {
        if (parsedLibResult case ParsedLibraryResult(:final units)) {
          for (final unit in units) {
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
        final source = sourceCode ?? element.source.contents.data;
        for (final candidate in candidatePartNames) {
          if (source.contains("part '$candidate';") ||
              source.contains('part "$candidate";')) {
            matchedPartDirective = candidate;
            break;
          }
        }
      }
    }

    final bool hasPartDirective = matchedPartDirective != null;

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
      CloneableOutput.inLibrary => resolvedDefaults.inLibrary,
      CloneableOutput.inClass => resolvedDefaults.inClass,
      CloneableOutput.part => resolvedDefaults.part,
      CloneableOutput.standalone => resolvedDefaults.standalone,
      CloneableOutput.auto => effectiveIsInline
          ? resolvedDefaults.inLibrary
          : (hasPartDirective
              ? resolvedDefaults.part
              : resolvedDefaults.standalone),
    };

    final approachPrefix = approachAffix?.peek('prefix')?.stringValue ??
        defaultApproachAffix?.prefix;
    final approachSuffix = approachAffix?.peek('suffix')?.stringValue ??
        defaultApproachAffix?.suffix;

    final cliPrefix = defaultPrefix ?? this.defaultPrefix;
    final cliSuffix = defaultSuffix ?? this.defaultSuffix;

    final defaultMixin = resolvedDefaults.mixin;
    final defaultExtension = resolvedDefaults.extension;
    final defaultTypedef = resolvedDefaults.typedef;

    // Qualifiers from approach or CLI
    final prefixQualifier = approachPrefix ?? cliPrefix;
    final suffixQualifier = approachSuffix ?? cliSuffix;

    // Mixin:
    final rawMixinPrefix =
        namingReader?.peek('mixin')?.peek('prefix')?.stringValue;
    final rawMixinSuffix =
        namingReader?.peek('mixin')?.peek('suffix')?.stringValue;
    final defaultMixinPrefix = defaultMixin.prefix ?? '';
    final defaultMixinSuffix = defaultMixin.suffix ?? '';
    final effectiveMixinPrefix =
        (rawMixinPrefix != null && rawMixinPrefix != defaultMixinPrefix)
            ? rawMixinPrefix
            : (prefixQualifier ?? rawMixinPrefix ?? defaultMixinPrefix);
    final effectiveMixinSuffix =
        (rawMixinSuffix != null && rawMixinSuffix != defaultMixinSuffix)
            ? rawMixinSuffix
            : (suffixQualifier ?? rawMixinSuffix ?? defaultMixinSuffix);

    // Extension:
    final rawExtensionPrefix =
        namingReader?.peek('extension')?.peek('prefix')?.stringValue;
    final rawExtensionSuffix =
        namingReader?.peek('extension')?.peek('suffix')?.stringValue;
    final defaultExtensionPrefix = defaultExtension.prefix ?? '';
    final defaultExtensionSuffix = defaultExtension.suffix ?? '';
    final qualifiedExtensionSuffix = switch (suffixQualifier) {
      final s? when s.isNotEmpty =>
        s.endsWith(defaultExtensionSuffix) ? s : '$s$defaultExtensionSuffix',
      _ => defaultExtensionSuffix,
    };
    final effectiveExtensionPrefix = (rawExtensionPrefix != null &&
            rawExtensionPrefix != defaultExtensionPrefix)
        ? rawExtensionPrefix
        : (prefixQualifier ?? rawExtensionPrefix ?? defaultExtensionPrefix);
    final effectiveExtensionSuffix = (rawExtensionSuffix != null &&
            rawExtensionSuffix != defaultExtensionSuffix)
        ? rawExtensionSuffix
        : (rawExtensionSuffix ?? qualifiedExtensionSuffix);

    // Typedef:
    final rawTypedefPrefix =
        namingReader?.peek('typedef')?.peek('prefix')?.stringValue;
    final rawTypedefSuffix =
        namingReader?.peek('typedef')?.peek('suffix')?.stringValue;
    final defaultTypedefPrefix = defaultTypedef.prefix ?? '';
    final defaultTypedefSuffix =
        defaultTypedef.suffix != CloneableNaming.defaultTypedef.suffix
            ? (defaultTypedef.suffix ?? '')
            : (methodName == CloneableNaming.defaultMethod
                ? (defaultTypedef.suffix ?? '')
                : '${capitalizedMethod}Fn');
    final effectiveTypedefPrefix =
        (rawTypedefPrefix != null && rawTypedefPrefix != defaultTypedefPrefix)
            ? rawTypedefPrefix
            : (prefixQualifier ?? rawTypedefPrefix ?? defaultTypedefPrefix);
    final effectiveTypedefSuffix =
        (rawTypedefSuffix != null && rawTypedefSuffix != defaultTypedefSuffix)
            ? rawTypedefSuffix
            : (rawTypedefSuffix ?? defaultTypedefSuffix);

    // Verify mixin (candidate names excluding short _$ClassName)
    final defaultCapitalizedMethod =
        '${CloneableNaming.defaultMethod[0].toUpperCase()}${CloneableNaming.defaultMethod.substring(1)}';

    final prefixScoped = effectiveMixinPrefix.startsWith('_')
        ? '$effectiveMixinPrefix${element.name}$effectiveMixinSuffix'
        : '_$effectiveMixinPrefix${element.name}$effectiveMixinSuffix';
    final prefixCapability = effectiveMixinPrefix.startsWith('_')
        ? '$effectiveMixinPrefix${element.name}$capitalizedMethod'
        : '_$effectiveMixinPrefix${element.name}$capitalizedMethod';
    final prefixDefaultCapability = effectiveMixinPrefix.startsWith('_')
        ? '$effectiveMixinPrefix${element.name}$defaultCapitalizedMethod'
        : '_$effectiveMixinPrefix${element.name}$defaultCapitalizedMethod';

    final candidateMixinNames = <String>{
      prefixScoped,
      prefixCapability,
      if (methodName != CloneableNaming.defaultMethod) prefixDefaultCapability,
      if (!effectiveMixinPrefix.startsWith('_')) ...[
        '$effectiveMixinPrefix${element.name}$effectiveMixinSuffix',
        '$effectiveMixinPrefix${element.name}$capitalizedMethod',
        if (methodName != CloneableNaming.defaultMethod)
          '$effectiveMixinPrefix${element.name}$defaultCapitalizedMethod',
      ],
      '_\$${element.name}$effectiveMixinSuffix',
      if (effectiveMixinSuffix.isEmpty) '_\$${element.name}',
      '_\$${element.name}Cloneable',
      '_\$${element.name}$capitalizedMethod',
      if (methodName != CloneableNaming.defaultMethod)
        '_\$${element.name}$defaultCapitalizedMethod',
    }.toList();

    String? detectedMixinName;

    // 1. Check AST node if available (direct from syntax tree of the class)
    if (parsedLibResult case ParsedLibraryResult parsedLib) {
      try {
        if (parsedLib.getElementDeclaration(element)?.node
            case ClassDeclaration(:final withClause?)) {
          for (final mixinType in withClause.mixinTypes) {
            final name = mixinType.name2.lexeme;
            if (candidateMixinNames.contains(name)) {
              detectedMixinName = name;
              break;
            }
          }
        }
      } catch (_) {}
    }

    // 2. Check element.mixins (element model)
    if (detectedMixinName == null) {
      for (final candidate in candidateMixinNames) {
        if (element.mixins.any((m) =>
            m.element.name == candidate ||
            m.getDisplayString(withNullability: false).startsWith(candidate))) {
          detectedMixinName = candidate;
          break;
        }
      }
    }

    // 3. Fallback to source inspection (useful in mock test environments or updated files)
    if (detectedMixinName == null) {
      final source = sourceCode ?? element.source.contents.data;
      for (final candidate in candidateMixinNames) {
        final pattern =
            RegExp(r'\bwith\b[^;{]*\b' + RegExp.escape(candidate) + r'\b');
        if (pattern.hasMatch(source)) {
          detectedMixinName = candidate;
          break;
        }
      }
    }

    final bool hasMixin = detectedMixinName != null;

    // Strategy configuration
    final strategy = switch (annotation
        .peek('strategy')
        ?.objectValue
        .getField('index')
        ?.toIntValue()) {
      final index? when index >= 0 && index < CloneableStrategy.values.length =>
        CloneableStrategy.values[index],
      _ => resolvedDefaults.strategy,
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
      _ => resolvedDefaults.sentinel,
    };

    final customSentinel = namingReader?.peek('sentinel')?.stringValue ??
        resolvedDefaults.sentinelName;

    final importPrefix = _findCloneableImportPrefix(element);
    final (sentinelExpr, sentinelDeclaration) = switch (sentinelStrategy) {
      CloneableSentinel.private => (
          customSentinel,
          output == CloneableOutput.inClass
              ? '  static const $customSentinel = Object();\n\n'
              : (includeHeader ? 'const $customSentinel = Object();\n\n' : ''),
        ),
      CloneableSentinel.package => () {
          if (importPrefix != null) {
            return ('$importPrefix.\$undefined', '');
          }
          final hasCloneableUndefined =
              (element.library.scope.lookup('cloneableUndefined').getter !=
                          null ||
                      element.source.contents.data
                          .contains('cloneableUndefined')) &&
                  element.library.scope.lookup(r'$undefined').getter == null &&
                  !element.source.contents.data.contains(r'$undefined');
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
          final hasUndefined =
              element.library.scope.lookup(r'$undefined').getter != null ||
                  element.source.contents.data.contains(r'$undefined');
          if (hasUndefined) {
            return (r'$undefined', '');
          }
          final hasCloneableUndefined =
              element.library.scope.lookup('cloneableUndefined').getter !=
                      null ||
                  element.source.contents.data.contains('cloneableUndefined');
          if (hasCloneableUndefined) {
            return ('cloneableUndefined', '');
          }
          return (
            customSentinel,
            includeHeader ? 'const $customSentinel = Object();\n\n' : '',
          );
        }(),
    };

    // Class-level configuration
    final constructorName = annotation.peek('constructor')?.stringValue;
    final classDeepCopy = annotation.peek('deepCopyCollections')?.boolValue ??
        resolvedDefaults.deepCopyCollections;
    final classIgnoreNull =
        annotation.peek('ignoreNull')?.boolValue ?? resolvedDefaults.ignoreNull;

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
      if (element.name.startsWith('_')) {
        throw InvalidGenerationSourceError(
          "Class '${element.name}' is private. Dart does not allow accessing private classes from standalone generated libraries.\n"
          "To generate copyWith for private classes, use 'CloneableOutput.part' with a part directive, or 'CloneableOutput.inLibrary' / 'CloneableOutput.inClass'.",
          element: element,
        );
      }
      if (constructor.name.startsWith('_')) {
        throw InvalidGenerationSourceError(
          "Constructor '${constructor.name}' of class '${element.name}' is private. Standalone generated libraries cannot access private constructors across library boundaries.\n"
          "Use a public constructor, or switch to 'CloneableOutput.part' / 'CloneableOutput.inClass'.",
          element: element,
        );
      }
    }

    // Generic type parameters
    final (typeParamsWithBounds, typeParamsArgs) =
        switch (element.typeParameters) {
      [] => ('', ''),
      final params => (
          '<${params.map((p) => p.getDisplayString(withNullability: true)).join(', ')}>',
          '<${params.map((p) => p.name).join(', ')}>',
        ),
    };

    final classDecl = _findClassDeclaration(
      element: element,
      parsedLibResult: parsedLibResult,
    );

    // Resolve fields whitelist (from annotation or in-class getter/field)
    final annotationFields = switch (annotation.peek('fields')?.listValue) {
      null => null,
      final list =>
        list.map((item) => item.toStringValue()).whereType<String>().toList(),
    };

    final customGetter = annotation.peek('cloneableFieldsGetter')?.stringValue;

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
      _ => resolvedDefaults.fieldsConflict,
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

    // If explicitly empty (AND NOT NULL), ignore code generation (like active = false)
    if (allowedFields != null && allowedFields.isEmpty) {
      return '';
    }

    if (allowedFields != null) {
      final constructorParamNames =
          constructor.parameters.map((p) => p.name).toSet();
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
    for (final param in constructor.parameters) {
      final field = element.getField(param.name) ??
          element.getGetter(param.name)?.variable ??
          (throw InvalidGenerationSourceError(
            "Constructor parameter '${param.name}' does not match any field or getter in class '${element.name}'.",
            element: param,
          ));

      if (isSeparateLibrary && param.name.startsWith('_')) {
        throw InvalidGenerationSourceError(
          "Constructor parameter '${param.name}' in class '${element.name}' is private. Standalone generated libraries cannot access private fields across library boundaries.\n"
          "Make the field public, or switch to 'CloneableOutput.part' / 'CloneableOutput.inClass'.",
          element: param,
        );
      }

      final isWhitelisted =
          allowedFields == null || allowedFields.contains(param.name);
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
            "Cloner function '$fieldCloner' on field '${param.name}' of class '${element.name}' is private. Standalone generated libraries cannot access private cloner functions across library boundaries.\n"
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
          name: param.name,
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
    final typedefName =
        '$effectiveTypedefPrefix${element.name}$effectiveTypedefSuffix';
    final resolvedMixinName = detectedMixinName ?? prefixScoped;

    // Validate symbol name collisions
    final colliding = <String>[];
    if (output != CloneableOutput.inClass) {
      if (useExtension && extensionName == typedefName) {
        colliding.add("extension '$extensionName' and typedef '$typedefName'");
      }
      if (!useExtension && resolvedMixinName == typedefName) {
        colliding.add("mixin '$resolvedMixinName' and typedef '$typedefName'");
      }
      if (!useExtension && resolvedMixinName == extensionName) {
        colliding
            .add("mixin '$resolvedMixinName' and extension '$extensionName'");
      }
    }

    if (colliding.isNotEmpty) {
      throw InvalidGenerationSourceError(
        "Naming conflict detected for class '${element.name}':\n"
        "The following generated symbols have identical names: ${colliding.join(', ')}.\n"
        "To resolve this, customize 'naming' in @Cloneable with distinct prefixes or suffixes for mixin, extension, and typedef (e.g. naming: CloneableNaming(extension: CloneableAffix(suffix: 'Extension'), typedef: CloneableAffix(suffix: 'CopyWithFn'))).",
        element: element,
      );
    }

    return _generateCode(
      className: element.name,
      constructorName: constructorName,
      typeParamsWithBounds: typeParamsWithBounds,
      typeParamsArgs: typeParamsArgs,
      fields: params,
      useExtension: useExtension,
      mixinName: resolvedMixinName,
      extensionName: extensionName,
      typedefName: typedefName,
      methodName: methodName,
      hasPartDirective: hasPartDirective,
      inputFileName: inputFileName,
      sentinelExpr: sentinelExpr,
      sentinelDeclaration: sentinelDeclaration,
      isInline: effectiveIsInline,
      includeHeader: includeHeader,
      fileImports: fileImports,
      output: output,
    );
  }

  /// Generates the separated code parts for [CloneableOutput.inClass]:
  /// - [typedefCode]: The top-level strongly-typed copyWith function typedef.
  /// - [memberCode]: The class members (sentinel, getter, and private copy method).
  ({String typedefCode, String memberCode}) generateInClassParts({
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

    final typedefPattern = RegExp(
      r'([\s\S]*?typedef\s+[^\n]+\s*=\s*[^\n]+\s+Function\s*\([\s\S]*?\);)\s*([\s\S]*)',
    );
    if (typedefPattern.firstMatch(fullCode.trim()) case final match?) {
      return (
        typedefCode: match.group(1)?.trim() ?? '',
        memberCode: match.group(2)?.trim() ?? '',
      );
    }

    return (typedefCode: '', memberCode: fullCode.trim());
  }

  String? _findCloneableImportPrefix(ClassElement element) {
    for (final import in element.library.libraryImports) {
      final uri = import.importedLibrary?.source.uri.toString();
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
      ParameterElement param, Element field) {
    const checker = TypeChecker.fromRuntime(CloneableField);
    if (checker.firstAnnotationOf(param) case final obj?) {
      return ConstantReader(obj);
    }
    if (checker.firstAnnotationOf(field) case final obj?) {
      return ConstantReader(obj);
    }

    // Fallback by element name for test environments / mock elements
    for (final meta in [...param.metadata, ...field.metadata]) {
      if (meta.computeConstantValue() case final val?
          when val.type?.element?.name == 'CloneableField') {
        return ConstantReader(val);
      }
    }
    return null;
  }

  bool _isFieldIgnored(ParameterElement param, Element field) =>
      _getFieldAnnotationReader(param, field)?.peek('ignore')?.boolValue ==
      true;

  bool? _getFieldDeepCopy(ParameterElement param, Element field) =>
      _getFieldAnnotationReader(param, field)?.peek('deepCopy')?.boolValue;

  bool? _getFieldIgnoreNull(ParameterElement param, Element field) =>
      _getFieldAnnotationReader(param, field)?.peek('ignoreNull')?.boolValue;

  String? _getFieldCloner(
    ParameterElement param,
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
                final annName = metadata.name.name;
                if (annName == 'CloneableField' ||
                    annName.endsWith('.CloneableField')) {
                  final args = metadata.arguments?.arguments;
                  if (args != null) {
                    for (final arg in args) {
                      if (arg is NamedExpression &&
                          arg.name.label.name == 'cloner') {
                        return arg.expression.toSource();
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

    final name = type.element?.name ??
        type.getDisplayString(withNullability: false).split('<').first.trim();

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
    required String typedefName,
    required String methodName,
    required bool hasPartDirective,
    required String inputFileName,
    required String sentinelExpr,
    required String sentinelDeclaration,
    required bool isInline,
    required bool includeHeader,
    required List<String> fileImports,
    required CloneableOutput output,
  }) {
    final targetClassType = '$className$typeParamsArgs';
    final copyWithTypedefWithArgs = '$typedefName$typeParamsArgs';
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
          buffer.writeln("import 'package:cloneable/cloneable.dart';");
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

    // Generate typedef function parameters
    final typedefParamsBuffer = StringBuffer();
    for (final field in copyFields) {
      final paramType = field.shouldIgnoreNull && !field.isNullable
          ? '${field.type}?'
          : field.type;
      typedefParamsBuffer.writeln('    $paramType ${field.name},');
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

    final implementation = switch (output) {
      CloneableOutput.inClass => '''
$sentinelDeclaration  $copyWithTypedefWithArgs get $methodName => $privateMethodName;

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
  $copyWithTypedefWithArgs get $methodName => $privateMethodName;

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
  $copyWithTypedefWithArgs get $methodName => $privateMethodName;

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

    final typedefDoc =
        '/// Strongly-typed $methodName function signature for [$className].\n'
        'typedef $typedefName$typeParamsWithBounds = $targetClassType Function({\n'
        '$typedefParamsBuffer});';

    if (output == CloneableOutput.inClass) {
      return '''
$typedefDoc

$implementation''';
    }

    final topSentinel =
        output != CloneableOutput.inClass ? sentinelDeclaration : '';

    return '''
$standaloneHeader$topSentinel$typedefDoc

$implementation''';
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
      try {
        if (parsedLib.getElementDeclaration(element)?.node
            case ClassDeclaration decl) {
          return decl;
        }
      } catch (_) {}
    }

    try {
      final parseResult = parseString(
        content: element.source.contents.data,
        throwIfDiagnostics: false,
      );
      for (final decl in parseResult.unit.declarations) {
        if (decl is ClassDeclaration && decl.name.lexeme == element.name) {
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
          content: element.source.contents.data,
          throwIfDiagnostics: false,
        );
        collectFromUnit(parseResult.unit);
      } catch (_) {}
    }

    return imports.toList();
  }

  String _resolveFieldType({
    required ParameterElement param,
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
              final actualParam = switch (p) {
                DefaultFormalParameter(:final parameter) => parameter,
                _ => p,
              };
              if (actualParam.name?.lexeme == param.name) {
                final typeSource = switch (actualParam) {
                  SimpleFormalParameter(:final type?) => type.toSource(),
                  FieldFormalParameter(:final type?) => type.toSource(),
                  _ => null,
                };
                if (typeSource != null && typeSource.isNotEmpty) {
                  return typeSource;
                }
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

    return param.type.getDisplayString(withNullability: true);
  }

  ({String getterName, List<String> fields})? _findInClassFields({
    required ClassElement element,
    required ConstructorElement constructor,
    required ClassDeclaration? classDecl,
    required String? customGetter,
    required String methodName,
  }) {
    if (classDecl == null) return null;

    final constructorParamNames =
        constructor.parameters.map((p) => p.name).toSet();

    final (hasCustomName, candidateNames) = switch (customGetter?.trim()) {
      final name? when name.isNotEmpty => (true, [name]),
      _ => (false, Cloneable.defaultCloneableFieldsGetters),
    };

    final found = <String, List<String>>{};

    for (final member in classDecl.members) {
      // 1. Method / Getter declaration (e.g. List<Object?> get cloneableFields => [name, age];)
      if (member is MethodDeclaration && member.isGetter) {
        final name = member.name.lexeme;
        if (candidateNames.contains(name)) {
          if (!constructorParamNames.contains(name)) {
            found[name] = _extractListNames(member.body, element, name);
          }
        }
      }

      // 2. Field declaration (e.g. static const cloneableFields = [...] or final copyWithFields = [...])
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
        "The '$getterName' getter in class '${element.name}' must return a list literal (e.g. '=> [fieldA, fieldB]').",
        element: element,
      );
    }

    return _extractListNamesFromExpr(expr, element, getterName);
  }

  List<String> _extractListNamesFromExpr(
      Expression expr, ClassElement element, String getterName) {
    final listExpr = switch (expr) {
      ListLiteral l => l,
      ParenthesizedExpression(:final expression)
          when expression is ListLiteral =>
        expression,
      _ => null,
    };

    if (listExpr == null) {
      throw InvalidGenerationSourceError(
        "The '$getterName' getter in class '${element.name}' must return a list literal (e.g. '=> [fieldA, fieldB]').",
        element: element,
      );
    }

    final names = <String>[];
    for (final elem in listExpr.elements) {
      final name = switch (elem) {
        SimpleIdentifier id => id.name,
        SimpleStringLiteral str => str.value,
        StringLiteral str when str.stringValue != null => str.stringValue!,
        PropertyAccess prop => prop.propertyName.name,
        PrefixedIdentifier pre when pre.prefix.name == 'this' =>
          pre.identifier.name,
        _ => throw InvalidGenerationSourceError(
            "The '$getterName' list in class '${element.name}' must contain only field identifiers or field name strings.",
            element: element,
          ),
      };
      names.add(name);
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
