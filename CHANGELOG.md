## Unreleased

* Added namespaced/module dictionary generation options: `--modules`, `--modules-only`, and `--module-depth`.
* Added standalone Catalog UI sidecar (`catalog serve`) with Swift String Catalog-style table editing, review actions, and status badges.
* Added Create New String workflow (`+ New String` UI and `catalog add-key` CLI) with dotted key validation and per-locale value inputs.
* Added new key status behavior: all locales filled at creation => `green`; partial creation => `warning` with `new_key_needs_translation_review`.
* Added catalog API endpoints for key creation, cell update/delete, review marking, summary, and metadata.
* Added CLI catalog command group (`init`, `status`, `serve`, `add-key`, `review`, `delete-key`) and `dev --with-catalog` sidecar mode.
* Added catalog unit/integration/CLI tests covering create-key states, duplicate rejection, API behavior, and state persistence across restart.
* Added `doc/SETUP_AND_USAGE.md` with end-to-end setup, runtime usage, and catalog workflow instructions.
* Added validator strictness profiles (`strict`, `balanced`, `lenient`) with per-rule toggles and CLI wiring.
* Added placeholder schema validation (required/type/format/select values) with ARB metadata support and optional `--schema-file` sidecar.
* Added benchmark harness for 1k/5k/10k datasets with cold-load, hot-switch, and memory RSS metrics.
* Added expanded regression coverage for nested/plural/gender/fallback behaviors and malformed CLI import/export inputs.
* Added migration guide from `easy_localization` and expanded migration guide from Flutter `gen_l10n`, including rollback notes.
* Added README positioning updates with badges, "Why this package", and a competitor comparison matrix.
* Added medium/advanced example matrix documentation with visual output diagrams.
* Added release-gating CI workflow for version/changelog checks, generator smoke checks, and `pub publish --dry-run`.
* Added `CONTRIBUTING.md` and `SECURITY.md` to improve package trust and contribution onboarding.
* Fixed ARB locale extraction from filenames to preserve full locale tails (for example `en_US`, `zh_Hant_TW`).
* Fixed rule toggle override semantics so profile defaults (for example lenient checks) are preserved unless explicitly overridden.
* Fixed benchmark CI workflow to use Flutter SDK setup and `flutter pub` commands.

## 0.1.0

* Added runtime `LocalizationService.configure(...)` to set asset path and supported locales in one place.
* Added Flutter preview support via `previewDictionaries` on `AnasLocalization` and service-level preview dictionary APIs.
* Fixed async locale change behavior by awaiting locale save in `setLocale`.
* Improved saved locale parsing normalization and country/language casing.
* Added tests for Flutter preview dictionaries and widget configuration wiring.
* Updated README with Flutter preview usage and fixed conflicting `assetPath` example.
* Added pre-launch hardening: typed localization exceptions, unified validators, nested key support, and expanded CLI workflows.

## 0.0.1

* Initial release: JSON-based translations, dictionary code generation, pluralization/gender support, and runtime locale switching.
