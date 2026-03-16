# Implementation Plan: English Localization Alignment

**Branch**: `004-update-english-localization` | **Date**: 2026-03-15 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-update-english-localization/spec.md`

**Note**: This plan covers Phase 0 research and Phase 1 design artifacts for aligning English localization behavior with the clarified spec while preserving the package's existing deterministic locale model.

## Summary

Align English localization across runtime, validation, code generation, and assets by keeping a shared base `en` locale, layering regional overrides for `en_US`, `en_GB`, `en_CA`, and `en_AU`, and making plural handling and generated APIs match the English-specific rules in the feature spec. The implementation will stay inside the existing library/CLI/catalog architecture rather than introducing an English-only subsystem.

## Goal

Deliver an implementation-ready design that updates English localization behavior without regressing Arabic support, typed dictionary generation, raw-key lookup, or deterministic locale fallback.

## Success Criteria

- The runtime supports the English plural contract from the spec, including absolute-value handling for negatives and plural treatment for non-one numeric values.
- Shared `en` content remains the source of truth, and region files contain only spelling, selected vocabulary, and formatting-sensitive overrides.
- Validation and generation workflows accept English one/other plural data without requiring Arabic-only forms or gender structures.
- Existing locale normalization and fallback remain deterministic for both base and regional English locales.
- The work is fully mapped to source files, tests, CLI workflows, and docs before execution begins.

## Technical Context

**Language/Version**: Dart `>=3.3.0 <4.0.0`, Flutter `>=3.19.0`  
**Primary Dependencies**: `intl`, `flutter_localizations`, `yaml`, `http`, `crypto`, `path`, `shared_preferences`  
**Storage**: File-based translation assets (`JSON`, `ARB`, `YAML`, `CSV`) plus `shared_preferences` for locale persistence  
**Testing**: `flutter test`, `flutter analyze`, `dart run anas_localization:anas_cli validate assets/lang --profile=strict --fail-on-warnings`, `dart run anas_localization:localization_gen --modules`  
**Target Platform**: Flutter package runtime for iOS, Android, web, and desktop, plus CLI/codegen workflows  
**Project Type**: Flutter/Dart localization library with CLI tooling, code generation, and a catalog sidecar UI  
**Performance Goals**: Locale switching and message resolution should remain fast in normal use (no new latency targets beyond existing resolution behavior); fallback behavior must remain deterministic  
**Constraints**: Preserve parity between generated APIs and raw-key access, avoid new English-only modes, keep region support limited to spelling/selected vocabulary/formatting in first release  
**Scale/Scope**: Update core runtime, validator, generator, asset contract, example coverage, and regression tests for base `en` plus four regional English variants

**Locale Notation**: User-facing requirements use hyphenated labels such as `en-US`; normalized runtime codes and asset file names use underscored forms such as `en_US`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Research Gate

- **Dual access modes**: Pass. Planned runtime and generator changes will keep raw-key lookup and generated dictionary APIs on the same resolution path.
- **CLI and tooling**: Pass. The work explicitly includes validator and generator alignment plus documented CLI verification.
- **Deterministic locale behavior**: Pass. The plan preserves existing normalized locale fallback and uses a shared `en` base with explicit regional overrides.
- **Migration-friendly**: Pass. The design is additive and keeps existing locale file patterns compatible with current workflows.
- **Catalog (under development)**: Pass. Validator and asset-contract changes remain compatible with catalog-managed localization files.
- **Simplicity and YAGNI**: Pass. The plan extends current locale and plural handling instead of adding a parallel English subsystem.

### Post-Design Gate

- **Dual access modes**: Pass. `research.md`, `data-model.md`, and the contracts keep one runtime contract for both generated and raw access.
- **CLI and tooling**: Pass. `quickstart.md` and the contracts make validation and codegen part of the supported flow.
- **Deterministic locale behavior**: Pass. The design codifies one base locale plus region override layering without ambiguous fallback rules.
- **Migration-friendly**: Pass. Existing `en` remains the canonical base locale, so current projects gain regional overrides without reworking their entire English tree.
- **Catalog (under development)**: Pass. The asset contract uses explicit files and value shapes the catalog can expose or validate.
- **Simplicity and YAGNI**: Pass. Regional differences are intentionally limited to the clarified first-release scope.

## Project Structure

### Documentation (this feature)

```text
specs/004-update-english-localization/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── english-locale-asset-contract.md
│   └── english-runtime-contract.md
├── checklists/
│   ├── english.md
│   └── requirements.md
├── spec.md
└── tasks.md
```

### Source Code (repository root)

```text
assets/
└── lang/
    ├── en.json
    ├── ar.json
    └── ...

bin/
├── anas.dart
├── anas_cli.dart
├── cli.dart
├── generate_dictionary.dart
├── localization_gen.dart
└── validate_translations.dart

example/
├── assets/
│   └── lang/
│       └── en.json
└── lib/
    └── generated/
        └── dictionary.dart

lib/
├── anas_localization.dart
└── src/
    ├── localization_manager.dart
    ├── features/
    │   └── localization/
    │       ├── data/
    │       └── domain/
    ├── shared/
    │   ├── core/
    │   └── utils/
    └── utils/

