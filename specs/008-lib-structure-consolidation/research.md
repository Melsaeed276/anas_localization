# Research: Lib Structure Consolidation

**Feature**: `008-lib-structure-consolidation`
**Date**: 2026-06-17

## Research Tasks

### R1: How to verify legacy shims are export-only after consolidation

**Decision**: Write a Dart script (`tool/check_shim_exports.dart`) that scans all files in `lib/src/utils/`, `lib/src/catalog/`, `lib/src/core/`, `lib/src/widgets/`, `lib/src/services/`, `lib/src/api/` and asserts each contains only `export` directives (plus optional `library;` declaration). Fails CI if any file has implementation code.

**Rationale**: Automated regression guard is the only reliable way to prevent shim files from accumulating implementation code over time. Manual review doesn't scale.

**Alternatives considered**:
- Grep-based check: Fragile; can't distinguish `export` from implementation code reliably.
- Lint rule: Would require custom `analysis_options.yaml` plugin; heavier than needed for a one-time structural check.

### R2: How to fix the catalog→localization boundary violation

**Current state**: `features/catalog/presentation/screens/catalog_flutter_app.dart` imports `features/localization/data/repositories/localization_service.dart` at line 9.

**Decision**: Introduce an **abstract contract** in `features/localization/domain/contracts/` (e.g. `localization_service_contract.dart`) with the API surface catalog needs. `LocalizationService` in data implements the contract. Catalog imports the contract from domain only — **domain file MUST NOT import data or presentation** (Constitution §VII).

**Rationale**: Constitution §VII forbids domain→data dependencies. A facade that wraps or re-exports data would violate this. Cross-feature access via domain contracts is the correct pattern.

**Alternatives considered**:
- Domain facade wrapping data: Violates §VII (domain depending on data).
- Constructor injection only without contract: Insufficient for `catalog_localizations.dart` delegate types.
- Move LocalizationService to shared: Would make localization-specific logic shared, violating placement rules.

### R3: How to handle divergent duplicate merges

**Decision**: Per clarified spec — merge all unique logic from both copies into the canonical location. Both copies' behavior is preserved; no logic is discarded. Merged types expose the superset of methods.

**Rationale**: Structural refactor must not change runtime behavior. Merging preserves all existing functionality.

**Alternatives considered**:
- Left-wins strategy: Would discard right copy's unique logic — unacceptable.
- Adapter/facade: Over-engineering for files that share 90%+ of their content.

### R4: Test file import strategy

**Decision**: Test files use `package:anas_localization/...` imports (not relative paths). This ensures tests validate the same import paths consumers use.

**Rationale**: Tests that use relative paths bypass the public API surface and won't catch shim breakage.

**Alternatives considered**:
- Relative imports: Would validate internal structure but miss consumer-facing import path issues.

### R5: How to handle `bin/` imports that use legacy paths

**Current state**:
- `bin/anas_cli.dart` imports `src/catalog/catalog.dart`, `src/utils/conversion_helper.dart`, `src/utils/migration_helper.dart`, `src/utils/migration_validation_helper.dart`, `src/utils/translation_file_parser.dart`, `src/utils/arb_interop.dart`, `src/utils/translation_validator.dart`
- `bin/generate_dictionary.dart` imports `src/utils/codegen_utils.dart`
- `bin/validate_translations.dart` imports `src/utils/translation_validator.dart`

**Decision**: Update `bin/` imports to canonical paths (`features/migration/data/helpers/`, `shared/utils/`, `features/catalog/`). Legacy shims ensure external consumers are unaffected.

**Rationale**: FR-004 requires `bin/` entry points to use canonical paths. Since `bin/` is internal to the package, it should exercise the canonical module structure.

**Alternatives considered**:
- Leave `bin/` imports unchanged: Would leave a parallel import graph through stale legacy paths, defeating the consolidation purpose.

### R6: FallbackConfigurationApi relocation

**Current state**: `lib/src/api/fallback_configuration_api.dart` exists in a standalone `api/` directory with no feature association.

**Decision**: Move to `features/catalog/api/fallback_configuration_api.dart` in **Phase 2 (T039a)** so `check_shim_exports.dart` passes at the Phase 2 checkpoint. Create export shim at `src/api/fallback_configuration_api.dart`. **Phase 7** verifies public barrel exports only.

**Rationale**: The API is catalog-related (fallback configuration is a catalog concern). Feature cohesion improves.

**Alternatives considered**:
- Move to `shared/`: Incorrect — API is catalog-specific, not cross-cutting.
- Delete `src/api/`: Would break `lib/anas_localization.dart` public export.

## Skills Reference

| Research | Applicable Skill | Workflow |
|----------|-----------------|----------|
| R1 (Shim verification) | `dart-run-static-analysis` | `dart analyze` catches any non-export code in shims |
| R2 (Boundary fix) | `flutter-apply-architecture-best-practices` | Verify facade follows MVVM dependency directions |
| R3 (Duplicate merge) | `dart-fix-runtime-errors` | If merge introduces type mismatches, use analysis resolution workflow |
| R4 (Test imports) | `flutter-add-widget-test` | Widget tests follow `testWidgets()` → `pumpWidget()` → `Finder` → `expect()` pattern |
| R5 (CLI imports) | `dart-run-static-analysis` | `dart analyze` on `bin/` files catches stale import references |
| R6 (API relocation) | `dart-run-static-analysis` | `dart analyze` confirms re-export shim resolves correctly |
