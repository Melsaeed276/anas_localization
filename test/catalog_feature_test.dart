import 'dart:convert';
import 'dart:io';

import 'package:anas_localization/src/catalog/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CatalogService add-key workflow', () {
    late _CatalogWorkspace workspace;

    setUp(() async {
      workspace = await _CatalogWorkspace.create();
    });

    tearDown(() async {
      await workspace.dispose();
    });

    test('creating key with all locale values marks cells green', () async {
      final service = await workspace.createService();

      final row = await service.addKey(
        keyPath: 'home.subtitle',
        valuesByLocale: const {
          'en': 'Welcome',
          'tr': 'Hoş geldiniz',
          'ar': 'مرحبا',
        },
      );

      expect(row.cellStates['en']?.status, CatalogCellStatus.green);
      expect(row.cellStates['tr']?.status, CatalogCellStatus.green);
      expect(row.cellStates['ar']?.status, CatalogCellStatus.green);
    });

    test('creating key with partial locale values keeps warning review state', () async {
      final service = await workspace.createService();

      final row = await service.addKey(
        keyPath: 'home.subtitle',
        valuesByLocale: const {'en': 'Welcome'},
      );

      expect(row.cellStates['en']?.status, CatalogCellStatus.warning);
      expect(
        row.cellStates['en']?.reason,
        CatalogStatusReasons.newKeyNeedsTranslationReview,
      );
      expect(row.cellStates['tr']?.status, CatalogCellStatus.warning);
      expect(
        row.cellStates['tr']?.reason,
        CatalogStatusReasons.newKeyNeedsTranslationReview,
      );
      expect(row.cellStates['ar']?.status, CatalogCellStatus.warning);
      expect(
        row.cellStates['ar']?.reason,
        CatalogStatusReasons.newKeyNeedsTranslationReview,
      );
    });

    test('duplicate key creation is rejected', () async {
      final service = await workspace.createService();

      expect(
        () => service.addKey(
          keyPath: 'home.title',
          valuesByLocale: const {
            'en': 'Home',
            'tr': 'Ana Sayfa',
            'ar': 'الرئيسية',
          },
        ),
        throwsA(isA<CatalogOperationException>()),
      );
    });
  });

  group('Catalog API integration', () {
    late _CatalogWorkspace workspace;
    CatalogApiServer? server;

    setUp(() async {
      workspace = await _CatalogWorkspace.create();
      final config = await workspace.loadConfig();
      final service = CatalogService(
        config: config,
        projectRootPath: workspace.root.path,
      );
      server = CatalogApiServer(
        service: service,
        host: '127.0.0.1',
        port: config.apiPort,
      );
      await server!.start();
    });

    tearDown(() async {
      await server?.stop();
      await workspace.dispose();
    });

    test('POST /api/catalog/key writes key to locale files', () async {
      final response = await _httpJsonRequest(
        method: 'POST',
        uri: Uri.parse('${server!.url}/api/catalog/key'),
        body: {
          'keyPath': 'checkout.summary.title',
          'valuesByLocale': {
            'en': 'Summary',
            'tr': 'Özet',
            'ar': 'الملخص',
          },
          'markGreenIfComplete': true,
        },
      );

      expect(response['keyPath'], 'checkout.summary.title');

      final enMap = await workspace.readLocaleFile('en');
      final trMap = await workspace.readLocaleFile('tr');
      final arMap = await workspace.readLocaleFile('ar');
      expect(
        ((enMap['checkout'] as Map<String, dynamic>)['summary'] as Map<String, dynamic>)['title'],
        'Summary',
      );
      expect(
        ((trMap['checkout'] as Map<String, dynamic>)['summary'] as Map<String, dynamic>)['title'],
        'Özet',
      );
      expect(
        ((arMap['checkout'] as Map<String, dynamic>)['summary'] as Map<String, dynamic>)['title'],
        'الملخص',
      );
    });

    test('POST /api/catalog/key returns warning statuses for partial values', () async {
      final response = await _httpJsonRequest(
        method: 'POST',
        uri: Uri.parse('${server!.url}/api/catalog/key'),
        body: {
          'keyPath': 'checkout.summary.subtitle',
          'valuesByLocale': {'en': 'Items'},
          'markGreenIfComplete': true,
        },
      );

      final cellStates = Map<String, dynamic>.from(response['cellStates'] as Map);
      expect((cellStates['tr'] as Map<String, dynamic>)['status'], 'warning');
      expect(
        (cellStates['tr'] as Map<String, dynamic>)['reason'],
        CatalogStatusReasons.newKeyNeedsTranslationReview,
      );
      expect((cellStates['ar'] as Map<String, dynamic>)['status'], 'warning');
    });

    test('POST /api/catalog/key returns error for duplicate key', () async {
      final result = await _httpJsonRequestAllowError(
        method: 'POST',
        uri: Uri.parse('${server!.url}/api/catalog/key'),
        body: {
          'keyPath': 'home.title',
          'valuesByLocale': {'en': 'Home'},
          'markGreenIfComplete': true,
        },
      );

      expect(result.statusCode, HttpStatus.badRequest);
      expect(result.body['error'].toString(), contains('already exists'));
    });

    test('catalog UI page contains New String modal controls', () async {
      final uiPort = (await workspace.loadConfig()).uiPort;
      final uiServer = CatalogUiServer(
        host: '127.0.0.1',
        port: uiPort,
        apiUrl: server!.url,
      );
      await uiServer.start();
      addTearDown(() async {
        await uiServer.stop();
      });

      final html = await _httpRawRequest(
        method: 'GET',
        uri: Uri.parse('${uiServer.url}/'),
      );
      expect(html, contains('Create New String'));
      expect(html, contains('+ New String'));
      expect(html, contains('newKeyPath'));
    });

    test('status persists after service restart', () async {
      await _httpJsonRequest(
        method: 'POST',
        uri: Uri.parse('${server!.url}/api/catalog/key'),
        body: {
          'keyPath': 'checkout.summary.subtitle',
          'valuesByLocale': {'en': 'Items'},
          'markGreenIfComplete': true,
        },
      );

      await server!.stop();
      final config = await workspace.loadConfig();
      final restartedService = CatalogService(
        config: config,
        projectRootPath: workspace.root.path,
      );
      final rows = await restartedService.loadRows();
      final row = rows.firstWhere((item) => item.keyPath == 'checkout.summary.subtitle');
      expect(row.cellStates['tr']?.status, CatalogCellStatus.warning);
      expect(
        row.cellStates['tr']?.reason,
        CatalogStatusReasons.newKeyNeedsTranslationReview,
      );
    });
  });

  group('Catalog CLI add-key', () {
    late _CatalogWorkspace workspace;

    setUp(() async {
      workspace = await _CatalogWorkspace.create();
    });

    tearDown(() async {
      await workspace.dispose();
    });

    test('catalog add-key succeeds with full locale input', () async {
      final result = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'catalog',
          'add-key',
          '--config=${workspace.configFile.path}',
          '--key=profile.title',
          '--value-en=Profile',
          '--value-tr=Profil',
          '--value-ar=الملف الشخصي',
        ],
      );

      expect(result.exitCode, 0);
      final state = await workspace.readStateFile();
      final keyState = (state['keys'] as Map<String, dynamic>)['profile.title'] as Map<String, dynamic>;
      final cells = keyState['cells'] as Map<String, dynamic>;
      expect((cells['en'] as Map<String, dynamic>)['status'], 'green');
      expect((cells['tr'] as Map<String, dynamic>)['status'], 'green');
      expect((cells['ar'] as Map<String, dynamic>)['status'], 'green');
    });

    test('catalog add-key partial locale input produces warning state', () async {
      final result = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'catalog',
          'add-key',
          '--config=${workspace.configFile.path}',
          '--key=profile.subtitle',
          '--value-en=Welcome back',
        ],
      );

      expect(result.exitCode, 0);
      final state = await workspace.readStateFile();
      final keyState = (state['keys'] as Map<String, dynamic>)['profile.subtitle'] as Map<String, dynamic>;
      final cells = keyState['cells'] as Map<String, dynamic>;
      expect((cells['tr'] as Map<String, dynamic>)['status'], 'warning');
      expect(
        (cells['tr'] as Map<String, dynamic>)['reason'],
        CatalogStatusReasons.newKeyNeedsTranslationReview,
      );
      expect((cells['ar'] as Map<String, dynamic>)['status'], 'warning');
    });

    test('catalog add-key fails for invalid or existing key', () async {
      final invalid = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'catalog',
          'add-key',
          '--config=${workspace.configFile.path}',
          '--key=home..title',
          '--value-en=Home',
        ],
      );
      expect(invalid.exitCode, isNonZero);

      final duplicate = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'catalog',
          'add-key',
          '--config=${workspace.configFile.path}',
          '--key=home.title',
          '--value-en=Home',
        ],
      );
      expect(duplicate.exitCode, isNonZero);
    });
  });
}

