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

enum NumericPlaceholder { amount, count }

// --- Inline requirement helpers (Option A: {name?}/{name!}) ---
ParamRequirement _reqOf(
  Map<String, ParamRequirement> m,
  String name, {
  ParamRequirement fallback = ParamRequirement.required,
}) => m[name] ?? fallback;

/// Scans a list of templates and returns per-placeholder requirement.
/// `{name!}` => required, `{name?}` => optional. If both appear, `!` wins.
Map<String, ParamRequirement> _scanRequirements(Iterable<String> templates) {
  final re = RegExp(r'\{([a-zA-Z0-9_]+)([!?])?\}');
  final out = <String, ParamRequirement>{};
  for (final t in templates) {
    for (final m in re.allMatches(t)) {
      final name = m.group(1)!; // cleaned name without marker
      final mark = m.group(2); // '!' or '?' or null
      if (mark == '!') {
        out[name] = ParamRequirement.required; // strongest
      } else if (mark == '?' && out[name] != ParamRequirement.required) {
        out[name] =
            ParamRequirement.optional; // only set if not required already
      } else {
        out.putIfAbsent(
          name,
          () => ParamRequirement.required,
        ); // default if seen without marker
      }
    }
  }
  return out;
}

String _reqKw(ParamRequirement r) =>
    r == ParamRequirement.required ? 'required ' : '';
String _nullSuf(ParamRequirement r) =>
    r == ParamRequirement.required ? '' : '?';
String _toStr(String v, ParamRequirement r) =>
    r == ParamRequirement.required ? '$v.toString()' : '$v?.toString() ?? \'\'';

Future<void> main(List<String> args) async {
  final pkgRoot = await _resolvePackageRoot();

  // Pick the correct package lang dir (your case: <pkg>/assets/lang)
  final pkgLangDir =
      await _pickExistingDir([
        File.fromUri(pkgRoot.resolve('assets/lang')).path, // canonical
        File.fromUri(pkgRoot.resolve('lib/assets/lang')).path, // safety net
      ]) ??
      _die(
        '❌ Could not find package lang folder. Tried:\n'
        ' - ${File.fromUri(pkgRoot.resolve('assets/lang')).path}\n'
        ' - ${File.fromUri(pkgRoot.resolve('lib/assets/lang')).path}',
      );

  // Where to look for app overrides (both are optional)
  final appLangDirs = <String>[
    Platform.environment['APP_LANG_DIR'] ?? 'assets/lang',
    'example/assets/lang', // when run from package root
  ];

  // Output always to the package lib/ by default
  final defaultOutPath = File.fromUri(
    pkgRoot.resolve('lib/src/generated/dictionary.dart'),
  ).path;
  final outPath = Platform.environment['OUTPUT_DART'] ?? defaultOutPath;

  // Find supported locales from the picked package lang dir, or env
  final supported = await _getSupportedLocales(
    fromEnv: Platform.environment['SUPPORTED_LOCALES'],
    packageLangDir: pkgLangDir,
  );

  // Load+merge per locale
  final mergedByLang = <String, Map<String, dynamic>>{};
  for (final code in supported) {
    final pkg =
        await _loadJson('$pkgLangDir/$code.json') ??
        _die('❌ Missing package $code.json at $pkgLangDir/$code.json');

    final app = await _loadFirstJson(
      appLangDirs.map((d) => '$d/$code.json').toList(),
    );
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
    return fromEnv
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList()
      ..sort();
  }
  final dir = Directory(packageLangDir);
  if (!dir.existsSync()) _die('❌ PACKAGE_LANG_DIR not found: $packageLangDir');

  final lands =
      dir
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
Map<String, dynamic> _mergeJson(
  Map<String, dynamic> pkg,
  Map<String, dynamic>? app,
) => {...pkg, ...?app};

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

bool _validateSameKeysetAcrossLanguages(
  Map<String, Map<String, dynamic>> mergedByLang,
) {
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
      stdout.writeln(
        '⚠️  Key mismatch for "${e.key}" compared to "$baseLang":',
      );
      if (missing.isNotEmpty)
        stdout.writeln('   Missing: ${missing.toList()..sort()}');
      if (extra.isNotEmpty)
        stdout.writeln('   Extra:   ${extra.toList()..sort()}');
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
          stdout.writeln(
            "   Note: '$k' in '${e.key}' is a String while base '$baseLang' is a Map. Accepting and auto-coercing to {'other': ...}.",
          );
        } else {
          ok = false;
          stdout.writeln(
            "   Type mismatch for '$k' in '${e.key}': expected ${refIsMap ? 'Map' : 'String'} but found ${thisIsMap ? 'Map' : 'String'}.",
          );
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
      final nameExtra = thisNames.difference(refNames);
      if (nameMissing.isNotEmpty || nameExtra.isNotEmpty) {
        ok = false;
        stdout.writeln("   Placeholder mismatch for key '$k' in '${e.key}':");
        if (nameMissing.isNotEmpty)
          stdout.writeln(
            '     Missing placeholders: ${nameMissing.toList()..sort()}',
          );
        if (nameExtra.isNotEmpty)
          stdout.writeln(
            '     Extra placeholders:   ${nameExtra.toList()..sort()}',
          );
      }

      // Requirement parity: {name!} vs {name?} must match across locales
      final commonPlaceholders = refNames.intersection(thisNames);
      for (final p in commonPlaceholders) {
        final rRef = refReqs[p] ?? ParamRequirement.required;
        final rThis = thisReqs[p] ?? ParamRequirement.required;
        if (rRef != rThis) {
          ok = false;
          stdout.writeln(
            "   Requirement conflict for key '$k' placeholder '$p' in '${e.key}': expected ${rRef.name}, found ${rThis.name}.",
          );
        }
      }

      // Gender form validation: if isGender, only 'male' and 'female' allowed as keys
      // This logic must match the gender/plural detection in _generateDictionary
      if (thisVal is Map) {
        final formsMap = thisVal.map((k2, v2) => MapEntry(k2.toString(), v2));
        final formKeys = formsMap.keys.toSet();
        final genderKeys = GenderForm.values.map((e) => e.name).toSet();
        final pluralCore = PluralForm.values.map((e) => e.name).toSet()
          ..remove('other');
        final isPlural = formKeys.any((kk) => pluralCore.contains(kk));
        final isGender =
            !isPlural && formKeys.every((kk) => genderKeys.contains(kk));
        if (isGender) {
          for (final key in formKeys) {
            if (!genderKeys.contains(key)) {
              ok = false;
              stdout.writeln(
                "❌ Invalid gender form for key '$k' in '${e.key}': only 'male' and 'female' are allowed.",
              );
              break;
            }
          }
        }
      }
    }
  }
  return ok;
}

