# Feature Specification: Lib Structure Consolidation

**Feature Branch**: `[008-lib-structure-consolidation]`  
**Created**: 2026-06-17  
**Status**: Draft  
**Input**: Architecture review — consolidate `features/` + `shared/` layout, remove duplicate implementations, fix cross-feature boundary violations, and document import rules.

## Assumptions

```
ASSUMPTIONS I'M MAKING:
1. This is a structural refactor only — no intentional behavior or public API changes.
2. Legacy paths (`core/`, `utils/`, `catalog/`, `widgets/`, `services/`) remain as export shims for pub consumers.
3. `core/` keeps runtime infrastructure (`sdk_utils`, `http_client_adapter`, `key_value_storage`).
4. Placement rule (confirmed): code used by ONE feature → `features/<feature>/`; code used by TWO OR MORE features → `shared/`.
5. `features/` owns feature-specific business logic with `data/` / `domain/` / `presentation/` layers.
6. Tests are reorganized into `test/features/` mirroring `lib/src/features/`, plus `test/shared/` for cross-cutting tests.
→ Correct me now or implementation will proceed with these.
```

## Clarifications

### Session 2026-06-17

- Q: When consolidating divergent duplicates with unique logic in both copies, how should conflicts be resolved? → A: Merge all unique logic into canonical location; both copies' behavior preserved.

## Resolved Decisions

| Question | Decision |
|----------|----------|
| Canonical placement / divergent merge | Apply the placement rule: single-feature → that feature; multi-feature → `shared/`. Diff both copies, merge all unique logic into the canonical location before deleting either copy. Both copies' behavior is preserved — no logic is discarded. |
| Merged type API surface | When merging two copies of a type with different method signatures, expose the superset of methods from both copies. |
| Test directory mirror | **In scope.** Reorganize `test/` into `test/features/{localization,catalog,migration}/` and `test/shared/`. Keep `test/contract/` and `test/e2e/` at root. |
| `conversion_helper` package imports | Convert to relative imports to canonical paths when touching those files. |

## Objective

Finish the migration to a feature-first package layout so contributors have one canonical location per module, legacy shim folders contain only `export` lines, and feature boundaries follow clean-architecture dependency rules.

**Who benefits**: package maintainers, contributors, and consumers relying on stable public import paths.

**Success looks like**: zero divergent duplicate `.dart` files, documented import rules, all CI gates green, and no presentation-layer imports of another feature's `data/` layer.

## User Scenarios & Testing

### User Story 1 — Single Canonical Implementation (Priority: P1)

A maintainer editing translation parsing, migration helpers, or catalog repository logic finds exactly one implementation file per concern, with legacy paths re-exporting the canonical module.

**Why this priority**: Duplicate files are the highest-risk source of drift and silent bugs.

**Independent Test**: Run a repo script or grep check confirming listed legacy paths are `export`-only (or deleted), and `diff` shows no second implementation for the same type.

**Acceptance Scenarios**:

1. **Given** the consolidation is complete, **When** a contributor opens `lib/src/utils/translation_file_parser.dart`, **Then** it contains only an `export` to the canonical file under `shared/utils/`.
2. **Given** the consolidation is complete, **When** searching for `class CatalogRepository`, **Then** exactly one implementation exists under `features/catalog/data/repositories/`.
3. **Given** two previously divergent copies existed, **When** consolidation merges them, **Then** all existing tests pass without changing expected behavior.

---

### User Story 2 — Feature Boundary Compliance (Priority: P1)

Catalog UI depends on localization through domain contracts or facades, not by importing `localization/data/` directly.

**Why this priority**: Violates the project's architecture rules and makes features harder to test in isolation.

**Independent Test**: Static grep/lint checks: no file under `features/catalog/` imports `features/localization/data/` or `features/localization/presentation/`.

**Acceptance Scenarios**:

1. **Given** `catalog_flutter_app.dart` needs localization runtime behavior, **When** refactored, **Then** it depends on an abstract contract in `localization/domain/` (no `localization/data/` import) via constructor injection or a domain-level type.
2. **Given** `catalog_localizations.dart` needs delegate types, **When** refactored, **Then** it imports from `localization/domain/` (contract/types only), not `localization/presentation/`.
3. **Given** the refactor, **When** `flutter test` runs catalog widget tests, **Then** all pass.

