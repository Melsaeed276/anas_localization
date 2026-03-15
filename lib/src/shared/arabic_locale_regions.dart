// Supported Arabic-speaking regions for locale resolution and formatting.
// Used for numeral system (Eastern/Western), date/time, and currency defaults.

/// Supported Arabic region country codes (ISO 3166-1 alpha-2).
/// Covers regions referenced in the Arabic localization spec (SA, EG, AE, etc.).
const List<String> supportedArabicRegionCodes = [
  'SA', // Saudi Arabia (Eastern numerals)
  'EG', // Egypt
  'AE', // United Arab Emirates
  'MA', // Morocco (Western numerals)
  'DZ', // Algeria
  'TN', // Tunisia
  'LB', // Lebanon
  'JO', // Jordan
  'IQ', // Iraq
];

/// Returns true if [regionCode] is a supported Arabic region.
bool isSupportedArabicRegion(String regionCode) {
  return supportedArabicRegionCodes.contains(regionCode.toUpperCase());
}
