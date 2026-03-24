# Tasks: Hierarchical Locale Fallback System with Custom Locale Support

**Input**: Design documents from `/specs/006-locale-hierarchical-fallback/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/catalog-service-api.md, quickstart.md

**Tests**: Included as per constitution requirement (Principle IX: Testing Discipline)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

**Total Tasks**: 72 (Setup: 8, Foundational: 7, US1: 19, US2: 18, US3: 13, Polish: 7)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Domain entities**: `lib/src/features/catalog/domain/entities/`
- **Domain services**: `lib/src/features/catalog/domain/services/`
- **Use cases**: `lib/src/features/catalog/use_cases/`
- **Presentation**: `lib/src/features/catalog/presentation/screens/`
- **Data/Repositories**: `lib/src/features/catalog/data/repositories/` and `lib/src/features/localization/data/repositories/`
- **Shared utilities**: `lib/src/shared/utils/`
- **Core exceptions**: `lib/src/core/`
- **Tests**: `test/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create new files and extend existing exceptions/utilities needed by all user stories

- [X] T001 [P] Create ISO locale code data constants in lib/src/shared/utils/iso_locale_codes.dart (ISO 639-1/639-2 language codes, ISO 3166-1 country codes, with names)
- [X] T002 [P] Add InvalidLocaleCodeException to lib/src/core/localization_exceptions.dart
- [X] T003 [P] Add CircularFallbackException to lib/src/core/localization_exceptions.dart
- [X] T004 [P] Create LocaleValidationResult entity in lib/src/features/catalog/domain/entities/locale_validation_result.dart
- [X] T005 [P] Create LocaleValidationErrorType enum in lib/src/features/catalog/domain/entities/locale_validation_result.dart
- [X] T006 [P] Create FallbackChain entity in lib/src/features/catalog/domain/entities/fallback_chain.dart
- [X] T007 [P] Create LanguageGroup entity in lib/src/features/catalog/domain/entities/language_group.dart
- [X] T008 [P] Create CustomLocale entity in lib/src/features/catalog/domain/entities/custom_locale.dart

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Extend core models and services that ALL user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [X] T009 Extend CatalogState in lib/src/features/catalog/domain/entities/catalog_models.dart with languageGroupFallbacks and customLocaleDirections maps
- [X] T010 Update CatalogState.fromJson() to parse new fields with defaults in lib/src/features/catalog/domain/entities/catalog_models.dart
- [X] T011 Update CatalogState.toJson() to serialize new fields in lib/src/features/catalog/domain/entities/catalog_models.dart
- [X] T012 Update CatalogState.copyWith() for new fields in lib/src/features/catalog/domain/entities/catalog_models.dart
- [X] T013 Extend CatalogStateStore to load/save languageGroupFallbacks in lib/src/features/catalog/data/repositories/catalog_state_store.dart
- [X] T014 Extend CatalogStateStore to load/save customLocaleDirections in lib/src/features/catalog/data/repositories/catalog_state_store.dart
- [X] T015 Create LocaleValidationService in lib/src/features/catalog/domain/services/locale_validation_service.dart with validateLocaleCode(), isValidLanguageCode(), isValidCountryCode()

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Configure Language Group Fallback for Regional Variants (Priority: P1)

**Goal**: Allow users to configure language group fallbacks so regional variants inherit translations from a designated locale within the same language

**Independent Test**: Create two regional locales (e.g., `en_US`, `en_GB`), set one as fallback, remove a translation from the other, verify it retrieves from fallback locale

### Tests for User Story 1

- [X] T016 [P] [US1] Unit test for circular fallback detection in test/locale_fallback_circular_test.dart (FR-007)
- [X] T017 [P] [US1] Unit test for fallback chain resolution with language group in test/locale_fallback_chain_test.dart (FR-003, FR-004)
- [X] T018 [P] [US1] Unit test for same-language-group constraint validation in test/locale_fallback_validation_test.dart (FR-002)
- [X] T019 [P] [US1] Unit test for fallback cleanup when fallback locale is deleted in test/locale_fallback_cleanup_test.dart (FR-006)
- [X] T019a [P] [US1] Unit test for preventing regional locale as language group fallback in test/locale_fallback_validation_test.dart (FR-010)

