# Contract: Remote Localization Runtime API

This contract describes the V1 public runtime API shape for optional remote localization pull support. Exact file names may change during implementation, but behavior and responsibilities should remain stable.

## Configuration Contract

```dart
final localization = AnasLocalizationConfig(
  // Existing local configuration remains unchanged.
  remote: RemoteLocalizationConfig(
    connector: MyRemoteLocalizationConnector(),
    checkOnStartup: false,
  ),
);
```

### `RemoteLocalizationConfig`

```dart
class RemoteLocalizationConfig {
  const RemoteLocalizationConfig({
    required this.connector,
    this.checkOnStartup = false,
    this.cacheStore,
    this.metrics,
  });

  final RemoteLocalizationConnector connector;
  final bool checkOnStartup;
  final RemoteLocalizationCacheStore? cacheStore;
  final RemoteLocalizationMetrics? metrics;
}
```

**Contract rules**:

- Omitting `remote` keeps existing localization behavior unchanged.
- `checkOnStartup` defaults to `false`.
- Startup checks must run after local translations are available.
- Runtime checks must not mutate app locale asset files.

## Connector Contract

```dart
abstract interface class RemoteLocalizationConnector {
  bool get supportsGlobalCheck;
  bool get supportsLocaleCheck;

  Future<RemoteCheckResponse> checkForUpdates(
    RemoteVersionSnapshot cachedVersions,
  );

  Future<RemoteCheckResponse> checkForLocaleUpdate(
    Locale locale,
    RemoteLocalizationVersion? cachedVersion,
  );

  Future<RemoteLocalizationPayload> downloadPayload(
    RemoteUpdateDescriptor update,
  );
}
```

**Contract rules**:

- Connector implementations own authentication, backend request construction, and backend response mapping.
- The package must not store connector credentials or include credentials in cache keys.
- Unsupported check modes return structured unsupported results.
- Downloaded payloads must be normalized to package-supported translation data.

## Manual Update Contract

```dart
final globalResult = await AnasLocalization.remote.checkForUpdates();
final localeResult = await AnasLocalization.remote.checkForLocaleUpdate(
  const Locale('en'),
);
```

### `RemoteLocalizationService`

```dart
abstract interface class RemoteLocalizationService {
  Future<RemoteLocalizationUpdateResult> checkForUpdates();

  Future<RemoteLocalizationUpdateResult> checkForLocaleUpdate(Locale locale);

  Future<RemoteLocalizationCacheSnapshot> readCache();
}
```

**Contract rules**:

- Global checks require a connector with `supportsGlobalCheck == true`.
- Locale checks require a connector with `supportsLocaleCheck == true`.
- Duplicate in-flight requests for the same global or locale scope return `skippedDuplicate`.
- Requests are processed sequentially to keep cache writes deterministic.
- Successful updates affecting the active locale reload the active dictionary and notify existing listeners.

## Result Contract

```dart
sealed class RemoteLocalizationUpdateResult {
  RemoteLocalizationUpdateResult({
    required this.scope,
    required this.status,
    required this.startedAt,
    required this.completedAt,
  });

  final RemoteLocalizationScope scope;
  final RemoteLocalizationUpdateStatus status;
  final DateTime startedAt;
  final DateTime completedAt;
}

enum RemoteLocalizationUpdateStatus {
  updated,
  noUpdate,
  skippedDuplicate,
  unsupported,
  failed,
}
```

**Contract rules**:

- `updated` includes applied locale payload summaries.
- `noUpdate` does not download payloads.
- `unsupported` does not call unsupported connector methods.
- `failed` includes sanitized failure details and preserves the last valid cache.

## Payload Contract

```dart
class RemoteLocalizationPayload {
  const RemoteLocalizationPayload({
    required this.locale,
    required this.version,
    required this.translations,
  });

  final Locale locale;
  final RemoteLocalizationVersion version;
  final Map<String, Object?> translations;
}

class RemoteLocalizationVersion {
  const RemoteLocalizationVersion({
    required this.updatedAtUtc,
    this.etag,
    this.hash,
  });

  final DateTime updatedAtUtc;
  final String? etag;
  final String? hash;
}
```

**Contract rules**:

- `updatedAtUtc` must be UTC.
- Remote payloads replace cache data only when their timestamp is strictly newer than the cached timestamp.
- Payload translation maps must support the same shapes as local JSON/YAML/CSV/ARB normalization.
- Invalid payloads return structured failures and do not replace the cache.

## Merge Contract

The final runtime dictionary for a locale is built with this precedence:

```text
package assets < app assets < remote cache
```

**Contract rules**:

- App asset entries marked with `override: false` cannot be replaced by remote cache values.
- Missing override metadata means `override: true`.
- Override metadata is stripped before values are exposed through dictionaries or rendered text.
- If no valid remote cache exists, localization falls back to the current local-only behavior.

## Observability Contract

```dart
abstract interface class RemoteLocalizationMetrics {
  void increment(RemoteLocalizationMetric metric, {Locale? locale});
}
```

**Required counters**:

- total checks
- downloads
- cache hits
- cache misses
- failures

**Required logs**:

- check start/end
- download start/end
- cache read/write
- errors

**Contract rules**:

- Logs and metrics must not include credentials, authorization headers, or raw backend secrets.
- Logs use the existing package logging service and respect release-mode logging behavior.
