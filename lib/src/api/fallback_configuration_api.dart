/// REST API Adapter for Anas Localization Fallback Configuration
///
/// This file demonstrates how to expose the fallback configuration system
/// via HTTP endpoints for remote management. This is useful for:
/// - Mobile apps with remote configuration
/// - Backend admin dashboards
/// - CI/CD pipeline integrations
/// - Cloud-based localization management

import 'package:anas_localization/anas_localization.dart';
import '../features/catalog/use_cases/catalog_service.dart';

/// REST API response wrapper for consistent responses
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.error,
    this.timestamp,
  });

  final bool success;
  final int statusCode;
  final T? data;
  final String? error;
  final DateTime? timestamp;

  Map<String, dynamic> toJson() => {
        'success': success,
        'statusCode': statusCode,
        if (data != null)
          'data': data is CatalogStateDto
              ? (data as CatalogStateDto).toJson()
              : data is Map
                  ? data
                  : data.toString(),
        if (error != null) 'error': error,
        'timestamp': timestamp?.toIso8601String(),
      };
}

/// Fallback configuration DTO for API requests/responses
class FallbackConfigDto {
  const FallbackConfigDto({
    required this.locale,
    required this.fallbackLocale,
    this.languageGroup,
  });

  factory FallbackConfigDto.fromJson(Map<String, dynamic> json) {
    return FallbackConfigDto(
      locale: json['locale'] as String,
      fallbackLocale: json['fallbackLocale'] as String?,
      languageGroup: json['languageGroup'] as String?,
    );
  }

  final String locale;
  final String? fallbackLocale; // null means remove fallback
  final String? languageGroup;

  Map<String, dynamic> toJson() => {
        'locale': locale,
        if (fallbackLocale != null) 'fallbackLocale': fallbackLocale,
        if (languageGroup != null) 'languageGroup': languageGroup,
      };
}

/// Catalog state DTO for API serialization
class CatalogStateDto {
  const CatalogStateDto({
    required this.sourceLocale,
    required this.format,
    required this.languageGroupFallbacks,
    required this.customLocaleDirections,
    required this.totalLocales,
    required this.totalKeys,
  });

  factory CatalogStateDto.fromJson(Map<String, dynamic> json) {
    return CatalogStateDto(
      sourceLocale: json['sourceLocale'] as String,
      format: json['format'] as String,
      languageGroupFallbacks: Map<String, String>.from(json['languageGroupFallbacks'] as Map? ?? {}),
      customLocaleDirections: Map<String, String>.from(json['customLocaleDirections'] as Map? ?? {}),
      totalLocales: json['totalLocales'] as int? ?? 0,
      totalKeys: json['totalKeys'] as int? ?? 0,
    );
  }

  final String sourceLocale;
  final String format;
  final Map<String, String> languageGroupFallbacks;
  final Map<String, String> customLocaleDirections;
  final int totalLocales;
  final int totalKeys;

  Map<String, dynamic> toJson() => {
        'sourceLocale': sourceLocale,
        'format': format,
        'languageGroupFallbacks': languageGroupFallbacks,
        'customLocaleDirections': customLocaleDirections,
        'totalLocales': totalLocales,
        'totalKeys': totalKeys,
      };
}

/// Locale validation result DTO
class LocaleValidationResultDto {
  const LocaleValidationResultDto({
    required this.isValid,
    required this.locale,
    this.displayName,
    this.errorMessage,
  });

  final bool isValid;
  final String locale;
  final String? displayName;
  final String? errorMessage;

  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        'locale': locale,
        if (displayName != null) 'displayName': displayName,
        if (errorMessage != null) 'errorMessage': errorMessage,
      };
}

/// REST API Controller for fallback configuration management
class FallbackConfigurationApi {
  FallbackConfigurationApi({
    required this.catalogService,
    this.onCheckAuth,
  });

  final CatalogService catalogService;
  final Future<bool> Function()? onCheckAuth;

  /// Check authentication (can be overridden via [onCheckAuth] callback)
  Future<bool> _checkAuth() async {
    if (onCheckAuth != null) {
      return await onCheckAuth!();
    }
    // Default: allow all (override in production)
    return true;
  }