String _generateDictionary(
  Map<String, dynamic> ref,
  Map<String, dynamic> enMap,
) {
  final buf = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('// Generated by bin/generate_dictionary.dart')
    ..writeln('')
    ..writeln("import 'package:anas_localization/src/utils/plural_rules.dart';")
    ..writeln('')
    ..writeln('class Dictionary {');
  buf.writeln('  final String _locale;');

  // Fields (public for plain strings), private templates for parameterized strings,
  // and plural form maps for JSON-based plural definitions
  ref.forEach((key, value) {
    final fieldName = sanitizeDartIdentifier(snakeToCamel(key));
    final englishText = (enMap[key] is String)
        ? enMap[key] as String
        : (enMap[key] is Map
              ? (enMap[key] as Map)['other']?.toString() ?? ''
              : '');
    final doc = generateDocComment(englishText);

    if (value is Map<String, dynamic>) {
      final pluralCore = PluralForm.values.map((e) => e.name).toSet()
        ..remove('other'); // exclude 'other'
      final mapVal = value;
      final topKeys = mapVal.keys.map((e) => e.toString()).toSet();
      final topIsPlural = topKeys.any((k) => pluralCore.contains(k));
      final nestedPlural =
          !topIsPlural &&
          mapVal.values.any(
            (v) =>
                v is Map &&
                (v).keys.any((k) => pluralCore.contains(k.toString())),
          );

      if (nestedPlural) {
        // Nested select (e.g., currency) -> inner plural forms
        buf
          ..writeln(doc)
          ..writeln(
            '  final Map<String, Map<String, String>> _${fieldName}NestedForms;',
          );
      } else {
        // Simple forms (plural or gender/select)
        buf
          ..writeln(doc)
          ..writeln('  final Map<String, String> _${fieldName}Forms;');
      }
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
      final pluralCore = PluralForm.values.map((e) => e.name).toSet()
        ..remove('other');
      final mapVal = value;
      final topKeys = mapVal.keys.map((e) => e.toString()).toSet();
      final topIsPlural = topKeys.any((k) => pluralCore.contains(k));
      final nestedPlural =
          !topIsPlural &&
          mapVal.values.any(
            (v) =>
                v is Map &&
                (v).keys.any((k) => pluralCore.contains(k.toString())),
          );

      if (nestedPlural) {
        final publicParam = '${fieldName}NestedForms';
        formsParamNames.add(publicParam);
        buf.writeln(
          '    required Map<String, Map<String, String>> $publicParam,',
        );
      } else {
        final publicParam = '${fieldName}Forms';
        formsParamNames.add(publicParam);
        buf.writeln('    required Map<String, String> $publicParam,');
      }
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

  // Methods for JSON-based forms and selects (plural/gender) and nested select->plural
  ref.forEach((key, value) {
    if (value is! Map<String, dynamic>) return;

    final pluralCore = PluralForm.values.map((e) => e.name).toSet()
      ..remove('other');
    final mapVal = value;
    final methodName = sanitizeDartIdentifier(snakeToCamel(key));

    final englishText = (enMap[key] is Map)
        ? ((enMap[key] as Map)['other']?.toString() ??
              (enMap[key] as Map).values.first.toString())
        : '';
    final doc = generateDocComment(englishText);

    final topKeys = mapVal.keys.map((e) => e.toString()).toSet();
    final topIsPlural = topKeys.any((k) => pluralCore.contains(k));
    final nestedPlural =
        !topIsPlural &&
        mapVal.values.any(
          (v) =>
              v is Map &&
              (v).keys.any((k) => pluralCore.contains(k.toString())),
        );

    if (nestedPlural) {
      // NESTED: outer select (e.g., currency), inner plural
      // Determine selector param name (prefer {currency} if present in docs/templates)
      final allInnerTemplates = mapVal.values
          .whereType<Map>()
          .expand((m) => m.values)
          .map((v) => v?.toString() ?? '')
          .toList();
      final namedSet = <String>{};
      for (final tpl in allInnerTemplates) {
        namedSet.addAll(extractPlaceholders(tpl));
      }
      // Selector param name: use 'currency' if mentioned, else 'formKey'
      final hasCurrency = namedSet.contains('currency');
      final selectorName = hasCurrency ? 'currency' : 'formKey';
      // Prefer `{amount}` as the plural-driving number; fallback to `{count}`
      final numericName = namedSet.contains(NumericPlaceholder.amount.name)
          ? NumericPlaceholder.amount.name
          : NumericPlaceholder.count.name;
      if (numericName.isNotEmpty) namedSet.remove(numericName);
      if (hasCurrency) namedSet.remove('currency');

      // Compute per-param requirements from inline markers
      final reqMap = _scanRequirements(allInnerTemplates);
      final reqSelector = hasCurrency
          ? _reqOf(reqMap, 'currency', fallback: ParamRequirement.required)
          : ParamRequirement.required;
      final reqNumeric = _reqOf(
        reqMap,
        numericName,
        fallback: ParamRequirement.required,
      );

      // Build param signature with per-param requirement & nullability
      final otherNamed = namedSet
          .map((p) {
            final req = _reqOf(reqMap, p, fallback: ParamRequirement.required);
            return '${_reqKw(req)}Object${_nullSuf(req)} $p';
          })
          .join(', ');
      final paramSig =
          '{'
          '${_reqKw(reqSelector)}String${_nullSuf(reqSelector)} $selectorName, '
          '${_reqKw(reqNumeric)}num${_nullSuf(reqNumeric)} $numericName'
          '${otherNamed.isNotEmpty ? ', ' + otherNamed : ''}'
          '}';

      // Named placeholder switch cases honor optionality
      final namedCases = [
        "case '$numericName': return ${_toStr(numericName, reqNumeric)};",
        if (hasCurrency)
          "case 'currency': return ${_toStr(selectorName, reqSelector)};",
        ...namedSet.map(
          (p) =>
              "case '$p': return ${_toStr(p, _reqOf(reqMap, p, fallback: ParamRequirement.required))};",
        ),
      ].join(' ');

      buf
        ..writeln('\n$doc')
        ..writeln('  String $methodName($paramSig) {')
        ..writeln("    final outer = _${methodName}NestedForms;")
        ..writeln(
          "    final inner = outer[$selectorName] ?? outer['other'] ?? const <String,String>{};",
        )
        ..writeln("    final form = PluralRules.select(_locale, $numericName);")
        ..writeln("    var t = (inner[form] ?? inner['other'] ?? '');")
        ..writeln(
          "    return t.replaceAllMapped(RegExp(r'\\{([a-zA-Z0-9_]+)\\}'), (m) {",
        )
        ..writeln(
          "      switch (m.group(1)) { $namedCases default: return m.group(0)!; }",
        )
        ..writeln('    });')
        ..writeln('  }');
    } else {
      // FLAT: plural or gender/select with optional positional and named placeholders
      final formsMap = mapVal.map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      );
      final formKeys = formsMap.keys.toSet();
      final genderKeys = GenderForm.values.map((e) => e.name).toSet();
      final pluralCore = PluralForm.values.map((e) => e.name).toSet()
        ..remove('other');
      final isPlural = formKeys.any((k) => pluralCore.contains(k));
      final isGender =
          !isPlural && formKeys.every((k) => genderKeys.contains(k));

      // Collect placeholders across all forms
      final namedSet = <String>{};
      int positionalCount = 0;
      for (final tpl in formsMap.values) {
        positionalCount =
            positionalCount < RegExp(r'\{\}').allMatches(tpl).length
            ? RegExp(r'\{\}').allMatches(tpl).length
            : positionalCount;
        namedSet.addAll(extractPlaceholders(tpl));
      }
      // Prefer `{amount}` as the plural-driving number; fallback to `{count}`
      final numericName = namedSet.contains(NumericPlaceholder.amount.name)
          ? NumericPlaceholder.amount.name
          : NumericPlaceholder.count.name;
      if (isPlural) namedSet.remove(numericName);

      // Compute per-param requirements from inline markers across all forms
      final reqMap = _scanRequirements(formsMap.values);

      final positionalParams = List.generate(
        positionalCount,
        (i) =>
            '${_reqKw(_reqOf(reqMap, 'p${i + 1}', fallback: ParamRequirement.required))}Object${_nullSuf(_reqOf(reqMap, 'p${i + 1}', fallback: ParamRequirement.required))} p${i + 1}',
      ).join(', ');

      final otherNamedParams = namedSet
          .map((p) {
            final req = _reqOf(reqMap, p, fallback: ParamRequirement.required);
            return '${_reqKw(req)}Object${_nullSuf(req)} $p';
          })
          .join(', ');

      final reqNumeric = _reqOf(
        reqMap,
        numericName,
        fallback: ParamRequirement.required,
      );
      final reqGender = _reqOf(
        reqMap,
        'gender',
        fallback: ParamRequirement.required,
      );
      final reqFormKey = _reqOf(
        reqMap,
        'formKey',
        fallback: ParamRequirement.required,
      );

      String headerParams;
      if (isPlural) {
        final paramsList = [
          if (positionalParams.isNotEmpty) positionalParams,
          '${_reqKw(reqNumeric)}num${_nullSuf(reqNumeric)} $numericName',
          if (otherNamedParams.isNotEmpty) otherNamedParams,
        ].join(', ');
        headerParams = '{$paramsList}';
      } else if (isGender) {
        final paramsList = [
          if (positionalParams.isNotEmpty) positionalParams,
          '${_reqKw(reqGender)}String${_nullSuf(reqGender)} gender',
          if (otherNamedParams.isNotEmpty) otherNamedParams,
        ].join(', ');
        headerParams = '{$paramsList}';
      } else {
        final paramsList = [
          if (positionalParams.isNotEmpty) positionalParams,
          '${_reqKw(reqFormKey)}String${_nullSuf(reqFormKey)} formKey',
          if (otherNamedParams.isNotEmpty) otherNamedParams,
        ].join(', ');
        headerParams = '{$paramsList}';
      }

      final namedCases = [
        if (isPlural)
          "case '$numericName': return ${_toStr(numericName, reqNumeric)};",
        if (isGender)
          ...namedSet.map(
            (p) =>
                "case '$p': return ${_toStr(p, _reqOf(reqMap, p, fallback: ParamRequirement.required))};",
          ),
        if (!isPlural)
          ...namedSet.map(
            (p) =>
                "case '$p': return ${_toStr(p, _reqOf(reqMap, p, fallback: ParamRequirement.required))};",
          ),
      ].join(' ');

      buf
        ..writeln('\n$doc')
        ..writeln('  String $methodName($headerParams) {')
        ..writeln("    final forms = _${methodName}Forms;")
        ..writeln(
          isPlural
              ? "    final form = PluralRules.select(_locale, $numericName);"
              : (isGender
                    ? "    final form = gender;"
                    : "    final form = formKey;"),
        )
        ..writeln("    var t = (forms[form] ?? forms['other'] ?? '');")
        ..writeln('    {')
        ..writeln(
          '      final pos = <Object?>[${(positionalCount > 0 ? List.generate(positionalCount, (i) => 'p${i + 1}').join(', ') : '').trim()}];',
        )
        ..writeln('      var i = 0;')
        ..writeln(
          "      if (pos.isNotEmpty) { t = t.replaceAllMapped(RegExp(r'\\{\\}'), (m) => (i < pos.length ? (pos[i++]?.toString() ?? \'\') : '').toString()); }",
        )
        ..writeln('    }')
        ..writeln(
          "    return t.replaceAllMapped(RegExp(r'\\{([a-zA-Z0-9_]+)\\}'), (m) {",
        )
        ..writeln(
          "      switch (m.group(1)) { ${namedCases.isEmpty ? '' : namedCases} default: return m.group(0)!; }",
        )
        ..writeln('    });')
        ..writeln('  }');
    }
  });

  // Methods for parameterized strings (interpolate runtime templates)
  ref.forEach((key, value) {
    if (value is! String || !hasPlaceholders(value)) return;
    final fieldName = sanitizeDartIdentifier(snakeToCamel(key));
    final englishText = (enMap[key] is String) ? enMap[key] as String : '';
    final doc = generateDocComment(englishText);
    final placeholders = extractPlaceholders(value).toSet().toList();

    // Per-param requirements from inline markers in this template
    final reqMap = _scanRequirements([value]);
    final params = placeholders
        .map((p) {
          final req = _reqOf(reqMap, p, fallback: ParamRequirement.required);
          return '${_reqKw(req)}Object${_nullSuf(req)} $p';
        })
        .join(', ');
    final cases = placeholders
        .map((p) {
          final req = _reqOf(reqMap, p, fallback: ParamRequirement.required);
          return "case '$p': return ${_toStr(p, req)};";
        })
        .join(' ');

    buf
      ..writeln('\n$doc')
      ..writeln('  String $fieldName({$params}) {')
      ..writeln("    final t = _${fieldName}Tpl;")
      ..writeln(
        "    return t.replaceAllMapped(RegExp(r'\\{([a-zA-Z0-9_]+)\\}'), (m) {",
      )
      ..writeln(
        "      switch (m.group(1)) { $cases default: return m.group(0)!; }",
      )
      ..writeln('    });')
      ..writeln('  }');
  });

  // fromMap factory for all fields (plain + template + plural forms)
  buf
    ..writeln(
      '\n  factory Dictionary.fromMap(Map<String, dynamic> map, {required String locale}) {',
    )
    ..writeln('    return Dictionary(')
    ..writeln('      locale: locale,');
  ref.forEach((key, value) {
    final fieldName = sanitizeDartIdentifier(snakeToCamel(key));
    if (value is Map<String, dynamic>) {
      final pluralCore = PluralForm.values.map((e) => e.name).toSet()
        ..remove('other');
      final mapVal = value;
      final topKeys = mapVal.keys.map((e) => e.toString()).toSet();
      final topIsPlural = topKeys.any((k) => pluralCore.contains(k));
      final nestedPlural =
          !topIsPlural &&
          mapVal.values.any(
            (v) =>
                v is Map &&
                (v).keys.any((k) => pluralCore.contains(k.toString())),
          );

      if (nestedPlural) {
        buf.writeln("      ${fieldName}NestedForms: (() {");
        buf.writeln("        final raw = map['$key'];");
        buf.writeln("        if (raw is Map) {");
        buf.writeln("          return raw.map((outerK, outerV) {");
        buf.writeln(
          "            if (outerV is String) { return MapEntry(outerK.toString(), <String,String>{'other': outerV}); }",
        );
        buf.writeln(
          "            if (outerV is Map) { return MapEntry(outerK.toString(), outerV.map((k, v) => MapEntry(k.toString(), v.toString()))); }",
        );
        buf.writeln(
          "            return MapEntry(outerK.toString(), const <String,String>{});",
        );
        buf.writeln("          });");
        buf.writeln("        }");
        buf.writeln("        return const <String, Map<String,String>>{};");
        buf.writeln("      })(),");
      } else {
        buf.writeln("      ${fieldName}Forms: (() {");
        buf.writeln("        final raw = map['$key'];");
        buf.writeln(
          "        if (raw is String) return <String, String>{'other': raw};",
        );
        buf.writeln(
          "        if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v.toString()));",
        );
        buf.writeln("        return const <String, String>{};");
        buf.writeln("      })(),");
      }
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
