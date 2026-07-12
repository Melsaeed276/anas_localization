# Feature Specification: Remote Localization V1

**Feature Branch**: `009-remote-localization`  
**Created**: 2026-07-08  
**Status**: Draft  
**Input**: User description: "this spec in @specs/009-remote-localization"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Use Remote Translations Without Changing Startup Behavior (Priority: P1)

As an app developer, I want remote localization to be optional and non-disruptive so existing apps continue rendering local translations immediately while remote updates can be checked separately.

**Why this priority**: This preserves trust for existing package consumers and makes remote localization safe to adopt incrementally.

**Independent Test**: Can be fully tested by initializing localization with and without remote configuration and verifying local translations render first in both cases.

**Acceptance Scenarios**:

1. **Given** an app has no remote localization configuration, **When** localization initializes, **Then** the app uses the same local translation behavior as before.
2. **Given** remote localization is configured but startup checking is disabled, **When** localization initializes, **Then** no remote check is attempted during startup.
3. **Given** startup checking is enabled, **When** localization initializes, **Then** local translations render first and remote work runs without blocking initial localization.

---

### User Story 2 - Check And Apply Remote Updates On Demand (Priority: P2)

As an app developer, I want to trigger remote localization updates manually for all locales or a single locale so my app can refresh translations when it is appropriate for my product flow.

**Why this priority**: Manual control lets developers match different backend designs and avoid forced network work during sensitive app moments.

**Independent Test**: Can be fully tested by invoking manual global and per-locale update flows with connector responses for update available, no update, and failure.

**Acceptance Scenarios**:

1. **Given** a global remote connector reports no update, **When** a global check runs, **Then** no download occurs and the result reports that no update was applied.
2. **Given** a global remote connector reports an update, **When** a global check runs, **Then** the updated locale bundle is downloaded, cached, and made available for localization.
3. **Given** a per-locale remote connector reports an update for `en`, **When** a check runs for `en`, **Then** only the `en` payload is downloaded, cached, and applied.
4. **Given** a caller requests a mode that the configured connector does not support, **When** the check runs, **Then** the operation returns a structured failure instead of attempting an unsupported remote flow.

---

### User Story 3 - Preserve Reliable Fallbacks And Protected Local Keys (Priority: P3)

As an app developer, I want remote translations to merge predictably with packaged and app-provided translations so cached remote content can improve localization without overwriting keys I explicitly protect.

**Why this priority**: Remote translation systems need safe rollback and override behavior to avoid breaking critical in-app copy.

**Independent Test**: Can be fully tested by loading package assets, app assets, cached remote data, and protected app keys, then verifying the final rendered values.

**Acceptance Scenarios**:

1. **Given** package assets, app assets, and cached remote data define the same unprotected key, **When** localization is loaded, **Then** the remote value is used.
2. **Given** an app asset key is marked as protected from remote override, **When** remote data contains the same key, **Then** the app asset value is used.
3. **Given** a protected-key marker exists in local asset metadata, **When** the final dictionary is created, **Then** the marker is not exposed as a rendered translation value.

---

### Edge Cases