class _CatalogWorkspace {
  _CatalogWorkspace({
    required this.root,
    required this.langDir,
    required this.configFile,
    required this.stateFile,
  });

  final Directory root;
  final Directory langDir;
  final File configFile;
  final File stateFile;

  static Future<_CatalogWorkspace> create() async {
    final root = Directory.systemTemp.createTempSync('catalog_feature_test_');
    final langDir = Directory('${root.path}/lang');
    await langDir.create(recursive: true);

    await File('${langDir.path}/en.json').writeAsString(
      jsonEncode({
        'home': {'title': 'Home'},
      }),
    );
    await File('${langDir.path}/tr.json').writeAsString(
      jsonEncode({
        'home': {'title': 'Ana Sayfa'},
      }),
    );
    await File('${langDir.path}/ar.json').writeAsString(
      jsonEncode({
        'home': {'title': 'الرئيسية'},
      }),
    );

    final uiPort = await _findFreePort();
    final apiPort = await _findFreePort();
    final configFile = File('${root.path}/anas_catalog.yaml');
    final stateFile = File('${root.path}/.anas_localization/catalog_state.json');
    await configFile.writeAsString('''
version: 1
lang_dir: ${langDir.path}
format: json
fallback_locale: en
source_locale: en
state_file: ${stateFile.path}
ui_port: $uiPort
api_port: $apiPort
open_browser: false
arb_file_prefix: app
''');

    return _CatalogWorkspace(
      root: root,
      langDir: langDir,
      configFile: configFile,
      stateFile: stateFile,
    );
  }

