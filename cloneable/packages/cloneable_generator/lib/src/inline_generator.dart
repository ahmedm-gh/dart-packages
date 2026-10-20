import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:cloneable/cloneable.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

import 'cloneable_generator.dart';
import 'config_loader.dart';

extension _ClassDeclarationHelper on ClassDeclaration {
  BlockClassBody? get asBlockBody =>
      body is BlockClassBody ? body as BlockClassBody : null;
  Token get leftBracket => asBlockBody!.leftBracket;
  Token get rightBracket => asBlockBody!.rightBracket;
  List<ClassMember> get members => asBlockBody?.members ?? const [];
}

extension _NamedTypeHelper on NamedType {
  String get typeName => name.lexeme;
}

/// The result of executing [CloneableGeneratorRunner.run].
final class CloneableResult {
  /// The total number of files scanned.
  final int scannedCount;

  /// The list of normalized file paths that were modified or created.
  final List<String> updatedFiles;

  /// The list of normalized file paths that were deleted (e.g. obsolete part files).
  final List<String> deletedFiles;

  /// Creates a [CloneableResult] with the scan and modification statistics.
  const CloneableResult({
    required this.scannedCount,
    required this.updatedFiles,
    this.deletedFiles = const [],
  });
}

final class _FileEdit {
  final int offset;
  final int end;
  final String text;

  const _FileEdit({
    required this.offset,
    required this.end,
    required this.text,
  });
}

/// Comprehensive standalone code generator runner for `@Cloneable`.
///
/// Can generate code both:
/// - **Inline**: directly inside the model file (in-library or in-class).
/// - **External / Part files**: directly into `*.g.dart` or `*.cloneable.dart` files.
///
/// Completely independent of `build_runner`.
final class CloneableGeneratorRunner {
  static const _cloneableTypeChecker =
      TypeChecker.fromUrl('package:cloneable/cloneable.dart#Cloneable');

  final DartFormatter _formatter;
  final CloneableGenerator _generator;

  /// Creates a [CloneableGeneratorRunner] with an optional custom [DartFormatter]
  /// and [CloneableGenerator].
  CloneableGeneratorRunner({
    DartFormatter? formatter,
    CloneableGenerator? generator,
  })  : _formatter = formatter ??
            DartFormatter(
              languageVersion: DartFormatter.latestLanguageVersion,
            ),
        _generator = generator ?? const CloneableGenerator();

  /// Updates [content] with generated code blocks for the classes in [classCodeMap].
  ///
  /// For each entry:
  /// - If the value is a non-empty [String], the marker block for that class is updated
  ///   or appended at the end of the file.
  /// - If the value is `null` or empty, any existing marker block for that class is removed.
  ///
  /// If [format] is `true`, the resulting source code is formatted using [DartFormatter].
  String updateContent({
    required String content,
    required Map<String, String?> classCodeMap,
    bool format = true,
  }) {
    var updated = content;

    for (final entry in classCodeMap.entries) {
      final className = entry.key;
      final code = entry.value;
      final pattern = CloneableGenerator.markerPattern(className);
      final typedefPattern = CloneableGenerator.typedefMarkerPattern(className);

      if (code != null && code.trim().isNotEmpty) {
        final wrapped = CloneableGenerator.wrapWithMarkers(className, code);
        if (pattern.hasMatch(updated)) {
          updated = updated.replaceFirst(pattern, wrapped);
        } else {
          updated = '${updated.trimRight()}\n$wrapped\n';
        }
      } else {
        if (pattern.hasMatch(updated)) {
          updated = updated.replaceFirst(pattern, '');
        }
        if (typedefPattern.hasMatch(updated)) {
          updated = updated.replaceFirst(typedefPattern, '');
        }
      }
    }

    if (format) {
      try {
        updated = _formatter.format(updated);
      } catch (_) {
        // Fallback to unformatted if formatting fails
      }
    }

    return updated;
  }

