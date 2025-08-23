// bin/generate_dictionary.dart
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:anas_localization/src/utils/codegen_utils.dart';

// Enum for plural forms
enum PluralForm { zero, one, two, few, many, other }

// Enum for gender forms
enum GenderForm { male, female }

// Enum for parameter requirement
enum ParamRequirement { required, optional }

// Enum for numeric placeholders

enum NumericPlaceholder {
  amount,
  count,
}

// --- Inline requirement helpers (Option A: {name?}/{name!}) ---
ParamRequirement _reqOf(Map<String, ParamRequirement> m, String name, {ParamRequirement fallback = ParamRequirement.required}) => m[name] ?? fallback;

/// Scans a list of templates and returns per-placeholder requirement.
/// `{name!}` => required, `{name?}` => optional. If both appear, `!` wins.
Map<String, ParamRequirement> _scanRequirements(Iterable<String> templates) {
  final re = RegExp(r'\{([a-zA-Z0-9_]+)([!?])?\}');
  final out = <String, ParamRequirement>{};
  for (final t in templates) {
    for (final m in re.allMatches(t)) {
      final name = m.group(1)!; // cleaned name without marker
      final mark = m.group(2);  // '!' or '?' or null
      if (mark == '!') {
        out[name] = ParamRequirement.required; // strongest
      } else if (mark == '?' && out[name] != ParamRequirement.required) {
        out[name] = ParamRequirement.optional; // only set if not required already
      } else {
        out.putIfAbsent(name, () => ParamRequirement.required); // default if seen without marker
      }
    }
  }
  return out;
}

String _reqKw(ParamRequirement r) => r == ParamRequirement.required ? 'required ' : '';
String _nullSuf(ParamRequirement r) => r == ParamRequirement.required ? '' : '?';
String _toStr(String v, ParamRequirement r) => r == ParamRequirement.required ? '$v.toString()' : '$v?.toString() ?? \'\'';


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

  // Output to the APP by default (not the package)
  // When run from an app directory, generate in that app
  // When run from package directory, generate in example/ if it exists
  final appRoot = await _resolveAppRoot();
  final isRunningFromPackage = await _isRunningFromPackage(appRoot);

  String defaultOutPath;
  if (isRunningFromPackage) {
    // Running from package root - check for example app
    final exampleRoot = File.fromUri(appRoot.resolve('example/')).path;
    if (Directory(exampleRoot).existsSync()) {
      defaultOutPath = File.fromUri(appRoot.resolve('example/lib/generated/dictionary.dart')).path;
      stdout.writeln('📦 Running from package - generating Dictionary in example app');
    } else {
      _die('❌ Running from package but no example app found. Please run from your app directory or create an example/ directory.');
    }
  } else {
    // Running from actual app directory
    defaultOutPath = File.fromUri(appRoot.resolve('lib/generated/dictionary.dart')).path;
    stdout.writeln('🚀 Generating Dictionary for app at ${appRoot.path}');
  }

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
  final code = _generateSimpleDictionary(refMap, enMap);

  // Write
  final outFile = File(outPath)..createSync(recursive: true);
  await outFile.writeAsString(code);
  stdout.writeln('✅ Dictionary.dart generated at $outPath');
}

