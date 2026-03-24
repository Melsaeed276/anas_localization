# ADR-001: Why Two Fallback Resolution Paths?

**Issue #126**: Fallback resolution logic duplication - Inconsistent behavior

**Date**: 2026-03-24  
**Status**: Accepted  
**Affected Components**: CatalogService, LocalizationService

---

## Context

The `anas_localization` package has two separate implementations of fallback chain resolution:

### 1. CatalogService.getFallbackChain() (Configuration Time)

**Location**: `lib/src/features/catalog/use_cases/catalog_service.dart:768`

**Algorithm**: Simple DAG traversal
```dart
// If configured: ar_SA → ar → (nothing)
// Returns: ['ar_SA', 'ar']
List<String> resolveConfiguredChain(Map<String, String> fallbacks, String locale) {
  final chain = [locale];
  var current = fallbacks[locale];
  while (current != null) {
    chain.add(current);
    current = fallbacks[current];
  }
  return chain;
}
```

**Used by**:
- UI fallback selector (shows configured chain)
- REST API (returns configured chain)
- Configuration validation (checks chain validity)

### 2. LocalizationService.resolveLocaleFallbackChain() (Runtime)

**Location**: `lib/src/features/localization/data/repositories/localization_service.dart:214`

**Algorithm**: Complex with variants and defaults
```dart
// If configured: ar_SA → ar, default: en, files: ar_SA.txt, ar.json, en.json
// Returns: ['ar_SA', 'ar_SA.*variants', 'ar', 'en']
List<String> resolveLocaleFallbackChain(String locale) {
  // (1) Requested locale
  // (2) Any supported variants of requested (ar_SA.txt, ar_SA.json)
  // (3) Configured fallback (ar_SA → ar)
  // (4) Any supported variants of fallback (ar.json, ar.txt)
  // (5) Language-only (ar)
  // (6) Default locale (en)
}
```

**Used by**:
- Dictionary loading (tries each candidate)
- Runtime locale resolution (finds best match)
- String/plural lookups (uses resolution path)

---

## Problem

### Risk: Divergence

If these two implementations drift, the UI and API might show a different chain than what runtime actually uses, causing confusion and bugs.

**Example Scenario**:
1. User configures: `ar_SA → ar`
2. UI shows: Chain = `[ar_SA, ar, en]`
3. Runtime tries: `[ar_SA, ar_SA.txt, ar_SA.json, ar, ar.txt, ar.json, en]`
4. User expects behavior from (2) but gets behavior from (3)

### Burden: Maintenance

Changes to one path might not be reflected in the other:
- Bug fix in CatalogService might not apply to LocalizationService
- New constraint validation might be missed in runtime path
- Testing both paths is tedious

### Root Cause

Phase 6 added CatalogService as the configuration layer, but LocalizationService predates it with its own resolution logic. No unified approach was established.

---

## Decision

**Keep both paths with clear separation of concerns and unified base logic.**

### Why Not Merge Them?

**Option A: Single Method** (rejected)
- ❌ Runtime needs variant expansion
- ❌ Configuration needs only configured chain
- ❌ Different use cases → different concerns
- ❌ Would force LocalizationService to know about CatalogService

**Option B: Single Unified Implementation** (rejected)
- ❌ Same as Option A, just refactored differently
- ❌ Runtime resolution is complex, configuration is simple

**Option C: Dual Paths with Shared Base** ✅ (chosen)
- ✅ Clear separation: configuration vs runtime
- ✅ Shared base logic eliminates duplication
- ✅ Each path optimized for its use case
- ✅ LocalizationService can delegate to CatalogService for configured chain

---

## Solution: Unified Base Logic

### Issue #126 Implementation

Created `FallbackResolver` service with shared utilities:

```dart
// Configuration: Simple DAG traversal
List<String> resolveConfiguredChain(
  Map<String, String> fallbacks,
  String locale,
) { ... }

// Runtime helpers
List<String> expandWithVariants(String locale) { ... }
List<String> resolveWithDefaults(List<String> chain, String defaultLocale) { ... }
```

### Two Layers

```
┌─────────────────────────────────────────────────────────────┐
│ Configuration Time (CatalogService)                         │
│                                                              │
│ getFallbackChain(locale)                                    │
│ └─> resolveConfiguredChain(fallbacks, locale)              │
│     └─> Follow DAG: [ar_SA, ar]                             │
│         (optionally append default for display)             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Runtime (LocalizationService)                               │
│                                                              │
│ resolveLocaleFallbackChain(locale)                          │
│ ├─> Get configured: resolveConfiguredChain(...)            │
│ ├─> For each locale, expand variants: expandWithVariants() │
│ └─> Append default: resolveWithDefaults(...)               │
│     └─> Result: [ar_SA, ar, en] + variants from files      │
└─────────────────────────────────────────────────────────────┘
```

### Benefits

1. **Single source of truth**: DAG stored in CatalogService
2. **Clear extension points**: Variants and defaults are added in runtime layer
3. **Easy maintenance**: Shared base logic in FallbackResolver
4. **Testable**: Each layer can be tested independently
5. **Documented**: Clear ADR explaining the split

---

## Consequences

### Positive

- ✅ Eliminates code duplication
- ✅ Easier to maintain: change DAG traversal once, it applies everywhere
- ✅ Clearer intent: Users understand configuration vs runtime
- ✅ Prevents divergence: Shared base makes drift obvious
- ✅ Better testability: 21 tests for FallbackResolver

### Negative

- ⚠️ Two methods to understand (but with clear separation)
- ⚠️ LocalizationService depends on CatalogService API (acceptable design)

---

## Validation

### Requirements Met

| FR | Requirement | Implementation | Status |
|----|----|----|----|
| FR-003 | Language group fallback | Shared resolver | ✅ |
| FR-004 | Fallback chain resolution | Two-layer approach | ✅ |
| FR-010 | Directionality validation | CatalogService | ✅ |
| FR-012 | Circular prevention | resolveConfiguredChain | ✅ |
| FR-013 | Variant support | expandWithVariants | ✅ |

### Tests

- 21 unit tests for FallbackResolver (Issue #126)
- Existing CatalogService tests still pass
- Existing LocalizationService tests still pass
- Integration tests validate end-to-end behavior

---

## Related Decisions

- **Issue #123**: FR-010 directionality validation (configuration time)
- **Issue #124**: Target existence validation (configuration time)
- **Issue #125**: UI filtering based on FR-010 (configuration time)
- **Issue #127**: Cascade delete on target deletion (configuration time)
- **Issue #131**: Cascade delete notifications (configuration time)

---

## How to Explain to Users

### "Why Are There Two Chains?"

**Configuration Time**: "What did you explicitly configure?"
```
ar_SA → ar
Returns: [ar_SA, ar]
```

**Runtime**: "What will we actually try to load?"
```
ar_SA → ar with variants + default
Returns: [ar_SA, ar_SA.txt, ar_SA.json, ar, ar.txt, ar.json, en]
```

**Why Both?**
- Configuration is clean and simple
- Runtime is complex because we try variants
- Both are correct for their purpose

---

## References

- **Issue #126**: Fallback resolution logic duplication - Inconsistent behavior
- **FallbackResolver**: `lib/src/features/localization/domain/services/fallback_resolver.dart`
- **CatalogService**: `lib/src/features/catalog/use_cases/catalog_service.dart`
- **LocalizationService**: `lib/src/features/localization/data/repositories/localization_service.dart`