test/
├── arb_interop_test.dart
├── dictionary_runtime_lookup_test.dart
├── localization_integration_regression_test.dart
├── localization_service_test.dart
├── tool_workflow_test.dart
└── translation_loader_integration_test.dart
```

**Structure Decision**: This is a single Flutter/Dart package. English-localization work should touch the core runtime under `lib/src/features/localization/`, shared utilities under `lib/src/shared/utils/`, CLI/codegen entry points in `bin/`, package/example assets under `assets/lang/` and `example/assets/lang/`, and regression tests in `test/`.

## Complexity Tracking

No constitution violations or extra complexity justifications are required for this feature.

## Phase 0 Research Plan

Create [research.md](./research.md) to resolve the implementation decisions that affect runtime, validation, and generation:

1. Confirm the English locale asset contract: shared `en.json` plus regional override files `en_US.json`, `en_GB.json`, `en_CA.json`, and `en_AU.json`.
2. Define the plural-count contract for runtime and generated APIs: accept `num`, use singular only when absolute numeric value equals `1`, otherwise plural.
3. Define validator/codegen behavior so `en` remains the canonical reference locale while English optional plural warnings and generated APIs remain compatible with the English one/other model.

## Phase 1 Design Plan

Create the following design artifacts after research is complete:

- [data-model.md](./data-model.md): entity and relationship model for base `en`, regional variants, count-sensitive entries, and regional overrides.
- [contracts/english-locale-asset-contract.md](./contracts/english-locale-asset-contract.md): contract for file naming, layering rules, and allowed English regional override content.
- [contracts/english-runtime-contract.md](./contracts/english-runtime-contract.md): runtime/generator/validator behavior contract for plural counts, fallback, and typed/raw lookup parity.
- [quickstart.md](./quickstart.md): contributor workflow for adding shared `en` entries, layering region files, validating, and regenerating the dictionary.

## Phase 2 Implementation Planning

### Runtime Alignment

- Update `lib/src/shared/utils/plural_rules.dart` to support the clarified English plural contract without changing Arabic semantics.
- Update `lib/src/features/localization/domain/services/message_resolver.dart` to preserve numeric counts instead of collapsing non-`int` values to `0`.
- Confirm explicit English left-to-right behavior remains covered in `lib/src/core/text_direction_helper.dart` and `lib/src/shared/core/formatters/text_direction_helper.dart`.
- Review `lib/src/features/localization/data/repositories/localization_service.dart` and `lib/src/localization_manager.dart` to confirm deterministic fallback for partial regional English assets.
- Update `lib/src/shared/core/formatters/date_time_formatter.dart` for clarified English regional date/time defaults where current formatter behavior is insufficient.
- Update `lib/src/shared/core/formatters/number_formatter.dart` for clarified English number and currency expectations where current formatter behavior is insufficient.

### Tooling Alignment

- Update `lib/src/shared/utils/translation_validator.dart` so English plural validation and optional warnings are compatible with one/other entries while Arabic keeps its stricter requirements.
- Update `bin/generate_dictionary.dart` so generated plural getters and selection logic match the runtime English contract.
- Audit any mirrored utility surfaces under `lib/src/utils/` and either keep them aligned or remove duplication in a controlled follow-up.

### Asset and Example Alignment

- Rework `assets/lang/en.json` into a true shared English base where necessary.
- Add representative region override files under `assets/lang/`.
- Mirror representative English asset coverage under `example/assets/lang/` if the example remains part of regression and generator verification.
- Regenerate `example/lib/generated/dictionary.dart` after asset updates so typed accessors track the new English base and regional overrides.

## Milestones

1. Phase 0 complete: `research.md` resolves all runtime, asset, validator, and generator decisions.
2. Phase 1 complete: `data-model.md`, `contracts/`, and `quickstart.md` define the implementation contract.
3. Phase 2 ready: source files, tests, and docs are fully mapped for execution and task breakdown.

## Verification Plan

- Extend `test/localization_service_test.dart` for English region fallback, same-language resolution, and explicit `en_CA` behavior.
- Extend `test/localization_integration_regression_test.dart` and `test/dictionary_runtime_lookup_test.dart` for plural-count and override behavior.
- Extend `test/localization_integration_regression_test.dart` for English date/time/number/currency formatter coverage and explicit LTR expectations where applicable.
- Extend `test/tool_workflow_test.dart` and `test/arb_interop_test.dart` for validation and generator coverage around regional English files.
- Run `flutter analyze`, `flutter test`, `dart run anas_localization:anas_cli validate assets/lang --profile=strict --fail-on-warnings`, and `dart run anas_localization:localization_gen --modules`.
- Update `README.md`, `doc/reference/file-structure.md`, and `CHANGELOG.md` if the public English asset contract or generated API changes.

## Dependencies

- Existing locale normalization and fallback behavior in `LocalizationService`.
- Existing `intl`-based date/time and number formatters.
- Existing validator and generator entry points that already prefer `en` as the canonical reference locale.

## Owners

- **Spec owner**: `specs/004-update-english-localization/spec.md`
- **Implementation owner**: next execution phase
- **Validation owner**: runtime, CLI, generator, and documentation updates in the same change set

## Next Steps

1. Use `research.md` as the authoritative decision log during implementation.
2. Use the contracts and data model to break the work into execution tasks.
3. Start implementation with plural/runtime alignment because it drives validator, generator, and test updates.
