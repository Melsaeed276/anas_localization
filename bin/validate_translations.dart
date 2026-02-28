import 'dart:io';
import 'package:anas_localization/src/utils/translation_validator.dart' as core;

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
    final result = await core.TranslationValidator.validateAgainstMaster(
      masterFilePath: masterFilePath,
      langDirectoryPath: langDirectoryPath,
      treatExtraKeysAsWarnings: false,
    );

    if (result.isValid) {
      _out('\n🎉 All translation files match the master keys!');
    } else {
      _err('❌ Validation failed:');
      for (final error in result.errors) {
        _err('   $error');
      }
      _err('\n❗ Please fix the issues above to keep translations in sync.');
    }

    if (result.hasWarnings) {
      _out('\n⚠️  Warnings:');
      for (final warning in result.warnings) {
        _out('   $warning');
      }
    }

    return result.isValid;
  }
}

void _out(Object? message) => stdout.writeln(message);

void _err(Object? message) => stderr.writeln(message);
