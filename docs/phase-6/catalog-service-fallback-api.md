# Phase 6 Catalog Service Fallback API Contract

**Issue #128**: Documentation improvements - API clarity and specification coverage

This document defines the contract for all fallback configuration methods in `CatalogService`.

## Methods

### `setLanguageGroupFallback(String locale, String newFallback)`

**Purpose**: Configure a language group fallback from one locale to another.

**Requirement References**:
- FR-010: "Language group fallbacks must respect directionality rules"
- FR-006: "Language group fallback storage and retrieval"
- FR-012: "Circular fallback prevention"

**Constraints** (FR-010 Directionality):
- **Regional → Regional**: ✅ ALLOWED
  - Example: `ar_SA → ar_EG` (both regional variants)
  - Example: `en_GB → en_US`
  
- **Regional → Base**: ✅ ALLOWED
  - Example: `ar_SA → ar` (regional to base language)
  - Example: `en_GB → en`

- **Base → Base**: ✅ ALLOWED
  - Example: `en → es` (base to base language)
  - Example: `ar → pt`

- **Base → Regional**: ❌ NOT ALLOWED
  - Example: `en → ar_SA` throws exception (FR-010)
  - Example: `ar → ar_EG` throws exception

**Circular Detection** (FR-012):
- Self-references are rejected: `en → en`
- Circular chains are rejected: `en → es → en`
- Existing chains are considered: If `en → es` exists, setting `es → en` is rejected

