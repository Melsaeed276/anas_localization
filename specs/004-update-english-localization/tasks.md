# Tasks: English Localization Alignment

**Input**: Design documents from `/specs/004-update-english-localization/`
**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Tests**: Include regression and workflow test updates because the plan explicitly requires runtime, validator, generator, and locale-fallback verification for this feature.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., `US1`, `US2`, `US3`, `US4`)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the English regional asset scaffolding and example fixtures referenced by the plan and contracts

- [X] T001 Create package regional English asset files in `assets/lang/en_US.json`, `assets/lang/en_GB.json`, `assets/lang/en_CA.json`, and `assets/lang/en_AU.json`
- [X] T002 [P] Create example regional English asset files in `example/assets/lang/en_US.json`, `example/assets/lang/en_GB.json`, `example/assets/lang/en_CA.json`, and `example/assets/lang/en_AU.json`
- [X] T003 [P] Align regeneration references for `example/lib/generated/dictionary.dart` in `specs/004-update-english-localization/plan.md` and `specs/004-update-english-localization/quickstart.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the shared runtime/tooling contract that all English user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Update English plural-form resolution to support the clarified `num` contract in `lib/src/shared/utils/plural_rules.dart`
- [X] T005 Update runtime count parsing and message resolution in `lib/src/features/localization/domain/services/message_resolver.dart`
- [X] T006 [P] Update generated plural accessor signatures and selection logic in `bin/generate_dictionary.dart`
- [X] T007 [P] Update English validation and optional plural warnings in `lib/src/shared/utils/translation_validator.dart`
- [X] T008 Update deterministic English locale fallback behavior in `lib/src/features/localization/data/repositories/localization_service.dart` and `lib/src/localization_manager.dart`
- [X] T009 [P] Align explicit English left-to-right direction handling in `lib/src/core/text_direction_helper.dart` and `lib/src/shared/core/formatters/text_direction_helper.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Correct English Plural Behavior (Priority: P1) 🎯 MVP

**Goal**: Deliver correct English singular/plural behavior for base English content, including negative and decimal counts

**Independent Test**: Resolve representative English messages for `0`, `1`, `2`, `5`, `-1`, `-2`, and `1.5` and confirm generated accessors and raw-key lookup return the same singular/plural wording

### Tests for User Story 1

- [X] T010 [P] [US1] Add English plural edge-case regression coverage in `test/localization_integration_regression_test.dart`
- [X] T011 [P] [US1] Add generated-vs-raw plural lookup coverage in `test/dictionary_runtime_lookup_test.dart`

### Implementation for User Story 1

- [X] T012 [US1] Update shared English plural and irregular-wording source entries in `assets/lang/en.json`
- [X] T013 [US1] Update example English plural and irregular-wording fixtures in `example/assets/lang/en.json`
- [X] T014 [US1] Regenerate typed English accessors in `example/lib/generated/dictionary.dart`

**Checkpoint**: User Story 1 should resolve English pluralized messages correctly and be testable on its own

---

## Phase 4: User Story 2 - Regional English Variants Feel Native (Priority: P1)

**Goal**: Deliver regional English overrides and deterministic fallback for `en_US`, `en_GB`, `en_CA`, and `en_AU`

**Independent Test**: Switch between base and regional English locales and verify spelling, selected vocabulary, date/time defaults, and fallback-to-`en` behavior work without requiring full duplicate locale files

### Tests for User Story 2

- [X] T015 [P] [US2] Add English regional fallback and normalization coverage in `test/localization_service_test.dart`
- [X] T016 [P] [US2] Add regional English workflow coverage for validation and generation in `test/tool_workflow_test.dart`
- [X] T017 [P] [US2] Add English regional locale import/export coverage in `test/arb_interop_test.dart`
- [X] T018 [P] [US2] Add English regional date/time/number/currency formatting coverage in `test/localization_integration_regression_test.dart`

### Implementation for User Story 2

- [X] T019 [P] [US2] Populate package regional override assets in `assets/lang/en_US.json`, `assets/lang/en_GB.json`, `assets/lang/en_CA.json`, and `assets/lang/en_AU.json`
- [X] T020 [P] [US2] Populate example regional override assets in `example/assets/lang/en_US.json`, `example/assets/lang/en_GB.json`, `example/assets/lang/en_CA.json`, and `example/assets/lang/en_AU.json`
- [X] T021 [US2] Finalize shared-base layering expectations in `assets/lang/en.json`, `lib/src/features/localization/data/repositories/localization_service.dart`, and `lib/src/localization_manager.dart`
- [X] T022 [US2] Update English regional date/time defaults in `lib/src/shared/core/formatters/date_time_formatter.dart`
- [X] T023 [US2] Update English number and currency formatting expectations in `lib/src/shared/core/formatters/number_formatter.dart`
- [X] T024 [US2] Regenerate typed English regional accessors in `example/lib/generated/dictionary.dart`

**Checkpoint**: User Story 2 should deliver native-feeling regional English behavior with deterministic fallback to shared `en`

---

## Phase 5: User Story 3 - English Scope Stays Simpler Than Arabic (Priority: P2)

**Goal**: Ensure English validation and runtime behavior do not inherit Arabic-only grammar requirements

**Independent Test**: Validate English locale files and runtime lookups to confirm English accepts one/other plural data and shared-base overlays without requiring Arabic-only plural or gender structures

