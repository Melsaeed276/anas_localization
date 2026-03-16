# Contract: English Locale Assets

## Purpose

Define how English translation assets are named, layered, and validated for the first release of English localization alignment.

## File Naming Contract

- Shared base locale file: `assets/lang/en.json`
- Regional override files:
- `assets/lang/en_US.json`
- `assets/lang/en_GB.json`
- `assets/lang/en_CA.json`
- `assets/lang/en_AU.json`

The same naming convention applies to example assets when example coverage is kept in sync.

## Layering Contract

1. `en.json` is the shared English source of truth.
2. A regional file contains only entries that differ from `en.json`.
3. At runtime, an exact regional locale uses its override file first and falls back to `en`.
4. Missing override keys are not errors when the base `en` key exists.

## Allowed Override Categories

First-release English regional overrides are limited to:

- Spelling differences
- Selected vocabulary differences
- Formatting-sensitive entries that must differ by locale

The following are out of scope for regional override assets in this release:

- Separate regional tone variants for otherwise equivalent content
- Arabic-style gender requirements for general English content
- English-specific alternate numeral or calendar systems

## Value Shape Contract

### Plain text entry

```json
{
  "colorLabel": "Color"
}
```

### Regional spelling override

```json
{
  "colorLabel": "Colour"
}
```

### English plural entry

```json
{
  "itemsCount": {
    "one": "{count} item",
    "other": "{count} items"
  }
}
```

Plural entries for English must use authored `one` and `other` values only.

## Validation Expectations

- `en` remains the canonical base locale for key and placeholder validation.
- Regional English files may omit any key that is unchanged from `en`.
- If a regional file overrides a key, placeholder names and requirements must remain compatible with the base entry.
- English plural entries must validate successfully with `one`/`other` structures.

## Example Fallback

If `en_CA.json` does not override `shoppingCartLabel`, runtime resolution should return the value from `en.json`.
