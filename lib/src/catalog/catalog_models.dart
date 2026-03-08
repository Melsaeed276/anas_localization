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

  static DateTime? _tryParseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text);
  }
}

class CatalogKeyState {
  CatalogKeyState({
    required this.sourceHash,
    required this.cells,
  });

  String sourceHash;
  final Map<String, CatalogCellState> cells;

  Map<String, dynamic> toJson() {
    return {
      'sourceHash': sourceHash,
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
    return CatalogKeyState(
      sourceHash: json['sourceHash']?.toString() ?? '',
      cells: parsedCells,
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
      version: 1,
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
      version: int.tryParse(json['version']?.toString() ?? '') ?? 1,
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
  });

  final String keyPath;
  final Map<String, dynamic> valuesByLocale;
  final Map<String, CatalogCellState> cellStates;

  Map<String, dynamic> toJson() {
    return {
      'keyPath': keyPath,
      'valuesByLocale': valuesByLocale,
      'cellStates': {
        for (final entry in cellStates.entries) entry.key: entry.value.toJson(),
      },
    };
  }
}

class CatalogSummary {
  const CatalogSummary({
    required this.totalKeys,
    required this.greenCount,
    required this.warningCount,
    required this.redCount,
  });

  final int totalKeys;
  final int greenCount;
  final int warningCount;
  final int redCount;

  Map<String, dynamic> toJson() {
    return {
      'totalKeys': totalKeys,
      'greenCount': greenCount,
      'warningCount': warningCount,
      'redCount': redCount,
    };
  }
}

class CatalogMeta {
  const CatalogMeta({
    required this.locales,
    required this.sourceLocale,
    required this.fallbackLocale,
    required this.langDirectory,
    required this.format,
    required this.stateFilePath,
    required this.uiPort,
    required this.apiPort,
  });

  final List<String> locales;
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
      'sourceLocale': sourceLocale,
      'fallbackLocale': fallbackLocale,
      'langDirectory': langDirectory,
      'format': format,
      'stateFilePath': stateFilePath,
      'uiPort': uiPort,
      'apiPort': apiPort,
    };
  }
}
