## Unreleased

* Added namespaced/module dictionary generation options: `--modules`, `--modules-only`, and `--module-depth`.
* Added validator strictness profiles (`strict`, `balanced`, `lenient`) with per-rule toggles and CLI wiring.
* Added benchmark harness for 1k/5k/10k datasets with cold-load, hot-switch, and memory RSS metrics.
* Added expanded regression coverage for nested/plural/gender/fallback behaviors and malformed CLI import/export inputs.
* Added migration guide from `easy_localization` and expanded migration guide from Flutter `gen_l10n`, including rollback notes.
* Added README positioning updates with badges, "Why this package", and a competitor comparison matrix.
* Added medium/advanced example matrix documentation with visual output diagrams.
* Added release-gating CI workflow for version/changelog checks, generator smoke checks, and `pub publish --dry-run`.
* Added `CONTRIBUTING.md` and `SECURITY.md` to improve package trust and contribution onboarding.

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
