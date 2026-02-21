/// A singleton provider that manages the application's localization state.
///
/// This provider offers reactive access to the current [Dictionary] and locale,
/// allowing widgets to rebuild when the locale changes. It is designed to be used
/// with `Provider`, `ChangeNotifierProvider`, or any other state management solution
/// that listens to [ChangeNotifier].
///
/// Usage:
/// ```dart
/// final localizationProvider = LocalizationProvider();
/// localizationProvider.loadLocale('en');
/// ```
///
/// Widgets can listen to this provider to reactively update UI based on locale changes.
library;

import 'package:flutter/widgets.dart';
import 'locale_storage.dart';
import 'localization_service.dart';
import '../generated/dictionary.dart';

/// Provides reactive access to the current [Dictionary] and locale.
///
/// This class is a singleton and extends [ChangeNotifier] to notify listeners
/// when the locale or dictionary changes. It must be initialized by calling
/// [loadLocale] before accessing [dictionary] or [locale].
class LocalizationProvider extends ChangeNotifier {
  LocalizationProvider._internal();

  static final LocalizationProvider _instance =
      LocalizationProvider._internal();
  factory LocalizationProvider() => _instance;

  Dictionary? _dictionary;
  String? _locale;

  /// Gets the current loaded [Dictionary].
  ///
  /// Throws an [Exception] if accessed before a dictionary has been loaded
  /// via [loadLocale].
  Dictionary get dictionary {
    if (_dictionary == null) {
      throw Exception('Dictionary not loaded. Call loadLocale() first.');
    }
    return _dictionary!;
  }

  /// Gets the current locale code (e.g., "en").
  ///
  /// Throws an [Exception] if accessed before a locale has been loaded
  /// via [loadLocale].
  String get locale {
    if (_locale == null) {
      throw Exception('Locale not loaded. Call loadLocale() first.');
    }
    return _locale!;
  }

  /// Loads the dictionary and locale for the given [localeCode].
  ///
  /// This method asynchronously loads the locale data using [LocalizationService]
  /// and updates the internal state. After loading, it notifies all listeners.
  ///
  /// Throws if the loading process fails.
  Future<void> loadLocale(String localeCode) async {
    await LocalizationService().loadLocale(localeCode);
    _dictionary = LocalizationService().currentDictionary;
    _locale = LocalizationService().currentLocale;

    // Save the selected locale for persistence
    await LocaleStorage.saveLocale(localeCode);

    notifyListeners();
  }

  /// Loads the saved locale from storage if available, or uses [fallback] if not.
  ///
  /// This should be called at app startup to restore the user's preferred language.
  /// If no locale is saved, the [fallback] locale code (default: 'en') will be used.
  Future<void> loadSavedLocaleOrDefault([String fallback = 'en']) async {
    String? saved = await LocaleStorage.loadLocale();
    await loadLocale(saved ?? fallback);
  }
}
