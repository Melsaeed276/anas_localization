import 'dart:convert';
import 'dart:io';

import 'package:anas_localization/src/core/dictionary.dart';

const _datasetSizes = <int>[1000, 5000, 10000];
const _locales = <String>['en', 'tr', 'ar'];
const _defaultIterations = 60;
const _defaultWarmups = 15;
const _defaultMaxRegression = 0.20;

Future<void> main(List<String> args) async {
  final parsed = _parseArgs(args);
  if (parsed == null) {
    exitCode = 64;
    return;
  }

  final report = _runBenchmark(
    iterations: parsed.iterations,
    warmups: parsed.warmups,
  );

  _printReport(report);

  if (parsed.outputPath != null) {
    final outputFile = File(parsed.outputPath!);
    await outputFile.create(recursive: true);
    await outputFile.writeAsString(const JsonEncoder.withIndent('  ').convert(report.toJson()));
    stdout.writeln('💾 Saved benchmark report to ${outputFile.path}');
  }

  if (parsed.comparePath != null) {
    final baselineFile = File(parsed.comparePath!);
    if (!baselineFile.existsSync()) {
      stderr.writeln('❌ Compare baseline not found: ${baselineFile.path}');
      exitCode = 2;
      return;
    }

    final baseline = BenchmarkReport.fromJson(
      jsonDecode(await baselineFile.readAsString()) as Map<String, dynamic>,
    );
    final regressions = _compareReports(
      current: report,
      baseline: baseline,
      maxRegression: parsed.maxRegression,
    );

    if (regressions.isEmpty) {
      stdout.writeln('✅ No regressions above ${(parsed.maxRegression * 100).toStringAsFixed(1)}%.');
      return;
    }

    stderr.writeln('❌ Performance regressions detected:');
    for (final regression in regressions) {
      stderr.writeln('  - $regression');
    }
    exitCode = 1;
  }
}

class _CliArgs {
  const _CliArgs({
    required this.iterations,
    required this.warmups,
    required this.maxRegression,
    this.outputPath,
    this.comparePath,
  });

  final int iterations;
  final int warmups;
  final double maxRegression;
  final String? outputPath;
  final String? comparePath;
}

_CliArgs? _parseArgs(List<String> args) {
  var iterations = _defaultIterations;
  var warmups = _defaultWarmups;
  var maxRegression = _defaultMaxRegression;
  String? outputPath;
  String? comparePath;

  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--help' || arg == '-h') {
      _printUsage();
      return null;
    }
    if (arg == '--iterations' && index + 1 < args.length) {
      iterations = int.tryParse(args[++index]) ?? -1;
      continue;
    }
    if (arg.startsWith('--iterations=')) {
      iterations = int.tryParse(arg.split('=').last) ?? -1;
      continue;
    }
    if (arg == '--warmups' && index + 1 < args.length) {
      warmups = int.tryParse(args[++index]) ?? -1;
      continue;
    }
    if (arg.startsWith('--warmups=')) {
      warmups = int.tryParse(arg.split('=').last) ?? -1;
      continue;
    }
    if (arg == '--output' && index + 1 < args.length) {
      outputPath = args[++index];
      continue;
    }
    if (arg.startsWith('--output=')) {
      outputPath = arg.split('=').last;
      continue;
    }
    if (arg == '--compare' && index + 1 < args.length) {
      comparePath = args[++index];
      continue;
    }
    if (arg.startsWith('--compare=')) {
      comparePath = arg.split('=').last;
      continue;
    }
    if (arg == '--max-regression' && index + 1 < args.length) {
      maxRegression = double.tryParse(args[++index]) ?? -1;
      continue;
    }
    if (arg.startsWith('--max-regression=')) {
      maxRegression = double.tryParse(arg.split('=').last) ?? -1;
      continue;
    }
    stderr.writeln('❌ Unknown option: $arg');
    _printUsage();
    return null;
  }

  if (iterations < 1 || warmups < 0 || maxRegression < 0) {
    stderr.writeln('❌ Invalid benchmark arguments. Use positive values.');
    _printUsage();
    return null;
  }

  return _CliArgs(
    iterations: iterations,
    warmups: warmups,
    maxRegression: maxRegression,
    outputPath: outputPath,
    comparePath: comparePath,
  );
}

void _printUsage() {
  stdout.writeln('''
Localization benchmark harness

Usage:
  dart run benchmark/localization_benchmark.dart [options]

Options:
  --iterations=<n>       Measured iterations per dataset (default: $_defaultIterations)
  --warmups=<n>          Warmup iterations per dataset (default: $_defaultWarmups)
  --output=<path>        Write benchmark JSON report
  --compare=<path>       Compare with baseline JSON report
  --max-regression=<r>   Allowed regression ratio (default: $_defaultMaxRegression)
''');
}

class BenchmarkReport {
  const BenchmarkReport({
    required this.generatedAtUtc,
    required this.runtime,
    required this.os,
    required this.metrics,
  });

