# Remote Localization Flow Diagrams

## 1. App Startup Flow

```mermaid
flowchart TD
    A["App Starts"] --> B["AnasLocalization widget created"]
    B --> C{"remoteConfig provided?"}
    C -->|No| D["Remote localization DISABLED"]
    C -->|Yes| E["_init()"]
    D --> E

    E --> F["LocalizationService.configure(remote: remoteConfig)"]
    E --> G["_loadSavedLocaleOrDefault()"]

    G --> H["loadLocale(localeCode)"]
    H --> I["_loadMergedJsonFor(localeCode)"]

    I --> J["Load package assets"]
    I --> K["Load app assets"]
    I --> L{"remoteConfig != null?"}
    L -->|No| M["remoteData = null"]
    L -->|Yes| N["cacheStore.snapshot()"]
    N --> O{"Disk read OK?"}
    O -->|Yes| P["Decode JSON -> return snapshot"]
    O -->|No| Q["Use in-memory fallback or null"]
    P --> M
    Q --> M

    J --> R["RemoteTranslationMergePolicy.merge()"]
    K --> R
    M --> R
    R --> S["Build Dictionary from merged map"]

    S --> T["Set _currentDictionary, _currentLocale"]
    T --> U["_notifyLocaleLoaded() -> widget rebuilds"]
    T --> V{"checkOnStartup == true?"}
    V -->|No| W["STOP - no remote work"]
    V -->|Yes| X["_triggerStartupRemoteCheck()\n(Non-blocking Future)"]

    X --> Y["connector.checkForUpdates(emptySnapshot)"]
    Y -->|SUCCESS| Z["applyRemoteUpdates()\nreloadActiveLocale -> widget rebuilds"]
    Y -->|FAILURE| AA["Log error, swallow\napp continues with local translations"]
```

---

## 2. Manual Global Update Flow

```mermaid
flowchart TD
    A["Caller: AnasLocalization.remote.checkForUpdates()"] --> B["RemoteLocalizationCoordinator"]
    B --> C{"__global__ scope\nalready in-flight?"}
    C -->|Yes| D["Return SkippedDuplicate"]
    C -->|No| E["Add __global__ to _inFlight set"]
    E --> F["_executeWithTimeoutAndRetry\n(timeout: 10s)"]
    F --> G["Run operation"]
    G -->|OK| H["Return result"]
    G -->|FAIL| I["Retry after 2s backoff"]
    I -->|OK| H
    I -->|FAIL| J["throw RemoteLocalizationFailure\n(timeout)"]
    H --> K["Remove __global__ from _inFlight"]

    K --> L["RemoteLocalizationRepositoryImpl\n.checkForUpdates()"]
    L --> M{"connector\n.supportsGlobalCheck?"}
    M -->|No| N["Return Unsupported"]
    M -->|Yes| O["Read cache snapshot\nBuild RemoteVersionSnapshot"]
    O --> P["connector.checkForUpdates(cachedVersions)"]
    P -->|No descriptors| Q["Return NoUpdate"]
    P -->|Descriptors returned| R["For each descriptor:"]
    R --> S{"Version > cached?"}
    S -->|No| T["Skip"]
    S -->|Yes| U["connector.downloadPayload(descriptor)"]
    U -->|FAIL| V["Log, continue next"]
    U -->|OK| W["Validate payload\n(locale match, shape, normalization)"]
    W -->|Invalid| X["Reject, continue next"]
    W -->|Valid| Y["cacheStore.write(payload)"]
    Y -->|OK| Z["updated locales++"]
    Y -->|FAIL| AA["Log, continue next"]
    Z --> R
    V --> R
    X --> R
    T --> R

    R --> AB["Return UpdateSuccess\n(appliedLocales: [...])"]
    AB --> AC{"Locales were\nupdated?"}
    AC -->|Yes| AD["_applyToLiveDictionary()\nLocalizationService.applyRemoteUpdates()\nreloadCurrentLocale\n_notifyLocaleLoaded()\nwidget rebuilds with new translations"]
    AC -->|No| AE["Return result to caller"]
```

---

## 3. Manual Per-Locale Update Flow

