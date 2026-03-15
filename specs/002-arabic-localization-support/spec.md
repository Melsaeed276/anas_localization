# Feature Specification: Arabic Language Localization Support

**Feature Branch**: `002-arabic-localization-support`  
**Created**: 2025-03-15  
**Status**: Draft  
**Input**: User description: "a new update for arabic support: here is a full document." (comprehensive Arabic localization specification provided)

## Clarifications

### Session 2025-03-15

- Q: How is user context (gender, formality, region/locale) provided to the system—app-level only, per-call only, or configurable? → A: App-level default with optional overrides (global default; callers can override per screen or per resolution when needed).
- Q: When multiple fallbacks apply (e.g. missing plural form, then missing gender, then missing key), should the spec define a single canonical order? → A: Yes. Canonical order documented in spec: within same key try alternate form (plural → other, gender → other, variant → MSA), then base language or key.
- Q: Additional: optional "type of string" per key (e.g. numeric, date, plural) to guide fallback and surface warnings when required configuration is missing; warnings shown in CLI or Catalog UI (e.g. "this key, type numeric, should have 'many' configured"). Gender is only male or female; if not set, default is male. → A: Accepted. Spec updated with optional string type, canonical fallback order, warning behavior (CLI / Catalog UI), and gender strictly male/female with default male.
- Q: When translations are loaded asynchronously and a key is requested before load completes, should the system block, use fallback, or show loading? → A: Use fallback immediately (do not block). If the asset loads in the background later, the system MUST rebuild/refresh the displayed text so the user sees the newly loaded translation.
- Q: Is there a performance requirement for message resolution or locale switching? → A: Qualitative only: resolution and locale switch must feel instant (no perceptible delay) in normal conditions.
- Q: Should the spec include an explicit "Out of scope" subsection for the first release? → A: Yes. Add an "Out of scope (first release)" subsection listing e.g. Hijri, diacritics, grammatical case, configurable fallback chain.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Correct Reading Direction and Layout (Priority: P1)

An Arabic-speaking user opens the app with Arabic as the display language. All text and layout flow right-to-left so that reading feels natural. Mixed content (e.g., Arabic text with an email address or phone number) displays without breaking layout or putting numbers/URLs in the wrong order.

**Why this priority**: RTL is essential for readability; without it, Arabic support is unusable.

**Independent Test**: Set app language to Arabic and verify all screens and mixed text (Arabic + numbers, URLs, emails) render in the correct reading direction and alignment. Can be validated by a native reader or visual inspection.

**Acceptance Scenarios**:

1. **Given** the user has selected Arabic as the app language, **When** they view any screen, **Then** the overall layout and text flow are right-to-left.
2. **Given** content contains Arabic and a phone number or email, **When** it is displayed, **Then** the number/email appears in a logical order and does not break the line or direction.
3. **Given** content contains punctuation or brackets around Arabic, **When** it is displayed, **Then** punctuation and bracket placement respect right-to-left flow.

---

### User Story 2 - Count-Dependent Messages Use Correct Plural Form (Priority: P1)

An Arabic-speaking user sees messages that depend on a count (e.g., "X messages", "no items"). The wording matches Arabic grammar: a distinct form for zero, one, two, few (n%100 in 3..10), many (n%100 in 11..99), and other (all other values, including 100+ and decimals). For n ≥ 100 the same rules apply via n % 100 (e.g. 103 → few, 115 → many), per CLDR.

**Why this priority**: Arabic has six plural categories; using the wrong form is grammatically incorrect and reduces trust.

**Independent Test**: For a message that varies by count, pass 0, 1, 2, 5, 15, and 100 and verify the displayed string matches the expected grammatical form for each range. Can be tested with a single pluralized message type.

**Acceptance Scenarios**:

1. **Given** a pluralized message key and count 0, **When** the message is resolved, **Then** the "zero" form is shown (e.g., "no messages" equivalent).
2. **Given** count 1, **When** the message is resolved, **Then** the "one" form is shown.
3. **Given** count 2, **When** the message is resolved, **Then** the "two" form is shown.
4. **Given** count such that n%100 is in 3..10 (e.g. 3–10, 103–110), **When** the message is resolved, **Then** the "few" form is shown.
5. **Given** count such that n%100 is in 11..99 (e.g. 11–99, 111–199), **When** the message is resolved, **Then** the "many" form is shown.
6. **Given** count such that n%100 is 0, 1, 2, or outside 3..99 (e.g. 100, 200, or a decimal/fraction), **When** the message is resolved, **Then** the "other" form is shown with the count substituted where applicable.

