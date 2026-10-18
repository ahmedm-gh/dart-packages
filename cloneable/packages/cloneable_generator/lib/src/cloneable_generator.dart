import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:cloneable/cloneable.dart';
import 'package:source_gen/source_gen.dart';

enum _CollectionKind { none, list, set, map, iterable }

/// Code generator for creating strongly-typed `copyWith` methods with
/// explicit-null handling.
final class CloneableGenerator extends GeneratorForAnnotation<Cloneable> {
  const CloneableGenerator();

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
    r'(?:\r?\\n//\s*={5,}\s*)?',
    caseSensitive: false,
  );

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final isActive = annotation.peek('active')?.boolValue ?? true;
    final isInline = annotation.peek('inline')?.boolValue ?? false;

    if (!isActive) {
      return '';
    }

    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'The @Cloneable() annotation can only be applied to classes.',
        element: element,
      );
    }

    if (isInline) {
      log.info(
        "@Cloneable(inline: true) detected on '${element.name}'. "
        'Run "dart run cloneable_generator" to generate inline code.',
      );
      return '';
    }

    final parsedLibResult =
        element.session?.getParsedLibraryByElement(element.library);

    return generateForClass(
      element: element,
      annotation: annotation,
      inputFileName: buildStep.inputId.pathSegments.last,
      inputFilePath: buildStep.inputId.path,
      isInline: false,
      parsedLibResult: parsedLibResult,
    );
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
    bool isInline = false,
    SomeParsedLibraryResult? parsedLibResult,
  }) {
    final isActive = annotation.peek('active')?.boolValue ?? true;
    if (!isActive) {
      return '';
    }

    if (element.isAbstract) {
      throw InvalidGenerationSourceError(
        'The @Cloneable() annotation cannot be applied to abstract classes.',
        element: element,
      );
    }

    // Resolve copy method name
    final methodName = switch (annotation.peek('methodName')?.stringValue) {
      final name? when name.isNotEmpty => name,
      _ => Cloneable.defaultMethodName,
    };

    final capitalizedMethod = switch (methodName) {
      '' => '',
      final m => '${m[0].toUpperCase()}${m.substring(1)}',
    };

    // Verify part directive (selective part naming support)
    final baseName = inputFileName.replaceAll(RegExp(r'\.dart$'), '');

    final candidatePartNames = [
      '$baseName.g.dart',
      '${baseName}_cloneable.g.dart',
      '$baseName.cloneable.g.dart',
      '${baseName}_${Cloneable.defaultMethodName}.g.dart',
      '$baseName.${Cloneable.defaultMethodName}.g.dart',
      if (methodName != Cloneable.defaultMethodName)
        '${baseName}_$methodName.g.dart',
      if (methodName != Cloneable.defaultMethodName)
        '$baseName.$methodName.g.dart',
      if (methodName != Cloneable.defaultMethodName)
        '${baseName}_$capitalizedMethod.g.dart',
    ];

    String? matchedPartDirective;
    if (!isInline) {
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
        final source = element.source.contents.data;
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

    // Verify mixin (candidate names excluding short _$ClassName)
    final defaultCapitalizedMethod =
        '${Cloneable.defaultMethodName[0].toUpperCase()}${Cloneable.defaultMethodName.substring(1)}';
    final candidateMixinNames = [
      '_\$${element.name}Cloneable',
      '_\$${element.name}$capitalizedMethod',
      if (methodName != Cloneable.defaultMethodName)
        '_\$${element.name}$defaultCapitalizedMethod',
    ];

    String? detectedMixinName;

    // 1. Check AST node if available (direct from syntax tree of the class)
    if (parsedLibResult case ParsedLibraryResult parsedLib) {
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

    // 3. Fallback to source inspection (useful in mock test environments)
    if (detectedMixinName == null) {
      final source = element.source.contents.data;
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
      _ => CloneableStrategy.auto,
    };

    final useExtension = switch (strategy) {
      CloneableStrategy.mixin when !hasPartDirective && !isInline =>
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
          "    class ${element.name} with _\$${element.name}Cloneable { ... }  (Scoped style)\n"
          "    class ${element.name} with _\$${element.name}$capitalizedMethod { ... }   (Capability style)\n"
          "Or use CloneableStrategy.extension / CloneableStrategy.auto to generate an extension without the mixin.",
          element: element,
        ),
      CloneableStrategy.mixin => false,
      CloneableStrategy.extension => true,
      CloneableStrategy.auto =>
        isInline ? !hasMixin : (!hasMixin || !hasPartDirective),
    };

    // Sentinel configuration
    final sentinelStrategy = switch (annotation
        .peek('sentinel')
        ?.objectValue
        .getField('index')
        ?.toIntValue()) {
      final index? when index >= 0 && index < CloneableSentinel.values.length =>
        CloneableSentinel.values[index],
      _ => CloneableSentinel.auto,
    };

    final prefix = _findCloneableImportPrefix(element);
    final (sentinelExpr, sentinelDeclaration) = switch (sentinelStrategy) {
      CloneableSentinel.private => (
          '_undefined',
          '  static const Object _undefined = Object();\n\n',
        ),
      CloneableSentinel.package => (
          prefix != null ? '$prefix.cloneableUndefined' : 'cloneableUndefined',
          '',
        ),
      CloneableSentinel.auto => () {
          if (prefix != null) {
            return ('$prefix.cloneableUndefined', '');
          }
          final hasInScope =
              element.library.scope.lookup('cloneableUndefined').getter != null;
          final inMockSource =
              element.source.contents.data.contains('cloneableUndefined');
          if (hasInScope || inMockSource) {
            return ('cloneableUndefined', '');
          }
          return (
            '_undefined',
            '  static const Object _undefined = Object();\n\n',
          );
        }(),
    };

    // Class-level configuration
    final constructorName = annotation.peek('constructor')?.stringValue;
    final classDeepCopy =
        annotation.peek('deepCopyCollections')?.boolValue ?? false;
    final classIgnoreNull = annotation.peek('ignoreNull')?.boolValue ?? false;

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

    // Generic type parameters
    final (typeParamsWithBounds, typeParamsArgs) =
        switch (element.typeParameters) {
      [] => ('', ''),
      final params => (
          '<${params.map((p) => p.getDisplayString(withNullability: true)).join(', ')}>',
          '<${params.map((p) => p.name).join(', ')}>',
        ),
    };

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
      parsedLibResult: parsedLibResult,
      customGetter: customGetter,
      methodName: methodName,
    );

    if (annotationFields != null && inClassResult != null) {
      throw InvalidGenerationSourceError(
        "Fields cannot be specified in both @Cloneable(fields: ...) and the '${inClassResult.getterName}' getter in class '${element.name}'.",
        element: element,
      );
    }

    final allowedFields = annotationFields ?? inClassResult?.fields;
    final whitelistSource = annotationFields != null
        ? '@Cloneable(fields: ...)'
        : inClassResult?.getterName;

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

      final isWhitelisted =
          allowedFields == null || allowedFields.contains(param.name);
      final isIgnored = !isWhitelisted || _isFieldIgnored(param, field);
      final fieldDeepCopy = _getFieldDeepCopy(param, field);
      final shouldDeepCopy = fieldDeepCopy ?? classDeepCopy;
      final fieldIgnoreNull = _getFieldIgnoreNull(param, field);
      final shouldIgnoreNull = fieldIgnoreNull ?? classIgnoreNull;
      final collectionKind = _getCollectionKind(param.type);

      final isNullable =
          param.type.nullabilitySuffix == NullabilitySuffix.question ||
              param.type is DynamicType ||
              param.type.isDartCoreNull;

      params.add(
        _FieldInfo(
          name: param.name,
          type: param.type.getDisplayString(withNullability: true),
          isNullable: isNullable,
          isNamed: param.isNamed,
          isRequired: param.isRequiredNamed || param.isRequiredPositional,
          isIgnored: isIgnored,
          shouldDeepCopy: shouldDeepCopy,
          shouldIgnoreNull: shouldIgnoreNull,
          collectionKind: collectionKind,
        ),
      );
    }

    return _generateCode(
      className: element.name,
      constructorName: constructorName,
      typeParamsWithBounds: typeParamsWithBounds,
      typeParamsArgs: typeParamsArgs,
      fields: params,
      useExtension: useExtension,
      mixinName: detectedMixinName ?? '_\$${element.name}Cloneable',
      methodName: methodName,
      hasPartDirective: hasPartDirective,
      inputFileName: inputFileName,
      sentinelExpr: sentinelExpr,
      sentinelDeclaration: sentinelDeclaration,
      isInline: isInline,
    );
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

  _CollectionKind _getCollectionKind(DartType type) => switch (type) {
        _ when type.isDartCoreList || type.element?.name == 'List' =>
          _CollectionKind.list,
        _ when type.isDartCoreSet || type.element?.name == 'Set' =>
          _CollectionKind.set,
        _ when type.isDartCoreMap || type.element?.name == 'Map' =>
          _CollectionKind.map,
        _ when type.isDartCoreIterable || type.element?.name == 'Iterable' =>
          _CollectionKind.iterable,
        _ => _CollectionKind.none,
      };

  String _generateCode({
    required String className,
    required String? constructorName,
    required String typeParamsWithBounds,
    required String typeParamsArgs,
    required List<_FieldInfo> fields,
    required bool useExtension,
    required String mixinName,
    required String methodName,
    required bool hasPartDirective,
    required String inputFileName,
    required String sentinelExpr,
    required String sentinelDeclaration,
    required bool isInline,
  }) {
    final capitalizedMethod = methodName.isEmpty
        ? ''
        : '${methodName[0].toUpperCase()}${methodName.substring(1)}';
    final copyWithTypedefName = '\$$className$capitalizedMethod';
    final targetClassType = '$className$typeParamsArgs';
    final copyWithTypedefWithArgs = '$copyWithTypedefName$typeParamsArgs';
    final privateMethodName = '_$methodName';

    final standaloneHeader = switch (isInline || hasPartDirective) {
      true => '',
      false => '''
import 'package:cloneable/cloneable.dart';
import '$inputFileName';

''',
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

    // Generate mixin/extension private method parameters
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

    for (final field in fields) {
      final valExpr = switch (field) {
        _ when field.isIgnored => 'self.${field.name}',
        _
            when field.shouldDeepCopy &&
                field.collectionKind != _CollectionKind.none =>
          _generateDeepCopyExpression(field, sentinelExpr: sentinelExpr),
        _ when field.shouldIgnoreNull =>
          'identical(${field.name}, $sentinelExpr) || ${field.name} == null ? self.${field.name} : ${field.name} as ${field.type}',
        _ =>
          'identical(${field.name}, $sentinelExpr) ? self.${field.name} : ${field.name} as ${field.type}',
      };

      if (field.isNamed) {
        constructorArgsBuffer.writeln('      ${field.name}: $valExpr,');
      } else {
        constructorArgsBuffer.writeln('      $valExpr,');
      }
    }

    final implementation = switch (useExtension) {
      true => '''
/// Generated cloneable extension for [$className].
extension \$${className}CloneableExtension$typeParamsWithBounds on $targetClassType {
$sentinelDeclaration  $copyWithTypedefWithArgs get $methodName => $privateMethodName;

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
$sentinelDeclaration  $copyWithTypedefWithArgs get $methodName => $privateMethodName;

  $targetClassType $privateMethodName({
$callParamsBuffer  }) {
    final self = this as $targetClassType;
    return $constructorCall(
$constructorArgsBuffer    );
  }
}
''',
    };

    return '''
$standaloneHeader/// Strongly-typed $methodName function signature for [$className].
typedef $copyWithTypedefName$typeParamsWithBounds = $targetClassType Function({
$typedefParamsBuffer});

$implementation''';
  }

  String _generateDeepCopyExpression(
    _FieldInfo field, {
    required String sentinelExpr,
  }) {
    final name = field.name;
    final type = field.type;
    final nonNullableType =
        type.endsWith('?') ? type.substring(0, type.length - 1) : type;

    final factoryMethod = switch (field.collectionKind) {
      _CollectionKind.list || _CollectionKind.iterable => 'List.of',
      _CollectionKind.set => 'Set.of',
      _CollectionKind.map => 'Map.of',
      _CollectionKind.none => null,
    };

    if (factoryMethod == null) {
      return 'identical($name, $sentinelExpr) ? self.$name : $name as $type';
    }

    return switch ((field.shouldIgnoreNull, field.isNullable)) {
      (true, true) => '''(identical($name, $sentinelExpr) || $name == null)
          ? (self.$name == null ? null : $factoryMethod(self.$name!))
          : $factoryMethod($name as $nonNullableType)''',
      (true, false) => '''(identical($name, $sentinelExpr) || $name == null)
          ? $factoryMethod(self.$name)
          : $factoryMethod($name as $type)''',
      (false, true) => '''identical($name, $sentinelExpr)
          ? (self.$name == null ? null : $factoryMethod(self.$name!))
          : ($name == null ? null : $factoryMethod($name as $nonNullableType))''',
      (false, false) => '''identical($name, $sentinelExpr)
          ? $factoryMethod(self.$name)
          : $factoryMethod($name as $type)''',
    };
  }

  ({String getterName, List<String> fields})? _findInClassFields({
    required ClassElement element,
    required ConstructorElement constructor,
    required SomeParsedLibraryResult? parsedLibResult,
    required String? customGetter,
    required String methodName,
  }) {
    ClassDeclaration? classDecl;
    if (parsedLibResult case ParsedLibraryResult parsedLib) {
      if (parsedLib.getElementDeclaration(element)?.node
          case ClassDeclaration decl) {
        classDecl = decl;
      }
    }

    if (classDecl == null) {
      try {
        final parseResult = parseString(
          content: element.source.contents.data,
          throwIfDiagnostics: false,
        );
        for (final decl in parseResult.unit.declarations) {
          if (decl is ClassDeclaration && decl.name.lexeme == element.name) {
            classDecl = decl;
            break;
          }
        }
      } catch (_) {
        // Fall back to null if parsing fails
      }
    }

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
  });
}