```mermaid
flowchart TD
    A["Caller:\nAnasLocalization.remote\n.checkForLocaleUpdate(locale)"] --> B["RemoteLocalizationCoordinator"]
    B --> C{"locale:<code>\nalready in-flight?"}
    C -->|Yes| D["Return SkippedDuplicate"]
    C -->|No| E["Add locale:<code> to _inFlight"]
    E --> F["_executeWithTimeoutAndRetry\n(timeout: 10s)"]
    F --> G["Run operation"]
    G -->|OK| H["Remove from _inFlight"]
    G -->|FAIL| I["Retry after 2s -> fail"]
    H --> J["RemoteLocalizationRepositoryImpl\n.checkForLocaleUpdate(locale)"]
    J --> K{"connector\n.supportsLocaleCheck?"}
    K -->|No| L["Return Unsupported"]
    K -->|Yes| M["Read cached version for locale"]
    M --> N["connector.checkForLocaleUpdate\n(locale, cachedVersion)"]
    N -->|No update| O["Return NoUpdate"]
    N -->|Update available| P["connector.downloadPayload(descriptor)"]
    P -->|FAIL| Q["Return Failed"]
    P -->|OK| R["Validate payload"]
    R -->|Invalid| S["Return Failed"]
    R -->|Valid| T["cacheStore.write(payload)"]
    T -->|OK| U["Return UpdateSuccess"]
    T -->|FAIL| V["Return Failed"]
    U --> W{"Updated?"}
    W -->|Yes| X["_applyToLiveDictionary()\n-> widget rebuilds"]
    W -->|No| Y["Return result to caller"]
```

---

## 4. Translation Merge Flow

```mermaid
flowchart TD
    A["_loadMergedJsonFor(localeCode)"] --> B["1. Load Package Assets\nassets/lang/<code>.json"]
    A --> C["2. Load App Assets\n<appAssetPath>/<code>.json"]
    A --> D["3. Load Remote Cache\ncacheStore.snapshot()\n.payloadFor(code)?.translations"]
    D --> E{"Remote data exists?"}
    E -->|No| F["remoteData = {}"]
    E -->|Yes| G["remoteData = cached translations"]

    B --> H["RemoteTranslationMergePolicy.merge()"]
    C --> H
    F --> H
    G --> H

    H --> I["Step A: result = packageData"]
    I --> J["Step B: Overlay appData"]
    J --> K{"Key has\n__override__: false?"}
    K -->|Yes| L["Mark key as PROTECTED\nresult[key] = appData[key]"]
    K -->|No| M["result[key] = appData[key]\n(overrideable)"]
    L --> N["Step C: Strip metadata wrappers\nunwrap {value, __override__: false}\nkeep only value"]
    M --> N
    N --> O["Step D: Overlay remoteData"]
    O --> P{"Key is PROTECTED?"}
    P -->|Yes| Q["SKIP - keep app value"]
    P -->|No| R["result[key] = remoteData[key]"]
    Q --> S["Return merged map"]
    R --> S
    S --> T["Build Dictionary\n(type-safe getters)"]
```

---

## 5. Cache Read Flow

```mermaid
flowchart TD
    A["cacheStore.snapshot()"] --> B["Read remote_cache.json from disk\n<cacheDir>/anas_localization/\nremote_cache/remote_cache.json"]
    B --> C{"IO successful?"}
    C -->|No| D["return _memoryFallback\nor null"]
    C -->|Yes| E["RemoteLocalizationCacheCodec\ndecode(json)"]
    E --> F{"Parse OK?"}
    F -->|No| D
    F -->|Yes| G["Update _memoryFallback"]
    G --> H["Return decoded snapshot"]
    H --> I["Snapshot fields:\npayloadsByLocale\nlastReadAt\nlastWriteAt\nfallbackMode: persistent | memory"]
```

## 6. Cache Write Flow

```mermaid
flowchart TD
    A["cacheStore.write(payload)"] --> B["Read existing cache from disk\n(or empty map)"]
    B --> C["Create new payloadsByLocale map"]
    C --> D["Add/overwrite entry:\npayloadsByLocale[payload.locale] = payload"]
    D --> E["Build RemoteLocalizationCacheSnapshot\nwith lastWriteAt: DateTime.now()"]
    E --> F["CacheCodec.encode(snapshot) -> JSON"]
    F --> G["Write JSON to remote_cache.json"]
    G -->|SUCCESS| H["Update _memoryFallback = snapshot\nReturn OK"]
    G -->|FAIL| I["Preserve existing _memoryFallback\n(never delete valid cache)\nReturn FAIL (logged, not thrown)"]
```

---

## 7. Error Boundary Layers

