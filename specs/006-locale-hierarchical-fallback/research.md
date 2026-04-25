# Research: Hierarchical Locale Fallback System with Custom Locale Support

**Feature Branch**: `006-locale-hierarchical-fallback`  
**Date**: 2026-03-24

## Research Questions

### 1. ISO Language Code Validation Strategy

**Question**: How should we validate custom locale codes against ISO 639-1/639-2 and ISO 3166-1 standards?

**Decision**: Embed a curated subset of ISO codes as static data

**Rationale**:
- The `intl` package provides locale names via `Intl.canonicalizedLocale()` but doesn't expose validation against ISO standards
- External packages like `iso_codes` add dependencies and may have maintenance issues
- A static list of ~200 language codes and ~250 country codes is small (~10KB) and rarely changes
- Flutter's `Locale` class accepts any string, so validation must be explicit

**Alternatives Considered**:
1. **External package (`iso_codes`)**: Rejected - adds dependency, potential maintenance burden
2. **No validation (accept any string)**: Rejected - spec requires strict validation (FR-006)
3. **API lookup**: Rejected - requires network, not offline-capable
4. **Intl package only**: Rejected - doesn't provide ISO validation, only formatting

**Implementation**:
- Create `lib/src/shared/utils/iso_locale_codes.dart` with curated ISO 639-1/639-2 language codes and ISO 3166-1 alpha-2 country codes
- Include language/country names for display (e.g., `en_US` → "English (United States)")
- Provide `isValidLanguageCode()`, `isValidCountryCode()`, `getLanguageName()`, `getCountryName()` utilities

---

### 2. Language Group Fallback Storage Schema

**Question**: How should language group fallback configuration be stored in `catalog_state.json`?

**Decision**: Store as a flat map in `CatalogState` with bidirectional lookup

**Rationale**:
- Spec FR-003 defines structure: `languageGroupFallbacks: {"ar_SA": "ar_EG", "ar_AE": "ar_EG"}`
- This maps each regional locale to its configured fallback
- Allows quick lookup: "What is ar_SA's fallback?" → `ar_EG`
- Reverse lookup (all locales using ar_EG as fallback) is done via iteration

