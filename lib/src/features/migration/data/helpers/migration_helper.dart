library;

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

import 'conversion_helper.dart';
import '../../../../shared/utils/localization_metadata.dart';

class MigrationOptions {
  const MigrationOptions({
    required this.from,
    this.langDir = 'assets/lang',
    this.targets = const <String>[],
    this.testTargets = const <String>[],
    this.apply = false,
    this.workingDirectory,
  });

  final String from;
  final String langDir;
  final List<String> targets;
  final List<String> testTargets;
  final bool apply;
  final String? workingDirectory;
}

class MigrationFileResult {
  const MigrationFileResult({
    required this.path,
    required this.changed,
    required this.originalContent,
    required this.updatedContent,
    required this.warnings,
  });

  final String path;
  final bool changed;
  final String originalContent;
  final String updatedContent;
  final List<String> warnings;

  String buildPreview() {
    if (!changed) {
      return '';
    }

    final oldLines = LineSplitter.split(originalContent).toList();
    final newLines = LineSplitter.split(updatedContent).toList();
    final maxLength = oldLines.length > newLines.length ? oldLines.length : newLines.length;

    var firstDiff = 0;
    while (firstDiff < maxLength) {
      final oldLine = firstDiff < oldLines.length ? oldLines[firstDiff] : null;
      final newLine = firstDiff < newLines.length ? newLines[firstDiff] : null;
      if (oldLine != newLine) {
        break;
      }
      firstDiff++;
    }

    var oldEnd = oldLines.length - 1;
    var newEnd = newLines.length - 1;
    while (oldEnd >= firstDiff && newEnd >= firstDiff && oldLines[oldEnd] == newLines[newEnd]) {
      oldEnd--;
      newEnd--;
    }

    final buffer = StringBuffer();
    buffer.writeln('--- $path');
    buffer.writeln('+++ $path');
    for (var index = firstDiff; index <= oldEnd; index++) {
      buffer.writeln('- ${oldLines[index]}');
    }
    for (var index = firstDiff; index <= newEnd; index++) {
      buffer.writeln('+ ${newLines[index]}');
    }
    return buffer.toString().trimRight();
  }
}

class MigrationResult {
  const MigrationResult({
    required this.apply,
    required this.filesScanned,
    required this.fileResults,
    required this.globalWarnings,
  });

  final bool apply;
  final int filesScanned;
  final List<MigrationFileResult> fileResults;
  final List<String> globalWarnings;

  int get changedFiles => fileResults.where((result) => result.changed).length;
}

class MigrationHelper {
  const MigrationHelper._();

  static Future<MigrationResult> migrate(MigrationOptions options) async {
    final normalizedSource = options.from.trim().toLowerCase();
    if (!ConversionHelper.supports(normalizedSource)) {
      throw UnsupportedError('Unsupported migration source: ${options.from}');
    }

    final workingDirectory = options.workingDirectory ?? Directory.current.path;
    final langDirPath = _resolvePath(workingDirectory, options.langDir);
    final metadata = await LocalizationMetadataIndex.load(langDirPath);
    final files = _resolveTargetFiles(
      workingDirectory: workingDirectory,
      targets: options.targets,
      testTargets: options.testTargets,
    );

    final results = <MigrationFileResult>[];
    final globalWarnings = <String>[];

    for (final file in files) {
      final result = await _migrateFile(
        file: file,
        metadata: metadata,
        from: normalizedSource,
        apply: options.apply,
      );
      results.add(result);
      globalWarnings.addAll(result.warnings.map((warning) => '${file.path}: $warning'));
    }

    return MigrationResult(
      apply: options.apply,
      filesScanned: files.length,
      fileResults: results,
      globalWarnings: globalWarnings,
    );
  }

