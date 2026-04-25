<!--
Sync Impact Report
==================
Version change: 1.0.0 → 2.0.0 (governance expansion with finance principles)
Modified principles:
  - I. Dual access modes → retained
  - II. CLI and tooling → retained
  - III. Deterministic locale behavior → retained
  - IV. Migration-friendly → retained
  - V. Catalog (under development) → retained
  - VI. Simplicity and YAGNI → retained
Added sections:
  - VII. Clean Architecture Boundaries
  - VIII. Error Handling Standards
  - IX. Testing Discipline
  - X. CI/CD Quality Gates
  - XI. Logging and Observability
  - XII. Sharia-Compliant Finance (Zakat, separation of funds, prohibited transactions)
  - Migration Rules (consolidation of existing inconsistencies)
  - Technology Stack (explicit tech alignment)
Removed sections: None
Templates requiring updates:
  - .specify/templates/plan-template.md ✅ (Constitution Check references generic principles)
  - .specify/templates/spec-template.md ✅ (no changes required)
  - .specify/templates/tasks-template.md ✅ (no changes required)
Follow-up TODOs: None
-->

# anas_localization Constitution

## Core Principles

### I. Dual Access Modes

Support both (a) type-safe generated dictionary APIs as the default/recommended path,
and (b) fast localization via raw string keys without generated code for quick iteration
or simple apps. Generated code, when used, remains the source of truth for keys;
raw-key access MUST use the same loading and fallback behavior.

### II. CLI and Tooling

Validation, import/export (ARB/CSV/JSON), stats, and catalog workflows are exposed via CLI.
CI MUST be able to run `validate` (and optional profiles) for deterministic checks.
CLI commands MUST exit with non-zero codes on failure. Output MUST be parseable
(JSON available where appropriate) for CI integration.

### III. Deterministic Locale Behavior

Locale resolution and fallback (e.g. `lang_script_region → lang_script → lang_region → lang
→ fallback`) MUST be documented and deterministic: same inputs give the same result on every
platform. Support iOS, Android, web, and desktop; initial or default locale MAY be taken from
the platform (system/device language). System locale is an input to resolution, not a
different code path per platform. The `resolveLocaleFallbackChain` function serves as the
canonical implementation.

### IV. Migration-Friendly

Provide and maintain migration paths from `gen_l10n` and `easy_localization`. Breaking changes
to public APIs require a migration path or clear deprecation period (minimum one minor version).
Migration validators (`validate-migration`) MUST be kept in sync with supported source formats.

### V. Catalog (Under Development)

A single-page UI for localization: add, edit, and update entries and configure them by type
(including Arabic language specifications). The Catalog is the UI gate to localization
files so users can manage and configure text without editing ARB/CSV/JSON/YAML directly.
It runs as a standalone sidecar (separate from the app runtime), with autosave, explicit
review completion, and structured editors for plural/gender and Arabic-specific options.

The catalog service follows the state machine pattern with explicit cell statuses
(`green`, `warning`, `red`) and reason codes. State MUST persist across service restarts
via `catalog_state.json`.

### VI. Simplicity and YAGNI

Prefer the smallest API surface that satisfies the above. New features MUST justify
complexity; avoid optional flags or modes that duplicate behavior. When in doubt:
- One obvious way to do things > multiple equivalent alternatives
- Explicit configuration > magic inference
- Fail fast with typed exceptions > silent fallbacks

### VII. Clean Architecture Boundaries

#### Layer Structure

Code is organized in feature modules following domain-driven boundaries:

```
lib/src/features/{feature}/
├── data/           # Repositories, data sources, DTOs
├── domain/         # Entities, value objects, contracts
└── presentation/   # Widgets, view logic (if applicable)
```

Shared code lives in `lib/src/shared/` (core exceptions, utilities, services).

#### Dependency Rules

- **Presentation** MAY depend on domain and data
- **Data** MAY depend on domain
- **Domain** MUST NOT depend on data or presentation
- **Shared** MUST NOT depend on features

Barrel files in `lib/src/core/` re-export canonical implementations but MUST NOT
contain implementation logic.

#### Migration Rule (Architecture)

