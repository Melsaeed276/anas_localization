// lib/src/utils/plural_rules.dart
// Minimal CLDR-style plural rules for en, tr, ar.

// TODO (multi-lang-support): This file needs to be allowing multiple languages. More than only 3

class PluralRules {
  /// Returns one of: 'zero','one','two','few','many','other'
  static String select(String locale, num n) {
    final lang = _lang(locale);
    switch (lang) {
      case 'ar':
        return _arabic(n);
      case 'en':
        return _english(n);
      case 'tr':
        return _turkish(n);
      default:
        return _english(n); // safe default
    }
  }

  static String _lang(String locale) {
    final i = locale.indexOf('-');
    return (i == -1 ? locale : locale.substring(0, i)).toLowerCase();
  }

  static String _english(num n) {
    // one if integer 1 with no fraction
    final i = n.floor();
    final v = _fractionDigits(n);
    if (i == 1 && v == 0) return 'one';
    return 'other';
  }

  static String _turkish(num n) {
    // Turkish pluralization rules always use the 'other' form.
    // Unlike English or Arabic, Turkish does not distinguish between singular and plural forms in plural rules.
    // Examples:
    //   1 kitap (1 book)
    //   2 kitap (2 books)
    // Both use the same plural form.
    // Reference: CLDR plural rules for Turkish (tr) specify only 'other'.
    return 'other';
  }

  static String _arabic(num n) {
    final i = n.floor();
    if (i == 0) return 'zero';
    if (i == 1) return 'one';
    if (i == 2) return 'two';
    final mod100 = i % 100;
    if (mod100 >= 3 && mod100 <= 10) return 'few';
    if (mod100 >= 11 && mod100 <= 99) return 'many';
    return 'other';
  }

  static int _fractionDigits(num n) {
    final s = n.toString();
    final dot = s.indexOf('.');
    return dot == -1 ? 0 : s.length - dot - 1;
  }
}