/// Generate a simple Dictionary class with type-safe getters
String _generateSimpleDictionary(Map<String, dynamic> refMap, Map<String, dynamic> enMap) {
  final buffer = StringBuffer();

  // File header
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('// Generated by localization_gen command');
  buffer.writeln();
  buffer.writeln('// ignore_for_file: prefer_single_quotes, unnecessary_string_escapes');
  buffer.writeln();

  // Imports
  buffer.writeln("import 'package:anas_localization/localization.dart' as base;");
  buffer.writeln();

  // Class definition
  buffer.writeln('/// Auto-generated Dictionary class with type-safe localization getters.');
  buffer.writeln('/// ');
  buffer.writeln('/// Access translations using getters like: dictionary.appName');
  buffer.writeln('class Dictionary extends base.Dictionary {');
  buffer.writeln('  Dictionary.fromMap(super.map, {required super.locale})');
  buffer.writeln('      : super.fromMap();');
  buffer.writeln();

  // Generate getters for each key
  final sortedKeys = refMap.keys.toList()..sort();
  for (final key in sortedKeys) {
    final value = refMap[key];
    if (value is String) {
      final camelKey = sanitizeDartIdentifier(key); // Use sanitizeDartIdentifier instead of snakeToCamel
      final hasParams = hasPlaceholders(value);

      buffer.writeln('  /// Get localized text for "$key"');
      if (hasParams) {
        final placeholders = extractPlaceholders(value).toList();
        buffer.writeln('  /// Placeholders: ${placeholders.join(', ')}');
        buffer.writeln('  String $camelKey({${_generateParameterList(placeholders)}}) {');
        buffer.writeln('    return getStringWithParams(\'$key\', {');
        for (final param in placeholders) {
          buffer.writeln('      \'$param\': $param,');
        }
        buffer.writeln('    });');
        buffer.writeln('  }');
      } else {
        buffer.writeln('  String get $camelKey => getString(\'$key\');');
      }
      buffer.writeln();
    }
  }

  buffer.writeln('}');
  buffer.writeln();

  // Add setup function
  buffer.writeln('/// Setup function to configure the localization service to use this generated Dictionary');
  buffer.writeln('/// Call this once in your app initialization (e.g., in main() or app startup)');
  buffer.writeln('void setupDictionary() {');
  buffer.writeln('  base.LocalizationService().setDictionaryFactory(');
  buffer.writeln('    (Map<String, dynamic> map, {required String locale}) {');
  buffer.writeln('      return Dictionary.fromMap(map, locale: locale);');
  buffer.writeln('    },');
  buffer.writeln('  );');
  buffer.writeln('}');

  return buffer.toString();
}

/// Generate parameter list for methods with placeholders
String _generateParameterList(List<String> placeholders) {
  return placeholders.map((param) => 'required String $param').join(', ');
}

Future<Uri> _resolvePackageRoot() async {
  // IMPORTANT: resolve something inside lib/, not bin/
  final resolved = await Isolate.resolvePackageUri(
    Uri.parse('package:anas_localization/anas_localization.dart'),
  );
  if (resolved != null) {
    // resolved -> .../localization/lib/localization.dart
    // package root -> parent of lib/
    return File.fromUri(resolved).parent.parent.uri; // .../localization/
  }
  // Fallback: script path
  return File.fromUri(Platform.script).parent.parent.uri;
}

/// Resolve the app root (nearest directory up from CWD that contains pubspec.yaml)
Future<Uri> _resolveAppRoot() async {
  var dir = Directory.current;
  while (true) {
    final candidate = File('${dir.path}${Platform.pathSeparator}pubspec.yaml');
    if (candidate.existsSync()) return dir.uri;
    final parent = dir.parent;
    if (parent.path == dir.path) break; // reached filesystem root
    dir = parent;
  }
  // Fallback to CWD if pubspec.yaml not found
  return Directory.current.uri;
}