Existing code placing implementation directly in `lib/src/core/*.dart` SHOULD be
migrated to the appropriate feature module and re-exported. New code MUST use
feature-based organization from the start.

### VIII. Error Handling Standards

#### Typed Exceptions

All package exceptions MUST extend `LocalizationException`. Specific failure modes
MUST have dedicated exception types:
- `UnsupportedLocaleException` – locale not in configured set
- `LocalizationAssetsNotFoundException` – no assets resolved
- `LocalizationNotInitializedException` – state accessed before setup
- `CatalogOperationException` – catalog workflow errors

#### No Silent Failures

Catch blocks MUST NOT swallow exceptions without logging or re-throwing. The pattern:

```dart
// ❌ FORBIDDEN
try { ... } catch (_) {}

// ✅ REQUIRED
try { ... } catch (e, st) {
  logger.error('Context', 'Source', e);
  // re-throw or return explicit fallback
}
```

#### User-Facing Errors

UI code MUST map typed exceptions to user-friendly messages. Raw exception `toString()`
MUST NOT be shown to end users in release builds.

### IX. Testing Discipline

#### Test Organization

- **Unit tests**: `test/*_test.dart` for isolated function/class behavior
- **Integration tests**: `test/*_integration_test.dart` for cross-module flows
- **Contract tests**: `test/contract/` for external API contracts (when applicable)
- **Widget tests**: Flutter widget verification with `TestWidgetsFlutterBinding`

#### Test Hygiene

- Each test file MUST call `setUp` to reset singleton state (`LocalizationService().clear()`)
- Tests MUST NOT depend on execution order
- Test helpers and fixtures MUST be prefixed with `_` or placed in dedicated helpers
- Golden tests (when used) MUST be updated via `flutter test --update-goldens`

#### Coverage Expectations

CI tracks coverage; new features SHOULD maintain or improve line coverage percentage.
Critical paths (fallback chains, exception handling) MUST have explicit test coverage.

### X. CI/CD Quality Gates

All PRs and main-branch pushes MUST pass the following gates (in order):

1. **Format** – `dart format --set-exit-if-changed .`
2. **Analyze** – `flutter analyze --no-fatal-infos`
3. **Unit/Integration tests** – `flutter test --coverage`
4. **Publish dry-run** – `flutter pub publish --dry-run`

Optional gates (informational):
- Dependency outdated check
- Benchmark harness (regression threshold 50%)
- Link validation in README

#### Version and Changelog

- `pubspec.yaml` version bumps MUST have a corresponding `## X.Y.Z` section in `CHANGELOG.md`
- Breaking changes require MAJOR version bump
- New features require MINOR version bump
- Bug fixes and docs require PATCH version bump

### XI. Logging and Observability

#### Logging Service

Use `AnasLoggingService` (singleton via `logger` global) for all runtime logging.
Log levels: `debug`, `info`, `warning`, `error`, `success`.

#### Release Behavior

Logging is DISABLED by default in release builds (`kDebugMode` check).
Sensitive data (user content, PII) MUST NOT be logged.

#### Structured Logging

Prefer the extension methods (`logger.localeLoaded()`, `logger.localeLoadFailed()`)
over raw `logger.info()` calls to maintain structured context.

### XII. Sharia-Compliant Finance

This section establishes non-negotiable principles for any financial features,
Zakat calculations, or monetary handling in the package or applications using it.

#### A. Prohibition of Riba (Interest)

- **NEVER** implement, calculate, or display interest-based computations as a
  financial feature
- Interest rates MUST NOT appear in example code, documentation, or test fixtures
- If an external API returns interest values, the UI layer MUST NOT present them
  as recommended or endorsed

#### B. Separation of Funds

When handling multi-account or multi-purpose monetary values:

- **Zakat-eligible assets** MUST be tracked separately from Zakat-exempt assets
- **Business funds** MUST be separated from **personal funds** in any ledger logic
- **Commingling** of Halal and non-Halal revenue streams is FORBIDDEN; if detected,
  the system MUST flag or reject the transaction

#### C. Zakat Calculation Rules

If the package or any dependent app implements Zakat features:

