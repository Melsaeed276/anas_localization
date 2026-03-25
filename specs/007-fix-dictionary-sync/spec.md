# Feature Specification: Fix Dictionary Sync

**Feature Branch**: `[007-fix-dictionary-sync]`  
**Created**: 2026-03-25  
**Status**: Draft  
**Input**: User description: "this needed updates."

## Clarifications

### Session 2026-03-25

- Q: Which approach should the “dictionary sync” fix target? (A=regenerate outputs only, B=fix generator only, C=update example only, D=do both A and B) → A: D (do both A and B).

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - Regenerate Dictionary Accessors (Priority: P1)

When developers regenerate the typed dictionary API from translation assets, the example app should compile and access the expected translation entries using the typed getters/methods it references; this fix also includes making generator behavior future-safe so future regenerations stay synchronized.

**Why this priority**: This prevents a broken developer experience and blocks verification of both runtime and generated localization features.

**Independent Test**: Regenerate the typed dictionary from the translation assets used by the example app, then run repository static analysis and confirm the example compiles without missing-translation accessor errors.

**Acceptance Scenarios**:

1. **Given** the example translation assets are present and the typed dictionary has been regenerated after applying the sync fix (including any generator improvements), **When** the example app is built, **Then** all typed translation entries referenced by the example are available.
2. **Given** the translation assets contain parameterized templates and nested/dotted key paths, **When** the example app accesses those entries via the typed API, **Then** resolved text matches the intended translations and placeholder substitution behavior.

---

### User Story 2 - Runtime Lookup Without Generation Still Works (Priority: P2)

Developers should be able to resolve translations at runtime without generating the typed dictionary, including resolving nested/dotted keys, substituting parameters, and applying fallbacks.

**Why this priority**: Runtime lookup is a first-class advertised capability; breaking it undermines the no-generation workflow.

**Independent Test**: Run the runtime-lookup-focused automated tests that validate dotted key lookup, parameter substitution, and fallback behavior.

**Acceptance Scenarios**:

1. **Given** a runtime dictionary is created from translation assets without generating a typed dictionary, **When** a developer resolves both flat and dotted nested keys, **Then** the correct translated strings are returned.
2. **Given** translation templates include placeholders, **When** parameters are provided or omitted, **Then** placeholder substitution behaves consistently with package runtime-lookup rules (including missing-parameter behavior).

---

### User Story 3 - Remove Example Static Analysis Failures (Priority: P3)

The example app and generated dictionary outputs should not introduce static analysis failures or warnings, so CI and publish checks remain clean.

**Why this priority**: Even if features work, failing quality gates blocks delivery and increases maintenance cost.

**Independent Test**: Run repository static analysis and confirm it completes successfully with no example-related failures.

**Acceptance Scenarios**:

1. **Given** the example app code and generated dictionary outputs are updated, **When** repository static analysis runs, **Then** there are no analysis errors.
2. **Given** previously reported example-related warnings exist, **When** the code is updated, **Then** those warnings are resolved or aligned with the project's lint policy.

---

*(No additional user stories in this scope.)*

### Edge Cases

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right edge cases.
-->

- What happens when a translation key is missing: the system should return the configured fallback (or the key identifier when no fallback is provided).
- What happens for deeply nested dotted key paths: resolution should traverse all segments correctly.
- What happens when placeholder parameters include optional/required marker syntax: substitution should follow runtime lookup rules and never produce malformed output.
- What happens when parameter values are non-string types: substitution should still render a sensible string representation.

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

- **FR-001**: System MUST keep the typed dictionary API surface synchronized with the translation keys used by the example app by (1) regenerating the current typed outputs and (2) ensuring generator behavior produces the expected accessor set in future regenerations.
- **FR-002**: System MUST ensure typed accessors correctly reflect parameterized templates, including placeholder markers and nested parameter substitution behavior.
- **FR-003**: System MUST ensure nested/dotted key resolution semantics are consistent between runtime lookup mode and the typed dictionary mode.
- **FR-004**: System MUST preserve runtime key-lookup functionality without requiring dictionary generation, including dotted key resolution, placeholder substitution, and fallbacks.
- **FR-005**: System MUST keep documentation examples consistent with the actual public APIs exercised by the example app and runtime lookup mode.
- **FR-006**: System MUST ensure repository automated quality gates (static analysis and test suite) pass without failures after updates.

- **Acceptance Criteria Mapping**:
  - User Story 1 validates **FR-001** and **FR-002**.
  - User Story 2 validates **FR-003** and **FR-004**.
  - User Story 1 and User Story 2 validate **FR-005**.
  - User Story 3 validates **FR-006**.

### Key Entities *(include if feature involves data)*

- **Translation Assets**: locale-specific structured key/value data used to resolve messages (including nested objects and templates with placeholders).
- **Typed Dictionary API Surface**: the generated set of typed getters/methods available to application code.
- **Runtime Dictionary Lookup**: the runtime mechanism to resolve keys and apply placeholder substitution without typed generation.
- **Example Application**: a sample consumer used to validate the end-to-end developer experience.

### Dependencies & Assumptions

- **Dependencies**: the translation assets and example translation keys; the regeneration workflow that produces the typed dictionary; the repository's automated static analysis and test suite.
- **Assumptions**: placeholder substitution behavior in typed mode matches existing runtime lookup behavior; missing keys follow configured fallback rules.

## Success Criteria *(mandatory)*

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: Repository static analysis completes successfully with no errors and no example-related failures.
- **SC-002**: The full automated test suite completes successfully with all tests passing, including runtime-lookup coverage.
- **SC-003**: The example application builds/runs without missing typed translation accessors and displays correct text for the demo features it demonstrates.
- **SC-004**: Documentation snippets related to typed and runtime access match the actual APIs available after regeneration (no stale getter/method names).
