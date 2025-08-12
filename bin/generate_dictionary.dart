// bin/generate_dictionary.dart
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:localization/src/utils/codegen_utils.dart';


Future<void> main(List<String> args) async {
  final pkgRoot = await _resolvePackageRoot();

// Pick the correct package lang dir (your case: <pkg>/assets/lang)
  final pkgLangDir = await _pickExistingDir([
    File.fromUri(pkgRoot.resolve('assets/lang')).path,      // canonical
    File.fromUri(pkgRoot.resolve('lib/assets/lang')).path,  // safety net
  ]) ?? _die('❌ Could not find package lang folder. Tried:\n'
      ' - ${File.fromUri(pkgRoot.resolve('assets/lang')).path}\n'
      ' - ${File.fromUri(pkgRoot.resolve('lib/assets/lang')).path}');

  // Where to look for app overrides (both are optional)
  final appLangDirs = <String>[
    Platform.environment['APP_LANG_DIR'] ?? 'assets/lang',
    'example/assets/lang', // when run from package root
  ];

  // Output always to the package lib/ by default
  final defaultOutPath =
      File.fromUri(pkgRoot.resolve('lib/src/generated/dictionary.dart')).path;
  final outPath = Platform.environment['OUTPUT_DART'] ?? defaultOutPath;

  // Find supported locales from the picked package lang dir, or env
  final supported = await _getSupportedLocales(
    fromEnv: Platform.environment['SUPPORTED_LOCALES'],
    packageLangDir: pkgLangDir,
  );

  // Load+merge per locale
  final mergedByLang = <String, Map<String, dynamic>>{};
  for (final code in supported) {
    final pkg = await _loadJson('$pkgLangDir/$code.json')
        ?? _die('❌ Missing package $code.json at $pkgLangDir/$code.json');

    final app = await _loadFirstJson(appLangDirs.map((d) => '$d/$code.json').toList());
    final merged = _mergeJson(pkg, app); // app overrides package
    mergedByLang[code] = merged;
  }

  // Validate keyset equality
  if (!_validateSameKeysetAcrossLanguages(mergedByLang)) {
    _die('❌ Key mismatch across languages. See warnings above.');
  }

  // Generate from a reference map (first locale)
  final referenceLang = supported.first;
  final refMap = mergedByLang[referenceLang]!;
  final enMap = mergedByLang['en'] ?? const <String, dynamic>{};
  final code = _generateDictionary(refMap, enMap);

  // Write
  final outFile = File(outPath)..createSync(recursive: true);
  await outFile.writeAsString(code);
  stdout.writeln('✅ dictionary.dart generated at $outPath');
}

/// Resolve real package root even when invoked via `dart run <pkg>:<exe>`
Future<Uri> _resolvePackageRoot() async {
  // IMPORTANT: resolve something inside lib/, not bin/
  final resolved = await Isolate.resolvePackageUri(
    Uri.parse('package:localization/localization.dart'),
  );
  if (resolved != null) {
    // resolved -> .../localization/lib/localization.dart
    // package root -> parent of lib/
    return File.fromUri(resolved).parent.parent.uri; // .../localization/
  }
  // Fallback: script path
  return File.fromUri(Platform.script).parent.parent.uri;
}

/// Pick the first directory path that exists, or null.
Future<String?> _pickExistingDir(List<String> candidates) async {
  for (final p in candidates) {
    if (Directory(p).existsSync()) return p;
  }
  return null;
}

/// SUPPORTED_LOCALES env ("en,tr,ar") OR from filenames in packageLangDir
Future<List<String>> _getSupportedLocales({
  String? fromEnv,
  required String packageLangDir,
}) async {
  if (fromEnv != null && fromEnv.trim().isNotEmpty) {
    return fromEnv.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()..sort();
  }
  final dir = Directory(packageLangDir);
  if (!dir.existsSync()) _die('❌ PACKAGE_LANG_DIR not found: $packageLangDir');

  final lands = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.json'))
      .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
      .toList()
    ..sort();

  if (lands.isEmpty) _die('❌ No *.json files found in $packageLangDir');
  return lands;
}

