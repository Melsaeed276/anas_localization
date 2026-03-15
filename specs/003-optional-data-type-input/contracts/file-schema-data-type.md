# Contract: File schema for data type (same file as values)

**Feature**: 003-optional-data-type-input  
**Spec**: [spec.md](../spec.md) | **Research**: [research.md](../research.md)

## Requirement

Data type MUST be stored in the **same file** as the localization values, alongside each key (per-key). Default when absent is `string`.

## JSON / YAML

- **Reserved key**: Use a single top-level key for type metadata so value shape stays unchanged.
  - **Option A (recommended)**: `@dataTypes` — map from key path (string) to type string.
  - **Option B**: `_meta.dataTypes` — same map under a `_meta` object.
- **Type values**: `string` | `numerical` | `gender` | `date` | `dateTime`. Case-sensitive or normalize to lowercase on read; document chosen convention.
- **Example (Option A)**:

```json
{
  "@dataTypes": {
    "countLabel": "numerical",
    "welcome": "gender",
    "lastUpdated": "date"
  },
  "countLabel": "5",
  "welcome": "مرحبا",
  "lastUpdated": "2025-03-15"
}
```

- **Key paths**: For nested keys (e.g. `dashboard.title`), use the same path string as used for the value (dotted or as in the file). Parser and validator MUST resolve key path consistently.

## ARB

- ARB already uses `@`-prefixed keys for metadata (e.g. `@keyName`). Add data type via:
  - **Option A**: Resource attribute on the entry, e.g. `"dataType": "numerical"` in the object for that key, if ARB format supports per-resource attributes.
  - **Option B**: A single `@dataTypes` resource whose value is a JSON object mapping key → type (same as JSON above).
- Implementation chooses one option and documents it; validators and codegen read the same convention.

## CSV

- **Option A**: Add a column `dataType` (or `data_type`). Rows with key + value + dataType; default empty = string.
- **Option B**: Second sheet or reserved rows for key → type mapping.
- Recommendation: single table with optional column `dataType`; if column missing, all entries are string.

## Behavior

- **Read**: Parser reads value map as today; if metadata key (`@dataTypes` or equivalent) present, read key → type map. Entries without an entry in the map have type `string`.
- **Write**: When saving/exporting, if any entry has type ≠ string, write the metadata key with the map of key → type. Do not change the shape of value entries (keep string or object for plural/etc.).
- **Merge on import**: When applying an imported file, merge type map: add types for new keys; for existing keys, apply file’s type if file provides one (per spec FR-009).
