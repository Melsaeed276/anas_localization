library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/entities/catalog_models.dart';

class CatalogBootstrapConfig {
  const CatalogBootstrapConfig({
    required this.apiUrl,
  });

  factory CatalogBootstrapConfig.fromJson(Map<String, dynamic> json) {
    return CatalogBootstrapConfig(
      apiUrl: json['apiUrl']?.toString() ?? '',
    );
  }

  final String apiUrl;
}

class CatalogApiClient {
  CatalogApiClient({
    required this.baseUri,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final Uri baseUri;
  final http.Client _httpClient;

  Future<CatalogMeta> loadMeta() async {
    final payload = await _requestJson(
      'GET',
      '/api/catalog/meta',
    );
    return CatalogMeta.fromJson(payload);
  }

  Future<List<CatalogRow>> loadRows({
    String search = '',
    String status = '',
  }) async {
    final payload = await _requestJson(
      'GET',
      '/api/catalog/rows',
      queryParameters: <String, String>{
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (status.trim().isNotEmpty) 'status': status.trim(),
      },
    );
    final rows = payload['rows'];
    if (rows is! List) {
      return const <CatalogRow>[];
    }
    return rows.whereType<Map>().map((row) => CatalogRow.fromJson(Map<String, dynamic>.from(row))).toList();
  }

  Future<CatalogSummary> loadSummary() async {
    final payload = await _requestJson(
      'GET',
      '/api/catalog/summary',
    );
    return CatalogSummary.fromJson(payload);
  }

  Future<List<CatalogActivityEvent>> loadActivity({
    required String keyPath,
  }) async {
    final payload = await _requestJson(
      'GET',
      '/api/catalog/activity',
      queryParameters: <String, String>{
        'keyPath': keyPath,
      },
    );
    final activities = payload['activities'];
    if (activities is! List) {
      return const <CatalogActivityEvent>[];
    }
    return activities
        .whereType<Map>()
        .map((item) => CatalogActivityEvent.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<CatalogRow> addKey({
    required String keyPath,
    required Map<String, dynamic> valuesByLocale,
    String? note,
    bool markGreenIfComplete = true,
  }) async {
    final payload = await _requestJson(
      'POST',
      '/api/catalog/key',
      body: <String, dynamic>{
        'keyPath': keyPath,
        'valuesByLocale': valuesByLocale,
        'markGreenIfComplete': markGreenIfComplete,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return CatalogRow.fromJson(payload);
  }

  Future<CatalogRow> updateCell({
    required String keyPath,
    required String locale,
    required dynamic value,
  }) async {
    final payload = await _requestJson(
      'PATCH',
      '/api/catalog/cell',
      body: <String, dynamic>{
        'keyPath': keyPath,
        'locale': locale,
        'value': value,
      },
    );
    return CatalogRow.fromJson(payload);
  }

  Future<CatalogRow> updateKeyNote({
    required String keyPath,
    String? note,
  }) async {
    final payload = await _requestJson(
      'PATCH',
      '/api/catalog/key',
      body: <String, dynamic>{
        'keyPath': keyPath,
        'note': note ?? '',
      },
    );
    return CatalogRow.fromJson(payload);
  }

  Future<void> markReviewed({
    required String keyPath,
    required String locale,
  }) async {
    await _requestJson(
      'POST',
      '/api/catalog/review',
      body: <String, dynamic>{
        'keyPath': keyPath,
        'locale': locale,
      },
    );
  }

  Future<CatalogBulkReviewResult> bulkReview({
    required List<CatalogReviewTarget> targets,
  }) async {
    final payload = await _requestJson(
      'POST',
      '/api/catalog/bulk-review',
      body: <String, dynamic>{
        'items': targets.map((target) => target.toJson()).toList(),
      },
    );
    return CatalogBulkReviewResult.fromJson(payload);
  }

  Future<CatalogRow> deleteCell({
    required String keyPath,
    required String locale,
  }) async {
    final payload = await _requestJson(
      'DELETE',
      '/api/catalog/cell',
      body: <String, dynamic>{
        'keyPath': keyPath,
        'locale': locale,
      },
    );
    return CatalogRow.fromJson(payload);
  }

  Future<void> deleteKey({
    required String keyPath,
  }) async {
    await _requestJson(
      'DELETE',
      '/api/catalog/key',
      body: <String, dynamic>{
        'keyPath': keyPath,
      },
    );
  }

  Future<Map<String, dynamic>> _requestJson(
    String method,
    String path, {
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    final uri = baseUri.replace(
      path: path,
      queryParameters: queryParameters == null || queryParameters.isEmpty ? null : queryParameters,
    );

    late final http.Response response;
    switch (method.toUpperCase()) {
      case 'GET':
        response = await _httpClient.get(uri, headers: _jsonHeaders);
        break;
      case 'POST':
        response =
            await _httpClient.post(uri, headers: _jsonHeaders, body: jsonEncode(body ?? const <String, dynamic>{}));
        break;
      case 'PATCH':
        response =
            await _httpClient.patch(uri, headers: _jsonHeaders, body: jsonEncode(body ?? const <String, dynamic>{}));
        break;
      case 'DELETE':
        response =
            await _httpClient.delete(uri, headers: _jsonHeaders, body: jsonEncode(body ?? const <String, dynamic>{}));
        break;
      default:
        throw UnsupportedError('Unsupported method: $method');
    }

    final text = response.body.trim();
    final payload = text.isEmpty ? const <String, dynamic>{} : jsonDecode(text);
    final map = payload is Map ? Map<String, dynamic>.from(payload) : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CatalogClientException(map['error']?.toString() ?? 'HTTP ${response.statusCode}');
    }
    return map;
  }

  void close() {
    _httpClient.close();
  }

  static const Map<String, String> _jsonHeaders = <String, String>{
    'Content-Type': 'application/json',
  };
}

class CatalogClientException implements Exception {
  CatalogClientException(this.message);

  final String message;

  @override
  String toString() => message;
}