### Implementation for User Story 1

- [X] T020 [US1] Implement hasCircularFallback() helper function in lib/src/features/catalog/use_cases/catalog_service.dart (FR-007)
- [X] T021 [US1] Implement isSameLanguageGroup() helper function in lib/src/features/catalog/use_cases/catalog_service.dart (FR-002)
- [X] T021a [US1] Implement isRegionalLocale() helper function to detect regional variants in lib/src/features/catalog/use_cases/catalog_service.dart (FR-010)
- [X] T022 [US1] Implement getLanguageGroups() method in lib/src/features/catalog/use_cases/catalog_service.dart (FR-001)
- [X] T023 [US1] Implement setLanguageGroupFallback() method in lib/src/features/catalog/use_cases/catalog_service.dart with validation (FR-005, FR-007, FR-010)
- [X] T024 [US1] Implement removeLanguageGroupFallback() method in lib/src/features/catalog/use_cases/catalog_service.dart (FR-006)
- [X] T025 [US1] Implement getFallbackChain() method in lib/src/features/catalog/use_cases/catalog_service.dart (FR-003)
- [X] T026 [US1] Extend resolveLocaleFallbackChain() to accept languageGroupFallbacks parameter in lib/src/features/localization/data/repositories/localization_service.dart (FR-004)
- [X] T027 [US1] Add language group fallback step to fallback chain resolution in lib/src/features/localization/data/repositories/localization_service.dart (FR-004)
- [X] T028 [US1] Implement clearFallbackReferencesOnDelete() to clean up when a fallback locale is deleted in lib/src/features/catalog/use_cases/catalog_service.dart (FR-006)
- [X] T029 [US1] Add GET /api/language-groups endpoint handler in lib/src/features/catalog/server/catalog_backend.dart (FR-001)
- [X] T030 [US1] Add POST /api/language-group-fallback endpoint handler in lib/src/features/catalog/server/catalog_backend.dart (FR-005)
- [X] T031 [US1] Add DELETE /api/language-group-fallback endpoint handler in lib/src/features/catalog/server/catalog_backend.dart (FR-006)
- [X] T032 [US1] Add GET /api/fallback-chain/{locale} endpoint handler in lib/src/features/catalog/server/catalog_backend.dart (FR-003)

**Checkpoint**: Language group fallback configuration is fully functional via API. Can verify by setting fallbacks and checking translation resolution.

---

## Phase 4: User Story 2 - Add Custom Locale with Manual Text Direction (Priority: P2)

**Goal**: Allow users to add locales not in the predefined list by entering locale codes with ISO validation and manual RTL/LTR direction selection

**Independent Test**: Enter a valid locale code (e.g., `es_MX`), select LTR, verify locale is created with correct direction. Enter invalid code, verify validation error.

### Tests for User Story 2

- [ ] T033 [P] [US2] Unit test for ISO language code validation (valid/invalid) in test/locale_validation_test.dart (FR-011)
- [ ] T034 [P] [US2] Unit test for ISO country code validation (valid/invalid) in test/locale_validation_test.dart (FR-011)
- [ ] T035 [P] [US2] Unit test for locale code normalization (hyphen to underscore) in test/locale_validation_test.dart (FR-012)
- [ ] T036 [P] [US2] Unit test for duplicate locale detection in test/locale_validation_test.dart (FR-013)
- [ ] T037 [P] [US2] Unit test for display name generation in test/locale_validation_test.dart (FR-014)

### Implementation for User Story 2

