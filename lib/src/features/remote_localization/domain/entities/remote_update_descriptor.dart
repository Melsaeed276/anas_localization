import 'package:anas_localization/src/core/localization_service.dart' show LocalizationService;
import 'remote_localization_version.dart';

class RemoteUpdateDescriptor {
  factory RemoteUpdateDescriptor.fromJson(Map<String, dynamic> json) {
    return RemoteUpdateDescriptor(
      locale: json['locale'] as String,
      version: RemoteLocalizationVersion.fromJson(
        json['version'] as Map<String, dynamic>,
      ),
      downloadHint: json['downloadHint'],
    );
  }
  const RemoteUpdateDescriptor({
    required this.locale,
    required this.version,
    this.downloadHint,
  });

  final String locale;
  final RemoteLocalizationVersion version;
  final Object? downloadHint;

  RemoteUpdateDescriptor normalize() {
    return RemoteUpdateDescriptor(
      locale: LocalizationService.normalizeLocaleCode(locale),
      version: version.normalize(),
      downloadHint: downloadHint,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RemoteUpdateDescriptor && locale == other.locale && version == other.version;

  @override
  int get hashCode => Object.hash(locale, version);

  Map<String, Object?> toJson() => {
        'locale': locale,
        'version': version.toJson(),
      };
}