---

### User Story 3 — CLI and Internal Imports Use Canonical Paths (Priority: P2)

`bin/` and in-package feature code import canonical modules (`features/*`, `shared/*`) while public shim paths remain available for external consumers.

**Why this priority**: Operational code should not maintain parallel import graphs through stale `utils/` copies.

**Independent Test**: `bin/anas_cli.dart` and `bin/generate_dictionary.dart` import migration/catalog/shared canonical paths; `utils/` shims still resolve for `package:anas_localization/...` public exports.

**Acceptance Scenarios**:

1. **Given** CLI migration commands, **When** imports are updated, **Then** they target `features/migration/` or `shared/utils/` (not duplicate `utils/*.dart` bodies).
2. **Given** a pub consumer imports `package:anas_localization/src/utils/arb_interop.dart`, **Then** the import still works via re-export.

---

### User Story 4 — Documented Structure Rules (Priority: P2)

New contributors can read one document explaining where code belongs and which import directions are allowed.

**Why this priority**: Prevents regression after consolidation.

**Independent Test**: `doc/reference/file-structure.md` (or linked architecture doc) includes folder roles and import rules; `CLAUDE.md` references it.

**Acceptance Scenarios**:

1. **Given** the updated docs, **When** a contributor adds a formatter, **Then** the doc clearly states it belongs in `shared/core/formatters/`.
2. **Given** the updated docs, **When** catalog needs localization logic, **Then** the doc states domain-to-domain imports are allowed; data/presentation cross-feature imports are not.

---

### User Story 5 — Mirror Tests Under `test/features/` (Priority: P2)

Test files live under `test/features/<feature>/` (or `test/shared/` for cross-cutting utilities) matching the lib layout, so contributors can find tests next to the code they exercise.

**Why this priority**: Structural consistency between `lib/` and `test/` prevents the same drift we are fixing in source.

**Independent Test**: All tests pass from repo root after moves; no orphaned files remain in flat `test/*.dart` (except documented root-level integration dirs).

**Acceptance Scenarios**:

1. **Given** catalog tests, **When** reorganized, **Then** they live under `test/features/catalog/`.
2. **Given** `flutter test` from repo root, **When** run after reorganization, **Then** all tests are discovered and pass without changing `pubspec.yaml` test config (default `test/` recursion).

---

### User Story 6 — Relocate Catalog API Module (Priority: P3)

`FallbackConfigurationApi` lives under the catalog feature instead of a loose `src/api/` root folder. **Relocation is done in Phase 2 (T039a)**; this story's Phase 7 work verifies public exports remain stable.

**Why this priority**: Improves feature cohesion; lower risk than duplicate removal.

**Independent Test**: `lib/anas_localization.dart` still exports `FallbackConfigurationApi`; canonical file is under `features/catalog/api/` with export shim at `src/api/`.

**Acceptance Scenarios**:

1. **Given** the move, **When** searching for `fallback_configuration_api.dart`, **Then** canonical file is under `features/catalog/api/` (or `features/catalog/server/api/`).
2. **Given** existing public export in `anas_localization.dart`, **When** consumers import `FallbackConfigurationApi`, **Then** no import path change is required.

---

## Requirements

### Functional Requirements

- **FR-001**: System MUST maintain a single canonical implementation for each of these types/modules (placement per resolved decision):
  - `CatalogRepository` → `features/catalog/data/repositories/` (catalog only)
  - `TranslationLoader` and loaders → `features/localization/data/sources/` (localization only)
  - `translation_file_parser` → `shared/utils/` (catalog, localization, migration, CLI)
  - `localization_metadata` → `features/migration/data/helpers/` (migration only)
  - `migration_helper`, `migration_validation_helper`, `conversion_helper` → `features/migration/data/helpers/` (migration only)