Future<Map<String, dynamic>?> _loadJson(String path) async {
  final f = File(path);
  if (!f.existsSync()) return null;
  try {
    final data = jsonDecode(await f.readAsString());
    if (data is Map<String, dynamic>) return data;
    return Map<String, dynamic>.from(data as Map);
  } catch (e) {
    stderr.writeln('⚠️  Failed to parse $path: $e');
    return null;
  }
}

/// Try a list of candidate JSON paths, return the first that loads.
Future<Map<String, dynamic>?> _loadFirstJson(List<String> candidates) async {
  for (final p in candidates) {
    final m = await _loadJson(p);
    if (m != null) return m;
  }
  return null;
}

/// Merge maps: package defaults + optional app overrides
Map<String, dynamic> _mergeJson(Map<String, dynamic> pkg, Map<String, dynamic>? app) =>
    {...pkg, ...?app};

bool _validateSameKeysetAcrossLanguages(Map<String, Map<String, dynamic>> mergedByLang) {
  final entries = mergedByLang.entries.toList();
  if (entries.isEmpty) return true;

  final baseLang = entries.first.key;
  final baseKeys = entries.first.value.keys.toSet();
  var ok = true;

  for (final e in entries.skip(1)) {
    final keys = e.value.keys.toSet();
    final missing = baseKeys.difference(keys);
    final extra = keys.difference(baseKeys);
    if (missing.isEmpty && extra.isEmpty) continue;

    ok = false;
    stdout.writeln('⚠️  Key mismatch for "${e.key}" compared to "$baseLang":');
    if (missing.isNotEmpty) stdout.writeln('   Missing: ${missing.toList()..sort()}');
    if (extra.isNotEmpty) stdout.writeln('   Extra:   ${extra.toList()..sort()}');

    // Type consistency check: warn if reference uses Map vs String and this locale differs
    final refMap = entries.first.value;
    for (final k in baseKeys) {
      final refIsMap = refMap[k] is Map;
      final thisIsMap = e.value[k] is Map;
      if (refIsMap != thisIsMap) {
        stdout.writeln("   Type mismatch for '$k' in '${e.key}': expected ${refIsMap ? 'Map' : 'String'} but found ${thisIsMap ? 'Map' : 'String'}. Will attempt auto-coercion where possible.");
      }
    }
  }
  return ok;
}

