# Research: Remote Localization V1

## Decision: Keep Remote Localization Runtime-Only And Opt-In

**Rationale**: The feature spec requires existing apps to behave exactly as before unless remote localization is explicitly configured. Keeping V1 in the runtime loading path avoids coupling it to CLI push, Catalog sync, local asset mutation, or history workflows.

**Alternatives considered**:

- Add CLI remote push/pull in V1: rejected because FR-022 explicitly excludes it.
- Make remote checks part of every startup: rejected because startup checking must be opt-in and disabled by default.

## Decision: Place Implementation Under `features/localization`

**Rationale**: Remote payloads affect runtime locale loading, fallback, dictionary creation, and listener notification. The existing clean-architecture feature area already owns these responsibilities through `LocalizationService`, domain services, contracts, and repositories.

**Alternatives considered**:

- Add implementation to `lib/src/core`: rejected because the constitution requires core barrel files to avoid implementation logic.
- Create a separate top-level remote feature: rejected because remote data is not independent from localization loading or merge semantics.

## Decision: Use A Consumer-Provided Remote Connector Contract

**Rationale**: Package consumers own backend authentication, endpoints, headers, and response formats. A connector lets the package define normalized check/download results while keeping credentials and backend-specific details out of package storage and logs.

**Alternatives considered**:

- Built-in HTTP endpoint configuration: rejected because it would force one backend shape and increase secret-handling risk.
- Reuse `HttpTranslationLoader` directly as the public remote API: rejected because it only downloads by URL and does not model check/no-update, version comparison, per-locale support, or structured failures.

## Decision: Represent Remote Updates With Structured Result Entities

**Rationale**: Manual checks must return success/failure details without crashing callers. Existing code uses purpose-specific result objects rather than a shared `Either` type, so V1 should follow that pattern with remote-specific result classes.

**Alternatives considered**:

- Throw exceptions for public check/update failures: rejected because FR-010 requires structured success or failure results.
- Add a global generic result type: rejected as unnecessary API surface for one feature.

## Decision: Use File-Based Cache With In-Memory Fallback

**Rationale**: The spec resolves cache storage as persistent file-based storage with in-memory fallback. This preserves the last valid payload across app launches where file IO works, while keeping runtime usable when cache reads or writes fail.

**Alternatives considered**:

- `shared_preferences`: rejected for potentially large nested locale payloads and because the spec asks for file-based storage.
- Memory-only cache: rejected because valid remote payloads should survive restarts.
- Write remote data into local locale assets: rejected by FR-013 and SC-008.

## Decision: Version Comparison Uses Strictly Newer UTC Timestamps

**Rationale**: The spec states that remote timestamps are UTC and remote data is newer only when its timestamp is strictly newer than cached data. Optional equality identifiers such as ETag or hash can be retained for diagnostics and equality checks, but they do not replace timestamp ordering.

**Alternatives considered**:

- Accept equal timestamps when ETag differs: rejected because the spec defines strictly newer timestamps as the update condition.
- Trust connector-reported update availability without local version validation: rejected because cache preservation requires deterministic handling of older or equal payloads.

## Decision: Merge Precedence Is `package assets < app assets < remote cache`

**Rationale**: Existing runtime merging already applies app assets over package assets. V1 adds remote cache above unprotected local values while preserving protected app keys marked `override: false`.

**Alternatives considered**:

- Remote always wins: rejected because FR-015 protects local app keys.
- App always wins over remote: rejected because FR-014 requires remote cache to win for unprotected keys.

## Decision: Strip Override Metadata Before Dictionary Exposure

**Rationale**: `override: false` is local merge metadata, not a translation. The final rendered dictionary must not expose metadata keys or metadata wrapper objects as user-facing text.

**Alternatives considered**:

- Preserve metadata in dictionaries for debugging: rejected because FR-017 requires removal before rendering or exposure.
- Put protected keys in a separate config file only: rejected because the spec says markers may exist in local asset metadata.

## Decision: Queue Remote Operations Sequentially And Skip Duplicate In-Flight Scopes

**Rationale**: The resolved concurrency rule is sequential processing with duplicate in-flight requests skipped for the same locale or global scope. This keeps cache writes deterministic and avoids repeated downloads for the same request.

**Alternatives considered**:

- Fully parallel per-locale downloads: rejected for V1 because it complicates cache consistency and conflicts with the sequential queue requirement.
- Cancel previous requests: rejected because callers need structured outcomes and predictable application of already-started operations.

## Decision: Apply 10-Second Timeout, One Retry, And 2-Second Backoff Around Remote Operations

**Rationale**: FR-019 fixes the timeout and retry behavior. The coordinator should apply this policy consistently around connector check and download calls, preserving the last valid cache when all attempts fail.

**Alternatives considered**:

- Exponential retries: rejected because the spec requires exactly one retry.
- Connector-defined retry policy only: rejected because consumers need package-level consistency.

## Decision: Use Existing Logger And Add Minimal Counter Metrics Interface

**Rationale**: The constitution requires `AnasLoggingService` and sensitive-data-safe logs. FR-023 also requires counters, but the codebase has no runtime metrics emitter, so a minimal remote metrics interface should emit check, download, cache hit/miss, and failure counters without introducing a third-party dependency.

**Alternatives considered**:

- Add a third-party analytics dependency: rejected as unnecessary and inconsistent with package scope.
- Log counters as text only: rejected because the requirement distinguishes logs and counter metrics.

## Decision: Reuse Existing Translation Parsers For Payload Normalization

**Rationale**: Remote payloads must support the same shape accepted by local assets, including nested values, plural/select patterns, and data type metadata. Reusing existing parsing/normalization avoids divergent behavior between local and remote translations.

**Alternatives considered**:

- Define a remote-only JSON shape: rejected because it would fragment supported translation formats.
- Accept raw connector maps without validation: rejected because corrupt remote payloads must not replace the last valid cache.
