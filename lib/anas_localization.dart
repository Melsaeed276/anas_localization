// Public package entrypoint.
//
// Most apps should import:
// `package:anas_localization/anas_localization.dart`
export 'src/anas_localization.dart';

// Core types (used by generated dictionaries + tests)
export 'src/core/dictionary.dart' show Dictionary;
export 'src/core/localization_service.dart' show LocalizationService;
export 'src/core/dictionary_localizations_delegate.dart'
    show DictionaryLocalizations, DictionaryLocalizationsDelegate;
export 'src/core/text_direction_helper.dart'
    show AnasTextDirection, AnasDirectionalityWrapper, TextDirectionExtension;
export 'src/core/number_formatter.dart'
    show AnasNumberFormatter, NumberFormattingExtension;
export 'src/core/date_time_formatter.dart' show AnasDateTimeFormatter;
export 'src/core/rich_text_formatter.dart' show AnasInterpolation, AnasRichText;

// Widgets
export 'src/widgets/language_selector.dart'
    show AnasLanguageSelector, AnasLanguageToggle, AnasLanguageDialog;
export 'src/widgets/language_setup_overlay.dart' show AnasLanguageSetupOverlay;
