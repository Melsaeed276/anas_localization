# Implementation Plan: Fix Dictionary Sync

**Branch**: `[007-fix-dictionary-sync]` | **Date**: 2026-03-25 | **Spec**: [`spec.md`](./spec.md)
**Input**: Feature specification from `/specs/007-fix-dictionary-sync/spec.md`

## Summary

Keep the typed dictionary generator and the example app’s generated dictionary in sync with the example’s translation assets, while ensuring future regenerations keep using the correct override inputs.

Primary approach: fix generator input precedence in `bin/generate_dictionary.dart` so when codegen runs from the package root it merges package defaults with overrides from `example/assets/lang` (not `assets/lang`), then add/adjust tests and regenerate outputs.

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: Dart >=3.3.0 <4.0.0 + Flutter >=3.19.0  
**Primary Dependencies**: intl, flutter_localizations, yaml, shared_preferences; generator/validation uses analyzer and internal translation parsing utilities  
**Storage**: File-based translation assets (`assets/lang/*.json` and `example/assets/lang/*.json`)  
**Testing**: `flutter_test` (unit/integration/widget tests) + `dart analyze` for static analysis  
**Target Platform**: All Flutter targets supported by this package (mobile, web, desktop)
**Project Type**: Flutter/Dart package with CLI code generation + example app  
**Performance Goals**: Dictionary generation should complete within a developer-friendly time window for typical translation sets  
**Constraints**: CI quality gates must pass (`dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test`, publish dry-run) and the generated API must remain backward compatible for existing keys  
**Scale/Scope**: Hundreds of translation keys in repo assets/lang and example/assets/lang; generation must stay deterministic and consistent across locales

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Gates to satisfy:
1. Architecture boundaries (VII): keep changes limited to CLI/generator + regeneration outputs; no domain/runtime restructuring.
2. Error handling (VIII): no silent failures; generator will keep emitting actionable errors for missing/invalid inputs.
3. Testing discipline (IX): add regression coverage for override-precedence and “example keys exist” expectations.
4. CI/CD quality gates (X): ensure format/analyze/tests/publish dry-run succeed after regeneration.
5. Logging/observability (XI): avoid logging sensitive/PII; keep existing CLI stdout/stderr behavior consistent.
6. Security/privacy (XII): not applicable (no financial features in this scope).

## Project Structure

### Documentation (this feature)

```text
specs/007-fix-dictionary-sync/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (optional)
├── data-model.md        # Phase 1 output (optional)
├── quickstart.md        # Phase 1 output (optional)
├── contracts/           # Phase 1 output (optional)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
bin/                      # `anas` + `localization_gen` entry points; dictionary generation logic
lib/                      # package runtime + feature modules
lib/src/                  # actual code organization inside the package
test/                     # generator + runtime tests
example/                  # demo app that consumes `example/lib/generated/dictionary.dart`
example/assets/lang/      # example override translation assets
assets/lang/              # package default translation assets
```

**Structure Decision**: Keep changes focused on the generator (`bin/`) and the example’s generated output (`example/lib/generated/dictionary.dart`), plus add regression tests in `test/` to prevent override-precedence regressions.

## Complexity Tracking

N/A (no new architectural complexity expected for this bugfix + regeneration sync).
