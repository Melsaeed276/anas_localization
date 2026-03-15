library;

import '../entities/catalog_models.dart';

abstract class CatalogRepositoryContract {
  Future<List<CatalogRow>> loadRows({
    String? search,
    CatalogCellStatus? status,
  });

  Future<CatalogSummary> loadSummary();

  Future<CatalogMeta> loadMeta();

  Future<List<CatalogActivityEvent>> loadActivity({
    required String keyPath,
  });
}
