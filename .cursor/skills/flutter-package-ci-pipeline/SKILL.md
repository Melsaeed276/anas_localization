---
name: flutter-package-ci-pipeline
description: >-
  Design, scaffold, audit, and adapt GitHub Actions CI/CD for Flutter/Dart pub
  packages — composite actions, PR/main/release workflows, OIDC pub publish,
  Dependabot, semantic PRs, codegen drift checks, pana gates. Use when setting up
  or improving package pipelines, GitHub Actions, release automation, or
  copying CI patterns to a new Flutter/Dart library project.
---

# Flutter Package CI/CD Pipeline

Reusable pipeline pattern distilled from **bloc**, **riverpod**, **Very Good Workflows**, and **flutter/packages**, validated on production packages.

## When to use

- New Flutter/Dart **library** (pub package) needs GitHub Actions
- Existing package CI needs audit, DRY refactor, or release automation
- User asks for pub.dev publish automation, Dependabot, or package quality gates

## Quick start (new project)

1. **Profile the project** — fill [project-profile.md](project-profile.md)
2. **Copy scaffold** — create `.github/actions/` + `.github/workflows/` per profile toggles
3. **Customize placeholders** — package name, repo, paths, optional jobs
4. **Validate locally** — `dart format`, `flutter analyze`, `flutter test`, `flutter pub publish --dry-run`, `pana .`
5. **Configure pub.dev OIDC** — one-time admin setup (see [reference.md](reference.md#pubdev-oidc-setup))
6. **Enable Dependabot** — `.github/dependabot.yml` with project's pub workspaces

## Architecture

```
Pull Request ─┬─ semantic-pr.yml          (PR title convention)
              ├─ pr-tests.yml           (multi-OS lint + test + dry-run)
              ├─ release-gate.yml       (main-target PR: version/changelog/pana)
              ├─ check-generation.yml   (optional: codegen drift)
              └─ project-specific.yml   (benchmarks, migration, docs)

Push main ────┬─ ci-main.yml             (lint → test → publish dry-run)
              └─ check-generation.yml

Push tag v* ──┬─ release-tags.yml
              │    ├─ release-gate  (validate)
              │    ├─ publish       (OIDC → pub.dev)
              │    └─ github-release (optional CLI artifacts)

Schedule ─────┬─ nightly.yml
              └─ dependabot.yml (weekly PRs)
```

## Composite actions (DRY core)

Always prefer composite actions over duplicated workflow steps.

| Action | Purpose |
|--------|---------|
| `setup-flutter` | Flutter SDK + `pub get` for root and optional workspaces |
| `package-hygiene` | README, LICENSE/NOTICE, license_checker, changelog-on-bump |
| `flutter-package-checks` | `dart format`, `flutter analyze`, `flutter test` (+ random seed) |
| `pana-score` | pub.dev quality gate (default min 130/160) |
| `coverage-report` | lcov summary, JUnit from machine report, artifacts |

Scaffold copies: [reference.md](reference.md#composite-action-templates)

## Workflow inventory

| Workflow | Trigger | Required? | Notes |
|----------|---------|-----------|-------|
| `ci-main.yml` | push `main` | Yes | `paths-ignore` for docs-only changes |
| `pr-tests.yml` | all PRs | Yes | OS matrix: ubuntu, macos, windows |
| `semantic-pr.yml` | PR events | Recommended | Conventional PR titles |
| `release-gate.yml` | PR → `main` | Yes for publishable packages | Strict changelog + smoke checks |
| `release-tags.yml` | tag `v*.*.*` | Yes if publishing | 3 jobs: validate → publish → GH release |
| `check-generation.yml` | path-filtered | If codegen committed | `generate && git diff --exit-code` |
| `dependabot.yml` | weekly | Recommended | pub + github-actions |
| `nightly.yml` | cron | Optional | Full suite + benchmarks |
| `github-pages.yml` | push/PR | Optional | MkDocs or static docs |

## Project adaptation checklist

Before generating files, determine:

```
Project profile:
- [ ] Package name and README usage grep pattern
- [ ] Default branch (main/master)
- [ ] Workspaces: example/, tool/*, packages/* (list paths)
- [ ] Has committed generated code? → check-generation.yml
- [ ] Has CLI binaries for GitHub Release? → release artifact step
- [ ] Has custom smoke tests? → release-gate generator step
- [ ] License checker config path (or disable)
- [ ] Min pana score (run `pana .` first)
- [ ] Docs site (MkDocs) → github-pages.yml
- [ ] Monorepo? → use melos/paths-filter instead of single-package actions
```

Full template: [project-profile.md](project-profile.md)

## Adaptation rules

### Package name in hygiene checks

Replace README usage awk pattern with project identifiers:

```bash
# Example for package "my_package":
$0 ~ /(my_package|MyPackage)/
```

### setup-flutter workspaces

Add `install_<workspace>` inputs for each extra `pubspec.yaml` (example, tool apps). Remove unused inputs in consuming workflows.

### Multi-OS PR matrix

Run expensive checks (lychee, `dart doc`, pana) on `ubuntu-latest` only. Format/analyze on all OSes to catch path issues.

### Release tag pattern

Must match pub.dev OIDC config:

- Git tag: `v0.1.0`
- pubspec: `version: 0.1.0`
- pub.dev tag pattern: `v{{version}}`

### OIDC publish constraints

- Publish job **only** on tag push (not `workflow_dispatch`, not branch push)
- Job needs `permissions: id-token: write`
- Use official `dart-lang/setup-dart/.github/workflows/publish.yml@v1`

### Dependabot pub directories

List every directory with its own `pubspec.yaml`. Root library packages typically **omit** `pubspec.lock`; Dependabot still works on `pubspec.yaml`.

### Optional: approval gate before publish

Add `environment: pub.dev` to publish job and configure matching environment on pub.dev admin + GitHub repo settings.

## Implementation workflow for the agent

When user asks to set up or port this pipeline:

1. Read target project: `pubspec.yaml`, `example/`, `tool/`, existing `.github/`, `CHANGELOG.md`, `.pubignore`
2. Fill project profile (ask user for repo owner/name if unclear)
3. Create composite actions first (stable foundation)
4. Create workflows from smallest to largest: `semantic-pr` → `ci-main` → `pr-tests` → `release-gate` → `release-tags` → `dependabot`
5. Add optional workflows only if profile flags them
6. Run local gates: `dart analyze`, `flutter test`, `pana .`, `flutter pub publish --dry-run`
7. Document pub.dev OIDC setup in `CONTRIBUTING.md` (brief section)

## Patterns from famous packages

| Source | Pattern adopted |
|--------|-----------------|
| bloc | Composite actions, semantic PR, pana gate, test randomization |
| riverpod | `paths-ignore` for markdown, separate codegen drift workflow |
| Very Good Workflows | Reusable job structure, coverage artifacts |
| flutter/packages | OIDC publish, Dependabot for pub + actions |
| dart.dev | `dart-lang/setup-dart` publish workflow, no long-lived secrets |

## Anti-patterns

- Do **not** put `dart pub publish` in a branch-triggered workflow (OIDC fails)
- Do **not** duplicate 50-line hygiene blocks across workflows — use composites
- Do **not** require `pubspec.lock` in library root packages
- Do **not** ship `doc/api/` to pub.dev — exclude via `.pubignore`, generate in CI before dry-run
- Do **not** use `workflow_dispatch` for production publish

## Install

```bash
# This skill only
curl -fsSL https://raw.githubusercontent.com/Melsaeed276/cursor-skills/main/skills/flutter-package-ci-pipeline/install.sh | bash

# Or via root installer
curl -fsSL https://raw.githubusercontent.com/Melsaeed276/cursor-skills/main/scripts/install.sh | bash -s -- flutter-package-ci-pipeline
```

Then invoke: *"Use the flutter-package-ci-pipeline skill to set up CI for this project."*

## Additional resources

- Composite action + workflow templates: [reference.md](reference.md)
- Per-project customization form: [project-profile.md](project-profile.md)
- Reference implementation: [anas_localization `.github/`](https://github.com/Melsaeed276/anas_localization/tree/main/.github)
- Skills collection: [github.com/Melsaeed276/cursor-skills](https://github.com/Melsaeed276/cursor-skills)
