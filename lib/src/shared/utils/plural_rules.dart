// lib/src/utils/plural_rules.dart
// Smart pluralization rules for different languages

/// Pluralization rules engine for different languages
class PluralRules {
  /// Get the correct plural form for a given count and locale
  static String getPluralForm(int count, String locale) {
    switch (locale) {
      case 'ar':
        return _getArabicPluralForm(count);
      case 'ru':
      case 'uk':
      case 'be':
        return _getSlavicPluralForm(count);
      case 'pl':
        return _getPolishPluralForm(count);
      case 'cs':
      case 'sk':
        return _getCzechPluralForm(count);
      case 'en':
      case 'de':
      case 'nl':
      case 'sv':
      case 'no':
      case 'da':
        return _getGermanicPluralForm(count);
      case 'fr':
      case 'pt':
      case 'it':
      case 'es':
      case 'ca':
        return _getRomancePluralForm(count);
      case 'tr':
      case 'az':
      case 'kk':
      case 'ky':
      case 'uz':
        return _getTurkicPluralForm(count);
      case 'ja':
      case 'ko':
      case 'zh':
      case 'th':
      case 'vi':
        return 'other'; // No pluralization
      default:
        return _getDefaultPluralForm(count);
    }
  }

  /// Arabic pluralization (complex 6-form system)
  static String _getArabicPluralForm(int count) {
    if (count == 0) return 'zero';
    if (count == 1) return 'one';
    if (count == 2) return 'two';
    if (count >= 3 && count <= 10) return 'few';
    if (count >= 11 && count <= 99) return 'many';
    return 'other';
  }

  /// Slavic pluralization (Russian, Ukrainian, Belarusian)
  static String _getSlavicPluralForm(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;

    if (mod10 == 1 && mod100 != 11) return 'one';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return 'few';
    return 'many';
  }

  /// Polish pluralization
  static String _getPolishPluralForm(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;

    if (count == 1) return 'one';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return 'few';
    return 'many';
  }

  /// Czech/Slovak pluralization
  static String _getCzechPluralForm(int count) {
    if (count == 1) return 'one';
    if (count >= 2 && count <= 4) return 'few';
    return 'other';
  }

  /// Germanic pluralization (English, German, Dutch, etc.)
  static String _getGermanicPluralForm(int count) {
    return count == 1 ? 'one' : 'other';
  }

  /// Romance pluralization (French, Spanish, Italian, etc.)
  static String _getRomancePluralForm(int count) {
    return count <= 1 ? 'one' : 'other';
  }

  /// Turkic pluralization (no pluralization)
  static String _getTurkicPluralForm(int count) {
    return 'other';
  }

  /// Default pluralization fallback
  static String _getDefaultPluralForm(int count) {
    return count == 1 ? 'one' : 'other';
  }

  /// Get supported plural forms for a locale
  static List<String> getSupportedForms(String locale) {
    switch (locale) {
      case 'ar':
        return ['zero', 'one', 'two', 'few', 'many', 'other'];
      case 'ru':
      case 'uk':
      case 'be':
      case 'pl':
        return ['one', 'few', 'many'];
      case 'cs':
      case 'sk':
        return ['one', 'few', 'other'];
      default:
        return ['one', 'other'];
    }
  }
}
