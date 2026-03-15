/// Per-type validation rules for localization entry values.
library;

import 'data_type.dart';
import 'numerical_type_helper.dart';

/// Result of validating a value against a [DataType].
class DataTypeValidationResult {
  const DataTypeValidationResult({required this.valid, this.ruleId, this.message});

  final bool valid;
  final String? ruleId;
  final String? message;
}

/// Validates a string value against [type]. Returns [DataTypeValidationResult].
DataTypeValidationResult validateValueForDataType(DataType type, String value) {
  final trimmed = value.trim();
  switch (type) {
    case DataType.string:
      return const DataTypeValidationResult(valid: true);
    case DataType.numerical:
      final parsed = tryParseNumerical(trimmed);
      if (parsed == null && trimmed.isNotEmpty) {
        return const DataTypeValidationResult(
          valid: false,
          ruleId: 'numerical',
          message: 'Value must be a number (integer or decimal).',
        );
      }
      return const DataTypeValidationResult(valid: true);
    case DataType.gender:
      final lower = trimmed.toLowerCase();
      if (lower != 'male' && lower != 'female') {
        return const DataTypeValidationResult(
          valid: false,
          ruleId: 'gender',
          message: 'Value must be exactly "male" or "female".',
        );
      }
      return const DataTypeValidationResult(valid: true);
    case DataType.date:
      // ISO 8601 date (YYYY-MM-DD)
      if (trimmed.isEmpty) {
        return const DataTypeValidationResult(valid: true);
      }
      final dateMatch = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed);
      if (!dateMatch) {
        return const DataTypeValidationResult(
          valid: false,
          ruleId: 'date',
          message: 'Date must be ISO 8601 format (YYYY-MM-DD).',
        );
      }
      final d = DateTime.tryParse(trimmed);
      if (d == null) {
        return const DataTypeValidationResult(
          valid: false,
          ruleId: 'date',
          message: 'Invalid date.',
        );
      }
      return const DataTypeValidationResult(valid: true);
    case DataType.dateTime:
      if (trimmed.isEmpty) {
        return const DataTypeValidationResult(valid: true);
      }
      final dt = DateTime.tryParse(trimmed);
      if (dt == null) {
        return const DataTypeValidationResult(
          valid: false,
          ruleId: 'dateTime',
          message: 'Date-time must be valid ISO 8601 date-time.',
        );
      }
      return const DataTypeValidationResult(valid: true);
  }
}
