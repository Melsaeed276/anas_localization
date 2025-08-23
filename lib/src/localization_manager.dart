// ignore_for_file: unused_element

part of 'anas_localization.dart';

class _LocalizationManager {
  _LocalizationManager._();

  /// Lazy Singleton
  static _LocalizationManager? _instance;
  static _LocalizationManager get instance => _instance ??= _LocalizationManager._();

  /// Value notifier for the current locale
  ///
  /// We can listen for changes of the current locale using this notifier.
  /// And every other function that depends on the current locale can use this notifier's value.
  ///
  // * Using Locale as value type will allow us to use regional locales too. (Example: en_UK, en_US)
  final ValueNotifier<Locale?> _localeNotifier = ValueNotifier(null);

  void addListener(void Function(Locale?) listener) {
    _localeNotifier.addListener(() => listener(_localeNotifier.value));
  }

  /// Gets the current locale code (e.g., "en").
  ///
  /// Throws an [Exception] if accessed before a locale has been loaded
  /// via [loadLocale].
  Locale get locale {
    if (_localeNotifier.value == null) {
      throw Exception('Locale not loaded. Call loadLocale() first.');
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
    await LocaleStorage.saveLocale(locale.toString());
    return locale;
  }

  /// Loads the saved locale from storage if available, or uses [fallback] if not.
  ///
  /// This should be called at app startup to restore the user's preferred language.
  /// If no locale is saved, the [fallback] locale code (default: 'en') will be used.
  Future<Locale> loadSavedLocaleOrDefault([Locale fallback = const Locale('en')]) async {
    final saved = await LocaleStorage.loadLocale();
    return await loadLocale(saved != null ? Locale(saved) : fallback);
  }

  Future<void> saveLocale(Locale locale) async {
    // ! We need an update of supported Locales
    if (!LocalizationService.supportedLocales.contains(locale.languageCode)) {
      throw Exception('Unsupported locale: ${locale.languageCode}');
    }

    await LocaleStorage.saveLocale(locale.toString());
    _LocalizationManager.instance._localeNotifier.value = locale;
  }
}