---

### User Story 3 - Gender-Appropriate Wording (Priority: P1)

An Arabic-speaking user receives messages that refer to "you" or "your" (e.g., welcome, "your account", "you have X items"). The wording uses the correct grammatical gender (masculine or feminine) based on the user context so that phrases sound natural.

**Why this priority**: Arabic requires gender agreement; wrong gender is noticeable and can feel disrespectful or careless.

**Independent Test**: Set user gender context to masculine, then feminine; for each, verify that a small set of "you/your" strings (welcome, your account, you have) show the corresponding form. Can be tested without other localization features.

**Acceptance Scenarios**:

1. **Given** user context is set to masculine, **When** a message that has masculine/feminine variants is shown, **Then** the masculine form is displayed.
2. **Given** user context is set to feminine, **When** the same message is shown, **Then** the feminine form is displayed.
3. **Given** a message that combines count and gender (e.g., "you selected X items"), **When** both count and gender are set, **Then** the correct combined form is shown (or a defined fallback is used if a form is missing).

---

### User Story 4 - Numbers, Dates, and Times Match Region (Priority: P2)

An Arabic-speaking user sees numbers, dates, and times formatted in a way that matches their region: either Eastern Arabic digits (٠–٩) with regional separators, or Western digits (0–9), and dates/times in the expected order and with localized month/weekday names and AM/PM labels.

**Why this priority**: Familiar formatting reduces cognitive load and supports trust in the app.

**Independent Test**: Set region/locale to a country that uses Eastern numerals (e.g., Saudi Arabia) and another that uses Western numerals (e.g., Morocco); verify that numbers, a sample date, and time are formatted accordingly with correct separators and labels.

**Acceptance Scenarios**:

1. **Given** the user's region uses Eastern Arabic numerals, **When** a number is displayed, **Then** digits and thousand/decimal separators follow that system.
2. **Given** the user's region uses Western numerals, **When** a number is displayed, **Then** digits and separators follow that system.
3. **Given** a date is displayed, **When** the user's locale is Arabic, **Then** weekday and month names appear in Arabic and in the expected order for the locale.
4. **Given** a time is displayed in 12-hour format, **When** the locale is Arabic, **Then** AM/PM labels use the expected Arabic abbreviations (e.g., ص / م).

---

### User Story 5 - Currency Amounts Formatted Correctly (Priority: P2)

An Arabic-speaking user sees prices and currency amounts with the correct symbol or code and position (before or after the number) for the currency, using the selected numeral system.

**Why this priority**: Currency formatting is expected in commerce and finance; wrong position or digits is confusing.

**Independent Test**: Display a fixed amount in at least two currencies (e.g., a local Arab currency and USD); verify symbol/code position and numeral style match expectations for the locale.

**Acceptance Scenarios**:

1. **Given** a currency used in Arab regions (e.g., Saudi Riyal, Egyptian Pound), **When** an amount is displayed, **Then** the symbol or code appears in the correct position (typically after the number) and numerals match the locale.
2. **Given** a currency like USD or EUR, **When** displayed in an Arabic locale, **Then** the symbol appears in the expected position (e.g., before the number) and numerals still follow the locale's numeral system.

---

### User Story 6 - Regional Variant and Formality (Priority: P2)

An Arabic-speaking user can optionally use a regional variant (e.g., Modern Standard Arabic, Gulf, Egyptian) and a formality level (formal vs informal) so that key phrases match how they speak or expect to be addressed (e.g., "you" as "حضرتك" vs "أنت").

**Why this priority**: Supports broader acceptance across regions and contexts (business vs casual).

**Independent Test**: Switch between MSA and one dialect, and between formal and informal; verify that a set of key phrases (e.g., "you", "your account") changes accordingly where variants exist.

**Acceptance Scenarios**:

