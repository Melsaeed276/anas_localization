# Implementation Plan: Arabic Language Localization Support

**Branch**: `002-arabic-localization-support` | **Date**: 2026-03-15 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-arabic-localization-support/spec.md`

## Summary

Add full Arabic localization support to the anas_localization package: RTL layout and bidirectional text, six-form Arabic plurals, gender (male/female) and formality variants, regional variants (MSA, Gulf, Egyptian), Eastern/Western numerals and locale-aware number/date/time/currency formatting, honorifics, canonical fallback chain, optional per-key string type with CLI/Catalog warnings when required forms are missing, and async-load-safe resolution (fallback immediately; refresh when asset loads). The package already provides `PluralRules` (Arabic 6-form), `AnasTextDirection`/RTL, `AnasNumberFormatter`, and `Dictionary`; this plan extends them to match the spec (user context, variant/formality, fallback order, string type, warnings) and adds date/time/currency and Catalog/CLI integration.

## Technical Context

**Language/Version**: Dart SDK >=3.3.0 <4.0.0, Flutter >=3.19.0  
**Primary Dependencies**: Flutter SDK, intl (>=0.18.0), flutter_localizations, yaml, shared_preferences; existing code uses analyzer, http, crypto, path  
**Storage**: File-based (ARB/JSON/YAML/CSV); shared_preferences for app preferences; no DB  
**Testing**: flutter_test; existing integration/unit tests in test/  
**Target Platform**: iOS, Android, web, desktop (Flutter targets)  
**Project Type**: Flutter/Dart package (library) with CLI (anas, anas_cli, localization_gen) and Catalog UI (tool/catalog_app)  
**Performance Goals**: Message resolution and locale switching must feel instant (no perceptible delay); qualitative per spec. *Instant* means no blocking and no perceptible delay in normal conditions.  
**Constraints**: Deterministic locale/fallback behavior; migration-friendly (gen_l10n, easy_localization); dual access (type-safe generated API + raw keys); CLI validation in CI  
**Scale/Scope**: Multiple Arabic regions (SA, EG, AE, MA, DZ, TN, LB, JO, IQ); six plural forms; male/female; MSA + optional dialect variants; formal/informal

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Alignment |
|-----------|-----------|
| **I. Dual access modes** | Type-safe generated dictionary and raw-key access both use the same loading and fallback; Arabic context (gender, formality, variant) applies to both. |
| **II. CLI and tooling** | Validate (and optional profiles) remain CI-ready; Arabic string-type warnings surface in CLI and Catalog UI per spec. |
| **III. Deterministic locale behavior** | Canonical fallback order (plural→other, gender→other, variant→MSA, then base/key) is documented and same inputs → same result on all platforms; system locale remains input to resolution. |
| **IV. Migration-friendly** | No breaking change to existing public API; new options (user context, string type) are additive; migration paths preserved. |
| **V. Catalog** | Catalog supports Arabic-specific options (plural forms, gender, variant, formality) and string type; warnings for missing required forms shown in Catalog UI. |
| **VI. Simplicity and YAGNI** | Optional string type and regional/formality variants are justified by the Arabic spec; no duplicate behavior flags. |

**Gate result**: PASS — no violations.

*Post–Phase 1 re-check*: data-model, contracts, and quickstart do not introduce new violations; resolution API and asset schema remain aligned with Principles I–VI.

## Project Structure

### Documentation (this feature)

```text
specs/002-arabic-localization-support/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── src/
│   ├── core/                    # Locale, loader, text direction, formatters
│   ├── features/
│   │   ├── localization/       # Dictionary, entities, repositories, services
│   │   ├── catalog/             # Catalog UI, backend, l10n, config
│   │   └── migration/           # gen_l10n / easy_localization migration
│   ├── shared/                  # plural_rules, formatters, validators, arb_interop
│   └── widgets/                 # language selector, setup overlay
├── anas_localization.dart
└── localization.dart

bin/                              # anas, localization_gen, anas_cli, cli
test/
example/
tool/catalog_app/                 # Catalog sidecar UI
```

**Structure Decision**: Single package with lib (core + features + shared), bin (CLI), test, example, and tool/catalog_app. Arabic support extends existing lib and shared code and Catalog configuration; no new top-level projects.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | — | — |
