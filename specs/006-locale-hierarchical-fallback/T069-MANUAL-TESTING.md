# T069 Manual Testing Checklist - Acceptance Scenarios

## Acceptance Scenario Testing Guide

### Phase 5 (US3) - Visualization Tests

✅ **Scenario 1: Language group visual grouping**
- [ ] Open catalog with `ar`, `ar_EG`, `ar_SA` where `ar_EG` is group fallback
- [ ] Verify locales are grouped under "Arabic"
- [ ] Verify `ar_EG` is marked with "Global Fallback for Arabic" badge
- [ ] Verify group is expandable/collapsible

✅ **Scenario 2: Fallback chain tooltip**
- [ ] Hover over `ar_SA` in locale list
- [ ] Verify tooltip shows: "ar_SA → ar_EG → ar → en"
- [ ] Verify tooltip appears on hover and disappears on mouse leave

✅ **Scenario 3: Multiple language groups**
- [ ] Create project with Arabic (ar, ar_EG, ar_SA), English (en, en_GB, en_US), Spanish (es, es_MX, es_AR)
- [ ] Verify each group is visually distinct
- [ ] Verify all groups are expandable/collapsible independently

✅ **Scenario 4: Custom locale badge**
- [ ] Add custom locale `fr_CA` (LTR)
- [ ] Verify it displays in locale list with "Custom" badge
- [ ] Verify badge distinguishes it from predefined locales

✅ **Scenario 5: Fallback chain without group fallback**
- [ ] Create locale `es_MX` without group fallback configured
- [ ] Hover over locale
- [ ] Verify tooltip shows: "es_MX → es → en"

### Phase 1 (US1) - Language Group Fallback Tests

✅ **Scenario 1: Basic fallback configuration**
- [ ] Create project with `ar_EG` and `ar_SA`
- [ ] Set `ar_EG` as fallback for Arabic
- [ ] Add translation key `greeting` with value "مرحبا" only in `ar_EG`
- [ ] Load `ar_SA` locale
- [ ] Verify translation resolves from `ar_EG`

✅ **Scenario 2: Multi-step fallback chain**
- [ ] With `ar_SA` → `ar_EG` configured
- [ ] Remove key from both `ar_SA` and `ar_EG`
- [ ] Verify translation resolves from default locale (`en`)
- [ ] Verify chain is: ar_SA → ar_EG → ar → en

✅ **Scenario 3: Single language group (no fallback option)**
- [ ] Create project with only `ar_EG`
- [ ] Open settings
- [ ] Verify no fallback option is shown (requires 2+ regional variants)

✅ **Scenario 4: Change fallback locale**
- [ ] With `ar_SA` → `ar_EG` configured
- [ ] Change fallback to `ar_SA`
- [ ] Verify `ar_EG` now falls back to `ar_SA`
- [ ] Verify all Arabic variants use `ar_SA` as fallback

✅ **Scenario 5: Remove fallback configuration**
- [ ] With `ar_SA` → `ar_EG` configured
- [ ] Remove fallback configuration
- [ ] Verify `ar_SA` reverts to: ar_SA → ar → en

### Phase 2 (US2) - Custom Locale Tests

✅ **Scenario 1: Custom locale input dialog**
- [ ] Open "Add Locale" dialog
- [ ] Click "Enter Custom Code" tab
- [ ] Verify input fields for locale code are present
- [ ] Verify direction selector (LTR/RTL) is present
- [ ] Verify LTR is selected by default

✅ **Scenario 2: Valid custom locale creation**
- [ ] Enter locale code `es_MX`
- [ ] Select LTR
- [ ] Submit
- [ ] Verify locale is created as "Spanish (Mexico)"
- [ ] Verify LTR is applied to text fields

✅ **Scenario 3: Invalid language code rejection**
- [ ] Enter locale code `xyz_ABC`
- [ ] Verify error message appears: "Invalid language code 'xyz'"
- [ ] Verify submit button is disabled

