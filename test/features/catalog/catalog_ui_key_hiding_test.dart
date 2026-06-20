import 'dart:convert';
import 'dart:io';

import 'package:anas_localization/src/catalog/catalog.dart';
import 'package:anas_localization/src/features/catalog/domain/services/catalog_ui_key_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCatalogUiKeyResolver extends CatalogUiKeyResolver {
  _FakeCatalogUiKeyResolver(this._keys);

  final Set<String> _keys;

  @override
  Future<Set<String>> resolve() async => _keys;
}

void main() {
  group('Catalog UI key hiding', () {
    late Directory root;
    late Directory langDir;
    late File configFile;
    late File stateFile;

    setUp(() async {
      root = Directory.systemTemp.createTempSync('catalog_ui_key_hiding_test_');
      langDir = Directory('${root.path}/lang');
      await langDir.create(recursive: true);

      await File('${langDir.path}/en.json').writeAsString(
        jsonEncode({
          'home': {'title': 'Home'},
          'refresh': 'ThisShouldBeHidden',
        }),
      );
      await File('${langDir.path}/tr.json').writeAsString(
        jsonEncode({
          'home': {'title': 'Ana Sayfa'},
          'refresh': 'GizliOlmali',
        }),
      );

      configFile = File('${root.path}/anas_catalog.yaml');
      stateFile = File('${root.path}/.anas_localization/catalog_state.json');
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
    });

    tearDown(() async {
      if (root.existsSync()) {
        await root.delete(recursive: true);
      }
    });

    Future<CatalogService> createService({required bool hideCatalogUiKeys}) async {
      final loadedConfig = await CatalogConfig.load(path: configFile.path);
      final config = loadedConfig.copyWith(hideCatalogUiKeys: hideCatalogUiKeys);
      return CatalogService(
        config: config,
        projectRootPath: root.path,
        uiKeyResolver: _FakeCatalogUiKeyResolver(const {'refresh'}),
      );
    }

    test('loadRows excludes reserved keys when enabled', () async {
      final service = await createService(hideCatalogUiKeys: true);
      final rows = await service.loadRows();

      expect(rows.any((row) => row.keyPath == 'refresh'), isFalse);
      expect(rows.any((row) => row.keyPath == 'home.title'), isTrue);
    });

    test('loadRows includes reserved keys when disabled', () async {
      final service = await createService(hideCatalogUiKeys: false);
      final rows = await service.loadRows();

      expect(rows.any((row) => row.keyPath == 'refresh'), isTrue);
      expect(rows.any((row) => row.keyPath == 'home.title'), isTrue);
    });

    test('addKey rejects reserved keys when enabled', () async {
      final service = await createService(hideCatalogUiKeys: true);

      expect(
        () => service.addKey(
          keyPath: 'refresh',
          valuesByLocale: const {'en': 'x', 'tr': 'y'},
        ),
        throwsA(isA<CatalogOperationException>()),
      );
    });
  });
}
