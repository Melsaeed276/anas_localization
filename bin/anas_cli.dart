#!/usr/bin/env dart

/// Comprehensive CLI tool for managing Anas Localization translations
library;

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;

import 'generate_dictionary.dart' as gen;
import 'package:anas_localization/src/catalog/catalog.dart';
import 'package:anas_localization/src/utils/conversion_helper.dart';
import 'package:anas_localization/src/utils/migration_helper.dart';
import 'package:anas_localization/src/utils/migration_validation_helper.dart';
import 'package:anas_localization/src/utils/translation_file_parser.dart';
import 'package:anas_localization/src/utils/arb_interop.dart';
import 'package:anas_localization/src/utils/translation_validator.dart';

const String _defaultLangDir = 'assets/lang';
const Set<String> _updateTriggerFlags = {'--gen', '--genupdate', '--genpdate'};
const Map<String, String> _catalogCommandAliases = {
  '--init': 'init',
  '--serve': 'serve',
  '--run': 'serve',
};

Future<void> main(List<String> arguments) async {
  final success = await _run(arguments);
  if (!success) {
    exitCode = 1;
  }
}

Future<bool> _run(List<String> arguments) async {
  if (arguments.isEmpty) {
    _printHelp();
    return true;
  }

  final command = arguments[0];
  final args = arguments.skip(1).toList();

  if (_isHelpFlag(command)) {
    _printHelp();
    return true;
  }

  if (command == '--validate') {
    final args = arguments.skip(1).toList();
    return _validateCommand(args);
  }

  switch (command) {
    case 'validate':
      return _validateCommand(args);
    case 'add-key':
      return _addKeyCommand(args);
    case 'remove-key':
      return _removeKeyCommand(args);
    case 'add-locale':
      return _addLocaleCommand(args);
    case 'translate':
      return _translateCommand(args);
    case 'stats':
      return _statsCommand(args);
    case 'catalog':
      return _catalogCommand(args);
    case 'dev':
      return _devCommand(args);
    case 'export':
      return _exportCommand(args);
    case 'import':
      return _importCommand(args);
    case 'convert':
      return _convertCommand(args);
    case 'migrate':
      return _migrateCommand(args);
    case 'validate-migration':
      return _validateMigrationCommand(args);
    case 'init':
      return _initCommand(args);
    case 'source_locale':
      return _sourceLocaleCommand(args);
    case 'update':
      return _updateCommand(args);
    case 'help':
      _printHelp();
      return true;
    default:
      _err('Unknown command: $command');
      _printHelp();
      return false;
  }
}

void _out(Object? message) => stdout.writeln(message);

void _err(Object? message) => stderr.writeln(message);

void _printHelp() {
  _out('''
Anas Localization CLI Tool

Commands:
  validate <lang-dir> [options] Validate translation files for consistency
  add-key <key> <value> [dir]   Add a new translation key to all languages
  remove-key <key> [dir]        Remove a translation key from all languages
  add-locale <locale> [tpl] [dir] Add support for a new locale from template locale
  translate <key> <locale> <text> [dir]  Add/update translation for specific locale
  stats <lang-dir>              Show translation statistics
  catalog <subcommand>          Manage interactive translation catalog workflow
  init --locale <code> [opts]   Initialize a new localization project (--help for details)
  source_locale <locale>         Set the source locale for the catalog (--help for details)
  dev --with-catalog -- <cmd>   Run command with catalog sidecar services
  export <lang-dir> <format> [out]  Export translations (csv, json, arb)
  import <file|dir> <lang-dir>      Import translations from json/csv/arb or l10n.yaml
  convert --from <package> [options] Convert supported localization sources into assets/lang JSON
  migrate --from <package> [options] Rewrite Dart localization callsites after conversion
  validate-migration [options]      Generate demo apps, migrate them, and verify analyze/test flows
  update --gen [--watch]          Run localization generator (alias for localization_gen)
  help                          Show this help

Examples:
  anas --validate assets/lang
  anas convert --from easy_localization
  anas convert --from gen_l10n --source l10n.yaml --out assets/lang
  anas migrate --from easy_localization --dry-run
  anas convert --from easy_localization --rewrite --test test/widget_test.dart
  anas validate-migration --from easy_localization
  anas catalog add-key --key=home.header.title --value-en="Home" --value-tr="Ana Sayfa"
  anas dev --with-catalog -- flutter run

Legacy `dart run` forms:
  dart run anas_localization:anas validate assets/lang
  dart run anas_localization:anas update --gen
''');
}

Future<bool> _updateCommand(List<String> args) async {
  final hasGen = args.any(_updateTriggerFlags.contains);
  if (!hasGen) {
    _err('❌ update requires --gen, --genupdate, or --genpdate');
    _printUpdateHelp();
    return false;
  }

  final generatorArgs = args.where((arg) => !_updateTriggerFlags.contains(arg)).toList();
  try {
    await gen.main(generatorArgs);
    return true;
  } on Object catch (error) {
    _err('❌ update failed: $error');
    return false;
  }
}

void _printUpdateHelp() {
  _out('''
Update commands:
  update --gen [--watch]      Run localization generator (alias for localization_gen)
  update --genupdate          Same as --gen (legacy typo)
  update --genpdate          Same as --gen (typo)
''');
}

class _ConvertArgs {
  const _ConvertArgs({
    required this.from,
    required this.sourcePath,
    required this.outputDirectory,
    required this.rewrite,
    required this.langDir,
    required this.targets,
    required this.testTargets,
    required this.apply,
  });

  final String from;
  final String? sourcePath;
  final String outputDirectory;
  final bool rewrite;
  final String langDir;
  final List<String> targets;
  final List<String> testTargets;
  final bool apply;
}

Future<bool> _convertCommand(List<String> args) async {
  final parsed = _parseConvertArgs(args);
  if (parsed == null) {
    return false;
  }

  if (parsed.rewrite) {
    return _runMigration(
      _MigrateArgs(
        from: parsed.from,
        langDir: parsed.langDir,
        targets: parsed.targets,
        testTargets: parsed.testTargets,
        apply: parsed.apply,
      ),
    );
  }

  if (!ConversionHelper.supports(parsed.from)) {
    _printUnsupportedConverterMessage(parsed.from);
    return false;
  }

  try {
    final result = await ConversionHelper.convert(
      from: parsed.from,
      sourcePath: parsed.sourcePath,
      outputDirectory: parsed.outputDirectory,
    );

    _out('✅ Converted ${result.sourcePackage} translations.');
    _out('Source: ${result.sourcePath}');
    _out('Output: ${result.outputDirectory}');
    _out('Locales: ${result.locales.join(', ')}');
    _out('');
    _out('Next steps:');
    _out('  1. dart run anas_localization:anas_cli validate ${result.outputDirectory}');
    _out('  2. dart run anas_localization:localization_gen');
    _out('  3. Follow ${result.migrationGuidePath} for code migration steps.');
    return true;
  } catch (error) {
    _err('❌ Conversion failed: $error');
    return false;
  }
}

_ConvertArgs? _parseConvertArgs(List<String> args) {
  String? from;
  String? sourcePath;
  var outputDirectory = _defaultLangDir;
  var rewrite = false;
  var langDir = _defaultLangDir;
  var apply = false;
  final targets = <String>[];
  final testTargets = <String>[];

  for (var index = 0; index < args.length; index++) {
    final arg = args[index];

    if ((arg == '--from' || arg == '-from') && index + 1 < args.length) {
      from = args[++index];
      continue;
    }
    if (arg.startsWith('--from=')) {
      from = arg.substring('--from='.length);
      continue;
    }

    if ((arg == '--source' || arg == '-source') && index + 1 < args.length) {
      sourcePath = args[++index];
      continue;
    }
    if (arg.startsWith('--source=')) {
      sourcePath = arg.substring('--source='.length);
      continue;
    }

    if ((arg == '--out' || arg == '-out') && index + 1 < args.length) {
      outputDirectory = args[++index];
      continue;
    }
    if (arg.startsWith('--out=')) {
      outputDirectory = arg.substring('--out='.length);
      continue;
    }

    if (arg == '--rewrite') {
      rewrite = true;
      continue;
    }

    if (arg == '--lang-dir' && index + 1 < args.length) {
      langDir = args[++index];
      continue;
    }
    if (arg.startsWith('--lang-dir=')) {
      langDir = arg.substring('--lang-dir='.length);
      continue;
    }

    if (arg == '--target' && index + 1 < args.length) {
      targets.add(args[++index]);
      continue;
    }
    if (arg.startsWith('--target=')) {
      targets.add(arg.substring('--target='.length));
      continue;
    }

    if ((arg == '--test' || arg == '-test') && index + 1 < args.length) {
      testTargets.add(args[++index]);
      continue;
    }
    if (arg.startsWith('--test=')) {
      testTargets.add(arg.substring('--test='.length));
      continue;
    }

    if (arg == '--apply') {
      apply = true;
      continue;
    }

    if (arg == '--dry-run') {
      apply = false;
      continue;
    }

    _err('❌ Unknown convert option: $arg');
    _err(
      'Usage: convert --from <package> [--source <path>] [--out <lang-dir>] [--rewrite] [--lang-dir <path>] [--target <path>] [--test <path>] [--dry-run|--apply]',
    );
    return null;
  }

  if (from == null || from.trim().isEmpty) {
    _err(
      'Usage: convert --from <package> [--source <path>] [--out <lang-dir>] [--rewrite] [--lang-dir <path>] [--target <path>] [--test <path>] [--dry-run|--apply]',
    );
    _err('Supported packages: ${ConversionHelper.supportedSources.join(', ')}');
    return null;
  }

  return _ConvertArgs(
    from: from.trim(),
    sourcePath: sourcePath?.trim().isEmpty ?? true ? null : sourcePath!.trim(),
    outputDirectory: outputDirectory,
    rewrite: rewrite,
    langDir: langDir,
    targets: targets,
    testTargets: testTargets,
    apply: apply,
  );
}

