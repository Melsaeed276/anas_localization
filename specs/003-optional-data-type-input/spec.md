# Feature Specification: Optional Data Type Input for Localization

**Feature Branch**: `003-optional-data-type-input`  
**Created**: 2025-03-15  
**Status**: Draft  
**Input**: User description: "add on the plan that also there will be optional input called data_type which will ask the user to enter the type of the data that will give us: (1) more understanding of these data, (2) type-based extensions e.g. numerical, (3) Catalog UI dropdown and type-specific inputs, (4) validation and code generation from localization files (JSON and other) that check these rules."

## Clarifications

### Session 2025-03-15

- Q: Where is data type stored in file-based workflows—same file as values, separate metadata file, or both? → A: Same file as values; type is stored alongside each key (e.g. per-key metadata or structured value) in the localization file.
- Q: When a file is imported and the Catalog already has entries for the same keys, should import overwrite, merge, or let the user choose? → A: Merge: add new keys from the file; for keys that already exist, keep existing type/value unless the file provides them, then apply file data.
- Q: For numerical type, should only integers be accepted or also decimals? → A: Integers and decimals: numerical type accepts both whole numbers and decimal numbers.
- Q: Must date and date & time use a single canonical format everywhere, or can display be locale-specific? → A: Storage format-agnostic, display locale-specific: store/exchange in a canonical form (e.g. ISO 8601); Catalog and display may use locale-specific date/time formats for input and display.
- Q: Should the spec include an explicit "Out of scope (first release)" subsection? → A: Yes. Add subsection listing e.g. extra data types, custom validation rules, timezone handling, configurable import strategy.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Declare Data Type for Better Understanding (Priority: P1)

A person managing localization entries can optionally assign a **data type** (e.g. string, numerical, gender, date, date & time) to each entry. The system uses this type to understand the data better and to drive validation, UI behavior, and extensions so that entries are consistent and easier to work with.

**Why this priority**: Data type is the foundation; without it, type-based behavior cannot be applied.

**Independent Test**: Create or edit an entry, set its data type to a non-default value (e.g. numerical), and confirm the type is stored and used (e.g. in validation or Catalog UI). Can be tested via Catalog or file-based workflow.

**Acceptance Scenarios**:

1. **Given** the user is creating or editing a localization entry, **When** they are prompted for data type, **Then** they can choose from a defined set of types (e.g. string, numerical, gender, date, date & time) and the default is string.
2. **Given** the user has set a data type for an entry, **When** the entry is saved or exported, **Then** the type is persisted and available for validation, UI, and extensions.
3. **Given** the user does not set a data type, **When** the entry is used, **Then** it is treated as string type.

---

### User Story 2 - Type-Based Extensions (Priority: P2)

When an entry has a data type (e.g. numerical), the system provides or enables extensions that make it easier to work with that type and with other data of the same type—for example, shared formatting, validation, or reuse rules for numerical data.

**Why this priority**: Extensions increase consistency and reduce repeated configuration across entries of the same type.

**Independent Test**: Mark two entries as numerical; verify that type-specific behavior (e.g. validation, formatting, or shared rules) applies to both and that working with other numerical data is simplified where the feature is implemented.

**Acceptance Scenarios**:

1. **Given** an entry has type numerical, **When** the system validates or processes it, **Then** numerical-type rules and extensions apply (e.g. number-only input, formatting).
2. **Given** multiple entries share the same data type, **When** supported, **Then** the user can benefit from type-based extensions (e.g. shared validation or formatting) without re-entering type-specific configuration per entry.

---

### User Story 3 - Catalog UI Adapts Input to Data Type (Priority: P1)

In the Catalog UI, the user selects data type from a dropdown (default: string). The input control for the localization value changes according to the type: for numerical only numbers are accepted; for gender a dropdown with male and female; for date a date picker; for date & time a date-and-time picker; for string a normal text field.

**Why this priority**: Type-appropriate inputs reduce errors and improve usability when editing in the Catalog.

**Independent Test**: In the Catalog, set a key’s data type to numerical, then to gender, then to date, then to date & time; verify the value input changes to number field, male/female dropdown, date picker, and date+time picker respectively. For string, verify a standard text field is shown.

**Acceptance Scenarios**:

1. **Given** the user is editing a localization entry in the Catalog, **When** they view or change the data type, **Then** the data type is presented as a dropdown list with default string.
2. **Given** data type is string, **When** the user edits the value, **Then** a text field is used.
3. **Given** data type is numerical, **When** the user edits the value, **Then** the control accepts only numbers (integers and decimals).
4. **Given** data type is gender, **When** the user edits the value, **Then** a dropdown (or equivalent) offers male and female only.
5. **Given** data type is date, **When** the user edits the value, **Then** a date picker is used.
6. **Given** data type is date & time, **When** the user edits the value, **Then** a date-and-time picker is used.

---

### User Story 4 - Validation and Code Generation from Localization Files (Priority: P1)

When localization data is loaded from files (e.g. JSON or other supported formats), the system validates entries against the data type rules and checklists (e.g. required forms for a type, allowed values for gender). When generating code or artifacts, the same rules are applied so that output is consistent and type-correct.

**Why this priority**: File-based workflows must respect data types so that validation and generated code stay aligned with Catalog and runtime behavior.

**Independent Test**: Provide a localization file that includes data type metadata (or inferred types); run validation and code generation. Verify that type-related checks are applied (e.g. numerical entries are numeric, gender entries are male/female) and that generation respects these rules.

