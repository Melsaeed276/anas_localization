# Data Model: Optional Data Type Input for Localization

**Feature**: 003-optional-data-type-input  
**Phase**: 1  
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Research**: [research.md](research.md)

## Entities

### DataType

- **Description**: Optional classification of a localization entry used for validation, Catalog UI, and code generation.
- **Attributes**: Enum or string: `string` | `numerical` | `gender` | `date` | `dateTime`.
- **Validation**:
  - **string**: Default when absent; any value allowed.
  - **numerical**: Value must parse as number (int or decimal); reject otherwise.
  - **gender**: Value must be exactly `male` or `female` (case-insensitive).
  - **date**: Value must be valid ISO 8601 date (YYYY-MM-DD) in storage; display may be locale-specific.
  - **dateTime**: Value must be valid ISO 8601 date-time in storage; display may be locale-specific.
- **Relationships**: Stored per key in the same file as values (see File schema in contracts). Drives Catalog input control and validation rules.

### LocalizationEntry (extended)

- **Description**: A key, one or more values (by locale/form), and optional **dataType**.
- **Attributes**:
  - **key**: String (key path).
  - **value** (or **values** by locale): String or map (e.g. plural/gender forms); shape unchanged by 003.
  - **dataType**: Optional DataType; default `string` when absent.
- **Validation**: When **dataType** is set, value(s) must satisfy the rule for that type (see DataType). Validation runs on load and before save/codegen; failures surface with entry key and rule.
- **Relationships**: Loaded/saved via translation file parser; Catalog displays and edits entry with type dropdown and type-specific value input. Merge on import: new keys get type from file; existing keys keep existing type/value unless file supplies type or value for that key.

### CatalogEntryState (extended)

- **Description**: Catalog’s in-memory/UI state for an entry; extends existing catalog entry with **dataType**.
- **Attributes**: Same as existing catalog entry (key, values per locale, status, etc.) plus:
  - **dataType**: DataType (default `string`); selected via dropdown in Catalog UI.
- **Relationships**: Persisted into localization file using same-file type storage (e.g. `@dataTypes` map). Value input widget depends on **dataType** (text field, number field, gender dropdown, date picker, date+time picker).

### ImportMergeResult

- **Description**: Result of merging an imported file into existing Catalog/project.
- **Attributes**:
  - **addedKeys**: Set of keys added from file.
  - **updatedKeys**: Set of keys for which file supplied type or value and local was updated.
  - **errors**: Optional list of validation errors (e.g. type violation in file).
- **Relationships**: Produced by import pipeline; merge policy is fixed (add new; for existing, apply file type/value when provided). No user-selectable overwrite/merge/skip in first release.

## State transitions

- **Entry without dataType** → User sets dataType in Catalog or file: entry gains dataType; value is validated against new type; if invalid, error surfaced and user can fix or revert type.
- **Import file** → Merge: new keys added with type/value from file; existing keys updated only where file provides type or value. Validation runs on merged result; errors reported per key/rule.

## Validation rules (summary)

| DataType  | Allowed value(s)                          | Storage format        |
|-----------|--------------------------------------------|------------------------|
| string    | Any                                        | As-is                  |
| numerical | Parsable number (int or decimal)           | As string representation |
| gender    | `male` \| `female`                         | Exact string           |
| date      | ISO 8601 date (YYYY-MM-DD)                 | Canonical; display locale-specific |
| dateTime  | ISO 8601 date-time                         | Canonical; display locale-specific |