class _MigrateArgs {
  const _MigrateArgs({
    required this.from,
    required this.langDir,
    required this.targets,
    required this.testTargets,
    required this.apply,
  });

  final String from;
  final String langDir;
  final List<String> targets;
  final List<String> testTargets;
  final bool apply;
}

class _ValidateMigrationArgs {
  const _ValidateMigrationArgs({
    required this.sources,
    required this.tempDir,
    required this.reportPath,
    required this.comparePath,
    required this.updateBaseline,
  });

  final List<String> sources;
  final String? tempDir;
  final String reportPath;
  final String comparePath;
  final bool updateBaseline;
}

Future<bool> _migrateCommand(List<String> args) async {
  final parsed = _parseMigrateArgs(args);
  if (parsed == null) {
    return false;
  }
  return _runMigration(parsed);
}

_MigrateArgs? _parseMigrateArgs(List<String> args) {
  String? from;
  var langDir = _defaultLangDir;
  var apply = false;
  final targets = <String>[];
  final testTargets = <String>[];

  for (var index = 0; index < args.length; index++) {
    final arg = args[index];

    if ((arg == '--from' || arg == '-from') && index + 1 < args.length) {
      from = args[++index];
      continue;
    }
    if (arg.startsWith('--from=')) {
      from = arg.substring('--from='.length);
      continue;
    }

    if (arg == '--lang-dir' && index + 1 < args.length) {
      langDir = args[++index];
      continue;
    }
    if (arg.startsWith('--lang-dir=')) {
      langDir = arg.substring('--lang-dir='.length);
      continue;
    }

    if (arg == '--target' && index + 1 < args.length) {
      targets.add(args[++index]);
      continue;
    }
    if (arg.startsWith('--target=')) {
      targets.add(arg.substring('--target='.length));
      continue;
    }

    if ((arg == '--test' || arg == '-test') && index + 1 < args.length) {
      testTargets.add(args[++index]);
      continue;
    }
    if (arg.startsWith('--test=')) {
      testTargets.add(arg.substring('--test='.length));
      continue;
    }

    if (arg == '--apply') {
      apply = true;
      continue;
    }

    if (arg == '--dry-run') {
      apply = false;
      continue;
    }

    _err(
      'Usage: migrate --from <package> [--lang-dir <path>] [--target <path>] [--test <path>] [--dry-run|--apply]',
    );
    _err('❌ Unknown migrate option: $arg');
    return null;
  }

  if (from == null || from.trim().isEmpty) {
    _err(
      'Usage: migrate --from <package> [--lang-dir <path>] [--target <path>] [--test <path>] [--dry-run|--apply]',
    );
    _err('Supported packages: ${ConversionHelper.supportedSources.join(', ')}');
    return null;
  }

  return _MigrateArgs(
    from: from.trim(),
    langDir: langDir,
    targets: targets,
    testTargets: testTargets,
    apply: apply,
  );
}

Future<bool> _runMigration(_MigrateArgs args) async {
  if (!ConversionHelper.supports(args.from)) {
    _printUnsupportedConverterMessage(args.from);
    return false;
  }

  try {
    final result = await MigrationHelper.migrate(
      MigrationOptions(
        from: args.from,
        langDir: args.langDir,
        targets: args.targets,
        testTargets: args.testTargets,
        apply: args.apply,
      ),
    );

    final modeLabel = args.apply ? 'Applied' : 'Dry run';
    _out('🛠️  $modeLabel migration for ${args.from}.');
    _out('Files scanned: ${result.filesScanned}');
    _out('Files changed: ${result.changedFiles}');

    for (final fileResult in result.fileResults.where((file) => file.changed)) {
      _out('');
      _out(fileResult.buildPreview());
    }

    if (result.globalWarnings.isNotEmpty) {
      _out('');
      _out('Warnings:');
      for (final warning in result.globalWarnings) {
        _out('  • $warning');
      }
    }

    return true;
  } catch (error) {
    _err('❌ Migration failed: $error');
    return false;
  }
}

Future<bool> _validateMigrationCommand(List<String> args) async {
  final parsed = _parseValidateMigrationArgs(args);
  if (parsed == null) {
    return false;
  }

  try {
    final report = await MigrationValidationHelper.validate(
      MigrationValidationOptions(
        sources: parsed.sources,
        tempDir: parsed.tempDir,
        reportPath: parsed.reportPath,
        comparePath: parsed.comparePath,
        updateBaseline: parsed.updateBaseline,
      ),
    );

    _out('🧪 Migration validation complete.');
    _out('Report: ${parsed.reportPath}');
    _out('Threshold: ${(report.threshold * 100).toStringAsFixed(0)}%');
    _out('');

    for (final result in report.results) {
      final status = result.success ? 'PASS' : 'FAIL';
      _out('${result.sourcePackage}: $status (${result.totalDurationMs}ms total)');
      for (final step in result.steps) {
        final stepStatus = step.success ? 'ok' : 'failed';
        _out('  - ${step.name}: ${step.durationMs}ms [$stepStatus]');
      }
      if (result.warnings.isNotEmpty) {
        _out('  warnings:');
        for (final warning in result.warnings) {
          _out('    - $warning');
        }
      }
      if (result.failureStep != null) {
        _out('  failure-step: ${result.failureStep}');
      }
      _out('');
    }

    if (report.regressions.isNotEmpty) {
      _out('Timing regressions:');
      for (final regression in report.regressions) {
        _out(
          '  - ${regression.sourcePackage}/${regression.stepName}: '
          '${regression.currentMs}ms vs ${regression.baselineMs}ms '
          '(${(regression.ratio * 100).toStringAsFixed(1)}%)',
        );
      }
      _out('');
    }

    if (report.globalWarnings.isNotEmpty) {
      _out('Warnings:');
      for (final warning in report.globalWarnings) {
        _out('  - $warning');
      }
    }

    return !report.hasFunctionalFailures;
  } catch (error) {
    _err('❌ Migration validation failed: $error');
    return false;
  }
}

_ValidateMigrationArgs? _parseValidateMigrationArgs(List<String> args) {
  final sources = <String>[];
  String? tempDir;
  var reportPath = kMigrationValidationDefaultReportPath;
  var comparePath = kMigrationValidationDefaultBaselinePath;
  var updateBaseline = false;

  for (var index = 0; index < args.length; index++) {
    final arg = args[index];

    if (arg == '--from' && index + 1 < args.length) {
      sources.add(args[++index].trim());
      continue;
    }
    if (arg.startsWith('--from=')) {
      sources.add(arg.substring('--from='.length).trim());
      continue;
    }

    if (arg == '--temp-dir' && index + 1 < args.length) {
      tempDir = args[++index];
      continue;
    }
    if (arg.startsWith('--temp-dir=')) {
      tempDir = arg.substring('--temp-dir='.length);
      continue;
    }

    if (arg == '--report' && index + 1 < args.length) {
      reportPath = args[++index];
      continue;
    }
    if (arg.startsWith('--report=')) {
      reportPath = arg.substring('--report='.length);
      continue;
    }

    if (arg == '--compare' && index + 1 < args.length) {
      comparePath = args[++index];
      continue;
    }
    if (arg.startsWith('--compare=')) {
      comparePath = arg.substring('--compare='.length);
      continue;
    }

    if (arg == '--update-baseline') {
      updateBaseline = true;
      continue;
    }

    _err(
      'Usage: validate-migration [--from <package>] [--temp-dir <path>] [--report <path>] [--compare <path>] [--update-baseline]',
    );
    _err('❌ Unknown validate-migration option: $arg');
    return null;
  }

  final normalizedSources = sources.isEmpty
      ? ConversionHelper.supportedSources
      : sources.map((source) => source.trim().toLowerCase()).where((source) => source.isNotEmpty).toList();

  for (final source in normalizedSources) {
    if (!ConversionHelper.supports(source)) {
      _printUnsupportedConverterMessage(source);
      return null;
    }
  }

  return _ValidateMigrationArgs(
    sources: normalizedSources,
    tempDir: tempDir,
    reportPath: reportPath,
    comparePath: comparePath,
    updateBaseline: updateBaseline,
  );
}

void _printUnsupportedConverterMessage(String packageName) {
  final issueUrl = ConversionHelper.buildUnsupportedIssueUrl(packageName);
  _err('Package "$packageName" is not supported yet.');
  _err('');
  _err('You can request support by opening a GitHub issue:');
  _err(issueUrl);
  _err('');
  _err('Please include:');
  _err('- package name');
  _err('- package repository URL');
  _err('- translation file format used');
  _err('- sample localization setup');
  _err('- sample lookup syntax used in code');
}

Future<bool> _validateCommand(List<String> args) async {
  if (args.isEmpty) {
    _err(
      'Usage: validate <lang-dir> [--profile=strict|balanced|lenient] [--disable=rule1,rule2] [--schema-file=<path>] [--extra-as-warnings|--extra-as-errors] [--fail-on-warnings]',
    );
    return false;
  }

  final langDir = args[0];
  final parsedOptions = _parseValidateArgs(args.skip(1).toList());
  if (parsedOptions == null) {
    return false;
  }

  _out('🔍 Validating translations in $langDir...');

  final result = await TranslationValidator.validateTranslations(
    langDir,
    profile: parsedOptions.profile,
    ruleToggles: parsedOptions.ruleToggles,
    treatExtraKeysAsWarnings: parsedOptions.treatExtraKeysAsWarnings,
    failOnWarnings: parsedOptions.failOnWarnings,
    schemaFilePath: parsedOptions.schemaFilePath,
  );

  if (result.isValid) {
    _out('✅ All translations are valid!');
  } else {
    _err('❌ Validation failed:');
    for (final error in result.errors) {
      _err('  • $error');
    }
  }

  if (result.hasWarnings) {
    _out('⚠️  Warnings:');
    for (final warning in result.warnings) {
      _out('  • $warning');
    }
  }

  return result.isValid;
}

