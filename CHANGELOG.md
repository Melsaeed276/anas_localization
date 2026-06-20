## 0.1.5 - 2026-06-19

* Internal: consolidated `lib/` into a feature-first layout (`features/{localization,catalog,migration}/` with `data`/`domain`/`presentation` layers, plus `shared/`). No public API or behavior changes — legacy paths (`src/utils/`, `src/catalog/`, `src/api/`, `src/core/translation_loader.dart`) remain as export shims.
* Internal: Catalog now depends on Localization through `domain/contracts/` interfaces instead of concrete classes, enforcing clean feature boundaries.
* Internal: added `tool/check_shim_exports.dart` regression guard (runs in CI) to keep legacy paths export-only; reorganized tests under `test/features/` and `test/shared/`.

## 0.1.4 - 2026-06-05

* Fixed `_extractNamedExpression` in `migration_helper.dart` to use source-text pattern matching instead of `is NamedExpression`, which was removed from the analyzer public API in v13.

## 0.1.3 - 2026-06-05

* Extracted `hasCircularFallback`, `resolveFallbackChain`, `getLanguageCode`, `sameLanguageGroup` into a `dart:io`-free helper file (`catalog_fallback_helpers.dart`) so the public library no longer transitively imports `dart:io`, enabling full platform support (iOS, Android, Web, Windows, macOS, Linux).

## 0.1.2 - 2026-06-05

* Fixed type errors in migration helper (`_extractStringLiteral` now accepts `AstNode` for compatibility with analyzer v13+ where `ArgumentList.arguments` returns `NodeList<Argument>` instead of `NodeList<Expression>`).
* Fixed `_buildGenL10nMethodReplacement` call to filter arguments with `.whereType<Expression>()` for analyzer v13+ compatibility.

## 0.1.1 - 2026-05-31

* Fixed migration helper compatibility with analyzer v13 (`NamedExpression` removed from public API, switched to source-text pattern matching).
* Widened analyzer constraint from `^10.0.1` to `>=10.0.1 <14.0.0` for broader SDK compatibility.
* Added pub.dev automated publishing workflow via `dart-lang/setup-dart/.github/workflows/publish.yml`.
* Fixed CHANGELOG version check in release workflows (removed strict line-end anchor).
* Added consumer E2E integration test suite for CLI and codegen workflows.
* Improved type handling in migration helper (`Expression` type guards, `whereType` filtering).
* Stabilized CI test suite and resolved pre-existing test failures.
* Updated package description for clarity and conciseness.

## 0.1.0 - 2026-05-19

* English localization alignment: shared base `en` with regional overlays (`en_US`, `en_GB`, `en_CA`, `en_AU`), one/other-only plural validation for English locales, validator and docs clarify English-scope boundaries and locale notation (underscore in file names, hyphen in user-facing labels).
* Added `AnasDateTimeFormatter.preferredDateSkeleton` returning region-correct date-order patterns (M/d/y for en_US, d/M/y for en_GB and en_AU, y-MM-dd for en_CA).
* Added `AnasNumberFormatter.defaultCurrencyCode` returning ISO 4217 currency codes for regional English locales (USD, GBP, CAD, AUD).
* Exposed `TranslationValidator.isEnglishLocale` and `TranslationValidator.requiredPluralFormsForLocale` as public static methods for custom tooling and Catalog UI.
* Added package-level regional English asset files (`assets/lang/en_US.json`, `assets/lang/en_GB.json`, `assets/lang/en_CA.json`, `assets/lang/en_AU.json`) with spelling and locale-convention overrides.
* Expanded `doc/reference/file-structure.md` with a regional English overlays section, English-vs-Arabic scope comparison table, and validator behavior notes.
* Added namespaced/module dictionary generation options: `--modules`, `--modules-only`, and `--module-depth`.
* Added standalone Catalog UI sidecar (`catalog serve`) with Swift String Catalog-style table editing, review actions, and status badges.
* Catalog UI: added `hide_catalog_ui_keys` (default `true`) to hide catalog chrome strings from the editor; disable it if your project legitimately uses the same key names (for example `refresh`).
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
* Added runtime `LocalizationService.configure(...)` to set asset path and supported locales in one place.
* Added Flutter preview support via `previewDictionaries` on `AnasLocalization` and service-level preview dictionary APIs.
* Fixed async locale change behavior by awaiting locale save in `setLocale`.
* Improved saved locale parsing normalization and country/language casing.
* Added tests for Flutter preview dictionaries and widget configuration wiring.
* Updated README with Flutter preview usage and fixed conflicting `assetPath` example.
* Added pre-launch hardening: typed localization exceptions, unified validators, nested key support, and expanded CLI workflows.

## 0.0.1

* Initial release: JSON-based translations, dictionary code generation, pluralization/gender support, and runtime locale switching.
