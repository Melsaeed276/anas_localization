import 'package:anas_localization/localization.dart';
import 'package:flutter/material.dart';
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
      dictionaryFactory: createDictionary,
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
  Widget build(BuildContext context) {
    // No need for any dictionary declaration anymore!
    // You can use 'anasDictionary' directly anywhere in your widgets

    return Scaffold(
      appBar: AppBar(title: Text(anasDictionary.appName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Language selector dropdown
            const LanguageSelector(),

            const SizedBox(height: 24),

            // Display a few localized strings - super simple now!
            Text(
              anasDictionary.welcomeUser(name: 'Ahmed'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              anasDictionary.welcome,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            // Localized string with positional arguments
            Text(
              anasDictionary.moneyArgs(name: 'Muhammed', amount: '500', currency: 'TL'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            Text(anasDictionary.car(count: itemCount)), // Will show appropriate singular form
            Text(anasDictionary.car(count: 5)), // Will show appropriate plural form
            // Arabic gender-aware examples:
            Text(anasDictionary.car(count: itemCount, gender: 'male')), // Arabic: "سيارة واحدة"
            Text(anasDictionary.car(count: itemCount, gender: 'female')), // Arabic: "سيارتان"
            Text(anasDictionary.car(count: 5, gender: 'male')), // Arabic: "5 سيارات"
            Text(anasDictionary.contactSupport),
            Text(anasDictionary.pleaseWait),
            const SizedBox(height: 12),

            // You can also use the context extension if you prefer:
            // Text(context.dict.appName),
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
