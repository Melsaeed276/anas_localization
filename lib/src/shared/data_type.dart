/// Optional data type for a localization entry.
///
/// Used for validation, Catalog UI controls, and code generation.
/// Default when absent is [DataType.string].
library;

enum DataType {
  string,
  numerical,
  gender,
  date,
  dateTime,
}

/// Default data type when none is specified (per spec FR-002).
const DataType defaultDataType = DataType.string;

/// Parses a string to [DataType]; returns [defaultDataType] for null/empty/unknown.
DataType dataTypeFromString(String? value) {
  if (value == null || value.trim().isEmpty) {
    return defaultDataType;
  }
  final normalized = value.trim().toLowerCase();
  return switch (normalized) {
    'string' => DataType.string,
    'numerical' => DataType.numerical,
    'gender' => DataType.gender,
    'date' => DataType.date,
    'datetime' => DataType.dateTime,
    _ => defaultDataType,
  };
}

/// Serializes [DataType] for storage (e.g. in @dataTypes map).
String dataTypeToString(DataType type) {
  return switch (type) {
    DataType.string => 'string',
    DataType.numerical => 'numerical',
    DataType.gender => 'gender',
    DataType.date => 'date',
    DataType.dateTime => 'dateTime',
  };
}
