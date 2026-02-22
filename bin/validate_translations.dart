import 'dart:convert';
import 'dart:io';

/// Validates translation JSON files against a master translation file.
class TranslationValidator {
  TranslationValidator({
    required this.masterFilePath,
    required this.langDirectoryPath,
  });

  final String masterFilePath;
  final String langDirectoryPath;

  /// Runs the validation process and prints the result.
  Future<bool> validate() async {
    final masterFile = File(masterFilePath);
    if (!masterFile.existsSync()) {
      _err('❌ Master translation file not found: $masterFilePath');
      return false;
    }

    final masterMap =
        jsonDecode(await masterFile.readAsString()) as Map<String, dynamic>;
    final masterKeys = masterMap.keys.toSet();

    final langDir = Directory(langDirectoryPath);
    final files = langDir
        .listSync()
        .whereType<File>()
        .where(
          (f) => f.path.endsWith('.json') && f.path != masterFile.path,
        )
        .toList();

    var hasErrors = false;

    for (final file in files) {
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final keys = map.keys.toSet();

      final missing = masterKeys.difference(keys);
      final extra = keys.difference(masterKeys);

      if (missing.isEmpty && extra.isEmpty) {
        _out('✅ ${file.path}: All keys present.');
      } else {
        hasErrors = true;
        _out('⚠️  ${file.path}:');
        if (missing.isNotEmpty) {
          _out('   Missing keys: ${missing.join(', ')}');
        }
        if (extra.isNotEmpty) {
          _out('   Extra keys:   ${extra.join(', ')}');
        }
      }
    }

    if (!hasErrors) {
      _out('\n🎉 All translation files match the master keys!');
    } else {
      _err('\n❗ Please fix the issues above to keep translations in sync.');
    }
    return !hasErrors;
  }
}

void _out(Object? message) => stdout.writeln(message);

void _err(Object? message) => stderr.writeln(message);
