library;

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
  }) : activities = activities ?? <CatalogActivityEvent>[];

  String sourceHash;
  final Map<String, CatalogCellState> cells;
  final List<CatalogActivityEvent> activities;
  String? note;

  Map<String, dynamic> toJson() {
    return {
      'sourceHash': sourceHash,
      if (note != null) 'note': note,
      if (activities.isNotEmpty) 'activities': activities.map((item) => item.toJson()).toList(),
      'cells': {
        for (final entry in cells.entries) entry.key: entry.value.toJson(),
      },
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
    );
  }
}

class CatalogState {
  CatalogState({
    required this.version,
    required this.sourceLocale,
    required this.format,
    required this.keys,
  });

  final int version;
  String sourceLocale;
  String format;
  final Map<String, CatalogKeyState> keys;

  static CatalogState empty({
    required String sourceLocale,
    required String format,
  }) {
    return CatalogState(
      version: 3,
      sourceLocale: sourceLocale,
      format: format,
      keys: <String, CatalogKeyState>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'sourceLocale': sourceLocale,
      'format': format,
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
  });

  final String keyPath;
  final Map<String, dynamic> valuesByLocale;
  final Map<String, CatalogCellState> cellStates;
  final CatalogCellStatus rowStatus;
  final List<String> pendingLocales;
  final List<String> missingLocales;
  final String? note;

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
