# English Requirements Checklist: English Language Localization Alignment

**Purpose**: Validate the completeness, clarity, consistency, and release readiness of the English-localization requirements across the spec, plan, and design artifacts
**Created**: 2026-03-15
**Feature**: [spec.md](../spec.md)

**Note**: This checklist tests the quality of the written requirements for English localization. It is a release-gate checklist for reviewers, not an implementation test plan.

## Requirement Completeness

- [ ] CHK001 Are the required English locale variants fully enumerated and used consistently across all docs (`en`, `en_US`, `en_GB`, `en_CA`, `en_AU`)? [Completeness, Spec §FR-006, Spec §FR-019, Research §Decision 1]
- [ ] CHK002 Are the allowed first-release regional override categories completely specified without leaving room for undocumented override types? [Completeness, Spec §FR-007, Spec §FR-017, Contract §Allowed Override Categories]
- [ ] CHK003 Are all required English formatting domains explicitly covered in the requirements set: date, time, number, and currency? [Completeness, Spec §FR-008, Spec §FR-009, Spec §FR-010, Spec §FR-011]
- [ ] CHK004 Are the required authored-wording cases for irregular plurals, uncountables, articles, contractions, and tone all documented in one coherent requirement set? [Completeness, Spec §FR-004, Spec §FR-005, Spec §FR-014, Spec §User Story 4]
- [ ] CHK005 Does the documentation fully define what a regional override file may omit versus what must still be present in the shared base `en` file? [Completeness, Contract §Layering Contract, Contract §Validation Expectations, Data Model §EnglishTranslationEntry]

## Requirement Clarity

- [ ] CHK006 Is the English plural rule stated with enough precision that `1`, `-1`, `1.0`, `1.5`, and `0` can be classified unambiguously from the requirements alone? [Clarity, Spec §FR-002, Spec §FR-003, Contract §Plural behavior]
- [ ] CHK007 Is the phrase "selected vocabulary differences" defined concretely enough to distinguish it from out-of-scope regional tone variants? [Ambiguity, Spec §FR-017, Contract §Allowed Override Categories]
- [ ] CHK008 Is the requirement for `en_CA` to use "mostly UK-style spelling" precise enough to determine which spellings are mandatory versus merely examples? [Ambiguity, Spec §FR-018, Spec §Clarifications, Data Model §EnglishLocale]
- [ ] CHK009 Are the default time-format requirements for `en_US`, `en_CA`, `en_GB`, and `en_AU` expressed with enough specificity to avoid conflicting interpretations during implementation? [Clarity, Spec §FR-009, Spec §Clarifications]
- [ ] CHK010 Is the distinction between shared base `en` content and regional overrides described clearly enough that reviewers can tell when a value belongs in `en.json` versus a regional file? [Clarity, Spec §FR-015, Spec §FR-019, Contract §Layering Contract]

## Requirement Consistency

- [ ] CHK011 Do the spec, research notes, data model, and contracts all use the same base-locale strategy (`en` as canonical base, regional files as overlays) without contradiction? [Consistency, Spec §FR-019, Research §Decision 1, Data Model §EnglishLocale, Contract §Layering Contract]
- [ ] CHK012 Do the plural requirements stay consistent across the spec, research, data model, runtime contract, and quickstart example with no mismatch between `int` and `num` expectations? [Consistency, Spec §FR-002, Research §Decision 2, Data Model §CountSensitiveEntry, Contract §Generated Dictionary Contract]
- [ ] CHK013 Do the documents consistently state that Arabic-only requirements remain out of scope for English, rather than partially reintroducing them through validation or tooling language? [Consistency, Spec §FR-012, Spec §FR-013, Spec §Out of scope, Contract §Validation Contract]
- [ ] CHK014 Are the validator and generator expectations aligned so `en` remains the canonical reference locale in both workflows? [Consistency, Spec §FR-016, Research §Decision 3, Contract §Validation Contract, Plan §Tooling Alignment]
- [ ] CHK015 Do the plan and contracts preserve the same deterministic locale fallback story described in the spec, with no separate English-only fallback path implied? [Consistency, Research §Decision 4, Contract §Runtime Contract, Plan §Runtime Alignment]

## Acceptance Criteria Quality

- [ ] CHK016 Are the success criteria specific enough to prove requirement quality for plural behavior, regional overrides, and validation boundaries without relying on unspoken test assumptions? [Acceptance Criteria, Spec §SC-001, Spec §SC-002, Spec §SC-004]
- [ ] CHK017 Can the requirement "reduce duplicated region-specific entries for unchanged content to zero in the representative test set" be objectively interpreted from the documentation as written? [Measurability, Spec §SC-003]
- [ ] CHK018 Are the plan-level completion signals detailed enough to determine when Phase 0, Phase 1, and Phase 2 planning outputs are complete and internally coherent? [Acceptance Criteria, Plan §Milestones, Plan §Next Steps]

