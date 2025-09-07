/// Automatic locale detection and setup utilities
library;

import 'dart:ui' show PlatformDispatcher, Locale;




/// Provides automatic locale detection and smart defaults
class AnasLocaleDetector {
  /// Get the best locale match from device settings
  static Locale detectBestLocale(List<Locale> supportedLocales) {
    final deviceLocales = PlatformDispatcher.instance.locales;

    // Try exact match first (language + country)
    for (final deviceLocale in deviceLocales) {
      for (final supported in supportedLocales) {
        if (deviceLocale.languageCode == supported.languageCode &&
            deviceLocale.countryCode == supported.countryCode) {
          return supported;
        }
      }
    }

    // Try language-only match
    for (final deviceLocale in deviceLocales) {
      for (final supported in supportedLocales) {
        if (deviceLocale.languageCode == supported.languageCode) {
          return supported;
        }
      }
    }

    // Fallback to first supported locale
    return supportedLocales.isNotEmpty ? supportedLocales.first : const Locale('en');
  }

  /// Get system locale
  static Locale get systemLocale {
    final systemLocales = PlatformDispatcher.instance.locales;
    return systemLocales.isNotEmpty ? systemLocales.first : const Locale('en');
  }

  /// Check if a locale is supported
  static bool isLocaleSupported(Locale locale, List<Locale> supportedLocales) {
    return supportedLocales.any((supported) =>
        supported.languageCode == locale.languageCode,
    );
  }
}
