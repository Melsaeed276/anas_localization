# Tasks: Arabic Language Localization Support

**Input**: Design documents from `/specs/002-arabic-localization-support/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Not explicitly requested in the spec; independent test criteria are manual/acceptance per user story.

**Organization**: Tasks grouped by user story for independent implementation and validation.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story (US1–US10)
- Include exact file paths in descriptions

## Path Conventions

- **Package**: `lib/`, `lib/src/core/`, `lib/src/features/localization/`, `lib/src/shared/`, `lib/src/widgets/`, `bin/`, `test/`, `example/`, `tool/catalog_app/` at repo root (per plan.md)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify project structure and dependencies align with plan; no new project creation.

- [X] T001 Verify lib structure (lib/src/core/, lib/src/features/localization/, lib/src/shared/, lib/src/widgets/) and pubspec.yaml dependencies (intl, flutter_localizations) per plan.md
- [X] T002 [P] Add supported Arabic regions constant or metadata (SA, EG, AE, MA, DZ, TN, LB, JO, IQ) in lib/src/features/localization/ or lib/src/shared/ for locale resolution and docs

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core types and resolution behavior that ALL user stories depend on. No user story work can start until this phase is complete.

**⚠️ CRITICAL**: Complete Phase 2 before starting any user story phase.

- [X] T003 Define UserContext type (locale, gender, formality, regionalVariant) with defaults (gender=male, variant=MSA) in lib/src/features/localization/domain/entities/ or lib/src/core/
- [X] T004 Implement canonical fallback order (plural→other, gender→other, variant→MSA, then base/key) in a single resolution path used by both type-safe and raw-key access in lib/src/features/localization/
- [X] T005 Ensure translation loader or registry notifies listeners when a locale asset finishes loading; ensure app-level localization state (e.g. AnasLocalization or LocalizationService) triggers rebuild/notifyListeners so UI refreshes after async load (lib/src/core/ or lib/src/features/localization/)
- [X] T006 Update PluralRules._getArabicPluralForm to use n % 100 for few/many (CLDR alignment) in lib/src/shared/utils/plural_rules.dart
- [X] T007 Expose resolution API that accepts key, context (UserContext), optional overrides, optional params (e.g. count), and returns resolved string; use same path for Dictionary and raw-key (lib/src/features/localization/ or lib/src/core/)

**Checkpoint**: Foundation ready — user story implementation can begin

---

## Phase 3: User Story 1 – Correct Reading Direction and Layout (P1) 🎯 MVP

**Goal**: RTL layout and bidirectional text when Arabic is active; mixed content (numbers, URLs, emails) does not break layout.

**Independent Test**: Set app language to Arabic; verify all screens and mixed text render RTL; validate by visual inspection or native reader.

- [X] T008 [P] [US1] Document RTL usage (AnasDirectionalityWrapper, AnasTextDirection) and when to wrap app/screens in doc/get-started/setup-and-guidelines.md or specs/002-arabic-localization-support/quickstart.md
- [X] T009 [US1] Ensure example app applies Directionality from current locale when Arabic (e.g. wrap with AnasDirectionalityWrapper or equivalent) in example/lib/
- [X] T010 [US1] Ensure Catalog UI applies RTL when locale is Arabic in tool/catalog_app/ or lib/src/features/catalog/

**Checkpoint**: US1 complete — RTL and mixed content work in example and Catalog

---

## Phase 4: User Story 2 – Count-Dependent Messages Use Correct Plural Form (P1)

**Goal**: Six Arabic plural forms (zero, one, two, few, many, other) resolved by count with count substitution. Plural rules follow CLDR (n%100 for few/many).

**Independent Test**: For a pluralized key, pass 0, 1, 2, 5, 15, 100 and verify correct form and substituted count.

- [X] T011 [US2] Wire resolution to PluralRules.getPluralForm(count, locale) and look up plural form in translation entry; substitute count placeholder in lib/src/features/localization/
- [X] T012 [US2] Support six plural forms (zero, one, two, few, many, other) in asset loaders (ARB/JSON) and in Dictionary getPluralData/resolution in lib/src/features/localization/ and lib/src/shared/utils/arb_interop.dart or equivalent
- [X] T013 [US2] Ensure type-safe dictionary and raw-key resolution both use same plural resolution path (contract resolution-api.md) in lib/

**Checkpoint**: US2 complete — plural resolution and count substitution work for Arabic

---

## Phase 5: User Story 3 – Gender-Appropriate Wording (P1)

**Goal**: Messages with male/female variants resolve by user context gender (default male when unset).

**Independent Test**: Set gender to masculine then feminine; verify gendered strings (e.g. welcome, your account) show correct form.

- [X] T014 [US3] Add gender variant support to asset schema and loaders (e.g. key_male/key_female or nested) per contracts/asset-schema-arabic.md in lib/src/shared/utils/ and loaders
- [X] T015 [US3] Resolve by gender from UserContext with fallback gender→other in the single resolution path in lib/src/features/localization/
- [X] T016 [US3] Support combined count+gender forms where present; fallback when form missing per canonical order in lib/src/features/localization/

**Checkpoint**: US3 complete — gender resolution and fallback work

---

## Phase 6: User Story 4 – Numbers, Dates, and Times Match Region (P2)

**Goal**: Eastern vs Western Arabic numerals and separators by region; dates/times with Arabic weekday/month names and AM/PM labels.

**Independent Test**: Set locale to ar_SA and ar_MA; verify number and date/time format and labels.

- [X] T017 [P] [US4] Use full Locale (e.g. ar_SA, ar_MA) in NumberFormat/DateFormat in lib/src/shared/core/formatters/number_formatter.dart and date_time_formatter (or lib/src/core/ equivalents)
- [X] T018 [US4] Document supported Arabic regions and numeral behavior (Eastern/Western) in doc/ or specs/002-arabic-localization-support/quickstart.md
- [X] T019 [US4] Ensure date/time formatter uses Arabic weekday and month names and AM/PM labels for Arabic locale in lib/src/shared/core/formatters/ or lib/src/core/

**Checkpoint**: US4 complete — numbers and dates/times format correctly for Arabic regions

---

## Phase 7: User Story 5 – Currency Amounts Formatted Correctly (P2)

**Goal**: Currency symbol/code position and numeral system match locale.

**Independent Test**: Display fixed amount in local Arab currency and USD; verify symbol position and numerals.

- [X] T020 [US5] Ensure AnasNumberFormatter.formatCurrency uses full locale for symbol position and numerals in lib/src/shared/core/formatters/number_formatter.dart (or lib/src/core/number_formatter.dart)
- [X] T021 [US5] Document currency formatting for Arabic locales in quickstart or doc/

**Checkpoint**: US5 complete — currency formatting correct for Arabic

---

## Phase 8: User Story 6 – Regional Variant and Formality (P2)

**Goal**: Optional regional variant (MSA, Gulf, Egyptian) and formality (formal/informal); fallback variant→MSA.

**Independent Test**: Switch MSA vs dialect and formal vs informal; verify key phrases change where variants exist.

- [X] T022 [US6] Add variant and formality to asset schema and loaders (suffix or nested keys) per contracts/asset-schema-arabic.md in lib/src/shared/ and loaders
- [X] T023 [US6] Resolve by regionalVariant and formality from UserContext with fallback variant→MSA, formality→single form in resolution path in lib/src/features/localization/
- [X] T024 [US6] Document variant and formality in quickstart and asset schema in doc/ or contracts

**Checkpoint**: US6 complete — variant and formality resolution and fallback work

---

## Phase 9: User Story 7 – Honorifics and Titles (P2)

**Goal**: Title + name in Arabic with correct gender form (e.g. الدكتور/الدكتورة); unknown title → name only or generic.

**Independent Test**: Display "Dr. Ahmed" and "Dr. Fatima"; verify Arabic title matches gender.

- [X] T025 [P] [US7] Add honorific map (e.g. Dr., Mr., Mrs., Engineer → male/female Arabic strings) in lib/src/features/localization/ or lib/src/shared/
- [X] T026 [US7] Implement honorific resolver (title + gender → string; unknown → name only or generic) and expose for use in resolution or display in lib/
- [X] T027 [US7] Document honorific usage in quickstart or doc/

**Checkpoint**: US7 complete — honorifics resolve correctly

---

## Phase 10: User Story 8 – Fallback When Translations or Context Are Missing (P2)

**Goal**: Canonical fallback always yields valid message; optional string type triggers CLI/Catalog warnings when required form missing.

**Independent Test**: Omit one plural form, one gender form, leave gender unset; verify fallback and optional warnings.

- [X] T028 [US8] Add optional string type (e.g. plural, numeric, date) to translation entry model and asset format in lib/src/features/localization/ and loaders per data-model.md and contracts
- [X] T029 [US8] In CLI validation (bin/ or lib/), emit warning when key has type and required form is missing (e.g. "key X, type plural, should have 'many' configured") per FR-012
- [X] T030 [US8] In Catalog UI, show missing-form warnings for typed keys where required form is missing in lib/src/features/catalog/ or tool/catalog_app/
- [X] T031 [US8] Document fallback order and optional type/warnings in contracts and quickstart

**Checkpoint**: US8 complete — fallback and warnings behave per spec

---

## Phase 11: User Story 9 – Search and Sort in Arabic (P3)

**Goal**: Arabic alphabetical sort and search normalization (equivalent character forms, optional diacritics).

**Independent Test**: Sort list of Arabic strings; search with one hamza form and verify variants match.

- [X] T032 [P] [US9] Implement or wire Arabic sort helper (locale-aware collation or sort key) using intl or platform in lib/src/shared/ or lib/src/features/localization/
- [X] T033 [US9] Implement search normalization for Arabic (e.g. hamza equivalence, optional diacritics) for matching in lib/src/shared/ or lib/
- [X] T034 [US9] Document Arabic sort and search in quickstart or doc/

**Checkpoint**: US9 complete — sort and search work for Arabic

---

## Phase 12: User Story 10 – Accessibility and Input (P3)

**Goal**: Screen reader order and number announcement; Arabic name and locale-appropriate phone number validation and display.

**Independent Test**: Use screen reader in Arabic; enter Arabic name and regional phone number; verify acceptance and display.

- [X] T035 [P] [US10] Document or ensure semantics and reading order for Arabic (Flutter defaults where sufficient) in doc/ or example
- [X] T036 [US10] Add Arabic name validation (allowed character set, length) and use in validation/display in lib/src/shared/utils/ or lib/src/features/localization/
- [X] T037 [US10] Add locale-appropriate phone number validation for supported regional formats and display in lib/
- [X] T038 [US10] Document accessibility and input in quickstart or doc/

**Checkpoint**: US10 complete — accessibility and input validated

---

## Phase 13: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, validation of quickstart, and cleanup.

- [X] T039 [P] Run through specs/002-arabic-localization-support/quickstart.md steps and fix any gaps in implementation or docs
- [X] T040 [P] Update doc/reference/features.md or main docs to mention Arabic support (RTL, plurals, gender, variant, formality, numerals, honorifics, fallback) per constitution
- [X] T041 Code cleanup and ensure no duplicate resolution paths; verify type-safe and raw-key use same resolution (Constitution I)
- [X] T042 Ensure CLI validate remains CI-ready and Arabic string-type warnings are surfaced per Constitution II

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1 — **blocks all user stories**.
- **Phases 3–12 (User Stories)**: Depend on Phase 2. Can proceed in priority order (US1→US2→US3 then P2 stories, then P3) or in parallel if staffed.
- **Phase 13 (Polish)**: Depends on completed user story phases.

### User Story Dependencies

- **US1 (P1)**: After Phase 2 only.
- **US2, US3 (P1)**: After Phase 2; may share resolution path from Phase 2.
- **US4–US8 (P2)**: After Phase 2; may depend on resolution path and context.
- **US9, US10 (P3)**: After Phase 2; independent of each other.

### Within Each User Story

- Implementation tasks in order listed; [P] tasks within a phase can run in parallel where no dependency is stated.

### Parallel Opportunities

- T002, T008, T017, T025, T032, T035, T039, T040: marked [P] (different files or docs).
- After Phase 2, US1–US10 can be worked in parallel by different owners.
- Within Phase 2, T003 and T006 can be done in parallel; T004, T005, T007 build on context/resolution.

---

## Parallel Example: User Story 1

```text
T008: Document RTL in doc/get-started/ or quickstart
T009: Example app Directionality when Arabic
T010: Catalog RTL when Arabic
(T008 can run in parallel with T009/T010; T009 and T010 are independent.)
```

---

## Implementation Strategy

### MVP First (User Stories 1–3)

1. Complete Phase 1: Setup  
2. Complete Phase 2: Foundational  
3. Complete Phase 3: US1 (RTL)  
4. Complete Phase 4: US2 (Plurals)  
5. Complete Phase 5: US3 (Gender)  
6. **STOP and VALIDATE**: Independent tests for US1–US3  
7. Demo/deploy if ready  

### Incremental Delivery

1. Setup + Foundational → resolution and context ready  
2. US1 → RTL validated  
3. US2 → Plurals validated  
4. US3 → Gender validated  
5. US4–US8 → Formatting, currency, variant, formality, honorifics, fallback/warnings  
6. US9–US10 → Search/sort, accessibility/input  
7. Polish → Quickstart and docs  

### Parallel Team Strategy

- Phase 2 completed together.  
- Then: Owner A (US1–US3), Owner B (US4–US6), Owner C (US7–US8), Owner D (US9–US10); integrate and run Polish.

---

## Notes

- [P] = different files or no blocking dependency.  
- [USn] = task belongs to User Story n for traceability.  
- Each user story is independently testable per spec acceptance scenarios.  
- Commit after each task or logical group.  
- Resolution API and fallback order must stay in one shared path (type-safe + raw-key).
