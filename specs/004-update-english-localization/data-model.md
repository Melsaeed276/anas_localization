# Data Model: English Localization Alignment

## Overview

This feature models English as one shared base locale with a small set of regional variants. The data model keeps authored English text as the source of truth and treats regional differences as targeted overrides rather than fully separate language trees.

## Entities

### EnglishLocale

Represents an English locale used by the runtime, validator, and generator.

**Fields**
- `code`: Canonical locale code such as `en`, `en_US`, `en_GB`, `en_CA`, or `en_AU`
- `languageCode`: Always `en`
- `regionCode`: Optional region segment for regional variants
- `parentCode`: Parent locale used for shared fallback; regional variants point to `en`
- `isBaseLocale`: Whether the locale is the shared English root
- `defaultTimeFormat`: Regional default clock style (`12-hour` or `24-hour`)
- `dateFormatProfile`: Region-specific date presentation profile
- `numberFormatProfile`: English number-format profile
- `currencyFormatProfile`: Currency-symbol and placement expectations for the locale

**Relationships**
- One `EnglishLocale` may have many `RegionalOverride` records
- One base `EnglishLocale` (`en`) is the parent of multiple regional `EnglishLocale` variants

**Validation rules**
- `en` is the only shared base English locale
- Regional variants must use the normalized locale format expected by the runtime
- `en_CA` defaults to mostly UK-style spelling while still remaining its own locale variant

### EnglishTranslationEntry

Represents a translation entry authored for shared English or a regional override.

**Fields**
- `keyPath`: Dotted translation key
- `baseValue`: Shared English value for `en`
- `entryKind`: `plainText`, `countSensitive`, or `structuredOverride`
- `placeholders`: Placeholder definitions extracted from the authored text
- `supportsRegionalOverride`: Whether a region file may override the entry
- `notes`: Optional translator or reviewer guidance

**Relationships**
- One `EnglishTranslationEntry` may have zero or more `RegionalOverride` records
- One `EnglishTranslationEntry` may embed one `CountSensitiveEntry` when plural behavior is needed

**Validation rules**
- Base `en` remains the source of truth for key presence
- Placeholder names and placeholder requirements must stay aligned across base and regional overrides
- Authored text remains authoritative for articles, contractions, capitalization, and tone

### CountSensitiveEntry

Represents an English entry whose wording changes based on count.

**Fields**
- `keyPath`: Translation key this plural data belongs to
- `oneForm`: Singular text
- `otherForm`: Plural text
- `countType`: Numeric count contract; runtime should accept `num`
- `usesIrregularPlural`: Whether the plural wording is explicitly authored instead of derived
- `usesMeasurePhrase`: Whether the entry expresses count via measure-based phrasing (for uncountables)

**Relationships**
- Belongs to one `EnglishTranslationEntry`

**Validation rules**
- English requires only `one` and `other`
- Singular selection occurs only when `count.abs() == 1`
- Zero, decimals, and all other numeric values use `other`
- Irregular plurals and uncountable noun phrasing must be authored explicitly

### RegionalOverride

Represents a region-specific replacement for a shared English value.

**Fields**
- `localeCode`: Target regional locale
- `keyPath`: Translation key being overridden
- `overrideCategory`: `spelling`, `selectedVocabulary`, `dateFormat`, `timeFormat`, `currencyFormat`, or combined entry override
- `overrideValue`: Authored region-specific value or structure
- `fallbackBehavior`: Always falls back to base `en` when absent

**Relationships**
- Belongs to one `EnglishLocale` regional variant
- Belongs to one `EnglishTranslationEntry`

**Validation rules**
- First-release override categories are limited to spelling, selected vocabulary, and formatting-sensitive entries
- Regional tone variants are out of scope
- Missing overrides fall back to the base `en` entry without error

## Derived Behaviors

### Locale Resolution

1. Normalize incoming locale codes into the runtime's canonical format.
2. Attempt exact regional match.
3. Fall back to the shared base `en`.
4. Continue using the existing package-wide fallback locale behavior if English assets are unavailable.

### Plural Resolution

1. Read `count` as `num`.
2. Resolve English plural form with absolute-value semantics.
3. Return `one` only when absolute numeric value is `1`.
4. Return `other` for every other numeric value.

### Validation Behavior

1. Use `en` as the reference locale for key and placeholder validation.
2. Permit regional locales to override only keys that actually differ.
3. Ensure English plural entries are accepted with `one`/`other` rather than Arabic's six-form set.

## State Transitions

This feature has no persistent workflow state machine. The main transition is content layering:

1. Author shared content in `en`
2. Add optional regional overrides
3. Validate
4. Generate typed dictionary output
5. Resolve at runtime using normalized locale and fallback