- Remote check throws, times out, or returns a failure result.
- Remote check succeeds but the download fails.
- Remote download succeeds but the payload cannot be parsed or normalized.
- Cached remote data is missing, corrupt, stale, or incomplete.
- A manual check requests a global update while only per-locale remote behavior is configured, or requests a per-locale update while only global remote behavior is configured.
- Remote data attempts to override a locally protected app asset key.
- Remote payload version is equal to or older than the cached version.
- Remote errors include sensitive details from a user-owned backend or authentication layer.
- Multiple overlapping manual update calls for the same locale (or global scope) are queued; in-flight duplicates are skipped.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST leave existing localization behavior unchanged unless remote localization is explicitly configured by the package consumer.
- **FR-002**: The system MUST make startup remote checking opt-in and disabled by default.
- **FR-003**: The system MUST load local translations first and MUST NOT block initial localization rendering on remote checks or downloads.
- **FR-004**: The system MUST allow package consumers to provide a remote connector that maps their backend responses into normalized localization results.
- **FR-005**: The system MUST support a global remote check that can determine whether any locale data has changed.
- **FR-006**: The system MUST support a per-locale remote check that can determine whether one requested locale has changed.
- **FR-007**: The system MUST avoid downloading remote localization data when a check reports that no update is available.
- **FR-008**: The system MUST download and cache all changed locale payloads when a supported global check reports that an update is available.
- **FR-009**: The system MUST download and cache only the requested locale payload when a supported per-locale check reports that an update is available for that locale.
- **FR-010**: The system MUST return a structured success or failure result for each remote check/update attempt.
- **FR-011**: The system MUST preserve the last valid cached remote payload when a later check, download, or payload validation fails.
- **FR-012**: The system MUST fall back to local locale assets when no valid cached remote payload is available.
- **FR-013**: The system MUST keep runtime remote data in a cache and MUST NOT write runtime pull results back into app locale asset files.
- **FR-014**: The system MUST use the merge precedence `package assets < app assets < remote cache` for unprotected keys.
- **FR-015**: The system MUST allow app asset keys marked with `override: false` to prevent remote data from replacing those values.
- **FR-016**: The system MUST treat missing override metadata as `override: true`.
- **FR-017**: The system MUST remove override metadata before final translation values are rendered or exposed through dictionaries.
- **FR-018**: The system MUST reload the active locale and notify existing localization listeners when newly applied remote data changes the active dictionary.
- **FR-019**: The system MUST apply a 10-second time limit to remote check and download operations and perform exactly one automatic retry after a 2-second backoff following a failed remote operation.
- **FR-020**: The system MUST queue concurrent remote check/update requests sequentially and MUST skip duplicate in-flight requests for the same locale (or global scope) while an operation is already running.
- **FR-021**: The system MUST NOT store credentials, include credentials in cache keys, or log secrets from user-owned remote connectors.
- **FR-022**: The system MUST keep CLI remote push, Catalog remote sync, remote history, and local asset-file updates outside V1 runtime scope.
- **FR-023**: The system MUST log remote check start/end, download start/end, cache read/write events, and all errors at appropriate log levels, and MUST emit counter metrics for total checks, downloads, cache hits, cache misses, and failures.

### Key Entities

- **Remote Localization Configuration**: Consumer-provided settings that enable remote localization, control startup checking, time limits, cache choice, and the selected remote connector.
- **Remote Connector**: Consumer-owned bridge between a remote backend and normalized package results; it owns authentication, backend request details, and response mapping.
- **Remote Check Result**: Outcome of asking whether remote localization data changed; includes whether an update is available and, for per-locale checks, the affected locale.
- **Remote Localization Payload**: Normalized locale data plus version information for one locale.
- **Remote Localization Version**: Version metadata used to decide whether remote data is newer than cached data; includes an update timestamp and may include equality identifiers such as an ETag or hash.
- **Remote Localization Cache**: Persistent file-based storage for the last valid remote payloads and version metadata, with in-memory fallback for read/write failures.
- **Protected Local Key**: App asset translation entry that cannot be overridden by remote data because it is marked with `override: false`.

### Assumptions

- V1 covers runtime remote pull only; tooling workflows for CLI push/pull, Catalog sync, local asset updates, and history are handled separately.
- Remote version timestamps are interpreted as UTC, and remote data is considered newer only when its timestamp is strictly newer than the cached version.
- Remote payloads use the same translation data shape already accepted by local assets, including nested values and existing plural/select/data-type patterns.
- Remote payloads are expected to be <1MB per locale and support ≤50 locales; no cache size limit is enforced—oldest entries are pruned on write failure.
- Public class names, file locations, and exact developer API signatures are planning details, not business-level specification decisions.

## Clarifications

### Session 2026-07-08

- Q: What timeout and retry strategy should be used for remote check/download operations? → A: 10s timeout, 1 retry with 2s backoff.
- Q: What cache storage mechanism should remote payloads use? → A: Persistent file-based cache with in-memory fallback.
- Q: How should concurrent/overlapping manual update checks be handled? → A: Queue sequential, skip duplicate in-flight requests.
- Q: What observability signals should the remote localization system produce? → A: Log lifecycle events + emit basic counters.
- Q: What are the expected data volume characteristics for remote payloads? → A: <1MB per locale, ≤50 locales, no explicit size limit (prune oldest on write failure).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of existing localization behavior remains unchanged for apps that do not configure remote localization.
- **SC-002**: Initial localization rendering completes from local or cached data without waiting for a remote network operation in all startup configurations.
- **SC-003**: Manual global update checks correctly skip downloads when no update is reported and apply cached remote data when an update is reported.
- **SC-004**: Manual per-locale update checks download only the requested locale when an update is reported for that locale.
- **SC-005**: Remote check, download, timeout, parsing, and unsupported-mode failures return structured failure results without crashing the app.
- **SC-006**: A valid previous remote cache remains usable after a later remote failure, and local locale assets remain usable when no valid cache exists.
- **SC-007**: Protected app asset keys marked with `override: false` retain their app-provided values in 100% of merge cases.
- **SC-008**: No runtime remote pull modifies app locale asset files.
- **SC-009**: No secret values from remote connectors are stored in cache data, cache keys, or package-produced logs.
