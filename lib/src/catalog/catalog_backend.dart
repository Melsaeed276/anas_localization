library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'catalog_ui_template.dart';
import 'catalog_config.dart';
import 'catalog_models.dart';
import 'catalog_service.dart';

class CatalogApiServer {
  CatalogApiServer({
    required this.service,
    this.host = '127.0.0.1',
    required this.port,
  });

  final CatalogService service;
  final String host;
  final int port;

  HttpServer? _server;

  bool get isRunning => _server != null;
  int get boundPort => _server?.port ?? port;
  String get url => 'http://$host:$boundPort';

  Future<void> start() async {
    if (_server != null) {
      return;
    }
    _server = await HttpServer.bind(host, port);
    _server!.listen(_handleRequest);
  }

  Future<void> stop() async {
    final server = _server;
    if (server == null) {
      return;
    }
    _server = null;
    await server.close(force: true);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final method = request.method.toUpperCase();
      final path = request.uri.path;

      if (method == 'OPTIONS') {
        request.response
          ..statusCode = HttpStatus.noContent
          ..headers.set('Access-Control-Allow-Origin', '*')
          ..headers.set('Access-Control-Allow-Headers', 'Content-Type')
          ..headers.set('Access-Control-Allow-Methods', 'GET,POST,PATCH,DELETE,OPTIONS');
        await request.response.close();
        return;
      }

      if (path == '/api/catalog/meta' && method == 'GET') {
        final meta = await service.loadMeta();
        return _respondJson(request, HttpStatus.ok, meta.toJson());
      }

      if (path == '/api/catalog/rows' && method == 'GET') {
        final status = request.uri.queryParameters['status'];
        final statusFilter = (status == null || status.isEmpty) ? null : catalogCellStatusFromString(status);
        final rows = await service.loadRows(
          search: request.uri.queryParameters['search'],
          status: statusFilter,
        );
        return _respondJson(
          request,
          HttpStatus.ok,
          {
            'rows': rows.map((row) => row.toJson()).toList(),
          },
        );
      }

      if (path == '/api/catalog/summary' && method == 'GET') {
        final summary = await service.loadSummary();
        return _respondJson(request, HttpStatus.ok, summary.toJson());
      }

      if (path == '/api/catalog/key' && method == 'POST') {
        final body = await _readJsonBody(request);
        final keyPath = body['keyPath']?.toString() ?? '';
        final valuesRaw = body['valuesByLocale'];
        final values = <String, dynamic>{};
        if (valuesRaw is Map) {
          for (final entry in valuesRaw.entries) {
            values[entry.key.toString()] = entry.value;
          }
        }
        final markGreenIfComplete = body['markGreenIfComplete'] != false;
        final row = await service.addKey(
          keyPath: keyPath,
          valuesByLocale: values,
          markGreenIfComplete: markGreenIfComplete,
        );
        return _respondJson(request, HttpStatus.ok, row.toJson());
      }

      if (path == '/api/catalog/cell' && method == 'PATCH') {
        final body = await _readJsonBody(request);
        final keyPath = body['keyPath']?.toString() ?? '';
        final locale = body['locale']?.toString() ?? '';
        final value = body['value'];
        final row = await service.updateCell(
          keyPath: keyPath,
          locale: locale,
          value: value,
        );
        return _respondJson(request, HttpStatus.ok, row.toJson());
      }

      if (path == '/api/catalog/cell' && method == 'DELETE') {
        final body = await _readJsonBody(request);
        final keyPath = body['keyPath']?.toString() ?? '';
        final locale = body['locale']?.toString() ?? '';
        final row = await service.deleteCell(
          keyPath: keyPath,
          locale: locale,
        );
        return _respondJson(request, HttpStatus.ok, row.toJson());
      }

      if (path == '/api/catalog/review' && method == 'POST') {
        final body = await _readJsonBody(request);
        final keyPath = body['keyPath']?.toString() ?? '';
        final locale = body['locale']?.toString() ?? '';
        await service.markReviewed(
          keyPath: keyPath,
          locale: locale,
        );
        return _respondJson(request, HttpStatus.ok, {'ok': true});
      }

      if (path == '/api/catalog/key' && method == 'DELETE') {
        final body = await _readJsonBody(request);
        final keyPath = body['keyPath']?.toString() ?? '';
        await service.deleteKey(keyPath);
        return _respondJson(request, HttpStatus.ok, {'ok': true});
      }

      _respondJson(
        request,
        HttpStatus.notFound,
        {'error': 'Route not found: ${request.method} ${request.uri.path}'},
      );
    } on CatalogOperationException catch (error) {
      _respondJson(
        request,
        HttpStatus.badRequest,
        {'error': error.message},
      );
    } catch (error) {
      _respondJson(
        request,
        HttpStatus.internalServerError,
        {'error': error.toString()},
      );
    }
  }

  Future<Map<String, dynamic>> _readJsonBody(HttpRequest request) async {
    final text = await utf8.decoder.bind(request).join();
    if (text.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw const FormatException('Request body must be a JSON object.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  void _respondJson(
    HttpRequest request,
    int statusCode,
    Map<String, dynamic> payload,
  ) {
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..headers.set('Access-Control-Allow-Origin', '*')
      ..headers.set('Access-Control-Allow-Headers', 'Content-Type')
      ..headers.set('Access-Control-Allow-Methods', 'GET,POST,PATCH,DELETE,OPTIONS')
      ..write(const JsonEncoder.withIndent('  ').convert(payload));
    request.response.close();
  }
}

class CatalogUiServer {
  CatalogUiServer({
    this.host = '127.0.0.1',
    required this.port,
    required this.apiUrl,
  });

  final String host;
  final int port;
  final String apiUrl;

  HttpServer? _server;

  bool get isRunning => _server != null;
  int get boundPort => _server?.port ?? port;
  String get url => 'http://$host:$boundPort';

  Future<void> start() async {
    if (_server != null) {
      return;
    }
    _server = await HttpServer.bind(host, port);
    _server!.listen(_handleRequest);
  }

  Future<void> stop() async {
    final server = _server;
    if (server == null) {
      return;
    }
    _server = null;
    await server.close(force: true);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    if (request.method.toUpperCase() != 'GET') {
      request.response
        ..statusCode = HttpStatus.methodNotAllowed
        ..write('Method Not Allowed');
      await request.response.close();
      return;
    }

    if (path == '/' || path == '/index.html') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(_buildCatalogHtml(apiUrl: apiUrl));
      await request.response.close();
      return;
    }

    if (path == '/health') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.text
        ..write('ok');
      await request.response.close();
      return;
    }

    request.response
      ..statusCode = HttpStatus.notFound
      ..write('Not Found');
    await request.response.close();
  }
}