- **FR-001a**: Any module MUST live in `shared/` only when imported by two or more features (or feature + `bin/` counts as cross-cutting for shared placement).
- **FR-002**: Legacy shim files under `lib/src/utils/`, `lib/src/catalog/`, `lib/src/core/` (where applicable) MUST contain only `export` directives after consolidation, except `core/` infrastructure files (`sdk_utils.dart`, `http_client_adapter.dart`, `key_value_storage.dart`).
- **FR-003**: `features/catalog/**` MUST NOT import from `features/localization/data/` or `features/localization/presentation/`. Cross-feature access MUST go through `localization/domain/` contracts (abstract types with no data-layer imports in domain).
- **FR-004**: `bin/` entry points and in-package `lib/src/**` implementations (excluding export shims) MUST import canonical `features/*` or `shared/*` paths — not legacy `src/utils/`, `src/catalog/`, or `src/core/` shim paths.
- **FR-005**: Public package exports in `lib/anas_localization.dart` and `lib/catalog.dart` MUST remain backward compatible (no removed exports).
- **FR-006**: Documentation MUST define folder roles (`features/`, `shared/`, `core/`, shim folders) and allowed cross-feature import directions.
- **FR-007**: `FallbackConfigurationApi` SHOULD be relocated under `features/catalog/` with optional re-export shim at `src/api/`.
- **FR-008**: Tests MUST be reorganized under `test/features/{localization,catalog,migration}/` and `test/shared/`; `test/contract/` and `test/e2e/` remain at `test/` root permanently (not deferred to a future phase).

### Non-Functional Requirements

- **NFR-001**: All CI quality gates pass after each phase checkpoint.
- **NFR-002**: No new runtime dependencies.
- **NFR-003**: Refactor tasks touch ≤5 files per task where possible (per planning skill).

## Tech Stack

- Dart `>=3.3.0 <4.0.0`, Flutter `>=3.19.0`
- Testing: `flutter_test`, `dart analyze`
- Architecture reference: `flutter-apply-architecture-best-practices` skill (layered features + repositories)

## Commands

```bash
# Format + analyze (CI lint)
dart format --set-exit-if-changed .
dart analyze

# Full test suite
flutter test

# Catalog sub-app tests
cd tool/catalog_app && flutter test

# Example app tests
cd example && flutter test

# Publish gate
flutter pub publish --dry-run

# Serve catalog (smoke after catalog changes)
dart run anas_localization:anas catalog serve
```

## Project Structure (Target)

```text
lib/
├── anas_localization.dart       # public barrel (unchanged exports)
├── catalog.dart                 # catalog public barrel
└── src/
    ├── features/
    │   ├── localization/        # runtime i18n: data / domain / presentation
    │   ├── catalog/             # editor + server + api
    │   │   └── api/             # FallbackConfigurationApi (moved)
    │   └── migration/           # migration helpers + localization_metadata
    ├── shared/
    │   ├── core/formatters/     # date, number, RTL, rich text, exceptions
    │   ├── utils/               # multi-feature parsers, validators, codegen
    │   └── services/logging/    # logging
    ├── core/                    # infra ONLY: sdk_utils, http, storage
    ├── utils/                   # export shims → shared/ or features/
    ├── catalog/                 # export shims → features/catalog/
    ├── widgets/                 # export shims → localization presentation
    ├── services/                # export shim → shared/services/
    └── api/                     # optional export shim → features/catalog/api/

test/
├── features/
│   ├── localization/            # dictionary, locale fallback, localization_service, etc.
│   ├── catalog/                 # catalog_* tests
│   └── migration/               # migration_* tests
├── shared/                      # arb_interop, tool_workflow, structure guard
├── contract/                    # unchanged
└── e2e/                         # unchanged
```

## Code Style

Shim files are one line:

```dart
export '../shared/utils/translation_file_parser.dart';
```

Canonical implementations use package-relative imports within `lib/src/`:

```dart
import '../../../../shared/utils/translation_file_parser.dart';
```

Test files use `package:anas_localization/...` imports (not relative paths) so tests validate the same import paths consumers use:

```dart
// ✅ test/features/catalog/
import 'package:anas_localization/src/features/catalog/domain/entities/catalog_models.dart';

// ❌ test/features/catalog/
import '../../../lib/src/features/catalog/domain/entities/catalog_models.dart';
```

Cross-feature imports allow `domain/` → `domain/` only:

```dart
// ✅ catalog/domain importing localization/domain
import '../../../localization/domain/services/fallback_resolver.dart';

// ❌ catalog importing localization/data or localization/presentation
import '../../../localization/data/repositories/localization_service.dart';
import '../../../localization/presentation/widgets/dictionary_localizations_delegate.dart';

// ✅ catalog importing localization/domain contract
import '../../../localization/domain/contracts/localization_service_contract.dart';
```

## Testing Strategy

| Concern | Where | How |
|---------|-------|-----|
| Duplicate removal | `test/` existing suite | Full `flutter test` after each merge |
| Catalog boundary | `test/catalog_flutter_app_test.dart` | Widget/integration tests |
| Migration CLI | `test/migration_helper_test.dart`, `test/migration_validation_helper_test.dart` | Unit tests |
| Shim compatibility | `tool/check_shim_exports.dart` + `test/shared/lib_structure_shim_exports_test.dart` | Script enforces export-only shims; test asserts key shim paths export expected types |
| Regression guard | `tool/check_shim_exports.dart` in CI | Fail CI if legacy files contain implementation code |

Coverage expectation: no decrease in passing tests; add shim export test if gaps exist.

## Boundaries

### Always

- Run `dart format --set-exit-if-changed .`, `flutter analyze --no-fatal-infos`, and `flutter test` at each checkpoint.
- Keep public exports stable in `lib/anas_localization.dart` and `lib/catalog.dart`.
- Merge divergent duplicates by diffing both copies before deleting either.
- Prefer re-export shims over breaking consumer import paths.

### Ask first

- Removing any file from `lib/` that is exported publicly without a shim.
- Adding new lint rules or CI steps.

### Never

- Change translation/runtime behavior intentionally in this refactor.
- Delete duplicate files without merging all unique logic from both copies into the canonical location first.
- Import `features/*/data/` or `features/*/presentation/` from another feature's code (use `domain/` contracts instead).
- Force consumers to change `package:anas_localization/...` import paths.

### Rollback Strategy

If any phase checkpoint fails CI (dart analyze / flutter test), revert that phase's commit via git and re-attempt. Do not fix-forward with hotfix commits within a failing phase.

## Success Criteria

- [X] Zero divergent duplicate implementations across all **38 modules** in `data-model.md` (8 remaining as of spec date; 30 already export-only).
- [X] All legacy shim directories (`utils/`, `catalog/`, `core/` except infra, `widgets/`, `services/`, `api/`) contain only `export` directives.
- [X] `localization_metadata` canonical copy lives under `features/migration/data/helpers/`; `utils/` path is export-only.
- [X] No `features/catalog/**` file imports `features/localization/data/**` or `features/localization/presentation/**`.
- [X] `bin/` and `lib/src/**` (non-shim) import canonical `features/*` and `shared/*` paths only.
- [X] `doc/reference/file-structure.md` documents folder roles and import rules; `CLAUDE.md` references it.
- [X] `tool/check_shim_exports.dart` passes and is wired into CI.
- [X] `flutter analyze --no-fatal-infos` reports 0 issues; `dart format --set-exit-if-changed .` passes.
- [X] `flutter test` passes; `cd tool/catalog_app && flutter test` and `cd example && flutter test` pass.
- [X] `flutter pub publish --dry-run` passes (`lib/anas_localization.dart` and `lib/catalog.dart` exports unchanged).
- [X] All package tests live under `test/features/` or `test/shared/` (no flat `test/*.dart`); `test/contract/` and `test/e2e/` remain at root.

## Module Placement Reference

| Module | Used by | Canonical location |
|--------|---------|-------------------|
| `translation_file_parser` | catalog, localization, migration, shared validators, CLI | `shared/utils/` |
| `localization_metadata` | migration only | `features/migration/data/helpers/` |
| `migration_helper` | migration, CLI | `features/migration/data/helpers/` |
| `migration_validation_helper` | migration, CLI | `features/migration/data/helpers/` |
| `conversion_helper` | migration, CLI | `features/migration/data/helpers/` |
| `CatalogRepository` | catalog only | `features/catalog/data/repositories/` |
| `TranslationLoader` | localization only | `features/localization/data/sources/` |
| `codegen_utils`, `arb_interop`, `translation_validator` | multiple / CLI | `shared/utils/` (already) |
| `FallbackConfigurationApi` | catalog / public API | `features/catalog/api/` |
