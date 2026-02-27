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