- [ ] T038 [US2] Implement addCustomLocale() method in lib/src/features/catalog/use_cases/catalog_service.dart (FR-015)
- [ ] T039 [US2] Implement getLocaleDirection() method to check customLocaleDirections then predefined list in lib/src/features/catalog/use_cases/catalog_service.dart (FR-008, FR-009)
- [ ] T040 [US2] Add POST /api/validate-locale endpoint handler in lib/src/features/catalog/presentation/api/catalog_api_handlers.dart (FR-011)
- [ ] T041 [US2] Extend POST /api/locale endpoint to accept direction field in lib/src/features/catalog/presentation/api/catalog_api_handlers.dart (FR-015)
- [ ] T042 [US2] Add custom locale tab state management to showAddLocaleDialog() in lib/src/features/catalog/presentation/screens/catalog_label_helpers.dart (FR-008)
- [ ] T043 [US2] Implement _buildCustomLocaleTab() widget with locale code TextField in lib/src/features/catalog/presentation/screens/catalog_label_helpers.dart (FR-008)
- [ ] T044 [US2] Add RTL/LTR SegmentedButton to custom locale tab in lib/src/features/catalog/presentation/screens/catalog_label_helpers.dart (FR-009)
- [ ] T045 [US2] Implement real-time validation with debouncing (300ms) in custom locale tab in lib/src/features/catalog/presentation/screens/catalog_label_helpers.dart (FR-011)
- [ ] T046 [US2] Display validation feedback (error/success indicator, display name preview) in custom locale tab in lib/src/features/catalog/presentation/screens/catalog_label_helpers.dart (FR-014)
- [ ] T047 [US2] Wire custom locale submission to CatalogService.addCustomLocale() in lib/src/features/catalog/presentation/screens/catalog_label_helpers.dart (FR-015)

### Widget Tests for User Story 2

- [ ] T048 [US2] Widget test for custom locale tab visibility and interaction in test/catalog_custom_locale_test.dart
- [ ] T049 [US2] Widget test for RTL/LTR toggle behavior in test/catalog_custom_locale_test.dart
- [ ] T050 [US2] Widget test for validation feedback display in test/catalog_custom_locale_test.dart

**Checkpoint**: Custom locale creation is fully functional. Can add locales via dialog with ISO validation and direction selection.

---

## Phase 5: User Story 3 - Visualize Fallback Chain and Language Groups (Priority: P3)

**Goal**: Provide visual feedback showing language groups, fallback relationships, and fallback chain tooltips

**Independent Test**: Configure a language group fallback, view locale list, verify visual indicators show: language group badge, fallback designation, and tooltip displaying complete fallback chain.

### Tests for User Story 3

- [ ] T051 [P] [US3] Widget test for language group visual grouping in test/catalog_locale_settings_test.dart (FR-016)
- [ ] T052 [P] [US3] Widget test for fallback locale badge display in test/catalog_locale_settings_test.dart (FR-017)
- [ ] T053 [P] [US3] Widget test for fallback chain tooltip content in test/catalog_locale_settings_test.dart (FR-018)
- [ ] T054 [P] [US3] Widget test for custom locale badge display in test/catalog_locale_settings_test.dart (FR-019)
- [ ] T054a [P] [US3] Widget test for expand/collapse behavior of language group sections in test/catalog_locale_settings_test.dart (FR-016, C6)

### Implementation for User Story 3

- [ ] T055 [US3] Create CatalogLocaleSettings screen in lib/src/features/catalog/presentation/screens/catalog_locale_settings.dart (FR-016)
- [ ] T056 [US3] Implement language group list view with expandable sections in lib/src/features/catalog/presentation/screens/catalog_locale_settings.dart (FR-016)
- [ ] T057 [US3] Add "Group Fallback" badge widget for designated fallback locale in lib/src/features/catalog/presentation/screens/catalog_locale_settings.dart (FR-017)
- [ ] T058 [US3] Add "Custom" badge widget for custom locales in lib/src/features/catalog/presentation/screens/catalog_locale_settings.dart (FR-019)
- [ ] T059 [US3] Implement fallback chain tooltip on locale hover in lib/src/features/catalog/presentation/screens/catalog_locale_settings.dart (FR-018)
- [ ] T060 [US3] Add fallback configuration selector (radio/dropdown) within language group in lib/src/features/catalog/presentation/screens/catalog_locale_settings.dart (FR-020)
- [ ] T061 [US3] Wire language group settings to CatalogService methods in lib/src/features/catalog/presentation/screens/catalog_locale_settings.dart
- [ ] T062 [US3] Integrate CatalogLocaleSettings into catalog navigation/menu in lib/src/features/catalog/presentation/screens/catalog_screen.dart

**Checkpoint**: All visualization features are functional. Users can see language groups, fallback relationships, and chain tooltips.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final integration, documentation, and comprehensive testing