  static List<File> _resolveTargetFiles({
    required String workingDirectory,
    required List<String> targets,
    required List<String> testTargets,
  }) {
    final roots = <String>[
      if (targets.isEmpty) p.join(workingDirectory, 'lib') else ...targets,
      ...testTargets,
    ];
    if (roots.isEmpty) {
      roots.add(p.join(workingDirectory, 'lib'));
    }

    final resolvedFiles = <String, File>{};
    for (final root in roots) {
      final absoluteRoot = _resolvePath(workingDirectory, root);
      final type = FileSystemEntity.typeSync(absoluteRoot);
      if (type == FileSystemEntityType.notFound) {
        throw FileSystemException('Migration target not found', absoluteRoot);
      }
      if (type == FileSystemEntityType.file) {
        if (_shouldIncludeFile(absoluteRoot)) {
          resolvedFiles[absoluteRoot] = File(absoluteRoot);
        }
        continue;
      }

      for (final entity in Directory(absoluteRoot).listSync(recursive: true)) {
        if (entity is! File) {
          continue;
        }
        if (_shouldIncludeFile(entity.path)) {
          resolvedFiles[entity.path] = entity;
        }
      }
    }

    final files = resolvedFiles.values.toList()..sort((left, right) => left.path.compareTo(right.path));
    return files;
  }

  static Future<MigrationFileResult> _migrateFile({
    required File file,
    required LocalizationMetadataIndex metadata,
    required String from,
    required bool apply,
  }) async {
    final originalContent = await file.readAsString();
    final parseResult = parseString(
      content: originalContent,
      path: file.path,
      throwIfDiagnostics: false,
    );

    if (parseResult.errors.isNotEmpty) {
      return MigrationFileResult(
        path: file.path,
        changed: false,
        originalContent: originalContent,
        updatedContent: originalContent,
        warnings: const ['Skipping file with parse diagnostics.'],
      );
    }

    final visitor = _MigrationVisitor(
      source: originalContent,
      metadata: metadata,
      from: from,
    );
    parseResult.unit.visitChildren(visitor);

    if (visitor.edits.isEmpty &&
        !visitor.requiresLocalizationImport &&
        !visitor.requiresGeneratedDictionaryImport &&
        !visitor.requestsImportCleanup) {
      return MigrationFileResult(
        path: file.path,
        changed: false,
        originalContent: originalContent,
        updatedContent: originalContent,
        warnings: visitor.warnings,
      );
    }

    var updatedContent = _applyEdits(originalContent, visitor.edits);
    updatedContent = _cleanupImports(updatedContent);
    if (visitor.requiresLocalizationImport) {
      updatedContent = _ensureLocalizationImport(updatedContent);
    }
    if (visitor.requiresGeneratedDictionaryImport) {
      updatedContent = _ensureGeneratedDictionaryImport(updatedContent, file.path);
    }

    final changed = updatedContent != originalContent;
    if (changed && apply) {
      await file.writeAsString(updatedContent);
    }

    return MigrationFileResult(
      path: file.path,
      changed: changed,
      originalContent: originalContent,
      updatedContent: updatedContent,
      warnings: visitor.warnings,
    );
  }
}

class _MigrationVisitor extends RecursiveAstVisitor<void> {
  _MigrationVisitor({
    required this.source,
    required this.metadata,
    required this.from,
  });

