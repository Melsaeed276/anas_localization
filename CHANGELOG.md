## [1.2.1](https://github.com/Melsaeed276/anas_localization/compare/v1.2.0...v1.2.1) (2026-07-17)

### Bug Fixes

* **ci:** reset release version baseline to 1.2.x after mis-bumped 1.4.0/1.5.0 releases ([#195](https://github.com/Melsaeed276/anas_localization/issues/195))

## [1.5.0](https://github.com/Melsaeed276/anas_localization/compare/v1.4.0...v1.5.0) (2026-07-20)


### Features

* add init and source_locale commands to CLI, enhance locale file… ([#112](https://github.com/Melsaeed276/anas_localization/issues/112)) ([7baba39](https://github.com/Melsaeed276/anas_localization/commit/7baba3970eff7f84380e0441b953b9f187e55dcd))
* finish v1.0.1 validation, cli, generator and runtime coverage ([#65](https://github.com/Melsaeed276/anas_localization/issues/65)) ([97ecd0e](https://github.com/Melsaeed276/anas_localization/commit/97ecd0e42510815f6bc26a53a923b31d9d413ef0))
* **github:** auto-apply form labels, stale bot, PR labeler, CODEOWNERS ([#171](https://github.com/Melsaeed276/anas_localization/issues/171)) ([e958c4a](https://github.com/Melsaeed276/anas_localization/commit/e958c4a918802c187550c8d004a41430f7e0fce7))
* **github:** auto-detect duplicate issues, merge, close, and bump priority ([#170](https://github.com/Melsaeed276/anas_localization/issues/170)) ([c2a30ba](https://github.com/Melsaeed276/anas_localization/commit/c2a30baddbf4423dcf77313b5dea9ee3148946b2))
* Remote Localization V1 ([#155](https://github.com/Melsaeed276/anas_localization/issues/155)) ([773ebd2](https://github.com/Melsaeed276/anas_localization/commit/773ebd2245540d29007b9ea414603f43da8aa0b6))
* **v1.2.0:** generator modules, validator profiles, benchmarks, integration regressions ([#77](https://github.com/Melsaeed276/anas_localization/issues/77)) ([904ea25](https://github.com/Melsaeed276/anas_localization/commit/904ea255b328efe49d96fb3eae4acb89d3d6aaa9))


### Bug Fixes

* **ci:** compare tag with v-prefix against pubspec version ([#204](https://github.com/Melsaeed276/anas_localization/issues/204)) ([aff16ec](https://github.com/Melsaeed276/anas_localization/commit/aff16ecc6c24e995329f75d6b19b97053cdbcfdf))
* **ci:** force next release to 1.2.1 via release-as ([#195](https://github.com/Melsaeed276/anas_localization/issues/195)) ([f218e41](https://github.com/Melsaeed276/anas_localization/commit/f218e413ddd2e8b1dbe4ebe72af80daa36d5c5c2))
* **ci:** pin Release Please to 1.2.0, gate pub.dev publish on PR checkbox ([#189](https://github.com/Melsaeed276/anas_localization/issues/189)) ([8c30a8c](https://github.com/Melsaeed276/anas_localization/commit/8c30a8ce8589acac203513774b1eb86256a3fbce))
* **ci:** pin release-please to v1.2.0 and auto-clear after release ([#192](https://github.com/Melsaeed276/anas_localization/issues/192)) ([19cbbf4](https://github.com/Melsaeed276/anas_localization/commit/19cbbf49874d722e93f9e4ece70359ea44526990))
* **ci:** publish to pub.dev from tag push, not branch push ([#157](https://github.com/Melsaeed276/anas_localization/issues/157)) ([f45b534](https://github.com/Melsaeed276/anas_localization/commit/f45b5340b18c8fe6ba27a2e7151fb90ff18ce1e0))
* **ci:** restore export shim and refresh catalog web bundle ([#151](https://github.com/Melsaeed276/anas_localization/issues/151)) ([1e31d6c](https://github.com/Melsaeed276/anas_localization/commit/1e31d6cf0013b90bd67775721efd530bd64af5e2))
* **ci:** use dart build exe instead of dart compile for release artifacts ([#205](https://github.com/Melsaeed276/anas_localization/issues/205)) ([3f09ea8](https://github.com/Melsaeed276/anas_localization/commit/3f09ea8c3c7c6c9cc5aff028d919ec99550fd0ea))
* guard same-language locale fallback to variants not in supported set ([#86](https://github.com/Melsaeed276/anas_localization/issues/86)) ([bc2c2f5](https://github.com/Melsaeed276/anas_localization/commit/bc2c2f5789ab7882058bfd952c9fa9b55b43034d))
* Implement Phase 6 validation fixes (Issues [#123](https://github.com/Melsaeed276/anas_localization/issues/123)-131) ([#132](https://github.com/Melsaeed276/anas_localization/issues/132)) ([29caeb8](https://github.com/Melsaeed276/anas_localization/commit/29caeb8eed536e2f7010961a180c3e6df1420f22))
* **remote:** apply remote translations to live dictionary after check ([#186](https://github.com/Melsaeed276/anas_localization/issues/186)) ([a5c94af](https://github.com/Melsaeed276/anas_localization/commit/a5c94af5f6e8ec26693a0a7b81c449105b3b5908))

## [1.2.0](https://github.com/Melsaeed276/anas_localization/compare/v1.1.0...v1.2.0) (2026-07-17)


### Bug Fixes

* merge remote translations into the live dictionary after a check ([#183](https://github.com/Melsaeed276/anas_localization/issues/183)) ([74b4975](https://github.com/Melsaeed276/anas_localization/commit/74b49755ca874a4c149f3374a183878e4131dfac))
* rebuild widget when remote updates are auto-applied on same-locale sync ([#184](https://github.com/Melsaeed276/anas_localization/issues/184)) ([c73c532](https://github.com/Melsaeed276/anas_localization/commit/c73c532a2e3f9c9a6a2e104e17f36025288b1cd0))
* resolve flat dotted resource-name keys in `getString` (e.g. `Bpm.Portal.Query.Inbox`) ([#185](https://github.com/Melsaeed276/anas_localization/issues/185)) ([1670057](https://github.com/Melsaeed276/anas_localization/commit/1670057dd631451a6bddb7521d9cafe951695fb9))
* case-insensitive flat-key lookup and trim remote payload key whitespace ([5e64c47](https://github.com/Melsaeed276/anas_localization/commit/5e64c47ffb24343f8c1f19251b118baa89b267a2))
* **remote:** apply remote translations to live dictionary after check ([#186](https://github.com/Melsaeed276/anas_localization/issues/186)) ([a5c94af](https://github.com/Melsaeed276/anas_localization/commit/a5c94af5f6e8ec26693a0a7b81c449105b3b5908))


## [1.1.0](https://github.com/Melsaeed276/anas_localization/compare/v1.0.0...v1.1.0) (2026-07-08)


### Bug Fixes

* **remote:** apply remote translations to live dictionary after check ([#186](https://github.com/Melsaeed276/anas_localization/issues/186)) ([a5c94af](https://github.com/Melsaeed276/anas_localization/commit/a5c94af5f6e8ec26693a0a7b81c449105b3b5908))

## [1.1.0](https://github.com/Melsaeed276/anas_localization/compare/v1.0.0...v1.1.0) (2026-07-08)


### Features

* add init and source_locale commands to CLI, enhance locale file… ([#112](https://github.com/Melsaeed276/anas_localization/issues/112)) ([7baba39](https://github.com/Melsaeed276/anas_localization/commit/7baba3970eff7f84380e0441b953b9f187e55dcd))
* finish v1.0.1 validation, cli, generator and runtime coverage ([#65](https://github.com/Melsaeed276/anas_localization/issues/65)) ([97ecd0e](https://github.com/Melsaeed276/anas_localization/commit/97ecd0e42510815f6bc26a53a923b31d9d413ef0))
* **v1.2.0:** generator modules, validator profiles, benchmarks, integration regressions ([#77](https://github.com/Melsaeed276/anas_localization/issues/77)) ([904ea25](https://github.com/Melsaeed276/anas_localization/commit/904ea255b328efe49d96fb3eae4acb89d3d6aaa9))


### Bug Fixes

* **ci:** restore export shim and refresh catalog web bundle ([#151](https://github.com/Melsaeed276/anas_localization/issues/151)) ([1e31d6c](https://github.com/Melsaeed276/anas_localization/commit/1e31d6cf0013b90bd67775721efd530bd64af5e2))
* guard same-language locale fallback to variants not in supported set ([#86](https://github.com/Melsaeed276/anas_localization/issues/86)) ([bc2c2f5](https://github.com/Melsaeed276/anas_localization/commit/bc2c2f5789ab7882058bfd952c9fa9b55b43034d))
* Implement Phase 6 validation fixes (Issues [#123](https://github.com/Melsaeed276/anas_localization/issues/123)-131) ([#132](https://github.com/Melsaeed276/anas_localization/issues/132)) ([29caeb8](https://github.com/Melsaeed276/anas_localization/commit/29caeb8eed536e2f7010961a180c3e6df1420f22))

## [1.3.0](https://github.com/Melsaeed276/anas_localization/compare/v1.2.0...v1.3.0) (2026-07-14)


### Features

* **github:** auto-apply form labels, stale bot, PR labeler, CODEOWNERS ([#171](https://github.com/Melsaeed276/anas_localization/issues/171)) ([e958c4a](https://github.com/Melsaeed276/anas_localization/commit/e958c4a918802c187550c8d004a41430f7e0fce7))
* **github:** auto-detect duplicate issues, merge, close, and bump priority ([#170](https://github.com/Melsaeed276/anas_localization/issues/170)) ([c2a30ba](https://github.com/Melsaeed276/anas_localization/commit/c2a30baddbf4423dcf77313b5dea9ee3148946b2))


### Bug Fixes

* **ci:** publish to pub.dev from tag push, not branch push ([#157](https://github.com/Melsaeed276/anas_localization/issues/157)) ([f45b534](https://github.com/Melsaeed276/anas_localization/commit/f45b5340b18c8fe6ba27a2e7151fb90ff18ce1e0))

## [1.2.0](https://github.com/Melsaeed276/anas_localization/compare/v1.1.0...v1.2.0) (2026-07-13)


### Features

* add init and source_locale commands to CLI, enhance locale file… ([#112](https://github.com/Melsaeed276/anas_localization/issues/112)) ([7baba39](https://github.com/Melsaeed276/anas_localization/commit/7baba3970eff7f84380e0441b953b9f187e55dcd))
* finish v1.0.1 validation, cli, generator and runtime coverage ([#65](https://github.com/Melsaeed276/anas_localization/issues/65)) ([97ecd0e](https://github.com/Melsaeed276/anas_localization/commit/97ecd0e42510815f6bc26a53a923b31d9d413ef0))
* Remote Localization V1 ([#155](https://github.com/Melsaeed276/anas_localization/issues/155)) ([773ebd2](https://github.com/Melsaeed276/anas_localization/commit/773ebd2245540d29007b9ea414603f43da8aa0b6))
* **v1.2.0:** generator modules, validator profiles, benchmarks, integration regressions ([#77](https://github.com/Melsaeed276/anas_localization/issues/77)) ([904ea25](https://github.com/Melsaeed276/anas_localization/commit/904ea255b328efe49d96fb3eae4acb89d3d6aaa9))


### Bug Fixes

* **ci:** restore export shim and refresh catalog web bundle ([#151](https://github.com/Melsaeed276/anas_localization/issues/151)) ([1e31d6c](https://github.com/Melsaeed276/anas_localization/commit/1e31d6cf0013b90bd67775721efd530bd64af5e2))
* guard same-language locale fallback to variants not in supported set ([#86](https://github.com/Melsaeed276/anas_localization/issues/86)) ([bc2c2f5](https://github.com/Melsaeed276/anas_localization/commit/bc2c2f5789ab7882058bfd952c9fa9b55b43034d))
* Implement Phase 6 validation fixes (Issues [#123](https://github.com/Melsaeed276/anas_localization/issues/123)-131) ([#132](https://github.com/Melsaeed276/anas_localization/issues/132)) ([29caeb8](https://github.com/Melsaeed276/anas_localization/commit/29caeb8eed536e2f7010961a180c3e6df1420f22))

## 1.0.0 (2026-07-08)


### Features

* add init and source_locale commands to CLI, enhance locale file… ([#112](https://github.com/Melsaeed276/anas_localization/issues/112)) ([7baba39](https://github.com/Melsaeed276/anas_localization/commit/7baba3970eff7f84380e0441b953b9f187e55dcd))
* finish v1.0.1 validation, cli, generator and runtime coverage ([#65](https://github.com/Melsaeed276/anas_localization/issues/65)) ([97ecd0e](https://github.com/Melsaeed276/anas_localization/commit/97ecd0e42510815f6bc26a53a923b31d9d413ef0))
* **v1.2.0:** generator modules, validator profiles, benchmarks, integration regressions ([#77](https://github.com/Melsaeed276/anas_localization/issues/77)) ([904ea25](https://github.com/Melsaeed276/anas_localization/commit/904ea255b328efe49d96fb3eae4acb89d3d6aaa9))


### Bug Fixes

* **ci:** restore export shim and refresh catalog web bundle ([#151](https://github.com/Melsaeed276/anas_localization/issues/151)) ([1e31d6c](https://github.com/Melsaeed276/anas_localization/commit/1e31d6cf0013b90bd67775721efd530bd64af5e2))
* guard same-language locale fallback to variants not in supported set ([#86](https://github.com/Melsaeed276/anas_localization/issues/86)) ([bc2c2f5](https://github.com/Melsaeed276/anas_localization/commit/bc2c2f5789ab7882058bfd952c9fa9b55b43034d))
* Implement Phase 6 validation fixes (Issues [#123](https://github.com/Melsaeed276/anas_localization/issues/123)-131) ([#132](https://github.com/Melsaeed276/anas_localization/issues/132)) ([29caeb8](https://github.com/Melsaeed276/anas_localization/commit/29caeb8eed536e2f7010961a180c3e6df1420f22))

## 0.1.6 - 2026-07-03

* CI: pinned Flutter to 3.44.2 and normalized catalog web bundle output (permissions + deterministic serviceWorkerVersion) so `check-generation` is stable across runners.
* Tests: updated `tool/catalog_app` wrapper widget test to match the current UI (opens settings before asserting display language).

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
