import 'package:anas_localization/anas_localization.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryTranslationLoader extends TranslationLoader {
  const _MemoryTranslationLoader(this._baseToMap);

  final Map<String, Map<String, dynamic>> _baseToMap;

  @override
  String get id => 'memory';

  @override
  List<String> get fileExtensions => const ['mem'];

  @override
  Future<Map<String, dynamic>?> load(String basePath) async {
    return _baseToMap[basePath];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocalizationService().clear();
    LocalizationService.clearPreviewDictionaries();
    LocalizationService.resetTranslationLoaders();
    LocalizationService.supportedLocales = ['en'];
    LocalizationService.setFallbackLocaleCode('en');
  });

  test('custom translation loader can be injected without migration', () async {
    LocalizationService.setTranslationLoaders([
      const _MemoryTranslationLoader({
        'assets/lang/en': {'from_loader': 'Loaded from custom loader'},
        'packages/anas_localization/assets/lang/en': {'fallback_key': 'fallback'},
      }),
    ]);

    await LocalizationService().loadLocale('en');

    expect(LocalizationService().currentLocale, 'en');
    expect(
      LocalizationService().currentDictionary.getString('from_loader'),
      'Loaded from custom loader',
    );
  });

  test('loader registry supports runtime registration and unregistration', () {
    final loader = const _MemoryTranslationLoader({});
    LocalizationService.registerTranslationLoader(loader, highestPriority: true);
    expect(
      LocalizationService.registeredTranslationLoaders.any((item) => item.id == 'memory'),
      isTrue,
    );

    final removed = LocalizationService.unregisterTranslationLoader('memory');
    expect(removed, isTrue);
    expect(
      LocalizationService.registeredTranslationLoaders.any((item) => item.id == 'memory'),
      isFalse,
    );
  });
}