1. **Given** a regional variant is selected (e.g., Gulf, Egyptian), **When** a phrase has a variant-specific translation, **Then** that variant is shown; otherwise a defined fallback (e.g., MSA) is used.
2. **Given** formality is set to formal, **When** a phrase has formal/informal variants, **Then** the formal form is shown (e.g., respectful "you").
3. **Given** formality is set to informal, **When** such a phrase is shown, **Then** the informal form is shown.

---

### User Story 7 - Honorifics and Titles (Priority: P2)

When the app displays a person's title and name (e.g., Dr., Mr., Mrs., Engineer), the title is shown in Arabic and in the correct gender form (masculine/feminine).

**Why this priority**: Common in professional and formal contexts; wrong gender for title is noticeable.

**Independent Test**: Display "Dr. Ahmed" and "Dr. Fatima" (or equivalent names); verify the Arabic title form matches the gender (e.g., الدكتور / الدكتورة).

**Acceptance Scenarios**:

1. **Given** a title and a name, **When** the locale is Arabic, **Then** the title is displayed in Arabic in the correct gender form.
2. **Given** an unknown or unsupported title, **When** displayed, **Then** a safe fallback (e.g., name only or generic label) is used.

---

### User Story 8 - Fallback When Translations or Context Are Missing (Priority: P2)

When a specific form is missing (e.g., a plural form, a gender variant, or a dialect) or when user context (e.g., gender) is not set, the system uses a defined fallback so the user always sees a valid message rather than a key or empty string.

**Why this priority**: Ensures a consistent experience and avoids broken or blank UI.

**Independent Test**: Omit one plural form, omit one gender variant, and leave gender unset; verify that fallback rules (e.g., other → masculine → neutral → base language) produce a sensible string without errors.

**Acceptance Scenarios**:

1. **Given** a pluralized message is missing one of the six forms, **When** the count would select that form, **Then** a defined fallback form (e.g., "other") is used.
2. **Given** a gendered message is missing the feminine (or masculine) form, **When** that gender is selected, **Then** the available form or a neutral fallback is used.
3. **Given** user gender is not set, **When** a gendered message is shown, **Then** the male form is used consistently.
4. **Given** a translation key is missing entirely, **When** the key is requested, **Then** the app shows a defined fallback (e.g., key name or base language) and does not crash.

---

### User Story 9 - Search and Sort in Arabic (Priority: P3)

When the user searches or sorts content in Arabic, the order follows Arabic alphabetical order and search treats equivalent characters (e.g., different forms of hamza, or with/without diacritics) as matching so that results are predictable and inclusive.

**Why this priority**: Improves findability and list ordering in Arabic-only or mixed lists.

**Independent Test**: Provide a list of Arabic strings; run sort and verify order. Search for a term with one form of a letter and verify that variants (e.g., أ, إ, آ) match. Can be tested in isolation with a small dataset.

**Acceptance Scenarios**:

1. **Given** a list of Arabic strings, **When** sorted alphabetically for Arabic, **Then** the order follows the expected Arabic alphabet order and the definite article "ال" is handled consistently.
2. **Given** a search query in Arabic, **When** matching against content, **Then** equivalent character forms and optional diacritics are treated as matches so that relevant results are not missed.

---

### User Story 10 - Accessibility and Input (Priority: P3)

Screen reader users hear Arabic content in the correct order and with numbers announced appropriately. Users can enter Arabic names (including typical characters and spaces) and, where applicable, phone numbers in local formats; validation and display support the chosen locale and direction.

**Why this priority**: Ensures Arabic support is usable for assistive technology and for entering personal data.

**Independent Test**: Use a screen reader with the app in Arabic and verify announcement order and number reading. Enter a valid Arabic name and a locale-appropriate phone number and verify acceptance and display.

**Acceptance Scenarios**:

1. **Given** the app is in Arabic and a screen reader is enabled, **When** content is read, **Then** the reading order and number pronunciation are appropriate for Arabic.
2. **Given** the user enters a name in Arabic (allowed character set, reasonable length), **When** the form is submitted, **Then** the input is accepted and stored/displayed correctly.
3. **Given** the user enters a phone number in a supported regional format, **When** valid, **Then** it is accepted and displayed in a consistent format; invalid input is rejected with a clear indication.

