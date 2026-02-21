/// Main entry point for the localization package.
///
/// This file exports the core localization API:
/// - [LocalizationProvider] for state management (ChangeNotifier/Provider)
/// - [Localization] for context-based access to type-safe translations
/// - [Dictionary] generated class for autocompleted translation keys
/// - [LocalizationService] (optional) for direct loading logic
/// - [LocaleStorage] for accessing or resetting persisted locale
library;

export 'src/core/localization_provider.dart';
export 'src/core/localization.dart';
export 'src/generated/dictionary.dart';
export 'src/core/localization_service.dart';
export 'src/core/locale_storage.dart';
export 'src/core/dictionary_localizations_delegate.dart';

export 'package:flutter_localizations/flutter_localizations.dart'
    show
        GlobalMaterialLocalizations,
        GlobalWidgetsLocalizations,
        GlobalCupertinoLocalizations;
