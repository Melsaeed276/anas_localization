# Contract: Catalog UI — data type dropdown and type-specific value inputs

**Feature**: 003-optional-data-type-input  
**Spec**: [spec.md](../spec.md) | **Research**: [research.md](../research.md)

## Requirement

In the Catalog UI, the user can set **data type** per entry via a dropdown (default: string). The **value input** control MUST change based on the selected type (FR-005, FR-008).

## Data type dropdown

- **Control**: Single dropdown (or equivalent single-select) listing the five types.
- **Options**: `string` | `numerical` | `gender` | `date` | `date & time` (display labels may be localized; stored value is the canonical string).
- **Default**: When creating a new entry or when type is absent, selected value is **string**.
- **Persistence**: On change, update in-memory state and persist to file (same-file type storage) on save/autosave per Catalog behavior.

## Value input by type

| Data type   | Input control              | Allowed input / behavior |
|-------------|----------------------------|---------------------------|
| **string**  | Text field                 | Any text.                 |
| **numerical** | Text field with number keyboard | Only digits and at most one decimal separator; integers and decimals allowed. Validate on blur/submit: must parse as number. |
| **gender**  | Dropdown                   | Exactly two options: **male**, **female**. No free text. |
| **date**    | Date picker                | User selects date; value stored as ISO 8601 date (YYYY-MM-DD). Display may use locale format. |
| **date & time** | Date picker + time picker | User selects date and time; value stored as ISO 8601 date-time. Display may use locale format. |

## Validation in Catalog

- When type is **numerical**: Reject non-numeric input; show inline or toast error.
- When type is **gender**: No custom input; selection is always male or female.
- When type is **date** or **date & time**: Picker output is canonical; invalid or out-of-range handled by picker or show error.
- When user changes type and current value is invalid for the new type: show error and either block save until value is fixed or revert type; document chosen behavior.

## Accessibility and i18n

- Dropdown and type-specific controls MUST be focusable and usable with keyboard and screen readers.
- Labels for type options and errors SHOULD be localizable (Catalog l10n).
