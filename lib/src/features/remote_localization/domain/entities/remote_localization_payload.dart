import 'package:anas_localization/src/core/localization_service.dart' show LocalizationService;
import 'remote_localization_version.dart';

class RemoteLocalizationPayload {
  factory RemoteLocalizationPayload.fromJson(Map<String, dynamic> json) {
    return RemoteLocalizationPayload(
      locale: json['locale'] as String,
      version: RemoteLocalizationVersion.fromJson(
        json['version'] as Map<String, dynamic>,
      ),
      translations: (json['translations'] as Map<String, dynamic>).cast<String, Object?>(),
    );
  }
  RemoteLocalizationPayload({
    required this.locale,
    required this.version,
    required this.translations,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();

  final String locale;
  final RemoteLocalizationVersion version;
  final Map<String, Object?> translations;
  final DateTime receivedAt;

  RemoteLocalizationPayload normalize() {
    return RemoteLocalizationPayload(
      locale: LocalizationService.normalizeLocaleCode(locale),
      version: version.normalize(),
      translations: _normalizeTranslations(translations),
    );
  }

  Map<String, Object?> _normalizeTranslations(Map<String, Object?> input) {
    final result = <String, Object?>{};
    for (final entry in input.entries) {
      final key = entry.key.trim();
      result[key] = entry.value is Map<String, Object?>
          ? _normalizeTranslations(entry.value as Map<String, Object?>)
          : entry.value;
    }
    return result;
  }

  bool get isValid => locale.isNotEmpty && translations.isNotEmpty;

  bool isNewerThan(RemoteLocalizationPayload other) => version.isNewerThan(other.version);

  bool isStaleComparedTo(RemoteLocalizationPayload other) =>
      !version.isNewerThan(other.version) && !(version == other.version);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteLocalizationPayload &&
          locale == other.locale &&
          version == other.version &&
          _mapEquals(translations, other.translations);

  @override
  int get hashCode => Object.hash(locale, version);

  Map<String, Object?> toJson() => {
        'locale': locale,
        'version': version.toJson(),
        'translations': translations,
      };

  static bool _mapEquals(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      final aVal = a[key];
      final bVal = b[key];
      if (aVal is Map<String, Object?> && bVal is Map<String, Object?>) {
        if (!_mapEquals(aVal, bVal)) return false;
      } else if (aVal != bVal) {
        return false;
      }
    }
    return true;
  }
}
