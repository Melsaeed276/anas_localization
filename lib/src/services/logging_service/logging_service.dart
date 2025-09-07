/// Centralized logging service for the localization package
library;

/// Log levels for different types of messages
enum LogLevel {
  /// Debug information for development
  debug,
  /// General information messages
  info,
  /// Warning messages for potential issues
  warning,
  /// Error messages for actual problems
  error,
  /// Success messages for completed operations
  success,
}

/// Centralized logging service to handle all print statements in the package
/// This allows easy migration to proper logging frameworks later
class AnasLoggingService {
  /// Private constructor for singleton pattern
  AnasLoggingService._();

  /// Singleton instance
  static final AnasLoggingService _instance = AnasLoggingService._();

  /// Get the singleton instance
  static AnasLoggingService get instance => _instance;

  /// Whether logging is enabled (can be controlled for production)
  static bool _isEnabled = true;

  /// Enable or disable logging
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Check if logging is enabled
  static bool get isEnabled => _isEnabled;

  /// Log a debug message
  void debug(String message, [String? context]) {
    _log(LogLevel.debug, message, context);
  }

  /// Log an info message
  void info(String message, [String? context]) {
    _log(LogLevel.info, message, context);
  }

  /// Log a warning message
  void warning(String message, [String? context]) {
    _log(LogLevel.warning, message, context);
  }

  /// Log an error message
  void error(String message, [String? context, Object? error]) {
    final errorMessage = error != null ? '$message: $error' : message;
    _log(LogLevel.error, errorMessage, context);
  }

  /// Log a success message
  void success(String message, [String? context]) {
    _log(LogLevel.success, message, context);
  }

  /// Internal logging method
  void _log(LogLevel level, String message, String? context) {
    if (!_isEnabled) return;

    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? '[$context] ' : '';
    final levelStr = _getLevelString(level);

    // For now, use print - can be easily replaced with logging framework later
    // ignore: avoid_print
    print('$timestamp $levelStr $contextStr$message');
  }

  /// Get string representation of log level with emojis for better visibility
  String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍 DEBUG:';
      case LogLevel.info:
        return 'ℹ️  INFO: ';
      case LogLevel.warning:
        return '⚠️  WARN: ';
      case LogLevel.error:
        return '❌ ERROR:';
      case LogLevel.success:
        return '✅ SUCCESS:';
    }
  }
}

/// Global logging instance for easy access throughout the package
final logger = AnasLoggingService.instance;

/// Extension methods for common logging patterns
extension AnasLoggingExtensions on AnasLoggingService {
  /// Log locale loading operations
  void localeLoaded(String locale) {
    info('Locale loaded successfully', 'LocalizationService');
  }

  /// Log locale loading failures
  void localeLoadFailed(String locale, Object error) {
    this.error('Failed to load locale: $locale', 'LocalizationService', error);
  }

  /// Log dictionary creation
  void dictionaryCreated(String locale) {
    debug('Dictionary created for locale: $locale', 'LocalizationService');
  }

  /// Log language change operations
  void languageChanged(String from, String to) {
    info('Language changed from $from to $to', 'LanguageSetup');
  }

  /// Log listener management
  void listenerAdded() {
    debug('Locale listener added', 'LocalizationManager');
  }

  /// Log listener management
  void listenerRemoved() {
    debug('Locale listener removed', 'LocalizationManager');
  }

  /// Log validation results
  void validationResult(bool success, String message) {
    if (success) {
      this.success(message, 'Validation');
    } else {
      warning(message, 'Validation');
    }
  }

  /// Log CLI operations
  void cliOperation(String operation, String result) {
    info('$operation: $result', 'CLI');
  }
}
