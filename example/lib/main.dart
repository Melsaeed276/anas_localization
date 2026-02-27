import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:localization_example/pages/features_page.dart';
import 'package:anas_localization/anas_localization.dart';
import 'package:localization_example/pages/features_page.dart';
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
  Widget build(BuildContext context) => MaterialApp(
        locale: AnasLocalization.of(context).locale,
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

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: AnasLocalization.of(context).locale,
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
        title: Text(dictionary.appName),
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
                    dictionary.appName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    dictionary.localizationDemo,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(dictionary.basicDemo),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: Text(dictionary.allFeaturesDemo),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FeaturesPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(dictionary.currentLanguage(language: context.locale.languageCode.toUpperCase())),
              subtitle: Text(context.isRTL ? dictionary.rightToLeft : dictionary.leftToRight),
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
                      Text(
                        dictionary.languageSelection,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                        dictionary.welcomeUser(name: 'Ahmed'),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dictionary.welcome,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        dictionary.moneyArgs(name: 'Muhammed', amount: '500', currency: 'TL'),
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
                      Text(
                        dictionary.pluralizationDemo,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(dictionary.car(count: itemCount)),
                      Text(dictionary.car(count: 5)),
                      if (context.locale.languageCode == 'ar') ...[
                        Text(dictionary.car(count: itemCount, gender: 'male')),
                        Text(dictionary.car(count: itemCount, gender: 'female')),
                        Text(dictionary.car(count: 5, gender: 'male')),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(dictionary.count(count: itemCount.toString())),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: itemCount > 0 ? () {
                              setState(() => itemCount--);
                            } : null,
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
                  label: Text(dictionary.exploreAllFeatures),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Quick stats
              Text(dictionary.contactSupport),
            ],
          ),
        ),
      ),
    );
  }
}