/// Check if we're running from the package directory vs an app directory
Future<bool> _isRunningFromPackage(Uri appRoot) async {
  final pubspecFile = File.fromUri(appRoot.resolve('pubspec.yaml'));
  if (!pubspecFile.existsSync()) return false;

  try {
    final pubspecContent = await pubspecFile.readAsString();
    // Check if this pubspec declares anas_localization as the package name
    return pubspecContent.contains('name: anas_localization');
  } catch (e) {
    return false;
  }
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

/// Flatten a value (String or Map of Strings/Maps) into a list of string templates
List<String> _flattenTemplates(dynamic v) {
  if (v is String) return [v];
  if (v is Map) {
    final out = <String>[];
    for (final entry in v.entries) {
      out.addAll(_flattenTemplates(entry.value));
    }
    return out;
  }
  return const <String>[];
}

/// Collect per-placeholder requirements from any value shape using inline markers
Map<String, ParamRequirement> _collectRequirements(dynamic v) {
  final templates = _flattenTemplates(v);
  return _scanRequirements(templates);
}

bool _validateSameKeysetAcrossLanguages(Map<String, Map<String, dynamic>> mergedByLang) {
  final entries = mergedByLang.entries.toList();
  if (entries.isEmpty) return true;

  // Prefer English as the canonical reference when present
  final baseEntry = entries.firstWhere(
    (e) => e.key == 'en',
    orElse: () => entries.first,
  );
  final baseLang = baseEntry.key;
  final baseKeys = baseEntry.value.keys.toSet();
  var ok = true;

  for (final e in entries.where((x) => x.key != baseLang)) {
    final keys = e.value.keys.toSet();
    final missing = baseKeys.difference(keys);
    final extra = keys.difference(baseKeys);
    if (missing.isNotEmpty || extra.isNotEmpty) {
      ok = false;
      stdout.writeln('⚠️  Key mismatch for "${e.key}" compared to "$baseLang":');
      if (missing.isNotEmpty) stdout.writeln('   Missing: ${missing.toList()..sort()}');
      if (extra.isNotEmpty) stdout.writeln('   Extra:   ${extra.toList()..sort()}');
    }

    // Type consistency check across common keys
    final refMap = baseEntry.value;
    final commonKeys = baseKeys.intersection(keys);
    for (final k in commonKeys) {
      final refIsMap = refMap[k] is Map;
      final thisIsMap = e.value[k] is Map;
      if (refIsMap != thisIsMap) {
        // Allow: base has plural/select Map but this locale uses a simple String.
        // We auto-coerce String -> {'other': string} at factory time.
        if (refIsMap && !thisIsMap) {
          stdout.writeln("   Note: '$k' in '${e.key}' is a String while base '$baseLang' is a Map. Accepting and auto-coercing to {'other': ...}.");
        } else {
          ok = false;
          stdout.writeln("   Type mismatch for '$k' in '${e.key}': expected ${refIsMap ? 'Map' : 'String'} but found ${thisIsMap ? 'Map' : 'String'}.");
        }
      }
    }

    // Placeholder name + requirement consistency across common keys
    for (final k in commonKeys) {
      final refVal = baseEntry.value[k];
      final thisVal = e.value[k];

      final refReqs = _collectRequirements(refVal);
      final thisReqs = _collectRequirements(thisVal);

      final refNames = refReqs.keys.toSet();
      final thisNames = thisReqs.keys.toSet();

      final nameMissing = refNames.difference(thisNames);
      final nameExtra   = thisNames.difference(refNames);
      if (nameMissing.isNotEmpty || nameExtra.isNotEmpty) {
        ok = false;
        stdout.writeln("   Placeholder mismatch for key '$k' in '${e.key}':");
        if (nameMissing.isNotEmpty) stdout.writeln('     Missing placeholders: ${nameMissing.toList()..sort()}');
        if (nameExtra.isNotEmpty)   stdout.writeln('     Extra placeholders:   ${nameExtra.toList()..sort()}');
      }

      // Requirement parity: {name!} vs {name?} must match across locales
      final commonPlaceholders = refNames.intersection(thisNames);
      for (final p in commonPlaceholders) {
        final rRef  = refReqs[p] ?? ParamRequirement.required;
        final rThis = thisReqs[p] ?? ParamRequirement.required;
        if (rRef != rThis) {
          ok = false;
          stdout.writeln("   Requirement conflict for key '$k' placeholder '$p' in '${e.key}': expected ${rRef.name}, found ${rThis.name}.");
        }
      }

      // Gender form validation: if isGender, only 'male' and 'female' allowed as keys
      // This logic must match the gender/plural detection in _generateDictionary
      if (thisVal is Map) {
        final formsMap = thisVal.map((k2, v2) => MapEntry(k2.toString(), v2));
        final formKeys = formsMap.keys.toSet();
        final genderKeys = GenderForm.values.map((e) => e.name).toSet();
        final pluralCore = PluralForm.values.map((e) => e.name).toSet()..remove('other');
        final isPlural = formKeys.any((kk) => pluralCore.contains(kk));
        final isGender = !isPlural && formKeys.every((kk) => genderKeys.contains(kk));
        if (isGender) {
          for (final key in formKeys) {
            if (!genderKeys.contains(key)) {
              ok = false;
              stdout.writeln("❌ Invalid gender form for key '$k' in '${e.key}': only 'male' and 'female' are allowed.");
              break;
            }
          }
        }
      }
    }
  }
  return ok;
}


Never _die(String msg) {
  stderr.writeln(msg);
  exit(1);
}
