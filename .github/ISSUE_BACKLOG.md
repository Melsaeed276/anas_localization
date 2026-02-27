# GitHub Issue Backlog (Priority + Labels + Dependencies)

This file converts `PACKAGE_IMPROVEMENT_SUGGESTIONS.md` into actionable GitHub issues.

## Label Taxonomy

- Priority: `P0`, `P1`, `P2`, `P3`
- Type: `type:feature`, `type:enhancement`, `type:docs`, `type:test`, `type:ci`
- Area: `area:core`, `area:validator`, `area:cli`, `area:generator`, `area:docs`, `area:ci`, `area:examples`, `area:performance`
- Status: `status:ready`, `status:blocked` (optional)

## Ordered Issue List

### 1) Typed exception model across runtime API
- Priority: `P0`
- Labels: `P0`, `type:enhancement`, `area:core`, `status:ready`
- Milestone: `v1.0.1`
- Depends on: none
- Title: `feat(core): introduce typed localization exceptions and replace generic Exception throws`
- Scope:
  - Add public exception hierarchy for unsupported locale, missing assets, and uninitialized access.
  - Replace runtime generic `Exception` throws with typed exceptions in service/manager/widget APIs.
  - Export exception types from package entrypoint.
- Acceptance criteria:
  - Public API throws typed exceptions for known failure cases.
  - Existing behavior is preserved except exception types.
  - Unit tests assert specific exception types.

### 2) Validator correctness + nested key support
- Priority: `P0`
- Labels: `P0`, `type:enhancement`, `area:validator`, `status:ready`
- Milestone: `v1.0.1`
- Depends on: none
- Title: `fix(validator): correct placeholder comparison and support nested key-path validation`
- Scope:
  - Fix set comparison to compare content, not object identity.
  - Resolve placeholders via nested key paths (`a.b.c`).
  - Keep strict and warning modes configurable.
- Acceptance criteria:
  - No false-positive placeholder mismatches.
  - Nested key placeholders are validated.
  - Add regression tests for nested and mismatch cases.

### 3) Unify library validator and bin validator
- Priority: `P0`
- Labels: `P0`, `type:enhancement`, `area:validator`, `area:cli`, `status:ready`
- Milestone: `v1.0.1`
- Depends on: `#2`
- Title: `refactor(validator): route bin validate_translations through core validator engine`
- Scope:
  - Remove duplicate validation logic from bin script.
  - Delegate to library validator API with master-file mode.
  - Keep CLI output human-friendly.
- Acceptance criteria:
  - Single source of truth for validation logic.
  - Bin and library validation produce consistent results.

### 4) Complete CLI command implementations
- Priority: `P0`
- Labels: `P0`, `type:feature`, `area:cli`, `status:ready`
- Milestone: `v1.0.1`
- Depends on: none
- Title: `feat(cli): implement add-locale, translate, remove-key, export, import with real file operations`
- Scope:
  - Implement missing commands and argument validation.
  - Add deterministic exit codes for success/failure.
  - Ensure nested key path operations work.
- Acceptance criteria:
  - All listed commands perform real work.
  - Failed command returns non-zero exit code.
  - Integration tests cover success and error paths.

### 5) Add CLI alias and executable consistency
- Priority: `P1`
- Labels: `P1`, `type:enhancement`, `area:cli`, `status:ready`
- Milestone: `v1.0.1`
- Depends on: `#4`
- Title: `chore(cli): add cli alias executable and align command examples`
- Scope:
  - Add `bin/cli.dart` alias.
  - Declare both `anas_cli` and `cli` executables.
  - Update help/examples to valid commands.
- Acceptance criteria:
  - `dart run anas_localization:anas_cli help` works.
  - `dart run anas_localization:cli help` works.

### 6) Nested key generation support in codegen
- Priority: `P0`
- Labels: `P0`, `type:feature`, `area:generator`, `status:ready`
- Milestone: `v1.0.1`
- Depends on: none
- Title: `feat(generator): generate APIs for nested translation keys and nested plural maps`
- Scope:
  - Flatten translatable entries and generate members for nested paths.
  - Keep plural/gender logic intact for nested nodes.
  - Sanitize identifiers for dotted keys.
