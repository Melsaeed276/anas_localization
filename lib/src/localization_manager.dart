// ignore_for_file: unused_element

part of 'anas_localization.dart';

class _LocalizationManager {
  _LocalizationManager._();

  /// Lazy Singleton
  static _LocalizationManager? _instance;
  static _LocalizationManager get instance => _instance ??= _LocalizationManager._();

  /// Sets the dictionary factory to use the app's generated Dictionary class
  void setDictionaryFactory(Dictionary Function(Map<String, dynamic>, {required String locale}) factory) {
    // Also set it in the LocalizationService for consistency
    LocalizationService().setDictionaryFactory(factory);
  }

  /// Returns the currently loaded [Dictionary].
  ///
  /// Throws an [Exception] if no dictionary is loaded.
  Dictionary get currentDictionary => LocalizationService().currentDictionary;

  /// Value notifier for the current locale
  ///
  /// We can listen for changes of the current locale using this notifier.
  /// And every other function that depends on the current locale can use this notifier's value.
  ///
  // * Using Locale as value type will allow us to use regional locales too. (Example: en_UK, en_US)
  final ValueNotifier<Locale?> _localeNotifier = ValueNotifier(null);

  // Store listener wrappers for proper removal
  final Map<void Function(Locale?), void Function()> _listenerWrappers = {};

  void addListener(void Function(Locale?) listener) {
    void wrapper() {
      try {
        listener(_localeNotifier.value);
      } catch (e) {
        // Use logging service instead of print
        logger.error('Localization listener error', 'LocalizationManager', e);
      }
    }

    _listenerWrappers[listener] = wrapper;
    _localeNotifier.addListener(wrapper);
    logger.listenerAdded();
  }

  void removeListener(void Function(Locale?) listener) {
    final wrapper = _listenerWrappers.remove(listener);
    if (wrapper != null) {
      _localeNotifier.removeListener(wrapper);
      logger.listenerRemoved();
    }
  }

  /// Gets the current locale code (e.g., "en").
  ///
  /// Throws an [Exception] if accessed before a locale has been loaded
  /// via [loadLocale].
  Locale get locale {
    if (_localeNotifier.value == null) {
      throw const LocalizationNotInitializedException();
    }
    return _localeNotifier.value!;
  }

  /// Loads the dictionary and locale for the given [locale].
  ///
  /// This method asynchronously loads the locale data using [LocalizationService]
  /// and updates the internal state. After loading, it notifies all listeners.
  ///
  /// Throws if the loading process fails.
  Future<Locale> loadLocale(Locale locale) async {
    final service = LocalizationService();
    await service.loadLocale(LocalizationService.localeToCode(locale));

    _localeNotifier.value = locale;

    // Save the selected locale for persistence
    await AnasLocalizationStorage.saveLocale(locale.toString());
    return locale;
  }

  /// Loads the saved locale from storage if available, or uses [fallback] if not.
  ///
  /// This should be called at app startup to restore the user's preferred language.
  /// If no locale is saved, the [fallback] locale code (default: 'en') will be used.
  Future<Locale> loadSavedLocaleOrDefault([Locale fallback = const Locale('en')]) async {
    final saved = await AnasLocalizationStorage.loadLocale();
    if (saved == null || saved.trim().isEmpty) {
      return await loadLocale(fallback);
    }

    final normalized = LocalizationService.normalizeLocaleCode(saved);
    final parts = normalized.split('_').where((element) => element.trim().isNotEmpty).toList();

    if (parts.isEmpty) {
      return await loadLocale(fallback);
    }

    final languageCode = parts.first.toLowerCase();
    String? scriptCode;
    String? countryCode;

    if (parts.length >= 2) {
      if (parts[1].length == 4) {
        final script = parts[1].toLowerCase();
        scriptCode = script[0].toUpperCase() + script.substring(1);
      } else {
        countryCode = parts[1].toUpperCase();
      }
    }

    if (parts.length >= 3) {
      countryCode = parts[2].toUpperCase();
    }

    final resolvedLocale = Locale.fromSubtags(
      languageCode: languageCode,
      scriptCode: scriptCode,
      countryCode: countryCode,
    );

    return await loadLocale(resolvedLocale);
  }

  Future<void> saveLocale(Locale locale) async {
    final localeCode = LocalizationService.localeToCode(locale);

    if (!LocalizationService.isLocaleSupported(localeCode)) {
      throw UnsupportedLocaleException(localeCode);
    }

    await LocalizationService().loadLocale(localeCode);

    // Then save to storage
    await AnasLocalizationStorage.saveLocale(locale.toString());

    // Finally, update the notifier to trigger all listeners
    _localeNotifier.value = locale;
  }
}
