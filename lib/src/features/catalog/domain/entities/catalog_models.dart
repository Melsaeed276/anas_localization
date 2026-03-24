library;

import '../../../../shared/data_type.dart';

export '../../../../shared/data_type.dart' show DataType, dataTypeFromString, dataTypeToString, defaultDataType;

enum CatalogCellStatus {
  green,
  warning,
  red,
}

CatalogCellStatus catalogCellStatusFromString(String value) {
  switch (value.toLowerCase()) {
    case 'green':
      return CatalogCellStatus.green;
    case 'warning':
      return CatalogCellStatus.warning;
    case 'red':
      return CatalogCellStatus.red;
    default:
      return CatalogCellStatus.warning;
  }
}

String catalogCellStatusToString(CatalogCellStatus status) {
  switch (status) {
    case CatalogCellStatus.green:
      return 'green';
    case CatalogCellStatus.warning:
      return 'warning';
    case CatalogCellStatus.red:
      return 'red';
  }
}

class CatalogCellState {
  const CatalogCellState({
    required this.status,
    this.reason,
    this.lastReviewedSourceHash,
    this.lastReviewedAt,
    this.lastEditedAt,
  });

  final CatalogCellStatus status;
  final String? reason;
  final String? lastReviewedSourceHash;
  final DateTime? lastReviewedAt;
  final DateTime? lastEditedAt;

  CatalogCellState copyWith({
    CatalogCellStatus? status,
    String? reason,
    bool clearReason = false,
    String? lastReviewedSourceHash,
    bool clearLastReviewedSourceHash = false,
    DateTime? lastReviewedAt,
    bool clearLastReviewedAt = false,
    DateTime? lastEditedAt,
  }) {
    return CatalogCellState(
      status: status ?? this.status,
      reason: clearReason ? null : (reason ?? this.reason),
      lastReviewedSourceHash:
          clearLastReviewedSourceHash ? null : (lastReviewedSourceHash ?? this.lastReviewedSourceHash),
      lastReviewedAt: clearLastReviewedAt ? null : (lastReviewedAt ?? this.lastReviewedAt),
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': catalogCellStatusToString(status),
      if (reason != null) 'reason': reason,
      if (lastReviewedSourceHash != null) 'lastReviewedSourceHash': lastReviewedSourceHash,
      if (lastReviewedAt != null) 'lastReviewedAt': lastReviewedAt!.toIso8601String(),
      if (lastEditedAt != null) 'lastEditedAt': lastEditedAt!.toIso8601String(),
    };
  }

  static CatalogCellState fromJson(Map<String, dynamic> json) {
    return CatalogCellState(
      status: catalogCellStatusFromString(json['status']?.toString() ?? 'warning'),
      reason: json['reason']?.toString(),
      lastReviewedSourceHash: json['lastReviewedSourceHash']?.toString(),
      lastReviewedAt: _tryParseDateTime(json['lastReviewedAt']),
      lastEditedAt: _tryParseDateTime(json['lastEditedAt']),
    );
  }
}

class CatalogActivityKinds {
  static const String keyCreated = 'key_created';
  static const String sourceUpdated = 'source_updated';
  static const String targetUpdated = 'target_updated';
  static const String noteUpdated = 'note_updated';
  static const String localeReviewed = 'locale_reviewed';
  static const String valueDeleted = 'value_deleted';
}

class CatalogActivityEvent {
  const CatalogActivityEvent({
    required this.kind,
    required this.timestamp,
    this.locale,
  });

  final String kind;
  final DateTime timestamp;
  final String? locale;

  Map<String, dynamic> toJson() {
    return {
      'kind': kind,
      'timestamp': timestamp.toIso8601String(),
      if (locale != null) 'locale': locale,
    };
  }

  static CatalogActivityEvent fromJson(Map<String, dynamic> json) {
    return CatalogActivityEvent(
      kind: json['kind']?.toString() ?? CatalogActivityKinds.targetUpdated,
      timestamp: _tryParseDateTime(json['timestamp']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      locale: json['locale']?.toString(),
    );
  }
}

class CatalogReviewTarget {
  const CatalogReviewTarget({
    required this.keyPath,
    required this.locale,
  });

  final String keyPath;
  final String locale;

  Map<String, dynamic> toJson() {
    return {
      'keyPath': keyPath,
      'locale': locale,
    };
  }

  static CatalogReviewTarget fromJson(Map<String, dynamic> json) {
    return CatalogReviewTarget(
      keyPath: json['keyPath']?.toString() ?? '',
      locale: json['locale']?.toString() ?? '',
    );
  }
}

class CatalogBulkReviewResult {
  const CatalogBulkReviewResult({
    required this.reviewedCount,
  });

  final int reviewedCount;