- Acceptance criteria:
  - Generator emits APIs for keys like `supported_languages.en`.
  - Generated code compiles and tests pass.

### 7) Runtime nested lookup support
- Priority: `P1`
- Labels: `P1`, `type:enhancement`, `area:core`, `status:ready`
- Milestone: `v1.0.1`
- Depends on: none
- Title: `feat(core): support dotted key path lookup in Dictionary.getString/getPluralData`
- Scope:
  - Add path resolver in base `Dictionary`.
  - Use resolver in string/plural/key-existence APIs.
- Acceptance criteria:
  - `getString('a.b.c')` works for nested maps.
  - Existing flat keys remain unchanged.

### 8) ARB + gen_l10n bridge
- Priority: `P1`
- Labels: `P1`, `type:feature`, `area:generator`, `area:core`, `status:ready`
- Milestone: `v1.1.0`
- Depends on: `#2`, `#6`
- Title: `feat(interop): add ARB import/export and l10n.yaml compatibility mode`
- Scope:
  - Import ARB files into package model.
  - Export package model back to ARB.
  - Read key l10n settings from `l10n.yaml`.
- Acceptance criteria:
  - ARB round-trip preserves placeholders/plurals.
  - Migration docs from `gen_l10n` are provided.

### 9) Locale fallback chain (language/script/region)
- Priority: `P1`
- Labels: `P1`, `type:feature`, `area:core`, `status:ready`
- Milestone: `v1.1.0`
- Depends on: none
- Title: `feat(core): implement deterministic locale fallback chain with script-aware resolution`
- Scope:
  - Resolve `lang_script_region -> lang_script -> lang_region -> lang -> fallback`.
  - Add tracing/debug API for fallback path used.
- Acceptance criteria:
  - Comprehensive tests for script/country scenarios.
  - Backward-compatible defaults.

### 10) Pluggable translation loader architecture
- Priority: `P1`
- Labels: `P1`, `type:feature`, `area:core`, `status:ready`
- Milestone: `v1.1.0`
- Depends on: `#9`
- Title: `feat(core): introduce TranslationLoader abstraction with JSON/YAML/CSV/remote implementations`
- Scope:
  - Define loader interface.
  - Implement JSON asset loader first, then optional YAML/CSV/HTTP loaders.
  - Preserve existing default behavior.
- Acceptance criteria:
  - Loader can be injected/configured.
  - Existing users have zero required migration.

### 11) Generator watch mode
- Priority: `P2`
- Labels: `P2`, `type:feature`, `area:generator`, `status:ready`
- Milestone: `v1.1.0`
- Depends on: `#6`
- Title: `feat(generator): add --watch mode with incremental regeneration`
- Scope:
  - File watcher on language directory.
  - Regenerate only changed artifacts where possible.
  - Clear terminal diagnostics.
- Acceptance criteria:
  - Watch mode updates generated output on file save.
  - Documented usage in README.

### 12) Namespace/module generation options
- Priority: `P2`
- Labels: `P2`, `type:feature`, `area:generator`, `status:ready`
- Milestone: `v1.2.0`
- Depends on: `#6`
- Title: `feat(generator): support namespaced output and module-based dictionary classes`
- Scope:
  - Split generation by key prefixes/domains.
  - Avoid collisions and keep API ergonomic.
- Acceptance criteria:
  - Large localization files can be split cleanly.
  - Add test fixtures for multi-module generation.

### 13) Validator mode framework (strict/balanced/lenient)
- Priority: `P2`
- Labels: `P2`, `type:enhancement`, `area:validator`, `status:ready`
- Milestone: `v1.2.0`
- Depends on: `#2`
- Title: `feat(validator): add strictness profiles and per-rule toggles`
- Scope:
  - Profiles: strict, balanced, lenient.
  - Toggle rules for keys, placeholders, plural forms, gender forms.
