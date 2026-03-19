library;

import 'dart:convert';
import 'dart:io';

import '../core/sdk_utils.dart';

import 'conversion_helper.dart';

const String kMigrationValidationDefaultReportPath = 'build/migration_validation/report.json';
const String kMigrationValidationDefaultBaselinePath = 'benchmark/migration_validation_baseline.json';
const double kMigrationValidationDefaultThreshold = 0.25;

class MigrationValidationOptions {
  const MigrationValidationOptions({
    this.sources = const <String>[],
    this.tempDir,
    this.reportPath = kMigrationValidationDefaultReportPath,
    this.comparePath = kMigrationValidationDefaultBaselinePath,
    this.updateBaseline = false,
    this.threshold = kMigrationValidationDefaultThreshold,
    this.workingDirectory,
    this.packageRootPath,
  });

  final List<String> sources;
  final String? tempDir;
  final String reportPath;
  final String comparePath;
  final bool updateBaseline;
  final double threshold;
  final String? workingDirectory;
  final String? packageRootPath;
}

class ValidationStepReport {
  const ValidationStepReport({
    required this.name,
    required this.durationMs,
    required this.success,
    this.command,
    this.error,
  });

  factory ValidationStepReport.fromJson(Map<String, dynamic> json) {
    return ValidationStepReport(
      name: json['name'] as String,
      durationMs: (json['durationMs'] as num).toInt(),
      success: json['success'] as bool,
      command: json['command'] as String?,
      error: json['error'] as String?,
    );
  }

  final String name;
  final int durationMs;
  final bool success;
  final String? command;
  final String? error;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'durationMs': durationMs,
      'success': success,
      if (command != null) 'command': command,
      if (error != null) 'error': error,
    };
  }
}

class SourceValidationResult {
  const SourceValidationResult({
    required this.sourcePackage,
    required this.workspacePath,
    required this.success,
    required this.steps,
    required this.totalDurationMs,
    required this.warnings,
    this.failureStep,
  });

  factory SourceValidationResult.fromJson(Map<String, dynamic> json) {
    return SourceValidationResult(
      sourcePackage: json['sourcePackage'] as String,
      workspacePath: json['workspacePath'] as String,
      success: json['success'] as bool,
      steps: (json['steps'] as List<dynamic>)
          .map((item) => ValidationStepReport.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalDurationMs: (json['totalDurationMs'] as num).toInt(),
      warnings: (json['warnings'] as List<dynamic>).map((item) => item.toString()).toList(),
      failureStep: json['failureStep'] as String?,
    );
  }

  final String sourcePackage;
  final String workspacePath;
  final bool success;
  final List<ValidationStepReport> steps;
  final int totalDurationMs;
  final List<String> warnings;
  final String? failureStep;

  Map<String, dynamic> toJson() {
    return {
      'sourcePackage': sourcePackage,
      'workspacePath': workspacePath,
      'success': success,
      'steps': steps.map((item) => item.toJson()).toList(),
      'totalDurationMs': totalDurationMs,
      'warnings': warnings,
      if (failureStep != null) 'failureStep': failureStep,
    };
  }
}

class TimingRegression {
  const TimingRegression({
    required this.sourcePackage,
    required this.stepName,
    required this.baselineMs,
    required this.currentMs,
    required this.threshold,
  });

  factory TimingRegression.fromJson(Map<String, dynamic> json) {
    return TimingRegression(
      sourcePackage: json['sourcePackage'] as String,
      stepName: json['stepName'] as String,
      baselineMs: (json['baselineMs'] as num).toInt(),
      currentMs: (json['currentMs'] as num).toInt(),
      threshold: (json['threshold'] as num).toDouble(),
    );
  }

  final String sourcePackage;
  final String stepName;
  final int baselineMs;
  final int currentMs;
  final double threshold;

  double get ratio => baselineMs == 0 ? 0 : (currentMs - baselineMs) / baselineMs;