  factory BenchmarkReport.fromJson(Map<String, dynamic> json) {
    return BenchmarkReport(
      generatedAtUtc: json['generatedAtUtc'] as String,
      runtime: json['runtime'] as String,
      os: json['os'] as String,
      metrics: (json['metrics'] as List<dynamic>)
          .map((item) => DatasetBenchmark.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String generatedAtUtc;
  final String runtime;
  final String os;
  final List<DatasetBenchmark> metrics;

  Map<String, dynamic> toJson() {
    return {
      'generatedAtUtc': generatedAtUtc,
      'runtime': runtime,
      'os': os,
      'metrics': metrics.map((item) => item.toJson()).toList(),
    };
  }
}

class DatasetBenchmark {
  const DatasetBenchmark({
    required this.keyCount,
    required this.coldLoadMicros,
    required this.hotSwitchMicros,
    required this.memoryRssMb,
  });

  factory DatasetBenchmark.fromJson(Map<String, dynamic> json) {
    return DatasetBenchmark(
      keyCount: json['keyCount'] as int,
      coldLoadMicros: (json['coldLoadMicros'] as num).toDouble(),
      hotSwitchMicros: (json['hotSwitchMicros'] as num).toDouble(),
      memoryRssMb: (json['memoryRssMb'] as num).toDouble(),
    );
  }

  final int keyCount;
  final double coldLoadMicros;
  final double hotSwitchMicros;
  final double memoryRssMb;

  Map<String, dynamic> toJson() {
    return {
      'keyCount': keyCount,
      'coldLoadMicros': coldLoadMicros,
      'hotSwitchMicros': hotSwitchMicros,
      'memoryRssMb': memoryRssMb,
    };
  }
}

BenchmarkReport _runBenchmark({
  required int iterations,
  required int warmups,
}) {
  final metrics = <DatasetBenchmark>[];

  for (final keyCount in _datasetSizes) {
    final jsonByLocale = _buildDatasetJsonByLocale(keyCount);
    final decodedByLocale = <String, Map<String, dynamic>>{
      for (final entry in jsonByLocale.entries)
        entry.key: Map<String, dynamic>.from(jsonDecode(entry.value) as Map<String, dynamic>),
    };

    final coldLoadMicros = _measureColdLoadMicros(
      jsonByLocale['en']!,
      iterations: iterations,
      warmups: warmups,
    );
    final hotSwitchMicros = _measureHotSwitchMicros(
      decodedByLocale,
      iterations: iterations,
      warmups: warmups,
    );
    final memoryRssMb = _measureMemoryRssMb(
      jsonByLocale,
      copiesPerLocale: 8,
    );

    metrics.add(
      DatasetBenchmark(
        keyCount: keyCount,
        coldLoadMicros: coldLoadMicros,
        hotSwitchMicros: hotSwitchMicros,
        memoryRssMb: memoryRssMb,
      ),
    );
  }

  return BenchmarkReport(
    generatedAtUtc: DateTime.now().toUtc().toIso8601String(),
    runtime: Platform.version,
    os: Platform.operatingSystem,
    metrics: metrics,
  );
}

Map<String, String> _buildDatasetJsonByLocale(int keyCount) {
  final result = <String, String>{};
  for (final locale in _locales) {
    final map = <String, dynamic>{};
    for (var index = 0; index < keyCount; index++) {
      final path = 'feature_${index % 20}.group_${(index ~/ 20) % 25}.key_$index';
      _setValueByPath(
        map,
        path,
        '$locale value $index {count}',
      );
    }

    for (var index = 0; index < (keyCount ~/ 50); index++) {
      final pluralPath = 'plurals.block_${index % 8}.item_$index';
      _setValueByPath(
        map,
        pluralPath,
        {
          'one': '$locale single item',
          'other': '$locale {count} items',
        },
      );
    }

    result[locale] = jsonEncode(map);
  }
  return result;
}

double _measureColdLoadMicros(
  String jsonPayload, {
  required int iterations,
  required int warmups,
}) {
  for (var i = 0; i < warmups; i++) {
    final decoded = Map<String, dynamic>.from(jsonDecode(jsonPayload) as Map<String, dynamic>);
    final dictionary = Dictionary.fromMap(decoded, locale: 'en');
    dictionary.getString('feature_0.group_0.key_0');
    dictionary.getString('feature_1.group_1.key_1');
    dictionary.getString('feature_2.group_2.key_2');
  }

  final samples = <int>[];
  for (var i = 0; i < iterations; i++) {
    final sw = Stopwatch()..start();
    final decoded = Map<String, dynamic>.from(jsonDecode(jsonPayload) as Map<String, dynamic>);
    final dictionary = Dictionary.fromMap(decoded, locale: 'en');
    dictionary.getString('feature_0.group_0.key_0');
    dictionary.getString('feature_1.group_1.key_1');
    dictionary.getString('feature_2.group_2.key_2');
    sw.stop();
    samples.add(sw.elapsedMicroseconds);
  }
  return _median(samples);
}

double _measureHotSwitchMicros(
  Map<String, Map<String, dynamic>> decodedByLocale, {
  required int iterations,
  required int warmups,
}) {
  final switchCount = iterations * _locales.length;

  for (var i = 0; i < warmups * _locales.length; i++) {
    final locale = _locales[i % _locales.length];
    final dictionary = Dictionary.fromMap(
      Map<String, dynamic>.from(decodedByLocale[locale]!),
      locale: locale,
    );
    dictionary.getString('feature_0.group_0.key_0');
    dictionary.getString('feature_1.group_1.key_1');
    dictionary.getString('feature_2.group_2.key_2');
  }

  final samples = <int>[];
  for (var i = 0; i < switchCount; i++) {
    final locale = _locales[i % _locales.length];
    final sw = Stopwatch()..start();
    final dictionary = Dictionary.fromMap(
      Map<String, dynamic>.from(decodedByLocale[locale]!),
      locale: locale,
    );
    dictionary.getString('feature_0.group_0.key_0');
    dictionary.getString('feature_1.group_1.key_1');
    dictionary.getString('feature_2.group_2.key_2');
    sw.stop();
    samples.add(sw.elapsedMicroseconds);
  }
  return _median(samples);
}

double _measureMemoryRssMb(
  Map<String, String> jsonByLocale, {
  required int copiesPerLocale,
}) {
  final before = ProcessInfo.currentRss;
  final retained = <Dictionary>[];
  for (var copy = 0; copy < copiesPerLocale; copy++) {
    for (final locale in _locales) {
      final decoded = Map<String, dynamic>.from(jsonDecode(jsonByLocale[locale]!) as Map<String, dynamic>);
      retained.add(Dictionary.fromMap(decoded, locale: locale));
    }
  }
  if (retained.isEmpty) {
    return 0;
  }
  final after = ProcessInfo.currentRss;
  final deltaBytes = after - before;
  return deltaBytes <= 0 ? 0 : deltaBytes / (1024 * 1024);
}

void _setValueByPath(Map<String, dynamic> map, String path, dynamic value) {
  final parts = path.split('.');
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
  current[parts.last] = value;
}

double _median(List<int> values) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) {
    return sorted[middle].toDouble();
  }
  return (sorted[middle - 1] + sorted[middle]) / 2.0;
}

void _printReport(BenchmarkReport report) {
  stdout.writeln('📊 anas_localization benchmark');
  stdout.writeln('Runtime: ${report.runtime}');
  stdout.writeln('OS: ${report.os}');
  stdout.writeln('Generated (UTC): ${report.generatedAtUtc}');
  stdout.writeln('');
  stdout.writeln('keys\tcold_load_µs\thot_switch_µs\tmemory_rss_mb');
  for (final row in report.metrics) {
    stdout.writeln(
      '${row.keyCount}\t'
      '${row.coldLoadMicros.toStringAsFixed(1)}\t'
      '${row.hotSwitchMicros.toStringAsFixed(1)}\t'
      '${row.memoryRssMb.toStringAsFixed(2)}',
    );
  }
}

List<String> _compareReports({
  required BenchmarkReport current,
  required BenchmarkReport baseline,
  required double maxRegression,
}) {
  final regressions = <String>[];
  final baselineBySize = <int, DatasetBenchmark>{
    for (final row in baseline.metrics) row.keyCount: row,
  };

  for (final row in current.metrics) {
    final baselineRow = baselineBySize[row.keyCount];
    if (baselineRow == null) {
      regressions.add('Missing baseline for dataset ${row.keyCount}.');
      continue;
    }
    _compareMetric(
      regressions,
      keyCount: row.keyCount,
      metricName: 'cold_load_µs',
      currentValue: row.coldLoadMicros,
      baselineValue: baselineRow.coldLoadMicros,
      maxRegression: maxRegression,
    );
    _compareMetric(
      regressions,
      keyCount: row.keyCount,
      metricName: 'hot_switch_µs',
      currentValue: row.hotSwitchMicros,
      baselineValue: baselineRow.hotSwitchMicros,
      maxRegression: maxRegression,
    );
    _compareMetric(
      regressions,
      keyCount: row.keyCount,
      metricName: 'memory_rss_mb',
      currentValue: row.memoryRssMb,
      baselineValue: baselineRow.memoryRssMb,
      maxRegression: maxRegression,
      absoluteTolerance: 2.0,
    );
  }
  return regressions;
}

void _compareMetric(
  List<String> regressions, {
  required int keyCount,
  required String metricName,
  required double currentValue,
  required double baselineValue,
  required double maxRegression,
  double absoluteTolerance = 0,
}) {
  if (baselineValue <= 0) {
    return;
  }
  if ((currentValue - baselineValue).abs() <= absoluteTolerance) {
    return;
  }
  final ratio = (currentValue - baselineValue) / baselineValue;
  if (ratio > maxRegression) {
    regressions.add(
      '$metricName regression on $keyCount keys: '
      '${(ratio * 100).toStringAsFixed(1)}% '
      '(baseline=${baselineValue.toStringAsFixed(2)}, current=${currentValue.toStringAsFixed(2)})',
    );
  }
}
