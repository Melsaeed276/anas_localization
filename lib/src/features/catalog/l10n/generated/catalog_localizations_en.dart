// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'catalog_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class CatalogLocalizationsEn extends CatalogLocalizations {
  CatalogLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Anas Catalog';

  @override
  String get refresh => 'Refresh';

  @override
  String get newString => 'New String';

  @override
  String get createNewString => 'Create New String';

  @override
  String get createNewStringSubtitle =>
      'Source locale goes first. Filled target locales still need review until marked Done.';

  @override
  String get keyPathLabel => 'Key path';

  @override
  String get keyPathHint => 'checkout.summary.title';

  @override
  String get noteLabel => 'Key note';

  @override
  String get noteHint => 'Add translator or reviewer context';

  @override
  String get create => 'Create';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get catalogLanguage => 'Catalog Language';

  @override
  String get searchLabel => 'Search';

  @override
  String get searchHint => 'Search keys, values, or notes';

  @override
  String get filterAll => 'All';

  @override
  String get filterReady => 'Ready';

  @override
  String get filterNeedsReview => 'Needs review';

  @override
  String get filterMissing => 'Missing';

  @override
  String get keysLabel => 'keys';

  @override
  String get readyRowsLabel => 'ready rows';

  @override
  String get reviewRowsLabel => 'review rows';

  @override
  String get missingRowsLabel => 'missing rows';

  @override
  String get noKeys => 'No keys found.';

  @override
  String get noSelection => 'Select a key to start editing.';

  @override
  String get sourceLabel => 'Source';

  @override
  String get sourceImpact => 'Source locale';

  @override
  String get sourceImpactBody => 'Editing the source reopens review for target locales.';

  @override
  String get editorLabel => 'Editor';

  @override
  String get done => 'Done';

  @override
  String get deleteKey => 'Delete Key';

  @override
  String get deleteValue => 'Delete Value';

  @override
  String get advancedJson => 'Advanced JSON';

  @override
  String get advancedJsonHelp => 'Use raw JSON for unsupported shapes.';

  @override
  String get syncClean => 'Synced';

  @override
  String get syncDirty => 'Unsaved';

  @override
  String get syncSaving => 'Saving';

  @override
  String get syncSaved => 'Saved';

  @override
  String get syncError => 'Save failed';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusNeedsReview => 'Needs review';

  @override
  String get statusMissing => 'Missing';

  @override
  String get reasonSourceChanged => 'Source changed';

  @override
  String get reasonSourceAdded => 'Source added';

  @override
  String get reasonSourceDeleted => 'Source deleted';

  @override
  String get reasonSourceDeletedReviewRequired => 'Source deleted, review required';

  @override
  String get reasonTargetMissing => 'Target missing';

  @override
  String get reasonNewKeyNeedsReview => 'New key needs review';

  @override
  String get reasonTargetUpdatedNeedsReview => 'Target updated, needs review';

  @override
  String get blockerTranslationEmpty => 'Translation is empty.';

  @override
  String get blockerWaitAutosave => 'Wait for autosave to finish.';

  @override
  String get blockerFillBranches => 'Fill every visible branch before marking Done.';

  @override
  String get blockerMissingPlaceholders => 'Missing placeholders';

  @override
  String get typeWarningTitle => 'Type warning (optional)';

  @override
  String get notesSection => 'Notes';

  @override
  String get backLabel => 'Back';

  @override
  String get loading => 'Loading catalog…';

  @override
  String get retry => 'Retry';

  @override
  String get pendingLabel => 'Pending';

  @override
  String get missingLabel => 'Missing';

  @override
  String get allTargetsReady => 'All target locales are ready.';

  @override
  String get reviewed => 'Reviewed';

  @override
  String get optionalValueLabel => 'Optional initial value';

  @override
  String get addBranchLabel => 'Add branch';

  @override
  String get saveFailed => 'Save failed';

  @override
  String get selectLocaleLabel => 'Locale';

  @override
  String get displayOnlyLabel => 'Display only';

  @override
  String get invalidKeyPath => 'Enter a valid dotted key path.';

  @override
  String get confirmCreateWithoutSource => 'Create this key without a source value?';

  @override
  String get deleteKeyConfirmation => 'Delete this key from all locales?';

  @override
  String get deleteSourceValueConfirmation => 'Delete the source value?';

  @override
  String get deleteLocaleValueConfirmation => 'Delete this locale value?';

  @override
  String get translationLabel => 'Translation';

  @override
  String get sourcePreviewLabel => 'Source preview';

  @override
  String get noteIndicator => 'Has note';

  @override
  String get noNote => 'No note yet.';

  @override
  String get bootstrapError => 'Could not load catalog bootstrap.';

  @override
  String get noteSaved => 'Note saved';

  @override
  String get noteAutosave => 'Notes autosave after a short delay.';

  @override
  String get queueTitle => 'Translation Queue';

  @override
  String get sortLabel => 'Sort';

  @override
  String get sortAlphabetical => 'A-Z';

  @override
  String get sortNamespace => 'Namespace';

  @override
  String get noKeysTitle => 'No catalog keys yet';

  @override
  String get noKeysBody => 'Create the first string to start the translation queue.';

  @override
  String get noResultsTitle => 'No matching keys';

  @override
  String get noResultsBody => 'Try a different search or clear the active filters.';

  @override
  String get selectionPlaceholderTitle => 'Choose a key';

  @override
  String get selectionPlaceholderBody => 'Select a queue item to inspect notes, source context, locales, and activity.';

  @override
  String get sectionEmpty => 'No keys in this section.';

  @override
  String get overviewSection => 'Overview';

  @override
  String get sourceContextSection => 'Source Context';

  @override
  String get localesSection => 'Locales';

  @override
  String get detailsSection => 'Details';

  @override
  String get contextSection => 'Catalog Context';

  @override
  String get activitySection => 'Activity';

  @override
  String get namespaceLabel => 'Namespace';

  @override
  String localeProgress(int ready, int total) {
    return '$ready of $total target locales ready';
  }

  @override
  String get placeholdersLabel => 'Placeholders';

  @override
  String get noPlaceholders => 'No placeholders in the source value.';

  @override
  String get reviewPendingLocales => 'Review pending locales';

  @override
  String reviewPendingSuccess(int count) {
    return 'Reviewed $count pending locales.';
  }

  @override
  String get sourceLocaleMeta => 'Source locale';

  @override
  String get fallbackLocaleMeta => 'Fallback locale';

  @override
  String get formatMeta => 'Format';

  @override
  String get stateFileMeta => 'State file';

  @override
  String get activityEmpty => 'No activity yet for this key.';

  @override
  String get activityKeyCreated => 'Key created';

  @override
  String get activitySourceUpdated => 'Source updated';

  @override
  String get activityTargetUpdated => 'Translation updated';

  @override
  String get activityNoteUpdated => 'Note updated';

  @override
  String get activityLocaleReviewed => 'Locale marked done';

  @override
  String get activityValueDeleted => 'Value deleted';

  @override
  String get projectLocales => 'Project Locales';

  @override
  String get defaultLabel => 'Default';

  @override
  String get changeDefaultLocale => 'Change Default';

  @override
  String get deleteLocale => 'Delete';

  @override
  String get addNewLocale => 'Add New Locale';

  @override
  String get cannotDeleteDefaultLocale => 'Cannot delete the default locale.';

  @override
  String confirmDeleteLocale(String locale) {
    return 'Delete locale \"$locale\"?';
  }

  @override
  String get localeCodeHint => 'Enter locale code (e.g., fr, de, zh_CN)';

  @override
  String get invalidLocaleCode => 'Invalid locale code. Use format like \"en\", \"en_US\", or \"zh_CN\".';

  @override
  String localeAlreadyExists(String locale) {
    return 'Locale \"$locale\" already exists.';
  }

  @override
  String get selectDefaultLocale => 'Select Default Locale';
}