  Map<String, dynamic> toJson() {
    return {
      'sourcePackage': sourcePackage,
      'stepName': stepName,
      'baselineMs': baselineMs,
      'currentMs': currentMs,
      'threshold': threshold,
      'ratio': ratio,
    };
  }
}

class MigrationValidationReport {
  const MigrationValidationReport({
    required this.generatedAtUtc,
    required this.os,
    required this.runtime,
    required this.threshold,
    required this.results,
    required this.regressions,
    required this.globalWarnings,
  });

  factory MigrationValidationReport.fromJson(Map<String, dynamic> json) {
    return MigrationValidationReport(
      generatedAtUtc: json['generatedAtUtc'] as String,
      os: json['os'] as String,
      runtime: json['runtime'] as String,
      threshold: (json['threshold'] as num).toDouble(),
      results: (json['results'] as List<dynamic>)
          .map((item) => SourceValidationResult.fromJson(item as Map<String, dynamic>))
          .toList(),
      regressions: (json['regressions'] as List<dynamic>)
          .map((item) => TimingRegression.fromJson(item as Map<String, dynamic>))
          .toList(),
      globalWarnings: (json['globalWarnings'] as List<dynamic>).map((item) => item.toString()).toList(),
    );
  }

  final String generatedAtUtc;
  final String os;
  final String runtime;
  final double threshold;
  final List<SourceValidationResult> results;
  final List<TimingRegression> regressions;
  final List<String> globalWarnings;

  bool get hasFunctionalFailures => results.any((result) => !result.success);

  Map<String, dynamic> toJson() {
    return {
      'generatedAtUtc': generatedAtUtc,
      'os': os,
      'runtime': runtime,
      'threshold': threshold,
      'results': results.map((item) => item.toJson()).toList(),
      'regressions': regressions.map((item) => item.toJson()).toList(),
      'globalWarnings': globalWarnings,
    };
  }
}

class MigrationValidationHelper {
  const MigrationValidationHelper._();

  static Future<MigrationValidationReport> validate(MigrationValidationOptions options) async {
    final workingDirectory = options.workingDirectory ?? Directory.current.path;
    final packageRootPath = options.packageRootPath ?? workingDirectory;
    final sources = options.sources.isEmpty
        ? ConversionHelper.supportedSources
        : options.sources.map((source) => source.trim().toLowerCase()).toList();

    for (final source in sources) {
      if (!ConversionHelper.supports(source)) {
        throw UnsupportedError('Unsupported migration validation source: $source');
      }
    }

    final baseDirectory = await _createBaseDirectory(options.tempDir, workingDirectory);
    final results = <SourceValidationResult>[];

    for (final source in sources) {
      results.add(
        await _validateSource(
          source: source,
          baseDirectory: baseDirectory,
          packageRootPath: packageRootPath,
        ),
      );
    }

    final globalWarnings = <String>[];
    final regressions = <TimingRegression>[];
    final comparePath = PathUtils.isAbsolute(options.comparePath)
        ? options.comparePath
        : PathUtils.join(workingDirectory, options.comparePath);
    final baselineFile = File(comparePath);
    if (baselineFile.existsSync()) {
      final baseline = MigrationValidationReport.fromJson(
        jsonDecode(await baselineFile.readAsString()) as Map<String, dynamic>,
      );
      regressions.addAll(compareReports(current: results, baseline: baseline.results, threshold: options.threshold));
      for (final regression in regressions) {
        globalWarnings.add(
          'Timing regression for ${regression.sourcePackage} ${regression.stepName}: '
          '${regression.currentMs}ms vs ${regression.baselineMs}ms baseline '
          '(${(regression.ratio * 100).toStringAsFixed(1)}%).',
        );
      }
    } else if (!options.updateBaseline) {
      globalWarnings.add('Baseline file not found: $comparePath');
    }

    final report = MigrationValidationReport(
      generatedAtUtc: DateTime.now().toUtc().toIso8601String(),
      os: Platform.operatingSystem,
      runtime: Platform.version.split(' ').first,
      threshold: options.threshold,
      results: results,
      regressions: regressions,
      globalWarnings: globalWarnings,
    );

    final reportPath = PathUtils.isAbsolute(options.reportPath)
        ? options.reportPath
        : PathUtils.join(workingDirectory, options.reportPath);
    await _writeJson(reportPath, report.toJson());

    if (options.updateBaseline) {
      await _writeJson(comparePath, report.toJson());
    }

    return report;
  }