class _ValidateArgs {
  const _ValidateArgs({
    required this.profile,
    required this.ruleToggles,
    required this.treatExtraKeysAsWarnings,
    required this.failOnWarnings,
    required this.schemaFilePath,
  });

  final ValidationProfile profile;
  final ValidationRuleToggles ruleToggles;
  final bool? treatExtraKeysAsWarnings;
  final bool? failOnWarnings;
  final String? schemaFilePath;
}

_ValidateArgs? _parseValidateArgs(List<String> args) {
  var profile = ValidationProfile.balanced;
  final disableList = <String>{};
  bool? treatExtraKeysAsWarnings;
  bool? failOnWarnings;
  String? schemaFilePath;

  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--profile' && index + 1 < args.length) {
      final value = args[++index];
      final parsedProfile = _tryParseProfile(value);
      if (parsedProfile == null) {
        _err('❌ Invalid profile value: $value');
        return null;
      }
      profile = parsedProfile;
      continue;
    }

    if (arg.startsWith('--profile=')) {
      final value = arg.split('=').last;
      final parsedProfile = _tryParseProfile(value);
      if (parsedProfile == null) {
        _err('❌ Invalid profile value: $value');
        return null;
      }
      profile = parsedProfile;
      continue;
    }

    if (arg == '--disable' && index + 1 < args.length) {
      disableList.addAll(
        args[++index].split(',').map((item) => item.trim().toLowerCase()).where((item) => item.isNotEmpty),
      );
      continue;
    }

    if (arg.startsWith('--disable=')) {
      disableList.addAll(
        arg.split('=').last.split(',').map((item) => item.trim().toLowerCase()).where((item) => item.isNotEmpty),
      );
      continue;
    }

    if (arg == '--fail-on-warnings') {
      failOnWarnings = true;
      continue;
    }

    if (arg == '--schema-file' && index + 1 < args.length) {
      schemaFilePath = args[++index];
      continue;
    }

    if (arg.startsWith('--schema-file=')) {
      schemaFilePath = arg.substring('--schema-file='.length);
      continue;
    }

    if (arg == '--schema' && index + 1 < args.length) {
      schemaFilePath = args[++index];
      continue;
    }

    if (arg.startsWith('--schema=')) {
      schemaFilePath = arg.substring('--schema='.length);
      continue;
    }

    if (arg == '--extra-as-errors') {
      treatExtraKeysAsWarnings = false;
      continue;
    }

    if (arg == '--extra-as-warnings') {
      treatExtraKeysAsWarnings = true;
      continue;
    }

    _err('❌ Unknown validate option: $arg');
    return null;
  }

  var toggles = const ValidationRuleToggles();
  for (final rule in disableList) {
    switch (rule) {
      case 'missing':
        toggles = toggles.copyWith(checkMissingKeys: false);
        break;
      case 'extra':
        toggles = toggles.copyWith(checkExtraKeys: false);
        break;
      case 'placeholders':
        toggles = toggles.copyWith(checkPlaceholders: false);
        break;
      case 'placeholder-schema':
      case 'schema':
        toggles = toggles.copyWith(checkPlaceholderSchema: false);
        break;
      case 'plural':
        toggles = toggles.copyWith(checkPluralForms: false);
        break;
      case 'gender':
        toggles = toggles.copyWith(checkGenderForms: false);
        break;
      default:
        _err('❌ Unknown rule in --disable: $rule');
        return null;
    }
  }

  return _ValidateArgs(
    profile: profile,
    ruleToggles: toggles,
    treatExtraKeysAsWarnings: treatExtraKeysAsWarnings,
    failOnWarnings: failOnWarnings,
    schemaFilePath: schemaFilePath,
  );
}

ValidationProfile? _tryParseProfile(String value) {
  switch (value.toLowerCase()) {
    case 'strict':
      return ValidationProfile.strict;
    case 'lenient':
      return ValidationProfile.lenient;
    case 'balanced':
      return ValidationProfile.balanced;
    default:
      return null;
  }
}

Future<bool> _catalogCommand(List<String> args) async {
  if (args.isEmpty) {
    _printCatalogHelp();
    return true;
  }

  final subcommand = args.first;
  final normalizedSubcommand = _catalogCommandAliases[subcommand] ?? subcommand;
  final subArgs = args.skip(1).toList();

  switch (normalizedSubcommand) {
    case 'init':
      return _catalogInitCommand(subArgs);
    case 'status':
      return _catalogStatusCommand(subArgs);
    case 'serve':
      return _catalogServeCommand(subArgs);
    case 'add-key':
      return _catalogAddKeyCommand(subArgs);
    case 'review':
      return _catalogReviewCommand(subArgs);
    case 'delete-key':
      return _catalogDeleteKeyCommand(subArgs);
    case 'clean-cache':
      return _catalogCleanCacheCommand(subArgs);
    case 'help':
    case '--help':
    case '-h':
      _printCatalogHelp();
      return true;
    default:
      _err('Unknown catalog subcommand: $subcommand');
      _printCatalogHelp();
      return false;
  }
}

Future<bool> _devCommand(List<String> args) async {
  final withCatalog = args.contains('--with-catalog');
  if (!withCatalog) {
    _err('Usage: dev --with-catalog [--config=<path>] -- <command> [args]');
    return false;
  }

  final separator = args.indexOf('--');
  if (separator == -1 || separator == args.length - 1) {
    _err('Usage: dev --with-catalog [--config=<path>] -- <command> [args]');
    return false;
  }

  final devArgs = args.sublist(0, separator);
  final commandParts = args.sublist(separator + 1);
  final options = _parseOptionArgs(devArgs);
  if (options == null) {
    return false;
  }
  final configPath = options['config'];

  final config = await _loadCatalogConfig(configPath);
  final service = CatalogService(
    config: config,
    projectRootPath: Directory.current.path,
  );
  final runtime = CatalogRuntime(
    service: service,
    config: config,
    host: options['host'] ?? '127.0.0.1',
  );

  try {
    await runtime.start();
  } on Object catch (error) {
    _err('❌ Failed to start catalog sidecar: $error');
    return false;
  }
  _out('📚 Catalog UI: ${runtime.uiUrl}');
  _out('🔌 Catalog API: ${runtime.apiUrl}');

  final executable = commandParts.first;
  final executableArgs = commandParts.skip(1).toList();
  _out('🚀 Running command with catalog sidecar: ${commandParts.join(' ')}');

  late final Process process;
  try {
    process = await Process.start(
      executable,
      executableArgs,
      mode: ProcessStartMode.inheritStdio,
      runInShell: true,
    );
  } on Object catch (error) {
    _err('❌ Failed to run command "$executable": $error');
    await runtime.stop();
    return false;
  }

  final signals = <StreamSubscription<ProcessSignal>>[];
  for (final signal in [ProcessSignal.sigint, ProcessSignal.sigterm]) {
    signals.add(
      signal.watch().listen((_) {
        process.kill(signal);
      }),
    );
  }

  final code = await process.exitCode;
  for (final subscription in signals) {
    await subscription.cancel();
  }
  await runtime.stop();

  if (code != 0) {
    _err('❌ Command exited with code $code');
    return false;
  }
  return true;
}

void _printCatalogHelp() {
  _out('''
Catalog workflow commands:
  catalog init [--config=<path>]                   Create default catalog config file
  catalog status [--config=<path>]                 Print catalog health summary
  catalog serve [--config=<path>] [--host=<host>]  Start API + table UI server
  catalog add-key --key=<path> [--value-xx=...] [--note=<text>]  Create new key in all locales
  catalog add-key --values-file=<json>             Bulk create keys from JSON file
  catalog review --key=<path> --locale=<xx>        Mark a locale cell reviewed (green)
  catalog delete-key --key=<path>                  Delete key across all locales
  catalog clean-cache [--config=<path>]          Clean catalog cache (preserves locales & config)

Examples:
  anas catalog --init
  anas catalog --serve
  anas catalog --run
  anas catalog add-key --key=home.title --value-en="Home" --value-tr="Ana Sayfa"
  anas catalog add-key --key=home.title --value-en="Home" --note="Shown in onboarding"
  anas catalog add-key --values-file=tool/catalog_add_keys.json

Legacy `dart run` forms:
  dart run anas_localization:anas catalog init
  dart run anas_localization:anas catalog serve
  dart run anas_localization:anas catalog add-key --values-file=tool/catalog_add_keys.json
''');
}

bool _isHelpFlag(String value) => value == '--help' || value == '-h';

Future<bool> _catalogInitCommand(List<String> args) async {
  final options = _parseOptionArgs(args);
  if (options == null) {
    return false;
  }

  final configPath = options['config'] ?? CatalogConfig.defaultConfigPath;
  final configFile = File(configPath);
  if (configFile.existsSync()) {
    _out('ℹ️  Catalog config already exists: ${configFile.path}');
    return true;
  }

  await CatalogConfig.writeDefault(path: configPath);
  _out('✅ Created catalog config at ${configFile.path}');
  _out('   Next: dart run anas_localization:anas_cli catalog serve');
  return true;
}

