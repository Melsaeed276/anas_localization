/// Currency and number formatting utilities for localization
library;

import 'package:intl/intl.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui' show Locale;

/// Provides localized number and currency formatting
class AnasNumberFormatter {
  const AnasNumberFormatter(this.locale);

  final Locale locale;

  /// Format currency with locale-specific patterns
  String formatCurrency(double amount, {
    String? currencyCode,
    String? currencySymbol,
    int? decimalDigits,
  }) {
    final formatter = NumberFormat.currency(
      locale: locale.toString(),
      symbol: currencySymbol,
      name: currencyCode,
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  /// Format percentage with locale-specific patterns
  String formatPercentage(double value) {
    final formatter = NumberFormat.percentPattern(locale.toString());
    return formatter.format(value);
  }

  /// Format decimal numbers
  String formatDecimal(double number, {int? decimalDigits}) {
    final formatter = NumberFormat.decimalPattern(locale.toString());
    if (decimalDigits != null) {
      formatter.minimumFractionDigits = decimalDigits;
      formatter.maximumFractionDigits = decimalDigits;
    }
    return formatter.format(number);
  }

  /// Format compact numbers (e.g., 1K, 1M)
  String formatCompact(num number) {
    final formatter = NumberFormat.compact(locale: locale.toString());
    return formatter.format(number);
  }

  /// Format file sizes (bytes, KB, MB, GB)
  String formatFileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${formatDecimal(size, decimalDigits: unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
  }
}

/// Extension to add number formatting to BuildContext
extension NumberFormattingExtension on BuildContext {
  /// Get number formatter for current locale
  AnasNumberFormatter get numberFormatter {
    final locale = Localizations.localeOf(this);
    return AnasNumberFormatter(locale);
  }
}
