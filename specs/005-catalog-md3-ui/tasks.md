# Tasks: Catalog UI Design and Stability

**Feature**: Catalog UI Design and Stability (`005-catalog-md3-ui`)  
**Spec**: `specs/005-catalog-md3-ui/spec.md`  
**Plan**: `specs/005-catalog-md3-ui/plan.md`  

All tasks follow the required checklist format:

```text
- [ ] T001 [P?] [US?] Description with file path
```

---

## Phase 1 – Setup (project & environment)

- [X] T001 Ensure Flutter/Dart toolchain and dependencies for the Catalog are installed and up to date (Flutter `>=3.19.0`, Dart `>=3.3.0`, `intl`, `flutter_localizations`, `yaml`) in the workspace toolchain config.  
- [X] T002 Create or verify the `lib/src/catalog/` directory structure (`models/`, `widgets/`, `state/`) matches the implementation plan, adding missing folders if needed.  
- [X] T003 Configure `tool/catalog_app/` or `example/lib/catalog_demo.dart` (whichever is used) to host the Catalog UI and depend on shared Catalog widgets from `lib/src/catalog/`.  
- [X] T004 Wire the Catalog host entrypoint (`tool/catalog_app/lib/main.dart` or `example/lib/catalog_demo.dart`) to call `runApp` with a `ThemeData` that sets `useMaterial3: true` and references the shared Catalog widget tree.  
- [X] T005 Add or update localization asset paths for the Catalog in the host app (e.g. point to `assets/lang/` or the configured source) and ensure they are listed in `pubspec.yaml`.  

---

## Phase 2 – Foundational Catalog infrastructure

- [X] T006 Define core Catalog UI state classes in `lib/src/catalog/state/` using the entities from `data-model.md` (e.g. `CatalogThemeState`, `CatalogViewportState`, `EntryFormState`, `ValidationPanelState`, `CatalogSessionState`, `LanguageConfigurationState`).  
- [X] T007 Implement a Catalog state management mechanism in `lib/src/catalog/state/` (provider/Riverpod/other existing pattern in the repo) that exposes the above state and actions (load, save, validate, change locale) to widgets.  
- [X] T008 Create or update integration between Catalog state and existing localization repositories/services in `lib/src/shared/` or `lib/src/catalog/models/` so the Catalog can load and save localization entries through a single abstraction.  
- [X] T009 Add contract-level tests in `test/contract/` that exercise the key behavior guarantees from `contracts/catalog-ui-contract.md` without tying to specific widgets (e.g. data types, variants, validation, RTL, language configuration, add-new-key, add-language, error handling).  
- [X] T010 [P] Add placeholder or skeleton Catalog widgets in `lib/src/catalog/widgets/` (list, detail, validation panel, language configuration) that compile and are wired to dummy state so later tasks can iterate on concrete behavior.  

---

## Phase 3 – User Story 1 (P1): Consistent, stable Catalog experience

- [X] T011 [US1] Implement the main Catalog scaffold widget in `lib/src/catalog/widgets/catalog_shell.dart` that lays out the key list and a detail area (Quickstart/actions when no key is selected, entry detail when a key is selected).  
- [X] T012 [P] [US1] Implement a `CatalogQuickstartPanel` in `lib/src/catalog/widgets/catalog_quickstart_panel.dart` that matches the spec's empty/initial state (quick actions, slogan) and is shown in the detail area when no key is selected.  
- [X] T013 [P] [US1] Implement a `CatalogEntryDetail` widget in `lib/src/catalog/widgets/catalog_entry_detail.dart` that shows entry values, data type, variants, and note when a key is selected.  
- [X] T014 [US1] Ensure navigation between list, detail, and configuration sections uses a single MD3-compliant navigation pattern (e.g. navigation rail/tabs) defined in `lib/src/catalog/widgets/catalog_shell.dart` so layout and controls feel unified.  
- [X] T015 [US1] Add widget tests in `test/catalog/` that open the Catalog, navigate between sections, edit an entry, and save, asserting that the layout structure (list + detail), primary flows, and visible controls remain stable across rebuilds.  
- [X] T016 [US1] Add regression test cases in `test/catalog/` that simulate a version upgrade or re-run of the Catalog and confirm core flows (list, filter, edit, save) still work without missing or duplicated controls.

---

