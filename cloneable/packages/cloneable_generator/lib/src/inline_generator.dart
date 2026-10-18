import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:cloneable/cloneable.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

import 'cloneable_generator.dart';

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

/// Comprehensive standalone code generator runner for `@Cloneable`.
///
/// Can generate code both:
/// - **Inline**: directly inside the model file between marker comments (`@Cloneable(inline: true)`).
/// - **External / Part files**: directly into `*.g.dart` or `*.cloneable.dart` files (`@Cloneable()`).
///
/// Completely independent of `build_runner`.
final class CloneableGeneratorRunner {
  final DartFormatter _formatter;
  final CloneableGenerator _generator;

  /// Creates a [CloneableGeneratorRunner] with an optional custom [DartFormatter]
  /// and [CloneableGenerator].
  CloneableGeneratorRunner({
    DartFormatter? formatter,
    CloneableGenerator? generator,
  })  : _formatter = formatter ?? DartFormatter(),
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

    final inlineClassCodeMap = <String, String?>{};
    final partFileCodes = <String>[];
    String? matchedPartName;
    const typeChecker = TypeChecker.fromRuntime(Cloneable);

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

    final targetPartFileName = matchedPartName ??
        '${p.basenameWithoutExtension(filePath)}.cloneable.dart';
    final targetPartFilePath =
        p.normalize(p.join(p.dirname(filePath), targetPartFileName));
    final hasPartDirective = matchedPartName != null;

    for (final declaration in unitResult.unit.declarations) {
      if (declaration is! ClassDeclaration) continue;

      final element = declaration.declaredElement;
      if (element == null) continue;

      final className = element.name;

      // Locate Cloneable annotation
      ConstantReader? annotationReader;
      try {
        if (typeChecker.firstAnnotationOf(element) case final obj?) {
          annotationReader = ConstantReader(obj);
        }
      } catch (_) {}

      if (annotationReader == null) {
        for (final meta in element.metadata) {
          try {
            if (meta.computeConstantValue() case final val?
                when val.type?.element?.name == 'Cloneable') {
              annotationReader = ConstantReader(val);
              break;
            }
          } catch (_) {}
        }
      }

      if (annotationReader != null) {
        final isActive = annotationReader.peek('active')?.boolValue ?? true;
        final isInline = annotationReader.peek('inline')?.boolValue ?? false;

        if (isActive) {
          if (isInline) {
            if (!partFilesOnly) {
              final code = _generator.generateForClass(
                element: element,
                annotation: annotationReader,
                inputFileName: p.basename(filePath),
                inputFilePath: filePath,
                isInline: true,
                parsedLibResult:
                    element.session?.getParsedLibraryByElement(element.library),
              );

              if (code.trim().isEmpty) {
                if (existingMarkerClasses.contains(className)) {
                  inlineClassCodeMap[className] = null;
                }
              } else {
                inlineClassCodeMap[className] = code;
              }
            }
            existingMarkerClasses.remove(className);
            continue;
          } else {
            // Non-inline: clean up inline marker if present from a previous run
            if (existingMarkerClasses.contains(className)) {
              inlineClassCodeMap[className] = null;
              existingMarkerClasses.remove(className);
            }

            if (!inlineOnly) {
              final code = _generator.generateForClass(
                element: element,
                annotation: annotationReader,
                inputFileName: p.basename(filePath),
                inputFilePath: filePath,
                isInline: false,
                parsedLibResult:
                    element.session?.getParsedLibraryByElement(element.library),
              );

              if (code.trim().isNotEmpty) {
                partFileCodes.add(code.trim());
              }
            }
            continue;
          }
        }
      }

      // If class is present but either not annotated or inactive:
      if (existingMarkerClasses.contains(className)) {
        inlineClassCodeMap[className] = null;
        existingMarkerClasses.remove(className);
      }
    }

    // Obsolete classes that no longer exist in the file at all:
    for (final orphan in existingMarkerClasses) {
      inlineClassCodeMap[orphan] = null;
    }

    // 1. Process inline code updates
    if (!partFilesOnly && inlineClassCodeMap.isNotEmpty) {
      final newContent = updateContent(
        content: content,
        classCodeMap: inlineClassCodeMap,
      );

      if (newContent != content) {
        await File(filePath).writeAsString(newContent);
        updated.add(filePath);
      }
    }

    // 2. Process part file updates
    if (!inlineOnly) {
      if (partFileCodes.isNotEmpty) {
        final buffer = StringBuffer();
        buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND\n');
        if (hasPartDirective) {
          buffer.writeln("part of '${p.basename(filePath)}';\n");
        } else {
          buffer.writeln("import 'package:cloneable/cloneable.dart';");
          buffer.writeln("import '${p.basename(filePath)}';\n");
        }
        buffer.writeln(partFileCodes.join('\n\n'));

        var formattedPart = buffer.toString();
        try {
          formattedPart = _formatter.format(formattedPart);
        } catch (_) {
          // Fallback if formatting fails
        }

        final partFile = File(targetPartFilePath);
        final existingPartContent =
            partFile.existsSync() ? partFile.readAsStringSync() : null;

        if (existingPartContent != formattedPart) {
          await partFile.writeAsString(formattedPart);
          updated.add(targetPartFilePath);
        }
      } else {
        // If no non-inline classes exist, clean up dedicated .cloneable.dart if present
        final defaultPartFile = File(p.join(
          p.dirname(filePath),
          '${p.basenameWithoutExtension(filePath)}.cloneable.dart',
        ));
        if (defaultPartFile.existsSync()) {
          final existing = defaultPartFile.readAsStringSync();
          if (existing.contains('// GENERATED CODE - DO NOT MODIFY BY HAND')) {
            defaultPartFile.deleteSync();
            deleted.add(defaultPartFile.path);
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

/// Backwards-compatible alias for [CloneableGeneratorRunner].
typedef InlineGenerator = CloneableGeneratorRunner;

/// Shared CLI handler for `cloneable_generator` executables.
Future<void> runCloneableCli(
  List<String> args, {
  bool inlineOnly = false,
  bool partFilesOnly = false,
}) async {
  final targetPaths = args.where((a) => !a.startsWith('-')).toList();
  final verbose = args.contains('-v') || args.contains('--verbose');
  final isInlineOnly = inlineOnly || args.contains('--inline-only');
  final isPartFilesOnly = partFilesOnly || args.contains('--part-only');

  final paths = targetPaths.isNotEmpty ? targetPaths : ['lib'];

  stdout.writeln(
    'Scanning for @Cloneable classes in: ${paths.join(', ')}...',
  );

  final runner = CloneableGeneratorRunner();
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
