# Research: Optional Data Type Input (003)

**Branch**: `003-optional-data-type-input` | **Spec**: [spec.md](spec.md)

## 1. Storing data type in the same file as values

**Decision**: Store data type alongside each key in the same file using one of two patterns depending on format:

- **JSON / YAML**: Use a reserved top-level key (e.g. `@dataTypes` or `_meta.dataTypes`) that maps key path → type string. Example: `{ "@dataTypes": { "countLabel": "numerical", "welcome": "gender" }, "countLabel": "5", "welcome": "مرحبا" }`. Values stay as they are (string or object for plural); type is separate but in same file.
- **Alternative considered**: Per-key object for every entry (e.g. `"countLabel": { "value": "5", "dataType": "numerical" }`). Rejected for first release because it changes the shape of every entry and breaks existing flat key→value expectations; would require migration of all existing files. The metadata map keeps value shape unchanged and is additive.

**Rationale**: Spec requires "same file as values" and "alongside each key". A single metadata map is the smallest change: existing parsers still see key→value; only the parser/validator/codegen need to read the metadata map. ARB already uses `@`-prefixed keys for metadata; JSON can use `@dataTypes` or `_meta.dataTypes` by convention.

**Alternatives considered**:
- Separate metadata file: Rejected; spec says same file.
- Inline in value object only when type ≠ string: Would mix shapes (sometimes string, sometimes object); harder for generators and validators to handle uniformly.

---

## 2. Validation rules per type

**Decision**: Implement explicit rule sets:

- **string**: Any non-null value; no format check.
- **numerical**: Parsable as number (int or decimal); reject if not (e.g. `num.tryParse` in Dart). Allow integers and decimals per spec.
- **gender**: Exactly `male` or `female` (case-insensitive); reject any other string.
- **date**: Valid ISO 8601 date (YYYY-MM-DD) or parseable by same canonical form; reject invalid or wrong format.
- **date & time**: Valid ISO 8601 date-time; same canonical form; reject invalid.

**Rationale**: Spec mandates these five types and merge/validation; deterministic rules make CLI and Catalog behavior consistent and testable.

**Alternatives considered**:
- Regex-only validation: Too brittle for date/time; numeric and gender are simple enough without regex.
- Configurable/custom rules: Out of scope for first release per spec.

---

## 3. Catalog UI: type dropdown and type-specific inputs

**Decision**: Use a single dropdown for data type (default string). For the value field, switch widget by type:

- **string**: `TextField` (or existing text input).
- **numerical**: `TextField` with `keyboardType: TextInputType.numberWithOptions(decimal: true)`, input formatters to allow only digits and one decimal separator.
- **gender**: `DropdownButtonFormField<String>` with options `male`, `female` only.
- **date**: Date picker (show date picker on tap; store value as ISO 8601 date string).
- **date & time**: Date + time picker; store as ISO 8601 date-time.

**Rationale**: Matches spec (FR-005, FR-008); Flutter has built-in `TextInputType`, `showDatePicker`, `showTimePicker`; dropdown for gender keeps allowed values fixed. Display format for date/time can use `intl`/locale when showing to user; storage remains canonical.

**Alternatives considered**:
- Single text field with validation only: Rejected; spec requires type-specific controls (dropdown for gender, pickers for date/dateTime).
- Third-party date picker package: Use platform `showDatePicker`/`showTimePicker` first; add dependency only if needed.

---

## 4. Import merge semantics

**Decision**: Implement merge as specified: (1) Add all keys from file that are not present locally. (2) For keys that already exist: keep existing type and value; if the file provides a value for that key, apply file value; if the file provides a type for that key, apply file type. Apply file type and value together when both are present for the same key.

**Rationale**: Spec FR-009 and clarification: "add new keys; for existing keys keep existing type/value unless the file provides them, then apply file data." No user choice at import time in first release.

---

## 5. Code generation and data type

**Decision**: Codegen reads the same file (and thus `@dataTypes` or equivalent); when generating typed accessors or validation, include type so that (a) generated code can use type for runtime validation or (b) generated types reflect expected shape (e.g. number getter for numerical). Exact shape of generated API left to implementation (e.g. getString, getNumber, getGender, getDate) or single getter with type metadata; must respect type rules so output is consistent with validation and Catalog.

**Rationale**: Spec FR-007 requires generated code/artifacts to apply same type rules; dual access (Principle I) means both generated API and raw-key access see the same type and validation.

---

## 6. Date/time canonical form

**Decision**: Use ISO 8601 for storage and exchange: date as `YYYY-MM-DD`, date-time as ISO 8601 (e.g. `yyyy-MM-ddTHH:mm:ss.sssZ` or with offset). Catalog and display parse/format using locale via `intl` when showing to user; on save, convert back to canonical string.

**Rationale**: Spec FR-010 and clarification: storage format-agnostic (canonical), display locale-specific. ISO 8601 is unambiguous and supported by Dart `DateTime` and `intl`.
