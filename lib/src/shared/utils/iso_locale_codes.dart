library;

/// ISO 639-1 language codes with their names.
const kIsoLanguageCodes = <String, String>{
  'en': 'English',
  'ar': 'Arabic',
  'zh': 'Chinese',
  'fr': 'French',
  'es': 'Spanish',
  'de': 'German',
  'it': 'Italian',
  'ja': 'Japanese',
  'ko': 'Korean',
  'pt': 'Portuguese',
  'ru': 'Russian',
  'hi': 'Hindi',
  'bn': 'Bengali',
  'pa': 'Punjabi',
  'te': 'Telugu',
  'mr': 'Marathi',
  'gu': 'Gujarati',
  'kn': 'Kannada',
  'ml': 'Malayalam',
  'ta': 'Tamil',
  'ur': 'Urdu',
  'th': 'Thai',
  'vi': 'Vietnamese',
  'tr': 'Turkish',
  'pl': 'Polish',
  'uk': 'Ukrainian',
  'el': 'Greek',
  'cs': 'Czech',
  'hu': 'Hungarian',
  'ro': 'Romanian',
  'sv': 'Swedish',
  'no': 'Norwegian',
  'da': 'Danish',
  'fi': 'Finnish',
  'nl': 'Dutch',
  'be': 'Belarusian',
  'bg': 'Bulgarian',
  'hr': 'Croatian',
  'sr': 'Serbian',
  'sk': 'Slovak',
  'sl': 'Slovenian',
  'et': 'Estonian',
  'lv': 'Latvian',
  'lt': 'Lithuanian',
  'he': 'Hebrew',
  'id': 'Indonesian',
  'ms': 'Malay',
  'tl': 'Tagalog',
  'sw': 'Swahili',
  'af': 'Afrikaans',
  'ca': 'Catalan',
  'eu': 'Basque',
  'gl': 'Galician',
  'cy': 'Welsh',
  'ga': 'Irish',
  'sq': 'Albanian',
  'mk': 'Macedonian',
  'fa': 'Persian',
  'hy': 'Armenian',
  'az': 'Azerbaijani',
  'ka': 'Georgian',
  'am': 'Amharic',
};

/// ISO 3166-1 alpha-2 country codes with their names.
const kIsoCountryCodes = <String, String>{
  'US': 'United States',
  'GB': 'United Kingdom',
  'CA': 'Canada',
  'AU': 'Australia',
  'NZ': 'New Zealand',
  'SA': 'Saudi Arabia',
  'AE': 'United Arab Emirates',
  'EG': 'Egypt',
  'DE': 'Germany',
  'FR': 'France',
  'IT': 'Italy',
  'ES': 'Spain',
  'BR': 'Brazil',
  'MX': 'Mexico',
  'JP': 'Japan',
  'CN': 'China',
  'IN': 'India',
  'RU': 'Russia',
  'KR': 'South Korea',
  'TW': 'Taiwan',
  'SG': 'Singapore',
  'MY': 'Malaysia',
  'TH': 'Thailand',
  'VN': 'Vietnam',
  'ID': 'Indonesia',
  'PH': 'Philippines',
  'NL': 'Netherlands',
  'BE': 'Belgium',
  'CH': 'Switzerland',
  'AT': 'Austria',
  'SE': 'Sweden',
  'NO': 'Norway',
  'DK': 'Denmark',
  'FI': 'Finland',
  'PL': 'Poland',
  'CZ': 'Czech Republic',
  'HU': 'Hungary',
  'RO': 'Romania',
  'GR': 'Greece',
  'PT': 'Portugal',
  'TR': 'Turkey',
  'IL': 'Israel',
  'ZA': 'South Africa',
  'NG': 'Nigeria',
  'KE': 'Kenya',
  'MA': 'Morocco',
  'TN': 'Tunisia',
  'LB': 'Lebanon',
  'JO': 'Jordan',
  'IQ': 'Iraq',
  'SY': 'Syria',
  'IR': 'Iran',
  'PK': 'Pakistan',
  'BD': 'Bangladesh',
  'LK': 'Sri Lanka',
  'HK': 'Hong Kong',
  'MO': 'Macau',
  'AF': 'Afghanistan',
  'LY': 'Libya',
  'SD': 'Sudan',
};

/// Returns the name of a language given its ISO 639-1 code.
/// Returns null if the code is not recognized.
String? getLanguageName(String languageCode) {
  return kIsoLanguageCodes[languageCode.toLowerCase()];
}

/// Returns the name of a country given its ISO 3166-1 alpha-2 code.
/// Returns null if the code is not recognized.
String? getCountryName(String countryCode) {
  return kIsoCountryCodes[countryCode.toUpperCase()];
}

/// Validates whether a language code is a valid ISO 639-1 or 639-2 code.
bool isValidLanguageCode(String code) {
  return kIsoLanguageCodes.containsKey(code.toLowerCase());
}

/// Validates whether a country code is a valid ISO 3166-1 alpha-2 code.
bool isValidCountryCode(String code) {
  return kIsoCountryCodes.containsKey(code.toUpperCase());
}

/// Normalizes a locale code to use underscores (en_US) instead of hyphens (en-US).
String normalizeLocaleCode(String code) {
  return code.replaceAll('-', '_');
}

/// Parses a locale code and returns (languageCode, countryCode) tuple.
/// Returns null if the code cannot be parsed.
({String languageCode, String? countryCode})? parseLocaleCode(String code) {
  final normalized = normalizeLocaleCode(code);
  final parts = normalized.split('_');

  if (parts.isEmpty || parts[0].isEmpty) return null;

  final languageCode = parts[0].toLowerCase();
  final countryCode = parts.length > 1 ? parts[1].toUpperCase() : null;

  return (languageCode: languageCode, countryCode: countryCode);
}
