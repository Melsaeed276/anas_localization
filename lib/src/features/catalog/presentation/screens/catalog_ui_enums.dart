import '../../domain/entities/catalog_models.dart';

enum CatalogQueueSortMode {
  alphabetical,
  namespace,
}

enum CatalogQueueSection {
  missing('missing', CatalogCellStatus.red),
  needsReview('needsReview', CatalogCellStatus.warning),
  ready('ready', CatalogCellStatus.green);

  const CatalogQueueSection(this.storageValue, this.status);

  final String storageValue;
  final CatalogCellStatus status;
}

enum CatalogRowStatusFilter {
  all(''),
  ready('green'),
  needsReview('warning'),
  missing('red');

  const CatalogRowStatusFilter(this.apiValue);

  final String apiValue;
}
