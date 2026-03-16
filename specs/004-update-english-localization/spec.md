# Feature Specification: English Language Localization Alignment

**Feature Branch**: `004-update-english-localization`  
**Created**: 2026-03-15  
**Status**: Draft  
**Input**: User description: "as we updated the arabic language cinfigration we will update the English." plus detailed English language localization requirements aligned against the updated Arabic configuration.

## Clarifications

### Session 2026-03-15

- Q: Which default time format should each English regional variant use? → A: `en-US` and `en-CA` use 12-hour by default; `en-GB` and `en-AU` use 24-hour by default.
- Q: How should negative counts be handled for English plural selection? → A: Use absolute value for plural selection; `-1` uses singular and `-2` uses plural.
- Q: What should regional English overrides include in the first release? → A: Regional overrides cover spelling and selected vocabulary differences.
- Q: What spelling baseline should `en-CA` use in the first release? → A: `en-CA` uses mostly UK-style spelling defaults, with Canadian-specific vocabulary overrides where needed.
- Q: How should English locales be structured in the first release? → A: Keep a shared base `en`, then layer `en-US`, `en-GB`, `en-CA`, and `en-AU` overrides on top.

## Terminology Note

- Hyphenated locale labels such as `en-US` are used in user-facing requirements and examples.
- Underscored locale codes such as `en_US` are used for normalized internal locale identifiers and asset file names.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Correct English Plural Behavior (Priority: P1)

As a user reading English content in the product, I see count-based messages that use natural English singular and plural wording so that messages feel correct and trustworthy.

**Why this priority**: Count-based messages are common across products, and incorrect plural wording is immediately visible to users.

**Independent Test**: Resolve a small set of English count-based messages for counts 0, 1, 2, 5, -1, -2, and 1.5 and verify the system uses the correct English singular or plural form and substitutes the count correctly.

**Acceptance Scenarios**:

1. **Given** an English message that varies by count, **When** the count is 1, **Then** the singular form is shown.
2. **Given** an English message that varies by count, **When** the count is 0, 2, 5, or 1.5, **Then** the plural form is shown.
3. **Given** an English message that varies by count, **When** the count is negative, **Then** plural selection uses the absolute value of the count so `-1` is singular and other negative values follow the corresponding plural rule.
4. **Given** an English message that uses an irregular noun, **When** the count changes between singular and plural, **Then** the stored irregular wording is shown rather than an automatically derived form.

---

### User Story 2 - Regional English Variants Feel Native (Priority: P1)

As a user in an English-speaking region, I see spelling, selected vocabulary, date presentation, time presentation, and currency display that match the English variant used for my region so the product feels locally appropriate.

**Clarification**: “Locally appropriate” is satisfied when spelling, vocabulary, and date/time/currency presentation match the active regional variant (e.g. US vs UK) as defined in this spec; no separate usability metric is required.

**Why this priority**: Regional correctness is the main English-specific difference called out in scope and is essential when supporting multiple English-speaking markets.

**Independent Test**: Switch the active English variant between at least US, UK, Canada, and Australia and verify representative text, dates, times, and currency examples change to the expected regional presentation.

**Acceptance Scenarios**:

1. **Given** the active locale is US English, **When** a region-sensitive word is shown, **Then** the US spelling is displayed.
2. **Given** the active locale is UK, Canadian, or Australian English, **When** a region-sensitive word or supported vocabulary term is shown, **Then** the corresponding regional override is displayed where one exists, with `en-CA` using mostly UK-style spelling by default and Canadian-specific vocabulary where defined.
3. **Given** the active locale is a specific English-speaking region, **When** a date, time, or currency amount is shown, **Then** the presentation follows that region's expected format, including a default 12-hour clock for `en-US` and `en-CA` and a default 24-hour clock for `en-GB` and `en-AU`.

---

### User Story 3 - English Scope Stays Simpler Than Arabic (Priority: P2)

As a product maintainer, I can configure English without having to provide Arabic-only grammar features, so English support is easier to maintain while still being correct for English-speaking users.

**Why this priority**: A key goal of the update is to align English with the Arabic configuration work without carrying over unnecessary complexity.

**Independent Test**: Review English localization configuration and validation behavior to confirm required English features are present and Arabic-only features are not required for English entries.

