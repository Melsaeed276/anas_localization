# Flutter Package CI/CD — Reference

## pub.dev OIDC setup

One-time configuration per package:

1. [pub.dev](https://pub.dev) → package **Admin** tab
2. Enable **Publishing from GitHub Actions**
3. Repository: `owner/repo`
4. Tag pattern: `v{{version}}`
5. (Optional) Require GitHub environment `pub.dev` with reviewers

Release command:

```bash
# Bump pubspec.yaml + CHANGELOG.md first
git tag v0.1.0
git push origin v0.1.0
```

`workflow_dispatch` on release workflow runs validation only — OIDC publish requires tag push.

---

## Composite action templates

### setup-flutter

```yaml
name: Setup Flutter
description: Install Flutter SDK and fetch package dependencies.

inputs:
  install_example:
    required: false
    default: 'true'
  # Add one boolean input per extra workspace:
  install_<workspace>:
    required: false
    default: 'false'

runs:
  using: composite
  steps:
    - uses: subosito/flutter-action@v2
      with:
        channel: stable
        cache: true
    - shell: bash
      run: flutter pub get
    - if: inputs.install_example == 'true'
      shell: bash
      working-directory: example
      run: flutter pub get
```

### package-hygiene

Key customizable line — README usage snippet grep:

```bash
awk '... {if(inblock && $0 ~ /(PACKAGE|PackageName)/) found=1} ...' README.md
```

Steps: lychee README links → usage section → LICENSE/NOTICE → license_checker → changelog-on-bump.

Changelog check compares `pubspec.yaml` version diff against `CHANGELOG.md` header `## {version}`.

### flutter-package-checks

```yaml
inputs:
  working_directory: { default: '.' }
  run_format: { default: 'true' }
  run_tests: { default: 'true' }
  test_report_path: { default: '' }  # e.g. build/ci/test-report.json

# Tests always use:
flutter test --coverage --test-randomize-ordering-seed random
```

### pana-score

```bash
dart pub global activate pana
sudo apt-get install -y webp   # ubuntu only
pana . --no-warning
# Parse "Points: N/160", fail if N < min_score
```

Run locally before setting `min_score` in CI.

### coverage-report

Requires `lcov` on ubuntu. Converts machine test JSON → JUnit via `junitreport` global package.

---

## Workflow templates

### ci-main.yml (push main)

```yaml
on:
  push:
    branches: [main]
    paths-ignore: ['**.md', 'doc/**', 'specs/**']
concurrency:
  group: main-ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:    # setup → hygiene → checks (no tests) → dart doc
  test:    # needs lint; tests + coverage artifacts
  publish-dry-run:  # needs test; dart doc → pana → flutter pub publish --dry-run
```

### pr-tests.yml (all PRs)

Same as ci-main but:

- `strategy.matrix.os: [ubuntu-latest, macos-latest, windows-latest]` for lint job
- `changelog_base_sha: ${{ github.event.pull_request.base.sha }}` in hygiene
- Expensive steps gated with `if: matrix.os == 'ubuntu-latest'`
- Extra workspace analysis (example, tool apps)

### semantic-pr.yml

```yaml
uses: amannn/action-semantic-pull-request@v5
types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
```

### release-gate.yml (PR → main)

Strict pre-merge gate: version in CHANGELOG, no TODO placeholders, pana, custom smoke checks, dry-run.

### release-tags.yml (tag push)

Three jobs:

```yaml
jobs:
  release-gate:
    # tag ↔ pubspec version check
    # full validation + dry-run
  publish:
    needs: release-gate
    if: github.event_name == 'push' && startsWith(github.ref, 'refs/tags/v')
    permissions:
      id-token: write
      contents: read
    uses: dart-lang/setup-dart/.github/workflows/publish.yml@v1
  github-release:
    needs: release-gate
    permissions:
      contents: write
    # optional: dart compile exe → softprops/action-gh-release
```

### check-generation.yml (optional)

```yaml
on:
  pull_request:
    paths: [/* sources that affect generated output */]
  push:
    branches: [main]
    paths: [/* same */]

steps:
  - run: <generate command>
  - run: git diff --exit-code -- <committed output paths>
```

### dependabot.yml

```yaml
version: 2
updates:
  - package-ecosystem: pub
    directory: /
    schedule: { interval: weekly, day: monday }
    labels: [dependencies]
  - package-ecosystem: pub
    directory: /example
    schedule: { interval: weekly, day: monday }
  - package-ecosystem: github-actions
    directory: /
    schedule: { interval: weekly, day: monday }
    groups:
      github-actions:
        patterns: ['*']
```

Add one `pub` entry per workspace directory.

---

## Local quality gate commands

Run before pushing CI changes:

```bash
dart format --set-exit-if-changed .
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test --coverage --test-randomize-ordering-seed random
dart doc
dart pub global activate pana && pana . --no-warning
flutter pub publish --dry-run
```

---

## Monorepo variant (bloc / riverpod)

For 3+ packages, extend with:

| Pattern | Tool |
|---------|------|
| Run checks per changed package | `dorny/paths-filter` + matrix |
| Bootstrap all packages | `melos bootstrap` or pub workspaces |
| Codegen all packages | `melos run generate` or `./scripts/generate.sh` |
| Per-package composite | `.github/actions/dart_package` / `flutter_package` |

Single-package composites in this skill do not replace melos for large monorepos.

---

## Customization quick reference

| Placeholder | Where used |
|-------------|------------|
| `{{PACKAGE_NAME}}` | README hygiene awk, smoke test commands |
| `{{GITHUB_OWNER}}/{{GITHUB_REPO}}` | pub.dev OIDC, CONTRIBUTING docs |
| `example/` | setup-flutter, pr-tests analysis |
| `tool/*` | extra workspaces, codegen scripts |
| `min_score` | pana-score action input |
| `paths-ignore` | ci-main, pr-tests triggers |
| `cli_artifacts` | release-tags github-release job |

---

## File tree (full single-package scaffold)

```
.github/
├── dependabot.yml
├── actions/
│   ├── setup-flutter/action.yaml
│   ├── package-hygiene/action.yaml
│   ├── flutter-package-checks/action.yaml
│   ├── pana-score/action.yaml
│   └── coverage-report/action.yaml
└── workflows/
    ├── ci-main.yml
    ├── pr-tests.yml
    ├── semantic-pr.yml
    ├── release-gate.yml
    ├── release-tags.yml
    ├── check-generation.yml      # optional
    ├── nightly.yml               # optional
    └── github-pages.yml          # optional
```

Supporting repo files:

```
LICENSE
NOTICE
CHANGELOG.md
.pubignore          # exclude doc/api/, build/, tool/
tool/license_checker.yaml   # if using license_checker
CONTRIBUTING.md     # include pub.dev OIDC section
```
