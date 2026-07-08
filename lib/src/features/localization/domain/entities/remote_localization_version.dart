import 'package:flutter/material.dart';

class RemoteLocalizationVersion {
  const RemoteLocalizationVersion({
    required this.updatedAtUtc,
    this.etag,
    this.hash,
  });

  final DateTime updatedAtUtc;
  final String? etag;
  final String? hash;

  RemoteLocalizationVersion normalize() {
    final utc = updatedAtUtc.isUtc
        ? updatedAtUtc
        : DateTime.utc(
            updatedAtUtc.year,
            updatedAtUtc.month,
            updatedAtUtc.day,
            updatedAtUtc.hour,
            updatedAtUtc.minute,
            updatedAtUtc.second,
            updatedAtUtc.millisecond,
            updatedAtUtc.microsecond,
          );
    return RemoteLocalizationVersion(
      updatedAtUtc: utc,
      etag: etag,
      hash: hash,
    );
  }

  bool isNewerThan(RemoteLocalizationVersion other) {
    return updatedAtUtc.isAfter(other.updatedAtUtc);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteLocalizationVersion &&
          updatedAtUtc == other.updatedAtUtc &&
          etag == other.etag &&
          hash == other.hash;

  @override
  int get hashCode => Object.hash(updatedAtUtc, etag, hash);

  Map<String, Object?> toJson() => {
        'updatedAtUtc': updatedAtUtc.toIso8601String(),
        if (etag != null) 'etag': etag,
        if (hash != null) 'hash': hash,
      };

  factory RemoteLocalizationVersion.fromJson(Map<String, dynamic> json) {
    return RemoteLocalizationVersion(
      updatedAtUtc: DateTime.parse(json['updatedAtUtc'] as String).toUtc(),
      etag: json['etag'] as String?,
      hash: json['hash'] as String?,
    );
  }
}
