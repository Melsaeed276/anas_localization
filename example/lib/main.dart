import 'package:anas_localization/localization.dart';
import 'package:flutter/material.dart';
import 'package:localization_example/widgets/language_selector.dart';

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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(AnasLocalization.dictionary.appName)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Language selector dropdown
              const LanguageSelector(),

              const SizedBox(height: 24),

              // Display a few localized strings
              Text(
                AnasLocalization.dictionary.welcomeUser(name: 'Ahmed'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                AnasLocalization.dictionary.itemsCount(count: itemCount),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              // Localized string with pluralization
              Text(
                AnasLocalization.dictionary.day(count: itemCount),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              // Localized string with positional arguments
              Text(
                AnasLocalization.dictionary.moneyArgs(name: 'Muhammed', amount: 500, currency: 'TL'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              // Localized string with named arguments

              Text(AnasLocalization.dictionary.car),

              // Localized string with gender-based message
              Text(
                AnasLocalization.dictionary.gender(gender: 'male'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(AnasLocalization.dictionary.pleaseWait),
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
