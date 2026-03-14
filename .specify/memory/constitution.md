<!--
Sync Impact Report
==================
Version change: (none) → 1.0.0 (initial ratification)
Modified principles: N/A (initial)
Added sections: Core Principles (6), Additional Constraints, Development Workflow, Governance
Removed sections: N/A
Templates: .specify/templates/plan-template.md ✅ (Constitution Check is generic); .specify/templates/spec-template.md ✅; .specify/templates/tasks-template.md ✅
Follow-up TODOs: None
-->

# anas_localization Constitution

## Core Principles

### I. Dual access modes

Support both (a) type-safe generated dictionary APIs as the default/recommended path,
and (b) fast localization via raw string keys without generated code for quick iteration
or simple apps. Generated code, when used, remains the source of truth for keys;
raw-key access MUST use the same loading and fallback behavior.

### II. CLI and tooling

Validation, import/export (ARB/CSV/JSON), stats, and catalog workflows are exposed via CLI.
CI MUST be able to run validate (and optional profiles) for deterministic checks.

### III. Deterministic locale behavior

Locale resolution and fallback (e.g. lang_script_region → lang_script → lang_region → lang
→ fallback) MUST be documented and deterministic: same inputs give the same result on every
platform. Support iOS, Android, web, and desktop; initial or default locale MAY be taken from
the platform (system/device language). System locale is an input to resolution, not a
different code path per platform.

### IV. Migration-friendly

Provide and maintain migration paths from gen_l10n and easy_localization. Breaking changes
to public APIs require a migration path or clear deprecation period.

### V. Catalog (under development)

A single-page UI for localization: add, edit, and update entries and configure them by type
(including Arabic language specifications). The Catalog is the UI gate to localization
files so users can manage and configure text without editing ARB/CSV/JSON/YAML directly.
It runs as a standalone sidecar (separate from the app runtime), with autosave, explicit
review completion, and structured editors for plural/gender and Arabic-specific options.

### VI. Simplicity and YAGNI

Prefer the smallest API surface that satisfies the above. New features MUST justify
complexity; avoid optional flags or modes that duplicate behavior.

## Additional Constraints

Target platforms: iOS, Android, web, desktop. Localization asset formats: ARB, CSV, JSON,
YAML. No constraints beyond Core Principles unless introduced in a ratified amendment.

## Development Workflow

Plans and specs MUST pass a Constitution Check (alignment with Core Principles) before
Phase 0 research and after Phase 1 design. PRs SHOULD verify alignment with these
principles; complexity that conflicts with Simplicity and YAGNI MUST be justified in
plan or spec.

## Governance

This constitution overrides ad-hoc decisions. Amendments require a version bump (semver),
updated docs, and any migration notes. PRs should verify alignment with these principles.

**Version**: 1.0.0 | **Ratified**: 2025-03-14 | **Last Amended**: 2025-03-14