  final String source;
  final LocalizationMetadataIndex metadata;
  final String from;
  final List<_SourceEdit> edits = <_SourceEdit>[];
  final List<String> warnings = <String>[];
  final Set<int> _asyncBodyOffsets = <int>{};
  bool requiresLocalizationImport = false;
  bool requiresGeneratedDictionaryImport = false;
  bool requestsImportCleanup = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_tryRewriteTextTr(node)) {
      return;
    }
    if (_tryRewriteStringTr(node)) {
      return;
    }
    if (_tryRewritePlural(node)) {
      return;
    }
    if (_tryRewriteSetLocale(node)) {
      return;
    }
    if (_tryRewriteGenL10nMethod(node)) {
      return;
    }
    if (_tryReportUnsupportedEasyLocalization(node)) {
      return;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_tryRewriteGenL10nProperty(node)) {
      return;
    }
    super.visitPropertyAccess(node);
  }

  bool _tryRewriteTextTr(MethodInvocation node) {
    if (from != ConversionHelper.easyLocalization) {
      return false;
    }
    if (node.methodName.name != 'tr' || node.target is! InstanceCreationExpression) {
      return false;
    }

    final target = node.target as InstanceCreationExpression;
    if (target.constructorName.type.toSource() != 'Text' || target.argumentList.arguments.isEmpty) {
      return false;
    }

    final firstArgument = target.argumentList.arguments.first;
    final key = _extractStringLiteral(firstArgument);
    if (key == null) {
      warnings.add('Skipped Text(...).tr() because the first argument is not a string literal.');
      return true;
    }

    final namedArgs = _extractNamedArgs(node.argumentList);
    final replacementExpression = _buildEasyStringReplacement(key, namedArgs);
    if (replacementExpression == null) {
      warnings.add('Skipped Text(...).tr() for "$key" because it could not be mapped safely.');
      return true;
    }

    final targetSource = _nodeText(target);
    final relativeStart = firstArgument.offset - target.offset;
    final relativeEnd = firstArgument.end - target.offset;
    final rewrittenTarget = targetSource.replaceRange(relativeStart, relativeEnd, replacementExpression);
    edits.add(_SourceEdit(node.offset, node.end, rewrittenTarget));
    requiresGeneratedDictionaryImport = true;
    requestsImportCleanup = true;
    return true;
  }

  bool _tryRewriteStringTr(MethodInvocation node) {
    if (from != ConversionHelper.easyLocalization || node.methodName.name != 'tr') {
      return false;
    }

    String? key;
    ArgumentList? arguments;
    if (node.target is StringLiteral) {
      key = _extractStringLiteral(node.target as Expression);
      arguments = node.argumentList;
    } else if (node.target == null && node.argumentList.arguments.isNotEmpty) {
      key = _extractStringLiteral(node.argumentList.arguments.first);
      arguments = node.argumentList;
    } else if (node.target != null &&
        _nodeText(node.target!).trim() == 'context' &&
        node.argumentList.arguments.isNotEmpty) {
      key = _extractStringLiteral(node.argumentList.arguments.first);
      arguments = node.argumentList;
    }

    if (key == null || arguments == null) {
      return false;
    }

    final namedArgs = _extractNamedArgs(arguments);
    final replacement = _buildEasyStringReplacement(key, namedArgs);
    if (replacement == null) {
      warnings.add('Skipped tr() call for "$key" because it could not be mapped safely.');
      return true;
    }

    edits.add(_SourceEdit(node.offset, node.end, replacement));
    requiresGeneratedDictionaryImport = true;
    requestsImportCleanup = true;
    return true;
  }

  bool _tryRewritePlural(MethodInvocation node) {
    if (from != ConversionHelper.easyLocalization || node.methodName.name != 'plural') {
      return false;
    }
    if (node.target is! StringLiteral || node.argumentList.arguments.isEmpty) {
      return false;
    }

    final key = _extractStringLiteral(node.target as Expression);
    if (key == null) {
      return false;
    }

    final countExpression = _nodeText(node.argumentList.arguments.first);
    final namedArgs = _extractNamedArgs(node.argumentList);
    if (namedArgs.isNotEmpty) {
      warnings.add('Skipped plural() call for "$key" because namedArgs are not safely supported.');
      return true;
    }

    final gender = _extractNamedExpression(node.argumentList, 'gender');
    final replacement = _buildPluralReplacement(
      key: key,
      countExpression: countExpression,
      genderExpression: gender,
    );
    if (replacement == null) {
      warnings.add('Skipped plural() call for "$key" because it could not be mapped safely.');
      return true;
    }

    edits.add(_SourceEdit(node.offset, node.end, replacement));
    requiresGeneratedDictionaryImport = true;
    requestsImportCleanup = true;
    return true;
  }

  bool _tryRewriteSetLocale(MethodInvocation node) {
    if (node.methodName.name != 'setLocale' || node.argumentList.arguments.length != 1) {
      return false;
    }

    String? contextExpression;
    if (node.target != null) {
      contextExpression = _contextExpressionFromSetLocaleTarget(node.target!);
    }
    if (contextExpression == null) {
      return false;
    }

    final localeArgument = _nodeText(node.argumentList.arguments.first);
    final baseCall = 'AnasLocalization.of($contextExpression).setLocale($localeArgument)';
    final replacement = node.parent is AwaitExpression ? baseCall : 'await $baseCall';

    if (node.parent is! AwaitExpression) {
      final functionBody = node.thisOrAncestorOfType<FunctionBody>();
      if (functionBody == null) {
        warnings.add('Skipped setLocale() rewrite because no enclosing function body was found.');
        return true;
      }
      _ensureAsync(functionBody);
    }

    edits.add(_SourceEdit(node.offset, node.end, replacement));
    requiresLocalizationImport = true;
    requestsImportCleanup = true;
    return true;
  }

  bool _tryRewriteGenL10nProperty(PropertyAccess node) {
    if (from != ConversionHelper.genL10n || !_isAppLocalizationsAccess(node.target)) {
      return false;
    }

    final member = node.propertyName.name;
    final entry = metadata.entriesByMemberName[member];
    if (entry == null) {
      warnings.add('Skipped AppLocalizations property "$member" because no matching localization key was found.');
      return true;
    }

    final replacement = _buildPropertyReplacement(entry);
    if (replacement == null) {
      warnings.add('Skipped AppLocalizations property "$member" because it requires parameters.');
      return true;
    }

    edits.add(_SourceEdit(node.offset, node.end, replacement));
    requiresGeneratedDictionaryImport = true;
    requestsImportCleanup = true;
    return true;
  }

  bool _tryRewriteGenL10nMethod(MethodInvocation node) {
    if (from != ConversionHelper.genL10n || !_isAppLocalizationsAccess(node.target)) {
      return false;
    }

    final member = node.methodName.name;
    final entry = metadata.entriesByMemberName[member];
    if (entry == null) {
      warnings.add('Skipped AppLocalizations method "$member" because no matching localization key was found.');
      return true;
    }

    final replacement = _buildGenL10nMethodReplacement(entry, node.argumentList.arguments);
    if (replacement == null) {
      warnings.add('Skipped AppLocalizations method "$member" because it could not be mapped safely.');
      return true;
    }

    edits.add(_SourceEdit(node.offset, node.end, replacement));
    requiresGeneratedDictionaryImport = true;
    requestsImportCleanup = true;
    return true;
  }

  bool _tryReportUnsupportedEasyLocalization(MethodInvocation node) {
    if (from != ConversionHelper.easyLocalization) {
      return false;
    }
    if (node.methodName.name == 'resetLocale' || node.methodName.name == 'deleteSaveLocale') {
      warnings.add('Manual follow-up required for ${node.methodName.name}().');
      return true;
    }
    return false;
  }

  String? _buildEasyStringReplacement(String key, Map<String, String> namedArgs) {
    final entry = metadata.entriesByKey[key];
    if (namedArgs.isEmpty) {
      if (entry == null || !entry.typedAccessorDeterministic) {
        return "getDictionary().getString('${_escapeSingleQuoted(key)}')";
      }
      if (entry.kind == LocalizationEntryKind.string) {
        return 'getDictionary().${entry.memberName}';
      }
      if (entry.kind == LocalizationEntryKind.parameterizedString) {
        return "getDictionary().getString('${_escapeSingleQuoted(key)}')";
      }
      return null;
    }

    if (entry != null &&
        entry.kind == LocalizationEntryKind.parameterizedString &&
        entry.typedAccessorDeterministic &&
        _hasAllPlaceholders(entry, namedArgs.keys.toList())) {
      final orderedArgs = entry.placeholders.map((placeholder) => '$placeholder: ${namedArgs[placeholder]}').join(', ');
      return 'getDictionary().${entry.memberName}($orderedArgs)';
    }

    final runtimeArgs =
        namedArgs.entries.map((entry) => "'${_escapeSingleQuoted(entry.key)}': ${entry.value}").join(', ');
    return "getDictionary().getStringWithParams('${_escapeSingleQuoted(key)}', {$runtimeArgs})";
  }

  String? _buildPluralReplacement({
    required String key,
    required String countExpression,
    String? genderExpression,
  }) {
    final entry = metadata.entriesByKey[key];
    if (entry == null || entry.kind != LocalizationEntryKind.plural || !entry.typedAccessorDeterministic) {
      return null;
    }

    final args = <String>['count: $countExpression'];
    if (genderExpression != null && entry.hasGender) {
      args.add('gender: $genderExpression');
    }
    return 'getDictionary().${entry.memberName}(${args.join(', ')})';
  }

  String? _buildPropertyReplacement(LocalizationEntry entry) {
    if (entry.kind == LocalizationEntryKind.string && entry.typedAccessorDeterministic) {
      return 'getDictionary().${entry.memberName}';
    }
    if (entry.kind == LocalizationEntryKind.string) {
      return "getDictionary().getString('${_escapeSingleQuoted(entry.keyPath)}')";
    }
    return null;
  }

  String? _buildGenL10nMethodReplacement(LocalizationEntry entry, List<Expression> arguments) {
    switch (entry.kind) {
      case LocalizationEntryKind.string:
        if (arguments.isEmpty) {
          return entry.typedAccessorDeterministic
              ? 'getDictionary().${entry.memberName}'
              : "getDictionary().getString('${_escapeSingleQuoted(entry.keyPath)}')";
        }
        return null;
      case LocalizationEntryKind.parameterizedString:
        if (arguments.length != entry.placeholders.length) {
          return null;
        }
        if (entry.typedAccessorDeterministic) {
          final namedArgs = <String>[];
          for (var index = 0; index < entry.placeholders.length; index++) {
            namedArgs.add('${entry.placeholders[index]}: ${_nodeText(arguments[index])}');
          }
          return 'getDictionary().${entry.memberName}(${namedArgs.join(', ')})';
        }
        final runtimeArgs = <String>[];
        for (var index = 0; index < entry.placeholders.length; index++) {
          runtimeArgs.add("'${entry.placeholders[index]}': ${_nodeText(arguments[index])}");
        }
        return "getDictionary().getStringWithParams('${_escapeSingleQuoted(entry.keyPath)}', {${runtimeArgs.join(', ')}})";
      case LocalizationEntryKind.plural:
        if (arguments.isEmpty || arguments.length > 2 || !entry.typedAccessorDeterministic) {
          return null;
        }
        final args = <String>['count: ${_nodeText(arguments.first)}'];
        if (arguments.length == 2 && entry.hasGender) {
          args.add('gender: ${_nodeText(arguments[1])}');
        } else if (arguments.length == 2) {
          return null;
        }
        return 'getDictionary().${entry.memberName}(${args.join(', ')})';
    }
  }

  String? _contextExpressionFromSetLocaleTarget(Expression target) {
    if (target is SimpleIdentifier) {
      return target.name;
    }

    if (target is MethodInvocation &&
        target.methodName.name == 'of' &&
        target.target is SimpleIdentifier &&
        (target.target as SimpleIdentifier).name == 'EasyLocalization' &&
        target.argumentList.arguments.length == 1) {
      return _nodeText(target.argumentList.arguments.first);
    }

    return null;
  }

  void _ensureAsync(FunctionBody body) {
    if (body.keyword != null || _asyncBodyOffsets.contains(body.offset)) {
      return;
    }
    edits.add(_SourceEdit(body.offset, body.offset, 'async '));
    _asyncBodyOffsets.add(body.offset);
  }

  Map<String, String> _extractNamedArgs(ArgumentList argumentList) {
    final namedArgsExpression = _extractNamedExpression(argumentList, 'namedArgs');
    if (namedArgsExpression == null) {
      return const <String, String>{};
    }

    final parsed = _parseStringMapLiteral(namedArgsExpression);
    if (parsed == null) {
      return const <String, String>{};
    }
    return parsed;
  }

  String? _extractNamedExpression(ArgumentList argumentList, String name) {
    for (final argument in argumentList.arguments) {
      if (argument is NamedExpression && argument.name.label.name == name) {
        return _nodeText(argument.expression);
      }
    }
    return null;
  }

  Map<String, String>? _parseStringMapLiteral(String expressionSource) {
    final parsed = parseString(
      content: 'final _value = $expressionSource;',
      throwIfDiagnostics: false,
    );
    if (parsed.errors.isNotEmpty || parsed.unit.declarations.isEmpty) {
      return null;
    }
    final declaration = parsed.unit.declarations.first;
    if (declaration is! TopLevelVariableDeclaration) {
      return null;
    }
    final initializer = declaration.variables.variables.first.initializer;
    if (initializer is! SetOrMapLiteral) {
      return null;
    }

    final map = <String, String>{};
    for (final element in initializer.elements) {
      if (element is! MapLiteralEntry) {
        return null;
      }
      final key = _extractStringLiteral(element.key);
      if (key == null) {
        return null;
      }
      map[key] = element.value.toSource();
    }
    return map;
  }

  String? _extractStringLiteral(Expression expression) {
    if (expression is SimpleStringLiteral) {
      return expression.value;
    }
    return null;
  }

  bool _hasAllPlaceholders(LocalizationEntry entry, List<String> providedNames) {
    final provided = providedNames.toSet();
    return entry.placeholders.every(provided.contains);
  }

  bool _isAppLocalizationsAccess(Expression? expression) {
    if (expression == null) {
      return false;
    }
    if (expression is PostfixExpression && expression.operator.lexeme == '!') {
      return _isAppLocalizationsAccess(expression.operand);
    }
    if (expression is MethodInvocation &&
        expression.methodName.name == 'of' &&
        expression.target is SimpleIdentifier &&
        (expression.target as SimpleIdentifier).name == 'AppLocalizations') {
      return true;
    }
    return false;
  }

  String _nodeText(AstNode node) => source.substring(node.offset, node.end);
}

