import 'package:analyzer/dart/analysis/results.dart';
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
class CloneableGenerator extends GeneratorForAnnotation<Cloneable> {
  const CloneableGenerator();

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement || element is EnumElement) {
      throw InvalidGenerationSourceError(
        'The @Cloneable() annotation can only be applied to classes.',
        element: element,
      );
    }

    if (element.isAbstract) {
      throw InvalidGenerationSourceError(
        'The @Cloneable() annotation cannot be applied to abstract classes.',
        element: element,
      );
    }

    // Verify part directive
    final library = element.library;
    final expectedPartName =
        buildStep.inputId.changeExtension('.g.dart').pathSegments.last;
    bool hasPartDirective = library.parts.any(
      (part) =>
          part.toString().contains(expectedPartName) ||
          part.toString().endsWith(expectedPartName),
    );

    if (!hasPartDirective) {
      final parsedLib =
          element.session?.getParsedLibraryByElement(element.library);
      if (parsedLib is ParsedLibraryResult) {
        for (final unit in parsedLib.units) {
          for (final directive in unit.unit.directives) {
            if (directive is PartDirective &&
                directive.uri.stringValue == expectedPartName) {
              hasPartDirective = true;
              break;
            }
          }
        }
      }
    }

    if (!hasPartDirective) {
      final source = element.source.contents.data;
      hasPartDirective = source.contains("part '$expectedPartName';") ||
          source.contains('part "$expectedPartName";');
    }

    if (!hasPartDirective) {
      throw InvalidGenerationSourceError(
        "The file '${buildStep.inputId.path}' must include the part directive:\n"
        "    part '$expectedPartName';",
        element: element,
      );
    }

    // Verify mixin
    final expectedMixinName = '_\$${element.name}Cloneable';
    bool hasMixin = element.mixins.any(
      (m) =>
          m.element.name == expectedMixinName ||
          m
              .getDisplayString(withNullability: false)
              .startsWith(expectedMixinName),
    );

    if (!hasMixin) {
      final parsedLib =
          element.session?.getParsedLibraryByElement(element.library);
      if (parsedLib is ParsedLibraryResult) {
        final decl = parsedLib.getElementDeclaration(element);
        final node = decl?.node;
        if (node is ClassDeclaration && node.withClause != null) {
          hasMixin = node.withClause!.mixinTypes.any(
            (m) => m.name2.lexeme == expectedMixinName,
          );
        }
      }
    }

    if (!hasMixin) {
      final source = element.source.contents.data;
      hasMixin = source.contains('with $expectedMixinName') ||
          source.contains(expectedMixinName);
    }

    // Strategy configuration
    CloneableStrategy strategy = CloneableStrategy.auto;
    final strategyField = annotation.peek('strategy');
    if (strategyField != null && !strategyField.isNull) {
      final index = strategyField.objectValue.getField('index')?.toIntValue();
      if (index != null &&
          index >= 0 &&
          index < CloneableStrategy.values.length) {
        strategy = CloneableStrategy.values[index];
      }
    }

    final bool useExtension;
    switch (strategy) {
      case CloneableStrategy.mixin:
        if (!hasMixin) {
          throw InvalidGenerationSourceError(
            "Class '${element.name}' is configured with CloneableStrategy.mixin but does not mix in '$expectedMixinName'.\n"
            "Example:\n"
            "    class ${element.name} with $expectedMixinName { ... }\n"
            "Or use CloneableStrategy.extension / CloneableStrategy.auto to generate an extension without the mixin.",
            element: element,
          );
        }
        useExtension = false;
        break;
      case CloneableStrategy.extension:
        useExtension = true;
        break;
      case CloneableStrategy.auto:
        useExtension = !hasMixin;
        break;
    }

    // Class-level configuration
    final constructorName = annotation.peek('constructor')?.stringValue;
    final classDeepCopy =
        annotation.peek('deepCopyCollections')?.boolValue ?? false;

    // Resolve constructor
    ConstructorElement? constructor;
    if (constructorName == null || constructorName.isEmpty) {
      constructor = element.unnamedConstructor;
      if (constructor == null) {
        throw InvalidGenerationSourceError(
          "Class '${element.name}' does not have an unnamed constructor.",
          element: element,
        );
      }
    } else {
      constructor = element.getNamedConstructor(constructorName);
      if (constructor == null) {
        throw InvalidGenerationSourceError(
          "Class '${element.name}' does not have a constructor named '$constructorName'.",
          element: element,
        );
      }
    }

    // Generic type parameters
    final typeParamsWithBounds = element.typeParameters.isEmpty
        ? ''
        : '<${element.typeParameters.map((p) => p.getDisplayString(withNullability: true)).join(', ')}>';
    final typeParamsArgs = element.typeParameters.isEmpty
        ? ''
        : '<${element.typeParameters.map((p) => p.name).join(', ')}>';

    // Process parameters
    final params = <_FieldInfo>[];
    for (final param in constructor.parameters) {
      final field = element.getField(param.name) ??
          element.getGetter(param.name)?.variable;

      if (field == null) {
        throw InvalidGenerationSourceError(
          "Constructor parameter '${param.name}' does not match any field or getter in class '${element.name}'.",
          element: param,
        );
      }

      final isIgnored = _isFieldIgnored(param, field);
      final fieldDeepCopy = _getFieldDeepCopy(param, field);
      final shouldDeepCopy = fieldDeepCopy ?? classDeepCopy;
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
    );
  }

  bool _isFieldIgnored(ParameterElement param, Element field) {
    const checker = TypeChecker.fromRuntime(CloneableField);
    final paramAnnotation = checker.firstAnnotationOf(param);
    if (paramAnnotation != null) {
      final reader = ConstantReader(paramAnnotation);
      if (reader.peek('ignore')?.boolValue == true) return true;
    }

    final fieldAnnotation = checker.firstAnnotationOf(field);
    if (fieldAnnotation != null) {
      final reader = ConstantReader(fieldAnnotation);
      if (reader.peek('ignore')?.boolValue == true) return true;
    }

    return false;
  }

  bool? _getFieldDeepCopy(ParameterElement param, Element field) {
    const checker = TypeChecker.fromRuntime(CloneableField);
    final paramAnnotation = checker.firstAnnotationOf(param);
    if (paramAnnotation != null) {
      final reader = ConstantReader(paramAnnotation);
      final deepCopy = reader.peek('deepCopy')?.boolValue;
      if (deepCopy != null) return deepCopy;
    }

    final fieldAnnotation = checker.firstAnnotationOf(field);
    if (fieldAnnotation != null) {
      final reader = ConstantReader(fieldAnnotation);
      final deepCopy = reader.peek('deepCopy')?.boolValue;
      if (deepCopy != null) return deepCopy;
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
    return _CollectionKind.none;
  }

  String _generateCode({
    required String className,
    required String? constructorName,
    required String typeParamsWithBounds,
    required String typeParamsArgs,
    required List<_FieldInfo> fields,
    required bool useExtension,
  }) {
    final copyWithTypedefName = '\$${className}CopyWith';
    final mixinName = '_\$${className}Cloneable';
    final targetClassType = '$className$typeParamsArgs';
    final copyWithTypedefWithArgs = '$copyWithTypedefName$typeParamsArgs';

    // Filter fields accepted in copyWith call (exclude ignored ones)
    final copyFields = fields.where((f) => !f.isIgnored).toList();

    // Generate typedef function parameters
    final typedefParamsBuffer = StringBuffer();
    for (final field in copyFields) {
      typedefParamsBuffer.writeln('    ${field.type} ${field.name},');
    }

    // Generate mixin/extension _copyWith method parameters
    final callParamsBuffer = StringBuffer();
    for (final field in copyFields) {
      callParamsBuffer.writeln(
        '    Object? ${field.name} = cloneableUndefined,',
      );
    }

    // Generate constructor invocation arguments
    final constructorArgsBuffer = StringBuffer();
    final constructorCall = constructorName == null || constructorName.isEmpty
        ? '$className$typeParamsArgs'
        : '$className$typeParamsArgs.$constructorName';

    for (final field in fields) {
      final String valExpr;

      if (field.isIgnored) {
        valExpr = 'self.${field.name}';
      } else if (field.shouldDeepCopy &&
          field.collectionKind != _CollectionKind.none) {
        valExpr = _generateDeepCopyExpression(field);
      } else {
        valExpr =
            'identical(${field.name}, cloneableUndefined) ? self.${field.name} : ${field.name} as ${field.type}';
      }

      if (field.isNamed) {
        constructorArgsBuffer.writeln('      ${field.name}: $valExpr,');
      } else {
        constructorArgsBuffer.writeln('      $valExpr,');
      }
    }

    final String implementation;
    if (useExtension) {
      final extensionName = '\$${className}CloneableExtension';
      implementation = '''
/// Generated cloneable extension for [$className].
extension $extensionName$typeParamsWithBounds on $targetClassType {
  $copyWithTypedefWithArgs get copyWith => _copyWith;

  $targetClassType _copyWith({
$callParamsBuffer  }) {
    final self = this;
    return $constructorCall(
$constructorArgsBuffer    );
  }
}
''';
    } else {
      implementation = '''
/// Generated cloneable mixin for [$className].
mixin $mixinName$typeParamsWithBounds {
  $copyWithTypedefWithArgs get copyWith => _copyWith;

  $targetClassType _copyWith({
$callParamsBuffer  }) {
    final self = this as $targetClassType;
    return $constructorCall(
$constructorArgsBuffer    );
  }
}
''';
    }

    return '''
/// Strongly-typed copyWith function signature for [$className].
typedef $copyWithTypedefName$typeParamsWithBounds = $targetClassType Function({
$typedefParamsBuffer});

$implementation''';
  }

  String _generateDeepCopyExpression(_FieldInfo field) {
    final name = field.name;
    final type = field.type;
    final nonNullableType =
        type.endsWith('?') ? type.substring(0, type.length - 1) : type;

    final String factoryMethod;
    switch (field.collectionKind) {
      case _CollectionKind.list:
      case _CollectionKind.iterable:
        factoryMethod = 'List.of';
        break;
      case _CollectionKind.set:
        factoryMethod = 'Set.of';
        break;
      case _CollectionKind.map:
        factoryMethod = 'Map.of';
        break;
      case _CollectionKind.none:
        return 'identical($name, cloneableUndefined) ? self.$name : $name as $type';
    }

    if (field.isNullable) {
      return '''identical($name, cloneableUndefined)
          ? (self.$name == null ? null : $factoryMethod(self.$name!))
          : ($name == null ? null : $factoryMethod($name as $nonNullableType))''';
    } else {
      return '''identical($name, cloneableUndefined)
          ? $factoryMethod(self.$name)
          : $factoryMethod($name as $type)''';
    }
  }
}

class _FieldInfo {
  final String name;
  final String type;
  final bool isNullable;
  final bool isNamed;
  final bool isRequired;
  final bool isIgnored;
  final bool shouldDeepCopy;
  final _CollectionKind collectionKind;

  _FieldInfo({
    required this.name,
    required this.type,
    required this.isNullable,
    required this.isNamed,
    required this.isRequired,
    required this.isIgnored,
    required this.shouldDeepCopy,
    required this.collectionKind,
  });
}