**Schema**:
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
    "fr_CA": "ltr",
    "custom_dialect": "rtl"
  },
  "keys": { ... }
}
```

**Alternatives Considered**:
1. **Nested structure by language**: `{"ar": {"fallback": "ar_EG", "members": ["ar_SA", "ar_AE"]}}` - Rejected: more complex, requires syncing two sources of truth
2. **Separate config file**: Rejected - violates existing catalog_state.json pattern
3. **Store in anas_catalog.yaml**: Rejected - state vs config separation; fallbacks are runtime state

---

### 3. Circular Fallback Detection Algorithm

**Question**: How should we detect and prevent circular fallback chains?

**Decision**: Graph-based cycle detection during configuration change

**Rationale**:
- Circular chains like `ar_EG → ar_SA → ar_EG` would cause infinite loops
- Detection must happen at configuration time (FR-012), not resolution time
- Simple visited-set algorithm is O(n) where n is number of locales

**Algorithm**:
```dart
bool hasCircularFallback(Map<String, String> fallbacks, String locale, String newFallback) {
  final visited = <String>{locale};
  var current = newFallback;
  while (current != null) {
    if (visited.contains(current)) return true;
    visited.add(current);
    current = fallbacks[current];
  }
  return false;
}
```

**Alternatives Considered**:
1. **Detect at resolution time**: Rejected - allows saving invalid config
2. **Limit chain depth**: Rejected - arbitrary limit, doesn't prevent actual cycles
3. **Block any chain >2**: Rejected - unnecessarily restrictive

---

### 4. Integration with Existing Fallback Chain

**Question**: How should language group fallback integrate with existing `resolveLocaleFallbackChain()`?

**Decision**: Insert language group fallback between exact match and same-language variants

**Rationale**:
- Existing chain: `lang_script_region → lang_script → lang_region → lang → fallback`
- New chain with language group: `exact → language_group_fallback → other_variants → lang → project_default`
- FR-004 specifies: (1) Exact match, (2) Language group fallback, (3) Project default

**Modified Resolution Order**:
1. Exact locale match (`ar_SA`)
2. Language group fallback if configured (`ar_EG`)
3. Other regional variants of same language (existing behavior)
4. Base language (`ar`)
5. Project default fallback (`en`)

**Implementation**:
- Modify `LocalizationService.resolveLocaleFallbackChain()` to accept optional `languageGroupFallbacks` map
- Inject language group fallback after exact match position
- Maintain backward compatibility: empty map = current behavior

---

### 5. UI Component Architecture for Language Group Settings

**Question**: Where should language group fallback configuration UI be placed?

**Decision**: Inline in locale list with expandable language group sections

**Rationale**:
- FR-013 requires visual grouping when 2+ regional variants exist
- FR-014 requires fallback indicator badges
- Users should see grouping without opening a separate settings dialog

**UI Design**:
1. **Locale List View**: Group locales by language when 2+ variants exist
   - Expandable section header: "Arabic (4 locales)" with expansion chevron
   - Within group: Radio/selector for "Language Group Fallback"
   - Badge on fallback locale: "Group Fallback"

2. **Fallback Chain Tooltip**: Hover on any locale shows chain (FR-015)
   - Example: "ar_SA → ar_EG → en (default)"

3. **No separate settings page**: Keep cognitive load low

**Alternatives Considered**:
1. **Dedicated settings page**: Rejected - adds navigation complexity
2. **Context menu only**: Rejected - poor discoverability
3. **Table column**: Rejected - too many columns already

---

### 6. Custom Locale Input Validation UX

**Question**: How should real-time validation feedback be presented?

**Decision**: Inline validation with progressive disclosure

**Rationale**:
- FR-009 requires real-time feedback as users type
- Users should see errors before attempting to submit
- Clear distinction between language code and country code errors

**UI Flow**:
1. Input field with placeholder: "en_US or en"
2. On input change (debounced 300ms):
   - Parse input into language and optional country
   - Validate language against ISO 639-1/639-2
   - Validate country (if present) against ISO 3166-1
   - Show inline error/success indicator
3. Direction toggle (RTL/LTR) below input, LTR default
4. Preview: "English (United States)" when valid
5. Submit button disabled until valid

**Validation States**:
- Empty: No indicator
- Valid language only: Green check, show "English"
- Valid language + country: Green check, show "English (United States)"
- Invalid language: Red X, "Invalid language code 'xyz'"
- Invalid country: Red X, "Invalid country code 'ZZ'"
- Duplicate: Red X, "Locale already exists"

---

### 7. Text Direction Storage and Application

**Question**: How should custom locale RTL/LTR settings be stored and applied?

**Decision**: Store in `customLocaleDirections` map in catalog_state.json

**Rationale**:
- FR-018 specifies storage structure: `customLocaleDirections: {"custom_locale": "rtl"}`
- FR-019 requires direction applied to text input fields
- Predefined locales have known directions; only custom locales need storage

**Implementation**:
1. **Storage**: `CatalogState.customLocaleDirections: Map<String, String>`
2. **Lookup**: Check `customLocaleDirections` first, then `_catalogRtlLanguageCodes`
3. **UI Application**: `TextDirection` set on text input widgets based on locale
4. **Default**: LTR when not specified (FR-007)

**Existing Code Reference**:
- `_catalogRtlLanguageCodes` in `catalog_service.dart` lists known RTL languages
- `CatalogMeta.localeDirections` already exists for this purpose

---

### 8. Backward Compatibility Strategy

**Question**: How do we ensure existing projects work without migration?

**Decision**: Optional fields with defaults in JSON parsing

**Rationale**:
- FR-020 requires backward compatibility
- Existing `catalog_state.json` files lack new fields
- JSON parsing must handle missing fields gracefully

**Implementation**:
1. `languageGroupFallbacks`: Default to empty map `{}` if missing
2. `customLocaleDirections`: Default to empty map `{}` if missing
3. No schema version bump required (fields are additive)
4. Add fields only when user configures them (avoid file bloat)

**Test Cases**:
- Load v3 state file without new fields → works normally
- Save state with new fields → includes them
- Load state with new fields → uses them

---

## Technology Choices

### Curated ISO Code Data

**Source**: Unicode CLDR (Common Locale Data Repository)

**Scope**:
- ISO 639-1: All 184 two-letter language codes
- ISO 639-2: Common three-letter codes used in localization (~50 most common)
- ISO 3166-1 alpha-2: All 249 country codes

**Maintenance**: Static data; update annually or as needed

### Graph Algorithm for Cycle Detection

**Approach**: Iterative visited-set traversal
**Complexity**: O(n) where n = number of locales
**Memory**: O(n) for visited set

### UI State Management

**Approach**: Extend existing `CatalogWorkspaceController`
**Pattern**: Follows existing catalog UI patterns with optimistic updates

---

## Best Practices Applied

### From Flutter Internationalization Skill

1. **Locale code normalization**: Convert hyphens to underscores, standardize case
2. **Directional widgets**: Use `TextDirection.ltr`/`.rtl` for input fields
3. **Display names**: Show "English (United States)" not just "en_US"

### From Constitution

1. **Typed exceptions**: `InvalidLocaleCodeException` for validation errors
2. **Deterministic behavior**: Document exact fallback resolution order
3. **Test coverage**: Unit tests for validation, integration tests for fallback chains

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| ISO code data outdated | Low | Low | Annual review; rare locale additions |
| Circular fallback edge cases | Low | High | Comprehensive cycle detection tests |
| UI complexity for language groups | Medium | Medium | Progressive disclosure; hide until 2+ variants |
| Performance with many locales | Low | Low | Simple map lookups; O(1) access |

---

## Dependencies

### New Files to Create

1. `lib/src/shared/utils/iso_locale_codes.dart` - ISO code validation data
2. `lib/src/features/catalog/domain/services/locale_validation_service.dart` - Validation logic
3. `lib/src/features/catalog/presentation/screens/catalog_locale_settings.dart` - Fallback config UI

### Files to Modify

1. `lib/src/features/catalog/domain/entities/catalog_models.dart` - Add CatalogState fields
2. `lib/src/features/localization/data/repositories/localization_service.dart` - Extend fallback chain
3. `lib/src/features/catalog/use_cases/catalog_service.dart` - Language group management methods
4. `lib/src/features/catalog/presentation/screens/catalog_label_helpers.dart` - Custom locale dialog
5. `lib/src/core/localization_exceptions.dart` - Add InvalidLocaleCodeException

---

## Summary

All research questions have been resolved:

1. **ISO Validation**: Embedded static data (~460 codes, ~10KB)
2. **Storage Schema**: Flat maps in `catalog_state.json`
3. **Cycle Detection**: Graph traversal with visited set
4. **Fallback Integration**: Insert after exact match in existing chain
5. **UI Architecture**: Inline in locale list with expandable groups
6. **Validation UX**: Real-time inline feedback with debouncing
7. **Direction Storage**: `customLocaleDirections` map
8. **Backward Compatibility**: Optional fields with defaults
