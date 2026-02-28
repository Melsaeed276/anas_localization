/// Main entry point for the localization package.
///
/// This file exports the core localization API:
/// - [AnasLocalization] for easy app setup with automatic dictionary detection
/// - [Dictionary] base class for translations with type-safe access
/// - [LocalizationService] for direct loading logic
/// - Enhanced utilities for dates, numbers, RTL support, and validation
library;

export 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalMaterialLocalizations, GlobalWidgetsLocalizations, GlobalCupertinoLocalizations;

// Core localization
export 'src/anas_localization.dart' show AnasLocalization, LocalizationExtension;
export 'src/core/anas_localization_storage.dart';
export 'src/core/dictionary_localizations_delegate.dart';
export 'src/core/localization_exceptions.dart';
export 'src/core/localization_service.dart';
export 'src/core/dictionary.dart';
export 'src/core/translation_loader.dart';

// Enhanced formatting utilities
export 'src/core/date_time_formatter.dart';
export 'src/core/number_formatter.dart';
export 'src/core/rich_text_formatter.dart';

// Text direction and RTL support
export 'src/core/text_direction_helper.dart';

// Locale detection and smart defaults
export 'src/core/locale_detector.dart';

// Pre-built UI widgets
export 'src/widgets/language_selector.dart';
export 'src/widgets/language_setup_overlay.dart';

// Validation and testing utilities
export 'src/utils/translation_validator.dart';
export 'src/utils/plural_rules.dart';
export 'src/utils/arb_interop.dart';
