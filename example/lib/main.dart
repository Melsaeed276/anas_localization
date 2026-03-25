import 'package:flutter/material.dart';
import 'package:anas_localization/anas_localization.dart' hide Dictionary;
import 'package:localization_example/pages/features_page.dart';
import 'generated/dictionary.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnasLocalization(
      fallbackLocale: Locale('en'),
      assetPath: 'assets/lang',
      assetLocales: [
        Locale('en'),
        Locale('ar'),
        Locale('tr'),
      ],
      app: MainApp(),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AnasLocalization.of(context).locale;

    return MaterialApp(
      title: 'Anas Localization Example',
      locale: locale,
      builder: (context, child) => AnasDirectionalityWrapper(
        locale: locale,
        child: child!,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DictionaryLocalizationsDelegate(),
      ],
      supportedLocales: context.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
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
  int _itemCount = 1;

  @override
  Widget build(BuildContext context) {
    final dictionary = getDictionary();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(dictionary.appTitle),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      drawer: _buildDrawer(context, dictionary, theme),
      body: AnasDirectionalityWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLanguageSection(context, dictionary, theme),
              const SizedBox(height: 24),
              _buildWelcomeSection(dictionary, theme),
              const SizedBox(height: 16),
              _buildPluralizationSection(dictionary, theme),
              const SizedBox(height: 16),
              _buildFeaturesButton(context, dictionary, theme),
              const SizedBox(height: 24),
              _buildInfoCard(dictionary, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, Dictionary dictionary, ThemeData theme) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.translate,
                  size: 48,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(height: 8),
                Text(
                  dictionary.appTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dictionary.localizationDemo,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(dictionary.basicDemo),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: Text(dictionary.exploreAllFeatures),
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
            title: Text(
              dictionary.currentLanguage(
                language: context.locale.languageCode.toUpperCase(),
              ),
            ),
            subtitle: Text(context.isRTL ? dictionary.rightToLeft : dictionary.leftToRight),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection(
    BuildContext context,
    Dictionary dictionary,
    ThemeData theme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dictionary.languageSelection,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            AnasLanguageDialog(
              supportedLocales: context.supportedLocales,
              showDescription: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(Dictionary dictionary, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dictionary.welcomeUser(name: 'Ahmed'),
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              dictionary.welcome,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              dictionary.moneyArgs(
                name: 'Muhammed',
                amount: '500',
                currency: 'TL',
              ),
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPluralizationSection(Dictionary dictionary, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dictionary.pluralizationDemo,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              dictionary.itemsCount(count: _itemCount),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  dictionary.count(count: _itemCount.toString()),
                  style: theme.textTheme.bodyLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _itemCount > 0 ? () => setState(() => _itemCount--) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => _itemCount++),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesButton(
    BuildContext context,
    Dictionary dictionary,
    ThemeData theme,
  ) {
    return SizedBox(
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
    );
  }

  Widget _buildInfoCard(Dictionary dictionary, ThemeData theme) {
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  dictionary.appTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              dictionary.featuresDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
