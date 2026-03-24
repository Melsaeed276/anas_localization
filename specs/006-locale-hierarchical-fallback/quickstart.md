# Quickstart: Hierarchical Locale Fallback System

**Feature Branch**: `006-locale-hierarchical-fallback`  
**Date**: 2026-03-24  
**Estimated Implementation Time**: 3-4 days

## Overview

This feature adds:
1. **Language Group Fallbacks**: Configure regional variants to fall back to specific locales within the same language (e.g., `ar_SA` → `ar_EG` → `ar` → default)
2. **Custom Locale Creation**: Add locales not in the predefined list with manual RTL/LTR selection
3. **ISO Validation**: Validate locale codes against ISO 639-1/639-2 and ISO 3166-1 standards

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                          │
├─────────────────────────────────────────────────────────────────┤
│  showAddLocaleDialog()     │  CatalogLocaleSettings (new)       │
│  - Add "Custom Code" tab   │  - Language group list              │
│  - RTL/LTR toggle          │  - Fallback chain visualization     │
│  - Real-time validation    │  - Configure fallback button        │
└──────────────────┬──────────┴──────────────────┬────────────────┘
                   │                              │
┌──────────────────▼──────────────────────────────▼────────────────┐
│                       USE CASE LAYER                             │
├──────────────────────────────────────────────────────────────────┤
│  CatalogService (extended)                                       │
│  - addCustomLocale()       - setLanguageGroupFallback()          │
│  - getLanguageGroups()     - removeLanguageGroupFallback()       │
│  - getFallbackChain()      - getLocaleDirection()                │
└──────────────────┬───────────────────────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────────────────────┐
│                       DOMAIN LAYER                               │
├──────────────────────────────────────────────────────────────────┤
│  LocaleValidationService (new)   │  Entities (extended)          │
│  - validateLocaleCode()          │  - CatalogState (add maps)    │
│  - isValidLanguageCode()         │  - LanguageGroup              │
│  - isValidCountryCode()          │  - FallbackChain              │
│  - ISO data constants            │  - CustomLocale               │
│                                  │  - LocaleValidationResult     │
└──────────────────┬───────────────┴───────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────────────────────┐
│                        DATA LAYER                                │
├──────────────────────────────────────────────────────────────────┤
│  CatalogStateStore (extended)    │  LocalizationService (ext)    │
│  - Load/save languageGroupFallbacks │  - resolveLocaleFallbackChain │
│  - Load/save customLocaleDirections │    (respects group fallbacks) │
└──────────────────────────────────────────────────────────────────┘
```

---

## Key Implementation Points

### 1. CatalogState Extension

Add two new maps to `CatalogState` (backward-compatible defaults):

```dart
// In catalog_models.dart
class CatalogState {
  // ... existing fields ...
  
  /// Language group fallbacks: sourceLocale → targetLocale (same language)
  /// Example: {"ar_SA": "ar_EG", "ar_AE": "ar_EG"}
  final Map<String, String> languageGroupFallbacks;
  
  /// Custom locale text directions: locale → "ltr" | "rtl"
  /// Only for locales not in predefined kAvailableLocales
  final Map<String, String> customLocaleDirections;
  
