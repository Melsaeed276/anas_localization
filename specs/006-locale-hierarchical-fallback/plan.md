# Implementation Plan: Hierarchical Locale Fallback System with Custom Locale Support

**Branch**: `006-locale-hierarchical-fallback` | **Date**: 2026-03-24 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/006-locale-hierarchical-fallback/spec.md`

## Summary

Implement a hierarchical locale fallback system that allows users to configure language group fallbacks (e.g., `ar_SA` falls back to `ar_EG` before the project default), alongside custom locale creation with manual text direction selection. This extends the existing `LocalizationService.resolveLocaleFallbackChain()` to respect user-configured language group preferences stored in `catalog_state.json`, and enhances the Add Locale dialog to accept custom locale codes with RTL/LTR selection validated against ISO 639-1/639-2 and ISO 3166-1 standards.

## Technical Context

**Language/Version**: Dart >=3.3.0 <4.0.0, Flutter >=3.19.0  
**Primary Dependencies**: `intl`, `flutter_localizations`, `yaml`, `shared_preferences`  
**Storage**: JSON files (`catalog_state.json` for state, `*.json`/`*.yaml`/`*.arb` for translations)  
**Testing**: `flutter_test` SDK (unit, widget, integration tests)  
**Target Platform**: Cross-platform (iOS, Android, Web, Desktop)  
**Project Type**: Flutter library with CLI tools and Catalog UI  
**Performance Goals**: Locale resolution in <10ms, UI updates at 60fps  
**Constraints**: Backward-compatible with existing `catalog_state.json` files (FR-020)  
**Scale/Scope**: Support 100+ locales, typical project has 5-20 locales

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Dual Access Modes | PASS | Feature extends runtime locale resolution; both generated dictionary and raw-key access benefit from hierarchical fallback |
| II. CLI and Tooling | PASS | No new CLI commands required; existing catalog service handles locale management |
| III. Deterministic Locale Behavior | PASS | Extends `resolveLocaleFallbackChain` with documented, deterministic priority: (1) exact match, (2) language group fallback, (3) project default |
| IV. Migration-Friendly | PASS | FR-020 ensures backward compatibility; existing catalog_state.json files work without modification |
| V. Catalog (Under Development) | PASS | Feature extends catalog UI with language group configuration and custom locale input |
| VI. Simplicity and YAGNI | PASS | Feature directly addresses user request; no speculative additions |
| VII. Clean Architecture Boundaries | PASS | Domain entities in `domain/`, UI in `presentation/`, state in `data/` |
| VIII. Error Handling Standards | PASS | Use `CatalogOperationException` for validation errors; typed exceptions for locale validation |
| IX. Testing Discipline | REQUIRED | Tests for: fallback chain resolution, circular detection, ISO validation, UI components |
| X. CI/CD Quality Gates | REQUIRED | Must pass format, analyze, test gates |
| XI. Logging and Observability | PASS | Use `AnasLoggingService` for fallback chain logging |
| XII. Sharia-Compliant Finance | N/A | Feature not finance-related |

**Gate Status**: PASS - Proceed to Phase 0

## Project Structure

### Documentation (this feature)

```text
specs/006-locale-hierarchical-fallback/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (API contracts)
└── tasks.md             # Phase 2 output (NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/src/
├── features/
│   ├── catalog/
│   │   ├── config/
│   │   │   └── catalog_config.dart              # Existing config
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── catalog_state_store.dart     # Extends for languageGroupFallbacks
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── catalog_models.dart          # Add LanguageGroupFallback, CustomLocale models
│   │   │   └── services/
│   │   │       └── locale_validation_service.dart  # NEW: ISO code validation
│   │   ├── presentation/
│   │   │   └── screens/
│   │   │       ├── catalog_label_helpers.dart   # Extend showAddLocaleDialog
│   │   │       └── catalog_locale_settings.dart # NEW: Language group fallback UI
│   │   └── use_cases/
│   │       └── catalog_service.dart             # Extend for fallback configuration
│   └── localization/
│       └── data/
│           └── repositories/
│               └── localization_service.dart    # Extend resolveLocaleFallbackChain
├── shared/
│   └── utils/
│       └── iso_locale_codes.dart                # NEW: ISO 639-1/639-2 and ISO 3166-1 data
└── core/
    └── localization_exceptions.dart             # Add InvalidLocaleCodeException

test/
├── catalog_locale_fallback_test.dart            # NEW: Fallback chain tests
├── locale_validation_test.dart                  # NEW: ISO validation tests
└── catalog_custom_locale_test.dart              # NEW: Custom locale UI tests
```

**Structure Decision**: Follows existing feature-based organization with clean architecture boundaries. New code placed in appropriate layers (domain for entities/services, presentation for UI, data for persistence).

## Complexity Tracking

> No constitution violations identified. Feature aligns with existing patterns.

---

## Post-Design Constitution Re-evaluation

*Re-checked after Phase 1 design completion (2026-03-24)*

| Principle | Status | Post-Design Notes |
|-----------|--------|-------------------|
| I. Dual Access Modes | PASS | Design maintains compatibility; FallbackChain resolution used by both codegen and runtime |
| II. CLI and Tooling | PASS | No CLI changes; HTTP API extensions documented in `contracts/catalog-service-api.md` |
| III. Deterministic Locale Behavior | PASS | Fallback chain algorithm fully specified in `quickstart.md`; cycle detection prevents non-determinism |
| IV. Migration-Friendly | PASS | `data-model.md` confirms backward compatibility via default empty maps |
| V. Catalog (Under Development) | PASS | UI extensions (dialog tab, settings screen) follow existing patterns |
| VI. Simplicity and YAGNI | PASS | Design adds only what spec requires; ISO data embedded, no external dependencies |
| VII. Clean Architecture Boundaries | PASS | Layer separation maintained: `LocaleValidationService` in domain, state in data, UI in presentation |
| VIII. Error Handling Standards | PASS | Typed exceptions defined: `InvalidLocaleCodeException`, `CircularFallbackException` |
| IX. Testing Discipline | READY | Test priorities documented in `quickstart.md`; unit > widget > integration order |
| X. CI/CD Quality Gates | READY | No special CI changes; standard format/analyze/test gates apply |
| XI. Logging and Observability | PASS | Logging points identified for fallback resolution and validation errors |
| XII. Sharia-Compliant Finance | N/A | Feature not finance-related |

**Post-Design Gate Status**: PASS - Ready for Phase 2 task breakdown

---

## Phase 1 Deliverables Summary

| Deliverable | Status | Location |
|-------------|--------|----------|
| `research.md` | Complete | `specs/006-locale-hierarchical-fallback/research.md` |
| `data-model.md` | Complete | `specs/006-locale-hierarchical-fallback/data-model.md` |
| `contracts/catalog-service-api.md` | Complete | `specs/006-locale-hierarchical-fallback/contracts/catalog-service-api.md` |
| `quickstart.md` | Complete | `specs/006-locale-hierarchical-fallback/quickstart.md` |

**Phase 1 Status**: COMPLETE - All deliverables created
