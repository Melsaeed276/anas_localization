import 'remote_localization_payload.dart';
import 'remote_localization_version.dart';

class RemoteVersionSnapshot {
  const RemoteVersionSnapshot({
    required this.versions,
  });

  final Map<String, RemoteLocalizationVersion> versions;

  RemoteLocalizationVersion? versionFor(String locale) => versions[locale];

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RemoteVersionSnapshot && _mapEquals(versions, other.versions);

  @override
  int get hashCode => Object.hashAll(versions.entries);

  Map<String, Object?> toJson() => versions.map(
        (key, value) => MapEntry(key, value.toJson()),
      );

  factory RemoteVersionSnapshot.fromJson(Map<String, dynamic> json) {
    return RemoteVersionSnapshot(
      versions: json.map(
        (key, value) => MapEntry(
          key,
          RemoteLocalizationVersion.fromJson(
            value as Map<String, dynamic>,
          ),
        ),
      ),
    );
  }

  static bool _mapEquals(
    Map<String, RemoteLocalizationVersion> a,
    Map<String, RemoteLocalizationVersion> b,
  ) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

class RemoteLocalizationCacheSnapshot {
  const RemoteLocalizationCacheSnapshot({
    required this.payloads,
    this.lastReadAt,
    this.lastWriteAt,
    this.fallbackMode = 'persistent',
  });

  final Map<String, RemoteLocalizationPayload> payloads;
  final DateTime? lastReadAt;
  final DateTime? lastWriteAt;
  final String fallbackMode;

  RemoteLocalizationPayload? payloadFor(String locale) => payloads[locale];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteLocalizationCacheSnapshot &&
          _payloadMapEquals(payloads, other.payloads) &&
          lastReadAt == other.lastReadAt &&
          lastWriteAt == other.lastWriteAt &&
          fallbackMode == other.fallbackMode;

  @override
  int get hashCode => Object.hash(Object.hashAll(payloads.entries), lastReadAt, lastWriteAt, fallbackMode);

  Map<String, Object?> toJson() => {
        'payloads': payloads.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
        if (lastReadAt != null) 'lastReadAt': lastReadAt!.toIso8601String(),
        if (lastWriteAt != null) 'lastWriteAt': lastWriteAt!.toIso8601String(),
        'fallbackMode': fallbackMode,
      };

  factory RemoteLocalizationCacheSnapshot.fromJson(Map<String, dynamic> json) {
    return RemoteLocalizationCacheSnapshot(
      payloads: (json['payloads'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          RemoteLocalizationPayload.fromJson(
            value as Map<String, dynamic>,
          ),
        ),
      ),
      lastReadAt: json['lastReadAt'] != null ? DateTime.parse(json['lastReadAt'] as String) : null,
      lastWriteAt: json['lastWriteAt'] != null ? DateTime.parse(json['lastWriteAt'] as String) : null,
      fallbackMode: json['fallbackMode'] as String? ?? 'persistent',
    );
  }

  static bool _payloadMapEquals(
    Map<String, RemoteLocalizationPayload> a,
    Map<String, RemoteLocalizationPayload> b,
  ) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}