**Acceptance Scenarios**:

1. **Given** English localization is being configured, **When** a translation entry does not provide gender variants, **Then** it remains valid unless that entry explicitly requires a traditional title distinction.
2. **Given** English localization is being configured, **When** no right-to-left, alternate numeral system, alternate calendar, or grammatical case data is provided, **Then** the configuration remains valid.
3. **Given** English localization content is reviewed, **When** a maintainer compares it with Arabic support, **Then** the English scope is limited to the English-specific rules defined in this specification.

---

### User Story 4 - English Content Handles Common Writing Cases (Priority: P3)

As a user reading English UI content, I see messages that account for common English writing needs such as irregular plurals, uncountable nouns, articles, and tone so text reads naturally in context.

**Why this priority**: These cases are important for polished English UX but are secondary to the core plural and regional behavior.

**Independent Test**: Validate representative entries for irregular plurals, uncountable nouns, article-sensitive words, and formal vs informal phrasing to confirm each case is supported through explicit content rather than unsafe assumptions.

**Acceptance Scenarios**:

1. **Given** an entry uses an irregular plural or uncountable noun, **When** it is resolved in English, **Then** the configured wording is shown exactly as authored.
2. **Given** an entry requires an article or tone-specific phrasing, **When** it is resolved, **Then** the full authored phrase is shown without automatic article generation or tone rewriting.

---

### Edge Cases

- When the count is zero, negative, fractional, or very large, the system still selects the correct English singular or plural category and displays a readable result; negative counts use the absolute value for plural selection.
- When an English term has an irregular plural, the system uses the explicitly stored plural wording rather than generating one automatically.
- When a regional override does not exist for a spelling or supported vocabulary term, the system uses the shared base English wording rather than failing.
- When English content includes titles or other rare gendered wording, the system supports explicit authored distinctions without making gender variants mandatory for general English content.
- When a phrase would require article handling, contractions, or tone differences, the authored translation remains the source of truth so the system does not create grammatically incorrect text by composition.

*Edge case coverage*: The scenarios above are reflected in requirements and acceptance criteria as follows: zero/negative/fractional/large counts and irregular plurals → FR-002, FR-003, FR-004 and User Story 1; missing regional override falls back to base → FR-015 and User Story 2; optional gender/titles → FR-013 and User Story 3; articles/contractions/tone authored → FR-014 and User Story 4.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST support English localization as a left-to-right language.
- **FR-002**: The system MUST resolve English pluralized messages using two categories only: singular when the absolute numeric value is 1 and plural for all other numeric values.
- **FR-003**: The system MUST treat zero, decimals, and all non-one absolute numeric values as plural in English output.
- **FR-004**: The system MUST allow English entries with irregular plurals to store explicit singular and plural wording.
- **FR-005**: The system MUST allow English entries with uncountable nouns or measure-based phrasing to store explicit wording for count-based output.
- **FR-006**: The system MUST support a shared default English locale and regional English variants for at least the United States, the United Kingdom, Canada, and Australia.
- **FR-007**: The system MUST allow regional English variants to override shared English text only where spelling, selected vocabulary, or formatting differs by region.
- **FR-008**: The system MUST present dates using the expected regional English format for the active locale.
- **FR-009**: The system MUST present times using the expected regional English preference for the active locale, with `en-US` and `en-CA` defaulting to 12-hour time and `en-GB` and `en-AU` defaulting to 24-hour time.
- **FR-010**: The system MUST present numbers in standard English digit formatting with period decimal separation and comma thousands separation.
- **FR-011**: The system MUST present currency amounts using the expected symbol and placement for the active English-speaking region or currency in use.
- **FR-012**: The system MUST NOT require right-to-left behavior, alternate numeral systems, alternate calendar systems, grammatical cases, or diacritic-specific handling for English localization.
- **FR-013**: The system MUST NOT require gender-based variants for general English entries; gender-specific wording MAY be provided only for entries that explicitly need traditional titles or equivalent distinctions.
- **FR-014**: The system MUST preserve authored English phrases for articles, contractions, capitalization choices, and tone-sensitive wording rather than generating those variations automatically.
- **FR-015**: The system MUST allow a single shared English translation to be reused across regions when no regional override is needed.
- **FR-016**: The system MUST provide validation guidance that distinguishes required English capabilities from Arabic-only capabilities so English content is not treated as incomplete for omitting Arabic-specific rules.
- **FR-017**: The first release MUST limit regional English content differences to spelling and selected vocabulary overrides and MUST NOT require separate regional tone variants for otherwise equivalent content.
- **FR-018**: The first release MUST treat `en-CA` as a distinct regional variant that defaults to mostly UK-style spelling while allowing Canadian-specific vocabulary overrides where needed.
- **FR-019**: The first release MUST use a shared base `en` locale for common English content and layer `en-US`, `en-GB`, `en-CA`, and `en-AU` overrides on top of that base only where regional differences are needed.

