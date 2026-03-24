/// Notification emitted when a fallback cascade delete occurs.
///
/// **Issue #131**: FR-011 Enhancement - Notify affected locales
///
/// When a locale is deleted and it was referenced as a fallback target,
/// the system automatically removes those references (Issue #127) AND
/// notifies the user about which locales were affected (Issue #131).
class FallbackCascadeNotification {
  /// The locale that was deleted
  final String deletedLocale;

  /// All locales that had a fallback reference to the deleted locale
  final List<String> affectedSourceLocales;

  /// When the cascade delete occurred
  final DateTime timestamp;

  FallbackCascadeNotification({
    required this.deletedLocale,
    required this.affectedSourceLocales,
    required this.timestamp,
  });

  /// User-friendly message describing the cascade delete
  String get message {
    if (affectedSourceLocales.isEmpty) {
      return 'Locale "$deletedLocale" deleted.';
    }

    final localeList = affectedSourceLocales.join(', ');
    return 'Fallback configuration cleared for: $localeList '
        '(target locale "$deletedLocale" was deleted)';
  }

  @override
  String toString() => 'FallbackCascadeNotification(deleted: $deletedLocale, affected: $affectedSourceLocales)';
}