  /// Processes a resolved AST unit, updating inline code blocks and external part files as needed.
  ///
  /// Returns a record containing the list of updated and deleted file paths.
  Future<({List<String> updated, List<String> deleted})>
      processResolvedUnitDetails({
    required ResolvedUnitResult unitResult,
    required String filePath,
    bool inlineOnly = false,
    bool partFilesOnly = false,
  }) async {
    final updated = <String>[];
    final deleted = <String>[];
    final content = unitResult.content;

    // Detect existing marker blocks for inline classes
    final existingMarkerClasses = <String>{};
    for (final match
        in CloneableGenerator.allMarkersPattern.allMatches(content)) {
      if (match.group(1)?.trim() case final name? when name.isNotEmpty) {
        existingMarkerClasses.add(name);
      }
    }
    for (final match
        in CloneableGenerator.allTypedefMarkersPattern.allMatches(content)) {
      if (match.group(1)?.trim() case final name? when name.isNotEmpty) {
        existingMarkerClasses.add(name);
      }
    }

    final inlineClassCodeMap = <String, String?>{};
    final partFileCodes = <String>[];
    final declaredSentinels = <String>{};
    String? matchedPartName;

    // Look for part directives in the source file AST
    for (final directive in unitResult.unit.directives) {
      if (directive is PartDirective && directive.uri.stringValue != null) {
        final uriStr = directive.uri.stringValue!;
        if (uriStr.endsWith('.dart')) {
          matchedPartName = uriStr;
          break;
        }
      }
    }

    var hasPartDirective = matchedPartName != null;
    final projectDefaults = ConfigLoader.findProjectSsotDefaults(filePath);
    final defaultFileAffix =
        projectDefaults?.file ?? CloneableNaming.defaultFile;
    final defaultFilePrefix = defaultFileAffix.prefix ?? '';
    final defaultFileSuffix = defaultFileAffix.suffix ?? '.cloneable.g';
    final cleanDefaultSuffix = defaultFileSuffix.endsWith('.dart')
        ? defaultFileSuffix
        : '$defaultFileSuffix.dart';
    final defaultDir = projectDefaults?.directory;
    final cleanDefaultDir = (defaultDir != null && defaultDir.trim().isNotEmpty)
        ? '${p.normalize(defaultDir).replaceAll('\\', '/')}/'
        : '';
    var targetPartFileName = matchedPartName ??
        '$cleanDefaultDir$defaultFilePrefix${p.basenameWithoutExtension(filePath)}$cleanDefaultSuffix';

    final edits = <_FileEdit>[];
    var fileNeedsPartDirective = false;
    String? desiredPartFileName;
    var fileNeedsPackageSentinel = false;
    final injectedMixins = <String>{};

    final removedClasses = <String>{};
    final activeAnnotatedClasses = <String>{};

    for (final declaration in unitResult.unit.declarations) {
      if (declaration is! ClassDeclaration) continue;
      final element = declaration.declaredFragment?.element;
      if (element == null) continue;

      ConstantReader? annotationReader;
      try {
        if (_cloneableTypeChecker.firstAnnotationOf(element) case final obj?) {
          annotationReader = ConstantReader(obj);
        }
      } catch (_) {}

      if (annotationReader == null) {
        for (final meta in element.metadata.annotations) {
          try {
            if (meta.computeConstantValue() case final val?
                when val.type?.element?.name == 'Cloneable') {
              annotationReader = ConstantReader(val);
              break;
            }
          } catch (_) {}
        }
      }

      // Check AST annotation for dot-shorthands
      RawCloneableConfig? astConfig;
      for (final meta in declaration.metadata) {
        final name = meta.name.toSource();
        if (name == 'Cloneable' || name.startsWith('Cloneable.')) {
          astConfig = AstConfigReader.parseFromAnnotationAst(meta);
          break;
        }
      }

      if (annotationReader == null && astConfig == null) continue;

      final resolvedDefaults = ConfigLoader.resolveDefaults(
        library: element.library,
        classElement: element,
        filePath: filePath,
      );

      final rawActiveness = annotationReader?.peek('activeness') != null
          ? switch (annotationReader!
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
          annotationReader?.peek('active')?.boolValue ?? astConfig?.active;

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

      if (!isActive) continue;
      if (element.name == null) continue;

      final className = element.name!;
      activeAnnotatedClasses.add(className);

      final output = switch (annotationReader
          ?.peek('output')
          ?.objectValue
          .getField('index')
          ?.toIntValue()) {
        final index? when index >= 0 && index < CloneableOutput.values.length =>
          CloneableOutput.values[index],
        _ => astConfig?.output ?? resolvedDefaults.output,
      };

      final strategy = switch (annotationReader
          ?.peek('strategy')
          ?.objectValue
          .getField('index')
          ?.toIntValue()) {
        final index?
            when index >= 0 && index < CloneableStrategy.values.length =>
          CloneableStrategy.values[index],
        _ => astConfig?.strategy ?? resolvedDefaults.strategy,
      };

      final sentinel = switch (annotationReader
          ?.peek('sentinel')
          ?.objectValue
          .getField('index')
          ?.toIntValue()) {
        final index?
            when index >= 0 && index < CloneableSentinel.values.length =>
          CloneableSentinel.values[index],
        _ => astConfig?.sentinel ?? resolvedDefaults.sentinel,
      };

      final isInline = output.isInline;

      if (!isInline && sentinel != CloneableSentinel.private) {
        fileNeedsPackageSentinel = true;
      }

      // Auto-inject missing mixin if strategy: CloneableStrategy.mixin
      if (strategy == CloneableStrategy.mixin &&
          output != CloneableOutput.inClass) {
        var hasMixin = false;
        if (declaration.withClause != null) {
          for (final mixinType in declaration.withClause!.mixinTypes) {
            final name = mixinType.typeName;
            if (name.contains(element.name!) || name.startsWith(r'_$')) {
              hasMixin = true;
              break;
            }
          }
        }

        if (!hasMixin) {
          injectedMixins.add(className);
          final namingReader = annotationReader?.peek('naming');
          final mixinAffix = namingReader?.peek('mixin');
          final rawMixinPrefix = mixinAffix?.peek('prefix')?.stringValue;
          final rawMixinSuffix = mixinAffix?.peek('suffix')?.stringValue;
          final defaultMixinPrefix = astConfig?.mixin?.prefix ??
              resolvedDefaults.mixin.prefix ??
              CloneableNaming.defaultMixin.prefix ??
              '';
          final defaultMixinSuffix = astConfig?.mixin?.suffix ??
              resolvedDefaults.mixin.suffix ??
              CloneableNaming.defaultMixin.suffix ??
              '';

          final isDefaultMixin = mixinAffix != null &&
              rawMixinPrefix == CloneableNaming.defaultMixin.prefix &&
              rawMixinSuffix == CloneableNaming.defaultMixin.suffix;

          final mixinPrefix = isDefaultMixin
              ? defaultMixinPrefix
              : switch (rawMixinPrefix) {
                  '' => '',
                  final p? => p,
                  _ => defaultMixinPrefix,
                };
          final mixinSuffix = isDefaultMixin
              ? defaultMixinSuffix
              : switch (rawMixinSuffix) {
                  '' => '',
                  final s? => s,
                  _ => defaultMixinSuffix,
                };
          final mixinName = (mixinPrefix.startsWith('_') || mixinPrefix.isEmpty)
              ? '$mixinPrefix${element.name}$mixinSuffix'
              : '${r'_$'}$mixinPrefix${element.name}$mixinSuffix';
          final typeArgs = element.typeParameters.isEmpty
              ? ''
              : '<${element.typeParameters.map((p) => p.name).join(', ')}>';
          final mixinWithArgs = '$mixinName$typeArgs';

          if (declaration.withClause != null) {
            edits.add(_FileEdit(
              offset: declaration.withClause!.end,
              end: declaration.withClause!.end,
              text: ', $mixinWithArgs',
            ));
          } else if (declaration.implementsClause != null) {
            edits.add(_FileEdit(
              offset: declaration.implementsClause!.offset,
              end: declaration.implementsClause!.offset,
              text: 'with $mixinWithArgs ',
            ));
          } else {
            edits.add(_FileEdit(
              offset: declaration.leftBracket.offset,
              end: declaration.leftBracket.offset,
              text: 'with $mixinWithArgs ',
            ));
          }
        }
      }

      // Check if file needs a part directive
      if (!isInline) {
        if (output == CloneableOutput.part ||
            strategy == CloneableStrategy.mixin) {
          final namingReader = annotationReader?.peek('naming');
          final directory = namingReader?.peek('directory')?.stringValue ??
              astConfig?.directory ??
              resolvedDefaults.directory;
          final fileAffix = namingReader?.peek('file');
          final rawFilePrefix = fileAffix?.peek('prefix')?.stringValue;
          final rawFileSuffix = fileAffix?.peek('suffix')?.stringValue;
          final defaultFilePrefix = astConfig?.file?.prefix ??
              resolvedDefaults.file.prefix ??
              CloneableNaming.defaultFile.prefix ??
              '';
          final defaultFileSuffix = astConfig?.file?.suffix ??
              resolvedDefaults.file.suffix ??
              CloneableNaming.defaultFile.suffix ??
              '';

          final isDefaultFile = fileAffix != null &&
              rawFilePrefix == CloneableNaming.defaultFile.prefix &&
              rawFileSuffix == CloneableNaming.defaultFile.suffix;

          final filePrefix = isDefaultFile
              ? defaultFilePrefix
              : (rawFilePrefix ?? defaultFilePrefix);
          final fileSuffix = isDefaultFile
              ? defaultFileSuffix
              : (rawFileSuffix ?? defaultFileSuffix);

          final cleanSuffix =
              fileSuffix.endsWith('.dart') ? fileSuffix : '$fileSuffix.dart';
          final cleanDir = (directory != null && directory.trim().isNotEmpty)
              ? '${p.normalize(directory).replaceAll('\\', '/')}/'
              : '';
          desiredPartFileName =
              '$cleanDir$filePrefix${p.basenameWithoutExtension(filePath)}$cleanSuffix';

          if (!hasPartDirective) {
            fileNeedsPartDirective = true;
          }
        }
      }
    }

    if (fileNeedsPartDirective && desiredPartFileName != null) {
      final partDirectiveStr = "part '$desiredPartFileName';";
      var insertionOffset = 0;
      var insertionText = '$partDirectiveStr\n\n';

      final directives = unitResult.unit.directives;
      ImportDirective? lastImport;
      for (final dir in directives) {
        if (dir is ImportDirective) {
          lastImport = dir;
        }
      }

      if (lastImport != null) {
        insertionOffset = lastImport.end;
        insertionText = '\n\n$partDirectiveStr';
      } else if (directives.isNotEmpty) {
        insertionOffset = directives.last.end;
        insertionText = '\n\n$partDirectiveStr';
      }

      edits.add(_FileEdit(
        offset: insertionOffset,
        end: insertionOffset,
        text: insertionText,
      ));

      hasPartDirective = true;
      targetPartFileName = desiredPartFileName;
    }

    final targetPartFilePath =
        p.normalize(p.join(p.dirname(filePath), targetPartFileName));

    // Process each class declaration for code generation and auto-removal
    for (final declaration in unitResult.unit.declarations) {
      if (declaration is! ClassDeclaration) continue;

      final element = declaration.declaredFragment?.element;
      if (element == null || element.name == null) continue;

      final className = element.name!;

      ConstantReader? annotationReader;
      try {
        if (_cloneableTypeChecker.firstAnnotationOf(element) case final obj?) {
          annotationReader = ConstantReader(obj);
        }
      } catch (_) {}

      if (annotationReader == null) {
        for (final meta in element.metadata.annotations) {
          try {
            if (meta.computeConstantValue() case final val?
                when val.type?.element?.name == 'Cloneable') {
              annotationReader = ConstantReader(val);
              break;
            }
          } catch (_) {}
        }
      }

      RawCloneableConfig? astConfig;
      for (final meta in declaration.metadata) {
        final name = meta.name.toSource();
        if (name == 'Cloneable' || name.startsWith('Cloneable.')) {
          astConfig = AstConfigReader.parseFromAnnotationAst(meta);
          break;
        }
      }

      if (annotationReader != null || astConfig != null) {
        final effectiveReader = annotationReader ??
            ConstantReader(null); // safely handled via astConfig fallback

        final resolvedDefaults = ConfigLoader.resolveDefaults(
          library: element.library,
          classElement: element,
          filePath: filePath,
        );

        final rawActiveness = annotationReader?.peek('activeness') != null
            ? switch (annotationReader!
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
            annotationReader?.peek('active')?.boolValue ?? astConfig?.active;

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

        final output = switch (annotationReader
            ?.peek('output')
            ?.objectValue
            .getField('index')
            ?.toIntValue()) {
          final index?
              when index >= 0 && index < CloneableOutput.values.length =>
            CloneableOutput.values[index],
          _ => astConfig?.output ?? resolvedDefaults.output,
        };
        final isInline = output.isInline;

        final sentinel = switch (annotationReader
            ?.peek('sentinel')
            ?.objectValue
            .getField('index')
            ?.toIntValue()) {
          final index?
              when index >= 0 && index < CloneableSentinel.values.length =>
            CloneableSentinel.values[index],
          _ => astConfig?.sentinel ?? resolvedDefaults.sentinel,
        };

        final cleanup = switch (annotationReader
            ?.peek('cleanup')
            ?.objectValue
            .getField('index')
            ?.toIntValue()) {
          final index?
              when index >= 0 && index < CloneableCleanup.values.length =>
            CloneableCleanup.values[index],
          _ => astConfig?.cleanup ?? resolvedDefaults.cleanup,
        };
        final shouldRemove = cleanup == CloneableCleanup.remove &&
            sentinel == CloneableSentinel.private;
        final shouldDeactivate = cleanup == CloneableCleanup.deactivate;

        void deactivateAnnotation() {
          for (final meta in declaration.metadata) {
            if (meta.name.name == 'Cloneable' ||
                meta.name.name.startsWith('Cloneable.')) {
              if (meta.arguments == null) {
                edits.add(_FileEdit(
                  offset: meta.end,
                  end: meta.end,
                  text: '(active: false)',
                ));
              } else {
                final args = meta.arguments!;
                AstNode? activeArg;
                AstNode? activeExpr;
                for (final arg in args.arguments) {
                  final (name, expr) = AstConfigReader.getArgumentInfo(arg);
                  if (name == 'active') {
                    activeArg = arg;
                    activeExpr = expr;
                    break;
                  }
                }
                if (activeArg != null && activeExpr != null) {
                  edits.add(_FileEdit(
                    offset: activeExpr.offset,
                    end: activeExpr.end,
                    text: 'false',
                  ));
                } else if (args.arguments.isEmpty) {
                  edits.add(_FileEdit(
                    offset: args.leftParenthesis.end,
                    end: args.rightParenthesis.offset,
                    text: 'active: false',
                  ));
                } else {
                  edits.add(_FileEdit(
                    offset: args.leftParenthesis.end,
                    end: args.leftParenthesis.end,
                    text: 'active: false, ',
                  ));
                }
              }
            }
          }
        }

        void cleanInClassMembers() {
          var removedMarker = false;
          for (final m in CloneableGenerator.markerPattern(className)
              .allMatches(content)) {
            if (m.start >= declaration.leftBracket.offset &&
                m.end <= declaration.rightBracket.offset) {
              edits.add(_FileEdit(offset: m.start, end: m.end, text: ''));
              removedMarker = true;
            }
          }
          for (final m in CloneableGenerator.typedefMarkerPattern(className)
              .allMatches(content)) {
            edits.add(_FileEdit(offset: m.start, end: m.end, text: ''));
          }
          if (!removedMarker) {
            for (final member in declaration.members) {
              if (member is FieldDeclaration &&
                  member.fields.variables.any((v) =>
                      v.name.lexeme == r'_$undefined' ||
                      v.name.lexeme == r'$undefined')) {
                var memberEnd = member.end;
                while (memberEnd < content.length &&
                    (content[memberEnd] == ' ' ||
                        content[memberEnd] == '\t' ||
                        content[memberEnd] == '\r' ||
                        content[memberEnd] == '\n')) {
                  final isNewline = content[memberEnd] == '\n';
                  memberEnd++;
                  if (isNewline) break;
                }
                edits.add(_FileEdit(
                  offset: member.offset,
                  end: memberEnd,
                  text: '',
                ));
              }
              if (member is MethodDeclaration) {
                final name = member.name.lexeme;
                final isGeneratedMethod = name == '_copyWith' ||
                    name == '_${resolvedDefaults.method}';
                final isGeneratedGetter = member.isGetter &&
                    (name == 'copyWith' || name == resolvedDefaults.method) &&
                    member.toSource().contains('_copyWith');
                if (isGeneratedMethod || isGeneratedGetter) {
                  var memberEnd = member.end;
                  while (memberEnd < content.length &&
                      (content[memberEnd] == ' ' ||
                          content[memberEnd] == '\t' ||
                          content[memberEnd] == '\r' ||
                          content[memberEnd] == '\n')) {
                    final isNewline = content[memberEnd] == '\n';
                    memberEnd++;
                    if (isNewline) break;
                  }
                  edits.add(_FileEdit(
                    offset: member.offset,
                    end: memberEnd,
                    text: '',
                  ));
                }
              }
            }
          }
        }

        void cleanOutsideMarkers() {
          for (final m in CloneableGenerator.markerPattern(className)
              .allMatches(content)) {
            if (m.start < declaration.offset ||
                m.end > declaration.rightBracket.offset) {
              edits.add(_FileEdit(offset: m.start, end: m.end, text: ''));
            }
          }
          for (final m in CloneableGenerator.typedefMarkerPattern(className)
              .allMatches(content)) {
            edits.add(_FileEdit(offset: m.start, end: m.end, text: ''));
          }
        }

        if (isActive) {
          if (isInline) {
            if (!partFilesOnly) {
              SomeParsedLibraryResult? parsedLibResult;
              try {
                parsedLibResult =
                    element.session?.getParsedLibraryByElement(element.library);
              } catch (_) {}

              if (output == CloneableOutput.inClass) {
                cleanOutsideMarkers();
                final memberCode = _generator.generateInClassMembers(
                  element: element,
                  annotation: effectiveReader,
                  inputFileName: p.basename(filePath),
                  inputFilePath: filePath,
                  sourceCode: content,
                  parsedLibResult: parsedLibResult,
                  resolvedDefaults: resolvedDefaults,
                );

                if (memberCode.isNotEmpty) {
                  if (shouldRemove) {
                    removedClasses.add(className);

                    // Insert member code inside class before right bracket
                    edits.add(_FileEdit(
                      offset: declaration.rightBracket.offset,
                      end: declaration.rightBracket.offset,
                      text: '\n$memberCode\n',
                    ));

                    // Auto-remove @Cloneable annotation on class
                    for (final meta in declaration.metadata) {
                      if (meta.name.name == 'Cloneable' ||
                          meta.name.name.startsWith('Cloneable.')) {
                        var metaEnd = meta.end;
                        while (metaEnd < content.length &&
                            (content[metaEnd] == ' ' ||
                                content[metaEnd] == '\t' ||
                                content[metaEnd] == '\r' ||
                                content[metaEnd] == '\n')) {
                          final isNewline = content[metaEnd] == '\n';
                          metaEnd++;
                          if (isNewline) break;
                        }
                        edits.add(_FileEdit(
                          offset: meta.offset,
                          end: metaEnd,
                          text: '',
                        ));
                      }
                    }

                    // Remove @CloneableField annotations on members and params
                    for (final member in declaration.members) {
                      for (final meta in member.metadata) {
                        if (meta.name.name == 'CloneableField' ||
                            meta.name.name.startsWith('CloneableField.')) {
                          var metaEnd = meta.end;
                          while (metaEnd < content.length &&
                              (content[metaEnd] == ' ' ||
                                  content[metaEnd] == '\t' ||
                                  content[metaEnd] == '\r' ||
                                  content[metaEnd] == '\n')) {
                            final isNewline = content[metaEnd] == '\n';
                            metaEnd++;
                            if (isNewline) break;
                          }
                          edits.add(_FileEdit(
                            offset: meta.offset,
                            end: metaEnd,
                            text: '',
                          ));
                        }
                      }
                      if (member is ConstructorDeclaration) {
                        for (final param in member.parameters.parameters) {
                          for (final meta in param.metadata) {
                            if (meta.name.name == 'CloneableField' ||
                                meta.name.name.startsWith('CloneableField.')) {
                              var metaEnd = meta.end;
                              while (metaEnd < content.length &&
                                  (content[metaEnd] == ' ' ||
                                      content[metaEnd] == '\t' ||
                                      content[metaEnd] == '\r' ||
                                      content[metaEnd] == '\n')) {
                                final isNewline = content[metaEnd] == '\n';
                                metaEnd++;
                                if (isNewline) break;
                              }
                              edits.add(_FileEdit(
                                offset: meta.offset,
                                end: metaEnd,
                                text: '',
                              ));
                            }
                          }
                        }
                      }
                    }

                    // Remove any existing marker blocks if present
                    if (CloneableGenerator.markerPattern(className)
                            .firstMatch(content)
                        case final m?) {
                      edits.add(_FileEdit(
                        offset: m.start,
                        end: m.end,
                        text: '',
                      ));
                    }
                    if (CloneableGenerator.typedefMarkerPattern(className)
                            .firstMatch(content)
                        case final m?) {
                      edits.add(_FileEdit(
                        offset: m.start,
                        end: m.end,
                        text: '',
                      ));
                    }
                  } else {
                    // Normal inClass with markers (or deactivate)
                    Match? insideMarker;
                    for (final m in CloneableGenerator.markerPattern(className)
                        .allMatches(content)) {
                      if (m.start >= declaration.leftBracket.offset &&
                          m.end <= declaration.rightBracket.offset) {
                        insideMarker = m;
                        break;
                      }
                    }

                    if (insideMarker != null) {
                      edits.add(_FileEdit(
                        offset: insideMarker.start,
                        end: insideMarker.end,
                        text: CloneableGenerator.wrapWithMarkers(
                            className, memberCode),
                      ));
                    } else {
                      edits.add(_FileEdit(
                        offset: declaration.rightBracket.offset,
                        end: declaration.rightBracket.offset,
                        text:
                            '\n${CloneableGenerator.wrapWithMarkers(className, memberCode)}\n',
                      ));
                    }

                    if (shouldDeactivate) {
                      deactivateAnnotation();
                    }
                  }
                }
                existingMarkerClasses.remove(className);
                continue;
              } else {
                // output == CloneableOutput.inLibrary
                cleanInClassMembers();
                final code = _generator.generateForClass(
                  element: element,
                  annotation: effectiveReader,
                  inputFileName: p.basename(filePath),
                  inputFilePath: filePath,
                  sourceCode: content,
                  isInline: true,
                  parsedLibResult: parsedLibResult,
                  resolvedDefaults: resolvedDefaults,
                  hasPartDirectiveOverride: fileNeedsPartDirective,
                  hasMixinOverride: injectedMixins.contains(className),
                  declaredSentinels: declaredSentinels,
                );

                if (shouldRemove) {
                  removedClasses.add(className);

                  if (code.trim().isNotEmpty) {
                    edits.add(_FileEdit(
                      offset: content.length,
                      end: content.length,
                      text: '\n$code\n',
                    ));
                  }

                  // Remove @Cloneable annotation on class
                  for (final meta in declaration.metadata) {
                    if (meta.name.name == 'Cloneable' ||
                        meta.name.name.startsWith('Cloneable.')) {
                      edits.add(_FileEdit(
                        offset: meta.offset,
                        end: meta.end,
                        text: '',
                      ));
                    }
                  }

                  // Remove @CloneableField annotations
                  for (final member in declaration.members) {
                    for (final meta in member.metadata) {
                      if (meta.name.name == 'CloneableField' ||
                          meta.name.name.startsWith('CloneableField.')) {
                        edits.add(_FileEdit(
                          offset: meta.offset,
                          end: meta.end,
                          text: '',
                        ));
                      }
                    }
                    if (member is ConstructorDeclaration) {
                      for (final param in member.parameters.parameters) {
                        for (final meta in param.metadata) {
                          if (meta.name.name == 'CloneableField' ||
                              meta.name.name.startsWith('CloneableField.')) {
                            edits.add(_FileEdit(
                              offset: meta.offset,
                              end: meta.end,
                              text: '',
                            ));
                          }
                        }
                      }
                    }
                  }

                  if (CloneableGenerator.markerPattern(className)
                          .firstMatch(content)
                      case final m?) {
                    edits.add(_FileEdit(
                      offset: m.start,
                      end: m.end,
                      text: '',
                    ));
                  }
                } else {
                  if (code.trim().isEmpty) {
                    if (existingMarkerClasses.contains(className)) {
                      inlineClassCodeMap[className] = null;
                    }
                  } else {
                    inlineClassCodeMap[className] = code;
                  }

                  if (shouldDeactivate) {
                    deactivateAnnotation();
                  }
                }
              }
            }
            existingMarkerClasses.remove(className);
            continue;
          } else {
            // Non-inline: clean up in-class members and inline marker if present from a previous run
            cleanInClassMembers();
            if (existingMarkerClasses.contains(className)) {
              inlineClassCodeMap[className] = null;
              existingMarkerClasses.remove(className);
            }

            if (!inlineOnly) {
              SomeParsedLibraryResult? parsedLibResult;
              try {
                parsedLibResult =
                    element.session?.getParsedLibraryByElement(element.library);
              } catch (_) {}

              final code = _generator.generateForClass(
                element: element,
                annotation: effectiveReader,
                inputFileName: p.basename(filePath),
                inputFilePath: filePath,
                sourceCode: content,
                isInline: false,
                includeHeader: false,
                parsedLibResult: parsedLibResult,
                resolvedDefaults: resolvedDefaults,
                hasPartDirectiveOverride: fileNeedsPartDirective,
                hasMixinOverride: injectedMixins.contains(className),
                declaredSentinels: declaredSentinels,
              );

              if (code.trim().isNotEmpty) {
                partFileCodes.add(code.trim());
              }

              if (shouldRemove) {
                removedClasses.add(className);
                for (final meta in declaration.metadata) {
                  if (meta.name.name == 'Cloneable' ||
                      meta.name.name.startsWith('Cloneable.')) {
                    edits.add(_FileEdit(
                      offset: meta.offset,
                      end: meta.end,
                      text: '',
                    ));
                  }
                }
                for (final member in declaration.members) {
                  for (final meta in member.metadata) {
                    if (meta.name.name == 'CloneableField' ||
                        meta.name.name.startsWith('CloneableField.')) {
                      edits.add(_FileEdit(
                        offset: meta.offset,
                        end: meta.end,
                        text: '',
                      ));
                    }
                  }
                  if (member is ConstructorDeclaration) {
                    for (final param in member.parameters.parameters) {
                      for (final meta in param.metadata) {
                        if (meta.name.name == 'CloneableField' ||
                            meta.name.name.startsWith('CloneableField.')) {
                          edits.add(_FileEdit(
                            offset: meta.offset,
                            end: meta.end,
                            text: '',
                          ));
                        }
                      }
                    }
                  }
                }
              } else if (shouldDeactivate) {
                deactivateAnnotation();
              }
            }
            continue;
          }
        }
      }

      // If class is present but not annotated at all (removed annotation):
      if (annotationReader == null && astConfig == null) {
        if (existingMarkerClasses.contains(className)) {
          inlineClassCodeMap[className] = null;
          existingMarkerClasses.remove(className);
        }
      } else {
        // Class is annotated with @Cloneable but inactive: preserve its existing code
        existingMarkerClasses.remove(className);
      }
    }

    // Obsolete classes that no longer exist in the file at all:
    for (final orphan in existingMarkerClasses) {
      inlineClassCodeMap[orphan] = null;
    }

    // If cleanup remove occurred, check if import line can be safely removed
    if (removedClasses.isNotEmpty) {
      final remainingActive = activeAnnotatedClasses.difference(removedClasses);
      if (remainingActive.isEmpty) {
        for (final directive in unitResult.unit.directives) {
          if (directive is ImportDirective) {
            final uri = directive.uri.stringValue;
            if (uri == 'package:cloneable/cloneable.dart' ||
                uri == 'package:cloneable/src/annotations.dart') {
              var importEnd = directive.end;
              while (importEnd < content.length &&
                  (content[importEnd] == ' ' ||
                      content[importEnd] == '\t' ||
                      content[importEnd] == '\r' ||
                      content[importEnd] == '\n')) {
                final isNewline = content[importEnd] == '\n';
                importEnd++;
                if (isNewline) break;
              }
              edits.add(_FileEdit(
                offset: directive.offset,
                end: importEnd,
                text: '',
              ));
            }
          }
        }
      }
    }

    // If no part file codes were generated, remove obsolete cloneable part directives
    if (partFileCodes.isEmpty) {
      for (final directive in unitResult.unit.directives) {
        if (directive is PartDirective && directive.uri.stringValue != null) {
          final uriStr = directive.uri.stringValue!;
          final partFilePath = p.normalize(p.join(p.dirname(filePath), uriStr));
          final partFile = File(partFilePath);
          final isCloneablePart = uriStr.contains('cloneable') ||
              (partFile.existsSync() &&
                  partFile
                      .readAsStringSync()
                      .contains('// GENERATED CODE - DO NOT MODIFY BY HAND'));
          if (isCloneablePart) {
            var partEnd = directive.end;
            while (partEnd < content.length &&
                (content[partEnd] == ' ' ||
                    content[partEnd] == '\t' ||
                    content[partEnd] == '\r' ||
                    content[partEnd] == '\n')) {
              final isNewline = content[partEnd] == '\n';
              partEnd++;
              if (isNewline) break;
            }
            edits.add(_FileEdit(
              offset: directive.offset,
              end: partEnd,
              text: '',
            ));
            if (partFile.existsSync()) {
              partFile.deleteSync();
              deleted.add(partFile.path);
            }
          }
        }
      }
    }

    // Apply inlineClassCodeMap updates via edits
    if (!partFilesOnly && inlineClassCodeMap.isNotEmpty) {
      for (final entry in inlineClassCodeMap.entries) {
        final className = entry.key;
        final code = entry.value;
        final pattern = CloneableGenerator.markerPattern(className);
        final typedefPattern =
            CloneableGenerator.typedefMarkerPattern(className);

        Match? topLevelMarker;
        for (final m in pattern.allMatches(content)) {
          var isInsideClass = false;
          for (final decl in unitResult.unit.declarations) {
            if (decl is ClassDeclaration &&
                m.start >= decl.leftBracket.offset &&
                m.end <= decl.rightBracket.offset) {
              isInsideClass = true;
              break;
            }
          }
          if (!isInsideClass) {
            topLevelMarker = m;
            break;
          }
        }

        if (code != null && code.trim().isNotEmpty) {
          final wrapped = CloneableGenerator.wrapWithMarkers(className, code);
          if (topLevelMarker != null) {
            edits.add(_FileEdit(
              offset: topLevelMarker.start,
              end: topLevelMarker.end,
              text: wrapped,
            ));
          } else {
            edits.add(_FileEdit(
              offset: content.length,
              end: content.length,
              text: '\n$wrapped\n',
            ));
          }
        } else {
          if (topLevelMarker != null) {
            edits.add(_FileEdit(
              offset: topLevelMarker.start,
              end: topLevelMarker.end,
              text: '',
            ));
          }
          for (final m in typedefPattern.allMatches(content)) {
            edits.add(_FileEdit(
              offset: m.start,
              end: m.end,
              text: '',
            ));
          }
        }
      }
    }

    // Apply all edits in descending order of offset
    var updatedContent = content;
    if (edits.isNotEmpty) {
      edits.sort((a, b) {
        final cmp = b.offset.compareTo(a.offset);
        if (cmp != 0) return cmp;
        return b.end.compareTo(a.end);
      });
      final nonOverlappingEdits = <_FileEdit>[];
      var lastOffset = 1 << 62;
      for (final edit in edits) {
        if (edit.end <= lastOffset) {
          nonOverlappingEdits.add(edit);
          lastOffset = edit.offset;
        }
      }
      for (final edit in nonOverlappingEdits) {
        updatedContent = updatedContent.substring(0, edit.offset) +
            edit.text +
            updatedContent.substring(edit.end);
      }

      try {
        updatedContent = _formatter.format(updatedContent);
      } catch (_) {
        // Fallback to unformatted if formatting fails
      }

      if (updatedContent != content) {
        await File(filePath).writeAsString(updatedContent);
        if (!updated.contains(filePath)) {
          updated.add(filePath);
        }
      }
    }

    // 2. Process part / standalone file updates
    if (!inlineOnly) {
      if (partFileCodes.isNotEmpty) {
        final buffer = StringBuffer();
        buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND\n');
        if (hasPartDirective) {
          buffer.writeln("part of '${p.basename(filePath)}';\n");
        } else {
          if (fileNeedsPackageSentinel) {
            buffer.writeln("import 'package:cloneable/cloneable.dart';");
          }
          buffer.writeln("import '${p.basename(filePath)}';");
          for (final directive in unitResult.unit.directives) {
            if (directive is ImportDirective) {
              final uri = directive.uri.stringValue;
              if (uri != null &&
                  uri != 'package:cloneable/cloneable.dart' &&
                  uri != 'package:cloneable/src/annotations.dart' &&
                  uri != p.basename(filePath) &&
                  !uri.endsWith('/${p.basename(filePath)}')) {
                buffer.writeln(directive.toSource());
              }
            }
          }
          buffer.writeln();
        }
        buffer.writeln(partFileCodes.join('\n\n'));

        var formattedPart = buffer.toString();
        try {
          formattedPart = _formatter.format(formattedPart);
        } catch (_) {
          // Fallback if formatting fails
        }

        final partFile = File(targetPartFilePath);
        if (!partFile.parent.existsSync()) {
          partFile.parent.createSync(recursive: true);
        }
        final existingPartContent =
            partFile.existsSync() ? partFile.readAsStringSync() : null;

        if (existingPartContent != formattedPart) {
          await partFile.writeAsString(formattedPart);
          updated.add(targetPartFilePath);
        }
      } else {
        // If no non-inline classes exist, clean up dedicated part files if present
        for (final candidatePath in [
          targetPartFilePath,
          p.join(
            p.dirname(filePath),
            '${p.basenameWithoutExtension(filePath)}.cloneable.dart',
          ),
        ]) {
          final candidateFile = File(candidatePath);
          if (candidateFile.existsSync()) {
            final existing = candidateFile.readAsStringSync();
            if (existing
                .contains('// GENERATED CODE - DO NOT MODIFY BY HAND')) {
              candidateFile.deleteSync();
              deleted.add(candidateFile.path);
            }
          }
        }
      }
    }

    return (updated: updated, deleted: deleted);
  }

  /// Processes a resolved AST unit, updating or removing inline code blocks as needed.
  ///
  /// Returns `true` if any file content was modified and written to disk.
  Future<bool> processResolvedUnit({
    required ResolvedUnitResult unitResult,
    required String filePath,
  }) async {
    final result = await processResolvedUnitDetails(
      unitResult: unitResult,
      filePath: filePath,
    );
    return result.updated.isNotEmpty || result.deleted.isNotEmpty;
  }

  /// Scans the given [paths] (files or directories) and generates or updates
  /// code for all `@Cloneable` classes.
  Future<CloneableResult> run({
    List<String> paths = const ['lib'],
    bool verbose = false,
    bool inlineOnly = false,
    bool partFilesOnly = false,
  }) async {
    final targetPaths = paths.isEmpty ? const ['lib'] : paths;
    final candidateFiles = <File>[];
    final contextRoots = <String>{};
    var scannedCount = 0;

    for (final rawPath in targetPaths) {
      final entityType = FileSystemEntity.typeSync(rawPath);
      if (entityType == FileSystemEntityType.file) {
        final file = File(rawPath);
        final normPath = p.normalize(file.absolute.path);
        if (_isCandidateDartFile(file)) {
          scannedCount++;
          if (_hasCloneableTrigger(normPath)) {
            candidateFiles.add(file);
            contextRoots.add(p.dirname(normPath));
          }
        }
      } else if (entityType == FileSystemEntityType.directory) {
        final dir = Directory(rawPath);
        final normDir = p.normalize(dir.absolute.path);
        contextRoots.add(normDir);

        for (final entity
            in dir.listSync(recursive: true, followLinks: false)) {
          if (entity is File && _isCandidateDartFile(entity)) {
            scannedCount++;
            final normPath = p.normalize(entity.absolute.path);
            if (_hasCloneableTrigger(normPath)) {
              candidateFiles.add(entity);
            }
          }
        }
      }
    }

    if (candidateFiles.isEmpty) {
      return CloneableResult(
        scannedCount: scannedCount,
        updatedFiles: const [],
        deletedFiles: const [],
      );
    }

    final collection = AnalysisContextCollection(
      includedPaths: contextRoots.toList(),
    );

    final updatedFiles = <String>[];
    final deletedFiles = <String>[];

    for (final file in candidateFiles) {
      final normPath = p.normalize(file.absolute.path);
      try {
        final context = collection.contextFor(normPath);
        final unitResult =
            await context.currentSession.getResolvedUnit(normPath);

        if (unitResult is ResolvedUnitResult) {
          final result = await processResolvedUnitDetails(
            unitResult: unitResult,
            filePath: normPath,
            inlineOnly: inlineOnly,
            partFilesOnly: partFilesOnly,
          );
          updatedFiles.addAll(result.updated);
          deletedFiles.addAll(result.deleted);
        }
      } catch (e) {
        if (verbose) {
          stderr.writeln('Error processing $normPath: $e');
        }
      }
    }

    return CloneableResult(
      scannedCount: scannedCount,
      updatedFiles: updatedFiles,
      deletedFiles: deletedFiles,
    );
  }

  bool _isCandidateDartFile(File file) {
    final name = p.basename(file.path);
    if (!name.endsWith('.dart')) return false;
    if (name.endsWith('.g.dart')) return false;
    if (name.endsWith('.cloneable.dart')) return false;
    if (name.endsWith('.freezed.dart')) return false;
    final parts = p.split(file.path);
    return !parts
        .any((segment) => segment.startsWith('.') && segment.length > 1);
  }

  bool _hasCloneableTrigger(String filePath) {
    try {
      final content = File(filePath).readAsStringSync();
      return content.contains('Cloneable') || content.contains('cloneable');
    } catch (_) {
      return false;
    }
  }
}

/// Shared CLI handler for `cloneable_generator` executables.
Future<void> runCloneableCli(
  List<String> args, {
  bool inlineOnly = false,
  bool partFilesOnly = false,
}) async {
  String? cliPrefix;
  String? cliSuffix;
  final flagValues = <int>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--prefix=')) {
      cliPrefix = arg.substring('--prefix='.length);
    } else if (arg == '--prefix' && i + 1 < args.length) {
      cliPrefix = args[i + 1];
      flagValues.add(i + 1);
    } else if (arg.startsWith('--suffix=')) {
      cliSuffix = arg.substring('--suffix='.length);
    } else if (arg == '--suffix' && i + 1 < args.length) {
      cliSuffix = args[i + 1];
      flagValues.add(i + 1);
    }
  }

