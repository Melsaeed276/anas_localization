/// Shared numerical type parsing and formatting for data type validation and Catalog.
library;

import 'package:intl/intl.dart';

/// Tries to parse a string as a number (int or decimal). Returns null if invalid.
num? tryParseNumerical(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return num.tryParse(trimmed);
}

/// Formats a number for display using optional locale (e.g. for Catalog).
String formatNumerical(num value, {String? locale}) {
  if (locale != null && locale.isNotEmpty) {
    try {
      return NumberFormat.decimalPattern(locale).format(value);
    } catch (_) {
      // fallback to default
    }
  }
  return NumberFormat.decimalPattern().format(value);
}