Future<bool> _catalogStatusCommand(List<String> args) async {
  final options = _parseOptionArgs(args);
  if (options == null) {
    return false;
  }

  final config = await _loadCatalogConfig(options['config']);
  final service = CatalogService(
    config: config,
    projectRootPath: Directory.current.path,
  );

  try {
    final meta = await service.loadMeta();
    final summary = await service.loadSummary();
    _out('📦 Catalog Status');
    _out('  Config: ${options['config'] ?? CatalogConfig.defaultConfigPath}');
    _out('  Lang dir: ${meta.langDirectory}');
    _out('  Locales: ${meta.locales.join(', ')}');
    _out('  Source locale: ${meta.sourceLocale}');
    _out('  Keys: ${summary.totalKeys}');
    _out('  Cells -> green: ${summary.greenCount}, warning: ${summary.warningCount}, red: ${summary.redCount}');
    return true;
  } on CatalogOperationException catch (error) {
    _err('❌ ${error.message}');
    return false;
  } on Object catch (error) {
    _err('❌ Failed to read catalog status: $error');
    return false;
  }
}

Future<bool> _catalogServeCommand(List<String> args) async {
  final options = _parseOptionArgs(args);
  if (options == null) {
    return false;
  }

  // Check if --no-build flag is passed
  final noBuild = options['no-build'] == 'true';

  if (!noBuild) {
    // Auto-rebuild web bundle if needed
    await _ensureCatalogWebBundle();
  }

  final config = await _loadCatalogConfig(options['config']);
  final service = CatalogService(
    config: config,
    projectRootPath: Directory.current.path,
  );
  final runtime = CatalogRuntime(
    service: service,
    config: config,
    host: options['host'] ?? '127.0.0.1',
  );

  try {
    await runtime.start();
  } on Object catch (error) {
    _err('❌ Failed to start catalog servers: $error');
    return false;
  }
  _out('📚 Catalog UI: ${runtime.uiUrl}');
  _out('🔌 Catalog API: ${runtime.apiUrl}');

  _out('🧭 Press Ctrl+C to stop.');
  final done = Completer<void>();
  late final StreamSubscription<ProcessSignal> sigInt;
  late final StreamSubscription<ProcessSignal> sigTerm;

  Future<void> shutdown() async {
    if (done.isCompleted) {
      return;
    }
    done.complete();
    await sigInt.cancel();
    await sigTerm.cancel();
    await runtime.stop();
  }

  sigInt = ProcessSignal.sigint.watch().listen((_) => shutdown());
  sigTerm = ProcessSignal.sigterm.watch().listen((_) => shutdown());

  await done.future;
  return true;
}

Future<bool> _catalogAddKeyCommand(List<String> args) async {
  final options = _parseOptionArgs(args);
  if (options == null) {
    return false;
  }

  final config = await _loadCatalogConfig(options.remove('config'));
  final service = CatalogService(
    config: config,
    projectRootPath: Directory.current.path,
  );
  final markGreenIfComplete = _parseBoolFlag(
    options.remove('mark-green-if-complete'),
    fallback: true,
  );
  if (markGreenIfComplete == null) {
    _err('❌ Invalid boolean for --mark-green-if-complete. Use true/false.');
    return false;
  }

  final valuesFilePath = options.remove('values-file');
  final note = options.remove('note');
  if (valuesFilePath != null) {
    late final List<_CatalogCreateRequest> requests;
    try {
      requests = await _loadCatalogCreateRequests(valuesFilePath);
    } on CatalogOperationException catch (error) {
      _err('❌ ${error.message}');
      return false;
    } on FormatException catch (error) {
      _err('❌ Invalid values file format: ${error.message}');
      return false;
    } on Object catch (error) {
      _err('❌ Failed to parse values file "$valuesFilePath": $error');
      return false;
    }
    if (requests.isEmpty) {
      _err('❌ No keys found in values file: $valuesFilePath');
      return false;
    }

    var success = true;
    for (final request in requests) {
      try {
        await service.addKey(
          keyPath: request.keyPath,
          valuesByLocale: request.valuesByLocale,
          note: request.note,
          markGreenIfComplete: markGreenIfComplete,
        );
        _out('✅ Added key "${request.keyPath}"');
      } on CatalogOperationException catch (error) {
        success = false;
        _err('❌ ${error.message}');
      } on Object catch (error) {
        success = false;
        _err('❌ Failed adding key "${request.keyPath}": $error');
      }
    }
    return success;
  }

  final keyPath = options.remove('key');
  if (keyPath == null || keyPath.trim().isEmpty) {
    _err('Usage: catalog add-key --key=<path> [--value-<locale>=<value>] [--note=<text>] [--config=<path>]');
    return false;
  }

  final valuesByLocale = _extractLocaleValueOptions(options);
  if (options.isNotEmpty) {
    _err('❌ Unknown options: ${options.keys.join(', ')}');
    return false;
  }

  try {
    final row = await service.addKey(
      keyPath: keyPath,
      valuesByLocale: valuesByLocale,
      note: note,
      markGreenIfComplete: markGreenIfComplete,
    );
    _out('✅ Added key "${row.keyPath}"');
    final statuses = row.cellStates.entries
        .map((entry) => '${entry.key}:${catalogCellStatusToString(entry.value.status)}')
        .join(', ');
    _out('   statuses => $statuses');
    return true;
  } on CatalogOperationException catch (error) {
    _err('❌ ${error.message}');
    return false;
  } on Object catch (error) {
    _err('❌ Failed to add key "$keyPath": $error');
    return false;
  }
}

Future<bool> _catalogReviewCommand(List<String> args) async {
  final options = _parseOptionArgs(args);
  if (options == null) {
    return false;
  }

  final keyPath = options.remove('key');
  final locale = options.remove('locale');
  if (keyPath == null || locale == null) {
    _err('Usage: catalog review --key=<path> --locale=<locale> [--config=<path>]');
    return false;
  }

  final config = await _loadCatalogConfig(options.remove('config'));
  if (options.isNotEmpty) {
    _err('❌ Unknown options: ${options.keys.join(', ')}');
    return false;
  }

  final service = CatalogService(
    config: config,
    projectRootPath: Directory.current.path,
  );
  try {
    await service.markReviewed(
      keyPath: keyPath,
      locale: locale,
    );
    _out('✅ Marked "$keyPath" for "$locale" as reviewed');
    return true;
  } on CatalogOperationException catch (error) {
    _err('❌ ${error.message}');
    return false;
  } on Object catch (error) {
    _err('❌ Failed to mark reviewed: $error');
    return false;
  }
}

Future<bool> _catalogDeleteKeyCommand(List<String> args) async {
  final options = _parseOptionArgs(args);
  if (options == null) {
    return false;
  }

  final keyPath = options.remove('key');
  if (keyPath == null || keyPath.trim().isEmpty) {
    _err('Usage: catalog delete-key --key=<path> [--config=<path>]');
    return false;
  }

  final config = await _loadCatalogConfig(options.remove('config'));
  if (options.isNotEmpty) {
    _err('❌ Unknown options: ${options.keys.join(', ')}');
    return false;
  }

  final service = CatalogService(
    config: config,
    projectRootPath: Directory.current.path,
  );
  try {
    await service.deleteKey(keyPath);
    _out('✅ Deleted key "$keyPath"');
    return true;
  } on CatalogOperationException catch (error) {
    _err('❌ ${error.message}');
    return false;
  } on Object catch (error) {
    _err('❌ Failed to delete key: $error');
    return false;
  }
}

Future<bool> _catalogCleanCacheCommand(List<String> args) async {
  final options = _parseOptionArgs(args);
  if (options == null) {
    return false;
  }

  final config = await _loadCatalogConfig(options.remove('config'));
  if (options.isNotEmpty) {
    _err('❌ Unknown options: ${options.keys.join(', ')}');
    return false;
  }

  final projectRoot = Directory.current.path;
  final statePath = config.resolveStateFilePath(projectRoot);
  final stateFile = File(statePath);

  int deletedFiles = 0;

  // Delete the state file
  if (stateFile.existsSync()) {
    try {
      stateFile.deleteSync();
      deletedFiles++;
      _out('🗑️  Deleted state file: $statePath');
    } catch (e) {
      _err('❌ Failed to delete state file: $e');
    }
  }

  // Check for .anas_localization directory
  final dirPath = p.join(projectRoot, '.anas_localization');
  final dir = Directory(dirPath);
  if (dir.existsSync()) {
    try {
      dir.deleteSync(recursive: true);
      deletedFiles++;
      _out('🗑️  Deleted cache directory: $dirPath');
    } catch (e) {
      _err('❌ Failed to delete cache directory: $e');
    }
  }

  if (deletedFiles == 0) {
    _out('✅ No cache files found. Catalog is already clean.');
  } else {
    _out('✅ Cleaned $deletedFiles cache file(s).');
    _out('   Note: Your locale files and config are preserved.');
  }

  return true;
}

Future<void> _ensureCatalogWebBundle() async {
  final bundleDir =
      Directory(p.join(Directory.current.path, 'lib', 'src', 'features', 'catalog', 'server', 'flutter_web_bundle'));
  final appDir = Directory(p.join(Directory.current.path, 'tool', 'catalog_app'));

  // Check if bundle exists
  if (!bundleDir.existsSync()) {
    _out('📦 Building catalog web bundle (first time setup)...');
    await _buildCatalogWebBundle();
    return;
  }

  // Check if bundle is outdated by comparing timestamps
  final bundleMain = File(p.join(bundleDir.path, 'flutter_bootstrap.js'));
  final appMain = File(p.join(appDir.path, 'lib', 'main.dart'));

  if (!bundleMain.existsSync() || !appMain.existsSync()) {
    _out('📦 Building catalog web bundle (missing files)...');
    await _buildCatalogWebBundle();
    return;
  }

  final bundleTime = bundleMain.lastModifiedSync();
  final appTime = appMain.lastModifiedSync();

  if (appTime.isAfter(bundleTime)) {
    _out('📦 Catalog web bundle is outdated. Rebuilding...');
    await _buildCatalogWebBundle();
    return;
  }

  // Also check pubspec.yaml for changes
  final appPubspec = File(p.join(appDir.path, 'pubspec.yaml'));
  final bundleIndex = File(p.join(bundleDir.path, 'index.html'));

  if (appPubspec.existsSync() && bundleIndex.existsSync()) {
    final pubspecTime = appPubspec.lastModifiedSync();
    final indexTime = bundleIndex.lastModifiedSync();

    if (pubspecTime.isAfter(indexTime)) {
      _out('📦 Catalog dependencies updated. Rebuilding...');
      await _buildCatalogWebBundle();
      return;
    }
  }

  _out('✅ Using existing catalog web bundle');
}