```mermaid
flowchart TD
    A["Remote operation initiated"] --> B["Layer 5: Dictionary Reload\ncatches in _applyToLiveDictionary\naction: log, app continues"]
    A --> C["Layer 4: Startup Check\ncatches via .catchError\naction: log and swallow\nnever blocks init"]
    A --> D["Layer 3: Cache Store\ncatches all IO errors\naction: fall back to memory or null"]
    A --> E["Layer 2: Repository\ncatches per-locale download fail\naction: skip locale, continue\ncatches top-level failure"]
    A --> F["Layer 1: Coordinator\ncatches RemoteLocalizationFailure + generic\nwraps in RemoteLocalizationFailed\nlogs: YES, rethrows: NO"]

    F --> G["Fallback Hierarchy"]
    E --> G
    D --> G
    C --> G
    B --> G

    G --> H["1. Live dictionary (last loaded)\nstill served to UI"]
    G --> I["2. In-memory cache fallback\nused if disk read fails"]
    G --> J["3. App locale assets\nused if no cache exists"]
    G --> K["4. Package locale assets\nused if app assets missing"]
    G --> L["5. Fallback locale\nused if exact locale missing"]

    H --> M["App continues rendering\nwith best available translations\nNEVER crashes from remote failures"]
    I --> M
    J --> M
    K --> M
    L --> M
```

---

## 8. Concurrency & Queue Flow

```mermaid
sequenceDiagram
    participant Caller
    participant Coordinator
    participant InFlight as _inFlight Set
    participant Repo as Repository

    Caller->>Coordinator: checkForUpdates() [__global__]
    Coordinator->>InFlight: Add __global__
    Coordinator->>Repo: Run operation

    Caller->>Coordinator: checkForUpdates() [__global__]
    Coordinator->>InFlight: __global__ exists?
    InFlight-->>Coordinator: YES
    Coordinator-->>Caller: SkippedDuplicate

    Caller->>Coordinator: checkForLocaleUpdate(ar) [locale:ar]
    Coordinator->>InFlight: locale:ar exists?
    InFlight-->>Coordinator: NO
    Coordinator->>InFlight: Add locale:ar
    Note over Coordinator,Repo: Different scopes run in parallel

    Repo-->>Coordinator: Operation complete
    Coordinator->>InFlight: Remove __global__
    Note over InFlight: Next __global__ request can now run
```

---

## 9. Version Comparison Flow

```mermaid
flowchart TD
    A["Remote payload received"] --> B{"cachedVersion\n== null?"}
    B -->|Yes| C["Treat as NEWER\n(first download)"]
    B -->|No| D["Compare updatedAtUtc\n(UTC timestamps)"]
    D --> E{"remote > cached?"}
    E -->|Yes| F["NEWER - replace cache"]
    E -->|No| G{"remote == cached?"}
    G -->|Yes| H["NOT NEWER - skip"]
    G -->|No| I{"remote < cached?"}
    I -->|Yes| J["STALE - skip"]
    I -->|No| K["etag/hash:\ninformational only\ndo not override timestamp ordering"]
```

---

## Summary: Key Class Responsibilities

| Class | Role in Flow |
|-------|-------------|
| `AnasLocalization` | Entry point. Accepts `remoteConfig`, triggers startup check, exposes `remote` static getter. |
| `RemoteLocalizationConfig` | Holds connector, startup flag, cache store, metrics, timeout/retry constants. |
| `RemoteLocalizationCoordinator` | Orchestrator. Queue/dedup, timeout+retry, lifecycle logging, triggers dictionary reload. |
| `RemoteLocalizationRepositoryImpl` | Business logic. Check-then-download, version validation, cache writes, structured results. |
| `RemoteTranslationMergePolicy` | Merge engine. `package < app < remote` precedence, protected key handling. |
| `RemoteLocalizationFileCacheStore` | Persistent JSON file cache with in-memory fallback via `path_provider`. |
| `RemoteLocalizationCacheCodec` | JSON encode/decode for all remote entities. Returns null on parse failure. |
| `RemoteLocalizationConnector` | Consumer-implemented. Owns backend URLs, auth, request/response mapping. |
| `LocalizationService` | Central singleton. Loads locales, merges remote cache, reloads active locale. |
| `RemoteLocalizationPayload` | Normalized locale data: locale code + version + translations map. |
| `RemoteLocalizationVersion` | UTC timestamp + optional etag/hash. `isNewerThan()` comparison. |
| `RemoteLocalizationUpdateResult` | Sealed outcome: `Success`, `NoUpdate`, `SkippedDuplicate`, `Unsupported`, `Failed`. |
| `RemoteLocalizationFailure` | Sanitized failure with typed code, message, locale, retry status. |
| `RemoteLocalizationMetrics` | Counters: `check`, `download`, `cacheHit`, `cacheMiss`, `failure`. |