**Validation rules (Arabic names and phone)** (ref. FR-014): *Allowed character set for Arabic names*: Unicode letters (including Arabic script), spaces, and common diacritics; configurable allowlists recommended. *Reasonable length*: configurable max length (e.g. 2–200 graphemes); product-specific. *Supported regional phone formats*: at least one format per supported Arabic-speaking region (e.g. E.164, national format for SA, EG, AE, etc.); validity and display follow configured rules. Details may be documented in package docs or a linked validation reference.

---

### Edge Cases

- When the count is negative, decimal, or very large, the system selects the appropriate plural form (e.g., "other" for decimals) and displays the value without breaking layout.
- When content is empty or a translation is missing, the system uses the canonical fallback chain and does not show raw keys or crash. When a key has an optional string type and a required form is missing, the system still resolves to a valid fallback string and MAY show a warning in CLI or Catalog UI that the key (of that type) should have the missing form configured.
- When the user switches language, region, gender, or formality mid-session, all visible messages update to reflect the new context where applicable.
- When translations load asynchronously and the system initially showed a fallback, once the asset loads in the background the displayed text is rebuilt or refreshed so the user sees the loaded translation instead of remaining on the fallback.
- When bidirectional content appears (e.g., Arabic with embedded URL or email), direction and punctuation are handled so that LTR segments do not break RTL flow.
- When date or time is invalid or out of range, the system handles it gracefully (e.g., clear message or placeholder) instead of showing corrupted output.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST display all UI and text in right-to-left layout when Arabic is the active language.
- **FR-002**: The system MUST support bidirectional text so that segments that are inherently left-to-right (numbers, URLs, emails, phone numbers) render in the correct order within Arabic content.
- **FR-003**: The system MUST resolve pluralized messages using six categories for Arabic: zero (n=0), one (n=1), two (n=2), few (n%100 in 3..10), many (n%100 in 11..99), and other (all other values, including 100+ and decimals/fractions), and substitute the count where required. For n ≥ 100 the same rules apply via n % 100 (CLDR-aligned).
- **FR-004**: The system MUST support gender context (male/female only; default male when not set) and resolve messages that have gender-specific variants accordingly. See FR-018 for the strict constraint.
- **FR-005**: The system MUST support messages that depend on both count and gender, using the correct combined form or a defined fallback when a form is missing.
- **FR-006**: The system MUST format numbers according to the user's region, including choice of Eastern or Western Arabic numerals and the correct decimal and thousands separators.
- **FR-007**: The system MUST format dates and times in Arabic with localized weekday and month names and AM/PM labels, and support at least the Gregorian calendar for the primary date/time display.
- **FR-008**: The system MUST format currency amounts with the correct symbol or code and position (before/after number) for the currency and locale.
- **FR-009**: The system MUST support at least one regional variant (e.g., Modern Standard Arabic) with the option to use additional variants (e.g., Gulf, Egyptian) where translations exist.
- **FR-010**: The system MUST support formal and informal variants for phrases that differ by formality (e.g., "you", "your") and use the selected formality level when resolving messages.
- **FR-011**: The system MUST support honorifics and titles in Arabic with correct masculine/feminine forms when displaying a person's title and name.
- **FR-012**: The system MUST apply a canonical fallback chain when a requested translation form (plural, gender, variant, or key) is missing, so that the user always sees a valid message. Fallback order: within the same key try alternate form (plural → other, gender → other, variant → MSA), then base language or key display. When a form is missing and the key has an optional string type (e.g. numeric, date, plural), the system SHOULD surface a warning—in CLI or in Catalog UI—indicating that the key (of that type) should have the missing form configured (e.g. "key X, type numeric, should have 'many' configured"); the resolved fallback string is still shown to the end user.
- **FR-013**: The system MUST support Arabic alphabetical sorting and search normalization (e.g., equivalent character forms and optional diacritics) for content in Arabic.
- **FR-014**: The system MUST validate and display user input for Arabic names and locale-appropriate phone numbers according to configured rules (allowed characters, length, format). See *Validation rules (Arabic names and phone)* below for definitions of allowed character set, reasonable length, and supported regional phone formats.
- **FR-015**: The system MUST expose locale metadata (language code, script, optional country/region) and support multiple Arabic-speaking regions (e.g., SA, EG, AE, MA, DZ, TN, LB, JO, IQ) for defaults. "Expose" means the package uses and may provide this data for resolution and formatting (e.g. a supported-regions list or locale helpers); a dedicated public API is not required unless implementation tasks add one.
- **FR-016**: The system MUST accept user context (locale, gender, formality, regional variant) as an app-level default and MUST allow callers to override that context when needed (e.g., per screen or per message resolution).
- **FR-017**: The system MAY support an optional string type per key (e.g. numeric, date, plural) that callers can supply; when supported, the system uses this type to guide fallback behavior and to produce targeted warnings (CLI or Catalog UI) when required configuration for that type is missing (e.g. a plural key missing the "many" form).
- **FR-018**: Gender context MUST be exactly male or female; no other values. When gender is not set, the system MUST default to male.
- **FR-019**: When a translation is requested and the corresponding asset is not yet loaded (e.g. async bundle or remote), the system MUST resolve immediately using the fallback chain and MUST NOT block the UI. When the asset finishes loading in the background, the system MUST rebuild or refresh the displayed text so the user sees the newly loaded translation where applicable.