  Map<String, dynamic> toJson() {
    return {
      'reviewedCount': reviewedCount,
    };
  }

  static CatalogBulkReviewResult fromJson(Map<String, dynamic> json) {
    return CatalogBulkReviewResult(
      reviewedCount: int.tryParse(json['reviewedCount']?.toString() ?? '') ?? 0,
    );
  }
}

class CatalogKeyState {
  CatalogKeyState({
    required this.sourceHash,
    required this.cells,
    List<CatalogActivityEvent>? activities,
    this.note,
    DataType? dataType,
  })  : activities = activities ?? <CatalogActivityEvent>[],
        dataType = dataType ?? defaultDataType;

  String sourceHash;
  final Map<String, CatalogCellState> cells;
  final List<CatalogActivityEvent> activities;
  String? note;

  /// Data type for this key; default string when absent.
  DataType dataType = defaultDataType;

  Map<String, dynamic> toJson() {
    return {
      'sourceHash': sourceHash,
      if (note != null) 'note': note,
      if (activities.isNotEmpty) 'activities': activities.map((item) => item.toJson()).toList(),
      'cells': {
        for (final entry in cells.entries) entry.key: entry.value.toJson(),
      },
      if (dataType != defaultDataType) 'dataType': dataTypeToString(dataType),
    };
  }

