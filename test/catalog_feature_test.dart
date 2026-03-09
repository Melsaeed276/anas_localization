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

    test('creating key with all locale values keeps source green and targets pending review', () async {
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
      expect(row.rowStatus, CatalogCellStatus.warning);
      expect(row.pendingLocales, unorderedEquals(['tr', 'ar']));
      expect(row.missingLocales, isEmpty);
    });

    test('creating key with partial locale values marks targets missing', () async {
      final service = await workspace.createService();

      final row = await service.addKey(
        keyPath: 'home.subtitle',
        valuesByLocale: const {'en': 'Welcome'},
      );

      expect(row.cellStates['en']?.status, CatalogCellStatus.green);
      expect(row.cellStates['tr']?.status, CatalogCellStatus.red);
      expect(
        row.cellStates['tr']?.reason,
        CatalogStatusReasons.targetMissing,
      );
      expect(row.cellStates['ar']?.status, CatalogCellStatus.red);
      expect(
        row.cellStates['ar']?.reason,
        CatalogStatusReasons.targetMissing,
      );
      expect(row.rowStatus, CatalogCellStatus.red);
      expect(row.pendingLocales, isEmpty);
      expect(row.missingLocales, unorderedEquals(['tr', 'ar']));
    });

    test('editing and reviewing targets turns the row green only after every target is done', () async {
      final service = await workspace.createService();

      await service.addKey(
        keyPath: 'checkout.notice',
        valuesByLocale: const {
          'en': 'Ready',
          'tr': 'Hazır',
          'ar': 'جاهز',
        },
      );

      await service.markReviewed(keyPath: 'checkout.notice', locale: 'tr');
      var row = (await service.loadRows()).firstWhere((item) => item.keyPath == 'checkout.notice');
      expect(row.cellStates['tr']?.status, CatalogCellStatus.green);
      expect(row.cellStates['ar']?.status, CatalogCellStatus.warning);
      expect(row.rowStatus, CatalogCellStatus.warning);
      expect(row.pendingLocales, ['ar']);

      await service.markReviewed(keyPath: 'checkout.notice', locale: 'ar');
      row = (await service.loadRows()).firstWhere((item) => item.keyPath == 'checkout.notice');
      expect(row.cellStates['tr']?.status, CatalogCellStatus.green);
      expect(row.cellStates['ar']?.status, CatalogCellStatus.green);
      expect(row.rowStatus, CatalogCellStatus.green);
      expect(row.pendingLocales, isEmpty);
      expect(row.missingLocales, isEmpty);
    });

    test('editing the source keeps target values but reopens their review state', () async {
      final service = await workspace.createService();

      await service.addKey(
        keyPath: 'checkout.label',
        valuesByLocale: const {
          'en': 'Checkout',
          'tr': 'Odeme',
          'ar': 'الدفع',
        },
      );
      await service.markReviewed(keyPath: 'checkout.label', locale: 'tr');
      await service.markReviewed(keyPath: 'checkout.label', locale: 'ar');

      final row = await service.updateCell(
        keyPath: 'checkout.label',
        locale: 'en',
        value: 'Checkout now',
      );

      expect(row.valuesByLocale['tr'], 'Odeme');
      expect(row.valuesByLocale['ar'], 'الدفع');
      expect(row.cellStates['en']?.status, CatalogCellStatus.green);
      expect(row.cellStates['tr']?.status, CatalogCellStatus.warning);
      expect(row.cellStates['tr']?.reason, CatalogStatusReasons.sourceChanged);
      expect(row.cellStates['ar']?.status, CatalogCellStatus.warning);
      expect(row.cellStates['ar']?.reason, CatalogStatusReasons.sourceChanged);
      expect(row.rowStatus, CatalogCellStatus.warning);
      expect(row.pendingLocales, unorderedEquals(['tr', 'ar']));
    });

    test('summary rolls up row statuses instead of only raw cell counts', () async {
      final service = await workspace.createService();

      await service.addKey(
        keyPath: 'home.subtitle',
        valuesByLocale: const {
          'en': 'Welcome',
          'tr': 'Hos geldiniz',
          'ar': 'مرحبا',
        },
      );
      await service.addKey(
        keyPath: 'home.caption',
        valuesByLocale: const {'en': 'Read more'},
      );

      final summary = await service.loadSummary();

      expect(summary.totalKeys, 3);
      expect(summary.greenRows, 1);
      expect(summary.warningRows, 1);
      expect(summary.redRows, 1);
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
      expect(response['rowStatus'], 'warning');
      expect(response['pendingLocales'], unorderedEquals(['tr', 'ar']));
      expect(response['missingLocales'], isEmpty);

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

    test('POST /api/catalog/key returns red row status for missing targets', () async {
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
      expect((cellStates['en'] as Map<String, dynamic>)['status'], 'green');
      expect((cellStates['tr'] as Map<String, dynamic>)['status'], 'red');
      expect(
        (cellStates['tr'] as Map<String, dynamic>)['reason'],
        CatalogStatusReasons.targetMissing,
      );
      expect((cellStates['ar'] as Map<String, dynamic>)['status'], 'red');
      expect(response['rowStatus'], 'red');
      expect(response['pendingLocales'], isEmpty);
      expect(response['missingLocales'], unorderedEquals(['tr', 'ar']));
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

    test('GET /api/catalog/meta exposes locale directions', () async {
      final response = await _httpJsonRequest(
        method: 'GET',
        uri: Uri.parse('${server!.url}/api/catalog/meta'),
      );

      final localeDirections = Map<String, dynamic>.from(response['localeDirections'] as Map);
      expect(localeDirections['en'], 'ltr');
      expect(localeDirections['tr'], 'ltr');
      expect(localeDirections['ar'], 'rtl');
    });

    test('POST /api/catalog/review turns only the reviewed target green', () async {
      await _httpJsonRequest(
        method: 'POST',
        uri: Uri.parse('${server!.url}/api/catalog/key'),
        body: {
          'keyPath': 'checkout.done_flow',
          'valuesByLocale': {
            'en': 'Done flow',
            'tr': 'Tamam akisi',
            'ar': 'مسار الاكتمال',
          },
          'markGreenIfComplete': true,
        },
      );

      await _httpJsonRequest(
        method: 'POST',
        uri: Uri.parse('${server!.url}/api/catalog/review'),
        body: {
          'keyPath': 'checkout.done_flow',
          'locale': 'tr',
        },
      );

      final rowsResponse = await _httpJsonRequest(
        method: 'GET',
        uri: Uri.parse('${server!.url}/api/catalog/rows'),
      );
      final rows = List<Map<String, dynamic>>.from(
        (rowsResponse['rows'] as List).map((item) => Map<String, dynamic>.from(item as Map)),
      );
      final row = rows.firstWhere((item) => item['keyPath'] == 'checkout.done_flow');
      final cellStates = Map<String, dynamic>.from(row['cellStates'] as Map);
      expect((cellStates['tr'] as Map<String, dynamic>)['status'], 'green');
      expect((cellStates['ar'] as Map<String, dynamic>)['status'], 'warning');
      expect(row['rowStatus'], 'warning');
      expect(row['pendingLocales'], ['ar']);
    });

    test('GET /api/catalog/summary exposes row-level counts', () async {
      await _httpJsonRequest(
        method: 'POST',
        uri: Uri.parse('${server!.url}/api/catalog/key'),
        body: {
          'keyPath': 'checkout.ready_row',
          'valuesByLocale': {
            'en': 'Ready row',
            'tr': 'Hazir satir',
            'ar': 'سطر جاهز',
          },
          'markGreenIfComplete': true,
        },
      );
      await _httpJsonRequest(
        method: 'POST',
        uri: Uri.parse('${server!.url}/api/catalog/review'),
        body: {
          'keyPath': 'checkout.ready_row',
          'locale': 'tr',
        },
      );
      await _httpJsonRequest(
        method: 'POST',
        uri: Uri.parse('${server!.url}/api/catalog/review'),
        body: {
          'keyPath': 'checkout.ready_row',
          'locale': 'ar',
        },
      );
      await _httpJsonRequest(
        method: 'POST',
        uri: Uri.parse('${server!.url}/api/catalog/key'),
        body: {
          'keyPath': 'checkout.pending_row',
          'valuesByLocale': {
            'en': 'Pending row',
            'tr': 'Bekleyen satir',
            'ar': 'سطر قيد المراجعة',
          },
          'markGreenIfComplete': true,
        },
      );
      await _httpJsonRequest(
        method: 'POST',
        uri: Uri.parse('${server!.url}/api/catalog/key'),
        body: {
          'keyPath': 'checkout.missing_row',
          'valuesByLocale': {'en': 'Missing row'},
          'markGreenIfComplete': true,
        },
      );

      final summary = await _httpJsonRequest(
        method: 'GET',
        uri: Uri.parse('${server!.url}/api/catalog/summary'),
      );

      expect(summary['totalKeys'], 4);
      expect(summary['greenRows'], 2);
      expect(summary['warningRows'], 1);
      expect(summary['redRows'], 1);
    });

    test('PATCH /api/catalog/cell preserves plural maps as objects', () async {
      await _httpJsonRequest(
        method: 'POST',
        uri: Uri.parse('${server!.url}/api/catalog/key'),
        body: {
          'keyPath': 'catalog.car',
          'valuesByLocale': {
            'en': {
              'one': '1 car visible',
              'other': '{count} cars visible',
            },
            'tr': '',
            'ar': '',
          },
          'markGreenIfComplete': true,
        },
      );

      final response = await _httpJsonRequest(
        method: 'PATCH',
        uri: Uri.parse('${server!.url}/api/catalog/cell'),
        body: {
          'keyPath': 'catalog.car',
          'locale': 'tr',
          'value': {
            'one': '1 araba gorunuyor',
            'other': '{count} araba gorunuyor',
          },
        },
      );

      final valuesByLocale = Map<String, dynamic>.from(response['valuesByLocale'] as Map);
      expect(valuesByLocale['tr'], isA<Map>());
      final trMap = await workspace.readLocaleFile('tr');
      final catalog = Map<String, dynamic>.from(trMap['catalog'] as Map);
      final car = Map<String, dynamic>.from(catalog['car'] as Map);
      expect(car['one'], '1 araba gorunuyor');
      expect(car['other'], '{count} araba gorunuyor');
    });

    test('PATCH /api/catalog/cell preserves gender-only maps as objects', () async {
      await _httpJsonRequest(
        method: 'POST',
        uri: Uri.parse('${server!.url}/api/catalog/key'),
        body: {
          'keyPath': 'profile.owner',
          'valuesByLocale': {
            'en': {
              'male': 'Owner for him',
              'female': 'Owner for her',
            },
            'tr': '',
            'ar': '',
          },
          'markGreenIfComplete': true,
        },
      );

      final response = await _httpJsonRequest(
        method: 'PATCH',
        uri: Uri.parse('${server!.url}/api/catalog/cell'),
        body: {
          'keyPath': 'profile.owner',
          'locale': 'ar',
          'value': {
            'male': 'المالك له',
            'female': 'المالكة لها',
          },
        },
      );

      final valuesByLocale = Map<String, dynamic>.from(response['valuesByLocale'] as Map);
      expect(valuesByLocale['ar'], isA<Map>());
      final arMap = await workspace.readLocaleFile('ar');
      final profile = Map<String, dynamic>.from(arMap['profile'] as Map);
      final owner = Map<String, dynamic>.from(profile['owner'] as Map);
      expect(owner['male'], 'المالك له');
      expect(owner['female'], 'المالكة لها');
    });

    test('PATCH /api/catalog/cell preserves nested plural-gender maps as objects', () async {
      await _httpJsonRequest(
        method: 'POST',
        uri: Uri.parse('${server!.url}/api/catalog/key'),
        body: {
          'keyPath': 'vehicle.visible',
          'valuesByLocale': {
            'en': {
              'one': '1 car visible',
              'other': '{count} cars visible',
            },
            'tr': '',
            'ar': '',
          },
          'markGreenIfComplete': true,
        },
      );

      final response = await _httpJsonRequest(
        method: 'PATCH',
        uri: Uri.parse('${server!.url}/api/catalog/cell'),
        body: {
          'keyPath': 'vehicle.visible',
          'locale': 'ar',
          'value': {
            'one': {
              'male': 'سيارة واحدة ظاهرة',
              'female': 'سيارة واحدة ظاهرة',
            },
            'more': {
              'male': '{count} سيارات ظاهرة',
              'female': '{count} سيارات ظاهرة',
            },
          },
        },
      );

      final valuesByLocale = Map<String, dynamic>.from(response['valuesByLocale'] as Map);
      final arValue = Map<String, dynamic>.from(valuesByLocale['ar'] as Map);
      expect(arValue['one'], isA<Map>());
      expect((arValue['one'] as Map<String, dynamic>)['male'], 'سيارة واحدة ظاهرة');
      expect((arValue['more'] as Map<String, dynamic>)['female'], '{count} سيارات ظاهرة');

      final arMap = await workspace.readLocaleFile('ar');
      final vehicle = Map<String, dynamic>.from(arMap['vehicle'] as Map);
      final visible = Map<String, dynamic>.from(vehicle['visible'] as Map);
      expect((visible['one'] as Map<String, dynamic>)['female'], 'سيارة واحدة ظاهرة');
      expect((visible['more'] as Map<String, dynamic>)['male'], '{count} سيارات ظاهرة');
    });

    test('PATCH /api/catalog/cell preserves unsupported but valid leaf objects', () async {
      await _httpJsonRequest(
        method: 'POST',
        uri: Uri.parse('${server!.url}/api/catalog/key'),
        body: {
          'keyPath': 'catalog.raw_variant',
          'valuesByLocale': {
            'en': {
              'one': 'visible',
              'metadata': {
                'tone': 'friendly',
              },
            },
            'tr': '',
            'ar': '',
          },
          'markGreenIfComplete': true,
        },
      );

      final response = await _httpJsonRequest(
        method: 'PATCH',
        uri: Uri.parse('${server!.url}/api/catalog/cell'),
        body: {
          'keyPath': 'catalog.raw_variant',
          'locale': 'tr',
          'value': {
            'one': 'gorunur',
            'metadata': {
              'tone': 'friendly',
              'editor': 'raw',
            },
          },
        },
      );

      final valuesByLocale = Map<String, dynamic>.from(response['valuesByLocale'] as Map);
      final trValue = Map<String, dynamic>.from(valuesByLocale['tr'] as Map);
      expect(trValue['metadata'], isA<Map>());
      expect((trValue['metadata'] as Map<String, dynamic>)['editor'], 'raw');

      final trMap = await workspace.readLocaleFile('tr');
      final catalog = Map<String, dynamic>.from(trMap['catalog'] as Map);
      final rawVariant = Map<String, dynamic>.from(catalog['raw_variant'] as Map);
      expect((rawVariant['metadata'] as Map<String, dynamic>)['tone'], 'friendly');
      expect(rawVariant['one'], 'gorunur');
    });

    test('catalog UI page contains minimal list-editor workspace markers', () async {
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
      expect(html, contains('+ New String'));
      expect(html, contains('Create New String'));
      expect(html, contains('list-editor-layout'));
      expect(html, contains('detailPanel'));
      expect(html, contains('Advanced JSON'));
      expect(html, contains('Done'));
      expect(html, contains('keyListPanel'));
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
      expect(row.cellStates['tr']?.status, CatalogCellStatus.red);
      expect(
        row.cellStates['tr']?.reason,
        CatalogStatusReasons.targetMissing,
      );
      expect(row.rowStatus, CatalogCellStatus.red);
      expect(row.missingLocales, unorderedEquals(['tr', 'ar']));
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

    test('catalog add-key keeps target locales pending until done', () async {
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
      expect((cells['tr'] as Map<String, dynamic>)['status'], 'warning');
      expect(
        (cells['tr'] as Map<String, dynamic>)['reason'],
        CatalogStatusReasons.newKeyNeedsTranslationReview,
      );
      expect((cells['ar'] as Map<String, dynamic>)['status'], 'warning');
      expect(
        (cells['ar'] as Map<String, dynamic>)['reason'],
        CatalogStatusReasons.newKeyNeedsTranslationReview,
      );
    });

    test('catalog add-key partial locale input produces missing target state', () async {
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
      expect((cells['en'] as Map<String, dynamic>)['status'], 'green');
      expect((cells['tr'] as Map<String, dynamic>)['status'], 'red');
      expect(
        (cells['tr'] as Map<String, dynamic>)['reason'],
        CatalogStatusReasons.targetMissing,
      );
      expect((cells['ar'] as Map<String, dynamic>)['status'], 'red');
      expect(
        (cells['ar'] as Map<String, dynamic>)['reason'],
        CatalogStatusReasons.targetMissing,
      );
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

    final configFile = File('${root.path}/anas_catalog.yaml');
    final stateFile = File('${root.path}/.anas_localization/catalog_state.json');
    await configFile.writeAsString('''
version: 1
lang_dir: ${langDir.path}
format: json
fallback_locale: en
source_locale: en
state_file: ${stateFile.path}
ui_port: 0
api_port: 0
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