Future<void> _buildCatalogWebBundle() async {
  final buildScript = File(p.join(Directory.current.path, 'tool', 'build_catalog_web.sh'));

  if (!buildScript.existsSync()) {
    _err('❌ Build script not found: tool/build_catalog_web.sh');
    throw StateError('Build script not found');
  }

  final result = await Process.run('bash', [buildScript.path], runInShell: true);

  if (result.exitCode != 0) {
    _err('❌ Failed to build catalog web bundle: ${result.stderr}');
    throw StateError('Build failed');
  }
}

Future<CatalogConfig> _loadCatalogConfig(String? path) async {
  final configPath = path?.trim();
  if (configPath == null || configPath.isEmpty) {
    return CatalogConfig.load();
  }
  return CatalogConfig.load(path: configPath);
}

Map<String, dynamic> _extractLocaleValueOptions(Map<String, String> options) {
  final valuesByLocale = <String, dynamic>{};
  final keys = options.keys.toList();
  for (final key in keys) {
    if (!key.startsWith('value-')) {
      continue;
    }
    final locale = key.substring('value-'.length).trim();
    if (locale.isEmpty) {
      continue;
    }
    final rawValue = options.remove(key) ?? '';
    valuesByLocale[locale] = TranslationFileParser.decodeMaybeJsonValue(rawValue);
  }
  return valuesByLocale;
}

Future<List<_CatalogCreateRequest>> _loadCatalogCreateRequests(String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    throw CatalogOperationException('Values file not found: $path');
  }

  final decoded = jsonDecode(await file.readAsString());
  final requests = <_CatalogCreateRequest>[];
  if (decoded is List) {
    for (final item in decoded) {
      final request = _parseCatalogCreateRequest(item);
      if (request != null) {
        requests.add(request);
      }
    }
    return requests;
  }

  if (decoded is Map) {
    final map = Map<String, dynamic>.from(decoded);
    final entries = map['keys'];
    if (entries is List) {
      for (final item in entries) {
        final request = _parseCatalogCreateRequest(item);
        if (request != null) {
          requests.add(request);
        }
      }
      return requests;
    }

    final single = _parseCatalogCreateRequest(map);
    if (single != null) {
      requests.add(single);
      return requests;
    }

    for (final entry in map.entries) {
      if (entry.key == 'keys') {
        continue;
      }
      if (entry.value is! Map) {
        continue;
      }
      final values = <String, dynamic>{};
      final rawValues = Map<dynamic, dynamic>.from(entry.value as Map);
      for (final valueEntry in rawValues.entries) {
        values[valueEntry.key.toString()] = valueEntry.value;
      }
      requests.add(
        _CatalogCreateRequest(
          keyPath: entry.key.toString(),
          valuesByLocale: values,
        ),
      );
    }
    return requests;
  }

  throw const FormatException('Values file must be a JSON object or list.');
}

_CatalogCreateRequest? _parseCatalogCreateRequest(dynamic value) {
  if (value is! Map) {
    return null;
  }

  final map = Map<String, dynamic>.from(value);
  final keyPath = map['keyPath']?.toString();
  if (keyPath == null || keyPath.trim().isEmpty) {
    return null;
  }

  final valuesByLocale = <String, dynamic>{};
  final rawValues = map['valuesByLocale'];
  if (rawValues is Map) {
    for (final entry in rawValues.entries) {
      valuesByLocale[entry.key.toString()] = entry.value;
    }
  }
  return _CatalogCreateRequest(
    keyPath: keyPath,
    valuesByLocale: valuesByLocale,
    note: map['note']?.toString(),
  );
}

Map<String, String>? _parseOptionArgs(List<String> args) {
  final options = <String, String>{};
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (!arg.startsWith('--')) {
      _err('❌ Unexpected argument "$arg". Use --key=value style options.');
      return null;
    }

    final withoutPrefix = arg.substring(2);
    if (withoutPrefix.contains('=')) {
      final splitIndex = withoutPrefix.indexOf('=');
      final key = withoutPrefix.substring(0, splitIndex);
      final value = withoutPrefix.substring(splitIndex + 1);
      options[key] = value;
      continue;
    }

    final key = withoutPrefix;
    final hasValue = index + 1 < args.length && !args[index + 1].startsWith('--');
    if (hasValue) {
      options[key] = args[index + 1];
      index++;
      continue;
    }
    options[key] = 'true';
  }
  return options;
}

bool? _parseBoolFlag(String? value, {required bool fallback}) {
  if (value == null || value.trim().isEmpty) {
    return fallback;
  }
  final normalized = value.trim().toLowerCase();
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return null;
}

class _CatalogCreateRequest {
  const _CatalogCreateRequest({
    required this.keyPath,
    required this.valuesByLocale,
    this.note,
  });

  final String keyPath;
  final Map<String, dynamic> valuesByLocale;
  final String? note;
}

Future<bool> _addKeyCommand(List<String> args) async {
  if (args.length < 2) {
    _err('Usage: add-key <key> <value> [lang-dir]');
    return false;
  }

  final key = args[0];
  final value = args[1];
  final langDir = args.length > 2 ? args[2] : _defaultLangDir;

  _out('➕ Adding key "$key" to all translation files...');

  final dir = Directory(langDir);
  if (!dir.existsSync()) {
    _err('❌ Language directory not found: $langDir');
    return false;
  }

  var success = true;
  final jsonFiles = _jsonFilesInDir(dir).toList();

  for (final file in jsonFiles) {
    try {
      final data = await _readJsonFile(file);

      if (!_hasPath(data, key)) {
        _setValueByPath(data, key, value, overwrite: true);
        await _writeJsonFile(file, data);
        _out('  ✅ Added to ${file.uri.pathSegments.last}');
      } else {
        _out('  ⚠️  Key already exists in ${file.uri.pathSegments.last} at "$key"');
      }
    } catch (e) {
      success = false;
      _err('  ❌ Failed to update ${file.uri.pathSegments.last}: $e');
    }
  }

  return success;
}

Future<bool> _statsCommand(List<String> args) async {
  if (args.isEmpty) {
    _err('Usage: stats <lang-dir>');
    return false;
  }

  final langDir = args[0];
  final dir = Directory(langDir);

  if (!dir.existsSync()) {
    _err('❌ Language directory not found: $langDir');
    return false;
  }

  _out('📊 Translation Statistics for $langDir\n');

  var success = true;
  final jsonFiles = _jsonFilesInDir(dir);

  final stats = <String, Map<String, dynamic>>{};

  for (final file in jsonFiles) {
    final locale = file.uri.pathSegments.last.replaceAll('.json', '');
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final keyCount = _countKeys(data);
      final stringCount = _countStrings(data);
      final pluralCount = _countPluralKeys(data);

      stats[locale] = {
        'keys': keyCount,
        'strings': stringCount,
        'plurals': pluralCount,
        'fileSize': await file.length(),
      };
    } catch (e) {
      success = false;
      _err('❌ Failed to analyze $locale.json: $e');
    }
  }

  // Print statistics table
  _out('Locale\tKeys\tStrings\tPlurals\tSize');
  _out('─' * 40);
  for (final entry in stats.entries) {
    final data = entry.value;
    final row = [
      entry.key,
      '${data['keys']}',
      '${data['strings']}',
      '${data['plurals']}',
      _formatFileSize(data['fileSize'] as int),
    ].join('\t');
    _out(row);
  }

  return success;
}

int _countKeys(Map<String, dynamic> map) {
  int count = 0;
  for (final value in map.values) {
    if (value is Map<String, dynamic>) {
      count += _countKeys(value);
    } else {
      count++;
    }
  }
  return count;
}

int _countStrings(Map<String, dynamic> map) {
  int count = 0;
  for (final value in map.values) {
    if (value is String) {
      count++;
    } else if (value is Map<String, dynamic>) {
      count += _countStrings(value);
    }
  }
  return count;
}

int _countPluralKeys(Map<String, dynamic> map) {
  int count = 0;
  for (final value in map.values) {
    if (value is Map<String, dynamic>) {
      final hasPlural = value.keys.any((k) => ['zero', 'one', 'two', 'few', 'many', 'other'].contains(k));
      if (hasPlural) count++;
    }
  }
  return count;
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
}