  static CatalogKeyState fromJson(Map<String, dynamic> json) {
    final rawCells = json['cells'];
    final parsedCells = <String, CatalogCellState>{};
    if (rawCells is Map) {
      for (final entry in rawCells.entries) {
        final value = entry.value;
        if (value is Map) {
          parsedCells[entry.key.toString()] = CatalogCellState.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      }
    }
    final activities = <CatalogActivityEvent>[];
    final rawActivities = json['activities'];
    if (rawActivities is List) {
      for (final item in rawActivities.whereType<Map>()) {
        activities.add(CatalogActivityEvent.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return CatalogKeyState(
      sourceHash: json['sourceHash']?.toString() ?? '',
      cells: parsedCells,
      activities: activities,
      note: json['note']?.toString(),
      dataType: dataTypeFromString(json['dataType']?.toString()),
    );
  }
}

class CatalogState {
  CatalogState({
    required this.version,
    required this.sourceLocale,
    required this.format,
    required this.keys,
    Map<String, String>? languageGroupFallbacks,
    Map<String, String>? customLocaleDirections,
  })  : languageGroupFallbacks = languageGroupFallbacks ?? <String, String>{},
        customLocaleDirections = customLocaleDirections ?? <String, String>{};

  final int version;
  String sourceLocale;
  String format;
  final Map<String, CatalogKeyState> keys;

  /// Maps a regional locale to its language group fallback.
  /// Example: {"ar_SA": "ar_EG", "ar_AE": "ar_EG"}
  /// When ar_SA is missing a translation, it falls back to ar_EG.
  final Map<String, String> languageGroupFallbacks;

  /// Maps custom locales to their text direction ("ltr" or "rtl").
  /// Example: {"custom_dialect": "rtl", "fr_CA": "ltr"}
  /// Only needed for locales not in the predefined kAvailableLocales list.
  final Map<String, String> customLocaleDirections;

  static CatalogState empty({
    required String sourceLocale,
    required String format,
  }) {
    return CatalogState(
      version: 3,
      sourceLocale: sourceLocale,
      format: format,
      keys: <String, CatalogKeyState>{},
      languageGroupFallbacks: <String, String>{},
      customLocaleDirections: <String, String>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'sourceLocale': sourceLocale,
      'format': format,
      if (languageGroupFallbacks.isNotEmpty) 'languageGroupFallbacks': languageGroupFallbacks,
      if (customLocaleDirections.isNotEmpty) 'customLocaleDirections': customLocaleDirections,
      'keys': {
        for (final entry in keys.entries) entry.key: entry.value.toJson(),
      },
    };
  }

  static CatalogState fromJson(Map<String, dynamic> json) {
    final rawKeys = json['keys'];
    final parsedKeys = <String, CatalogKeyState>{};
    if (rawKeys is Map) {
      for (final entry in rawKeys.entries) {
        final value = entry.value;
        if (value is Map) {
          parsedKeys[entry.key.toString()] = CatalogKeyState.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      }
    }

    // Parse languageGroupFallbacks with safe defaults
    final languageGroupFallbacks = <String, String>{};
    final rawFallbacks = json['languageGroupFallbacks'];
    if (rawFallbacks is Map) {
      for (final entry in rawFallbacks.entries) {
        languageGroupFallbacks[entry.key.toString()] = entry.value.toString();
      }
    }

    // Parse customLocaleDirections with safe defaults
    final customLocaleDirections = <String, String>{};
    final rawDirections = json['customLocaleDirections'];
    if (rawDirections is Map) {
      for (final entry in rawDirections.entries) {
        customLocaleDirections[entry.key.toString()] = entry.value.toString();
      }
    }

    return CatalogState(
      version: (() {
        final parsed = int.tryParse(json['version']?.toString() ?? '');
        if (parsed == null || parsed < 3) {
          return 3;
        }
        return parsed;
      })(),
      sourceLocale: json['sourceLocale']?.toString() ?? 'en',
      format: json['format']?.toString() ?? 'json',
      keys: parsedKeys,
      languageGroupFallbacks: languageGroupFallbacks,
      customLocaleDirections: customLocaleDirections,
    );
  }

  /// Creates a copy of this CatalogState with the specified fields replaced.
  CatalogState copyWith({
    int? version,
    String? sourceLocale,
    String? format,
    Map<String, CatalogKeyState>? keys,
    Map<String, String>? languageGroupFallbacks,
    Map<String, String>? customLocaleDirections,
  }) {
    return CatalogState(
      version: version ?? this.version,
      sourceLocale: sourceLocale ?? this.sourceLocale,
      format: format ?? this.format,
      keys: keys ?? this.keys,
      languageGroupFallbacks: languageGroupFallbacks ?? this.languageGroupFallbacks,
      customLocaleDirections: customLocaleDirections ?? this.customLocaleDirections,
    );
  }
}

class CatalogRow {
  const CatalogRow({
    required this.keyPath,
    required this.valuesByLocale,
    required this.cellStates,
    required this.rowStatus,
    required this.pendingLocales,
    required this.missingLocales,
    this.note,
    this.dataType = defaultDataType,
  });

  final String keyPath;
  final Map<String, dynamic> valuesByLocale;
  final Map<String, CatalogCellState> cellStates;
  final CatalogCellStatus rowStatus;
  final List<String> pendingLocales;
  final List<String> missingLocales;
  final String? note;

  /// Optional data type for this entry; default string when absent.
  final DataType dataType;

  Map<String, dynamic> toJson() {
    return {
      'keyPath': keyPath,
      'valuesByLocale': valuesByLocale,
      'cellStates': {
        for (final entry in cellStates.entries) entry.key: entry.value.toJson(),
      },
      'rowStatus': catalogCellStatusToString(rowStatus),
      'pendingLocales': pendingLocales,
      'missingLocales': missingLocales,
      if (note != null) 'note': note,
      if (dataType != defaultDataType) 'dataType': dataTypeToString(dataType),
    };
  }

  static CatalogRow fromJson(Map<String, dynamic> json) {
    final valuesByLocale = <String, dynamic>{};
    final rawValues = json['valuesByLocale'];
    if (rawValues is Map) {
      for (final entry in rawValues.entries) {
        valuesByLocale[entry.key.toString()] = entry.value;
      }
    }

    final cellStates = <String, CatalogCellState>{};
    final rawCellStates = json['cellStates'];
    if (rawCellStates is Map) {
      for (final entry in rawCellStates.entries) {
        final value = entry.value;
        if (value is Map) {
          cellStates[entry.key.toString()] = CatalogCellState.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      }
    }

    return CatalogRow(
      keyPath: json['keyPath']?.toString() ?? '',
      valuesByLocale: valuesByLocale,
      cellStates: cellStates,
      rowStatus: catalogCellStatusFromString(json['rowStatus']?.toString() ?? 'warning'),
      pendingLocales: _stringListFromJson(json['pendingLocales']),
      missingLocales: _stringListFromJson(json['missingLocales']),
      note: json['note']?.toString(),
      dataType: dataTypeFromString(json['dataType']?.toString()),
    );
  }

  CatalogRow copyWith({
    String? keyPath,
    Map<String, dynamic>? valuesByLocale,
    Map<String, CatalogCellState>? cellStates,
    CatalogCellStatus? rowStatus,
    List<String>? pendingLocales,
    List<String>? missingLocales,
    String? note,
    DataType? dataType,
  }) {
    return CatalogRow(
      keyPath: keyPath ?? this.keyPath,
      valuesByLocale: valuesByLocale ?? this.valuesByLocale,
      cellStates: cellStates ?? this.cellStates,
      rowStatus: rowStatus ?? this.rowStatus,
      pendingLocales: pendingLocales ?? this.pendingLocales,
      missingLocales: missingLocales ?? this.missingLocales,
      note: note ?? this.note,
      dataType: dataType ?? this.dataType,
    );
  }
}

class CatalogSummary {
  const CatalogSummary({
    required this.totalKeys,
    required this.greenCount,
    required this.warningCount,
    required this.redCount,
    required this.greenRows,
    required this.warningRows,
    required this.redRows,
  });

  final int totalKeys;
  final int greenCount;
  final int warningCount;
  final int redCount;
  final int greenRows;
  final int warningRows;
  final int redRows;

  Map<String, dynamic> toJson() {
    return {
      'totalKeys': totalKeys,
      'greenCount': greenCount,
      'warningCount': warningCount,
      'redCount': redCount,
      'greenRows': greenRows,
      'warningRows': warningRows,
      'redRows': redRows,
    };
  }

  static CatalogSummary fromJson(Map<String, dynamic> json) {
    return CatalogSummary(
      totalKeys: int.tryParse(json['totalKeys']?.toString() ?? '') ?? 0,
      greenCount: int.tryParse(json['greenCount']?.toString() ?? '') ?? 0,
      warningCount: int.tryParse(json['warningCount']?.toString() ?? '') ?? 0,
      redCount: int.tryParse(json['redCount']?.toString() ?? '') ?? 0,
      greenRows: int.tryParse(json['greenRows']?.toString() ?? '') ?? 0,
      warningRows: int.tryParse(json['warningRows']?.toString() ?? '') ?? 0,
      redRows: int.tryParse(json['redRows']?.toString() ?? '') ?? 0,
    );
  }

  CatalogSummary copyWith({
    int? totalKeys,
    int? greenCount,
    int? warningCount,
    int? redCount,
    int? greenRows,
    int? warningRows,
    int? redRows,
  }) {
    return CatalogSummary(
      totalKeys: totalKeys ?? this.totalKeys,
      greenCount: greenCount ?? this.greenCount,
      warningCount: warningCount ?? this.warningCount,
      redCount: redCount ?? this.redCount,
      greenRows: greenRows ?? this.greenRows,
      warningRows: warningRows ?? this.warningRows,
      redRows: redRows ?? this.redRows,
    );
  }
}

class CatalogMeta {
  const CatalogMeta({
    required this.locales,
    required this.localeDirections,
    required this.sourceLocale,
    required this.fallbackLocale,
    required this.langDirectory,
    required this.format,
    required this.stateFilePath,
    required this.uiPort,
    required this.apiPort,
  });

  final List<String> locales;
  final Map<String, String> localeDirections;
  final String sourceLocale;
  final String fallbackLocale;
  final String langDirectory;
  final String format;
  final String stateFilePath;
  final int uiPort;
  final int apiPort;

  Map<String, dynamic> toJson() {
    return {
      'locales': locales,
      'localeDirections': localeDirections,
      'sourceLocale': sourceLocale,
      'fallbackLocale': fallbackLocale,
      'langDirectory': langDirectory,
      'format': format,
      'stateFilePath': stateFilePath,
      'uiPort': uiPort,
      'apiPort': apiPort,
    };
  }

  static CatalogMeta fromJson(Map<String, dynamic> json) {
    final localeDirections = <String, String>{};
    final rawDirections = json['localeDirections'];
    if (rawDirections is Map) {
      for (final entry in rawDirections.entries) {
        localeDirections[entry.key.toString()] = entry.value?.toString() ?? 'ltr';
      }
    }

    return CatalogMeta(
      locales: _stringListFromJson(json['locales']),
      localeDirections: localeDirections,
      sourceLocale: json['sourceLocale']?.toString() ?? 'en',
      fallbackLocale: json['fallbackLocale']?.toString() ?? 'en',
      langDirectory: json['langDirectory']?.toString() ?? '',
      format: json['format']?.toString() ?? 'json',
      stateFilePath: json['stateFilePath']?.toString() ?? '',
      uiPort: int.tryParse(json['uiPort']?.toString() ?? '') ?? 0,
      apiPort: int.tryParse(json['apiPort']?.toString() ?? '') ?? 0,
    );
  }

  CatalogMeta copyWith({
    List<String>? locales,
    Map<String, String>? localeDirections,
    String? sourceLocale,
    String? fallbackLocale,
    String? langDirectory,
    String? format,
    String? stateFilePath,
    int? uiPort,
    int? apiPort,
  }) {
    return CatalogMeta(
      locales: locales ?? this.locales,
      localeDirections: localeDirections ?? this.localeDirections,
      sourceLocale: sourceLocale ?? this.sourceLocale,
      fallbackLocale: fallbackLocale ?? this.fallbackLocale,
      langDirectory: langDirectory ?? this.langDirectory,
      format: format ?? this.format,
      stateFilePath: stateFilePath ?? this.stateFilePath,
      uiPort: uiPort ?? this.uiPort,
      apiPort: apiPort ?? this.apiPort,
    );
  }
}

List<String> _stringListFromJson(dynamic value) {
  if (value is! List) {
    return const <String>[];
  }
  return value.map((item) => item.toString()).toList();
}

DateTime? _tryParseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  if (text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text);
}
