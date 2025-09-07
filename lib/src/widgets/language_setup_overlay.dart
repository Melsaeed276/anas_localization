/// Loading screen for language changes
library;

import 'package:flutter/material.dart';

import '../../localization.dart';
import '../services/logging_service/logging_service.dart';

/// Public API for triggering language changes with setup overlay
class AnasLanguageSetup {
  /// Attempts to change language using the setup overlay if available,
  /// returns true if successful, false if setup overlay is not available
  static bool tryChangeLanguage(Locale targetLocale) {
    if (_AnasLanguageSetupOverlayState._instance != null) {
      _AnasLanguageSetupOverlayState.changeLanguage(targetLocale);
      return true;
    }
    return false;
  }

  /// Checks if the setup overlay is currently available
  static bool get isSetupOverlayAvailable => _AnasLanguageSetupOverlayState._instance != null;
}

/// A loading overlay that appears during language changes
/// Similar to iPhone's "Setting up language..." screen
class AnasLanguageSetupOverlay extends StatefulWidget {
  const AnasLanguageSetupOverlay({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.backgroundColor,
    this.textColor,
    this.showProgressIndicator = true,
  });

  /// The child widget (MaterialApp)
  final Widget child;

  /// Duration to show the loading screen
  final Duration duration;

  /// Background color of the overlay (defaults to system background)
  final Color? backgroundColor;

  /// Text color (defaults to system text color)
  final Color? textColor;

  /// Whether to show a progress indicator
  final bool showProgressIndicator;

  @override
  State<AnasLanguageSetupOverlay> createState() => _AnasLanguageSetupOverlayState();
}

