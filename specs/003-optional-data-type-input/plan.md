# Implementation Plan: Optional Data Type Input for Localization

**Branch**: `003-optional-data-type-input` | **Date**: 2025-03-15 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `specs/003-optional-data-type-input/spec.md`

## Summary

Add an optional **data_type** input per localization entry (string, numerical, gender, date, date & time) so the system can drive validation, Catalog UI controls, type-based extensions, and code generation. Data type is stored in the same file as values (per-key metadata). Catalog shows a type dropdown (default string) and type-specific value inputs (text field, number field, male/female dropdown, date picker, date+time picker). Numerical allows integers and decimals; date/time use canonical storage (e.g. ISO 8601) with locale-specific display. File import uses merge semantics. Validation and code generation apply the same type rules; out of scope for first release: extra types, custom validation rules, timezone, configurable import.

## Technical Context

**Language/Version**: Dart SDK >=3.3.0 <4.0.0, Flutter >=3.19.0  
**Primary Dependencies**: Flutter SDK, intl (date/number formatting), existing lib (catalog, translation_file_parser, translation_validator, codegen_utils)  
**Storage**: File-based (ARB/JSON/YAML/CSV); data type stored alongside each key in the same file (structure in data-model/contracts)  
**Testing**: flutter_test; unit tests for validation rules and merge logic; widget/integration tests for Catalog type dropdown and type-specific inputs  
**Target Platform**: iOS, Android, web, desktop (Flutter); CLI and Catalog as in 002  
**Project Type**: Flutter/Dart package (library) with CLI and Catalog UI (tool/catalog_app)  
**Performance Goals**: No perceptible delay for validation or type resolution; qualitative per spec  
**Constraints**: Same file for type and values; merge-on-import fixed; deterministic validation  
**Scale/Scope**: Five data types (string, numerical, gender, date, date & time); Catalog UI and file-based workflows; validation and codegen aligned

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Alignment |
|-----------|-----------|
| **I. Dual access modes** | Data type applies to both type-safe generated API and raw-key access; same loading and validation. |
| **II. CLI and tooling** | Validation (and codegen) use data type rules; CLI can report type violations; Catalog is the UI for configuring type. |
| **III. Deterministic locale behavior** | Date/time canonical storage (e.g. ISO 8601) and locale-specific display are deterministic; no new locale branching. |
| **IV. Migration-friendly** | data_type is optional (default string); existing entries without type unchanged; no breaking API. |
| **V. Catalog** | Catalog presents data type as dropdown and type-specific value inputs (text, number, gender dropdown, date picker, date+time picker); aligns with "configure by type". |
| **VI. Simplicity and YAGNI** | Five types only; no custom validation or configurable import in first release; justified by spec. |

**Gate result**: PASS — no violations.

*Post–Phase 1 re-check*: data-model and contracts keep type optional and same-file (`@dataTypes` or equivalent); Catalog contract defines dropdown and type-specific inputs without duplicating behavior. No new violations.

## Project Structure

### Documentation (this feature)

```text
specs/003-optional-data-type-input/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── src/
│   ├── core/                    # Extend for type-aware validation/codegen if needed
│   ├── features/
│   │   ├── localization/       # Dictionary/entry model + data_type
│   │   ├── catalog/             # Catalog UI: type dropdown, type-specific inputs, merge on import
│   │   └── migration/           # Unchanged unless type appears in migration output
│   ├── shared/                  # Type enum, validation rules per type; shared/utils/ = translation_file_parser (read/write type)
│   └── utils/                   # translation_validator (wired to type rules)
bin/                              # CLI: validate respects type; import merge
test/
tool/catalog_app/                 # Catalog: data_type dropdown; number/gender/date/dateTime inputs
```

**Structure Decision**: Single package; data type is a new optional field in shared models and Catalog/CLI/validation/codegen. No new top-level projects. Catalog and lib/shared extended per contracts.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | — | — |
