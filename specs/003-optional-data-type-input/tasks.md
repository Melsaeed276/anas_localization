# Tasks: Optional Data Type Input for Localization

**Input**: Design documents from `specs/003-optional-data-type-input/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Not explicitly requested in spec; plan mentions unit tests for validation/merge and widget tests for Catalog. Optional test tasks included in Polish phase.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story (US1–US4) for traceability
- Include exact file paths in descriptions

## Path Conventions

- **Package**: `lib/src/` (shared, features/catalog, features/localization, utils), `tool/catalog_app/` for Catalog UI, `test/` at repo root
- Paths follow plan.md structure

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Ensure structure and dependencies support data type feature; no new project.

- [x] T001 Ensure lib/src/shared/ and lib/src/features/catalog/ and lib/src/features/localization/ exist per plan in lib/
- [x] T002 [P] Add any new dev or test dependencies required for data type validation (e.g. no new deps if intl/analyzer sufficient) in pubspec.yaml

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: DataType enum, file schema read/write, and validation rules MUST be in place before any user story.

**Independent Test**: Load a JSON map containing `@dataTypes`; expect key→type map and default string when key missing. Validate one entry per type (string, numerical, gender, date, dateTime) and get pass/fail per rule.

- [x] T003 [P] Define DataType enum (string, numerical, gender, date, dateTime) and default string in lib/src/shared/data_type.dart
- [x] T004 [P] Extend translation file parser to read @dataTypes (or _meta.dataTypes) from JSON/YAML in lib/src/shared/utils/translation_file_parser.dart; return key→DataType map; entries not in map default to string
- [x] T005 Extend translation file parser to write @dataTypes when saving/exporting when any entry has type ≠ string in lib/src/shared/utils/translation_file_parser.dart
- [x] T006 Implement per-type validation rules (string: any; numerical: num.tryParse; gender: male|female case-insensitive; date: ISO 8601 date; dateTime: ISO 8601 date-time) in lib/src/shared/data_type_validator.dart (or extend lib/src/utils/translation_validator.dart)
- [x] T007 Wire parser and validator so loaded entries carry optional dataType and validator runs type rules on load; surface failures with entry key and rule in lib/src/utils/translation_validator.dart

**Checkpoint**: Foundation ready—parser reads/writes type, validator applies rules; user story implementation can begin.

---

## Phase 3: User Story 1 - Declare Data Type for Better Understanding (Priority: P1) — MVP

**Goal**: User can assign data type per entry; type is persisted and used for validation/UI/extensions. Default when absent is string.

**Independent Test**: Create or edit an entry, set data type to numerical (or other non-string), save/export; reload and confirm type is persisted and used (e.g. in validation or Catalog).

- [x] T008 [P] [US1] Extend catalog/domain entry model (or catalog_models) with optional dataType field default string in lib/src/features/catalog/domain/entities/catalog_models.dart
- [x] T009 [P] [US1] Extend localization/domain entry or dictionary-related model with optional dataType for in-memory representation in lib/src/features/localization/domain/entities/ or lib/src/core/
- [x] T010 [US1] Ensure Catalog save/export writes entry dataType into @dataTypes in the same file as values using parser in lib/src/features/catalog/
- [x] T011 [US1] Ensure load/import reads @dataTypes and populates entry dataType; missing key → string in lib/src/features/catalog/ and/or lib/src/features/localization/

**Checkpoint**: User Story 1 deliverable—declare type, persist, default string; testable via Catalog or file workflow.

---

## Phase 4: User Story 2 - Type-Based Extensions (Priority: P2)

**Goal**: For numerical (and shared) type, system provides or enables extensions (e.g. number-only input, formatting, shared rules) so working with that type is easier.

**Independent Test**: Mark two entries as numerical; confirm type-specific behavior (validation, formatting, or shared rules) applies to both.

- [x] T012 [P] [US2] Add numerical formatting/validation helper or extension used by validator and Catalog in lib/src/shared/ or lib/src/core/number_formatter.dart
- [x] T013 [US2] Apply numerical-type rules in validator and (if applicable) codegen so numerical entries use shared rules in lib/src/utils/translation_validator.dart and codegen if present
- [x] T014 [US2] Document or wire type-based extensions so multiple entries of same type benefit without per-entry config in lib/src/shared/ or doc

**Checkpoint**: Type-based extensions for numerical (and consistent behavior for other types) in place.

---

## Phase 5: User Story 3 - Catalog UI Adapts Input to Data Type (Priority: P1)

**Goal**: Catalog shows data type dropdown (default string) and type-specific value input: string→text field, numerical→number field, gender→male/female dropdown, date→date picker, date & time→date+time picker.

**Independent Test**: In Catalog, set key data type to numerical, gender, date, date & time, string; verify value input switches to correct control and restricts input.

- [x] T015 [US3] Add data type dropdown (string, numerical, gender, date, date & time; default string) to Catalog entry edit UI in tool/catalog_app/ or lib/src/features/catalog/presentation/
- [ ] T016 [US3] Implement value input switcher by dataType: text field (string), number field with decimal (numerical), dropdown male/female (gender), date picker (date), date+time picker (dateTime) in tool/catalog_app/ or lib/src/features/catalog/presentation/
- [x] T017 [US3] Persist selected data type and value on save/autosave using same-file schema in lib/src/features/catalog/
- [ ] T018 [US3] When type is numerical validate on blur/submit (parse as number); when type is gender restrict to male/female; when date/dateTime store ISO 8601; show clear error on invalid input in Catalog UI
- [ ] T019 [US3] When user changes type and current value is invalid for new type, show error and block save or revert type per contract in lib/src/features/catalog/presentation/

**Checkpoint**: Catalog UI delivers type dropdown and type-specific inputs; independently testable.

---

## Phase 6: User Story 4 - Validation and Code Generation from Localization Files (Priority: P1)

**Goal**: On file load, validate entries against data type rules and surface failures (entry + rule). Codegen applies same type rules. Import uses merge semantics (add new keys; for existing, apply file type/value when provided).

**Independent Test**: Load a file with @dataTypes and one violation (e.g. non-numeric for numerical); expect clear failure with key and rule. Run codegen and confirm type rules reflected. Import file with overlapping keys; confirm merge behavior.

- [x] T020 [US4] Run type validation on load and collect failures with entry key and rule identifier in lib/src/utils/translation_validator.dart
- [x] T021 [US4] Surface validation failures in CLI and (if applicable) Catalog with clear indication of failing entry and rule in bin/ or lib/src/features/catalog/
- [x] T022 [US4] Implement merge on import: add new keys with type/value from file; for existing keys keep existing type/value unless file provides type or value for that key then apply file data in lib/src/features/catalog/ or localization load path
- [ ] T023 [US4] Apply same data type rules in code generation so generated artifacts respect type (e.g. typed getters or validation) in lib/src/utils/codegen_utils.dart or codegen entry point
- [ ] T024 [US4] Ensure generated code/artifacts stay consistent with validation and Catalog behavior per spec FR-007 in lib/src/utils/ or codegen

**Checkpoint**: File validation, merge-on-import, and codegen aligned with data type rules.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, edge cases, and quality.

- [ ] T025 [P] Handle edge case: type changed after values exist—validate existing value against new type and surface errors or migration guidance in lib/src/features/catalog/ or validator
- [ ] T026 [P] Handle edge case: file entries without data type metadata default to string; validation and generation apply string rules in lib/src/shared/utils/translation_file_parser.dart and validator
- [ ] T027 Update quickstart.md or doc to reflect data type usage (Catalog, file schema, validation, merge); document the chosen file schema option (@dataTypes or _meta.dataTypes) in quickstart or doc in specs/003-optional-data-type-input/quickstart.md or doc/
- [ ] T028 Add unit tests for data type validation rules (string, numerical, gender, date, dateTime) and merge logic in test/ if not already covered
- [ ] T029 Run quickstart validation and confirm data type flow end-to-end

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies.
- **Phase 2 (Foundational)**: Depends on Phase 1; **blocks** all user stories.
- **Phase 3 (US1)**: Depends on Phase 2.
- **Phase 4 (US2)**: Depends on Phase 2 (and benefits from US1 model).
- **Phase 5 (US3)**: Depends on Phase 2 and US1 (entry model + persist).
- **Phase 6 (US4)**: Depends on Phase 2, US1 (load/type), and merge/validator.
- **Phase 7 (Polish)**: Depends on completion of desired user stories.

### User Story Dependencies

- **US1 (P1)**: After Foundational only; no other story required.
- **US2 (P2)**: After Foundational; can use US1 model.
- **US3 (P1)**: After Foundational + US1 (persist/load type).
- **US4 (P1)**: After Foundational + US1; merge and codegen build on parser/validator.

### Parallel Opportunities

- T003, T004 can run in parallel (enum vs parser read).
- T008, T009 can run in parallel (catalog vs localization model).
- T012 can run in parallel with other US2 tasks.
- T025, T026 can run in parallel in Polish.
- After Phase 2, US1 then US3/US4; US2 can overlap with US1/US3.

---

## Parallel Example: User Story 1

```bash
# Models in parallel:
Task: "Extend catalog/domain entry model with optional dataType in lib/src/features/catalog/domain/entities/catalog_models.dart"
Task: "Extend localization/domain entry with optional dataType in lib/src/features/localization/domain/entities/ or lib/src/core/"
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Complete Phase 1 + Phase 2 (Setup + Foundational).
2. Complete Phase 3 (US1: declare type, persist, default string).
3. **Validate**: Create/edit entry, set type, save, reload and confirm type used.
4. Optionally add US3 (Catalog UI) or US4 (validation/codegen) next.

### Incremental Delivery

1. Foundation (Phases 1–2) → then US1 (Phase 3) → test.
2. Add US3 (Catalog UI) → test independently.
3. Add US4 (validation + codegen + merge) → test independently.
4. Add US2 (type-based extensions) → test.
5. Polish (Phase 7).

### Parallel Team Strategy

- After Foundational: Developer A — US1 + US3 (declare + Catalog UI); Developer B — US4 (validation, merge, codegen); Developer C — US2 (extensions). Integrate and run full validation.

---

## Notes

- [P] = different files or no dependency on incomplete tasks.
- [USn] maps task to user story for traceability.
- Each user story phase is independently testable per spec.
- Commit after each task or logical group.
- File paths use existing lib/ and tool/catalog_app layout; adjust if your tree differs.
