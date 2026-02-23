/// RTL and text direction utilities for localization
library;

import 'package:flutter/widgets.dart';

/// Provides text direction utilities for different locales
class AnasTextDirection {
  /// Get text direction for a given locale
  static TextDirection getTextDirection(Locale locale) {
    // RTL languages
    const rtlLanguages = {
      'ar', // Arabic
      'he', // Hebrew
      'fa', // Persian/Farsi
      'ur', // Urdu
      'ku', // Kurdish
      'ps', // Pashto
      'sd', // Sindhi
      'yi', // Yiddish
    };

    return rtlLanguages.contains(locale.languageCode)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  /// Check if a locale is RTL
  static bool isRTL(Locale locale) {
    return getTextDirection(locale) == TextDirection.rtl;
  }
}

/// Widget that automatically handles text direction based on current locale
class AnasDirectionalityWrapper extends StatelessWidget {
  const AnasDirectionalityWrapper({
    super.key,
    required this.child,
    this.locale,
  });

  final Widget child;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    final currentLocale = locale ?? Localizations.localeOf(context);
    final textDirection = AnasTextDirection.getTextDirection(currentLocale);

    return Directionality(
      textDirection: textDirection,
      child: child,
    );
  }
}

/// Extension to add text direction helpers to BuildContext
extension TextDirectionExtension on BuildContext {
  /// Get text direction for current locale
  TextDirection get textDirection {
    final locale = Localizations.localeOf(this);
    return AnasTextDirection.getTextDirection(locale);
  }

  /// Check if current locale is RTL
  bool get isRTL => textDirection == TextDirection.rtl;

  /// Check if current locale is LTR
  bool get isLTR => textDirection == TextDirection.ltr;
}