- Acceptance criteria:
  - Validation can be tuned for team maturity.
  - CI can run strict mode deterministically.

### 14) Performance benchmark suite
- Priority: `P2`
- Labels: `P2`, `type:test`, `area:performance`, `status:ready`
- Milestone: `v1.2.0`
- Depends on: `#10`
- Title: `test(perf): add benchmark harness for load/switch latency and memory usage`
- Scope:
  - Benchmarks for 1k/5k/10k keys.
  - Measure cold load, hot switch, and memory.
  - Document baseline numbers.
- Acceptance criteria:
  - Benchmark script reproducible locally and in CI.
  - Performance regressions become visible.

### 15) Expanded integration tests
- Priority: `P1`
- Labels: `P1`, `type:test`, `area:core`, `area:validator`, `area:cli`, `status:ready`
- Milestone: `v1.2.0`
- Depends on: `#2`, `#4`, `#6`, `#9`
- Title: `test(integration): add cross-locale regression coverage for nested/plural/gender/fallback behaviors`
- Scope:
  - Add full-path regression tests for cross-locale consistency.
  - Add CLI import/export edge-case tests.
- Acceptance criteria:
  - Test suite catches prior classes of bugs.
  - Includes negative scenarios and malformed input handling.

### 16) Migration guides (official i18n + easy_localization)
- Priority: `P1`
- Labels: `P1`, `type:docs`, `area:docs`, `status:ready`
- Milestone: `v2.0.0`
- Depends on: `#8`, `#10`
- Title: `docs(migration): add complete migration guides from gen_l10n and easy_localization`
- Scope:
  - Step-by-step migration docs.
  - Rollback plan and compatibility notes.
- Acceptance criteria:
  - New adopters can migrate without guesswork.

### 17) README package positioning and comparison matrix
- Priority: `P2`
- Labels: `P2`, `type:docs`, `area:docs`, `status:ready`
- Milestone: `v2.0.0`
- Depends on: `#8`, `#9`, `#10`
- Title: `docs(readme): add "Why this package" section and competitor comparison table`
- Scope:
  - Compare against official i18n, easy_localization, slang.
  - Highlight package differentiators and constraints.
- Acceptance criteria:
  - README makes adoption value immediately clear.

### 18) Example app matrix
- Priority: `P2`
- Labels: `P2`, `type:enhancement`, `area:examples`, `status:ready`
- Milestone: `v2.0.0`
- Depends on: `#8`, `#10`
- Title: `feat(examples): add medium and advanced example apps with real project structures`
- Scope:
  - Medium app: feature modules + nested keys.
  - Advanced app: fallback chain + remote loader + CLI workflow.
- Acceptance criteria:
  - Each example includes run instructions and screenshots.

### 19) CI release governance
- Priority: `P1`
- Labels: `P1`, `type:ci`, `area:ci`, `status:ready`
- Milestone: `v2.0.0`
- Depends on: none
- Title: `ci(release): add version/changelog/publish-dry-run gating workflow`
- Scope:
  - Enforce version + changelog alignment.
  - Enforce publish dry-run and generator smoke checks.
- Acceptance criteria:
  - Release PRs fail fast on packaging hygiene issues.

### 20) Pub.dev polish and trust assets
- Priority: `P3`
- Labels: `P3`, `type:docs`, `area:docs`, `status:ready`
- Milestone: `v2.0.0`
- Depends on: `#17`, `#18`
- Title: `docs(pub): add badges, screenshots, API examples, CONTRIBUTING, SECURITY`
- Scope:
  - Improve package page completeness and community trust.
- Acceptance criteria:
  - pub.dev page has strong onboarding quality.

---

## Suggested triage order for maintainers

1. Create issues `#1` through `#7` first (stabilization + correctness).
2. Mark `#8` to `#12` as next milestone planning.
3. Keep `#13` to `#20` as growth track with documented dependencies.

## Optional `gh` workflow (after login)

Run:

```bash
gh auth login
```

Then create labels and issues using this file as source of truth.
