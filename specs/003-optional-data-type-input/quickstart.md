# Quickstart: Optional Data Type Input (003)

**Feature**: 003-optional-data-type-input  
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

## What this feature adds

- **Optional data type** per localization entry: `string` (default), `numerical`, `gender`, `date`, `date & time`.
- **Catalog UI**: Data type dropdown + type-specific value input (text field, number field, male/female dropdown, date picker, date+time picker).
- **Same-file storage**: Type is stored in the same file as values (e.g. `@dataTypes` map in JSON/YAML).
- **Validation**: On load and in CLI, entries are checked against type rules; violations reported with key and rule.
- **Code generation**: Generated code/artifacts use the same type rules so they stay consistent with validation and Catalog.
- **Import**: Merge semantics—new keys added; existing keys updated only when the file provides type or value for that key.

## How to use (after implementation)

### In the Catalog

1. Open the Catalog and create or edit an entry.
2. Set **Data type** from the dropdown (default: string).
3. Edit the value using the control shown for that type (e.g. number field for numerical, male/female dropdown for gender, date picker for date).
4. Save; type and value are written to the localization file in the same file (see [contracts/file-schema-data-type.md](contracts/file-schema-data-type.md)).

### In localization files (JSON example)

- Add a top-level key `@dataTypes` (or equivalent per format) mapping key path → type:

```json
{
  "@dataTypes": {
    "countLabel": "numerical",
    "welcome": "gender"
  },
  "countLabel": "5",
  "welcome": "مرحبا"
}
```

- Omitted keys default to type `string`.

### Validation (CLI)

- Run the existing validate command; it will apply data type rules and report violations (e.g. non-numeric value for `numerical`, or value other than male/female for `gender`).

### Import

- When importing a file, merge applies: new keys and their types/values are added; for keys that already exist, existing type and value are kept unless the file provides type or value for that key, in which case the file’s data is applied.

## Out of scope (first release)

- Additional data types (e.g. currency, duration).
- Custom validation rules per type.
- Timezone handling for date & time.
- User-selectable import strategy (overwrite/merge/skip).
