# Quickstart: Lib Structure Consolidation

**Feature**: `008-lib-structure-consolidation`
**Date**: 2026-06-17

## What This Does

Consolidates `lib/src/` into a clean feature-first architecture:
- **38 modules** in inventory (30 export-only shims + 8 divergent as of spec date)
- **2** cross-feature boundary violations fixed (`catalog` → `localization/data` and `localization/presentation`)
- **29** flat `test/*.dart` files reorganized under `test/features/` and `test/shared/`
- `bin/` and in-package `lib/` imports updated to canonical paths
- Import rules documented; regression guard wired into CI

## Prerequisites

- Dart `>=3.3.0`, Flutter `>=3.19.0`
- Clean git state (commit or stash current work)
- CI passing on `main` before branching

## Skills Reference

Use these skills during implementation:

| Phase | Skill | When |
|-------|-------|------|
| Every checkpoint | `dart-run-static-analysis` | Run `flutter analyze --no-fatal-infos` → `dart fix --apply` → `dart format --set-exit-if-changed .` → re-analyze |
| Boundary fix | `flutter-apply-architecture-best-practices` | Domain contracts only; no domain→data imports |
| Test reorg | `flutter-add-widget-test` | Catalog widget tests follow `testWidgets()` → `pumpWidget()` → `Finder` → `expect()` pattern |
| Error resolution | `dart-fix-runtime-errors` | If `flutter analyze` reports errors after file moves |
| Final verification | `dart-collect-coverage` | `flutter test --coverage` → validate `coverage/lcov.info` |

## Phase Order (matches `tasks.md`)

| Phase | Focus |
|-------|-------|
| 1 | Setup — regression guard script + CI wiring |
| 2 | Duplicate resolution (US1) — merge 8 remaining divergent pairs; convert legacy to shims |
| 3 | Boundary fix (US2) — domain contracts for catalog→localization |
| 4 | CLI + lib imports (US3) — canonical paths in `bin/` and `lib/src/**` |
| 5 | Documentation (US4) — `doc/reference/file-structure.md` |
| 6 | Test reorg (US5) — mirror `test/features/` layout |
| 7 | API relocation (US6) — **T039a in Phase 2**; Phase 7 verifies public exports |
| 8 | Polish — full CI gate + sub-project tests |

## Verification Commands

```bash
# After implementation, run these to confirm success:

# 1. Static analysis (per constitution §X / dart-run-static-analysis skill)
dart format --set-exit-if-changed .
flutter analyze --no-fatal-infos

# 2. All tests pass
flutter test

# 3. Shim export check (must pass after Phase 2+)
dart run tool/check_shim_exports.dart

# 4. Boundary violation check
rg "import.*features/localization/(data|presentation)" lib/src/features/catalog/
# Must return empty

# 5. Canonical imports in bin/ and lib/
rg "import.*src/utils/" bin/ lib/src/features/ lib/src/shared/
rg "import.*src/catalog/" bin/ lib/src/features/ lib/src/shared/
# Must return empty (shim dirs excluded)

# 6. Public exports still work
flutter pub publish --dry-run

# 7. Coverage check
flutter test --coverage

# 8. Sub-project tests
cd tool/catalog_app && flutter test
cd example && flutter test
```

## File Count Summary

| Category | Before (2026-06-17) | After |
|----------|---------------------|-------|
| Legacy files with implementations | 8 divergent + 29 shims | 0 impl (all export-only) + 3 infra in `core/` |
| Duplicate module pairs | 38 in inventory | 0 divergent |
| Cross-feature boundary violations | 2 | 0 |
| Test files in flat `test/` | 29 | 0 (moved to subdirs) |
| Test files in `test/e2e/` | 1 | 1 (unchanged) |

## Rollback

If any phase fails CI:
```bash
git revert HEAD    # Revert last phase commit
# Fix the issue, then re-attempt
```

## Key Files to Touch

See `tasks.md` for the full task list. High-level mapping:

- **Phase 1**: `tool/check_shim_exports.dart`, `.github/workflows/`
- **Phase 2**: 8 remaining divergent pairs + `FallbackConfigurationApi` (T039a); convert legacy paths to export shims
- **Phase 3**: `localization/domain/contracts/`, `catalog_flutter_app.dart`, `catalog_localizations.dart`
- **Phase 4**: `bin/*.dart`, `lib/src/**` canonical import cleanup
- **Phase 5**: `doc/reference/file-structure.md`, `CLAUDE.md`
- **Phase 6**: `test/features/`, `test/shared/`
- **Phase 7**: Verify `FallbackConfigurationApi` public exports (relocation done in Phase 2 T039a)
- **Phase 8**: CI validation, `test/shared/lib_structure_shim_exports_test.dart`
