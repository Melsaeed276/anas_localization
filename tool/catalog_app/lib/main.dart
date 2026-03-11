import 'package:anas_localization/catalog.dart';
import 'package:flutter/widgets.dart';

void main() {
  runApp(const CatalogWebAppRoot());
}

class CatalogWebAppRoot extends StatelessWidget {
  const CatalogWebAppRoot({
    super.key,
    this.bootstrapLoader,
    this.clientFactory,
    this.preferencesController,
  });

  final Future<CatalogBootstrapConfig> Function()? bootstrapLoader;
  final CatalogApiClient Function(Uri baseUri)? clientFactory;
  final CatalogPreferencesController? preferencesController;

  @override
  Widget build(BuildContext context) {
    return CatalogBootstrapApp(
      bootstrapLoader: bootstrapLoader,
      clientFactory: clientFactory,
      preferencesController: preferencesController,
    );
  }
}
