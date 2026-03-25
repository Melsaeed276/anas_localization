# Data Model: Hierarchical Locale Fallback System with Custom Locale Support

**Feature Branch**: `006-locale-hierarchical-fallback`  
**Date**: 2026-03-24

## Entity Definitions

### 1. CatalogState (Extended)

**Location**: `lib/src/features/catalog/domain/entities/catalog_models.dart`

**Description**: Root state object for catalog persistence. Extended with language group fallback configuration and custom locale direction settings.

```dart
class CatalogState {
  CatalogState({
    required this.version,
    required this.sourceLocale,
    required this.format,
    required this.keys,
    Map<String, String>? languageGroupFallbacks,
    Map<String, String>? customLocaleDirections,
  })  : languageGroupFallbacks = languageGroupFallbacks ?? <String, String>{},
        customLocaleDirections = customLocaleDirections ?? <String, String>{};

  final int version;
  String sourceLocale;
  String format;
  final Map<String, CatalogKeyState> keys;
  
  /// Maps a regional locale to its language group fallback.
  /// Example: {"ar_SA": "ar_EG", "ar_AE": "ar_EG"}
  /// When ar_SA is missing a translation, it falls back to ar_EG.
  final Map<String, String> languageGroupFallbacks;
  
  /// Maps custom locales to their text direction ("ltr" or "rtl").
  /// Example: {"custom_dialect": "rtl", "fr_CA": "ltr"}
  /// Only needed for locales not in the predefined kAvailableLocales list.
  final Map<String, String> customLocaleDirections;
}
```

**Fields**:
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| version | int | Yes | 3 | Schema version |
| sourceLocale | String | Yes | - | Primary source locale for translations |
| format | String | Yes | - | Translation file format (json/yaml/csv/arb) |
| keys | Map<String, CatalogKeyState> | Yes | {} | Translation key states |
| languageGroupFallbacks | Map<String, String> | No | {} | Regional locale → fallback locale mapping |
| customLocaleDirections | Map<String, String> | No | {} | Custom locale → direction ("ltr"/"rtl") |

**Validation Rules**:
- `languageGroupFallbacks` keys and values must be valid locale codes
- `languageGroupFallbacks` must not contain circular references
- `customLocaleDirections` values must be "ltr" or "rtl"

**JSON Schema**:
```json
{
  "version": 3,
  "sourceLocale": "en",
  "format": "json",
  "languageGroupFallbacks": {
    "ar_SA": "ar_EG",
    "ar_AE": "ar_EG"
  },
  "customLocaleDirections": {
    "custom_dialect": "rtl"
  },
  "keys": {}
}
```

---

### 2. LocaleValidationResult

**Location**: `lib/src/features/catalog/domain/entities/locale_validation_result.dart` (new file)

**Description**: Result of validating a locale code against ISO standards.

```dart
class LocaleValidationResult {
  const LocaleValidationResult({
    required this.isValid,
    this.languageCode,
    this.countryCode,
    this.languageName,
    this.countryName,
    this.displayName,
    this.errorMessage,
    this.errorType,
  });

  /// Whether the locale code is valid.
  final bool isValid;
  
  /// Parsed and normalized language code (e.g., "en").
  final String? languageCode;
  
  /// Parsed and normalized country code (e.g., "US"). Null if not present.
  final String? countryCode;
  
  /// Human-readable language name (e.g., "English").
  final String? languageName;
  
  /// Human-readable country name (e.g., "United States"). Null if not present.
  final String? countryName;
  
  /// Full display name (e.g., "English (United States)" or "English").
  final String? displayName;
  
  /// Error message if validation failed.
  final String? errorMessage;
  
  /// Type of validation error.
  final LocaleValidationErrorType? errorType;
}

enum LocaleValidationErrorType {
  invalidFormat,
  invalidLanguageCode,
  invalidCountryCode,
  duplicateLocale,
}
```

**State Transitions**: N/A (immutable value object)

---

### 3. LanguageGroup

**Location**: `lib/src/features/catalog/domain/entities/language_group.dart` (new file)

**Description**: Represents a logical grouping of locales sharing the same base language. Computed dynamically, not persisted.

```dart
class LanguageGroup {
  const LanguageGroup({
    required this.baseLanguageCode,
    required this.locales,
    this.fallbackLocale,
  });

  /// The ISO 639-1/639-2 language code (e.g., "ar", "en").
  final String baseLanguageCode;
  
  /// All locales in this language group (e.g., ["ar", "ar_SA", "ar_EG"]).
  final List<String> locales;
  
  /// The designated fallback locale for this language group.
  /// Null if no fallback is configured.
  final String? fallbackLocale;
  
  /// Whether this group has 2+ locales (enabling fallback configuration).
  bool get canConfigureFallback => locales.length >= 2;
  
  /// Display name for the group (e.g., "Arabic (3 locales)").
  String get displayName => '${_languageName(baseLanguageCode)} (${locales.length} locales)';
}
```

**Relationships**:
- Derived from `CatalogMeta.locales` by grouping on language code
- `fallbackLocale` references `CatalogState.languageGroupFallbacks`

---

### 4. FallbackChain

**Location**: `lib/src/features/catalog/domain/entities/fallback_chain.dart` (new file)

**Description**: Represents the complete resolution path for a locale's translations.

```dart
class FallbackChain {
  const FallbackChain({
    required this.targetLocale,
    required this.chain,
    required this.projectDefaultLocale,
  });

  /// The locale for which this chain was computed.
  final String targetLocale;
  
  /// Ordered list of locales to try when resolving translations.
  /// First element is the target locale itself.
  final List<String> chain;
  
  /// The project's default fallback locale (always last in chain).
  final String projectDefaultLocale;
  
  /// Human-readable representation (e.g., "ar_SA → ar_EG → en").
  String get displayString => chain.join(' → ');
  
  /// Whether this chain includes a language group fallback.
  bool get hasLanguageGroupFallback => chain.length > 2 && 
      chain[1] != _getLanguageCode(targetLocale) &&
      chain[1] != projectDefaultLocale;
}
```

**Example**:
```dart
FallbackChain(
  targetLocale: 'ar_SA',
  chain: ['ar_SA', 'ar_EG', 'ar', 'en'],
  projectDefaultLocale: 'en',
)
// displayString: "ar_SA → ar_EG → ar → en"
```

---

### 5. CustomLocale

**Location**: `lib/src/features/catalog/domain/entities/custom_locale.dart` (new file)

**Description**: Represents a user-defined locale not in the predefined list.

```dart
class CustomLocale {
  const CustomLocale({
    required this.code,
    required this.direction,
    required this.displayName,
    required this.languageName,
    this.countryName,
  });

  /// Normalized locale code (e.g., "fr_CA").
  final String code;
  
  /// Text direction: "ltr" or "rtl".
  final String direction;
  
  /// Full display name (e.g., "French (Canada)").
  final String displayName;
  
  /// Language name component (e.g., "French").
  final String languageName;
  
  /// Country name component (e.g., "Canada"). Null for language-only locales.
  final String? countryName;
  
  /// Whether this is an RTL locale.
  bool get isRtl => direction == 'rtl';
  
  /// TextDirection for Flutter widgets.
  TextDirection get textDirection => isRtl ? TextDirection.rtl : TextDirection.ltr;
}
```

**Creation Flow**:
1. User enters locale code (e.g., "fr_CA" or "fr-CA")
2. System normalizes to underscore format ("fr_CA")
3. System validates against ISO codes
4. User selects direction (LTR default)
5. System creates `CustomLocale` with resolved names

---

### 6. InvalidLocaleCodeException

**Location**: `lib/src/core/localization_exceptions.dart` (extend existing)

**Description**: Exception thrown when a locale code fails validation.

```dart
/// Exception thrown when an invalid locale code is provided.
class InvalidLocaleCodeException extends LocalizationException {
  InvalidLocaleCodeException(
    this.localeCode, {
    required this.errorType,
    String? message,
  }) : super(message ?? _defaultMessage(localeCode, errorType));

  /// The invalid locale code.
  final String localeCode;
  
  /// The type of validation error.
  final LocaleValidationErrorType errorType;
  
  static String _defaultMessage(String code, LocaleValidationErrorType type) {
    switch (type) {
      case LocaleValidationErrorType.invalidFormat:
        return 'Invalid locale format "$code". Use format like "en", "en_US", or "zh_CN".';
      case LocaleValidationErrorType.invalidLanguageCode:
        return 'Invalid language code in "$code". Please use ISO 639-1 or 639-2 codes.';
      case LocaleValidationErrorType.invalidCountryCode:
        return 'Invalid country code in "$code". Please use ISO 3166-1 alpha-2 codes.';
      case LocaleValidationErrorType.duplicateLocale:
        return 'Locale "$code" already exists.';
    }
  }
}
```

