import 'package:anas_localization/src/core/date_time_formatter.dart';
import 'package:anas_localization/src/core/number_formatter.dart';
import 'package:anas_localization/src/core/rich_text_formatter.dart';
import 'package:anas_localization/src/core/text_direction_helper.dart';
import 'package:anas_localization/src/core/localization_exceptions.dart';
import 'package:anas_localization/src/core/dictionary.dart';
import 'package:anas_localization/src/core/locale_detector.dart';
import 'package:anas_localization/src/utils/translation_file_parser.dart';
import 'package:anas_localization/src/utils/translation_validator.dart';
import 'package:anas_localization/src/utils/arb_interop.dart';
import 'package:anas_localization/src/utils/plural_rules.dart';
import 'package:anas_localization/src/widgets/language_selector.dart';
import 'package:anas_localization/src/widgets/language_setup_overlay.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests that key public shim paths resolve expected types.
///
/// These tests verify that the export shims in legacy directories
/// (lib/src/core/, lib/src/utils/, lib/src/widgets/) correctly re-export
/// types from their canonical locations.
void main() {
  group('Core shim exports', () {
    test('date_time_formatter.dart exports AnasDateTimeFormatter', () {
      expect(AnasDateTimeFormatter, isA<Type>());
    });

    test('number_formatter.dart exports AnasNumberFormatter', () {
      expect(AnasNumberFormatter, isA<Type>());
    });

    test('rich_text_formatter.dart exports AnasInterpolation', () {
      expect(AnasInterpolation, isA<Type>());
    });

    test('text_direction_helper.dart exports AnasTextDirection', () {
      expect(AnasTextDirection, isA<Type>());
    });

    test('localization_exceptions.dart exports LocalizationException', () {
      expect(LocalizationException, isA<Type>());
    });

    test('dictionary.dart exports Dictionary', () {
      expect(Dictionary, isA<Type>());
    });

    test('locale_detector.dart exports AnasLocaleDetector', () {
      expect(AnasLocaleDetector, isA<Type>());
    });
  });

  group('Utils shim exports', () {
    test('translation_file_parser.dart exports TranslationFileParser', () {
      expect(TranslationFileParser, isA<Type>());
    });

    test('translation_validator.dart exports TranslationValidator', () {
      expect(TranslationValidator, isA<Type>());
    });

    test('arb_interop.dart exports ArbInterop', () {
      expect(ArbInterop, isA<Type>());
    });

    test('plural_rules.dart exports PluralRules', () {
      expect(PluralRules, isA<Type>());
    });
  });

  group('Widgets shim exports', () {
    test('language_selector.dart exports AnasLanguageSelector', () {
      expect(AnasLanguageSelector, isA<Type>());
    });

    test('language_setup_overlay.dart exports AnasLanguageSetupOverlay', () {
      expect(AnasLanguageSetupOverlay, isA<Type>());
    });
  });
}