String _generateDictionary(Map<String, dynamic> ref, Map<String, dynamic> enMap) {
  final buf = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('// Generated by bin/generate_dictionary.dart')
    ..writeln('')
    ..writeln("import 'package:localization/src/utils/plural_rules.dart';")
    ..writeln('')
    ..writeln('class Dictionary {');
  buf.writeln('  final String _locale;');

  // Fields (public for plain strings), private templates for parameterized strings,
  // and plural form maps for JSON-based plural definitions
  ref.forEach((key, value) {
    final fieldName = sanitizeDartIdentifier(snakeToCamel(key));
    final englishText = (enMap[key] is String)
        ? enMap[key] as String
        : (enMap[key] is Map ? (enMap[key] as Map)['other']?.toString() ?? '' : '');
    final doc = generateDocComment(englishText);

    if (value is Map<String, dynamic>) {
      // JSON-based plural forms: store the raw forms map
      buf
        ..writeln(doc)
        ..writeln('  final Map<String, String> _${fieldName}Forms;');
    } else if (value is String && hasPlaceholders(value)) {
      // Parameterized single template
      buf
        ..writeln(doc)
        ..writeln('  final String _${fieldName}Tpl;');
    } else if (value is String) {
      // Plain string
      buf
        ..writeln(doc)
        ..writeln('  final String $fieldName;');
    }
  });

  // Constructor for all fields (plain + template + plural forms) + locale
  buf.writeln('\n  Dictionary({');
  buf.writeln('    required String locale,');
  final templateParamNames = <String>[];
  final formsParamNames = <String>[];
  ref.forEach((key, value) {
    final fieldName = sanitizeDartIdentifier(snakeToCamel(key));
    if (value is Map<String, dynamic>) {
      final publicParam = '${fieldName}Forms';
      formsParamNames.add(publicParam);
      buf.writeln('    required Map<String, String> $publicParam,');
    } else if (value is String && hasPlaceholders(value)) {
      final publicParam = '${fieldName}Tpl';
      templateParamNames.add(publicParam);
      buf.writeln('    required String $publicParam,');
    } else if (value is String) {
      buf.writeln('    required this.$fieldName,');
    }
  });
  if (templateParamNames.isEmpty && formsParamNames.isEmpty) {
    buf.writeln('  }) : _locale = locale;');
  } else {
    final init = <String>[];
    init.add('_locale = locale');
    init.addAll(formsParamNames.map((p) => '_$p = $p'));
    init.addAll(templateParamNames.map((p) => '_$p = $p'));
    buf.writeln('  }) : ${init.join(', ')};');
  }

  // Plural methods for JSON-based forms (e.g., {"one": "{count} item", "other": "{count} items"})
  ref.forEach((key, value) {
    if (value is! Map<String, dynamic>) return;
    final methodName = sanitizeDartIdentifier(snakeToCamel(key));
    final englishText = (enMap[key] is Map)
        ? ((enMap[key] as Map)['other']?.toString() ?? (enMap[key] as Map).values.first.toString())
        : '';
    final doc = generateDocComment(englishText);

    // Collect placeholders across all forms; always require 'count' for plural selection
    final placeholderSet = <String>{};
    (value).forEach((_, v) {
      if (v is String) {
        placeholderSet.addAll(extractPlaceholders(v));
      }
    });
    final otherParams = placeholderSet.where((p) => p != 'count').toList();
    final paramSig = ['required num count', ...otherParams.map((p) => 'required Object $p')].join(', ');
    final cases = ["case 'count': return count.toString();", ...otherParams.map((p) => "case '$p': return $p.toString();")].join(' ');

    buf
      ..writeln('\n$doc')
      ..writeln('  String $methodName({$paramSig}) {')
      ..writeln("    final form = PluralRules.select(_locale, count);")
      ..writeln("    final forms = _${methodName}Forms;")
      ..writeln("    final t = (forms[form] ?? forms['other'] ?? '');")
      ..writeln("    return t.replaceAllMapped(RegExp(r'\\{([a-zA-Z0-9_]+)\\}'), (m) {")
      ..writeln("      switch (m.group(1)) { $cases default: return m.group(0)!; }")
      ..writeln('    });')
      ..writeln('  }');
  });

  // Methods for parameterized strings (interpolate runtime templates)
  ref.forEach((key, value) {
    if (value is! String || !hasPlaceholders(value)) return;
    final fieldName = sanitizeDartIdentifier(snakeToCamel(key));
    final englishText = (enMap[key] is String) ? enMap[key] as String : '';
    final doc = generateDocComment(englishText);
    final placeholders = extractPlaceholders(value).toSet().toList();

    final params = placeholders.map((p) => 'required Object $p').join(', ');
    final cases = placeholders.map((p) => "case '$p': return $p.toString();").join(' ');

    buf
      ..writeln('\n$doc')
      ..writeln('  String $fieldName({$params}) {')
      ..writeln("    final t = _${fieldName}Tpl;")
      ..writeln("    return t.replaceAllMapped(RegExp(r'\\{([a-zA-Z0-9_]+)\\}'), (m) {")
      ..writeln("      switch (m.group(1)) { $cases default: return m.group(0)!; }")
      ..writeln('    });')
      ..writeln('  }');
  });

  // fromMap factory for all fields (plain + template + plural forms)
  buf
    ..writeln('\n  factory Dictionary.fromMap(Map<String, dynamic> map, {required String locale}) {')
    ..writeln('    return Dictionary(')
    ..writeln('      locale: locale,');
  ref.forEach((key, value) {
    final fieldName = sanitizeDartIdentifier(snakeToCamel(key));
    if (value is Map<String, dynamic>) {
      buf.writeln("      ${fieldName}Forms: (() {");
      buf.writeln("        final raw = map['$key'];");
      buf.writeln("        if (raw is String) return <String, String>{'other': raw};");
      buf.writeln("        if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v.toString()));");
      buf.writeln("        return const <String, String>{};");
      buf.writeln("      })(),");
    } else if (value is String && hasPlaceholders(value)) {
      buf.writeln("      ${fieldName}Tpl: (map['$key'] as String?) ?? '',");
    } else if (value is String) {
      buf.writeln("      $fieldName: (map['$key'] as String?) ?? '',");
    }
  });
  buf
    ..writeln('    );')
    ..writeln('  }')
    ..writeln('}');

  return buf.toString();
}

Never _die(String msg) {
  stderr.writeln(msg);
  exit(1);
}