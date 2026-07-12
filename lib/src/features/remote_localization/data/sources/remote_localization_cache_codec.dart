import 'dart:convert';

import '../../domain/entities/remote_localization_cache_snapshot.dart';
import '../../domain/entities/remote_localization_failure.dart';
import '../../domain/entities/remote_localization_payload.dart';
import '../../domain/entities/remote_localization_version.dart';
import '../../domain/entities/remote_update_descriptor.dart';

class RemoteLocalizationCacheCodec {
  const RemoteLocalizationCacheCodec();

  String encodeCacheSnapshot(RemoteLocalizationCacheSnapshot snapshot) {
    return jsonEncode(snapshot.toJson());
  }

  RemoteLocalizationCacheSnapshot? decodeCacheSnapshot(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return RemoteLocalizationCacheSnapshot.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  String encodePayload(RemoteLocalizationPayload payload) {
    return jsonEncode(payload.toJson());
  }

  RemoteLocalizationPayload? decodePayload(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return RemoteLocalizationPayload.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  String encodeVersion(RemoteLocalizationVersion version) {
    return jsonEncode(version.toJson());
  }

  RemoteLocalizationVersion? decodeVersion(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return RemoteLocalizationVersion.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  String encodeUpdateDescriptor(RemoteUpdateDescriptor descriptor) {
    return jsonEncode(descriptor.toJson());
  }

  RemoteUpdateDescriptor? decodeUpdateDescriptor(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return RemoteUpdateDescriptor.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  String encodeFailure(RemoteLocalizationFailure failure) {
    return jsonEncode(failure.toJson());
  }

  RemoteLocalizationFailure? decodeFailure(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return RemoteLocalizationFailure.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