  static List<TimingRegression> compareReports({
    required List<SourceValidationResult> current,
    required List<SourceValidationResult> baseline,
    required double threshold,
  }) {
    final baselineBySource = <String, SourceValidationResult>{
      for (final item in baseline) item.sourcePackage: item,
    };
    final regressions = <TimingRegression>[];

    for (final result in current) {
      final baselineResult = baselineBySource[result.sourcePackage];
      if (baselineResult == null) {
        continue;
      }
      final baselineSteps = <String, ValidationStepReport>{
        for (final step in baselineResult.steps) step.name: step,
      };
      for (final step in result.steps) {
        final baselineStep = baselineSteps[step.name];
        if (baselineStep == null || baselineStep.durationMs <= 0) {
          continue;
        }
        final ratio = (step.durationMs - baselineStep.durationMs) / baselineStep.durationMs;
        if (ratio > threshold) {
          regressions.add(
            TimingRegression(
              sourcePackage: result.sourcePackage,
              stepName: step.name,
              baselineMs: baselineStep.durationMs,
              currentMs: step.durationMs,
              threshold: threshold,
            ),
          );
        }
      }
    }

    return regressions;
  }

  static Future<SourceValidationResult> _validateSource({
    required String source,
    required Directory baseDirectory,
    required String packageRootPath,
  }) async {
    final workspace = Directory(PathUtils.join(baseDirectory.path, source.replaceAll('_', '-')));
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
    workspace.createSync(recursive: true);

    final steps = <ValidationStepReport>[];
    final warnings = <String>[];
    final totalStopwatch = Stopwatch()..start();
    String? failureStep;

    final generation = await _runStep(
      'generate-demo',
      command: 'generate demo',
      action: () async {
        await _generateDemoProject(
          source: source,
          workspace: workspace,
          packageRootPath: packageRootPath,
        );
        return const _CommandOutput(
          exitCode: 0,
          combinedOutput: 'Demo generated.',
        );
      },
    );
    steps.add(generation.step);
    if (!generation.step.success) {
      failureStep = generation.step.name;
    }

    if (failureStep == null) {
      final pubGet = await _runStep(
        'flutter-pub-get',
        command: 'flutter pub get',
        action: () => _runCommand('flutter', ['pub', 'get'], workingDirectory: workspace.path),
      );
      steps.add(pubGet.step);
      if (!pubGet.step.success) {
        failureStep = pubGet.step.name;
      }
    }

    if (failureStep == null) {
      final convert = await _runStep(
        'convert',
        command: 'dart run anas_localization:anas_cli convert --from $source',
        action: () => _runCommand(
          'dart',
          ['run', 'anas_localization:anas_cli', 'convert', '--from', source],
          workingDirectory: workspace.path,
        ),
      );
      steps.add(convert.step);
      if (!convert.step.success) {
        failureStep = convert.step.name;
      }
    }

    if (failureStep == null) {
      final migrate = await _runStep(
        'migrate',
        command: 'dart run anas_localization:anas_cli migrate --from $source --test test --apply',
        action: () => _runCommand(
          'dart',
          [
            'run',
            'anas_localization:anas_cli',
            'migrate',
            '--from',
            source,
            '--test',
            'test',
            '--apply',
          ],
          workingDirectory: workspace.path,
        ),
      );
      steps.add(migrate.step);
      warnings.addAll(_extractWarnings(migrate.output));
      if (!migrate.step.success) {
        failureStep = migrate.step.name;
      }
    }

    if (failureStep == null) {
      final codegen = await _runStep(
        'codegen',
        command: 'dart run anas_localization:localization_gen',
        action: () => _runCommand(
          'dart',
          ['run', 'anas_localization:localization_gen'],
          workingDirectory: workspace.path,
          environment: const {
            'SUPPORTED_LOCALES': 'en,tr',
            'APP_LANG_DIR': 'assets/lang',
          },
        ),
      );
      steps.add(codegen.step);
      if (!codegen.step.success) {
        failureStep = codegen.step.name;
      }
    }

    if (failureStep == null) {
      final analyze = await _runStep(
        'analyze',
        command: 'flutter analyze',
        action: () => _runCommand('flutter', ['analyze'], workingDirectory: workspace.path),
      );
      steps.add(analyze.step);
      if (!analyze.step.success) {
        failureStep = analyze.step.name;
      }
    }

    if (failureStep == null) {
      final test = await _runStep(
        'test',
        command: 'flutter test',
        action: () => _runCommand('flutter', ['test'], workingDirectory: workspace.path),
      );
      steps.add(test.step);
      if (!test.step.success) {
        failureStep = test.step.name;
      }
    }

    totalStopwatch.stop();

    return SourceValidationResult(
      sourcePackage: source,
      workspacePath: workspace.path,
      success: failureStep == null,
      steps: steps,
      totalDurationMs: totalStopwatch.elapsedMilliseconds,
      warnings: warnings,
      failureStep: failureStep,
    );
  }

