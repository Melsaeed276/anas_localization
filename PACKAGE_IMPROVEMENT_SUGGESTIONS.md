# Package Improvement Suggestions

This document proposes practical improvements for `anas_localization`, prioritized by impact.

## 1) High-priority fixes (correctness & API reliability)

1. **Await locale-change writes in public API**
   - In `_AnasLocalizationWidget.setLocale`, `_LocalizationManager.instance.saveLocale(locale)` is called without `await`.
   - Because `setLocale` returns `Future<void>`, callers naturally expect completion when the locale is fully saved and applied.
   - **Suggestion:** `await _LocalizationManager.instance.saveLocale(locale);`
   - **Benefit:** correct async semantics, proper exception propagation, and fewer race conditions in UI tests.

2. **Unify supported locales with widget configuration**
   - Runtime checks rely on static `LocalizationService.supportedLocales`, while the widget accepts `assetLocales`.
   - This can drift: app config says one set, service checks another.
   - **Suggestion:** initialize service-supported locales from `AnasLocalization.assetLocales` during startup and expose one source of truth.
   - **Benefit:** eliminates mismatch bugs and improves developer trust in configuration.

3. **Reduce global mutable state for asset path**
   - `LocalizationService.setAppAssetPath` mutates static global state.
   - Multiple instances/roots can overwrite each other.
   - **Suggestion:** prefer instance-level configuration (or at least guard and document singleton-global behavior clearly).
   - **Benefit:** fewer hidden side effects and safer composition.

## 2) Testing and CI improvements

4. **Add deterministic unit tests using bundle mocks/fakes**
   - Current tests depend on real assets and global mutable lists.
   - **Suggestion:** use test doubles for asset loading (`rootBundle`/asset abstraction), including parse errors, missing files, malformed JSON, and fallback behavior.
   - **Benefit:** faster and more reliable tests with better edge-case coverage.

5. **Add CI matrix for Flutter stable + Dart analyze/test**
   - Tooling availability blocked local execution previously.
   - **Suggestion:** add GitHub Actions for `flutter analyze`, `flutter test`, and package publish checks.
   - **Benefit:** prevents regressions and validates PRs automatically.

6. **Add regression tests for locale string normalization**
   - Locale restoration now handles `en-US` / `en_US`.
   - **Suggestion:** explicitly test additional values (`en`, `ar_EG`, uppercase variants, empty strings, invalid formats).
   - **Benefit:** preserves startup locale behavior over future refactors.

## 3) Developer experience and documentation

7. **Fix README example duplication/conflict**
   - One setup snippet includes `assetPath` twice with conflicting values.
   - **Suggestion:** keep one value and explain override behavior once.
   - **Benefit:** avoids copy/paste failures and confusion.

8. **Document configuration precedence clearly**
   - There are multiple layers: package defaults, app overrides, saved locale, fallback locale.
   - **Suggestion:** add one "Resolution order" section with a short flow diagram.
   - **Benefit:** easier onboarding and fewer support questions.

9. **Add a troubleshooting section**
   - Common issues: missing assets in `pubspec.yaml`, unsupported locale exceptions, dictionary factory not registered.
   - **Benefit:** faster self-service debugging for users.

## 4) Architecture and performance

10. **Introduce dictionary caching per locale**
    - Re-loading from assets may be repeated unnecessarily.
    - **Suggestion:** cache loaded merged maps/dictionaries keyed by locale and invalidate on config change.
    - **Benefit:** reduced startup and switch latency.

11. **Extract locale parsing into dedicated utility**
    - Parsing logic currently lives in manager startup flow.
    - **Suggestion:** create `LocaleParser` utility with tests.
    - **Benefit:** reusable, testable, and easier to evolve (script subtags, region normalization).

12. **Consider injectable asset loader abstraction**
    - Direct `rootBundle` usage limits testability.
    - **Suggestion:** interface-based loader (`AssetLoader`) with default Flutter implementation.
    - **Benefit:** cleaner architecture, better test isolation.

## Suggested implementation order

1. Fix `setLocale` await behavior and add tests.
2. Unify locale source-of-truth (`assetLocales` vs `supportedLocales`).
3. Resolve README conflict and add config precedence docs.
4. Add CI checks and deterministic asset-loading tests.
5. Refactor static config into injectable or instance-based configuration.