Future<bool> _addLocaleCommand(List<String> args) async {
  if (args.isEmpty) {
    _err('Usage: add-locale <locale> [template-locale] [lang-dir]');
    return false;
  }

  final locale = args[0];
  final templateLocale = args.length > 1 ? args[1] : 'en';
  var langDir = args.length > 2 ? args[2] : _defaultLangDir;

  // Try to detect format from catalog config
  CatalogFileFormat format = CatalogFileFormat.json;
  try {
    final config = await CatalogConfig.load();
    format = config.format;
    // Use config's langDir if not explicitly provided
    if (args.length <= 2) {
      langDir = config.langDir;
    }
  } catch (_) {
    // Use default if config loading fails
  }

  final extension = format == CatalogFileFormat.yaml ? 'yaml' : 'json';
  final dir = Directory(langDir);

  if (!dir.existsSync()) {
    _err('❌ Language directory not found: $langDir');
    return false;
  }

  final targetFile = File('$langDir/$locale.$extension');
  if (targetFile.existsSync()) {
    _err('❌ Locale file already exists: ${targetFile.path}');
    return false;
  }

  // Find template file with any supported extension
  File? templateFile;
  final templateExtensions = format == CatalogFileFormat.yaml ? ['yaml', 'yml', 'json'] : ['json'];

  for (final ext in templateExtensions) {
    final candidate = File('$langDir/$templateLocale.$ext');
    if (candidate.existsSync()) {
      templateFile = candidate;
      break;
    }
  }

  if (templateFile == null) {
    // Try to find any template file in the directory
    final candidates = _localeFilesInDir(dir).toList();
    if (candidates.isEmpty) {
      _err('❌ No template files found in $langDir');
      return false;
    }
    templateFile = candidates.first;
  }

  // At this point, templateFile is guaranteed to be non-null
  final templateFilePath = templateFile.path;

  try {
    Map<String, dynamic> localeMap;

    if (templateFilePath.endsWith('.json')) {
      final templateMap = await _readJsonFile(templateFile);
      localeMap = _cloneStructureForNewLocale(templateMap);
      await _writeJsonFile(targetFile, localeMap);
    } else {
      // For YAML, create empty structure
      localeMap = <String, dynamic>{};
      await _writeYamlFile(targetFile, localeMap);
    }

    _out('✅ Added locale file: ${targetFile.path}');
    return true;
  } catch (error) {
    _err('❌ Failed to add locale "$locale": $error');
    return false;
  }
}

// ---------------------------------------------------------------------------
// Init command
// ---------------------------------------------------------------------------

class _InitArgs {
  const _InitArgs({
    required this.locale,
    required this.locales,
    required this.fileFormat,
    required this.langDir,
    required this.configPath,
    required this.projectPath,
  });

  final String locale;
  final List<String> locales;
  final String fileFormat;
  final String langDir;
  final String configPath;
  final String? projectPath;
}

Future<bool> _initCommand(List<String> args) async {
  // Check for help flag
  if (args.isNotEmpty && (args.contains('--help') || args.contains('-h'))) {
    _printInitHelp();
    return true;
  }

  final parsed = _parseInitArgs(args);
  if (parsed == null) {
    return false;
  }

  // Save original working directory
  final originalDir = Directory.current.path;
  String workingDir = originalDir;

  // Change to project directory if specified
  if (parsed.projectPath != null) {
    final projectDir = Directory(parsed.projectPath!);
    if (!projectDir.existsSync()) {
      _err('❌ Project directory not found: ${parsed.projectPath}');
      return false;
    }
    Directory.current = parsed.projectPath!;
    workingDir = parsed.projectPath!;
    _out('📂 Working in: $workingDir');
  }

  // Create language directory
  final langDir = Directory(parsed.langDir);
  if (!langDir.existsSync()) {
    try {
      await langDir.create(recursive: true);
      _out('📁 Created language directory: ${parsed.langDir}');
    } catch (error) {
      _err('❌ Failed to create language directory: $error');
      return false;
    }
  }

  // Create locale files
  final format = catalogFileFormatFromString(parsed.fileFormat);
  final extension = format == CatalogFileFormat.yaml ? 'yaml' : 'json';

  for (final locale in parsed.locales) {
    final filePath = '${parsed.langDir}/$locale.$extension';
    final file = File(filePath);

    if (file.existsSync()) {
      _out('⚠️  Locale file already exists: $filePath');
      continue;
    }

    try {
      if (format == CatalogFileFormat.yaml) {
        await _writeYamlFile(file, <String, dynamic>{});
      } else {
        await _writeJsonFile(file, <String, dynamic>{});
      }
      _out('✅ Created locale file: $filePath');
    } catch (error) {
      _err('❌ Failed to create locale file "$filePath": $error');
      return false;
    }
  }

  // Create or update catalog config
  final configFile = File(parsed.configPath);
  CatalogConfig config;

  if (configFile.existsSync()) {
    try {
      config = await CatalogConfig.load(path: parsed.configPath);
      // Update with new values
      config = config.copyWith(
        langDir: parsed.langDir,
        format: format,
        fallbackLocale: parsed.locale,
      );
    } catch (error) {
      _err('⚠️  Failed to load existing config, creating new one: $error');
      config = CatalogConfig(
        version: 1,
        langDir: parsed.langDir,
        format: format,
        fallbackLocale: parsed.locale,
        sourceLocale: parsed.locale,
        stateFile: '.anas_localization/catalog_state.json',
        uiPort: 4466,
        apiPort: 4467,
        openBrowser: true,
        arbFilePrefix: 'app',
      );
    }
  } else {
    config = CatalogConfig(
      version: 1,
      langDir: parsed.langDir,
      format: format,
      fallbackLocale: parsed.locale,
      sourceLocale: parsed.locale,
      stateFile: '.anas_localization/catalog_state.json',
      uiPort: 4466,
      apiPort: 4467,
      openBrowser: true,
      arbFilePrefix: 'app',
    );
  }

  try {
    await CatalogConfig.writeConfig(path: parsed.configPath, config: config);
    _out('✅ Updated catalog config at ${configFile.path}');
  } catch (error) {
    _err('❌ Failed to write catalog config: $error');
    return false;
  }

  _out('');
  _out('🎉 Project initialized successfully!');
  _out('   Fallback locale: ${parsed.locale}');
  _out('   Locales created: ${parsed.locales.join(", ")}');
  _out('   Format: ${parsed.fileFormat}');
  _out('');

  _out('Next steps:');
  _out('  dart run anas_localization:anas_cli catalog serve');
  return true;
}

void _printInitHelp() {
  _out('''
init -- Initialize a new localization project

Usage:
  dart run anas_localization:anas_cli init --locale <code> [options]

Options:
  --locale <code>        Required. The fallback/source locale code (e.g., tr, en, ar)
  --locales <codes>     Additional locales to create, comma-separated (e.g., tr,en,ar)
  --file <format>       Output format: json or yaml (default: json)
  --lang-dir <path>     Language directory path (default: assets/lang)
  --config <path>       Catalog config file path (default: anas_catalog.yaml)
  --path <directory>    Project directory to initialize in (default: current directory)
  --help, -h            Show this help message

Description:
  Initializes a new localization project by creating:
  - Locale files in the specified format
  - A catalog config file with the specified fallback locale

Examples:
  # Initialize with default settings (JSON format, current directory)
  dart run anas_localization:anas_cli init --locale tr

  # Initialize with multiple locales
  dart run anas_localization:anas_cli init --locale tr --locales tr,en,ar

  # Initialize with YAML format
  dart run anas_localization:anas_cli init --locale tr --file yaml

  # Initialize in a specific directory
  dart run anas_localization:anas_cli init --locale tr --path /path/to/project

  # Initialize with custom language directory
  dart run anas_localization:anas_cli init --locale tr --lang-dir lib/l10n

  # Initialize with all options
  dart run anas_localization:anas_cli init --locale tr --locales tr,en --file yaml --lang-dir lib/l10n --path /path/to/project
''');
}

void _printSourceLocaleHelp() {
  _out('''
source_locale -- Set the source locale for the catalog

Usage:
  dart run anas_localization:anas_cli source_locale <locale> [options]

Arguments:
  <locale>             Required. The source locale code (e.g., en, tr)

Options:
  --config=<path>      Catalog config file path (default: anas_catalog.yaml)
  --help, -h          Show this help message

Description:
  Updates the source locale in the catalog config. The source locale is the
  base language used for translations. All other locales are translations of
  this source locale.

  Note: The locale file must exist in the configured language directory.

Examples:
  # Set source locale to English
  dart run anas_localization:anas_cli source_locale en

  # Set source locale with custom config
  dart run anas_localization:anas_cli source_locale tr --config=custom_config.yaml
''');
}

_InitArgs? _parseInitArgs(List<String> args) {
  String? locale;
  List<String> locales = [];
  var fileFormat = 'json';
  var langDir = _defaultLangDir;
  var configPath = CatalogConfig.defaultConfigPath;
  String? projectPath;

  for (var index = 0; index < args.length; index++) {
    final arg = args[index];

    if ((arg == '--locale' || arg == '-locale') && index + 1 < args.length) {
      locale = args[++index];
      continue;
    }
    if (arg.startsWith('--locale=')) {
      locale = arg.substring('--locale='.length);
      continue;
    }

    if ((arg == '--locales' || arg == '-locales') && index + 1 < args.length) {
      final localesStr = args[++index];
      locales = localesStr.split(',').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      continue;
    }
    if (arg.startsWith('--locales=')) {
      final localesStr = arg.substring('--locales='.length);
      locales = localesStr.split(',').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      continue;
    }

    if ((arg == '--file' || arg == '-file') && index + 1 < args.length) {
      fileFormat = args[++index].toLowerCase();
      continue;
    }
    if (arg.startsWith('--file=')) {
      fileFormat = arg.substring('--file='.length).toLowerCase();
      continue;
    }

    if ((arg == '--lang-dir' || arg == '-lang-dir') && index + 1 < args.length) {
      langDir = args[++index];
      continue;
    }
    if (arg.startsWith('--lang-dir=')) {
      langDir = arg.substring('--lang-dir='.length);
      continue;
    }

    if ((arg == '--config' || arg == '-config') && index + 1 < args.length) {
      configPath = args[++index];
      continue;
    }
    if (arg.startsWith('--config=')) {
      configPath = arg.substring('--config='.length);
      continue;
    }

    if ((arg == '--path' || arg == '-path') && index + 1 < args.length) {
      projectPath = args[++index];
      continue;
    }
    if (arg.startsWith('--path=')) {
      projectPath = arg.substring('--path='.length);
      continue;
    }

    _err('❌ Unknown init option: $arg');
    _err(
      'Usage: init --locale <code> [--locales <codes>] [--file json|yaml] [--lang-dir <path>] [--config <path>] [--path <project-dir>]',
    );
    return null;
  }

  if (locale == null || locale.trim().isEmpty) {
    _err('❌ --locale is required');
    _err(
      'Usage: init --locale <code> [--locales <codes>] [--file json|yaml] [--lang-dir <path>] [--config <path>] [--path <project-dir>]',
    );
    return null;
  }

  // Default locales to just the fallback locale if not specified
  if (locales.isEmpty) {
    locales = [locale];
  }

  // Validate file format
  if (fileFormat != 'json' && fileFormat != 'yaml') {
    _err('❌ Invalid --file value: $fileFormat. Use "json" or "yaml".');
    return null;
  }

  return _InitArgs(
    locale: locale.trim(),
    locales: locales,
    fileFormat: fileFormat,
    langDir: langDir,
    configPath: configPath,
    projectPath: projectPath,
  );
}

