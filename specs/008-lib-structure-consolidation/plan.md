# Implementation Plan: Lib Structure Consolidation

**Branch**: `[008-lib-structure-consolidation]` | **Date**: 2026-06-17 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/008-lib-structure-consolidation/spec.md`

## Summary

Consolidate the `lib/src/` layout into a clean feature-first architecture: **38 modules** tracked in `data-model.md` (30 already export-only shims; **8 still have divergent implementations** as of 2026-06-17). Fix cross-feature boundary violations (`catalog` → `localization/data` and `catalog` → `localization/presentation`). Migrate `bin/` and in-package `lib/` imports from legacy paths to canonical paths. Reorganize **29** flat `test/*.dart` files into `test/features/` and `test/shared/`. Document import rules in `doc/reference/file-structure.md`.

## Technical Context

**Language/Version**: Dart `>=3.3.0 <4.0.0`, Flutter `>=3.19.0`
**Primary Dependencies**: None new — `flutter_localizations`, `intl`, `yaml`, `http`, `shared_preferences` (existing)
**Storage**: File-based (JSON/YAML/CSV/ARB locale files + `catalog_state.json`)
**Testing**: `flutter_test`, `dart analyze`, `dart format`
**Target Platform**: Flutter (iOS, Android, Web, Desktop) — this refactor is platform-agnostic
**Project Type**: Flutter package (pub.dev library)
**Performance Goals**: No runtime performance change — structural refactor only
**Constraints**: Zero new runtime dependencies; public exports must remain backward compatible; no behavior changes
**Scale/Scope**: 38 modules in inventory (8 remaining divergent, 30 already shims); 29 flat test files to reorganize; 2 cross-feature boundary violations to fix (`localization/data`, `localization/presentation`); `FallbackConfigurationApi` relocation in Phase 2 (T039a), export verification in Phase 7

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Principle | Status | Notes |
|------|-----------|--------|-------|
| VII | Clean Architecture Boundaries | ⚠️ VIOLATION | `catalog_flutter_app.dart` imports `localization/data/`; `catalog_localizations.dart` imports `localization/presentation/` — both must be fixed via domain contracts (domain MUST NOT import data) |
| VIII | Error Handling Standards | ✅ PASS | No error handling changes in this refactor |
| IX | Testing Discipline | ✅ PASS | Tests reorganized; all existing tests must continue passing |
| X | CI/CD Quality Gates | ✅ PASS | `dart format --set-exit-if-changed`, `flutter analyze --no-fatal-infos`, `flutter test`, `flutter pub publish --dry-run` gates remain unchanged |
| XI | Logging and Observability | ✅ PASS | No logging changes |
| XII | Sharia-Compliant Finance | N/A | No financial features in this refactor |
| VI | Simplicity and YAGNI | ✅ PASS | Minimal approach: re-export shims, no new abstractions |

**Verdict**: Two architecture boundary violations (VII) exist in current codebase — this refactor explicitly fixes them via domain contracts (no domain→data imports). No new violations introduced. Gate passes.

## Skills Reference

The following skills from `.agents/skills/` apply to this feature and should be followed during implementation:

| Skill | When to Use | Key Workflow |
|-------|-------------|--------------|
| `flutter-apply-architecture-best-practices` | Architecture layer verification | Verify data→domain→presentation dependency directions match MVVM pattern |
| `dart-run-static-analysis` | Every phase checkpoint | `flutter analyze --no-fatal-infos` → `dart fix --apply` → `dart format --set-exit-if-changed .` → re-analyze |
| `dart-fix-runtime-errors` | If analysis errors appear after file moves | `dart analyze` → `dart fix --dry-run` → `dart fix --apply` → manual resolution |
| `flutter-add-widget-test` | Catalog widget test reorganization | `testWidgets()` → `pumpWidget()` → `Finder` → `expect()` → `pumpAndSettle()` |
| `dart-collect-coverage` | Final verification | `flutter test --coverage` → validate `coverage/lcov.info` exists |

### Static Analysis Workflow (per `dart-run-static-analysis`)

Each phase checkpoint MUST follow this sequence:

```bash
# 1. Analyze (matches CI)
flutter analyze --no-fatal-infos

# 2. Apply automated fixes (if any)
dart fix --dry-run    # preview
dart fix --apply      # apply

# 3. Format (matches CI)
dart format --set-exit-if-changed .

# 4. Re-analyze to confirm clean
flutter analyze --no-fatal-infos

# 5. Run tests
flutter test
```

### Architecture Boundary Fix (per `flutter-apply-architecture-best-practices`)

The `catalog` → `localization` violations must be fixed by:

1. Creating an **abstract contract** in `localization/domain/contracts/` (e.g. `localization_service_contract.dart`) with the methods/types catalog needs — **no imports from `localization/data/` or `localization/presentation/` in domain**
2. Implementing the contract in `localization/data/repositories/localization_service.dart`
3. Updating `catalog_flutter_app.dart` to depend on the contract type (constructor injection or domain import)
4. Refactoring `catalog/l10n/catalog_localizations.dart` to obtain delegate types via a domain-level contract (not `localization/presentation/`)
5. Verifying: `rg "import.*features/localization/(data|presentation)" lib/src/features/catalog/` returns empty

## Project Structure

### Documentation (this feature)

```text
specs/008-lib-structure-consolidation/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (import rules contract)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── anas_localization.dart       # public barrel (exports unchanged)
├── catalog.dart                 # catalog public barrel (exports unchanged)
└── src/
    ├── features/
    │   ├── localization/        # runtime i18n: data / domain / presentation
    │   ├── catalog/             # editor + server + api
    │   │   └── api/             # FallbackConfigurationApi (moved from src/api/)
    │   └── migration/           # migration helpers
    ├── shared/
    │   ├── core/formatters/     # date, number, RTL, rich text, exceptions
    │   ├── utils/               # multi-feature parsers, validators, codegen
    │   └── services/logging/    # logging
    ├── core/                    # infra ONLY: sdk_utils, http, storage
    ├── utils/                   # export shims → shared/ or features/
    ├── catalog/                 # export shims → features/catalog/
    ├── widgets/                 # export shims → localization presentation
    ├── services/                # export shim → shared/services/
    └── api/                     # export shim → features/catalog/api/

test/
├── features/
│   ├── localization/
│   ├── catalog/
│   └── migration/
├── shared/
├── contract/                    # unchanged
└── e2e/                         # unchanged
```

**Structure Decision**: Feature-first layout per constitution §VII. Legacy directories become thin re-export shims for backward compatibility.

## Complexity Tracking

> Two existing violations (VII) are fixed by this refactor. Proposed domain contracts MUST NOT import data or presentation layers.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
