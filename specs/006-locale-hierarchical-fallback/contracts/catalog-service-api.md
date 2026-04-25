# Catalog Service API Contract

**Feature Branch**: `006-locale-hierarchical-fallback`  
**Date**: 2026-03-24  
**Service**: `CatalogService`

## Overview

Extensions to the Catalog Service API for managing language group fallbacks and custom locales. These methods integrate with the existing HTTP API served by `CatalogBackend`.

---

## Endpoints

### 1. Get Language Groups

Retrieves all language groups with their configured fallbacks.

**HTTP**: `GET /api/language-groups`

**Request**: None

**Response**:
```json
{
  "groups": [
    {
      "baseLanguageCode": "ar",
      "locales": ["ar", "ar_SA", "ar_EG", "ar_AE"],
      "fallbackLocale": "ar_EG",
      "canConfigureFallback": true,
      "displayName": "Arabic (4 locales)"
    },
    {
      "baseLanguageCode": "en",
      "locales": ["en", "en_US", "en_GB"],
      "fallbackLocale": null,
      "canConfigureFallback": true,
      "displayName": "English (3 locales)"
    }
  ]
}
```

**Status Codes**:
- `200 OK`: Success
- `500 Internal Server Error`: Service error

---

### 2. Set Language Group Fallback

Configures a language group fallback for a regional locale.

**HTTP**: `POST /api/language-group-fallback`

**Request**:
```json
{
  "locale": "ar_SA",
  "fallbackLocale": "ar_EG"
}
```

**Response (Success)**:
```json
{
  "success": true,
  "locale": "ar_SA",
  "fallbackLocale": "ar_EG",
  "fallbackChain": ["ar_SA", "ar_EG", "ar", "en"]
}
```

**Response (Error - Circular)**:
```json
{
  "success": false,
  "error": "circular_fallback",
  "message": "Circular fallback detected. Setting 'ar_SA' to fall back to 'ar_EG' would create a cycle."
}
```

**Response (Error - Invalid Locale)**:
```json
{
  "success": false,
  "error": "invalid_locale",
  "message": "Locale 'ar_XY' does not exist in the project."
}
```

**Validation Rules**:
- `locale` must exist in project locales
- `fallbackLocale` must exist in project locales
- `locale` and `fallbackLocale` must share same base language code
- Must not create circular fallback chain
- Cannot set regional variant as fallback for base language (FR-010)

**Status Codes**:
- `200 OK`: Success
- `400 Bad Request`: Validation error
- `500 Internal Server Error`: Service error

---

### 3. Remove Language Group Fallback

Removes a language group fallback configuration.

**HTTP**: `DELETE /api/language-group-fallback`

**Request**:
```json
{
  "locale": "ar_SA"
}
```

**Response**:
```json
{
  "success": true,
  "locale": "ar_SA",
  "fallbackChain": ["ar_SA", "ar", "en"]
}
```

**Status Codes**:
- `200 OK`: Success
- `400 Bad Request`: Locale not found
- `500 Internal Server Error`: Service error

---

### 4. Get Fallback Chain

Retrieves the complete fallback chain for a locale.

**HTTP**: `GET /api/fallback-chain/{locale}`

**Response**:
```json
{
  "targetLocale": "ar_SA",
  "chain": ["ar_SA", "ar_EG", "ar", "en"],
  "projectDefaultLocale": "en",
  "hasLanguageGroupFallback": true,
  "displayString": "ar_SA → ar_EG → ar → en"
}
```

**Status Codes**:
- `200 OK`: Success
- `404 Not Found`: Locale not found
- `500 Internal Server Error`: Service error

---

### 5. Validate Locale Code

Validates a locale code against ISO standards.

**HTTP**: `POST /api/validate-locale`

**Request**:
```json
{
  "code": "fr_CA"
}
```

**Response (Valid)**:
```json
{
  "isValid": true,
  "languageCode": "fr",
  "countryCode": "CA",
  "languageName": "French",
  "countryName": "Canada",
  "displayName": "French (Canada)",
  "errorMessage": null,
  "errorType": null
}
```

**Response (Invalid Language)**:
```json
{
  "isValid": false,
  "languageCode": null,
  "countryCode": null,
  "languageName": null,
  "countryName": null,
  "displayName": null,
  "errorMessage": "Invalid language code 'xyz'. Please use ISO 639-1 or 639-2 language codes.",
  "errorType": "invalidLanguageCode"
}
```

