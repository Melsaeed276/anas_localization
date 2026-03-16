# Quickstart: Catalog UI Design and Stability

## Goal

Run the Catalog, confirm it uses Material Design 3, and verify that data types, entry variants, validation (inline + panel), RTL, responsiveness (360px min), and save/load and multi-tab behavior work as specified.

## Prerequisites

- Flutter SDK and dependencies installed for the package and Catalog app
- Feature spec and plan in `specs/005-catalog-md3-ui/`
- Localization assets (e.g. under `assets/lang/` or the path the Catalog is configured to use)

## Workflow

### 1. Run the Catalog

From the repository root:

```bash
# Standalone Catalog app (if used)
cd tool/catalog_app && flutter run

# Or run the Catalog from the package example / integration point as defined in the project
```

Ensure the Catalog opens and shows the entry list (or empty state) and that the UI uses Material 3 theming (theme colors, typography, and components match MD3).

### 2. Verify MD3 and stability

- Navigate between list, entry detail, and edit; confirm layout and controls are consistent.
- Confirm no regressions: list, filter, edit entry, and save complete without broken or missing controls.
- Optionally switch light/dark theme and confirm color roles and contrast remain correct.

### 3. Verify data types and type-specific inputs

- Create or edit an entry; set data type to string, numerical, gender, date, and date-time.
- Confirm the value input adapts: text field, number field, gender options, date picker, date-time picker.
- Save and reload; confirm type and value persist.

### 4. Verify entry variants (plurals, gender, regional)

- Open an entry that has plural forms, gender variants, or regional overrides (if your assets support them).
- Confirm you can view and edit those variants in the Catalog.
- Save and confirm variants persist.

### 5. Verify validation display

- Trigger at least one validation scenario (e.g. missing plural form or type mismatch) so that validation messages exist.
- Confirm the current entry shows an inline summary or indicator.
- Confirm a dedicated list or panel shows all validation messages; if many, confirm they are grouped or paginated appropriately.

### 6. Verify RTL (if applicable)

- Set the Catalog or app locale to an RTL language (e.g. Arabic) if supported.
- Confirm layout and text direction switch to RTL and remain usable.

### 7. Verify responsiveness and 360px minimum

- Resize the Catalog window to 360px width (or use a device/emulator at 360px).
- Complete the primary workflow (open list, select entry, edit, save) without horizontal scroll blocking critical controls.

### 8. Verify save/load error behavior

- Simulate a save failure (e.g. make the target file read-only or disconnect storage if possible); attempt save.
- Confirm an error message is shown and form data is kept; fix the cause and save again.
- If load failure can be simulated, confirm error is shown and already-loaded state is retained where applicable.

### 9. Verify multi-tab behavior (optional)

- Open the same localization source in two Catalog tabs or windows.
- Edit and save in one tab; in the other, confirm the defined behavior (reload prompt or last save wins) and that data is not silently corrupted.

## Success Checklist

- [ ] Catalog runs and uses Material Design 3 (theme, components, typography).
- [ ] Language configuration is available: list of languages/locales and language-specific settings (e.g. Arabic: RTL, plural, gender; English: regional variants, time format; other languages) are viewable and editable.
- [ ] Add new key: default language string is required; other locales optional with warning if empty; missing values fall back to default at runtime.
- [ ] Add new language: user can add a new localization language by selecting from a list (at least Arabic and English); the new language becomes an enabled locale and appears in the Catalog for editing.
- [ ] Data type selection and type-specific inputs work for all supported types.
- [ ] Plural/gender/regional variants are visible and editable where supported.
- [ ] Validation appears inline for current entry and in a dedicated list/panel.
- [ ] RTL works when locale or content requires it.
- [ ] At 360px width, core workflow is usable without blocking horizontal scroll.
- [ ] Save failure shows error and keeps form data; load failure shows error and retains state.
- [ ] Multi-tab behavior is defined and preserves data integrity.
- [ ] Button emphasis matches importance (one primary per section/dialog, secondary and tertiary use lower emphasis).
- [ ] UI is easy to implement and edit: structure is clear, design system components are reused, and a small change (e.g. label or button) can be made in a localized way.

## Related

- Spec: [spec.md](../spec.md)
- Plan: [plan.md](../plan.md)
- Contract: [contracts/catalog-ui-contract.md](contracts/catalog-ui-contract.md)
