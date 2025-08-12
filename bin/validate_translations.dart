import 'dart:convert';
import 'dart:io';


/// Validates translation JSON files against a master translation file.
class TranslationValidator {
  final String masterFilePath;
  final String langDirectoryPath;

  TranslationValidator({
    required this.masterFilePath,
    required this.langDirectoryPath,
  });

  /// Runs the validation process and prints the result.
  Future<bool> validate() async {
    final masterFile = File(masterFilePath);
    if (!masterFile.existsSync()) {
    
        print('❌ Master translation file not found: $masterFilePath');
      
      return false;
    }

    final Map<String, dynamic> masterMap =
    jsonDecode(await masterFile.readAsString());
    final masterKeys = masterMap.keys.toSet();

    final langDir = Directory(langDirectoryPath);
    final files = langDir
        .listSync()
        .whereType<File>()
        .where((f) =>
    f.path.endsWith('.json') && f.path != masterFile.path)
        .toList();

    var hasErrors = false;

    for (final file in files) {
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final keys = map.keys.toSet();

      final missing = masterKeys.difference(keys);
      final extra = keys.difference(masterKeys);

      if (missing.isEmpty && extra.isEmpty) {
 
          print('✅ ${file.path}: All keys present.');

      } else {
        hasErrors = true;
 
          print('⚠️  ${file.path}:');

        if (missing.isNotEmpty) {
   
            print('   Missing keys: ${missing.join(', ')}');

        }
        if (extra.isNotEmpty) {
   
            print('   Extra keys:   ${extra.join(', ')}');

        }
      }
    }

    if (!hasErrors) {

        print('\n🎉 All translation files match the master keys!');

    } else {

        print('\n❗ Please fix the issues above to keep translations in sync.');

    }
    return !hasErrors;
  }
}