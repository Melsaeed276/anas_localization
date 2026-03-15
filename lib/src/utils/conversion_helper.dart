library;

import 'dart:convert';
import 'dart:io';

import 'package:anas_localization/src/utils/arb_interop.dart';
import 'package:anas_localization/src/utils/translation_file_parser.dart';

const String kConversionIssueBaseUrl = 'https://github.com/Melsaeed276/anas_localization/issues/new';

class ConversionResult {
  const ConversionResult({
    required this.sourcePackage,
    required this.sourcePath,
    required this.outputDirectory,
    required this.locales,
    required this.migrationGuidePath,
  });

  final String sourcePackage;
  final String sourcePath;
  final String outputDirectory;
  final List<String> locales;
  final String migrationGuidePath;
}

class ConversionHelper {
  const ConversionHelper._();

  static const String easyLocalization = 'easy_localization';
  static const String genL10n = 'gen_l10n';

  static const List<String> supportedSources = <String>[
    easyLocalization,
    genL10n,
  ];

  static bool supports(String packageName) {
    return supportedSources.contains(_normalizePackageName(packageName));
  }

  static String buildUnsupportedIssueUrl(String packageName) {
    final normalized = packageName.trim().isEmpty ? 'unknown_package' : packageName.trim();
    final title = Uri.encodeQueryComponent('Support converter for $normalized');
    final body = Uri.encodeQueryComponent('''
Package name: $normalized
Package repository URL:
Translation file format used:
Sample localization setup:
Sample lookup syntax used in code:
''');
    return '$kConversionIssueBaseUrl?title=$title&body=$body';
  }

  static Future<ConversionResult> convert({
    required String from,
    String? sourcePath,
    String outputDirectory = 'assets/lang',
  }) async {
    final normalized = _normalizePackageName(from);
    switch (normalized) {
      case easyLocalization:
        return _convertEasyLocalization(
          sourcePath: sourcePath ?? 'assets/translations',
          outputDirectory: outputDirectory,
        );
      case genL10n:
        return _convertGenL10n(
          sourcePath: sourcePath ?? 'l10n.yaml',
          outputDirectory: outputDirectory,
        );
      default:
        throw UnsupportedError('Unsupported conversion source: $from');
    }
  }

  static Future<ConversionResult> _convertGenL10n({
    required String sourcePath,
    required String outputDirectory,
  }) async {
    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      throw FileSystemException('l10n.yaml source file not found', sourcePath);
    }

    final imported = await ArbInterop.importUsingL10nYaml(sourceFile.path);
    if (imported.isEmpty) {
      throw FormatException('No locale ARB files found for l10n config: ${sourceFile.path}');
    }

    final locales = imported.keys.toList()..sort();
    await _writeConvertedLocales(
      imported.map(
        (locale, value) => MapEntry(locale, TranslationFileParser.expandDottedMap(value)),
      ),
      outputDirectory,
    );

    return ConversionResult(
      sourcePackage: genL10n,
      sourcePath: sourceFile.path,
      outputDirectory: outputDirectory,
      locales: locales,
      migrationGuidePath: 'doc/MIGRATION_GEN_L10N.md',
    );
  }

  static Future<ConversionResult> _convertEasyLocalization({
    required String sourcePath,
    required String outputDirectory,
  }) async {
    final sourceDirectory = Directory(sourcePath);
    if (!sourceDirectory.existsSync()) {
      throw FileSystemException('easy_localization source directory not found', sourcePath);
    }

    final localeFiles = sourceDirectory
        .listSync()
        .whereType<File>()
        .where((file) => _supportedEasyLocalizationExtensions.contains(_extensionFor(file)))
        .toList()
      ..sort((left, right) => left.path.compareTo(right.path));

    if (localeFiles.isEmpty) {
      throw FormatException(
        'No supported easy_localization files found in ${sourceDirectory.path}. '
        'Expected .json, .yaml, .yml, or .csv files named <locale>.<ext>.',
      );
    }

    final detectedFormats = localeFiles.map((file) => _formatFamilyFor(_extensionFor(file))).toSet();
    if (detectedFormats.length > 1) {
      final formats = detectedFormats.toList()..sort();
      throw FormatException(
        'Mixed easy_localization source formats are not supported. Found: ${formats.join(', ')}.',
      );
    }

    final converted = <String, Map<String, dynamic>>{};
    for (final file in localeFiles) {
      final locale = _localeFor(file);
      if (locale.isEmpty) {
        throw FormatException('Invalid locale filename: ${file.path}');
      }
      final extension = _extensionFor(file);
      final content = await file.readAsString();
      converted[locale] = switch (extension) {
        'json' => TranslationFileParser.parseJsonContent(content),
        'yaml' || 'yml' => TranslationFileParser.parseYamlContent(content),
        'csv' => TranslationFileParser.parseCsvContent(content),
        _ => throw FormatException('Unsupported easy_localization file type: .$extension'),
      };
    }

    final locales = converted.keys.toList()..sort();
    await _writeConvertedLocales(converted, outputDirectory);

    return ConversionResult(
      sourcePackage: easyLocalization,
      sourcePath: sourceDirectory.path,
      outputDirectory: outputDirectory,
      locales: locales,
      migrationGuidePath: 'doc/MIGRATION_EASY_LOCALIZATION.md',
    );
  }

  static Future<void> _writeConvertedLocales(
    Map<String, Map<String, dynamic>> locales,
    String outputDirectory,
  ) async {
    final encoder = const JsonEncoder.withIndent('  ');
    for (final entry in locales.entries) {
      final outputFile = File('$outputDirectory/${entry.key}.json');
      await outputFile.create(recursive: true);
      await outputFile.writeAsString(encoder.convert(entry.value));
    }
  }

  static String _normalizePackageName(String packageName) {
    return packageName.trim().toLowerCase();
  }

  static String _extensionFor(File file) {
    final name = file.uri.pathSegments.last;
    final index = name.lastIndexOf('.');
    if (index == -1) {
      return '';
    }
    return name.substring(index + 1).toLowerCase();
  }

  static String _localeFor(File file) {
    final name = file.uri.pathSegments.last;
    final index = name.lastIndexOf('.');
    if (index <= 0) {
      return '';
    }
    return name.substring(0, index);
  }

  static String _formatFamilyFor(String extension) {
    switch (extension) {
      case 'yaml':
      case 'yml':
        return 'yaml';
      default:
        return extension;
    }
  }

  static const Set<String> _supportedEasyLocalizationExtensions = <String>{
    'json',
    'yaml',
    'yml',
    'csv',
  };
}