  static Future<_StepOutcome> _runStep(
    String name, {
    required String command,
    required Future<_CommandOutput> Function() action,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final output = await action();
      stopwatch.stop();
      return _StepOutcome(
        ValidationStepReport(
          name: name,
          durationMs: stopwatch.elapsedMilliseconds,
          success: output.exitCode == 0,
          command: command,
          error: output.exitCode == 0 ? null : output.combinedOutput.trim(),
        ),
        output.combinedOutput,
      );
    } catch (error) {
      stopwatch.stop();
      return _StepOutcome(
        ValidationStepReport(
          name: name,
          durationMs: stopwatch.elapsedMilliseconds,
          success: false,
          command: command,
          error: error.toString(),
        ),
        error.toString(),
      );
    }
  }

  static Future<_CommandOutput> _runCommand(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
    Map<String, String>? environment,
  }) async {
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: true,
    );
    return _CommandOutput(
      exitCode: result.exitCode,
      combinedOutput: '${result.stdout}${result.stderr}',
    );
  }

  static List<String> _extractWarnings(String output) {
    final warnings = <String>[];
    for (final line in const LineSplitter().convert(output)) {
      final trimmed = line.trim();
      if (trimmed.startsWith('• ') ||
          trimmed.contains('Warning') ||
          trimmed.contains('Warnings:') ||
          trimmed.contains('Manual follow-up')) {
        warnings.add(trimmed);
      }
    }
    return warnings;
  }

  static Future<void> _generateDemoProject({
    required String source,
    required Directory workspace,
    required String packageRootPath,
  }) async {
    switch (source) {
      case ConversionHelper.easyLocalization:
        await _generateEasyDemo(workspace, packageRootPath);
        return;
      case ConversionHelper.genL10n:
        await _generateGenL10nDemo(workspace, packageRootPath);
        return;
      default:
        throw UnsupportedError('Unsupported demo generator source: $source');
    }
  }

  static Future<void> _generateEasyDemo(Directory workspace, String packageRootPath) async {
    await _writeFile(
      PathUtils.join(workspace.path, 'pubspec.yaml'),
      '''
name: migration_validation_easy_demo
publish_to: "none"

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  easy_localization: ^3.0.7
  anas_localization:
    path: ${jsonEncode(packageRootPath)}

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: any

flutter:
  uses-material-design: true
  assets:
    - assets/translations/
    - assets/lang/
''',
    );

    await _writeFile(
      PathUtils.join(workspace.path, 'lib', 'main.dart'),
      '''
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('tr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const SourceDemoApp(),
    ),
  );
}

class SourceDemoApp extends StatelessWidget {
  const SourceDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: const HomePage(),
    );
  }
}
''',
    );

    await _writeFile(
      PathUtils.join(workspace.path, 'lib', 'main_migrated.dart'),
      '''
import 'package:anas_localization/localization.dart';
import 'package:flutter/material.dart';
import 'generated/dictionary.dart' as app_dictionary;
import 'home_page.dart';

void main() {
  runApp(const MigratedDemoApp());
}

class MigratedDemoApp extends StatelessWidget {
  const MigratedDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnasLocalization(
      animationSetup: false,
      fallbackLocale: const Locale('en'),
      assetPath: 'assets/lang',
      assetLocales: const [Locale('en'), Locale('tr')],
      dictionaryFactory: (map, {required locale}) {
        return app_dictionary.Dictionary.fromMap(map, locale: locale);
      },
      app: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          home: const HomePage(),
        ),
      ),
    );
  }
}
''',
    );

    await _writeFile(
      PathUtils.join(workspace.path, 'lib', 'home_page.dart'),
      '''
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int count = 1;
  final String userName = 'Anas';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('home.title'.tr(), key: const Key('title')),
          Text('greeting'.tr(namedArgs: {'name': userName}), key: const Key('greeting')),
          Text('cart.items'.plural(count), key: const Key('count')),
          ElevatedButton(
            key: const Key('increment'),
            onPressed: () {
              setState(() {
                count += 1;
              });
            },
            child: const Text('+'),
          ),
          ElevatedButton(
            key: const Key('locale'),
            onPressed: () async {
              await context.setLocale(const Locale('tr'));
            },
            child: const Text('locale'),
          ),
        ],
      ),
    );
  }
}
''',
    );

    await _writeFile(
      PathUtils.join(workspace.path, 'test', 'widget_test.dart'),
      '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migration_validation_easy_demo/main_migrated.dart';

void main() {
  testWidgets('migrated easy demo works', (tester) async {
    await tester.pumpWidget(const MigratedDemoApp());
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.byKey(const Key('title')), findsOneWidget);
    expect(find.byKey(const Key('greeting')), findsOneWidget);
    expect(find.byKey(const Key('count')), findsOneWidget);

    await tester.tap(find.byKey(const Key('increment')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('count')), findsOneWidget);
  });
}
''',
    );

    await _writeJson(
      PathUtils.join(workspace.path, 'assets', 'translations', 'en.json'),
      {
        'home': {'title': 'Home'},
        'greeting': 'Hello {name}',
        'cart': {
          'items': {
            'one': '{count} item',
            'other': '{count} items',
          },
        },
      },
    );
    await _writeJson(
      PathUtils.join(workspace.path, 'assets', 'translations', 'tr.json'),
      {
        'home': {'title': 'Ana Sayfa'},
        'greeting': 'Merhaba {name}',
        'cart': {
          'items': {
            'one': '{count} urun',
            'other': '{count} urun',
          },
        },
      },
    );
  }

  static Future<void> _generateGenL10nDemo(Directory workspace, String packageRootPath) async {
    await _writeFile(
      PathUtils.join(workspace.path, 'pubspec.yaml'),
      '''
name: migration_validation_gen_demo
publish_to: "none"

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  anas_localization:
    path: ${jsonEncode(packageRootPath)}

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: any

flutter:
  generate: true
  uses-material-design: true
  assets:
    - assets/lang/
''',
    );

    await _writeFile(
      PathUtils.join(workspace.path, 'l10n.yaml'),
      '''
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
''',
    );

    await _writeFile(
      PathUtils.join(workspace.path, 'lib', 'main.dart'),
      '''
import 'package:flutter/material.dart';
import 'home_page.dart';

void main() {
  runApp(const SourceDemoApp());
}

class SourceDemoApp extends StatelessWidget {
  const SourceDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}
''',
    );

    await _writeFile(
      PathUtils.join(workspace.path, 'lib', 'main_migrated.dart'),
      '''
import 'package:anas_localization/localization.dart';
import 'package:flutter/material.dart';
import 'generated/dictionary.dart' as app_dictionary;
import 'home_page.dart';

void main() {
  runApp(const MigratedDemoApp());
}

class MigratedDemoApp extends StatelessWidget {
  const MigratedDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnasLocalization(
      animationSetup: false,
      fallbackLocale: const Locale('en'),
      assetPath: 'assets/lang',
      assetLocales: const [Locale('en'), Locale('tr')],
      dictionaryFactory: (map, {required locale}) {
        return app_dictionary.Dictionary.fromMap(map, locale: locale);
      },
      app: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          home: const HomePage(),
        ),
      ),
    );
  }
}
''',
    );

    await _writeFile(
      PathUtils.join(workspace.path, 'lib', 'home_page.dart'),
      '''
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const String userName = 'Anas';
    return Scaffold(
      body: Column(
        children: [
          Text(AppLocalizations.of(context)!.welcomeTitle, key: const Key('title')),
          Text(AppLocalizations.of(context)!.greeting(userName), key: const Key('greeting')),
        ],
      ),
    );
  }
}
''',
    );

    await _writeFile(
      PathUtils.join(workspace.path, 'test', 'widget_test.dart'),
      '''