  /// GET /api/v1/fallbacks
  /// Get the complete catalog state with all fallback configurations
  ///
  /// Response: 200 OK
  /// ```json
  /// {
  ///   "success": true,
  ///   "statusCode": 200,
  ///   "data": {
  ///     "sourceLocale": "en",
  ///     "format": "arb",
  ///     "languageGroupFallbacks": {
  ///       "es_AR": "es_MX",
  ///       "es_MX": "es",
  ///       "ar_SA": "ar_EG",
  ///       "ar_AE": "ar_EG"
  ///     },
  ///     "customLocaleDirections": {},
  ///     "totalLocales": 45,
  ///     "totalKeys": 1250
  ///   },
  ///   "timestamp": "2024-03-24T22:25:00.000Z"
  /// }
  /// ```
  Future<ApiResponse<CatalogStateDto>> getCatalogState() async {
    try {
      if (!await _checkAuth()) {
        return ApiResponse<CatalogStateDto>(
          success: false,
          statusCode: 401,
          error: 'Unauthorized',
          timestamp: DateTime.now(),
        );
      }

      // Load current catalog metadata and fallback configuration
      final meta = await catalogService.loadMeta();
      final summary = await catalogService.loadSummary();
      final fallbacks = await catalogService.getLanguageGroupFallbacks();

      final dto = CatalogStateDto(
        sourceLocale: meta.sourceLocale,
        format: meta.format,
        languageGroupFallbacks: fallbacks,
        customLocaleDirections: meta.localeDirections,
        totalLocales: meta.locales.length,
        totalKeys: summary.totalKeys,
      );

      return ApiResponse<CatalogStateDto>(
        success: true,
        statusCode: 200,
        data: dto,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return ApiResponse<CatalogStateDto>(
        success: false,
        statusCode: 500,
        error: 'Error loading catalog state: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  /// GET /api/v1/fallbacks/{locale}
  /// Get the fallback chain for a specific locale
  ///
  /// Parameters:
  ///   - locale: The locale code (e.g., "es_AR", "ar_SA")
  ///
  /// Response: 200 OK
  /// ```json
  /// {
  ///   "success": true,
  ///   "statusCode": 200,
  ///   "data": {
  ///     "locale": "es_AR",
  ///     "chain": ["es_AR", "es_MX", "es", "en"],
  ///     "fallbacks": {
  ///       "es_AR": "es_MX",
  ///       "es_MX": "es"
  ///     }
  ///   },
  ///   "timestamp": "2024-03-24T22:25:00.000Z"
  /// }
  /// ```
  Future<ApiResponse<Map<String, dynamic>>> getFallbackChain(String locale) async {
    try {
      if (!await _checkAuth()) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          statusCode: 401,
          error: 'Unauthorized',
          timestamp: DateTime.now(),
        );
      }

      // Validate locale code
      const validationService = LocaleValidationService();
      final validation = validationService.validateLocaleCode(locale);

      if (!validation.isValid) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          statusCode: 400,
          error: 'Invalid locale code: ${validation.errorMessage}',
          timestamp: DateTime.now(),
        );
      }

      // Get the fallback chain
      final chain = await catalogService.getFallbackChain(locale);
      final fallbacks = await catalogService.getLanguageGroupFallbacks();

      return ApiResponse<Map<String, dynamic>>(
        success: true,
        statusCode: 200,
        data: {
          'locale': locale,
          'chain': chain.chain,
          'fallbacks': fallbacks,
        },
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        statusCode: 500,
        error: 'Error resolving fallback chain: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  /// POST /api/v1/fallbacks
  /// Set or update a fallback configuration
  ///
  /// Request body:
  /// ```json
  /// {
  ///   "locale": "es_AR",
  ///   "fallbackLocale": "es_MX",
  ///   "languageGroup": "es"
  /// }
  /// ```
  ///
  /// Response: 200 OK
  /// ```json
  /// {
  ///   "success": true,
  ///   "statusCode": 200,
  ///   "data": {
  ///     "locale": "es_AR",
  ///     "fallbackLocale": "es_MX",
  ///     "languageGroup": "es"
  ///   },
  ///   "timestamp": "2024-03-24T22:25:00.000Z"
  /// }
  /// ```
  Future<ApiResponse<FallbackConfigDto>> setFallback(
    FallbackConfigDto config,
  ) async {
    try {
      if (!await _checkAuth()) {
        return ApiResponse<FallbackConfigDto>(
          success: false,
          statusCode: 401,
          error: 'Unauthorized',
          timestamp: DateTime.now(),
        );
      }

      // Validate both locale codes
      const validationService = LocaleValidationService();
      final localeValidation = validationService.validateLocaleCode(config.locale);

      if (!localeValidation.isValid) {
        return ApiResponse<FallbackConfigDto>(
          success: false,
          statusCode: 400,
          error: 'Invalid locale code: ${localeValidation.errorMessage}',
          timestamp: DateTime.now(),
        );
      }

      if (config.fallbackLocale != null) {
        final fallbackValidation = validationService.validateLocaleCode(config.fallbackLocale!);
        if (!fallbackValidation.isValid) {
          return ApiResponse<FallbackConfigDto>(
            success: false,
            statusCode: 400,
            error: 'Invalid fallback locale: ${fallbackValidation.errorMessage}',
            timestamp: DateTime.now(),
          );
        }
      }

      // Get all valid locales for existence check
      final meta = await catalogService.loadMeta();
      final allLocales = meta.locales;

      // Set the fallback
      if (config.fallbackLocale != null) {
        await catalogService.setLanguageGroupFallback(
          locale: config.locale,
          newFallback: config.fallbackLocale!,
          validLocales: allLocales,
        );
      } else {
        // Remove fallback if fallbackLocale is null
        await catalogService.removeLanguageGroupFallback(config.locale);
      }

      return ApiResponse<FallbackConfigDto>(
        success: true,
        statusCode: 200,
        data: config,
        timestamp: DateTime.now(),
      );
    } on CatalogOperationException catch (e) {
      return ApiResponse<FallbackConfigDto>(
        success: false,
        statusCode: 409,
        error: 'Conflict: ${e.message}',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return ApiResponse<FallbackConfigDto>(
        success: false,
        statusCode: 500,
        error: 'Error setting fallback: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  /// DELETE /api/v1/fallbacks/{locale}
  /// Remove fallback configuration for a locale
  ///
  /// Response: 204 No Content
  Future<ApiResponse<void>> removeFallback(String locale) async {
    try {
      if (!await _checkAuth()) {
        return ApiResponse<void>(
          success: false,
          statusCode: 401,
          error: 'Unauthorized',
          timestamp: DateTime.now(),
        );
      }

      // Validate locale code
      const validationService = LocaleValidationService();
      final validation = validationService.validateLocaleCode(locale);

      if (!validation.isValid) {
        return ApiResponse<void>(
          success: false,
          statusCode: 400,
          error: 'Invalid locale code: ${validation.errorMessage}',
          timestamp: DateTime.now(),
        );
      }

      // Remove the fallback
      await catalogService.removeLanguageGroupFallback(locale);

      return ApiResponse<void>(
        success: true,
        statusCode: 204,
        timestamp: DateTime.now(),
      );
    } on CatalogOperationException catch (e) {
      return ApiResponse<void>(
        success: false,
        statusCode: 400,
        error: 'Bad Request: ${e.message}',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        statusCode: 500,
        error: 'Error removing fallback: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  /// GET /api/v1/fallbacks/validate/{locale}
  /// Validate a locale code
  ///
  /// Parameters:
  ///   - locale: The locale code to validate
  ///
  /// Response: 200 OK
  /// ```json
  /// {
  ///   "success": true,
  ///   "statusCode": 200,
  ///   "data": {
  ///     "isValid": true,
  ///     "locale": "es_AR",
  ///     "displayName": "Spanish (Argentina)"
  ///   },
  ///   "timestamp": "2024-03-24T22:25:00.000Z"
  /// }
  /// ```
  Future<ApiResponse<LocaleValidationResultDto>> validateLocale(String locale) async {
    try {
      if (!await _checkAuth()) {
        return ApiResponse<LocaleValidationResultDto>(
          success: false,
          statusCode: 401,
          error: 'Unauthorized',
          timestamp: DateTime.now(),
        );
      }

      // Validate the locale code
      const validationService = LocaleValidationService();
      final validation = validationService.validateLocaleCode(locale);

      final dto = LocaleValidationResultDto(
        isValid: validation.isValid,
        locale: locale,
        displayName: validation.isValid ? locale : null,
        errorMessage: validation.isValid ? null : validation.errorMessage,
      );

      return ApiResponse<LocaleValidationResultDto>(
        success: true,
        statusCode: 200,
        data: dto,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return ApiResponse<LocaleValidationResultDto>(
        success: false,
        statusCode: 500,
        error: 'Error validating locale: $e',
        timestamp: DateTime.now(),
      );
    }
  }
}
