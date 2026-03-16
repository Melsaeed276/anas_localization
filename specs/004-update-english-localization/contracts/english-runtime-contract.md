# Contract: English Runtime, Validation, and Generation Behavior

## Purpose

Define the shared behavior contract that runtime resolution, CLI validation, and generated dictionary APIs must follow for English localization.

## Runtime Contract

### Locale behavior

- Locale codes use the package's normalized format.
- Regional English locales resolve through the existing deterministic fallback chain.
- Shared `en` content is the fallback source for `en_US`, `en_GB`, `en_CA`, and `en_AU`.

### Plural behavior

- English plural resolution accepts `num` counts.
- English selects `one` only when `count.abs() == 1`.
- English selects `other` for `0`, decimals, and all other numeric values.
- Negative counts use absolute value only for plural-form selection; the displayed number remains the authored substituted value.

### Authored wording

- Articles, contractions, capitalization, irregular plurals, and uncountable noun phrasing are authored in the translation data.
- Runtime resolution must not generate those forms automatically.

## Generated Dictionary Contract

- Generated plural helpers must use the same plural-selection rules as runtime resolution.
- Generated APIs must accept the same numeric count contract as runtime lookup.
- Generated accessors remain based on the canonical `en` reference locale.
- Raw-key access and generated access must continue returning equivalent results for the same locale, key, and parameters.

## Validation Contract

- `en` remains the canonical validation base when present.
- Regional English files may be partial overlays and must not be treated as incomplete solely because they omit unchanged base keys.
- English plural entries validate against `one` and `other`.
- Arabic-only plural or gender expectations must not be applied to English entries unless the entry explicitly uses a supported cross-locale structure.

## Failure Handling

- Missing regional English overrides fall back to `en`.
- Missing English base keys still surface as validation failures.
- Placeholder mismatches remain validation failures across base and override files.
- Generator and validator behavior must remain deterministic across repeated runs.
