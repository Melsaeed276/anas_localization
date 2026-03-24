/// HTTP client adapter implementations.
///
/// Provides default HTTP client implementation using the `http` package.
/// Users can create custom implementations of [HttpClientAdapter] for
/// their preferred HTTP library (e.g., `dio`).
library;

import 'package:http/http.dart' as http;

import 'sdk_utils.dart';

/// Default HTTP client implementation using the `http` package.
///
/// This implementation wraps the `http` package to provide cross-platform
/// HTTP support (mobile, web, desktop).
///
/// Example:
/// ```dart
/// final client = DefaultHttpClient();
/// final response = await client.get(Uri.parse('https://api.example.com/data'));
/// print(response.body);
/// client.close();
/// ```
class DefaultHttpClient implements HttpClientAdapter {
  /// Creates a new [DefaultHttpClient].
  ///
  /// Optionally accepts an existing [http.Client] instance.
  /// If not provided, a new client will be created.
  DefaultHttpClient([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<SimpleHttpResponse> get(Uri uri, {Map<String, String>? headers}) async {
    final response = await _client.get(uri, headers: headers);
    return _toSimpleResponse(response);
  }

  @override
  Future<SimpleHttpResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final response = await _client.post(uri, headers: headers, body: body);
    return _toSimpleResponse(response);
  }

  @override
  Future<SimpleHttpResponse> patch(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final response = await _client.patch(uri, headers: headers, body: body);
    return _toSimpleResponse(response);
  }

  @override
  Future<SimpleHttpResponse> delete(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final response = await _client.delete(uri, headers: headers, body: body);
    return _toSimpleResponse(response);
  }

  @override
  void close() {
    _client.close();
  }

  SimpleHttpResponse _toSimpleResponse(http.Response response) {
    return SimpleHttpResponse(
      statusCode: response.statusCode,
      body: response.body,
      headers: response.headers,
    );
  }
}
