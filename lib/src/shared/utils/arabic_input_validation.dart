/// Arabic name and phone validation helpers (US10 / FR-014).
/// Configurable rules for allowed character set, length, and regional phone formats.
library;

/// Default max grapheme length for Arabic name validation (configurable).
const int kDefaultArabicNameMaxLength = 200;

/// Default min length for Arabic name.
const int kDefaultArabicNameMinLength = 2;

/// Returns true if [name] is non-empty, within length bounds, and contains only
/// allowed characters: Unicode letters (including Arabic), spaces, and common
/// diacritics. Use [minLength]/[maxLength] to override defaults.
bool isReasonablyValidArabicName(
  String name, {
  int minLength = kDefaultArabicNameMinLength,
  int maxLength = kDefaultArabicNameMaxLength,
}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return false;
  final length = trimmed.runes.length;
  if (length < minLength || length > maxLength) return false;
  for (final rune in trimmed.runes) {
    if (!_isAllowedNameChar(rune)) return false;
  }
  return true;
}

bool _isAllowedNameChar(int code) {
  if (code == 0x20 || code == 0x00A0) return true; // space, NBSP
  if (code >= 0x0600 && code <= 0x06FF) return true; // Arabic
  if (code >= 0x0750 && code <= 0x077F) return true; // Arabic Supplement
  if (code >= 0x08A0 && code <= 0x08FF) return true; // Arabic Extended-A
  if (code >= 0xFB50 && code <= 0xFDFF) return true; // Arabic Presentation Forms
  if (code >= 0xFE70 && code <= 0xFEFF) return true;
  if (code >= 0x0300 && code <= 0x036F) return true; // combining
  if (code >= 0x0610 && code <= 0x061A) return true;
  if (code >= 0x064B && code <= 0x065F) return true;
  if (code >= 0x0041 && code <= 0x005A) return true; // Latin
  if (code >= 0x0061 && code <= 0x007A) return true;
  return false;
}

/// Supported Arabic region codes for phone validation (subset of supportedArabicRegionCodes).
const List<String> kArabicPhoneRegionCodes = ['SA', 'EG', 'AE', 'MA', 'DZ', 'JO', 'KW', 'BH', 'QA', 'OM', 'TN', 'LB', 'IQ', 'SY', 'YE'];

/// Returns true if [phone] looks like a valid number for [regionCode] (e.g. SA, EG).
/// Uses a simple length and digit check; for strict E.164 or national format use
/// a dedicated library (e.g. libphonenumber) or pass a custom [validator].
bool isReasonablyValidArabicRegionPhone(
  String phone,
  String regionCode, {
  bool Function(String digits)? validator,
}) {
  final digits = phone.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');
  if (digits.isEmpty) return false;
  if (!RegExp(r'^\+?[0-9]+$').hasMatch(digits)) return false;
  if (validator != null) return validator(digits);
  final len = digits.length;
  if (digits.startsWith('+')) {
    if (len < 10 || len > 15) return false;
  } else {
    if (len < 8 || len > 12) return false;
  }
  return kArabicPhoneRegionCodes.contains(regionCode.toUpperCase());
}