- [ ] T063 [P] Integration test: full flow - add custom locale, configure fallback, verify resolution in test/catalog_locale_integration_test.dart
- [ ] T064 [P] Add logging for fallback chain resolution in lib/src/features/localization/data/repositories/localization_service.dart
- [ ] T065 [P] Add logging for locale validation errors in lib/src/features/catalog/domain/services/locale_validation_service.dart
- [ ] T066 Verify backward compatibility: load existing catalog_state.json without new fields
- [ ] T067 Run dart format and dart analyze, fix any issues
- [ ] T068 Update package exports if new public entities are exposed
- [ ] T069 Manual testing: verify all acceptance scenarios from spec.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - US1, US2, US3 can proceed in parallel after Foundational
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Independent of US1
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Uses LanguageGroup/FallbackChain entities from US1 implementation but can work with stubs

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Entities before services
- Services before use cases
- Use cases before presentation
- API endpoints before UI that calls them

### Parallel Opportunities

**Setup Phase (8 tasks, all parallelizable)**:
- T001-T008 can all run in parallel (different files)

**Foundational Phase (7 tasks)**:
- T009-T012 sequential (same file: catalog_models.dart)
- T013-T014 parallel after T012 (catalog_state_store.dart)
- T015 parallel with T013-T014 (locale_validation_service.dart)

**User Story 1 (19 tasks)**:
- T016-T019a all parallel (test files, 5 tests)
- T020-T021a parallel (helper functions, 3 functions)
- T022-T025 sequential (service methods building on each other)
- T026-T027 sequential (same method extension)
- T029-T032 parallel (different endpoints)

**User Story 2 (18 tasks)**:
- T033-T037 all parallel (test files)
- T038-T041 can work sequentially
- T042-T047 sequential (same dialog file)
- T048-T050 parallel (test files)

**User Story 3 (13 tasks)**:
- T051-T054a all parallel (test files, 5 tests)
- T055-T062 sequential (building same screen)

---

## Parallel Example: Setup Phase

```bash
# Launch all Setup tasks together (8 parallel tasks):
Task T001: "Create ISO locale code data constants in lib/src/shared/utils/iso_locale_codes.dart"
Task T002: "Add InvalidLocaleCodeException to lib/src/core/localization_exceptions.dart"
Task T003: "Add CircularFallbackException to lib/src/core/localization_exceptions.dart"
Task T004: "Create LocaleValidationResult entity in lib/src/features/catalog/domain/entities/locale_validation_result.dart"
Task T005: "Create LocaleValidationErrorType enum in lib/src/features/catalog/domain/entities/locale_validation_result.dart"
Task T006: "Create FallbackChain entity in lib/src/features/catalog/domain/entities/fallback_chain.dart"
Task T007: "Create LanguageGroup entity in lib/src/features/catalog/domain/entities/language_group.dart"
Task T008: "Create CustomLocale entity in lib/src/features/catalog/domain/entities/custom_locale.dart"
```

## Parallel Example: User Story 1 Tests

```bash
# Launch all US1 tests together (5 parallel tasks):
Task T016: "Unit test for circular fallback detection in test/locale_fallback_circular_test.dart"
Task T017: "Unit test for fallback chain resolution with language group in test/locale_fallback_chain_test.dart"
Task T018: "Unit test for same-language-group constraint validation in test/locale_fallback_validation_test.dart"
Task T019: "Unit test for fallback cleanup when fallback locale is deleted in test/locale_fallback_cleanup_test.dart"
Task T019a: "Unit test for preventing regional locale as language group fallback in test/locale_fallback_validation_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (8 tasks)
2. Complete Phase 2: Foundational (7 tasks)
3. Complete Phase 3: User Story 1 (17 tasks)
4. **STOP and VALIDATE**: Test language group fallback independently
5. Deploy/demo if ready - core fallback functionality works

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready (15 tasks)
2. Add User Story 1 → Test independently → Deploy (34 tasks total) - **MVP!**
3. Add User Story 2 → Test independently → Deploy (52 tasks total) - Custom locales
4. Add User Story 3 → Test independently → Deploy (65 tasks total) - Full visualization
5. Add Polish → Final release (72 tasks total)

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Language Group Fallbacks)
   - Developer B: User Story 2 (Custom Locales)
   - Developer C: User Story 3 (Visualization) - can use stubs initially
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [USx] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Constitution requires tests (Principle IX) - included in each story
