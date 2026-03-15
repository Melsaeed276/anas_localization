# Contract: Asset schema for Arabic (plural, gender, variant, formality, type)

**Feature**: 002-arabic-localization-support  
**Consumers**: Loaders (ARB/JSON/YAML), codegen, Catalog UI, validation/CLI.

## Purpose

Define how translation entries store Arabic-specific forms (plural, gender, variant, formality) and optional string type so that loaders and Catalog can read/write and validators can emit targeted warnings.

## Requirements (from spec)

- Six plural forms for Arabic: zero, one, two, few, many, other.
- Gender: male, female (optional per key where applicable).
- Regional variant: e.g. MSA, Gulf, Egyptian (optional where translations exist).
- Formality: formal, informal (optional where translations exist).
- Optional string type per key: e.g. plural, numeric, date — used for warnings when a required form is missing.

## ARB alignment

- **Plural**: ARB already supports `zero`, `one`, `two`, `few`, `many`, `other` in value structure (e.g. `"key": {"zero": "...", "one": "...", ...}` or `@key.zero`, etc. depending on generator). Package MUST accept the same form names.
- **Gender**: Can be represented as suffix or nested key (e.g. `key_male`, `key_female` or `key.male`, `key.female`). Exact key shape is implementation-defined but MUST be documented so Catalog and CLI can validate.
- **Variant / formality**: Same idea: suffix or nested (e.g. `key_msa`, `key_gulf` or `key.formal`, `key.informal`). Fallback order: requested variant → MSA; requested formality → single form if only one.
- **Type**: Optional metadata on the key (e.g. `@key.type`: `plural` or `"key"` with `"_type": "plural"` in JSON). Used only for validation/warnings.

## JSON/CSV/YAML

- When the package supports JSON (or CSV/YAML), the same logical structure applies: a key can map to a string or to an object with form keys (plural, gender, variant, formality) and optional `_type`.
- Nested keys (dot path) and flat keys with suffixes are both acceptable as long as resolution and validation use the same convention.

## Catalog and CLI

- Catalog MUST allow editing and configuring plural forms, gender variants, variant, and formality where the format supports it.
- Validation (CLI) MUST be able to check: for a key with type `plural`, all six forms present (or emit warning); for type `numeric`/`date`, any required forms per type. Warnings MUST reference key and type (e.g. "key X, type plural, should have 'many' configured").

## Validation rules

- If type is set and a required form is missing → warning in CLI/Catalog; resolution still returns fallback.
- CLI validation: when a key's value has `_type: "plural"`, all six forms (zero, one, two, few, many, other) are required; missing forms produce a warning like `locale: key "keyName", type plural, should have 'many' configured`.
- Fallback order for resolution is unchanged: plural→other, gender→other, variant→MSA, formality→key; optional type does not block resolution.
- Asset format MUST allow at least: one string per key (simple), or object with plural/gender/variant/formality keys (Arabic-rich). Type is optional metadata.