**Response (Invalid Country)**:
```json
{
  "isValid": false,
  "languageCode": "en",
  "countryCode": null,
  "languageName": "English",
  "countryName": null,
  "displayName": null,
  "errorMessage": "Invalid country code 'ZZ'. Please use ISO 3166-1 alpha-2 country codes.",
  "errorType": "invalidCountryCode"
}
```

**Response (Duplicate)**:
```json
{
  "isValid": false,
  "languageCode": "en",
  "countryCode": "US",
  "languageName": "English",
  "countryName": "United States",
  "displayName": "English (United States)",
  "errorMessage": "Locale 'en_US' already exists.",
  "errorType": "duplicateLocale"
}
```

**Status Codes**:
- `200 OK`: Always (validation result in body)
- `500 Internal Server Error`: Service error

---

### 6. Add Custom Locale

Creates a new locale with custom text direction.

**HTTP**: `POST /api/locale`

**Request**:
```json
{
  "code": "fr_CA",
  "direction": "ltr"
}
```

**Response (Success)**:
```json
{
  "success": true,
  "locale": {
    "code": "fr_CA",
    "direction": "ltr",
    "displayName": "French (Canada)",
    "languageName": "French",
    "countryName": "Canada",
    "isCustom": true
  }
}
```

**Response (Error)**:
```json
{
  "success": false,
  "error": "invalid_locale_code",
  "message": "Invalid language code 'xyz'. Please use ISO 639-1 or 639-2 language codes."
}
```

**Validation Rules**:
- Code must pass ISO validation (FR-006)
- Code must not already exist (FR-005)
- Direction must be "ltr" or "rtl" (FR-007)
- Code is normalized (hyphens → underscores) (FR-008)

**Status Codes**:
- `201 Created`: Success
- `400 Bad Request`: Validation error
- `409 Conflict`: Locale already exists
- `500 Internal Server Error`: Service error

---

## Dart Service Interface

```dart
/// Extensions to CatalogService for language group fallback management.
abstract class ILanguageGroupFallbackService {
  /// Returns all language groups derived from current locales.
  Future<List<LanguageGroup>> getLanguageGroups();
  
  /// Sets a language group fallback for a regional locale.
  /// Throws [CircularFallbackException] if this would create a cycle.
  /// Throws [CatalogOperationException] if locales are invalid.
  Future<FallbackChain> setLanguageGroupFallback({
    required String locale,
    required String fallbackLocale,
  });
  
  /// Removes a language group fallback configuration.
  Future<FallbackChain> removeLanguageGroupFallback(String locale);
  
  /// Returns the complete fallback chain for a locale.
  Future<FallbackChain> getFallbackChain(String locale);
}

/// Extensions to CatalogService for custom locale management.
abstract class ICustomLocaleService {
  /// Validates a locale code against ISO standards.
  LocaleValidationResult validateLocaleCode(String code);
  
  /// Adds a custom locale with specified text direction.
  /// Throws [InvalidLocaleCodeException] if validation fails.
  /// Throws [CatalogOperationException] if locale already exists.
  Future<CustomLocale> addCustomLocale({
    required String code,
    required String direction,
  });
  
  /// Returns text direction for a locale.
  /// Checks customLocaleDirections first, then predefined list.
  String getLocaleDirection(String locale);
}
```

---

## Error Types

| Error Type | HTTP Status | When |
|------------|-------------|------|
| `invalid_locale` | 400 | Locale not in project |
| `invalid_locale_code` | 400 | Fails ISO validation |
| `circular_fallback` | 400 | Would create cycle |
| `duplicate_locale` | 409 | Locale already exists |
| `invalid_direction` | 400 | Direction not ltr/rtl |
| `invalid_base_fallback` | 400 | Regional set as base fallback |
| `internal_error` | 500 | Unexpected server error |

---

## Backward Compatibility

### Existing Endpoints

All existing catalog endpoints continue to work unchanged:
- `GET /api/meta` - Returns locales (unchanged)
- `POST /api/locale` - Extended with `direction` field
- `DELETE /api/locale` - Clears fallback references when deleting fallback locale

### Fallback Cleanup on Locale Deletion

When a locale that is a language group fallback is deleted:
1. All references to it in `languageGroupFallbacks` are removed
2. A notification is included in the response:

```json
{
  "success": true,
  "locale": "ar_EG",
  "affectedFallbacks": ["ar_SA", "ar_AE"],
  "message": "Deleted locale 'ar_EG' was the language group fallback for Arabic. Other Arabic locales now fall back directly to the default locale."
}
```