import 'package:flutter_test/flutter_test.dart';
import 'package:migration_validation_gen_demo/generated/dictionary.dart';
import 'package:migration_validation_gen_demo/main_migrated.dart';

void main() {
  testWidgets('migrated gen_l10n demo works', (tester) async {
    await tester.pumpWidget(const MigratedDemoApp());
    await tester.pumpAndSettle();

    expect(find.text(getDictionary().welcomeTitle), findsOneWidget);
    expect(find.text(getDictionary().greeting(name: 'Anas')), findsOneWidget);
  });
}
''',
    );

    await _writeJson(
      PathUtils.join(workspace.path, 'lib', 'l10n', 'app_en.arb'),
      {
        '@@locale': 'en',
        'welcome_title': 'Welcome',
        'greeting': 'Hello {name}',
        '@greeting': {
          'placeholders': {
            'name': {},
          },
        },
      },
    );
    await _writeJson(
      PathUtils.join(workspace.path, 'lib', 'l10n', 'app_tr.arb'),
      {
        '@@locale': 'tr',
        'welcome_title': 'Hos Geldin',
        'greeting': 'Merhaba {name}',
        '@greeting': {
          'placeholders': {
            'name': {},
          },
        },
      },
    );
  }

  static Future<Directory> _createBaseDirectory(String? configuredTempDir, String workingDirectory) async {
    if (configuredTempDir != null) {
      final directory = Directory(
        PathUtils.isAbsolute(configuredTempDir)
            ? configuredTempDir
            : PathUtils.join(workingDirectory, configuredTempDir),
      );
      await directory.create(recursive: true);
      final unique = Directory(PathUtils.join(directory.path, DateTime.now().millisecondsSinceEpoch.toString()));
      await unique.create(recursive: true);
      return unique;
    }
    return Directory.systemTemp.createTempSync('migration_validation_');
  }

  static Future<void> _writeFile(String path, String content) async {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(content);
  }

  static Future<void> _writeJson(String path, Map<String, dynamic> data) async {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }
}

class _CommandOutput {
  const _CommandOutput({
    required this.exitCode,
    required this.combinedOutput,
  });

  final int exitCode;
  final String combinedOutput;
}

class _StepOutcome {
  const _StepOutcome(this.step, this.output);

  final ValidationStepReport step;
  final String output;
}