  Future<CatalogService> createService() async {
    final config = await loadConfig();
    return CatalogService(
      config: config,
      projectRootPath: root.path,
    );
  }

  Future<CatalogConfig> loadConfig() {
    return CatalogConfig.load(path: configFile.path);
  }

  Future<Map<String, dynamic>> readLocaleFile(String locale) async {
    final file = File('${langDir.path}/$locale.json');
    return Map<String, dynamic>.from(jsonDecode(await file.readAsString()) as Map);
  }

  Future<Map<String, dynamic>> readStateFile() async {
    return Map<String, dynamic>.from(jsonDecode(await stateFile.readAsString()) as Map);
  }

  Future<void> dispose() async {
    if (root.existsSync()) {
      await root.delete(recursive: true);
    }
  }
}

Future<int> _findFreePort() async {
  final serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = serverSocket.port;
  await serverSocket.close();
  return port;
}

Future<Map<String, dynamic>> _httpJsonRequest({
  required String method,
  required Uri uri,
  Map<String, dynamic>? body,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri);
    request.headers.contentType = ContentType.json;
    if (body != null) {
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    final text = await utf8.decoder.bind(response).join();
    final decoded = text.trim().isEmpty ? <String, dynamic>{} : jsonDecode(text);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('HTTP ${response.statusCode}: $decoded');
    }
    return Map<String, dynamic>.from(decoded as Map);
  } finally {
    client.close(force: true);
  }
}

Future<_HttpResult> _httpJsonRequestAllowError({
  required String method,
  required Uri uri,
  Map<String, dynamic>? body,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri);
    request.headers.contentType = ContentType.json;
    if (body != null) {
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    final text = await utf8.decoder.bind(response).join();
    final decoded = text.trim().isEmpty ? <String, dynamic>{} : jsonDecode(text);
    return _HttpResult(
      statusCode: response.statusCode,
      body: Map<String, dynamic>.from(decoded as Map),
    );
  } finally {
    client.close(force: true);
  }
}

Future<String> _httpRawRequest({
  required String method,
  required Uri uri,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri);
    final response = await request.close();
    final text = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('HTTP ${response.statusCode}: $text');
    }
    return text;
  } finally {
    client.close(force: true);
  }
}

class _HttpResult {
  const _HttpResult({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final Map<String, dynamic> body;
}
