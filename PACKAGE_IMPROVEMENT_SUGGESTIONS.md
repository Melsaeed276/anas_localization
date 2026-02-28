# Package Improvement Roadmap (Detailed TODO)

This roadmap lists all high-value additions needed to move `anas_localization`
from "works well" to "best-in-class Flutter localization package".

Use this as the implementation backlog and release checklist.

## Success criteria

- Pub package is easy to adopt for existing Flutter teams.
- API remains predictable for simple apps and scalable for large apps.
- CLI and generator are reliable for real production workflows.
- Documentation clearly explains migration and tradeoffs.
- Quality gates prevent regressions before publishing.

---

## Milestone 1: Compatibility and Core Architecture

### 1) ARB + `gen_l10n` compatibility bridge
- [ ] Add ARB import mode (`*.arb` -> internal JSON model).
- [ ] Add ARB export mode (internal JSON model -> `*.arb`).
- [ ] Support `l10n.yaml` parsing for source/default locale directories.
- [ ] Preserve ICU messages, placeholders, and metadata when round-tripping.
- [ ] Add CLI commands:
  - [ ] `anas_cli import --from-arb <dir>`
  - [ ] `anas_cli export --to-arb <dir>`
- [ ] Document migration path from Flutter official i18n.

**Definition of done**
- Existing ARB projects can adopt package without rewriting translation files.
- Round-trip tests pass for plural/select/placeholders.

### 2) Locale fallback chain with script/region awareness
- [ ] Implement deterministic fallback algorithm:
  - `language_script_region`
  - `language_script`
  - `language_region` (optional fallback branch)
  - `language`
  - global fallback locale
- [ ] Add support for script-aware locales (`zh_Hans`, `zh_Hant`, etc.).
- [ ] Add API to inspect resolved fallback path for debugging.

**Definition of done**
- `Locale('zh', 'CN', scriptCode: 'Hans')` resolves in expected order.
- Tests cover language-only, language+country, language+script+country.

### 3) Pluggable translation loaders
- [ ] Introduce `TranslationLoader` abstraction.
- [ ] Provide built-in loaders:
  - [ ] Asset JSON loader
  - [ ] Asset YAML loader (optional dependency)
  - [ ] Asset CSV loader
  - [ ] Remote HTTP loader (with timeout/retry)
- [ ] Add composition mode: package defaults + app overrides + remote overrides.
- [ ] Keep current behavior as default (zero-break change).

**Definition of done**
- Loader can be swapped by constructor/config.
- Existing users get identical behavior without config changes.

---

## Milestone 2: Codegen and CLI Excellence

### 4) Codegen watch mode and incremental generation
- [ ] Add `localization_gen --watch`.
- [ ] File system watch on language directory.
- [ ] Incremental regeneration only for changed locales/keys.
- [ ] Clear diagnostics output (changed files, generated symbols, warnings).

**Definition of done**
- Generator updates output automatically on file save.
- Regeneration for a single-file change is fast (<1 second in sample app).

### 5) Namespace/module-based generation
- [ ] Support splitting generated APIs by domain:
  - [ ] `auth.*`, `home.*`, `settings.*`
- [ ] Generate optional nested accessors for grouped keys.
- [ ] Add config options in generation command and docs.

**Definition of done**
- Large projects can avoid a single huge dictionary class.
- Generated API remains type-safe and conflict-free.

### 6) CLI hardening
- [ ] Add `--dry-run` mode for mutating commands.
- [ ] Add automatic backup before write (`.bak` or timestamped snapshot).
- [ ] Add conflict detection when importing to existing keys.
- [ ] Standardize exit codes:
  - `0` success
  - `1` validation/usage error
  - `2` file IO/parsing error
- [ ] Add machine-readable output option (`--json`) for CI pipelines.

**Definition of done**
- CLI is safe to use in automation and local edits.
- Failures are explicit and script-friendly.

### 7) CLI import/export test suite
- [ ] Add integration tests for:
  - [ ] CSV escaping/quotes/newlines
  - [ ] malformed rows
  - [ ] nested keys
  - [ ] import merge/overwrite rules
  - [ ] JSON schema mismatch
