import 'package:anas_localization/localization.dart';
import 'package:flutter/material.dart';
import 'package:localization_example/widgets/language_selector.dart';
import 'generated/dictionary.dart' as app_dictionary;

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
    return AnasLocalization(
      fallbackLocale: const Locale('en'),
      assetPath: 'assets/lang',
      assetLocales: const [
        Locale('ar'),
        Locale('en'),
        Locale('tr'),
      ],
      dictionaryFactory: (Map<String, dynamic> map, {required String locale}) {
        return app_dictionary.Dictionary.fromMap(map, locale: locale);
      },
      app: const MyApp(),
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
        supportedLocales: LocalizationService.allSupportedLocales.map((code) => Locale(code)).toList(),
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
    final dict = AnasLocalization.of(context).dictionary as app_dictionary.Dictionary;

    return Scaffold(
      appBar: AppBar(title: Text(dict.appName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Language selector dropdown
            const LanguageSelector(),

            const SizedBox(height: 24),

            // Display a few localized strings
            Text(
              dict.welcomeUser(name: 'Ahmed'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              dict.welcome,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            // Localized string with positional arguments
            Text(
              dict.moneyArgs(name: 'Muhammed', amount: '500', currency: 'TL'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            Text(dict.car(count: itemCount)), // Will show appropriate singular form
            Text(dict.car(count: 5)), // Will show appropriate plural form
            // Arabic gender-aware examples:
            Text(dict.car(count: itemCount, gender: 'male')), // Arabic: "سيارة واحدة"
            Text(dict.car(count: itemCount, gender: 'female')), // Arabic: "سيارتان"
            Text(dict.car(count: 5, gender: 'male')), // Arabic: "5 سيارات"
            Text(dict.contactSupport),
            Text(dict.pleaseWait),
            const SizedBox(height: 12),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            itemCount = itemCount + 1;
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
