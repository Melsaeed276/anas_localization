/// Arabic text utilities: search normalization and sort/collation guidance (US9).
library;

/// Normalizes [text] for search matching: strips combining marks (diacritics) so
/// that queries match regardless of tashkeel. For hamza equivalence or full NFD,
/// consider using package:unicode or platform collation.
String normalizeForSearch(String text) {
  if (text.isEmpty) return text;
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    if (!_isCombiningMark(rune)) buffer.writeCharCode(rune);
  }
  return buffer.toString();
}

bool _isCombiningMark(int code) {
  if (code >= 0x0300 && code <= 0x036F) return true; // Combining Diacritical Marks
  if (code >= 0x0610 && code <= 0x061A) return true; // Arabic combining
  if (code >= 0x064B && code <= 0x065F) return true; // Arabic tashkeel etc.
  if (code == 0x0670) return true; // Arabic letter superscript alef
  return false;
}

/// Sorts [list] in place using [compare]. For locale-aware Arabic sort, use a
/// collation API (e.g. intl4x Collation or platform) and pass its compare;
/// this helper documents the pattern.
void sortWithLocale(List<String> list, int Function(String a, String b) compare) {
  list.sort(compare);
}