1. **Nisab threshold** MUST be configurable (gold/silver-based) and sourced from
   a trusted reference; hard-coding a single currency value is NOT acceptable
2. **Hawl (lunar year)** MUST be respected; Zakat calculation MUST NOT be triggered
   before the asset has been held for one lunar year
3. **Rate accuracy** – the standard Zakat rate is 2.5% of Zakatable wealth; deviations
   MUST be explicitly justified and documented
4. **Asset categorization** – distinguish between:
   - Cash and bank balances
   - Trade inventory (valued at current market price)
   - Gold, silver, and precious metals
   - Debts receivable (good debts only)
   - Exempt assets (personal residence, personal vehicle, etc.)
5. **Deductions** – valid deductions (debts owed, business liabilities) MUST be
   subtracted before calculating Zakat
6. **Auditability** – Zakat calculations MUST be reproducible; store inputs and
   formula version so users can verify correctness

#### D. Halal Screening (When Applicable)

If the package supports investment or business classification:

- Provide screening criteria aligned with AAOIFI or equivalent standards
- Non-compliant assets MUST be clearly labeled
- Mixed-status portfolios MUST show compliance percentage

#### E. Transparency and User Control

- Users MUST be able to inspect the calculation methodology
- No Zakat or financial calculation SHOULD be opaque or hidden
- Localization keys for finance-related strings MUST include context notes
  explaining Sharia relevance (use catalog notes feature)

#### Migration Rule (Finance)

Any existing code that performs monetary calculations MUST be audited against
these principles. Non-compliant implementations MUST be refactored or removed
before the next minor release.

## Technology Stack Alignment

| Concern             | Standard                                            |
|---------------------|-----------------------------------------------------|
| Language/SDK        | Dart ≥ 3.3.0, Flutter ≥ 3.19.0                      |
| State Management    | Built-in (`AnasLocalization` widget state); no external deps |
| Networking          | `http` package (pluggable via `HttpClientAdapter`)  |
| Local Storage       | `shared_preferences` (pluggable via `KeyValueStorage`) |
| Linting             | `flutter_lints` v6+                                  |
| Testing             | `flutter_test` SDK                                   |
| CI                  | GitHub Actions                                       |

## Migration Rules (Consolidation)

The following inconsistencies exist in the codebase and SHOULD be unified:

| Area                    | Current State                                 | Target State                             | Priority |
|-------------------------|-----------------------------------------------|------------------------------------------|----------|
| Core barrel exports     | Some impl in `lib/src/core/*.dart`            | Re-export only; impl in feature modules  | Medium   |
| CLI executable aliases  | Multiple entry points (`anas`, `cli`, `anas_cli`) | Single canonical `anas` entry point   | Low      |
| Test state reset        | Inconsistent `setUp` patterns                 | Standardized reset via helper            | Medium   |
| Singleton access        | Mix of `factory` and `instance` getters       | Prefer `factory LocalizationService()`   | Low      |

PRs addressing these migrations are welcome and SHOULD reference this section.

## Development Workflow

Plans and specs MUST pass a Constitution Check (alignment with Core Principles) before
Phase 0 research and after Phase 1 design. PRs SHOULD verify alignment with these
principles; complexity that conflicts with Simplicity and YAGNI MUST be justified in
plan or spec.

### Constitution Check Gates

1. Does the change respect architecture boundaries (VII)?
2. Are typed exceptions used for failure modes (VIII)?
3. Are tests added or updated for new behavior (IX)?
4. Does CI pass all quality gates (X)?
5. Is logging used appropriately with no PII exposure (XI)?
6. For financial features: Does it comply with Sharia principles (XII)?

## Governance

This constitution overrides ad-hoc decisions. Amendments require:

1. A version bump following semver:
   - **MAJOR** – Principle removal or incompatible redefinition
   - **MINOR** – New principle or material expansion
   - **PATCH** – Clarifications, typo fixes, non-semantic refinements
2. Updated documentation and any migration notes
3. PR review by at least one maintainer

PRs MUST verify alignment with these principles. Non-trivial deviations MUST be
documented with justification in the PR description.

**Version**: 2.0.0 | **Ratified**: 2025-03-14 | **Last Amended**: 2025-03-24