class _SourceEdit {
  const _SourceEdit(this.start, this.end, this.replacement);

  final int start;
  final int end;
  final String replacement;
}

String _applyEdits(String source, List<_SourceEdit> edits) {
  final ordered = edits.toList()
    ..sort((left, right) {
      final compare = right.start.compareTo(left.start);
      if (compare != 0) {
        return compare;
      }
      return right.end.compareTo(left.end);
    });

  var result = source;
  for (final edit in ordered) {
    result = result.replaceRange(edit.start, edit.end, edit.replacement);
  }
  return result;
}

String _cleanupImports(String source) {
  var updated = source;
  if (!updated.contains('EasyLocalization') && !updated.contains('.tr(') && !updated.contains(' tr(')) {
    updated = updated.replaceAll(
      RegExp("^import\\s+[\"']package:easy_localization/easy_localization\\.dart[\"'];\\n?", multiLine: true),
      '',
    );
  }
  if (!updated.contains('AppLocalizations')) {
    updated = updated.replaceAll(
      RegExp("^import\\s+[\"'].*app_localizations\\.dart[\"'];\\n?", multiLine: true),
      '',
    );
  }
  return updated;
}

String _ensureLocalizationImport(String source) {
  const importLine = "import 'package:anas_localization/localization.dart';";
  if (source.contains(importLine)) {
    return source;
  }

  final lines = LineSplitter.split(source).toList();
  var insertIndex = 0;
  for (var index = 0; index < lines.length; index++) {
    final trimmed = lines[index].trimLeft();
    if (trimmed.startsWith('import ')) {
      insertIndex = index + 1;
    }
  }
  lines.insert(insertIndex, importLine);
  return '${lines.join('\n')}\n';
}