// ---------------------------------------------------------------------------
// Source locale command
// ---------------------------------------------------------------------------

Future<bool> _sourceLocaleCommand(List<String> args) async {
  // Check for help flag
  if (args.isNotEmpty && (args.contains('--help') || args.contains('-h'))) {
    _printSourceLocaleHelp();
    return true;
  }

  if (args.isEmpty) {
    _printSourceLocaleHelp();
    return false;
  }

  final locale = args[0].trim();
  String? configPath;

  // Parse optional config path
  for (final arg in args.skip(1)) {
    if (arg.startsWith('--config=')) {
      configPath = arg.substring('--config='.length);
    }
  }

  final configFilePath = configPath ?? CatalogConfig.defaultConfigPath;
  final configFile = File(configFilePath);

  if (!configFile.existsSync()) {
    _err('❌ Catalog config not found: $configFilePath');
    _err('Run "init" first to create a catalog config.');
    return false;
  }

  CatalogConfig config;
  try {
    config = await CatalogConfig.load(path: configFilePath);
  } catch (error) {
    _err('❌ Failed to load catalog config: $error');
    return false;
  }

  // Validate that the locale file exists
  final langDir = config.resolveLangDirectory(Directory.current.path);
  final format = config.format;
  final extension = format == CatalogFileFormat.yaml ? 'yaml' : 'json';
  final localeFile = File('$langDir/$locale.$extension');

  if (!localeFile.existsSync()) {
    _err('❌ Locale file not found: ${localeFile.path}');
    _err('Available locales: ${config.fallbackLocale}${config.sourceLocale != null ? ", ${config.sourceLocale}" : ""}');
    return false;
  }

  // Update config with new source locale
  final updatedConfig = config.copyWith(sourceLocale: locale);

  try {
    await CatalogConfig.writeConfig(path: configFilePath, config: updatedConfig);
    _out('✅ Updated source locale to: $locale');
    return true;
  } catch (error) {
    _err('❌ Failed to write catalog config: $error');
    return false;
  }
}

// ---------------------------------------------------------------------------
// Helper for writing YAML files
// ---------------------------------------------------------------------------

Future<void> _writeYamlFile(File file, Map<String, dynamic> data) async {
  await file.create(recursive: true);
  final yamlContent = _mapToYaml(data);
  await file.writeAsString(yamlContent);
}

String _mapToYaml(Map<String, dynamic> map, {int indent = 0}) {
  final buffer = StringBuffer();
  final prefix = '  ' * indent;

  for (final entry in map.entries) {
    final key = entry.key;
    final value = entry.value;

    if (value is Map<String, dynamic>) {
      buffer.writeln('$prefix$key:');
      buffer.write(_mapToYaml(value, indent: indent + 1));
    } else if (value is List) {
      buffer.writeln('$prefix$key:');
      for (final item in value) {
        if (item is Map<String, dynamic>) {
          buffer.writeln('$prefix  -');
          buffer.write(_mapToYaml(item, indent: indent + 2));
        } else {
          buffer.writeln('$prefix  - ${_yamlValue(item)}');
        }
      }
    } else {
      buffer.writeln('$prefix$key: ${_yamlValue(value)}');
    }
  }

  return buffer.toString();
}

String _yamlValue(dynamic value) {
  if (value == null) return 'null';
  if (value is String) {
    if (value.contains('\n') || value.contains(':') || value.contains('#')) {
      return '"${value.replaceAll('"', '\\"')}"';
    }
    return value;
  }
  return value.toString();
}

Future<bool> _translateCommand(List<String> args) async {
  if (args.length < 3) {
    _err('Usage: translate <key> <locale> <text> [lang-dir]');
    return false;
  }

  final key = args[0];
  final locale = args[1];
  final text = args[2];
  final langDir = args.length > 3 ? args[3] : _defaultLangDir;
  final file = File('$langDir/$locale.json');

  if (!file.existsSync()) {
    _err('❌ Locale file not found: ${file.path}');
    return false;
  }

  try {
    final data = await _readJsonFile(file);
    _setValueByPath(data, key, text, overwrite: true);
    await _writeJsonFile(file, data);
    _out('✅ Updated "$key" in ${file.uri.pathSegments.last}');
    return true;
  } catch (error) {
    _err('❌ Failed to update translation: $error');
    return false;
  }
}

Future<bool> _removeKeyCommand(List<String> args) async {
  if (args.isEmpty) {
    _err('Usage: remove-key <key> [lang-dir]');
    return false;
  }

  final key = args[0];
  final langDir = args.length > 1 ? args[1] : _defaultLangDir;
  final dir = Directory(langDir);
  if (!dir.existsSync()) {
    _err('❌ Language directory not found: $langDir');
    return false;
  }

  var success = true;
  for (final file in _jsonFilesInDir(dir)) {
    try {
      final data = await _readJsonFile(file);
      final removed = _removeValueByPath(data, key);
      if (removed) {
        await _writeJsonFile(file, data);
        _out('  ✅ Removed from ${file.uri.pathSegments.last}');
      } else {
        _out('  ⚠️  Key not found in ${file.uri.pathSegments.last}');
      }
    } catch (error) {
      success = false;
      _err('  ❌ Failed to update ${file.uri.pathSegments.last}: $error');
    }
  }

  return success;
}

Future<bool> _exportCommand(List<String> args) async {
  if (args.length < 2) {
    _err('Usage: export <lang-dir> <format> [output]');
    return false;
  }

  final langDir = args[0];
  final format = args[1].toLowerCase();
  final defaultOutput = switch (format) {
    'csv' => 'translations_export.csv',
    'arb' => 'arb',
    _ => 'translations_export.json',
  };
  final outputPath = args.length > 2 ? args[2] : defaultOutput;

  final dir = Directory(langDir);
  if (!dir.existsSync()) {
    _err('❌ Language directory not found: $langDir');
    return false;
  }

  final localeData = <String, Map<String, dynamic>>{};
  for (final file in _jsonFilesInDir(dir)) {
    final locale = file.uri.pathSegments.last.replaceAll('.json', '');
    localeData[locale] = await _readJsonFile(file);
  }

  switch (format) {
    case 'json':
      await File(outputPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert(localeData),
      );
      _out('✅ Exported JSON to $outputPath');
      return true;
    case 'csv':
      await _exportCsv(localeData, outputPath);
      _out('✅ Exported CSV to $outputPath');
      return true;
    case 'arb':
      final exported = await _exportArb(localeData, outputPath);
      if (exported) {
        _out('✅ Exported ARB files to $outputPath');
      }
      return exported;
    default:
      _err('❌ Unsupported format: $format. Use "json", "csv", or "arb".');
      return false;
  }
}

Future<bool> _importCommand(List<String> args) async {
  if (args.length < 2) {
    _err('Usage: import <file> <lang-dir>');
    return false;
  }

  final importPath = args[0];
  final importFile = File(importPath);
  final importDirectory = Directory(importPath);
  final langDir = args[1];
  final hasFile = importFile.existsSync();
  final hasDirectory = importDirectory.existsSync();
  if (!hasFile && !hasDirectory) {
    _err('❌ Import source not found: $importPath');
    return false;
  }

  final dir = Directory(langDir);
  await dir.create(recursive: true);

  if (hasDirectory) {
    final arbFiles =
        importDirectory.listSync().whereType<File>().where((file) => file.path.toLowerCase().endsWith('.arb')).toList();
    if (arbFiles.isNotEmpty) {
      return _importArbDirectory(importDirectory, langDir);
    }
    _err('❌ Unsupported directory import source: ${importDirectory.path}');
    return false;
  }

  final extension = importFile.path.split('.').last.toLowerCase();
  switch (extension) {
    case 'json':
      return _importJson(importFile, langDir);
    case 'csv':
      return _importCsv(importFile, langDir);
    case 'arb':
      return _importArbFile(importFile, langDir);
    case 'yaml':
    case 'yml':
      return _importFromL10nYaml(importFile, langDir);
    default:
      _err('❌ Unsupported import file type: .$extension');
      return false;
  }
}

Iterable<File> _jsonFilesInDir(Directory dir) {
  final files = dir.listSync().whereType<File>().where((file) => file.path.endsWith('.json')).toList()
    ..sort((left, right) => left.path.compareTo(right.path));
  return files;
}

Iterable<File> _localeFilesInDir(Directory dir) {
  final files = dir
      .listSync()
      .whereType<File>()
      .where(
        (file) => file.path.endsWith('.json') || file.path.endsWith('.yaml') || file.path.endsWith('.yml'),
      )
      .toList()
    ..sort((left, right) => left.path.compareTo(right.path));
  return files;
}

