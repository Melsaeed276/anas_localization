## 1.0.0

* Added runtime `LocalizationService.configure(...)` to set asset path and supported locales in one place.
* Added Flutter preview support via `previewDictionaries` on `AnasLocalization` and service-level preview dictionary APIs.
* Fixed async locale change behavior by awaiting locale save in `setLocale`.
* Improved saved locale parsing normalization and country/language casing.
* Added tests for Flutter preview dictionaries and widget configuration wiring.
* Updated README with Flutter preview usage and fixed conflicting `assetPath` example.

## 0.0.1

* TODO: Describe initial release.