String _ensureGeneratedDictionaryImport(String source, String filePath) {
  final projectRoot = _findProjectRoot(filePath);
  final generatedPath = p.join(projectRoot, 'lib', 'generated', 'dictionary.dart');
  final relativeImport = p.relative(generatedPath, from: p.dirname(filePath)).replaceAll('\\', '/');
  final importLine = "import '$relativeImport';";
  if (source.contains(importLine)) {
    return source;
  }

  final lines = LineSplitter.split(source).toList();
  var insertIndex = 0;
  for (var index = 0; index < lines.length; index++) {
    final trimmed = lines[index].trimLeft();
    if (trimmed.startsWith('import ')) {
      insertIndex = index + 1;
    }
  }
  lines.insert(insertIndex, importLine);
  return '${lines.join('\n')}\n';
}

String _findProjectRoot(String filePath) {
  var current = Directory(p.dirname(filePath));
  while (true) {
    final pubspec = File(p.join(current.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      return current.path;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      return p.dirname(filePath);
    }
    current = parent;
  }
}

String _resolvePath(String workingDirectory, String path) {
  if (p.isAbsolute(path)) {
    return p.normalize(path);
  }
  return p.normalize(p.join(workingDirectory, path));
}

bool _shouldIncludeFile(String path) {
  final lower = path.toLowerCase();
  if (!lower.endsWith('.dart')) {
    return false;
  }
  if (lower.endsWith('.g.dart') || lower.endsWith('.freezed.dart')) {
    return false;
  }
  if (lower.contains('${p.separator}.dart_tool${p.separator}') ||
      lower.contains('${p.separator}build${p.separator}') ||
      lower.contains('${p.separator}.cache${p.separator}')) {
    return false;
  }
  final base = p.basename(lower);
  if (base == 'dictionary.dart' || base == 'generated_dictionary.dart') {
    return false;
  }
  return true;
}

String _escapeSingleQuoted(String value) {
  return value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
}