  final targetPaths = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (!args[i].startsWith('-') && !flagValues.contains(i)) {
      targetPaths.add(args[i]);
    }
  }
  final verbose = args.contains('-v') || args.contains('--verbose');
  final isInlineOnly = inlineOnly || args.contains('--inline-only');
  final isPartFilesOnly = partFilesOnly || args.contains('--part-only');

  final paths = targetPaths.isNotEmpty ? targetPaths : ['lib'];

  stdout.writeln(
    'Scanning for @Cloneable classes in: ${paths.join(', ')}...',
  );

  final generator = CloneableGenerator(
    defaultPrefix: cliPrefix,
    defaultSuffix: cliSuffix,
  );
  final runner = CloneableGeneratorRunner(generator: generator);
  final stopwatch = Stopwatch()..start();
  final result = await runner.run(
    paths: paths,
    verbose: verbose,
    inlineOnly: isInlineOnly,
    partFilesOnly: isPartFilesOnly,
  );
  stopwatch.stop();

  final totalChanges = result.updatedFiles.length + result.deletedFiles.length;

  if (totalChanges == 0) {
    stdout.writeln(
      'Done in ${stopwatch.elapsedMilliseconds}ms. All files up to date (${result.scannedCount} files scanned).',
    );
  } else {
    stdout.writeln(
      'Done in ${stopwatch.elapsedMilliseconds}ms. Updated $totalChanges file(s):',
    );
    for (final file in result.updatedFiles) {
      stdout.writeln('  [updated] $file');
    }
    for (final file in result.deletedFiles) {
      stdout.writeln('  [deleted] $file');
    }
  }
}