  CatalogState({
    // ... existing params ...
    this.languageGroupFallbacks = const {},
    this.customLocaleDirections = const {},
  });
}
```

### 2. Fallback Chain Resolution

Extend `LocalizationService.resolveLocaleFallbackChain()`:

```dart
// In localization_service.dart
List<String> resolveLocaleFallbackChain(
  String targetLocale,
  List<String> projectLocales,
  String defaultLocale,
  Map<String, String> languageGroupFallbacks, // NEW parameter
) {
  final chain = <String>[];
  final visited = <String>{};
  
  void addToChain(String locale) {
    if (!visited.add(locale)) return; // Prevent cycles
    if (projectLocales.contains(locale)) {
      chain.add(locale);
    }
  }
  
  // 1. Exact match
  addToChain(targetLocale);
  
  // 2. Language group fallback (NEW)
  final groupFallback = languageGroupFallbacks[targetLocale];
  if (groupFallback != null) {
    addToChain(groupFallback);
  }
  
  // 3. Base language (strip region)
  final baseLanguage = targetLocale.split('_').first;
  if (baseLanguage != targetLocale) {
    addToChain(baseLanguage);
  }
  
  // 4. Default locale
  addToChain(defaultLocale);
  
  return chain;
}
```

### 3. ISO Validation Service

Create new service for locale code validation:

```dart
// In locale_validation_service.dart
class LocaleValidationService {
  LocaleValidationResult validateLocaleCode(
    String code, {
    required Set<String> existingLocales,
  }) {
    final normalized = code.replaceAll('-', '_').toLowerCase();
    final parts = normalized.split('_');
    
    // Check language code (ISO 639-1/639-2)
    final languageCode = parts[0];
    if (!_isValidLanguageCode(languageCode)) {
      return LocaleValidationResult.invalidLanguage(languageCode);
    }
    
    // Check country code if present (ISO 3166-1 alpha-2)
    if (parts.length > 1) {
      final countryCode = parts[1].toUpperCase();
      if (!_isValidCountryCode(countryCode)) {
        return LocaleValidationResult.invalidCountry(countryCode);
      }
    }
    
    // Check for duplicates
    if (existingLocales.contains(normalized)) {
      return LocaleValidationResult.duplicate(normalized);
    }
    
    return LocaleValidationResult.valid(
      languageCode: parts[0],
      countryCode: parts.length > 1 ? parts[1].toUpperCase() : null,
    );
  }
}
```

### 4. Add Locale Dialog Extension

Add a "Custom" tab to `showAddLocaleDialog()`:

```dart
// In catalog_label_helpers.dart
Widget _buildCustomLocaleTab() {
  return Column(
    children: [
      TextField(
        decoration: InputDecoration(
          labelText: 'Locale Code',
          hintText: 'e.g., fr_CA or ar_EG',
          errorText: _validationError,
        ),
        onChanged: _validateInRealTime,
      ),
      const SizedBox(height: 16),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'ltr', label: Text('LTR')),
          ButtonSegment(value: 'rtl', label: Text('RTL')),
        ],
        selected: {_selectedDirection},
        onSelectionChanged: (selected) {
          setState(() => _selectedDirection = selected.first);
        },
      ),
      if (_validationResult?.isValid == true) ...[
        const SizedBox(height: 16),
        Text('Will create: ${_validationResult!.displayName}'),
      ],
    ],
  );
}
```

---

## Critical Validation Rules

### Circular Fallback Detection

Before setting a language group fallback, detect cycles:

```dart
bool wouldCreateCycle(
  String source,
  String target,
  Map<String, String> existingFallbacks,
) {
  final visited = <String>{source};
  var current = target;
  
  while (existingFallbacks.containsKey(current)) {
    if (visited.contains(current)) return true;
    visited.add(current);
    current = existingFallbacks[current]!;
  }
  
  return visited.contains(current);
}
```

### Same Language Group Constraint

Only allow fallbacks within the same language:

```dart
bool isSameLanguageGroup(String locale1, String locale2) {
  return locale1.split('_').first == locale2.split('_').first;
}
```

---

## File Changes Summary

| File | Change Type | Description |
|------|-------------|-------------|
| `catalog_models.dart` | EXTEND | Add `languageGroupFallbacks`, `customLocaleDirections` to CatalogState |
| `catalog_state_store.dart` | EXTEND | Load/save new CatalogState fields |
| `localization_service.dart` | EXTEND | Update `resolveLocaleFallbackChain()` signature |
| `catalog_service.dart` | EXTEND | Add fallback management methods |
| `catalog_label_helpers.dart` | EXTEND | Add custom locale tab to dialog |
| `locale_validation_service.dart` | NEW | ISO code validation |
| `iso_locale_codes.dart` | NEW | ISO 639-1/639-2 and ISO 3166-1 data |
| `localization_exceptions.dart` | EXTEND | Add `InvalidLocaleCodeException`, `CircularFallbackException` |
| `catalog_locale_settings.dart` | NEW | Language group fallback UI screen |

---

## Test Priorities

### Unit Tests (High Priority)

1. **Fallback Chain Resolution**
   - Standard chain: `ar_SA` → `ar` → `en`
   - With group fallback: `ar_SA` → `ar_EG` → `ar` → `en`
   - Cycle prevention (should never happen)

2. **ISO Validation**
   - Valid codes: `en`, `en_US`, `fr_CA`
   - Invalid language: `xyz`, `123`
   - Invalid country: `en_ZZ`, `fr_123`
   - Normalization: `en-US` → `en_US`

3. **Circular Detection**
   - Direct: A → A
   - Indirect: A → B → A
   - Transitive: A → B → C → A

### Widget Tests (Medium Priority)

1. **Add Locale Dialog**
   - Custom tab visibility
   - RTL/LTR toggle
   - Real-time validation feedback
   - Successful creation

2. **Language Group Settings**
   - Group list display
   - Fallback configuration
   - Chain visualization

### Integration Tests (Lower Priority)

1. **End-to-End Flow**
   - Add custom locale
   - Configure language group fallback
   - Verify translation resolution uses new chain

---

## Backward Compatibility

### Migration Strategy

No migration needed. The new fields default to empty maps:

```dart
CatalogState({
  this.languageGroupFallbacks = const {},  // Empty = no change to existing behavior
  this.customLocaleDirections = const {},  // Empty = use predefined directions
});
```

### Existing catalog_state.json Files

Files without the new fields will deserialize with defaults:

```json
// Old file (still works)
{
  "meta": { ... },
  "labels": { ... }
}

// New file (adds optional fields)
{
  "meta": { ... },
  "labels": { ... },
  "languageGroupFallbacks": { "ar_SA": "ar_EG" },
  "customLocaleDirections": { "custom_LC": "ltr" }
}
```

---

## Dependencies

No new package dependencies required. Uses:
- `intl` (existing) - Locale utilities
- `flutter_localizations` (existing) - Flutter localization support

The ISO code data will be embedded as Dart constants (no external data files).

---

## Risk Areas

| Risk | Mitigation |
|------|------------|
| Large ISO data file | Use code generation or lazy loading if bundle size is a concern |
| Circular fallback creation | Validate before save; unit test edge cases |
| Direction override conflicts | Custom direction takes precedence; log warning if overriding known direction |
| Performance with many locales | Cache computed fallback chains; benchmark with 100+ locales |

---

## Next Steps

1. **Phase 2**: Create detailed `tasks.md` with implementation tickets
2. **Implementation Order**:
   - Domain: Entities, validation service, exceptions
   - Data: State store extension, localization service extension
   - Use Case: CatalogService methods
   - Presentation: Dialog extension, settings screen
   - Tests: Unit → Widget → Integration
