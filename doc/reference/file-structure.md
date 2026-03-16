# File Structure

Use this page when you want a recommended project layout or need to verify where generated and source files should live.

## Recommended layout

```text
assets/
  lang/
    en.json
    ar.json
lib/
  generated/
    dictionary.dart
  main.dart
anas_catalog.yaml
```

## Notes

- keep source locale files in `assets/lang` unless you need a custom `assetPath`
- generated dictionary output typically lives in `lib/generated/dictionary.dart`
- catalog state stays outside runtime code under `.anas_localization/`
- **locale notation**: asset file names use underscored locale codes (e.g. `en_US.json`, `en_GB.json`); user-facing text and hyphenated forms (e.g. `en-US`) are normalized automatically at runtime

## English Regional Overlays

Regional English files (`en_US.json`, `en_GB.json`, `en_CA.json`, `en_AU.json`) are **overlay-only** files. They contain only the keys that differ from the shared `en.json` base. At runtime the service merges `en.json` first, then layers the regional override on top, so any key absent from the overlay resolves to the shared English value.

```text
assets/
  lang/
    en.json        ← shared English base (source of truth)
    en_US.json     ← US overrides only (e.g. "Color", USD formatting)
    en_GB.json     ← GB overrides only (e.g. "Colour", "Catalogue", GBP)
    en_CA.json     ← CA overrides only (e.g. "Colour", CAD, ISO date)
    en_AU.json     ← AU overrides only (e.g. "Colour", "G'day!", AUD)
```

### English scope vs Arabic scope

| Feature | English (`en*`) | Arabic (`ar*`) |
|---|---|---|
| Required plural forms | `one`, `other` | `zero`, `one`, `two`, `few`, `many`, `other` |
| Gender forms required | No | Yes (when base defines them) |
| Regional overlay files | `en_US`, `en_GB`, `en_CA`, `en_AU` | per-country variants optional |
| Clock format defaults | 12 h (`en_US`, `en_CA`) / 24 h (`en_GB`, `en_AU`) | locale-driven by `intl` |
| Currency defaults | USD / GBP / CAD / AUD | country-specific via `intl` |

### Validation behavior

The validator (`TranslationValidator`) applies English-scope rules automatically:

- Regional overlays (`en_US`, `en_GB`, `en_CA`, `en_AU`) are **not required** to duplicate every key from `en.json`.
- English locale files with `_type: plural` only need `one` and `other` — missing Arabic forms (zero, two, few, many) are not flagged.
- Arabic and other locale files are free to add plural/gender forms that the English base doesn't define; these are treated as allowed extras.

Use `TranslationValidator.isEnglishLocale(locale)` and `TranslationValidator.requiredPluralFormsForLocale(locale)` in custom tooling to apply the same locale-aware rules.

## Next

- [Generate and Wrap Your App](../get-started/generate-and-wrap.md)
- [Config Reference](config-reference.md)
