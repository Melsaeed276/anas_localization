/// Date and time formatting utilities for localization
library;

import 'package:intl/intl.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui' show Locale;

/// Provides localized date and time formatting utilities
class AnasDateTimeFormatter {
  const AnasDateTimeFormatter(this.locale);

  final Locale locale;

  /// Format date with localized patterns
  String formatDate(DateTime date, {DateFormat? customFormat}) {
    if (customFormat != null) {
      return customFormat.format(date);
    }
    return DateFormat.yMMMd(locale.toString()).format(date);
  }

  /// Format time with localized patterns
  String formatTime(DateTime time) {
    return DateFormat.jm(locale.toString()).format(time);
  }

  /// Format date and time together
  String formatDateTime(DateTime dateTime) {
    return DateFormat.yMMMd(locale.toString()).add_jm().format(dateTime);
  }

  /// Format relative time (e.g., "2 hours ago", "yesterday")
  String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Format currency with locale-specific patterns
  String formatCurrency(double amount, {String? currencySymbol}) {
    final symbol = currencySymbol ?? '\$';
    final formatter = NumberFormat.currency(
      locale: locale.toString(),
      symbol: symbol,
    );
    return formatter.format(amount);
  }

  /// Format numbers with locale-specific patterns
  String formatNumber(num number) {
    return NumberFormat('#,##0', locale.toString()).format(number);
  }
}

/// Extension to add date/time formatting to Dictionary
extension DateTimeFormattingExtension on DateTime {
  /// Format this DateTime using the current locale
  String format({String? pattern}) {
    // This would need access to current locale from AnasLocalization
    return DateFormat(pattern ?? 'yMMMd').format(this);
  }
}
