# Data Model: Arabic Language Localization Support

**Feature**: 002-arabic-localization-support  
**Phase**: 1  
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Research**: [research.md](research.md)

## Entities

### Locale

- **Description**: Language, script, and optional region used to select formatting and translation variants.
- **Attributes**:
  - **languageCode**: String (e.g. `ar`).
  - **scriptCode**: Optional String (e.g. Arabic script; when omitted, inferred from language).
  - **countryCode**: Optional String (e.g. `SA`, `EG`, `MA`) for region-specific numerals and formats.
- **Relationships**: Drives RTL/LTR (via language/script), numeral system (Eastern/Western by region), and date/time/currency formatting. Used as part of **UserContext**.

### PluralForm

- **Description**: One of six categories for Arabic pluralization.
- **Attributes**: Enum or string: `zero` | `one` | `two` | `few` | `many` | `other`.
- **Validation**: For Arabic, rules are: zero (n=0), one (n=1), two (n=2), few (n % 100 in 3..10), many (n % 100 in 11..99), other (else). See research.md.
- **Relationships**: Selected from count by `PluralRules`; used to look up the correct **TranslationEntry** form.

### Gender

- **Description**: User or audience gender for message resolution; only male or female.
- **Attributes**: Enum or string: `male` | `female`.
- **Validation**: No other values. When not set, default is **male** (per spec).
- **Relationships**: Part of **UserContext**; used to select gender-specific forms and honorifics.

### RegionalVariant

- **Description**: Dialect or standard (e.g. MSA, Gulf, Egyptian) for dialect-specific translations.
- **Attributes**: String or enum, e.g. `msa` | `gulf` | `egyptian` (extensible).
- **Validation**: Default when not set is **MSA** (Modern Standard Arabic).
- **Relationships**: Part of **UserContext**; resolution falls back variant → MSA → base/key.

### FormalityLevel

- **Description**: Formal vs informal mode for pronouns and phrasing.
- **Attributes**: Enum or string: `formal` | `informal`.
- **Relationships**: Part of **UserContext**; used to select formal/informal variants where present.

### UserContext (resolution context)

- **Description**: The set of options used for message resolution: locale, gender, formality, regional variant.
- **Attributes**:
  - **locale**: Locale (required).
  - **gender**: Gender (optional; default male).
  - **formality**: FormalityLevel (optional; product default, e.g. formal).
  - **regionalVariant**: RegionalVariant (optional; default MSA).
- **Relationships**: App-level default; overridable per call (per screen or per resolution). Consumed by resolution API.

### TranslationEntry

- **Description**: A message key with one or more forms (by plural, gender, variant, formality) and optional placeholders.
- **Attributes**:
  - **key**: String (key path).
  - **forms**: Map or structure of form → value (e.g. plural form → string, gender → string, variant → string, formality → string). Structure may be nested or suffix-based (see contracts).
  - **placeholders**: Optional set of placeholder names (e.g. `count`, `name`).
  - **type**: Optional string (e.g. `plural`, `numeric`, `date`) used to guide fallback and to trigger warnings when a required form is missing (CLI/Catalog).
- **Validation**: If **type** is set and a form required for that type is missing, validation/CLI/Catalog MAY emit a warning; resolution still returns a value via fallback.
- **Relationships**: Loaded from assets (ARB/JSON/YAML); resolved by resolution engine using **UserContext** and **canonical fallback order**.

### Canonical fallback order

- **Description**: Fixed order when a requested form or key is missing.
- **Order**: Within same key: try alternate form (plural → other, gender → other, variant → MSA). Then: base language or key display. No configurable chain in first release.
- **Relationships**: Implemented in one resolution path shared by type-safe and raw-key access.

### HonorificEntry

- **Description**: A title with masculine and feminine Arabic forms.
- **Attributes**:
  - **titleKey**: String (e.g. "Dr.", "Mr.", "Mrs.").
  - **male**: String (e.g. الدكتور).
  - **female**: String (e.g. الدكتورة).
- **Relationships**: Small built-in or configurable map; resolution: (title, gender) → string; unknown title → name-only or generic fallback.

### StringType (optional)

- **Description**: Optional classification of a key for validation and warnings.
- **Attributes**: String or enum, e.g. `plural` | `numeric` | `date`.
- **Relationships**: When set on a **TranslationEntry**, used to (1) guide fallback and (2) produce targeted warnings in CLI/Catalog when a required form is missing.

## State transitions

- **Locale/context switch**: When the app changes locale, gender, formality, or variant, all visible messages that depend on context are re-resolved and UI updates (no explicit state machine; resolution is stateless per call; app state holds current UserContext).
- **Async load**: When an asset for a locale finishes loading, the system notifies listeners so that widgets re-resolve and refresh; initial resolution before load uses fallback only.

## Validation rules

- Gender MUST be male or female; if not set, treat as male.
- Fallback order MUST be deterministic and documented (same inputs → same result on all platforms).
- Resolution MUST NOT block when asset is not loaded; MUST return fallback and MAY refresh when asset loads.
- If a key has an optional string type and a required form for that type is missing, resolution still returns a valid string; CLI/Catalog MAY show a warning.
