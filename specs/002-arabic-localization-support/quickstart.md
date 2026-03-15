# Quickstart: Arabic Language Localization Support

**Feature**: 002-arabic-localization-support  
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Data model**: [data-model.md](data-model.md)

## Goal

Enable Arabic support in an app using anas_localization: RTL layout, six-form plurals, gender and formality, regional variant, locale-correct numbers/dates/currency, and correct fallback behavior.

## Prerequisites

- Feature spec and plan: `specs/002-arabic-localization-support/spec.md`, `plan.md`
- Contracts: `contracts/resolution-api.md`, `contracts/asset-schema-arabic.md`
- Research: `research.md` (plural rules, numerals, context, async load)

## Steps

### 1. Set app locale and RTL

- Set the app locale to an Arabic locale (e.g. `ar`, `ar_SA`, `ar_EG`) via your existing localization setup (e.g. `AnasLocalization`, `LocalizationService`, or platform locale).
- Wrap the app (or Arabic screens) with a widget that sets `Directionality` from the current locale — e.g. `AnasDirectionalityWrapper` or `Directionality(textDirection: AnasTextDirection.getTextDirection(locale), child: ...)` so that when Arabic is active, layout is RTL.
- Ensure `Localizations.localeOf(context)` (or the app-level locale you use for resolution) is the same locale used for direction, so that RTL and message resolution stay in sync.

### 2. Configure user context (app-level default)

- Set the default **UserContext** (locale, gender, formality, regional variant) at app level. When not set: gender = male, variant = MSA.
- Use the package API (once implemented) to set or provide this context (e.g. via `AnasLocalization` or a dedicated context holder). Overrides can be passed per screen or per resolution call where the spec allows.

### 3. Prepare assets for Arabic

- Add Arabic translations in your chosen format (ARB/JSON/YAML). For plurals, provide all six forms (zero, one, two, few, many, other) where the message depends on count; use the structure defined in `contracts/asset-schema-arabic.md`.
- Where you need gender or formality variants, add the corresponding forms (e.g. male/female, formal/informal). For regional variants (e.g. Gulf, Egyptian), add variant-specific strings and use MSA as fallback where a variant is missing. Resolution supports suffix keys: `key_gulf`, `key_formal`, `key_gulf_formal`; fallback order is variant→MSA, formality→single form (see `contracts/asset-schema-arabic.md`).
- Optionally tag keys with a string type (e.g. plural, numeric, date) so the CLI and Catalog can warn when a required form is missing; resolution still uses the fallback chain.

### 4. Use full locale for formatting

- Use full locale (e.g. `ar_SA`, `ar_MA`) for number, date, time, and currency formatting so that Eastern vs Western numerals and separators follow region. Pass this locale to `NumberFormat`/`DateFormat` (or the package’s formatters that wrap them).

- Currency: `AnasNumberFormatter(locale).formatCurrency(amount, ...)` uses the full locale for symbol/code position and numeral system; use the same locale as for numbers and dates.

### 5. Validate and optional warnings

- Run the package CLI validation (e.g. `anas validate` or equivalent) so that missing required forms for typed keys surface as warnings. Fix or accept fallback behavior as needed.
- In the Catalog, configure Arabic-specific options (plural forms, gender, variant, formality) and resolve any reported missing-form warnings.

### 6. Async loading

- If you load translations asynchronously, rely on the package’s behavior: resolution returns immediately using the fallback chain when an asset is not yet loaded, and the UI refreshes when the asset finishes loading. Ensure your app rebuilds when the localization state notifies (e.g. listeners or `notifyListeners`) so users see the loaded translation instead of staying on fallback.

### 7. Honorifics (optional)

- For “title + name” (e.g. Dr., Mr., Mrs.), use the package’s honorific resolution (title + gender) when implemented, or pass the resolved Arabic title from a small table; for unknown titles, show name only or a generic label.

### 8. Search and sort (optional)

- Use `normalizeForSearch(text)` to strip diacritics for matching; for locale-aware Arabic sort use a collation API (e.g. intl4x Collation) with the app locale. See `arabic_text_utils.dart` and `sortWithLocale`.

### 9. Accessibility and input (US10)

- Semantics and reading order: Flutter's default semantics and `Directionality` (from `AnasDirectionalityWrapper`) give correct reading order for Arabic; screen readers announce content in logical order.
- Arabic name validation: use `isReasonablyValidArabicName(name)` for allowed character set and length; configure min/max length as needed.
- Phone validation: use `isReasonablyValidArabicRegionPhone(phone, regionCode)` for supported regional formats; for strict E.164 use a dedicated library.

## Verification

- Switch app language to Arabic and confirm layout is RTL and mixed content (numbers, URLs) does not break.
- For a pluralized key, test counts 0, 1, 2, 5, 15, 100 and confirm the correct form is shown.
- Set gender to male then female and confirm gendered strings change where variants exist.
- Set region to one using Eastern numerals and one using Western; confirm number/date format.
- Remove one plural form or leave gender unset and confirm fallback behavior and (if applicable) CLI/Catalog warning.

## References

- Spec: `specs/002-arabic-localization-support/spec.md`
- Plan: `specs/002-arabic-localization-support/plan.md`
- Resolution API: `specs/002-arabic-localization-support/contracts/resolution-api.md`
- Asset schema: `specs/002-arabic-localization-support/contracts/asset-schema-arabic.md`
- Research: `specs/002-arabic-localization-support/research.md`
