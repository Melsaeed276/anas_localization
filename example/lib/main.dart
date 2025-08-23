import 'package:anas_localization/localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'generated/dictionary.dart' as dictionary_file;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // IMPORTANT: Call this setup function to use the generated Dictionary
  dictionary_file.setupDictionary();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final LocalizationProvider _localizationProvider;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _localizationProvider = LocalizationProvider();
    _initializeLocalization();
  }

  Future<void> _initializeLocalization() async {
    try {
      await _localizationProvider.loadSavedLocaleOrDefault();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading localization:'),
                Text(_errorMessage ?? 'Unknown error'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _isInitialized = false;
                    });
                    _initializeLocalization();
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading localization...'),
              ],
            ),
          ),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _localizationProvider,
      child: Consumer<LocalizationProvider>(
        builder: (context, localizationProvider, child) {
          return MaterialApp(
            title: 'Localization Example',
            home: MyHomePage(),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Localization Demo'),
      ),
      body: Localization(
        dictionary: context.watch<LocalizationProvider>().dictionary,
        locale: context.watch<LocalizationProvider>().locale,
        child: DemoContent(),
      ),
    );
  }
}

class DemoContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Now this will use the GENERATED Dictionary with type-safe getters!
    final dict = Localization.of(context).dictionary! as dictionary_file.Dictionary;

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Using Generated Dictionary:',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16),

          // Type-safe access to translations
          Text('App Name: ${dict.appName}'),
          Text('OK: ${dict.ok}'),
          Text('Cancel: ${dict.cancel}'),
          Text('Continue: ${dict.continueText}'), // Note: 'continue' becomes 'continueText'
          Text('Save: ${dict.save}'),
          Text('Loading: ${dict.loading}'),

          SizedBox(height: 20),

          ElevatedButton(
            onPressed: () => _changeLanguage(context),
            child: Text(dict.changeLanguage),
          ),
        ],
      ),
    );
  }

  void _changeLanguage(BuildContext context) async {
    final provider = context.read<LocalizationProvider>();
    final currentLocale = provider.locale;

    // Cycle through supported languages
    switch (currentLocale) {
      case 'en':
        await provider.loadLocale('ar');
        break;
      case 'ar':
        await provider.loadLocale('tr');
        break;
      default:
        await provider.loadLocale('en');
        break;
    }
  }
}