- [ ] Add large-file smoke test.

**Definition of done**
- Import/export behaves predictably on messy real-world datasets.

---

## Milestone 3: Validation and Quality

### 8) Validator strictness modes
- [ ] Add mode flags:
  - [ ] `strict` (extras are errors)
  - [ ] `balanced` (extras warnings, missing errors)
  - [ ] `lenient` (warnings only)
- [ ] Add per-rule toggles:
  - [ ] key set consistency
  - [ ] placeholder names
  - [ ] placeholder optional/required markers
  - [ ] plural form presence
  - [ ] gender form presence
- [ ] Add report summary counts for CI (`errors`, `warnings`, `files`).

**Definition of done**
- Teams can tune enforcement by project maturity.

### 9) Cross-locale integration tests
- [ ] Add dedicated tests for:
  - [ ] nested keys
  - [ ] plural shape consistency across locales
  - [ ] gender-aware forms
  - [ ] fallback chain behavior
  - [ ] preview dictionaries vs asset loader precedence
- [ ] Add regression tests for known bugs.

**Definition of done**
- Core localization rules are locked by tests and remain stable.

### 10) Performance and scalability benchmarks
- [ ] Add benchmark harness:
  - [ ] cold load time
  - [ ] locale switch time
  - [ ] memory usage with large dictionaries
- [ ] Benchmark at 1k, 5k, 10k translation keys.
- [ ] Add optional in-memory cache tuning.

**Definition of done**
- Performance baselines are documented and tracked in CI or manual release checks.

---

## Milestone 4: Adoption, Docs, and Release Trust

### 11) Migration guides
- [ ] Add guide: Flutter official `gen_l10n` -> `anas_localization`.
- [ ] Add guide: `easy_localization` -> `anas_localization`.
- [ ] Add guide for mixed approach (gradual migration).
- [ ] Include common pitfalls and rollback plan.

**Definition of done**
- Teams can migrate with minimal risk and clear steps.

### 12) "Why choose this package" section
- [ ] Add comparison table in README:
  - [ ] official Flutter i18n
  - [ ] `easy_localization`
  - [ ] `slang`
  - [ ] this package
- [ ] Highlight differentiators:
  - [ ] package+app merge model
  - [ ] Arabic gender/plural handling
  - [ ] integrated CLI + generator
  - [ ] setup overlay widgets

**Definition of done**
- Value proposition is clear to new users on first read.

### 13) End-to-end example apps
- [ ] Keep current simple example.
- [ ] Add medium example (feature modules + nested keys + CLI workflow).
- [ ] Add advanced example (remote loader + fallback chain + script locales).
- [ ] Add screenshots/GIFs for each.

**Definition of done**
- Users can copy real patterns, not only toy setup.

### 14) CI release checks
- [ ] Add workflow gate for:
  - [ ] semantic version consistency
  - [ ] changelog entry required for version bump
  - [ ] `flutter pub publish --dry-run`
  - [ ] generator smoke test in example app
- [ ] Add PR status checks for critical paths.

**Definition of done**
- No publish can happen with missing changelog/version/test gates.

### 15) Pub.dev polish
- [ ] Add badges (pub version, likes, points, CI, coverage).
- [ ] Add screenshots/GIFs in README.
- [ ] Improve API docs for public classes and exceptions.
- [ ] Add topic tags and keyword optimization for discoverability.
- [ ] Add `CONTRIBUTING.md` and `SECURITY.md`.

**Definition of done**
- Package page looks complete and trustworthy to first-time evaluators.

---

## Suggested release plan

### `v1.0.1` (stabilization)
- Typed exceptions
- Validator correctness and unification
- CLI command completion and alias
- Nested key support baseline
- README CLI docs and test coverage updates

### `v1.1.0` (compatibility + DX)
- ARB bridge
- Fallback chain overhaul
- Loader abstraction (JSON + one additional loader)
- Watch mode

### `v1.2.0` (quality + scalability)
- Strict validator modes
- Benchmark suite
- Extended integration tests
- Namespace generation options

### `v2.0.0` (ecosystem-grade)
- Full migration toolkit
- Advanced examples
- Release governance gates
- polished pub.dev presentation