## Phase 4 – User Story 2 (P1): Surface all specified localization features

- [X] T017 [US2] Implement data-type–aware entry editors in `lib/src/catalog/widgets/entry_editors/` so that, based on `EntryFormState.dataType`, the Catalog shows appropriate input widgets (string, numerical, gender, date, dateTime) per `FR-003`.  
- [X] T018 [P] [US2] Implement variant editing widgets in `lib/src/catalog/widgets/variants/` to display and edit plural, gender, and regional overrides where the underlying model supports them, wired to `LocalizationEntry.valueOrVariantMap`.  
- [X] T019 [P] [US2] Implement the validation inline summary/indicator for the current entry in `lib/src/catalog/widgets/validation_inline.dart`, bound to `EntryFormState.validationSummary`.  
- [X] T020 [US2] Implement the dedicated validation panel widget in `lib/src/catalog/widgets/validation_panel.dart` showing all validation messages from `ValidationPanelState`, with grouping or pagination for many messages.  
- [X] T021 [US2] Implement the language configuration screen in `lib/src/catalog/widgets/language_configuration.dart` that exposes enabled locales, allows adding/removing languages (at least Arabic and English), and shows language-specific settings fields per `LanguageConfigurationState`.  
- [X] T022 [P] [US2] Implement the add-new-key flow in `lib/src/catalog/widgets/add_key_dialog.dart` enforcing required default language string, optional inputs per enabled locale, and warnings for empty locales, integrated with the underlying repository.  
- [X] T023 [P] [US2] Implement the add-language flow in `lib/src/catalog/widgets/add_language_dialog.dart` that presents the supported language list and appends the chosen language to enabled locales and Catalog UI.  
- [X] T024 [US2] Implement search and filter behavior in the Catalog list widget (`lib/src/catalog/widgets/catalog_list.dart`) so matches include key path, translation values (per locale), and notes.  
- [X] T025 [US2] Implement entry notes UI in `lib/src/catalog/widgets/entry_note_field.dart` so each key can view and edit its note, stored with the entry and searchable in the list.  
- [X] T026 [US2] Add widget/integration tests in `test/catalog/` that validate the presence and behavior of data-type–specific inputs, variants editing, validation (inline + panel), add-new-key, add-language, notes, and empty state per the spec and contract.  

---

## Phase 5 – User Story 3 (P2): Accessible and responsive Catalog

- [X] T027 [US3] Implement responsive layout logic in `lib/src/catalog/widgets/catalog_shell.dart` using `MediaQuery`/`LayoutBuilder` and `CatalogViewportState` to adapt the list/detail layout down to 360px width without blocking core tasks.  
- [X] T028 [P] [US3] Add focus and keyboard navigation handling across Catalog widgets (list, detail, dialogs, language configuration) to satisfy keyboard accessibility requirements, updating widgets under `lib/src/catalog/widgets/` as needed.  
- [X] T029 [P] [US3] Add semantic labels, roles, and grouping for screen readers in relevant widgets (list items, buttons, forms, validation summaries, configuration controls) using Flutter's semantics APIs.  
- [X] T030 [US3] Add tests in `test/catalog/` verifying that at 360px width the main workflow (open list, select entry, edit, save) is possible without horizontal scrolling blocking critical controls.  
- [X] T031 [US3] Add accessibility-focused widget/integration tests in `test/catalog/` that exercise keyboard navigation and screen-reader semantics for primary flows.

---

## Phase 6 – User Story 4 (P2): MD3 design system compliance

- [X] T032 [US4] Define a dedicated Catalog `ThemeData` and `ColorScheme` configuration in `lib/src/catalog/theme/catalog_theme.dart` that uses MD3 color roles and text styles, reusing existing MD3 theme patterns in the repo where possible.  
- [X] T033 [P] [US4] Apply MD3 component themes (buttons, text fields, cards, navigation, dialogs) consistently across Catalog widgets in `lib/src/catalog/widgets/`, eliminating one-off styling that conflicts with the design system.  
- [X] T034 [P] [US4] Implement button emphasis rules in all Catalog dialogs and primary surfaces (exactly one primary, appropriate secondary/tertiary) by updating buttons in `lib/src/catalog/widgets/` to use MD3 variants that match the Button UX table.  
- [X] T035 [US4] Add visual review aids or golden tests in `test/catalog/` (where appropriate) that capture main Catalog screens under the MD3 theme for later regression checking.  
- [X] T036 [US4] Add documentation comments or MD3 reference notes (in Markdown under `specs/005-catalog-md3-ui/` or inline where appropriate) pointing to the design system references used for color roles, typography, and components.  