### Key Entities

- **English locale**: The shared base `en` language context used for common translations and default English behavior before regional overrides are applied.
- **English regional variant**: A region-specific English context, such as US, UK, Canadian, or Australian English, that can override shared wording or formatting.
- **Canadian English variant**: The `en-CA` regional variant, which defaults to mostly UK-style spelling while allowing Canadian-specific vocabulary overrides.
- **English translation entry**: A localized message that may contain plain text, placeholders, singular and plural forms, and optional regional overrides.
- **Count-sensitive entry**: An English translation entry whose wording changes based on whether the value is singular or plural.
- **Regional override**: A variant-specific replacement layered on top of the shared base `en` locale for spelling, selected vocabulary, date presentation, time presentation, or currency presentation when shared English is not sufficient.

## Assumptions

- Hyphenated locale labels are documentation-facing, while underscored locale codes are used for normalized internal/runtime and file-naming contexts.
- US English is the default shared English variant unless a different regional preference is selected.
- Most English content can reuse one shared translation set with only targeted overrides for spelling, selected vocabulary, and formatting differences.
- Canadian English uses mostly UK-style spelling unless a specific Canadian override is defined.
- A shared base `en` locale is the source of common English content, with regional variants overriding only the entries that differ.
- English date, time, number, and currency presentation should feel familiar to users in each supported English-speaking region.
- English content should default to gender-neutral wording wherever practical.
- English article choice, contractions, and tone are best authored directly in the source translation rather than inferred by the system.
- *Expected* regional date, time, and currency formats are those commonly used in each region (e.g. 12h vs 24h clock, decimal/thousands separators, currency symbol placement); the implementation uses the package’s existing formatters and contracts rather than defining a new format list here.

## Out of scope (first release)

The following are explicitly out of scope for this feature and are not required for English localization:

- Mandatory gender grammar across general English content.
- Right-to-left layout support for English.
- Alternate numeral systems for English.
- Alternate calendar systems for English.
- Grammatical case handling for English.
- Diacritic-specific processing for English.
- Automatic generation of irregular plurals, articles, contractions, or tone variants from a base English phrase.
- Separate regional tone variants for otherwise equivalent English content.

## Success Criteria *(mandatory)*

### Measurable Outcomes

*Representative* in the criteria below means: at least one count-based message (SC-001), one spelling/date/time/currency example per regional variant (SC-002), one reuse-from-base scenario (SC-003), one validation scenario that omits Arabic-only features (SC-004), and one irregular-plural, one uncountable/article-sensitive entry (SC-005). The exact test set is defined by the implementation and quickstart verification.

- **SC-001**: For representative English pluralized messages, counts 0, 1, 2, 5, -1, -2, and 1.5 produce the expected singular or plural wording in 100% of tested cases.
- **SC-002**: At least one representative spelling override, one date example, one time example, and one currency example display correctly for each supported English regional variant in scope, including the default 12-hour clock for `en-US` and `en-CA` and the default 24-hour clock for `en-GB` and `en-AU`.
- **SC-003**: Shared English translations can be reused unchanged from the base `en` locale for entries that do not require regional overrides, reducing duplicated region-specific entries for unchanged content to zero in the representative test set.
- **SC-004**: English localization validation accepts entries that omit Arabic-only features while still flagging missing required English plural or regional data in the representative test set.
- **SC-005**: Representative English entries for irregular plurals, uncountable nouns, and article-sensitive phrases display the authored wording exactly as configured in all tested cases.