class _AnasLanguageSetupOverlayState extends State<AnasLanguageSetupOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _textTransitionController;
  late Animation<double> _textFadeInAnimation;

  Locale? _previousLocale;
  bool _isShowingOverlay = false;
  String _loadingText = 'Setting up language...';
  String _currentPleaseWaitText = 'Please wait...';
  bool _isTransitioningText = false;

  // Static reference to allow external access
  static _AnasLanguageSetupOverlayState? _instance;

  @override
  void initState() {
    super.initState();
    _instance = this; // Set static instance
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _textTransitionController = AnimationController(
      duration: const Duration(milliseconds: 250), // 250ms for each fade (out then in)
      vsync: this,
    );

    _textFadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textTransitionController,
        curve: Curves.easeIn,
      ),
    );
  }

  // Static method to trigger language change from external widgets
  static void changeLanguage(Locale targetLocale) {
    _instance?._showLanguageSetupOverlay(targetLocale: targetLocale);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = AnasLocalization.of(context).locale;

    // Store the very first locale when widget is first built
    if (_previousLocale == null) {
      _previousLocale = currentLocale;
      return; // Don't trigger overlay on first build
    }

    // Remove the automatic triggering since we'll control it externally
    _previousLocale = currentLocale;
  }

  void _showLanguageSetupOverlay({required Locale targetLocale}) async {
    if (_isShowingOverlay) return;

    // Calculate timing based on input duration
    final totalDuration = widget.duration.inMilliseconds;
    final firstHalfDuration = (totalDuration * 0.4).round(); // 50% for showing current language
    final transitionDuration = (totalDuration * 0.25).round(); // 25% for fade out + 25% for fade in
    final remainingDuration = totalDuration - firstHalfDuration - (transitionDuration * 2);

    setState(() {
      _isShowingOverlay = true;
      _loadingText = _getLoadingText(); // Get current language text
      _currentPleaseWaitText = _getPleaseWaitText(); // Get current language text
      _isTransitioningText = false;
    });

    // Update text transition controller duration
    _textTransitionController.duration = Duration(milliseconds: transitionDuration);

    // Fade in the overlay
    await _fadeController.forward();

    // Wait to show the current language text (first half of duration)
    await Future.delayed(Duration(milliseconds: firstHalfDuration));

    // NOW UPDATE THE LOCALIZATION TO TARGET LANGUAGE AT HALFWAY POINT
    if (mounted) {
      // Update to target locale
      await AnasLocalization.of(context).setLocale(targetLocale);

      // Phase 1: Fade out current text
      setState(() {
        _isTransitioningText = true; // Start fade out
      });

      await _textTransitionController.forward(); // Fade out current text

      // Phase 2: Get new language text and fade in
      setState(() {
        _loadingText = _getLoadingText(); // Update loading text to new language
        _currentPleaseWaitText = _getPleaseWaitText(); // Get updated language text
      });

      _textTransitionController.reset(); // Reset for fade in
      await _textTransitionController.forward(); // Fade in new text

      // End transition
      setState(() {
        _isTransitioningText = false;
      });
    }

    // Wait for remaining duration
    if (remainingDuration > 0) {
      await Future.delayed(Duration(milliseconds: remainingDuration));
    }

    // Fade out the overlay
    await _fadeController.reverse();

    if (mounted) {
      setState(() {
        _isShowingOverlay = false;
        _isTransitioningText = false;
      });
    }
  }

  String _getLoadingText() {
    try {
      final dictionary = AnasLocalization.of(context).dictionary;
      // Try to get localized text with proper fallback
      return dictionary.getString('language_setting_up', fallback: 'Setting up language...');
    } catch (e) {
      return 'Setting up language...';
    }
  }

  String _getPleaseWaitText() {
    try {
      final dictionary = AnasLocalization.of(context).dictionary;
      // Try to get localized "please wait" text, fallback to English
      return dictionary.getString('please_wait', fallback: 'Please wait...');
    } catch (e) {
      return 'Please wait...';
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _textTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        alignment: Alignment.center, // Use non-directional alignment
        children: [
          // Main app content
          widget.child,

          // Loading overlay
          if (_isShowingOverlay)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: widget.backgroundColor ?? colorScheme.surface,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App icon or logo (optional)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: colorScheme.primary.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          Icons.translate,
                          size: 40,
                          color: colorScheme.primary,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Progress indicator
                      if (widget.showProgressIndicator)
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Loading text
                      Text(
                        _loadingText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: widget.textColor ?? colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Subtitle with animated text transition
                      SizedBox(
                        height: 20, // Fixed height to prevent layout shifts
                        child: Center(
                          child: _isTransitioningText
                              ? FadeTransition(
                                  opacity: _textFadeInAnimation,
                                  child: Text(
                                    _currentPleaseWaitText,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: (widget.textColor ?? colorScheme.onSurface).withValues(alpha: 0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : Text(
                                  _currentPleaseWaitText,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: (widget.textColor ?? colorScheme.onSurface).withValues(alpha: 0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A complete localization provider with language setup overlay
///
/// This widget shows a loading screen during language changes, similar to iPhone's setup screen
class AnasLocalizationWithSetup extends StatelessWidget {
  const AnasLocalizationWithSetup({
    super.key,
    required this.child,
    required this.fallbackLocale,
    required this.assetPath,
    required this.assetLocales,
    this.dictionaryFactory,
    this.setupDuration,
    this.enableSetupScreen = true,
    this.overlayBackgroundColor,
    this.overlayTextColor,
    this.showProgressIndicator = true,
  });

  /// The child widget (typically MaterialApp)
  final Widget child;

  /// Fallback locale if device locale is not supported
  final Locale fallbackLocale;

  /// Path to translation assets
  final String assetPath;

  /// List of supported locales
  final List<Locale> assetLocales;

  /// Optional dictionary factory for custom Dictionary classes
  final Dictionary Function(Map<String, dynamic>, {required String locale})? dictionaryFactory;

  /// Duration to show the setup screen
  /// Defaults to 1500ms for a realistic setup feel
  final Duration? setupDuration;

  /// Whether to show the setup screen (disable for testing)
  final bool enableSetupScreen;

  /// Background color of the setup overlay
  final Color? overlayBackgroundColor;

  /// Text color of the setup overlay
  final Color? overlayTextColor;

  /// Whether to show progress indicator
  final bool showProgressIndicator;

  // Default settings
  static const Duration _defaultSetupDuration = Duration(milliseconds: 1500);

  @override
  Widget build(BuildContext context) {
    return AnasLocalization(
      fallbackLocale: fallbackLocale,
      assetPath: assetPath,
      assetLocales: assetLocales,
      dictionaryFactory: dictionaryFactory,
      app: enableSetupScreen
          ? AnasLanguageSetupOverlay(
              duration: setupDuration ?? _defaultSetupDuration,
              backgroundColor: overlayBackgroundColor,
              textColor: overlayTextColor,
              showProgressIndicator: showProgressIndicator,
              child: child,
            )
          : child,
    );
  }
}