✅ **Scenario 4: Invalid country code rejection**
- [ ] Enter locale code `en_ZZ`
- [ ] Verify error message appears: "Invalid country code 'ZZ'"
- [ ] Verify submit button is disabled

✅ **Scenario 5: Duplicate locale detection**
- [ ] Try to create locale that already exists
- [ ] Verify error: "Locale 'es_MX' already exists"

✅ **Scenario 6: Custom RTL locale**
- [ ] Create custom locale `ur_PK`
- [ ] Select RTL direction
- [ ] Submit
- [ ] Verify text input fields for this locale display RTL

✅ **Scenario 7: Locale code normalization**
- [ ] Enter `en-US` (with hyphen)
- [ ] Verify it's normalized to `en_US` (underscore)
- [ ] Verify created locale is `en_US`

### Edge Cases

✅ **Scenario 1: Regional variant as base language fallback prevention**
- [ ] Try to set `ar_EG` (regional) as fallback for `ar` (base)
- [ ] Verify error: "Cannot set a regional variant as fallback for a base language"

✅ **Scenario 2: Fallback locale deletion**
- [ ] Create `es_MX` and `es_AR` with `es_AR` → `es_MX`
- [ ] Delete `es_MX`
- [ ] Verify fallback reference is removed
- [ ] Verify `es_AR` chain is now: es_AR → es → en

✅ **Scenario 3: Custom locale with only language code**
- [ ] Create custom locale `fr` (no country code)
- [ ] Verify it can be created as base language
- [ ] Verify it can serve as fallback for `fr_CA`

✅ **Scenario 4: Circular fallback prevention**
- [ ] Try to configure: `ar_SA` → `ar_EG` and `ar_EG` → `ar_SA`
- [ ] Verify circular reference is detected and prevented

✅ **Scenario 5: Missing translation fallback chain**
- [ ] Create `ar_SA` → `ar_EG` → base
- [ ] Remove key from all three locales
- [ ] Load locale
- [ ] Verify resolution attempts all locales in order

### Logging Verification

✅ **Scenario 1: Language group fallback logging**
- [ ] Enable debug logging
- [ ] Load locale with group fallback configured
- [ ] Verify log shows: "Language group fallback resolved: ar_SA → ar_EG"

✅ **Scenario 2: Fallback chain logging**
- [ ] Enable debug logging
- [ ] Load locale
- [ ] Verify log shows: "Fallback chain for ar_SA: ar_SA → ar_EG → ar → en"

✅ **Scenario 3: Validation error logging**
- [ ] Enable warning logging
- [ ] Try invalid custom locale code
- [ ] Verify log shows validation error

### Backward Compatibility

✅ **Scenario 1: Legacy catalog state loading**
- [ ] Load existing `catalog_state.json` without new fields
- [ ] Verify no errors occur
- [ ] Verify new fields default to empty maps

✅ **Scenario 2: Field addition**
- [ ] Load legacy state and add new fields
- [ ] Save and reload
- [ ] Verify new fields are preserved

### Performance Tests

✅ **Scenario 1: Large number of locales**
- [ ] Create catalog with 20+ locales in multiple language groups
- [ ] Verify UI renders without lag
- [ ] Verify expand/collapse is responsive

✅ **Scenario 2: Large translation files**
- [ ] Create locales with 1000+ translation keys
- [ ] Configure fallbacks between locales
- [ ] Verify translation resolution is fast (< 100ms)

---

## Testing Notes

- All tests should be conducted in both light and dark mode
- Test on multiple screen sizes (mobile, tablet, desktop)
- Test on both iOS/Android simulators and web
- Verify all error messages are displayed in configured language
- Verify all UI elements follow Material Design 3 guidelines
- Run accessibility checks (screen reader, color contrast)

## Sign-off

Tested by: _________________________ Date: _________

Results:
- [ ] All acceptance scenarios pass
- [ ] All edge cases handled correctly
- [ ] Logging output is correct
- [ ] Backward compatibility verified
- [ ] Performance acceptable