## Scenario Coverage

- [ ] CHK019 Are primary requirements fully specified for both of the major English scenario classes: count-sensitive messages and regional locale variants? [Coverage, Spec §User Story 1, Spec §User Story 2]
- [ ] CHK020 Are authoring scenarios covered for both shared-base content creation and selective regional override creation? [Coverage, Quickstart §Workflow, Data Model §State Transitions]
- [ ] CHK021 Are validation and generation scenario requirements defined for both raw-key access and generated dictionary access, rather than only one access mode? [Coverage, Contract §Generated Dictionary Contract, Plan §Runtime Alignment, Constitution §Dual access modes]
- [ ] CHK022 Are documentation requirements defined for how example-app assets participate in the English feature, or is that scope intentionally limited and stated clearly? [Coverage, Plan §Asset and Example Alignment, Quickstart §5, Assumption or Gap]

## Edge Case Coverage

- [ ] CHK023 Are the boundary cases for zero, negative counts, decimals, and very large values fully addressed in the requirement set with no missing English plural edge class? [Edge Case Coverage, Spec §Edge Cases, Spec §FR-002, Spec §FR-003]
- [ ] CHK024 Is fallback behavior specified for missing regional overrides, missing base English keys, and placeholder mismatches as distinct cases rather than one blended fallback rule? [Edge Case Coverage, Contract §Layering Contract, Contract §Failure Handling]
- [ ] CHK025 Are the requirements clear about what happens when a regional file contains unsupported categories such as tone-only overrides or Arabic-style plural/gender structures? [Edge Case Coverage, Contract §Allowed Override Categories, Contract §Validation Contract, Gap]
- [ ] CHK026 Are the requirements explicit about whether mixed structures across locales are acceptable when one locale uses a plural map and another uses a plain string for the same key? [Ambiguity, Plan §Tooling Alignment, Contract §Validation Contract, Gap]

## Non-Functional Requirements

- [ ] CHK027 Is the phrase "feel instant" or equivalent performance language translated into sufficiently reviewable non-functional expectations for locale switching and message resolution? [Clarity, Spec §Success Criteria, Plan §Technical Context]
- [ ] CHK028 Are determinism requirements for fallback, validation, and generation strong enough to rule out platform-specific or run-order-specific behavior? [Non-Functional Requirements, Constitution §III, Contract §Failure Handling]
- [ ] CHK029 Are maintainability constraints explicit enough to prevent accidental expansion of first-release English scope beyond spelling, selected vocabulary, and formatting? [Non-Functional Requirements, Spec §FR-017, Spec §Out of scope, Plan §Constraints]

## Dependencies & Assumptions

- [ ] CHK030 Are the assumptions about `intl`, existing locale normalization, and `en`-as-reference behavior documented and traceable enough that implementation does not depend on hidden repository knowledge? [Dependencies & Assumptions, Plan §Dependencies, Research §Decision 3]
- [ ] CHK031 Are the boundaries between package assets and example-app assets specified clearly enough to avoid inconsistent requirement interpretation during generation and review? [Dependencies & Assumptions, Plan §Project Structure, Plan §Asset and Example Alignment, Quickstart §5]
- [ ] CHK032 Does the documentation clearly separate requirement facts from implementation preferences where the current repo already has duplicate utility surfaces under `lib/src/shared/utils/` and `lib/src/utils/`? [Assumption, Plan §Tooling Alignment]

## Ambiguities & Conflicts

- [ ] CHK033 Is there any conflict between the spec's requirement for regional formatting support and the contracts' focus on string/file layering, leaving formatting-source responsibilities underdefined? [Conflict, Spec §FR-008, Spec §FR-011, Contract §English Locale Assets, Gap]
- [ ] CHK034 Do the docs define whether regional formatting differences are represented only by locale-aware formatter behavior, only by overridden strings, or by both where needed? [Ambiguity, Spec §FR-008, Spec §FR-009, Contract §Allowed Override Categories, Gap]
- [ ] CHK035 Is a reviewer able to distinguish normative requirements from examples in the quickstart and contracts, especially for sample JSON snippets and spelling examples? [Clarity, Quickstart §Workflow, Contract §Value Shape Contract]
- [ ] CHK036 Are all out-of-scope boundaries for English written strongly enough to prevent scope creep into Arabic-specific validation, runtime, or asset requirements during implementation review? [Boundary Clarity, Spec §Out of scope, Spec §FR-012, Spec §FR-013]

## Notes

- This checklist was created as a new file for the English-localization domain.
- Use it as a release-gate review of the written requirements across `spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/`, and `quickstart.md`.
- Items marked with `[Gap]`, `[Ambiguity]`, `[Conflict]`, or `[Assumption]` should trigger a documentation update before implementation is considered complete.