class CatalogRuntime {
  CatalogRuntime({
    required CatalogService service,
    required CatalogConfig config,
    this.host = '127.0.0.1',
  })  : _service = service,
        _config = config;

  final CatalogService _service;
  final CatalogConfig _config;
  final String host;

  late final CatalogApiServer _apiServer = CatalogApiServer(
    service: _service,
    host: host,
    port: _config.apiPort,
  );
  late final CatalogUiServer _uiServer = CatalogUiServer(
    host: host,
    port: _config.uiPort,
    apiUrl: _apiServer.url,
  );

  bool get isRunning => _apiServer.isRunning || _uiServer.isRunning;
  String get apiUrl => _apiServer.url;
  String get uiUrl => _uiServer.url;

  Future<void> start() async {
    await _apiServer.start();
    try {
      await _uiServer.start();
    } on Object {
      await _apiServer.stop();
      rethrow;
    }

    if (_config.openBrowser) {
      unawaited(_openBrowser(uiUrl));
    }
  }

  Future<void> stop() async {
    await _uiServer.stop();
    await _apiServer.stop();
  }
}

Future<void> _openBrowser(String url) async {
  try {
    if (Platform.isMacOS) {
      await Process.start('open', [url], runInShell: true);
      return;
    }
    if (Platform.isWindows) {
      await Process.start('cmd', ['/c', 'start', '', url], runInShell: true);
      return;
    }
    if (Platform.isLinux) {
      await Process.start('xdg-open', [url], runInShell: true);
    }
  } on Object {
    // Ignore browser launch errors; server is still usable via printed URL.
  }
}

String _buildCatalogHtml({required String apiUrl}) => buildCatalogHtml(apiUrl: apiUrl);