Future<Map<String, dynamic>> _readJsonFile(File file) async {
  final content = await file.readAsString();
  return jsonDecode(content) as Map<String, dynamic>;
}

Future<void> _writeJsonFile(File file, Map<String, dynamic> data) async {
  await file.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
}

Map<String, dynamic> _cloneStructureForNewLocale(Map<String, dynamic> source) {
  final output = <String, dynamic>{};
  for (final entry in source.entries) {
    output[entry.key] = _cloneValueForNewLocale(entry.value);
  }
  return output;
}

dynamic _cloneValueForNewLocale(dynamic value) {
  if (value is String) {
    return '';
  }

  if (value is Map<String, dynamic>) {
    final map = <String, dynamic>{};
    for (final entry in value.entries) {
      map[entry.key] = _cloneValueForNewLocale(entry.value);
    }
    return map;
  }

  if (value is List) {
    return value.map(_cloneValueForNewLocale).toList();
  }

  return value;
}

bool _setValueByPath(
  Map<String, dynamic> map,
  String path,
  dynamic value, {
  required bool overwrite,
}) {
  final parts = path.split('.');
  if (parts.isEmpty) {
    return false;
  }

  Map<String, dynamic> current = map;
  for (var index = 0; index < parts.length - 1; index++) {
    final part = parts[index];
    final next = current[part];
    if (next is Map<String, dynamic>) {
      current = next;
      continue;
    }
    final created = <String, dynamic>{};
    current[part] = created;
    current = created;
  }

  final leaf = parts.last;
  if (!overwrite && current.containsKey(leaf)) {
    return false;
  }
  current[leaf] = value;
  return true;
}

bool _hasPath(Map<String, dynamic> map, String path) {
  final parts = path.split('.');
  dynamic current = map;
  for (final part in parts) {
    if (current is Map<String, dynamic> && current.containsKey(part)) {
      current = current[part];
    } else {
      return false;
    }
  }
  return true;
}

bool _removeValueByPath(Map<String, dynamic> map, String path) {
  final parts = path.split('.');
  if (parts.isEmpty) {
    return false;
  }

  Map<String, dynamic> current = map;
  for (var index = 0; index < parts.length - 1; index++) {
    final next = current[parts[index]];
    if (next is! Map<String, dynamic>) {
      return false;
    }
    current = next;
  }

  return current.remove(parts.last) != null;
}

Future<void> _exportCsv(
  Map<String, Map<String, dynamic>> localeData,
  String outputPath,
) async {
  final locales = localeData.keys.toList()..sort();
  final flattenedByLocale = <String, Map<String, String>>{};
  final allKeys = <String>{};

  for (final locale in locales) {
    final flattened = <String, String>{};
    _flattenMapForCsv(localeData[locale]!, '', flattened);
    flattenedByLocale[locale] = flattened;
    allKeys.addAll(flattened.keys);
  }

  final orderedKeys = allKeys.toList()..sort();
  final lines = <String>[];
  lines.add(['key', ...locales].map(_escapeCsv).join(','));

  for (final key in orderedKeys) {
    final row = <String>[key];
    for (final locale in locales) {
      row.add(flattenedByLocale[locale]![key] ?? '');
    }
    lines.add(row.map(_escapeCsv).join(','));
  }

  await File(outputPath).writeAsString(lines.join('\n'));
}

void _flattenMapForCsv(
  Map<String, dynamic> map,
  String prefix,
  Map<String, String> output,
) {
  for (final entry in map.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    final value = entry.value;
    if (value is Map<String, dynamic>) {
      _flattenMapForCsv(value, key, output);
    } else if (value is String) {
      output[key] = value;
    } else {
      output[key] = jsonEncode(value);
    }
  }
}

String _escapeCsv(String input) {
  if (input.contains(',') || input.contains('"') || input.contains('\n')) {
    final escaped = input.replaceAll('"', '""');
    return '"$escaped"';
  }
  return input;
}

Future<bool> _importJson(File importFile, String langDir) async {
  try {
    final content = await importFile.readAsString();
    final decoded = jsonDecode(content);
    if (decoded is! Map) {
      _err('❌ JSON import must be an object of locale-to-translations.');
      return false;
    }

    var success = true;
    for (final entry in decoded.entries) {
      final locale = entry.key.toString();
      final value = entry.value;
      if (value is! Map<String, dynamic>) {
        success = false;
        _err('❌ Skipping "$locale": translation value must be an object.');
        continue;
      }
      final file = File('$langDir/$locale.json');
      await _writeJsonFile(file, value);
      _out('✅ Imported $locale (${file.path})');
    }
    return success;
  } catch (error) {
    _err('❌ JSON import failed: $error');
    return false;
  }
}

Future<bool> _importCsv(File importFile, String langDir) async {
  try {
    final lines = await importFile.readAsLines();
    if (lines.isEmpty) {
      _err('❌ CSV import file is empty.');
      return false;
    }

    final header = TranslationFileParser.parseCsvLine(lines.first);
    if (header.length < 2 || header.first != 'key') {
      _err('❌ CSV header must start with "key".');
      return false;
    }

    final locales = header.skip(1).toList();
    final byLocale = <String, Map<String, dynamic>>{
      for (final locale in locales) locale: <String, dynamic>{},
    };

    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final row = TranslationFileParser.parseCsvLine(line);
      if (row.isEmpty) continue;
      final key = row.first;
      for (var index = 0; index < locales.length; index++) {
        final locale = locales[index];
        final value = index + 1 < row.length ? row[index + 1] : '';
        _setValueByPath(
          byLocale[locale]!,
          key,
          TranslationFileParser.decodeMaybeJsonValue(value),
          overwrite: true,
        );
      }
    }

    for (final entry in byLocale.entries) {
      final file = File('$langDir/${entry.key}.json');
      await _writeJsonFile(file, entry.value);
      _out('✅ Imported ${entry.key} (${file.path})');
    }
    return true;
  } catch (error) {
    _err('❌ CSV import failed: $error');
    return false;
  }
}

Future<bool> _exportArb(
  Map<String, Map<String, dynamic>> localeData,
  String outputPath,
) async {
  try {
    final flattened = <String, Map<String, dynamic>>{};
    for (final entry in localeData.entries) {
      final localeFlat = <String, dynamic>{};
      _flattenMapForArb(entry.value, '', localeFlat);
      flattened[entry.key] = localeFlat;
    }

    await ArbInterop.exportArbDirectory(
      localeData: flattened,
      outputDirectory: outputPath,
    );
    return true;
  } catch (error) {
    _err('❌ ARB export failed: $error');
    return false;
  }
}

Future<bool> _importArbFile(File importFile, String langDir) async {
  try {
    final document = ArbInterop.parseArb(
      await importFile.readAsString(),
      fileName: importFile.uri.pathSegments.last,
    );
    final expanded = TranslationFileParser.expandDottedMap(document.translations);
    final output = File('$langDir/${document.locale}.json');
    await _writeJsonFile(output, expanded);
    _out('✅ Imported ${document.locale} (${output.path})');
    return true;
  } catch (error) {
    _err('❌ ARB import failed: $error');
    return false;
  }
}

Future<bool> _importArbDirectory(Directory importDirectory, String langDir) async {
  try {
    final imported = await ArbInterop.importArbDirectory(importDirectory.path);
    for (final entry in imported.entries) {
      final expanded = TranslationFileParser.expandDottedMap(entry.value);
      final output = File('$langDir/${entry.key}.json');
      await _writeJsonFile(output, expanded);
      _out('✅ Imported ${entry.key} (${output.path})');
    }
    return true;
  } catch (error) {
    _err('❌ ARB directory import failed: $error');
    return false;
  }
}

Future<bool> _importFromL10nYaml(File l10nYamlFile, String langDir) async {
  try {
    final imported = await ArbInterop.importUsingL10nYaml(l10nYamlFile.path);
    if (imported.isEmpty) {
      _err('❌ No locale ARB files found for l10n config: ${l10nYamlFile.path}');
      return false;
    }
    for (final entry in imported.entries) {
      final expanded = TranslationFileParser.expandDottedMap(entry.value);
      final output = File('$langDir/${entry.key}.json');
      await _writeJsonFile(output, expanded);
      _out('✅ Imported ${entry.key} (${output.path})');
    }
    return true;
  } catch (error) {
    _err('❌ l10n.yaml import failed: $error');
    return false;
  }
}

void _flattenMapForArb(
  Map<String, dynamic> map,
  String prefix,
  Map<String, dynamic> output,
) {
  for (final entry in map.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    final value = entry.value;

    if (value is String) {
      output[key] = value;
      continue;
    }

    if (value is Map<String, dynamic>) {
      if (_isPluralFormsMap(value) && value.values.every((item) => item is String)) {
        output[key] = _pluralFormsMapToIcu(value);
      } else {
        _flattenMapForArb(value, key, output);
      }
      continue;
    }

    output[key] = jsonEncode(value);
  }
}

bool _isPluralFormsMap(Map<String, dynamic> map) {
  const pluralForms = {'zero', 'one', 'two', 'few', 'many', 'other', 'more'};
  return map.keys.isNotEmpty && map.keys.every(pluralForms.contains);
}

String _pluralFormsMapToIcu(Map<String, dynamic> pluralMap) {
  const orderedForms = ['zero', 'one', 'two', 'few', 'many', 'other'];
  final forms = <String>[];
  for (final form in orderedForms) {
    final value = pluralMap[form];
    if (value is! String) continue;
    final selector = form == 'zero' ? '=0' : form;
    forms.add('$selector{$value}');
  }
  final other = pluralMap['other'];
  if (other is String && !forms.any((entry) => entry.startsWith('other{'))) {
    forms.add('other{$other}');
  }
  if (forms.isEmpty) {
    return '';
  }
  return '{count, plural, ${forms.join(' ')}}';
}
