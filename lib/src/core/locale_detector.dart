/// Automatic locale detection and setup utilities
library;

import 'dart:ui' show window, Locale;
import 'package:flutter/services.dart';

/// Provides automatic locale detection and smart defaults
class AnasLocaleDetector {
  /// Get the best locale match from device settings
  static Locale detectBestLocale(List<Locale> supportedLocales) {
    final deviceLocales = window.locales;

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
    final systemLocales = window.locales;
    return systemLocales.isNotEmpty ? systemLocales.first : const Locale('en');
  }

  /// Check if a locale is supported
  static bool isLocaleSupported(Locale locale, List<Locale> supportedLocales) {
    return supportedLocales.any((supported) =>
        supported.languageCode == locale.languageCode);
  }

  /// Get region-aware currency for locale
  static String getCurrencyForLocale(Locale locale) {
    switch (locale.countryCode?.toUpperCase()) {
      case 'US': case 'CA': return 'USD';
      case 'GB': return 'GBP';
      case 'EU': case 'DE': case 'FR': case 'IT': case 'ES': return 'EUR';
      case 'TR': return 'TRY';
      case 'SA': case 'AE': return 'SAR';
      case 'JP': return 'JPY';
      case 'CN': return 'CNY';
      case 'IN': return 'INR';
      default: return 'USD';
    }
  }
}
