# Tasks: Fix Dictionary Sync

## User Story Order
1. [US1] Regenerate Dictionary Accessors (Priority: P1)
2. [US2] Runtime Lookup Without Generation Still Works (Priority: P2)
3. [US3] Remove Example Static Analysis Failures (Priority: P3)

## Dependencies
1. US1 must run before US2/US3 validation because typed regeneration impacts the example compilation surface.
2. US2 and US3 can be executed in parallel after US1 regeneration.

## Parallel Execution Opportunities
- [US2] runtime test tasks can run in parallel with [US3] lint cleanup after `example/lib/generated/dictionary.dart` is regenerated.

## Tasks (checklist format)

### Phase 1 - Setup
- [X] T001 Ensure repo is on branch `007-fix-dictionary-sync` and prerequisites are met using `.specify/scripts/bash/check-prerequisites.sh`

### Phase 2 - Foundational
- [X] T002 [P] Compare example’s expected typed accessors in `example/lib/main.dart` against current generated output in `example/lib/generated/dictionary.dart` to confirm mismatch set

### Phase 3 - [US1] Regenerate Dictionary Accessors
- [X] T003 [US1] Locate override-precedence/merge behavior in `bin/generate_dictionary.dart` (and any helper it uses) and capture where example overrides are currently ignored
- [X] T004 [US1] Implement override precedence fix in `bin/generate_dictionary.dart` so typed generation uses `example/assets/lang` overrides when codegen runs from repo/package root
- [X] T005 [US1] Add regression test file `test/dictionary_generator_override_precedence_test.dart` asserting generated typed output uses example overrides (not only `assets/lang`) AND validates typed-mode semantics for dotted keys + placeholder markers (`{param}`, `{param?}`, `{param!}`); constitution test hygiene: in each test file use `setUp(() { LocalizationService().clear(); })` (or the repo-mandated equivalent) so tests are order-independent
- [X] T006 [US1] Regenerate typed output by running `dart run anas_localization:anas update --gen` from repo root and updating `example/lib/generated/dictionary.dart` (MUST reflect the new override precedence behavior)
- [X] T007 [US1] Run `dart analyze` from repo root and confirm example compilation errors for missing typed getters/methods are resolved (targets `example/lib/main.dart` diagnostics)

### Phase 4 - [US2] Runtime Lookup Without Generation Still Works
- [X] T008 [P] [US2] Run `flutter test test/dictionary_runtime_lookup_test.dart` to confirm no-generation dotted keys + parameter substitution + fallbacks still work
- [X] T009 [US2] If any runtime tests fail or gaps are found, add/adjust targeted runtime regression tests in `test/dictionary_runtime_lookup_test.dart`; constitution test hygiene: ensure the file resets singleton state in `setUp` (e.g., `LocalizationService().clear()`) and tests do not depend on execution order

### Phase 5 - [US3] Remove Example Static Analysis Failures
- [X] T010 [P] [US3] Fix remaining example-only static analysis issues (e.g., unused imports) in `example/lib/pages/features_page.dart`
- [X] T011 [US3] Ensure generated example outputs satisfy lint expectations (or generator emits an appropriate `// ignore_for_file` policy) in `example/lib/generated/dictionary.dart`
- [ ] T012 [US3] Run full CI-quality verification per constitution gates from repo root after regeneration: `dart format --set-exit-if-changed .` → `flutter analyze --no-fatal-infos` → `flutter test --coverage` → `flutter pub publish --dry-run`, targeting both package + example surfaces (`example/lib/` and `lib/`)

### Phase 6 - Finalize
- [X] T013 Confirm documentation consistency by aligning any typed-vs-runtime examples in `doc/RUNTIME_LOOKUP_WITHOUT_GENERATION.md` and `README.md` with the actual API used by the example app
