// lib/src/shared/utils/plural_rules.dart
// Smart pluralization rules for different languages

/// Pluralization rules engine for different languages.
/// English uses a [num] contract: singular only when count.abs() == 1; otherwise plural.
class PluralRules {
  /// Get the correct plural form for a given count and locale.
  /// Prefer [getPluralFormNum] when the count may be fractional or negative (e.g. English).
  static String getPluralForm(int count, String locale) {
    return getPluralFormNum(count.toDouble(), locale);
  }

  /// Get the correct plural form for a [num] count and locale.
  /// English: one only when [count].abs() == 1; other for 0, decimals, and all other values.
  static String getPluralFormNum(num count, String locale) {
    switch (locale) {
      case 'ar':
        return _getArabicPluralForm(count.truncate());
      case 'ru':
      case 'uk':
      case 'be':
        return _getSlavicPluralForm(count.toInt());
      case 'pl':
        return _getPolishPluralForm(count.toInt());
      case 'cs':
      case 'sk':
        return _getCzechPluralForm(count.toInt());
      case 'en':
        return _getEnglishPluralForm(count);
      case 'de':
      case 'nl':
      case 'sv':
      case 'no':
      case 'da':
        return _getGermanicPluralForm(count.toInt());
      case 'fr':
      case 'pt':
      case 'it':
      case 'es':
      case 'ca':
        return _getRomancePluralForm(count.toInt());
      case 'tr':
      case 'az':
      case 'kk':
      case 'ky':
      case 'uz':
        return _getTurkicPluralForm(count.toInt());
      case 'ja':
      case 'ko':
      case 'zh':
      case 'th':
      case 'vi':
        return 'other'; // No pluralization
      default:
        return _getDefaultPluralForm(count.toInt());
    }
  }

  /// English plural: one only when absolute value is 1; other for 0, decimals, negatives.
  static String _getEnglishPluralForm(num count) {
    return count.abs() == 1 ? 'one' : 'other';
  }

  /// Arabic pluralization (complex 6-form system, CLDR-aligned).
  /// few = n % 100 in 3..10, many = n % 100 in 11..99, other = rest.
  static String _getArabicPluralForm(int count) {
    if (count == 0) return 'zero';
    if (count == 1) return 'one';
    if (count == 2) return 'two';
    final mod100 = count.abs() % 100;
    if (mod100 >= 3 && mod100 <= 10) return 'few';
    if (mod100 >= 11 && mod100 <= 99) return 'many';
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

  /// Get supported plural forms for a locale.
  /// English uses only one/other.
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
      case 'en':
        return ['one', 'other'];
      default:
        return ['one', 'other'];
    }
  }
}
