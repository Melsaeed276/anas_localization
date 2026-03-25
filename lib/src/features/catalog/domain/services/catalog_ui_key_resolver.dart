library;

import 'dart:io';
import 'dart:isolate';

import '../../../../shared/utils/arb_interop.dart';

class CatalogUiKeyResolver {
  CatalogUiKeyResolver({
    Uri? catalogEnArbPackageUri,
  }) : catalogEnArbPackageUri = catalogEnArbPackageUri ?? defaultCatalogEnArbPackageUri;

  static final Uri defaultCatalogEnArbPackageUri = Uri.parse(
    'package:anas_localization/src/features/catalog/l10n/l10n/catalog_en.arb',
  );

  final Uri catalogEnArbPackageUri;

  Set<String>? _cached;

  Future<Set<String>> resolve() async {
    final cached = _cached;
    if (cached != null) {
      return cached;
    }

    String? path;
    try {
      final resolved = await Isolate.resolvePackageUri(catalogEnArbPackageUri);
      if (resolved != null) {
        path = File.fromUri(resolved).path;
      }
    } on UnsupportedError {
      // Some runtime environments do not support package URI resolution.
    }

    if (path == null) {
      _cached = const <String>{};
      return _cached!;
    }

    final file = File(path);
    if (!file.existsSync()) {
      _cached = const <String>{};
      return _cached!;
    }

    final document = ArbInterop.parseArb(
      await file.readAsString(),
      fileName: file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : null,
    );

    _cached = document.translations.keys.toSet();
    return _cached!;
  }
}
