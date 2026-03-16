# Multi-Tab & Session Behavior Requirements Checklist: Catalog UI Design and Stability

**Purpose**: Validate that multi-tab/session and concurrency-related requirements in the Catalog UI spec are complete, clear, consistent, and testable.  
**Created**: 2026-03-15  
**Feature**: [spec.md](../spec.md)

## Requirement Completeness

- [ ] CHK001 Are all places where multi-tab or multi-session editing is possible explicitly identified and scoped (e.g. same machine, same user, same source file)? [Completeness, Spec Clarifications, §FR-015]
- [ ] CHK002 Is the end-to-end flow for “file changed in another tab” fully described, including detection, prompting, and user choices? [Completeness, Spec §FR-015, Edge Cases]
- [ ] CHK003 Are requirements defined for what information the reload prompt must contain (e.g. that the file changed, potential overwrite risk, actions)? [Completeness, Spec §FR-015, [Gap]]
- [ ] CHK004 Are scenarios where multiple tabs save in quick succession (near-simultaneous writes) explicitly considered or acknowledged? [Completeness, Edge Cases, [Gap]]

## Requirement Clarity

- [ ] CHK005 Is it clear **when** the Catalog checks for external changes (e.g. on focus, before save, periodic polling, file watcher)? [Clarity, Spec §FR-015, Edge Cases, [Gap]]
- [ ] CHK006 Is the “last save wins” rule clearly linked to a specific sequence (e.g. if user ignores reload and saves, then their save overwrites)? [Clarity, Spec §FR-015]
- [ ] CHK007 Is it unambiguous whether reload discards unsaved local changes, merges them, or offers options (e.g. “Reload and discard changes” vs “Cancel”)? [Clarity, Spec §FR-015, Edge Cases, [Gap]]
- [ ] CHK008 Is the supported concurrency model (“single user, multiple tabs/sessions on same machine”) explicitly distinguished from unsupported multi-user editing? [Clarity, Spec Clarifications, Assumptions]

## Requirement Consistency

- [ ] CHK009 Do all mentions of multi-tab behavior (Clarifications, Edge Cases, FR-015, Research Decision 3) agree on the same model (reload prompt + last save wins)? [Consistency, Spec §FR-015, Research]
- [ ] CHK010 Are assumptions in the Constitution about deterministic behavior and reproducible outcomes consistent with the described multi-tab behavior? [Consistency, Constitution, Spec §FR-015]
- [ ] CHK011 Are error messages and prompts for multi-tab conflicts consistent with general error handling requirements (tone, placement, clarity)? [Consistency, Spec §FR-013, §FR-015, Edge Cases]

## Scenario & Edge Case Coverage

- [ ] CHK012 Is there an explicit scenario for: “User edits in Tab A, then saves in Tab B, then returns to Tab A and saves without reloading”? [Coverage, Spec §FR-015, Edge Cases]
- [ ] CHK013 Is there a scenario for “User edits in Tab A, sees reload prompt, but chooses not to reload and continues editing”? [Coverage, Edge Cases, [Gap]]
- [ ] CHK014 Is behavior defined when the underlying file changes due to **external tools** (e.g. CLI, editor) while the Catalog is open? [Coverage, Spec §FR-015, Research, [Gap]]
- [ ] CHK015 Are rollback or recovery expectations (e.g. what if a save fails after a reload prompt) addressed or explicitly out of scope? [Coverage, Spec §FR-013, §FR-015, [Gap]]

## Dependencies & Assumptions

- [ ] CHK016 Is the mechanism for detecting file changes (OS file watcher, timestamp check, hash comparison, etc.) at least acknowledged so that requirements are realistic? [Assumption, Research, [Gap]]
- [ ] CHK017 Is it clear that multi-tab behavior MUST NOT break deterministic locale behavior or asset integrity (e.g. no partial writes or mixed versions)? [Dependency, Constitution, Spec §Assumptions]

## Ambiguities & Conflicts

- [ ] CHK018 Are there any conflicting hints between “last save wins only” and “reload prompt” that might confuse implementers (e.g. some places implying one without the other)? [Conflict, Spec §FR-015, Research]
- [ ] CHK019 Is the allowed degree of staleness (how long a tab may remain open without reloading) addressed or intentionally left unspecified? [Ambiguity, Edge Cases, [Gap]]

## Notes

- Check items off as completed: `[x]`
- Add comments or findings inline
- Reference spec sections (e.g. `Spec §FR-015`, `Spec §Edge Cases`, `Research Decision 3`) or mark `[Gap]`, `[Ambiguity]`, `[Conflict]`, `[Assumption]` as needed.

