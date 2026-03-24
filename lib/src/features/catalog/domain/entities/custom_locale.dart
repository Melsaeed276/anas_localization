library;

import 'package:flutter/material.dart';

/// Represents a user-defined locale not in the predefined list.
class CustomLocale {
  const CustomLocale({
    required this.code,
    required this.direction,
    required this.displayName,
    required this.languageName,
    this.countryName,
  });

  /// Normalized locale code (e.g., "fr_CA").
  final String code;

  /// Text direction: "ltr" or "rtl".
  final String direction;

  /// Full display name (e.g., "French (Canada)").
  final String displayName;

  /// Language name component (e.g., "French").
  final String languageName;

  /// Country name component (e.g., "Canada"). Null for language-only locales.
  final String? countryName;

  /// Whether this is an RTL locale.
  bool get isRtl => direction == 'rtl';

  /// TextDirection for Flutter widgets.
  TextDirection get textDirection => isRtl ? TextDirection.rtl : TextDirection.ltr;

  @override
  String toString() =>
      'CustomLocale(code: $code, direction: $direction, displayName: $displayName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomLocale &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          direction == other.direction &&
          displayName == other.displayName &&
          languageName == other.languageName &&
          countryName == other.countryName;

  @override
  int get hashCode =>
      code.hashCode ^
      direction.hashCode ^
      displayName.hashCode ^
      languageName.hashCode ^
      countryName.hashCode;
}