### Key Entities

- **Locale**: Language (e.g., Arabic), script (e.g., Arabic script), and optional region/country used to select formatting and translation variants.
- **Plural form**: One of six categories (zero, one, two, few, many, other) used to select the correct string for a count in Arabic. For Arabic, few = n%100 in 3..10, many = n%100 in 11..99, other = remainder (CLDR).
- **Gender context**: User or audience gender; only male or female. Default when not set is male. Used to select the correct string for messages that vary by gender.
- **Regional variant**: Dialect or standard (e.g., MSA, Gulf, Egyptian) used to select dialect-specific translations where available.
- **Formality level**: Formal or informal mode affecting choice of pronouns and phrasing.
- **Translation entry**: A message key with one or more forms (e.g., by plural, gender, variant, formality) and optional placeholders (e.g., count, name). Optionally carries a string type (e.g., numeric, date, plural) used to guide fallback and to surface warnings when required forms are missing (CLI or Catalog UI).

## Assumptions

- The feature is implemented within or on top of an existing localization/library infrastructure; exact mechanism is out of scope for this spec.
- Default regional variant when not specified is Modern Standard Arabic (MSA).
- Gender is only male or female; no other values. When gender is not set, the system defaults to male.
- Formality defaults to formal in business/official contexts unless the product specifies otherwise.
- Hijri calendar support is optional (nice-to-have); the minimum is Gregorian with Arabic names.
- Diacritics (tashkeel) and grammatical case are optional and not required for the first release; they can be added later for specialized use cases (e.g., education, religious content).
- Supported regions and currencies are those listed in the source document; additional regions/currencies can be added later without changing the spec.

## Out of scope (first release)

The following are explicitly not in scope for the first release; they may be added later without changing this spec:

- **Hijri (Islamic) calendar** as primary or alternate date display (Gregorian with Arabic names is in scope).
- **Full diacritics (tashkeel)** support; default is no diacritics.
- **Grammatical case** (nominative, accusative, genitive) for Arabic; not required for general apps.
- **Configurable fallback chain**: the canonical order is fixed in the spec; apps cannot supply a custom fallback policy for the first release.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users with Arabic selected see all primary screens and messages in right-to-left layout with no broken or reversed segments for mixed content (e.g., URLs, numbers) in representative test cases.
- **SC-002**: For every pluralized message tested, the correct one of the six Arabic plural forms is shown for counts 0, 1, 2, 5, 15, and 100, with count substituted where applicable.
- **SC-003**: For every gendered message tested, switching user gender context produces the corresponding masculine or feminine form without errors or fallback to the wrong gender.
- **SC-004**: Numbers, dates, and currency amounts displayed in Arabic match the expected format (numeral system, separators, symbol position) for at least two regions (e.g., one Eastern-numeral and one Western-numeral region).
- **SC-005**: When a translation form or key is missing, the system uses the defined fallback and never shows a raw key or blank critical text in normal operation.
- **SC-006**: Arabic sort order for a sample list matches the expected alphabetical order; search finds intended matches when using equivalent character forms or without diacritics.
- **SC-007**: Users can complete representative flows (e.g., view dashboard, see counts and dates, change gender/region) in Arabic without layout or resolution errors that block understanding.
- **SC-008**: Message resolution and locale switching exhibit no perceptible delay in normal conditions (feel instant to the user).

