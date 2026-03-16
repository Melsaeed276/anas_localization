import 'package:flutter/material.dart';
import 'package:localization_example/pages/features_page.dart';
import 'package:anas_localization/anas_localization.dart';
import 'package:anas_localization/catalog.dart';
import 'package:localization_example/widgets/language_selector.dart';
import 'generated/dictionary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use AnasLocalization with iPhone-style language setup screen enabled by default
    return const AnasLocalization(
      app: MyApp(),
      fallbackLocale: Locale('en'),
      assetPath: 'assets/lang',
      assetLocales: [
        Locale('ar'),
        Locale('en'),
        Locale('tr'),
      ],
      // animationSetup and setupDuration now have sensible defaults
      // animationSetup: true (default)
      // setupDuration: Duration(milliseconds: 1500) (default)
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final locale = AnasLocalization.of(context).locale;
    return MaterialApp(
      locale: locale,
      builder: (context, child) => AnasDirectionalityWrapper(
        locale: locale,
        child: child!,
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        const DictionaryLocalizationsDelegate(),
      ],
      supportedLocales: context.supportedLocales,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int itemCount = 1;

  @override
  Widget build(BuildContext context) {
    // Get the dictionary safely using the helper function - this will update when language changes
    final dictionary = getDictionary();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anas Localization'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.translate,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Anas Localization',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Localization Demo',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Basic Demo'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('All Features Demo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FeaturesPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Catalog'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CatalogBootstrapApp(
                      bootstrapLoader: _loadExampleBootstrap,
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text('Language: ${context.locale.languageCode.toUpperCase()}'),
              subtitle: Text(context.isRTL ? 'RTL' : 'LTR'),
            ),
          ],
        ),
      ),
      body: AnasDirectionalityWrapper(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              // Enhanced language selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Language Selection',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      AnasLanguageDialog(
                        supportedLocales: context.supportedLocales,
                        showDescription: false,
                      ),
                      const LanguageSelector(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Welcome section with enhanced formatting
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, Ahmed!',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Muhammed has 500 TL',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Pluralization demo
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pluralization Demo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text('Item: $itemCount'),
                      const Text('Items: 5'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Count: $itemCount'),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: itemCount > 0
                                ? () {
                                    setState(() => itemCount--);
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() => itemCount++);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Quick access to features page
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FeaturesPage()),
                    );
                  },
                  icon: const Icon(Icons.explore),
                  label: const Text('Explore All Features'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Quick stats
              const Text('Contact Support'),
            ],
          ),
        ),
      ),
    );
  }
}

Future<CatalogBootstrapConfig> _loadExampleBootstrap() async {
  return const CatalogBootstrapConfig(
    apiUrl: 'http://localhost:4467',
  );
}
