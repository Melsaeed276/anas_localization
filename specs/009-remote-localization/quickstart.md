# Quickstart: Remote Localization V1

This quickstart describes how package consumers should use Remote Localization V1 after implementation.

## 1. Keep Existing Local-Only Behavior

Do nothing if the app does not need remote localization.

```dart
await AnasLocalization.initialize(
  fallbackLocale: const Locale('en'),
  supportedLocales: const [Locale('en'), Locale('ar')],
);
```

Expected behavior:

- Local package/app assets load exactly as before.
- No remote check runs during startup.
- No remote cache is read unless remote localization is configured.

## 2. Add A Remote Connector

Implement a connector that maps your backend into normalized package results.

```dart
class MyRemoteLocalizationConnector implements RemoteLocalizationConnector {
  @override
  bool get supportsGlobalCheck => true;

  @override
  bool get supportsLocaleCheck => true;

  @override
  Future<RemoteCheckResponse> checkForUpdates(
    RemoteVersionSnapshot cachedVersions,
  ) async {
    // Call your backend and return update descriptors for changed locales.
  }

  @override
  Future<RemoteCheckResponse> checkForLocaleUpdate(
    Locale locale,
    RemoteLocalizationVersion? cachedVersion,
  ) async {
    // Call your backend for one locale.
  }

  @override
  Future<RemoteLocalizationPayload> downloadPayload(
    RemoteUpdateDescriptor update,
  ) async {
    // Download and normalize one locale payload.
  }
}
```

Connector responsibilities:

- Own backend URLs, authentication, request headers, and response mapping.
- Return sanitized failures when backend operations fail.
- Never place credentials in payload data, version data, or cache identifiers.

## 3. Configure Remote Localization

```dart
await AnasLocalization.initialize(
  fallbackLocale: const Locale('en'),
  supportedLocales: const [Locale('en'), Locale('ar')],
  remote: RemoteLocalizationConfig(
    connector: MyRemoteLocalizationConnector(),
    checkOnStartup: false,
  ),
);
```

Expected behavior:

- Local translations render first.
- Remote startup work is skipped because `checkOnStartup` is `false`.
- Any valid existing remote cache may be merged after local app assets.

## 4. Trigger A Manual Global Check

```dart
final result = await AnasLocalization.remote.checkForUpdates();

switch (result.status) {
  case RemoteLocalizationUpdateStatus.updated:
    // One or more locale payloads were downloaded, cached, and applied.
    break;
  case RemoteLocalizationUpdateStatus.noUpdate:
    // Backend reported no newer translation data.
    break;
  case RemoteLocalizationUpdateStatus.failed:
    // Last valid cache remains available; inspect sanitized failure details.
    break;
  default:
    break;
}
```

Expected behavior:

- No download occurs when the connector reports no update.
- Changed locale payloads are downloaded and cached when updates exist.
- Active-locale updates reload the active dictionary and notify listeners.

## 5. Trigger A Manual Per-Locale Check

```dart
final result = await AnasLocalization.remote.checkForLocaleUpdate(
  const Locale('en'),
);
```

Expected behavior:

- Only the requested locale is checked and downloaded.
- If the connector does not support per-locale checks, the result is `unsupported`.
- Duplicate in-flight checks for `en` are skipped with a structured result.

## 6. Protect Local App Keys From Remote Override

Mark app-owned entries that must not be replaced by remote data.

```json
{
  "checkoutTitle": {
    "value": "Checkout",
    "override": false
  },
  "promoBanner": "Summer sale"
}
```

Expected behavior:

- Remote payloads cannot replace `checkoutTitle`.
- Remote payloads can replace `promoBanner`.
- `override` metadata is removed before dictionary values are rendered.

## 7. Verify The Implementation

Run focused tests during development:

```bash
flutter test test/features/localization/remote_translation_merge_policy_test.dart
flutter test test/features/localization/remote_localization_coordinator_test.dart
flutter test test/features/localization/remote_localization_integration_test.dart
flutter test test/contract/remote_localization_api_contract_test.dart
```

Run full package gates before merging:

```bash
dart format --set-exit-if-changed .
flutter analyze --no-fatal-infos
flutter test --coverage
flutter pub publish --dry-run
```

## Expected Failure Behavior

- Timeout, connector failure, download failure, parse failure, and stale payloads return structured failure results.
- The last valid cached remote payload remains available after later failures.
- If no valid remote cache exists, localization falls back to local assets.
- Package logs and metrics do not expose backend secrets.
