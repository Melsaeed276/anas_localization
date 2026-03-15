# Tasks: Package Features and Details Document

**Input**: Design documents from `specs/001-package-features-doc/`  
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Not requested in the feature specification; no test tasks included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g. US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Documentation deliverables live under `doc/` at repository root.
- Spec and plan live under `specs/001-package-features-doc/`.
- Paths below are relative to repository root.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify doc structure and contract so the features document can be created in the right place.

- [x] T001 Verify doc structure exists: ensure `doc/reference/` exists at repository root (create if missing)
- [x] T002 Load document outline from `specs/001-package-features-doc/contracts/features-document-outline.md` for reference when writing `doc/reference/features.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Ensure the setup/guideline link target exists so the features document can link to it (FR-002).

**⚠️ CRITICAL**: User story content tasks assume this target exists; complete before Phase 3.

- [x] T003 Decide setup/guideline target: if a single consolidated "setup and guidelines" page is desired and does not exist, create `doc/get-started/setup-and-guidelines.md` at repository root with short summary and links to Install and First Run, Generate and Wrap, Validate, and (if relevant) Catalog and CLI (do not add to mkdocs in this task)
- [x] T004 If T003 created a new page, add `doc/get-started/setup-and-guidelines.md` to the Get Started section in `mkdocs.yml` at repository root; otherwise skip

**Checkpoint**: Setup/guideline target exists (either existing Get Started overview or new setup-and-guidelines.md). Features document can link to it.

---

## Phase 3: User Story 1 - Evaluate Package Fit (Priority: P1) 🎯 MVP

**Goal**: A single document that lists all package features and what each does so evaluators can decide in minutes whether anas_localization fits their project.

**Independent Test**: Give the document to someone unfamiliar with the package; they can answer "Does it support X?" and "What does Y do?" within a few minutes without opening the repo.

### Implementation for User Story 1

- [x] T005 [US1] Create `doc/reference/features.md` at repository root with H1 title (e.g. "Package features" or "anas_localization features") and one short overview paragraph for evaluators (what the package is, who it is for, link to Get Started) per contracts/features-document-outline.md
- [x] T006 [US1] Add theme group section headings (H2) to `doc/reference/features.md` in order: Access modes, CLI and tooling, Locale and fallback, Migration, Catalog, Platforms and system locale (optional: Loaders and formats) per contracts/features-document-outline.md

**Checkpoint**: Evaluators can open the document and see an overview plus empty theme sections; they can infer structure and know where to find features.

---

## Phase 4: User Story 2 - Onboard and Use Features Correctly (Priority: P2)

**Goal**: Each feature explained with "what it is / when to use it" plus minimal "how to enable" (or link) so adopters can use the document to enable one capability without guessing.

**Independent Test**: Use only this document to enable one capability (e.g. validation or locale fallback) and confirm the description matches actual behavior.

### Implementation for User Story 2

- [x] T007 [US2] Populate Access modes section in `doc/reference/features.md` with features: typed dictionary, raw string keys (mark in development if applicable); each with "what it is / when to use it", minimal "how to enable" or link to setup/guideline, per data-model.md and constitution
- [x] T008 [US2] Populate CLI and tooling section in `doc/reference/features.md` (validation, import/export, stats, catalog workflows) with per-feature descriptions and links
- [x] T009 [US2] Populate Locale and fallback section in `doc/reference/features.md` (deterministic fallback chain, platform support, system locale) with per-feature descriptions and links
- [x] T010 [US2] Populate Migration section in `doc/reference/features.md` (gen_l10n, easy_localization migration paths) with per-feature descriptions and links
- [x] T011 [US2] Populate Catalog section in `doc/reference/features.md`; mark as in development; include what it is / when to use it and link to catalog docs
- [x] T012 [US2] Populate Platforms and system locale section in `doc/reference/features.md` (iOS, Android, web, desktop; system-based language config) with descriptions and links
- [x] T013 [US2] Ensure `doc/reference/features.md` links to the setup/guideline target (Get Started overview or `get-started/setup-and-guidelines.md`) from intro and/or each theme; verify every feature has minimal "how to enable" or link per FR-002

**Checkpoint**: Adopters can look up any feature and see what it does, when to use it, and how to enable it (or where to go for steps).

---

## Phase 5: User Story 3 - Maintain a Canonical Feature Reference (Priority: P3)

**Goal**: README and doc home link to the features document; MkDocs nav includes the Features page; structure supports incremental updates when features are added or changed.

**Independent Test**: When a new capability is added to the package, a maintainer can add or update a section in the document without rewriting the whole file.

### Implementation for User Story 3

- [x] T014 [US3] Add Features page to MkDocs nav in `mkdocs.yml` at repository root (e.g. under Reference: `Features: reference/features.md` or top-level entry)
- [x] T015 [US3] Add a short "Features" subsection or bullet in README at repository root that links to the features document (or published Features page); do not duplicate the full feature list
- [x] T016 [US3] Add a link to the Features page in `doc/index.md` (e.g. under "Start with the path that matches your goal" or "Recommended next pages") so evaluators and adopters can find it

**Checkpoint**: README and doc home point to the features document; the published site shows the Features page in nav; maintainers can update one section when a feature changes.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validate links and alignment with spec; run quickstart validation.

- [x] T017 [P] Validate all links in `doc/reference/features.md` and in the setup/guideline target (internal doc links and Get Started/catalog/CLI links); fix any broken links
- [x] T018 Run validation steps from `specs/001-package-features-doc/quickstart.md` (steps 6: read as evaluator and adopter, check constitution alignment, confirm in-development features marked, confirm no broken links)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS user story content (Phases 3–4) because features doc must link to setup/guideline target.
- **User Story 1 (Phase 3)**: Depends on Foundational — creates file and structure.
- **User Story 2 (Phase 4)**: Depends on Phase 3 — populates content.
- **User Story 3 (Phase 5)**: Depends on Phase 4 — adds nav and README/doc home links.
- **Polish (Phase 6)**: Depends on Phase 5 — validate and run quickstart.

### User Story Dependencies

- **User Story 1 (P1)**: After Foundational; no dependency on other stories. Delivers evaluator-facing structure and overview.
- **User Story 2 (P2)**: After US1; populates all theme groups so adopters can use the doc. Independently testable once T005–T006 exist.
- **User Story 3 (P3)**: After US2; adds discoverability (nav, README, doc home). Independently testable.

### Within Each User Story

- US1: T005 before T006 (overview and title before section headings).
- US2: T007–T012 can be done in any order (different sections); T013 after all sections populated (link check).
- US3: T014, T015, T016 can be done in any order (different files).

### Parallel Opportunities

- T007–T012 (US2): Populating different theme sections can be parallelized if multiple editors work on different sections.
- T014, T015, T016 (US3): MkDocs nav, README, and doc/index.md are separate files — can be done in parallel.
- T017 (Polish): Link validation can run in parallel with other polish prep; T018 runs after content and links are stable.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup  
2. Complete Phase 2: Foundational  
3. Complete Phase 3: User Story 1  
4. **STOP and VALIDATE**: An evaluator can open the doc and see overview + theme structure.  
5. Optionally publish and demo the Features page (after T014).

### Incremental Delivery

1. Setup + Foundational → setup/guideline target ready  
2. Add User Story 1 → evaluators see structure and overview (MVP)  
3. Add User Story 2 → adopters can use doc for each feature  
4. Add User Story 3 → README and doc home link; nav updated  
5. Polish → links validated, quickstart run  

### Parallel Team Strategy

- One writer can own Phases 1–2, then Phase 3.  
- Phase 4: multiple writers can own different theme sections (T007–T012) in parallel.  
- Phase 5: one person can do T014–T016 in sequence or split (nav vs README vs doc home).

---

## Notes

- [P] tasks = different files or sections, no dependencies on same-phase tasks.
- [USn] label maps task to user story for traceability.
- Each user story is independently testable per Independent Test above.
- No automated test tasks; validation is manual per quickstart.md.
- Commit after each task or logical group (e.g. after each theme section populated).