---

### 7. CircularFallbackException

**Location**: `lib/src/core/localization_exceptions.dart` (extend existing)

**Description**: Exception thrown when a circular fallback chain is detected.

```dart
/// Exception thrown when configuring a language group fallback would create a cycle.
class CircularFallbackException extends LocalizationException {
  CircularFallbackException(this.locale, this.attemptedFallback)
      : super('Circular fallback detected. Setting "$locale" to fall back to '
            '"$attemptedFallback" would create a cycle.');

  /// The locale being configured.
  final String locale;
  
  /// The attempted fallback that would create a cycle.
  final String attemptedFallback;
}
```

---

## Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            CatalogState                                  │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │ languageGroupFallbacks: {"ar_SA": "ar_EG", "ar_AE": "ar_EG"}     │   │
│  │ customLocaleDirections: {"custom_locale": "rtl"}                  │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ derives
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          LanguageGroup[]                                 │
│  ┌────────────────────────┐  ┌────────────────────────┐                 │
│  │ baseLanguageCode: "ar" │  │ baseLanguageCode: "en" │                 │
│  │ locales: [ar,ar_SA,    │  │ locales: [en,en_US,    │                 │
│  │           ar_EG,ar_AE] │  │           en_GB]       │                 │
│  │ fallbackLocale: ar_EG  │  │ fallbackLocale: null   │                 │
│  └────────────────────────┘  └────────────────────────┘                 │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ computes
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          FallbackChain                                   │
│  targetLocale: "ar_SA"                                                  │
│  chain: ["ar_SA", "ar_EG", "ar", "en"]                                  │
│  displayString: "ar_SA → ar_EG → ar → en"                               │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## State Transitions

### Language Group Fallback Configuration

```
┌─────────────┐     setFallback(ar_SA, ar_EG)     ┌─────────────────────┐
│ No Fallback │ ──────────────────────────────▶   │ ar_SA → ar_EG       │
│ configured  │                                    │ configured          │
└─────────────┘                                    └─────────────────────┘
       │                                                    │
       │ deleteFallback(ar_SA)                              │ changeFallback(ar_SA, ar_LY)
       ◀────────────────────────────────────────────────────┘
                                                            │
                                                            ▼
                                                   ┌─────────────────────┐
                                                   │ ar_SA → ar_LY       │
                                                   │ configured          │
                                                   └─────────────────────┘
```

### Fallback Locale Deletion

```
┌─────────────────────┐     deleteLocale(ar_EG)    ┌─────────────────────┐
│ ar_SA → ar_EG       │ ──────────────────────▶    │ No Fallback         │
│ ar_AE → ar_EG       │     (clears references)    │ (user notified)     │
└─────────────────────┘                            └─────────────────────┘
```

---

## Validation Rules Summary

| Entity | Field | Rule |
|--------|-------|------|
| CatalogState | languageGroupFallbacks keys | Must be valid locale codes in project |
| CatalogState | languageGroupFallbacks values | Must be valid locale codes in project |
| CatalogState | languageGroupFallbacks | No circular references |
| CatalogState | customLocaleDirections values | Must be "ltr" or "rtl" |
| CustomLocale | code | Must match ISO 639-1/639-2 language + optional ISO 3166-1 country |
| CustomLocale | code | Must not be duplicate of existing locale |
| LocaleValidationResult | - | Language code must exist in ISO 639-1 or 639-2 |
| LocaleValidationResult | - | Country code (if present) must exist in ISO 3166-1 alpha-2 |

---

## Migration Notes

### Existing CatalogState Files

- **No migration required**: New fields are optional with defaults
- `languageGroupFallbacks`: Defaults to `{}` if missing
- `customLocaleDirections`: Defaults to `{}` if missing
- Schema version remains `3` (additive change)

### API Compatibility

- `CatalogState.fromJson()`: Updated to parse new fields
- `CatalogState.toJson()`: Includes new fields only if non-empty
- `CatalogState.empty()`: Initializes with empty maps for new fields