**Parameters**:
- `locale` (String): Source locale. Must exist in `supportedLocales` (FR-005)
- `newFallback` (String): Target locale. Must exist in `supportedLocales` (FR-005, Issue #124)

**Returns**: `Future<void>` - Completes when configuration is persisted

**Throws**:
- `LocalizationException` if source or target locale doesn't exist (FR-005, Issue #124)
- `CatalogOperationException` if violates FR-010 directionality rules (Issue #123)
- `CatalogOperationException` if would create circular chain (FR-012)

**Example**:
```dart
final service = CatalogService(...);

// ✅ Regional to base (ALLOWED)
await service.setLanguageGroupFallback('ar_SA', 'ar');

// ✅ Base to base (ALLOWED)
await service.setLanguageGroupFallback('en', 'es');

// ❌ Base to regional (NOT ALLOWED - Issue #123)
await service.setLanguageGroupFallback('en', 'ar_SA'); // throws CatalogOperationException

// ❌ Self-reference (NOT ALLOWED - Issue #127)
await service.setLanguageGroupFallback('en', 'en'); // throws CatalogOperationException

// ❌ Non-existent target (NOT ALLOWED - Issue #124)
await service.setLanguageGroupFallback('ar_SA', 'nonexistent'); // throws LocalizationException
```

---

### `removeLanguageGroupFallback(String locale)`

**Purpose**: Remove a configured language group fallback for a locale.

**Parameters**:
- `locale` (String): The source locale to remove fallback from

**Returns**: `Future<void>` - Completes when change is persisted

**Behavior**:
- Idempotent: Removing a non-existent fallback is a no-op (no error)
- Only affects the specified locale
- Other fallbacks remain unchanged

**Example**:
```dart
// Remove fallback ar_SA → ar
await service.removeLanguageGroupFallback('ar_SA');

// Removing non-existent fallback: no error
await service.removeLanguageGroupFallback('en_GB'); // OK even if no fallback exists
```

---

### `getFallbackChain(String locale) → Future<FallbackChain>`

**Purpose**: Get the **configured** fallback chain for a locale.

**Important Note**: 
- This returns the **configuration-time view** (what user configured)
- For **runtime resolution** with variant expansion and default locale, see `LocalizationService.resolveLocaleFallbackChain()`
- See ADR-001 for explanation of dual paths

**Parameters**:
- `locale` (String): Target locale

**Returns**: `FallbackChain` entity with:
- `targetLocale`: The requested locale
- `chain`: List of locales in fallback order
- `projectDefaultLocale`: The project's default locale

**Example**:
```dart
// If configured: ar_SA → ar → default is en
final chain = await service.getFallbackChain('ar_SA');
// Returns: FallbackChain(
//   targetLocale: 'ar_SA',
//   chain: ['ar_SA', 'ar'],  // Note: doesn't include 'en' (that's runtime)
//   projectDefaultLocale: 'en'
// )
```

---

### `getLanguageGroupFallbacks() → Future<Map<String, String>>`

**Purpose**: Get all configured language group fallbacks as a map.

**Returns**: `Future<Map<String, String>>` where:
- Key: Source locale
- Value: Target locale

**Example**:
```dart
final fallbacks = await service.getLanguageGroupFallbacks();
// Returns: {
//   'ar_SA': 'ar',
//   'ar_EG': 'ar',
//   'en_GB': 'en',
// }
```

---

### `deleteLocale(String locale) → Future<void>`

**Purpose**: Delete a locale and handle cascade cleanup.

**Cascade Behavior** (Issue #127, FR-011):
When deleting a locale that is configured as a fallback target:
1. ✅ Auto-remove all fallback references pointing to it
2. ✅ Notify affected source locales (Issue #131)
3. ✅ Persist changes

**Example Scenario**:
```dart
// Setup: ar_SA → ar_EG, ar_west → ar_EG
await service.setLanguageGroupFallback('ar_SA', 'ar_EG');
await service.setLanguageGroupFallback('ar_west', 'ar_EG');

// Delete ar_EG
await service.deleteLocale('ar_EG');
// Result:
// - ar_EG locale deleted
// - ar_SA → ar_EG fallback auto-removed
// - ar_west → ar_EG fallback auto-removed
// - FallbackCascadeNotification emitted with affected: ['ar_SA', 'ar_west']
```

**Parameters**:
- `locale` (String): The locale to delete

**Throws**:
- `CatalogOperationException` if trying to delete the default locale
- `CatalogOperationException` if locale doesn't exist

**Related Issues**:
- Issue #127: Cascade delete implementation
- Issue #131: Cascade delete notifications

---

## Requirement Coverage Summary

| Requirement | Method | Implementation | Tests |
|-------------|--------|-----------------|-------|
| FR-005 | setLanguageGroupFallback | Validates existence (Issue #124) | ✅ |
| FR-006 | getLanguageGroupFallbacks | Full map retrieval | ✅ |
| FR-010 | setLanguageGroupFallback | Directionality validation (Issue #123) | ✅ 3 tests |
| FR-011 | deleteLocale | Cascade delete + notifications (Issues #127, #131) | ✅ |
| FR-012 | setLanguageGroupFallback | Circular detection | ✅ |

---

## Architecture Notes

### Configuration vs Runtime

- **CatalogService.getFallbackChain()**: Shows what user configured (simple DAG traversal)
- **LocalizationService.resolveLocaleFallbackChain()**: Shows runtime resolution (includes variants + default)

See [ADR-001: Dual Fallback Resolution Paths](./adr-001-dual-fallback-resolution.md) for rationale.

### Issue #126: Unified Resolution

Both services now use shared `FallbackResolver` utilities:
- `resolveConfiguredChain()`: DAG traversal (used by CatalogService)
- `expandWithVariants()`: Variant handling (used by LocalizationService)
- `resolveWithDefaults()`: Default appending (used by LocalizationService)

This eliminates duplication while keeping concerns separate.

---

## Error Handling

All methods follow consistent error patterns:

```dart
try {
  await service.setLanguageGroupFallback('ar_SA', 'ar');
} on LocalizationException {
  // Locale doesn't exist (FR-005, Issue #124)
} on CatalogOperationException catch (e) {
  if (e.message.contains('directionality')) {
    // FR-010 violation (Issue #123)
  } else if (e.message.contains('circular')) {
    // FR-012 violation
  }
}
```

---

## Testing Strategy

All methods have:
- ✅ Unit tests for happy path
- ✅ Unit tests for constraint validation
- ✅ Unit tests for error cases
- ✅ Integration tests for E2E flows

Test files:
- `test/locale_fallback_config_test.dart` - Main configuration tests
- `test/fallback_resolver_test.dart` - Unified resolver tests
- `test/fallback_cascade_notification_test.dart` - Notification tests