**Acceptance Scenarios**:

1. **Given** a localization file (e.g. JSON) is imported or loaded, **When** validation runs, **Then** entries are checked against data type rules (e.g. numerical values are valid numbers; gender values are male or female where type is gender).
2. **Given** validation finds a type violation (e.g. non-numeric value for a numerical entry), **When** the result is presented, **Then** the user sees a clear indication of the failing entry and the rule that failed.
3. **Given** code or other artifacts are generated from localization data, **When** data type is defined for entries, **Then** generation uses the same type rules and checklists so that output is consistent with validation and Catalog behavior.

---

### Edge Cases

- When data type is changed after values already exist, the system validates existing values against the new type and surfaces errors or migration guidance where values are incompatible.
- When a file contains entries without data type metadata, the system treats them as string type unless type can be inferred from context; validation and generation apply string rules by default.
- When the Catalog shows a type-specific control (e.g. date picker), invalid or out-of-range input is rejected with a clear message; the user can correct or change the type.
- When multiple types are supported in one file or project, validation and generation apply the correct rules per entry based on that entry’s type.
- When a file is imported and keys already exist in the Catalog, merge applies: new keys are added; existing keys keep their current type/value unless the file supplies type or value for that key, then the file’s data is applied.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST offer an optional input (data_type) for each localization entry so the user can declare the type of the data (e.g. string, numerical, gender, date, date & time).
- **FR-002**: The default data type when none is specified MUST be string.
- **FR-003**: The system MUST use the declared data type to improve understanding of the data and to drive validation, UI behavior, and type-based extensions.
- **FR-004**: For type numerical, the system MUST apply or enable extensions that make it easier to work with numerical data (e.g. number-only input, formatting, or shared rules) in this release per the implementation plan.
- **FR-005**: In the Catalog UI, the system MUST present data type as a dropdown list with default string and MUST change the value input control based on type: string → text field; numerical → input that accepts numbers only (integers and decimals); gender → dropdown with male and female; date → date picker; date & time → date-and-time picker.
- **FR-006**: When localization data is loaded from files (e.g. JSON or other supported formats), the system MUST read data type from the same file as the values (stored alongside each key) and MUST validate entries against data type rules and checklists (e.g. allowed values for gender, numeric format for numerical) and MUST surface failures clearly.
- **FR-007**: When code or other artifacts are generated from localization data, the system MUST apply the same data type rules and checklists so that output is consistent with validation and Catalog behavior.
- **FR-008**: Gender type MUST allow only male or female as values; the Catalog MUST restrict input to a male/female dropdown when type is gender.
- **FR-009**: When a localization file is imported and the Catalog (or project) already has entries for the same keys, the system MUST merge: add new keys and their type/value from the file; for keys that already exist, keep existing type and value unless the file provides type or value for that key, in which case apply the file’s data.
- **FR-010**: For date and date & time types, the system MUST store and exchange values in a canonical form (e.g. ISO 8601); the Catalog and display MAY use locale-specific date/time formats for input and display.

### Key Entities

- **Data type**: Optional classification of a localization entry (e.g. string, numerical, gender, date, date & time). Default is string. Numerical allows integers and decimals. Drives validation, Catalog UI controls, and type-based extensions.
- **Localization entry**: A key plus one or more values (and optional metadata such as data type). May include plural/gender forms where applicable; type constrains allowed values and input controls.
- **Catalog**: The UI where users create or edit localization entries; presents data type as a dropdown and type-specific value inputs (text field, number field, gender dropdown, date picker, date-and-time picker).

## Assumptions

- Data type is optional; existing entries without a type are treated as string.
- The set of types (string, numerical, gender, date, date & time) is sufficient for the first release; additional types may be added later.
- Validation and code generation are part of the same product or toolchain that provides the Catalog and localization file support.
- Localization files (e.g. JSON) carry data type in the same file as the values—alongside each key (e.g. per-key metadata or structured value). The exact structure is left to the implementation plan.
- For date and date & time types: storage and exchange use a canonical form (e.g. ISO 8601); the Catalog and display may use locale-specific formats for input and display.

## Out of scope (first release)

The following are explicitly not in scope for the first release; they may be added later without changing this spec:

- **Additional data types** beyond string, numerical, gender, date, and date & time (e.g. currency, duration, percentage).
- **Custom validation rules** per type or per entry (user-defined regex or rules).
- **Timezone handling** for date & time (e.g. store/display in a specific timezone); first release assumes canonical format without mandating timezone behavior.
- **Configurable import strategy**: overwrite/merge/skip is not user-selectable at import time; merge behavior is fixed for the first release.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can assign a data type to a localization entry in the Catalog (dropdown, default string) and the stored type is used for validation and UI.
- **SC-002**: In the Catalog, changing data type to numerical, gender, date, or date & time changes the value input to the correct control (number field, male/female dropdown, date picker, date+time picker) and restricts input accordingly.
- **SC-003**: When a localization file is loaded, validation runs against data type rules and reports failures (e.g. non-numeric value for numerical type, invalid option for gender) with clear identification of the entry and rule.
- **SC-004**: Generated code or artifacts respect data type rules so that entries marked as numerical, gender, date, or date & time are handled consistently with validation and Catalog behavior.
- **SC-005**: Users can complete adding or editing an entry with a non-string type (numerical, gender, date, or date & time) in the Catalog using the type-specific control without incorrect input being accepted.
