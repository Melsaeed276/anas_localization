# Data Model: Remote Localization V1

## Remote Localization Configuration

Consumer-provided settings that enable remote localization and control when remote work runs.

**Fields**:

- `enabled`: `bool`; derived from whether a configuration is provided.
- `checkOnStartup`: `bool`; default `false`.
- `connector`: `RemoteLocalizationConnector`; required when enabled.
- `cacheStore`: `RemoteLocalizationCacheStore?`; optional override for persistent cache implementation.
- `timeout`: `Duration`; default `10 seconds`.
- `retryCount`: `int`; fixed default `1`.
- `retryBackoff`: `Duration`; default `2 seconds`.
- `metrics`: `RemoteLocalizationMetrics?`; optional metrics sink.

**Validation rules**:

- Missing configuration means remote localization is disabled.
- Enabled configuration must include a connector.
- Startup checks must not block initial local dictionary loading.
- Timeout/retry values must match V1 defaults unless a later spec expands configurability.

**Relationships**:

- Owns one remote connector.
- Owns or resolves one cache store.
- May own one metrics sink.

## Remote Connector

Consumer-owned bridge between the package and a backend.

**Fields / capabilities**:

- `supportsGlobalCheck`: `bool`.
- `supportsLocaleCheck`: `bool`.
- `checkForUpdates(cachedVersions)`: returns a global check result.
- `checkForLocaleUpdate(locale, cachedVersion)`: returns a per-locale check result.
- `downloadPayload(locale, versionHint)`: returns one normalized locale payload.

**Validation rules**:

- Unsupported global/per-locale calls must return structured failure results without attempting remote work.
- Connector output must not expose credentials to package logs, cache keys, or cache payloads.
- Returned payload locale must match the requested locale for per-locale updates.

**Relationships**:

- Produces `Remote Check Result`.
- Produces `Remote Localization Payload`.
- May use `HttpClientAdapter` internally, but owns all backend-specific details.

## Remote Check Result

Outcome of asking whether remote data changed.

**Fields**:

- `scope`: `global | locale`.
- `locale`: `String?`; required for locale scope.
- `status`: `updated | noUpdate | skippedDuplicate | unsupported | failed`.
- `updates`: `List<RemoteUpdateDescriptor>`; empty for no update.
- `failure`: `Remote Localization Failure?`.
- `startedAt`: `DateTime`.
- `completedAt`: `DateTime`.

**Validation rules**:

- `updated` requires at least one update descriptor.
- `noUpdate`, `skippedDuplicate`, and `unsupported` must not trigger downloads.
- `failed` must include a sanitized failure.
- Locale-scope results must include exactly one requested locale.

**Relationships**:

- References zero or more remote update descriptors.
- May lead to one or more payload downloads.

## Remote Update Descriptor

Normalized signal that a locale payload should be downloaded.

**Fields**:

- `locale`: `String`.
- `version`: `Remote Localization Version`.
- `downloadHint`: `Object?`; optional opaque connector-owned hint.

**Validation rules**:

- Locale must be normalized before cache lookup or write.
- Version timestamp must be strictly newer than the cached version before replacing cache data.
- Download hints must not be persisted unless explicitly safe and sanitized.

## Remote Localization Payload

Validated remote translation data for one locale.

**Fields**:

- `locale`: `String`.
- `version`: `Remote Localization Version`.
- `translations`: `Map<String, Object?>`.
- `receivedAt`: `DateTime`.

**Validation rules**:

- Payload locale must be non-empty and normalized.
- `translations` must parse to the same normalized shape accepted by local locale assets.
- Payload must be rejected if parsing, normalization, or validation fails.
- Payloads older than or equal to cached versions must not replace cache data.
- Payloads should be less than 1 MB per locale under V1 assumptions.

**Relationships**:

- Stored in `Remote Localization Cache`.
- Merged into runtime dictionaries after package/app assets for unprotected keys.

## Remote Localization Version

Version metadata used for update decisions.

**Fields**:

- `updatedAtUtc`: `DateTime`.
- `etag`: `String?`.
- `hash`: `String?`.

**Validation rules**:

- `updatedAtUtc` must be interpreted as UTC.
- A remote version is newer only when `remote.updatedAtUtc` is strictly after `cached.updatedAtUtc`.
- `etag` and `hash` may support equality/diagnostics but do not override timestamp ordering.

## Remote Localization Cache

Persistent storage for the last valid remote payloads and versions.

**Fields**:

- `payloadsByLocale`: `Map<String, Remote Localization Payload>`.
- `lastReadAt`: `DateTime?`.
- `lastWriteAt`: `DateTime?`.
- `fallbackMode`: `persistent | memory`.

**Validation rules**:

- Cache reads that fail must fall back to in-memory data or an empty cache without crashing localization.
- Cache writes that fail must preserve existing last valid payloads and may prune oldest entries before retrying a write.
- Runtime cache data must never be written back to app locale asset files.
- Cache keys must not include credentials, authorization headers, or backend secrets.

**Relationships**:

- Read by the localization merge path.
- Written by successful remote update operations.
- Emits cache hit, miss, read, write, and failure events.

## Protected Local Key

App asset translation entry that prevents remote override.

**Fields**:

- `key`: `String`.
- `value`: `Object?`.
- `override`: `bool`; defaults to `true` when metadata is missing.

**Validation rules**:

- `override: false` means remote data cannot replace this key.
- Missing override metadata is treated as `override: true`.
- Override metadata must be stripped before dictionary values are rendered or exposed.
- Metadata markers must not appear as raw translation keys.

**Relationships**:

- Read from app asset metadata during merge.
- Applied by the remote translation merge policy.

## Remote Localization Failure

Sanitized failure details for structured results and logs.

**Fields**:

- `code`: `unsupportedMode | checkFailed | downloadFailed | timeout | parseFailed | cacheReadFailed | cacheWriteFailed | stalePayload | unknown`.
- `message`: `String`.
- `locale`: `String?`.
- `retryAttempted`: `bool`.
- `recoverable`: `bool`.

**Validation rules**:

- Message must not include credentials, tokens, authorization headers, or raw backend secret material.
- Failures must preserve the last valid cache.
- Public failures should not expose raw stack traces.

## State Transitions

### Remote Operation

```text
idle
  -> queued
  -> checking
  -> noUpdate
  -> completed
```

```text
idle
  -> queued
  -> checking
  -> updateAvailable
  -> downloading
  -> validating
  -> caching
  -> applied
  -> completed
```

```text
idle
  -> queued
  -> checking/downloading/validating/caching
  -> failed
  -> completed
```

### Duplicate Scope Handling

```text
requested
  -> inFlightScopeExists
  -> skippedDuplicate
```

### Active Locale Refresh

```text
remotePayloadCached
  -> activeLocaleAffected
  -> reloadActiveLocale
  -> notifyLocalizationListeners
```