### Tests for User Story 3

- [X] T025 [P] [US3] Add English-vs-Arabic validation regression coverage in `test/tool_workflow_test.dart`
- [X] T026 [P] [US3] Add shared-base overlay lookup coverage in `test/dictionary_runtime_lookup_test.dart`

### Implementation for User Story 3

- [X] T027 [US3] Refine English-specific validation behavior in `lib/src/shared/utils/translation_validator.dart`
- [X] T028 [US3] Keep public/shared validator surfaces aligned in `lib/src/utils/translation_validator.dart` and `lib/src/shared/utils/translation_validator.dart`
- [X] T029 [US3] Document English-scope boundaries and locale-notation guidance in `README.md`, `doc/reference/file-structure.md`, and `CHANGELOG.md`

**Checkpoint**: User Story 3 should prove English remains simpler than Arabic in both requirements and enforcement behavior

---

## Phase 6: User Story 4 - English Content Handles Common Writing Cases (Priority: P3)

**Goal**: Preserve authored English wording for irregular plurals, uncountables, articles, and tone-sensitive phrasing

**Independent Test**: Resolve representative English entries for irregular plurals, measure-based phrasing, and article-sensitive wording and confirm the authored text is returned unchanged by both runtime and generated accessors

### Tests for User Story 4

- [X] T030 [P] [US4] Add authored-English-wording regression coverage in `test/localization_test.dart`

### Implementation for User Story 4

- [X] T031 [US4] Extend shared authored-English wording entries in `assets/lang/en.json`
- [X] T032 [US4] Extend example authored-English wording fixtures in `example/assets/lang/en.json`
- [X] T033 [US4] Regenerate authored-wording accessors in `example/lib/generated/dictionary.dart`

**Checkpoint**: User Story 4 should preserve authored English wording without automatic grammar generation

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Complete end-to-end verification and synchronize feature docs with the finished task set

- [X] T034 [P] Run strict localization validation from `specs/004-update-english-localization/quickstart.md` against `assets/lang/`
- [X] T035 [P] Run dictionary generation from `specs/004-update-english-localization/quickstart.md` and verify `example/lib/generated/dictionary.dart`
- [X] T036 [P] Run package verification from `specs/004-update-english-localization/quickstart.md` covering `lib/` and `test/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - blocks all user stories
- **User Stories (Phase 3+)**: Depend on Foundational completion
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Starts after Foundational - establishes the MVP plural contract
- **User Story 2 (P1)**: Starts after Foundational - depends on the same runtime/tooling foundation but remains independently testable
- **User Story 3 (P2)**: Starts after Foundational - verifies English-scope enforcement and may reuse US1/US2 fixtures
- **User Story 4 (P3)**: Starts after Foundational - builds on the shared English asset structure but remains independently testable

### Within Each User Story

- Regression tests should be written or updated before finishing implementation for that story
- Shared runtime/tooling changes happen in Foundational before story-specific assets and docs
- Asset updates precede dictionary regeneration
- Story-specific verification should complete before moving to the next lower-priority story

### Parallel Opportunities

- `T002` and `T003` can run in parallel after `T001`
- `T006`, `T007`, and `T009` can run in parallel after `T004` while `T005`/`T008` proceed on separate files
- User-story test tasks marked `[P]` can run in parallel within each story
- Package and example asset tasks marked `[P]` can run in parallel within US2
- Final verification tasks `T034`, `T035`, and `T036` can run in parallel if the workspace is otherwise stable

---

## Parallel Example: User Story 2

```bash
# Launch regional-English verification tasks together:
Task: "Add English regional fallback and normalization coverage in test/localization_service_test.dart"
Task: "Add regional English workflow coverage for validation and generation in test/tool_workflow_test.dart"
Task: "Add English regional locale import/export coverage in test/arb_interop_test.dart"

# Launch regional asset population together:
Task: "Populate package regional override assets in assets/lang/en_US.json, assets/lang/en_GB.json, assets/lang/en_CA.json, and assets/lang/en_AU.json"
Task: "Populate example regional override assets in example/assets/lang/en_US.json, example/assets/lang/en_GB.json, example/assets/lang/en_CA.json, and example/assets/lang/en_AU.json"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. Stop and validate plural behavior independently

### Incremental Delivery

1. Setup + Foundational establish the shared runtime and tooling contract
2. User Story 1 delivers the minimum viable English behavior
3. User Story 2 adds regional English value without changing the MVP plural contract
4. User Story 3 tightens English-vs-Arabic validation boundaries
5. User Story 4 polishes authored English wording cases

### Parallel Team Strategy

1. One developer completes Foundational runtime/tooling tasks
2. A second developer can prepare package/example regional asset files once the file scaffolding exists
3. After Foundational, story-specific test and asset work can proceed in parallel by story

---

## Notes

- All tasks follow the required checkbox + ID + optional `[P]` + optional `[US#]` + exact file path format
- User-facing locale labels use hyphenated forms such as `en-US`, while internal/runtime and file-path tasks use normalized underscored forms such as `en_US`
- User stories remain independently testable even when they share foundational runtime work
- `T014`, `T024`, and `T033` intentionally regenerate `example/lib/generated/dictionary.dart` after story-specific asset changes
- Final verification tasks reference `specs/004-update-english-localization/quickstart.md` so execution uses the planned commands
