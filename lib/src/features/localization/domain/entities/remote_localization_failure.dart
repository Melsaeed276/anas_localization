enum RemoteLocalizationFailureCode {
  unsupportedMode,
  checkFailed,
  downloadFailed,
  timeout,
  parseFailed,
  cacheReadFailed,
  cacheWriteFailed,
  stalePayload,
  unknown,
}

class RemoteLocalizationFailure {
  const RemoteLocalizationFailure({
    required this.code,
    required this.message,
    this.locale,
    this.retryAttempted = false,
    this.recoverable = true,
  });

  final RemoteLocalizationFailureCode code;
  final String message;
  final String? locale;
  final bool retryAttempted;
  final bool recoverable;

  static const _sanitizedMessage = 'An error occurred';

  RemoteLocalizationFailure sanitize() {
    return RemoteLocalizationFailure(
      code: code,
      message: _sanitizedMessage,
      locale: locale,
      retryAttempted: retryAttempted,
      recoverable: recoverable,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteLocalizationFailure &&
          code == other.code &&
          message == other.message &&
          locale == other.locale &&
          retryAttempted == other.retryAttempted &&
          recoverable == other.recoverable;

  @override
  int get hashCode => Object.hash(code, message, locale, retryAttempted, recoverable);

  Map<String, Object?> toJson() => {
        'code': code.name,
        'message': message,
        if (locale != null) 'locale': locale,
        'retryAttempted': retryAttempted,
        'recoverable': recoverable,
      };

  factory RemoteLocalizationFailure.fromJson(Map<String, dynamic> json) {
    return RemoteLocalizationFailure(
      code: RemoteLocalizationFailureCode.values.firstWhere(
        (e) => e.name == json['code'],
        orElse: () => RemoteLocalizationFailureCode.unknown,
      ),
      message: json['message'] as String? ?? _sanitizedMessage,
      locale: json['locale'] as String?,
      retryAttempted: json['retryAttempted'] as bool? ?? false,
      recoverable: json['recoverable'] as bool? ?? true,
    );
  }
}
