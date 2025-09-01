/// Theme-aware localization utilities
library;

import 'package:flutter/material.dart';

/// Provides theme-aware translation support
class AnasThemeLocalizer {
  const AnasThemeLocalizer(this.brightness);

  final Brightness brightness;

  /// Get theme-specific translation key
  String getThemeKey(String baseKey) {
    final suffix = brightness == Brightness.dark ? '_dark' : '_light';
    return '$baseKey$suffix';
  }

  /// Check if dark mode is active
  bool get isDarkMode => brightness == Brightness.dark;

  /// Check if light mode is active
  bool get isLightMode => brightness == Brightness.light;
}

/// Extension to add theme-aware localization to BuildContext
extension ThemeLocalizationExtension on BuildContext {
  /// Get theme localizer for current brightness
  AnasThemeLocalizer get themeLocalizer {
    final brightness = Theme.of(this).brightness;
    return AnasThemeLocalizer(brightness);
  }

  /// Get theme-specific translation (falls back to base key if theme-specific doesn't exist)
  String getThemeText(String baseKey, {String? darkText, String? lightText}) {
    final isDark = Theme.of(this).brightness == Brightness.dark;

    if (isDark && darkText != null) {
      return darkText;
    } else if (!isDark && lightText != null) {
      return lightText;
    }

    // Fallback to base translation
    return baseKey;
  }
}