---

## Phase 7 – User Story 5 (P2): Easy to implement and edit

- [X] T037 [US5] Refactor or organize Catalog widgets into a small, well-defined set of reusable building blocks in `lib/src/catalog/widgets/` (e.g. list, detail, configuration, dialogs, validation) to avoid duplication and tangled logic.  
- [X] T038 [P] [US5] Introduce or align on a consistent naming and folder convention for Catalog widgets and state (e.g. `catalog_shell.dart`, `catalog_list.dart`, `language_configuration.dart`, `entry_editors/`, `variants/`) and update existing files to match.  
- [X] T039 [P] [US5] Add high-level documentation in `specs/005-catalog-md3-ui/` or `lib/src/catalog/README.md` that explains how the Catalog is structured (list, detail, edit, configuration) and how new features should be added without breaking the structure.  
- [X] T040 [US5] Add a small “change a label or add a button” example task in `test/catalog/` or doc form that demonstrates how to make localized UI changes with minimal impact, validating the easy-to-edit requirement.  

---

## Phase 8 – Cross-cutting: Error handling, multi-tab, performance, and codegen

- [X] T041 Implement error handling for save/load in Catalog state (`lib/src/catalog/state/`) and surface errors in widgets (`lib/src/catalog/widgets/`) so that failed saves keep form data and failed loads show errors while retaining previously loaded state.  
- [X] T042 Implement multi-tab detection in `CatalogSessionState` and the underlying repository so that external changes trigger a reload prompt, and saving without reload follows last-save-wins behavior per the spec.  
- [X] T043 [P] Ensure list virtualization or equivalent lazy rendering is used in `lib/src/catalog/widgets/catalog_list.dart` (e.g. `ListView.builder`) and that search is implemented efficiently over the in-memory set to keep the Catalog responsive up to ~5,000 entries.  
- [X] T044 [P] Wire the Catalog save flow to trigger dictionary model regeneration (or to invoke the existing codegen workflow) so that changes in the Catalog are reflected in the generated dictionary model per `FR-027`, updating `example` or tooling scripts as needed.  
- [X] T045 Add performance-oriented tests or benchmarks (where practical) in `test/catalog/` or a separate perf harness to validate list/search responsiveness with a simulated ~5,000-entry dataset.  

---

## Dependencies & Story Order

- **Foundational**: Phase 1 (T001–T005) and Phase 2 (T006–T010) must be completed before user-story phases.  
- **User Story Order**:
  - P1: **US1** (Phase 3) and **US2** (Phase 4) can proceed in parallel once foundational tasks are complete, with coordination on shared widgets and state.
  - P2: **US3** (Phase 5), **US4** (Phase 6), and **US5** (Phase 7) depend on core Catalog structures from US1/US2 but can be interleaved by area (accessibility, theming, structure).  
- **Cross-cutting**: Phase 8 can start once basic flows from US1/US2 are present, but finalization should wait until other phases stabilize.  

---

## Parallel Execution Examples

- **Example 1**: After T006–T010, run T017–T018 (data-type and variants widgets) in parallel with T021–T023 (language configuration and add-language flows) because they touch different widget sets.  
- **Example 2**: While T027 implements core responsive layout, T028–T029 can proceed in parallel to add keyboard navigation and semantics to already-built widgets.  
- **Example 3**: T032–T033 (Catalog theme and MD3 components) can proceed in parallel with T037–T038 (structure refactors) as long as conflicting files are coordinated.  

---

## MVP Scope Recommendation

- **Minimum Viable Product (MVP)**:  
  - Complete Phases 1–2, **US1** (Phase 3), and the core of **US2** (Phase 4) sufficient to:  
    - Run the Catalog with MD3 theming  
    - View a list of entries and a detail panel  
    - Edit entries with data-type–aware inputs  
    - See inline and panel validation  
    - Add new keys and languages, including basic language configuration  
  - Defer advanced responsiveness/accessibility, full MD3 polish, and structural refinements (US3–US5, parts of Phase 8) to subsequent iterations.  

