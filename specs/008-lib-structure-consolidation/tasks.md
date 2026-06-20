# Tasks: Lib Structure Consolidation

**Input**: Design documents from `/specs/008-lib-structure-consolidation/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/import-rules.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Regression Guard)

**Purpose**: Create the regression guard script and establish git checkpoint strategy.

- [X] T001 Create `tool/check_shim_exports.dart` — scan `lib/src/utils/`, `lib/src/catalog/`, `lib/src/core/`, `lib/src/widgets/`, `lib/src/services/`, `lib/src/api/` and assert each contains only `export` directives (plus optional `library;`). Fail CI if any file has implementation code. Per contracts/import-rules.md regression guard spec.
- [X] T002 Run `dart run tool/check_shim_exports.dart` against current codebase — **expect exit code 1** (8 files still have implementation as of spec date). Record baseline output; do not treat failure as blocking until Phase 2 completes.
- [X] T002a Wire `dart run tool/check_shim_exports.dart` into `.github/workflows/` CI (after `flutter test` or as lint step). Gate passes only after Phase 2.
- [X] T002b Create `test/shared/lib_structure_shim_exports_test.dart` — assert key public shim paths (`src/utils/arb_interop.dart`, `src/core/dictionary.dart`, etc.) export expected types.

---

## Phase 2: Foundational (Duplicate Resolution)

**Purpose**: Resolve remaining divergent module pairs. **38 modules** in `data-model.md` inventory; **30 already export-only**; **8 still have divergent implementations** (as of 2026-06-17). Tasks T003–T039a cover the full inventory — skip pairs already export-only after `diff` confirms no unique logic in legacy copy.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete. Each checkpoint must pass `flutter analyze --no-fatal-infos` + `flutter test` per constitution §X.

**Workflow per duplicate pair**: (1) `diff` both copies — (2) merge all unique logic into canonical location — (3) delete legacy copy — (4) convert legacy path to export shim — (5) verify `dart analyze` + `flutter test`.

### US1: Canonical catalog implementation

- [X] T003 [P] [US1] Resolve `CatalogRepository` — diff `lib/src/catalog/catalog_repository.dart` vs `lib/src/features/catalog/data/repositories/catalog_repository.dart`, merge unique logic into canonical at `features/catalog/data/repositories/catalog_repository.dart`, convert `lib/src/catalog/catalog_repository.dart` to export shim
- [X] T004 [P] [US1] Resolve `CatalogStateStore` — diff `lib/src/catalog/catalog_state_store.dart` vs `lib/src/features/catalog/data/repositories/catalog_state_store.dart`, merge into canonical, convert legacy to export shim
- [X] T005 [P] [US1] Resolve `CatalogService` — diff `lib/src/catalog/catalog_service.dart` vs `lib/src/features/catalog/use_cases/catalog_service.dart`, merge into canonical, convert legacy to export shim
- [X] T006 [P] [US1] Resolve `CatalogBackend` — diff `lib/src/catalog/catalog_backend.dart` vs `lib/src/features/catalog/server/catalog_backend.dart`, merge into canonical, convert legacy to export shim
- [X] T007 [P] [US1] Resolve `CatalogConfig` — diff `lib/src/catalog/catalog_config.dart` vs `lib/src/features/catalog/config/catalog_config.dart`, merge into canonical, convert legacy to export shim
- [X] T008 [P] [US1] Resolve `CatalogModels` — diff `lib/src/catalog/catalog_models.dart` vs `lib/src/features/catalog/domain/entities/catalog_models.dart`, merge into canonical, convert legacy to export shim
- [X] T009 [P] [US1] Resolve `CatalogFlatten` — diff `lib/src/catalog/catalog_flatten.dart` vs `lib/src/features/catalog/domain/services/catalog_flatten.dart`, merge into canonical, convert legacy to export shim
- [X] T010 [P] [US1] Resolve `CatalogStatusEngine` — diff `lib/src/catalog/catalog_status_engine.dart` vs `lib/src/features/catalog/domain/services/catalog_status_engine.dart`, merge into canonical, convert legacy to export shim
- [X] T011 [P] [US1] Resolve `CatalogFlutterApp` — diff `lib/src/catalog/catalog_flutter_app.dart` vs `lib/src/features/catalog/presentation/screens/catalog_flutter_app.dart`, merge into canonical, convert legacy to export shim
- [X] T012 [P] [US1] Resolve `CatalogUiLogic` — diff `lib/src/catalog/catalog_ui_logic.dart` vs `lib/src/features/catalog/presentation/controllers/catalog_ui_logic.dart`, merge into canonical, convert legacy to export shim
- [X] T013 [P] [US1] Resolve `CatalogUiTemplate` — diff `lib/src/catalog/catalog_ui_template.dart` vs `lib/src/features/catalog/server/catalog_ui_template.dart`, merge into canonical, convert legacy to export shim
- [X] T014 [P] [US1] Resolve `CatalogClient` — diff `lib/src/catalog/catalog_client.dart` vs `lib/src/features/catalog/client/catalog_client.dart`, merge into canonical, convert legacy to export shim

### US1: Canonical localization implementation

- [X] T015 [P] [US1] Resolve `TranslationLoader` — diff `lib/src/core/translation_loader.dart` vs `lib/src/features/localization/data/sources/translation_loader.dart`, merge into canonical, convert legacy to export shim
- [X] T016 [P] [US1] Resolve `LocalizationService` — diff `lib/src/core/localization_service.dart` vs `lib/src/features/localization/data/repositories/localization_service.dart`, merge into canonical, convert legacy to export shim
- [X] T017 [P] [US1] Resolve `AnasLocalizationStorage` — diff `lib/src/core/anas_localization_storage.dart` vs `lib/src/features/localization/data/sources/anas_localization_storage.dart`, merge into canonical, convert legacy to export shim
- [X] T018 [P] [US1] Resolve `Dictionary` — diff `lib/src/core/dictionary.dart` vs `lib/src/features/localization/domain/entities/dictionary.dart`, merge into canonical, convert legacy to export shim
- [X] T019 [P] [US1] Resolve `LocaleDetector` — diff `lib/src/core/locale_detector.dart` vs `lib/src/features/localization/domain/entities/locale_detector.dart`, merge into canonical, convert legacy to export shim
- [X] T020 [P] [US1] Resolve `DictionaryLocalizationsDelegate` — diff `lib/src/core/dictionary_localizations_delegate.dart` vs `lib/src/features/localization/presentation/widgets/dictionary_localizations_delegate.dart`, merge into canonical, convert legacy to export shim

### US1: Canonical shared/utils implementation

- [X] T021 [P] [US1] Resolve `translation_file_parser` — diff `lib/src/utils/translation_file_parser.dart` vs `lib/src/shared/utils/translation_file_parser.dart`, merge into canonical, convert legacy to export shim
- [X] T022 [P] [US1] Resolve `translation_validator` — diff `lib/src/utils/translation_validator.dart` vs `lib/src/shared/utils/translation_validator.dart`, merge into canonical, convert legacy to export shim
- [X] T023 [P] [US1] Resolve `arb_interop` — diff `lib/src/utils/arb_interop.dart` vs `lib/src/shared/utils/arb_interop.dart`, merge into canonical, convert legacy to export shim
- [X] T024 [P] [US1] Resolve `codegen_utils` — diff `lib/src/utils/codegen_utils.dart` vs `lib/src/shared/utils/codegen_utils.dart`, merge into canonical, convert legacy to export shim
- [X] T025 [P] [US1] Resolve `localization_metadata` — diff `lib/src/utils/localization_metadata.dart` vs `lib/src/features/migration/data/helpers/localization_metadata.dart`, merge into canonical at `features/migration/data/helpers/`, convert legacy to export shim
- [X] T026 [P] [US1] Resolve `plural_rules` — diff `lib/src/utils/plural_rules.dart` vs `lib/src/shared/utils/plural_rules.dart`, merge into canonical, convert legacy to export shim
- [X] T027 [P] [US1] Resolve `arabic_text_utils` — diff `lib/src/utils/arabic_text_utils.dart` vs `lib/src/shared/utils/arabic_text_utils.dart`, merge into canonical, convert legacy to export shim
- [X] T028 [P] [US1] Resolve `arabic_input_validation` — diff `lib/src/utils/arabic_input_validation.dart` vs `lib/src/shared/utils/arabic_input_validation.dart`, merge into canonical, convert legacy to export shim

### US1: Canonical migration implementation

- [X] T029 [P] [US1] Resolve `migration_helper` — diff `lib/src/utils/migration_helper.dart` vs `lib/src/features/migration/data/helpers/migration_helper.dart`, merge into canonical, convert legacy to export shim
- [X] T030 [P] [US1] Resolve `migration_validation_helper` — diff `lib/src/utils/migration_validation_helper.dart` vs `lib/src/features/migration/data/helpers/migration_validation_helper.dart`, merge into canonical, convert legacy to export shim
- [X] T031 [P] [US1] Resolve `conversion_helper` — diff `lib/src/utils/conversion_helper.dart` vs `lib/src/features/migration/data/helpers/conversion_helper.dart`, merge into canonical, convert legacy to export shim; update canonical copy to use relative imports to `shared/utils/` (not `package:.../src/utils/`)

### US1: Canonical formatters and widgets

- [X] T032 [P] [US1] Resolve `DateTimeFormatter` — diff `lib/src/core/date_time_formatter.dart` vs `lib/src/shared/core/formatters/date_time_formatter.dart`, merge into canonical, convert legacy to export shim
- [X] T033 [P] [US1] Resolve `NumberFormatter` — diff `lib/src/core/number_formatter.dart` vs `lib/src/shared/core/formatters/number_formatter.dart`, merge into canonical, convert legacy to export shim
- [X] T034 [P] [US1] Resolve `RichTextFormatter` — diff `lib/src/core/rich_text_formatter.dart` vs `lib/src/shared/core/formatters/rich_text_formatter.dart`, merge into canonical, convert legacy to export shim
- [X] T035 [P] [US1] Resolve `TextDirectionHelper` — diff `lib/src/core/text_direction_helper.dart` vs `lib/src/shared/core/formatters/text_direction_helper.dart`, merge into canonical, convert legacy to export shim
- [X] T036 [P] [US1] Resolve `LocalizationExceptions` — diff `lib/src/core/localization_exceptions.dart` vs `lib/src/shared/core/localization_exceptions.dart`, merge into canonical, convert legacy to export shim
- [X] T037 [P] [US1] Resolve `LanguageSelector` — diff `lib/src/widgets/language_selector.dart` vs `lib/src/features/localization/presentation/widgets/language_selector.dart`, merge into canonical, convert legacy to export shim
- [X] T038 [P] [US1] Resolve `LanguageSetupOverlay` — diff `lib/src/widgets/language_setup_overlay.dart` vs `lib/src/features/localization/presentation/widgets/language_setup_overlay.dart`, merge into canonical, convert legacy to export shim

### US1: Catalog API (included in Phase 2 so shim script passes before Phase 7)

- [X] T039a [P] [US1] Resolve `FallbackConfigurationApi` — move `lib/src/api/fallback_configuration_api.dart` to `lib/src/features/catalog/api/fallback_configuration_api.dart`, create export shim at `lib/src/api/fallback_configuration_api.dart`: `export '../features/catalog/api/fallback_configuration_api.dart';`

### US1: Canonical services

- [X] T039 [P] [US1] Resolve `LoggingService` — diff `lib/src/services/logging_service/logging_service.dart` vs `lib/src/shared/services/logging/logging_service.dart`, merge into canonical, convert legacy to export shim

**Checkpoint**: Run `flutter analyze --no-fatal-infos` + `dart fix --apply` + `dart format --set-exit-if-changed .` + `flutter analyze --no-fatal-infos` + `flutter test` + `dart run tool/check_shim_exports.dart` (must pass — all 38 modules export-only, including `src/api/`). Commit as Phase 2.

---

## Phase 3: User Story 2 — Feature Boundary Compliance (Priority: P1) 🎯 MVP

**Goal**: Catalog depends on localization through domain contracts only — no imports of `localization/data/` or `localization/presentation/`.

**Independent Test**: `rg "import.*features/localization/(data|presentation)" lib/src/features/catalog/` returns empty.

### Implementation for User Story 2

- [X] T040 [US2] Read `catalog_flutter_app.dart` and `catalog/l10n/catalog_localizations.dart` — identify what from `LocalizationService` and `DictionaryLocalizationsDelegate` is needed (methods, types).
- [X] T041 [US2] Create abstract contract `lib/src/features/localization/domain/contracts/localization_service_contract.dart` with the API surface catalog needs. **MUST NOT import `localization/data/` or `localization/presentation/`** (Constitution §VII).
- [X] T042 [US2] Update `lib/src/features/localization/data/repositories/localization_service.dart` to implement `LocalizationServiceContract`.
- [X] T043 [US2] Update `lib/src/features/catalog/presentation/screens/catalog_flutter_app.dart` — replace `localization/data/` import with `localization/domain/contracts/localization_service_contract.dart`; inject or resolve `LocalizationService` as the contract type.
- [X] T043a [US2] Create domain contract `lib/src/features/localization/domain/contracts/dictionary_localizations_contract.dart` for delegate types catalog needs (no presentation imports in domain file).
- [X] T043b [US2] Refactor `lib/src/features/catalog/l10n/catalog_localizations.dart` — replace `localization/presentation/widgets/dictionary_localizations_delegate.dart` import with domain contract; wire to presentation implementation at composition boundary.
- [X] T044 [US2] Verify: `rg "import.*features/localization/(data|presentation)" lib/src/features/catalog/` returns empty.
- [X] T045 [US2] Run `flutter analyze --no-fatal-infos` + `flutter test` per constitution §X. Commit as Phase 3.

---

## Phase 4: User Story 3 — CLI and Internal Imports Use Canonical Paths (Priority: P2)

**Goal**: `bin/` and in-package `lib/src/**` (non-shim) import canonical feature/shared paths while public shim paths remain available for external consumers.

**Independent Test**: `rg "import.*src/utils/" bin/ lib/src/features/ lib/src/shared/` returns empty; `rg "import.*src/catalog/" bin/ lib/src/features/ lib/src/shared/` returns empty.

### Implementation for User Story 3

- [X] T046 [US3] Update `bin/anas_cli.dart` imports — replace `src/catalog/catalog.dart` with `src/features/catalog/catalog.dart`, replace `src/utils/conversion_helper.dart` with `src/features/migration/data/helpers/conversion_helper.dart`, replace `src/utils/migration_helper.dart` with `src/features/migration/data/helpers/migration_helper.dart`, replace `src/utils/migration_validation_helper.dart` with `src/features/migration/data/helpers/migration_validation_helper.dart`, replace `src/utils/translation_file_parser.dart` with `src/shared/utils/translation_file_parser.dart`, replace `src/utils/arb_interop.dart` with `src/shared/utils/arb_interop.dart`, replace `src/utils/translation_validator.dart` with `src/shared/utils/translation_validator.dart`.
- [X] T047 [US3] Update `bin/generate_dictionary.dart` import — replace `src/utils/codegen_utils.dart` with `src/shared/utils/codegen_utils.dart`.
- [X] T048 [US3] Update `bin/validate_translations.dart` import — replace `src/utils/translation_validator.dart` with `src/shared/utils/translation_validator.dart`.
- [X] T049 [US3] Update in-package `lib/src/features/**` and `lib/src/shared/**` files still importing `package:anas_localization/src/utils/` or `src/catalog/` — convert to relative canonical paths (e.g. `conversion_helper.dart` → `shared/utils/arb_interop.dart`).
- [X] T050 [US3] Verify canonical imports: `rg "import.*src/utils/" bin/ lib/src/features/ lib/src/shared/` and `rg "import.*src/catalog/" bin/ lib/src/features/ lib/src/shared/` both return empty.
- [X] T051 [US3] Run `flutter analyze --no-fatal-infos` + `flutter test`. Commit as Phase 4.

---

## Phase 5: User Story 4 — Documented Structure Rules (Priority: P2)

**Goal**: Contributors can read one document explaining folder roles and allowed import directions.

**Independent Test**: `doc/reference/file-structure.md` includes folder roles and import rules; CLAUDE.md references it.

### Implementation for User Story 4

- [X] T052 [US4] Create `doc/reference/file-structure.md` with: folder roles (`features/`, `shared/`, `core/`, shim folders), module placement rules (single-feature → `features/<feature>/`, cross-feature → `shared/`), import direction rules (per contracts/import-rules.md boundary table), and full module inventory from `data-model.md`.
- [X] T053 [US4] Update `CLAUDE.md` (project root) to reference `doc/reference/file-structure.md` in the architecture or contributing section.
- [X] T054 [US4] Run `flutter analyze --no-fatal-infos`. Commit as Phase 5.

---

## Phase 6: User Story 5 — Mirror Tests Under test/features/ (Priority: P2)

**Goal**: Test files live under `test/features/<feature>/` or `test/shared/` matching the lib layout.

**Independent Test**: All tests pass from repo root; no orphaned files remain in flat `test/*.dart` (except `test/contract/` and `test/e2e/`).

### Implementation for User Story 5

- [X] T055 [US5] Create directory structure: `test/features/catalog/`, `test/features/localization/`, `test/features/migration/`, `test/shared/`.
- [X] T056 [US5] Move 8 `test/catalog_*_test.dart` files to `test/features/catalog/`. Update imports to `package:anas_localization/...` per spec.md test code style.
- [X] T057 [US5] Move to `test/features/localization/`: 8 `test/locale_*_test.dart`, 3 `test/localization_*_test.dart`, `test/localization_test.dart`, 2 `test/fallback_*_test.dart`, `test/translation_loader_integration_test.dart`, 2 `test/dictionary_*_test.dart`. Update imports.
- [X] T058 [US5] Move 2 `test/migration_*_test.dart` files to `test/features/migration/`. Update imports.
- [X] T059 [US5] Move `test/arb_interop_test.dart` and `test/tool_workflow_test.dart` to `test/shared/`. Update imports.
- [X] T060 [US5] Verify no orphaned test files in flat `test/*.dart`: `ls test/*.dart` should return empty (only subdirectories remain, plus `test/contract/` and `test/e2e/`).
- [X] T061 [US5] Run `flutter test` — all 29 moved tests discovered and pass from new locations. Commit as Phase 6.

---

## Phase 7: User Story 6 — Verify Catalog API Public Exports (Priority: P3)

**Goal**: Confirm `FallbackConfigurationApi` relocation (done in T039a) preserves public package exports. No file moves in this phase.

**Independent Test**: `lib/anas_localization.dart` still exports `FallbackConfigurationApi`; `src/api/` is export-only shim pointing to `features/catalog/api/`.

### Implementation for User Story 6

- [X] T062 [US6] Verify T039a outcome: canonical at `lib/src/features/catalog/api/fallback_configuration_api.dart`; `lib/src/api/fallback_configuration_api.dart` is export-only shim.
- [X] T063 [US6] Verify `lib/anas_localization.dart` and `lib/catalog.dart` export all public types (no removed exports). Update `lib/anas_localization.dart` to canonical export path if beneficial (shim must still resolve for legacy imports).
- [X] T064 [US6] Run `flutter analyze --no-fatal-infos` + `flutter test`. Commit as Phase 7.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, documentation, and regression guard verification.

- [X] T066 Run `dart run tool/check_shim_exports.dart` — all legacy files must be export-only (exit 0).
- [X] T067 Run `dart format --set-exit-if-changed .` — must pass (constitution §X).
- [X] T068 Run `flutter analyze --no-fatal-infos` — must report 0 issues.
- [X] T069 Run `flutter test` — must pass.
- [X] T070 Run `flutter test --coverage` — validate `coverage/lcov.info` exists per `dart-collect-coverage` skill.
- [X] T071 Run `cd tool/catalog_app && flutter test` and `cd example && flutter test` — sub-project tests must pass.
- [X] T072 Run `flutter pub publish --dry-run` — must pass; verify `lib/anas_localization.dart` and `lib/catalog.dart` exports unchanged.
- [X] T073 Final boundary check: `rg "import.*features/localization/(data|presentation)" lib/src/features/catalog/` — must return empty.
- [X] T074 Final import check: `rg "import.*src/utils/" bin/ lib/src/features/ lib/src/shared/` and `rg "import.*src/catalog/" bin/ lib/src/features/ lib/src/shared/` — must both return empty.
- [X] T075 Update `specs/008-lib-structure-consolidation/spec.md` success criteria checkboxes — mark all as complete.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — can start immediately
- **Phase 2 (Foundational/Duplicates)**: Depends on Phase 1 (regression guard must exist). **BLOCKS all user stories.**
- **Phase 3 (US2 — Boundary)**: Depends on Phase 2 completion
- **Phase 4 (US3 — CLI)**: Depends on Phase 2 completion
- **Phase 5 (US4 — Docs)**: Depends on Phase 2 completion
- **Phase 6 (US5 — Tests)**: Depends on Phase 2 completion
- **Phase 7 (US6 — API)**: Depends on Phase 2 completion
- **Phase 8 (Polish)**: Depends on ALL user stories being complete

### User Story Dependencies

- **US1 (P1)**: Covered by Phase 2 (duplicate resolution). Complete after Phase 2.
- **US2 (P1)**: Can start after Phase 2. No dependency on other stories.
- **US3 (P2)**: Can start after Phase 2. No dependency on other stories.
- **US4 (P2)**: Can start after Phase 2. No dependency on other stories.
- **US5 (P2)**: Can start after Phase 2. No dependency on other stories.
- **US6 (P3)**: Relocation in Phase 2 (T039a); export verification in Phase 7. Depends on Phase 2.

### Within Each User Story

- Follow constitution §X workflow at every checkpoint: `dart format --set-exit-if-changed .` → `flutter analyze --no-fatal-infos` → `flutter test`
- Verify all three before committing each phase

### Parallel Opportunities

- Phases 3–7 (US2–US6) can all proceed in parallel after Phase 2 completes
- Within Phase 2, duplicate resolution tasks for independent file pairs can proceed in parallel (e.g., catalog duplicates vs. localization duplicates vs. shared/utils duplicates)

---

## Parallel Example: User Story 1 (Duplicate Resolution)

```bash
# After Phase 1 completes, launch independent duplicate pairs in parallel:
Task: "Resolve CatalogRepository (T003)"
Task: "Resolve CatalogStateStore (T004)"
Task: "Resolve TranslationLoader (T015)"
Task: "Resolve translation_file_parser (T021)"
# Each touches different files — no conflicts
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (regression guard + CI wiring)
2. Complete Phase 2: Foundational — all divergent pairs resolved, legacy shims in place
3. **STOP and VALIDATE**: `flutter analyze --no-fatal-infos` + `flutter test` + `dart run tool/check_shim_exports.dart`
4. Commit Phase 2

### Incremental Delivery

1. Phase 1 + Phase 2 → Foundation ready, US1 complete → Commit
2. Phase 3 (US2) → Boundary fixed → Commit
3. Phase 4 (US3) → CLI imports canonical → Commit
4. Phase 5 (US4) → Docs updated → Commit
5. Phase 6 (US5) → Tests reorganized → Commit
6. Phase 7 (US6) → API export verification → Commit
7. Phase 8 (Polish) → Final validation → Commit

### Parallel Team Strategy

With multiple developers after Phase 2:

- **Developer A**: Phase 3 (US2 — boundary fix)
- **Developer B**: Phase 4 (US3 — CLI imports) + Phase 5 (US4 — docs)
- **Developer C**: Phase 6 (US5 — test reorg) + Phase 7 (US6 — API export verification)
- All converge at Phase 8 (Polish) for final validation

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each phase ends with a CI checkpoint: `dart format --set-exit-if-changed .` + `flutter analyze --no-fatal-infos` + `flutter test`
- Rollback strategy: `git revert HEAD` if any phase fails CI
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
- Skills to follow: `dart-run-static-analysis`, `flutter-apply-architecture-best-practices`, `dart-fix-runtime-errors`, `flutter-add-widget-test`, `dart-collect-coverage`
