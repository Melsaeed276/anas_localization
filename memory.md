# anas_localization — Project Memory

Last updated: 2026-07-03

Persistent notes for humans and AI assistants working in this repository.

## Repository

| Item | Value |
|------|-------|
| Package | `anas_localization` |
| Version | `0.1.5` (see `pubspec.yaml`) |
| GitHub | `Melsaeed276/anas_localization` |
| Default branch | `main` |
| Docs site | <https://melsaeed276.github.io/anas_localization/> |
| pub.dev | <https://pub.dev/packages/anas_localization> |

## Branch strategy

- **Single active branch:** `main` (as of 2026-07-02).
- Previous milestone branches (`clean-up`, `ci/smoke-test`, `pipeline-update`, `dev`) were merged into `main` via PR #147 and deleted.
- Start new work from `main`:

```bash
git checkout main
git pull origin main
git checkout -b feat/short-description
```

## CI/CD pipeline

Composite actions live under `.github/actions/`:

| Action | Purpose |
|--------|---------|
| `setup-flutter` | Flutter SDK + `pub get` (root + optional example/catalog) |
| `package-hygiene` | README links, usage section, LICENSE/NOTICE, license_checker |
| `flutter-package-checks` | `dart format`, `dart analyze`, `flutter test` |
| `pana-score` | pub.dev score gate |
| `coverage-report` | lcov summary + artifact upload |

Main workflows:

| Workflow | Trigger | Notes |
|----------|---------|-------|
| `ci-main.yml` | push to `main`, `workflow_dispatch` | Lint → tests → publish dry-run |
| `pr-tests.yml` | pull requests | PR quality gate |
| `semantic-pr.yml` | PR title edits | Requires conventional title (`feat:`, `fix:`, `ci:`, etc.) |
| `release-tags.yml` | semver tags `v*`, `workflow_dispatch` | OIDC publish to pub.dev + GitHub release binaries |
| `nightly.yml` | cron + manual | Full suite + benchmarks |
| `check-generation.yml` | path filters | Codegen drift detection |
| `migration-validation.yml` | PR + manual | `validate-migration` CLI flow |

### CI quirks

- `dart analyze` must be **0 issues** (warnings fail CI).
- `dart format --set-exit-if-changed .` runs in CI; format before push.
- `build/**` and `tool/**` are excluded from root analyzer (`analysis_options.yaml`).
- `doc/api/` is generated in CI; excluded via `.pubignore` (~13 MB).
- Test output uses `tee` + expanded reporter so failures appear in GitHub Actions logs.
- `actions/checkout@v5` and `actions/upload-artifact@v6` (Node 24) — avoid v4/v5 upload-artifact deprecation warnings.
- Informational step: `dart pub outdated || true` (do not use `--mode=null-safety`; removed in current Dart).

## Local commands

```bash
flutter pub get
cd example && flutter pub get && cd ..

dart analyze
dart format --set-exit-if-changed .
flutter test
flutter pub publish --dry-run

dart run anas_localization:anas catalog serve
dart run anas_localization:anas_cli validate assets/lang --profile=balanced
dart run anas_localization:localization_gen --modules
```

## Publishing

- Releases are automated via **OIDC** when a semver tag matching `pubspec.yaml` is pushed (e.g. `v0.1.5`).
- Workflow: `.github/workflows/release-tags.yml`
- One-time setup: pub.dev Admin → Publishing from GitHub Actions → repo `Melsaeed276/anas_localization`, tag pattern `v{{version}}`.

## Contributor templates

### Issues (`.github/ISSUE_TEMPLATE/`)

- `bug_report.yml` — default title prefix `fix:`
- `feature_request.yml` — default title prefix `feat:`
- Labels use backlog taxonomy: `P0`–`P3`, `type:*`, `area:*`

### Pull requests (`.github/PULL_REQUEST_TEMPLATE/`)

- `feature.md` — new features
- `fix.md` — bug fixes
- `ci.md` — workflow/CI changes
- `docs.md` — documentation-only

PR titles must pass **semantic PR** check (see `semantic-pr.yml`).

## Architecture (short)

- **Package type:** Flutter/Dart pub package (not an app).
- **Public API:** `lib/anas_localization.dart`
- **CLI:** `bin/anas_cli.dart` (`dart run anas_localization:anas`)
- **Codegen:** `bin/generate_dictionary.dart` — honors `APP_LANG_DIR` when set from package root (tests use temp dirs).
- **Catalog UI:** pre-built web bundle at `lib/src/features/catalog/server/flutter_web_bundle/`
- **Catalog app source:** `tool/catalog_app/` (excluded from pub publish via `.pubignore`)

## Test patterns learned

- Catalog widget tests need `ThemeData(splashFactory: InkRipple.splashFactory)` to avoid `ink_sparkle.frag` shader errors in test environments.
- Prefer bounded `pump()` frames over `pumpAndSettle()` when BackdropFilter/animations never settle.
- `CatalogApp` tests must configure `LocalizationService` with `CatalogDictionary.fromMap` / preview dictionaries.
- Example smoke test should assert localized `itemsCount()` text, not hardcoded `"Count: N"`.
- `locale_fallback_performance_benchmark_test.dart` skips strict timing thresholds on CI (`Platform.environment.containsKey('CI')`).
- Migration validation demos need `GlobalMaterialLocalizations` delegates on migrated `MaterialApp`.

## Cursor skill

- Pipeline skill: `.cursor/skills/flutter-package-ci-pipeline/`
- Also published externally as reusable `cursor-skills` repo (multi-skill).

## Recent milestones (2026-06 → 2026-07)

1. CI/CD pipeline with composite actions, Dependabot, semantic PR, pana gate.
2. Catalog test fixes + theme handling for Material 3.
3. `APP_LANG_DIR` fix in dictionary codegen for `tool_workflow_test`.
4. Issue + PR template choosers on `main`.
5. Merge `clean-up` → `main` (PR #147); branch cleanup to single `main`.

## Files to avoid committing

- `coverage/lcov.info` (local test artifact; in `.pubignore`)
- IDE/agent metadata (`.cursor/`, `.claude/`, etc. — in `.pubignore` but some paths may exist in repo for dev)

## When updating this file

Add entries when:

- Branch or release process changes
- New CI gate or composite action is added
- Recurring test/CI pitfalls are discovered
- Default development workflow changes
