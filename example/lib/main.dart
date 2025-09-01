import 'package:anas_localization/localization.dart';
import 'package:flutter/material.dart';
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
    // Wrap MaterialApp in AnasLocalization to provide translations and locale to subtree
    // It will automatically rebuild the app whenever the locale updated.
    return const AnasLocalization(
      fallbackLocale: Locale('en'),
      assetPath: 'assets/lang',
      assetLocales: [
        Locale('ar'),
        Locale('en'),
        Locale('tr'),
      ],
      app: MyApp(),
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int itemCount = 1;

  @override
  Widget build(BuildContext context) {
    // Get the dictionary safely using the helper function
    final dict = getDictionary();

    return Scaffold(
      appBar: AppBar(
        title: Text(dict.appName),
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
                    dict.appName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    dict.localizationDemo,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(dict.basicDemo),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: Text(dict.allFeaturesDemo),
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
              title: Text(dict.currentLanguage(language: context.locale.languageCode.toUpperCase())),
              subtitle: Text(context.isRTL ? dict.rightToLeft : dict.leftToRight),
            ),
          ],
        ),
      ),
      body: AnasDirectionalityWrapper(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Enhanced language selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dict.languageSelection,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                        dict.welcomeUser(name: 'Ahmed'),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dict.welcome,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        dict.moneyArgs(name: 'Muhammed', amount: '500', currency: 'TL'),
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
                        dict.pluralizationDemo,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(dict.car(count: itemCount)),
                      Text(dict.car(count: 5)),
                      if (context.locale.languageCode == 'ar') ...[
                        Text(dict.car(count: itemCount, gender: 'male')),
                        Text(dict.car(count: itemCount, gender: 'female')),
                        Text(dict.car(count: 5, gender: 'male')),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(dict.count(count: itemCount.toString())),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: itemCount > 0 ? () {
                              setState(() => itemCount--);
                            } : null,
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
                  label: Text(dict.exploreAllFeatures),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Quick stats
              Text(dict.contactSupport),
            ],
          ),
        ),
      ),
    );
  }
}
