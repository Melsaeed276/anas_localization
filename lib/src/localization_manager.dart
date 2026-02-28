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
    await service.loadLocale(locale.languageCode);

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

    final normalized = saved.replaceAll('-', '_').trim();
    final parts = normalized
        .split('_')
        .where((element) => element.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return await loadLocale(fallback);
    }

    final languageCode = parts.first.toLowerCase();
    final countryCode = parts.length > 1 ? parts[1].toUpperCase() : null;
    final resolvedLocale = countryCode != null
        ? Locale(languageCode, countryCode)
        : Locale(languageCode);

    return await loadLocale(resolvedLocale);
  }

  Future<void> saveLocale(Locale locale) async {
    // ! We need an update of supported Locales
    if (!LocalizationService.supportedLocales.contains(locale.languageCode)) {
      throw UnsupportedLocaleException(locale.languageCode);
    }

    // First, load the new locale in the service
    await LocalizationService().loadLocale(locale.languageCode);

    // Then save to storage
    await AnasLocalizationStorage.saveLocale(locale.toString());

    // Finally, update the notifier to trigger all listeners
    _localeNotifier.value = locale;
  }
}
