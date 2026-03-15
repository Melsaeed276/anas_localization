// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'catalog_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class CatalogLocalizationsEs extends CatalogLocalizations {
  CatalogLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Catálogo Anas';

  @override
  String get refresh => 'Actualizar';

  @override
  String get newString => 'Nueva Cadena';

  @override
  String get createNewString => 'Crear Nueva Cadena';

  @override
  String get createNewStringSubtitle =>
      'El idioma fuente va primero. Los idiomas de destino completos siguen necesitando revisión hasta marcar Hecho.';

  @override
  String get keyPathLabel => 'Ruta de clave';

  @override
  String get keyPathHint => 'checkout.summary.title';

  @override
  String get noteLabel => 'Nota de la clave';

  @override
  String get noteHint => 'Agrega contexto para traductores o revisores';

  @override
  String get create => 'Crear';

  @override
  String get confirm => 'Confirmar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get themeLabel => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get catalogLanguage => 'Idioma del Catálogo';

  @override
  String get searchLabel => 'Buscar';

  @override
  String get searchHint => 'Buscar claves, valores o notas';

  @override
  String get filterAll => 'Todo';

  @override
  String get filterReady => 'Listo';

  @override
  String get filterNeedsReview => 'Necesita revisión';

  @override
  String get filterMissing => 'Falta';

  @override
  String get keysLabel => 'claves';

  @override
  String get readyRowsLabel => 'filas listas';

  @override
  String get reviewRowsLabel => 'filas en revisión';

  @override
  String get missingRowsLabel => 'filas faltantes';

  @override
  String get noKeys => 'No se encontraron claves.';

  @override
  String get noSelection => 'Selecciona una clave para empezar a editar.';

  @override
  String get sourceLabel => 'Origen';

  @override
  String get sourceImpact => 'Idioma fuente';

  @override
  String get sourceImpactBody => 'Editar la fuente vuelve a abrir la revisión de los idiomas objetivo.';

  @override
  String get editorLabel => 'Editor';

  @override
  String get done => 'Hecho';

  @override
  String get deleteKey => 'Eliminar Clave';

  @override
  String get deleteValue => 'Eliminar Valor';

  @override
  String get advancedJson => 'JSON Avanzado';

  @override
  String get advancedJsonHelp => 'Usa JSON sin procesar para formas no compatibles.';

  @override
  String get syncClean => 'Sincronizado';

  @override
  String get syncDirty => 'Sin guardar';

  @override
  String get syncSaving => 'Guardando';

  @override
  String get syncSaved => 'Guardado';

  @override
  String get syncError => 'Error al guardar';

  @override
  String get statusReady => 'Listo';

  @override
  String get statusNeedsReview => 'Necesita revisión';

  @override
  String get statusMissing => 'Falta';

  @override
  String get reasonSourceChanged => 'La fuente cambió';

  @override
  String get reasonSourceAdded => 'La fuente fue agregada';

  @override
  String get reasonSourceDeleted => 'La fuente fue eliminada';

  @override
  String get reasonSourceDeletedReviewRequired => 'La fuente fue eliminada, se requiere revisión';

  @override
  String get reasonTargetMissing => 'Falta el destino';

  @override
  String get reasonNewKeyNeedsReview => 'La nueva clave necesita revisión';

  @override
  String get reasonTargetUpdatedNeedsReview => 'El destino fue actualizado y necesita revisión';

  @override
  String get blockerTranslationEmpty => 'La traducción está vacía.';

  @override
  String get blockerWaitAutosave => 'Espera a que termine el autoguardado.';

  @override
  String get blockerFillBranches => 'Completa todas las ramas visibles antes de marcar Hecho.';

  @override
  String get blockerMissingPlaceholders => 'Marcadores faltantes';

  @override
  String get typeWarningTitle => 'Aviso de tipo (opcional)';

  @override
  String get notesSection => 'Notas';

  @override
  String get backLabel => 'Atrás';

  @override
  String get loading => 'Cargando catálogo…';

  @override
  String get retry => 'Reintentar';

  @override
  String get pendingLabel => 'Pendiente';

  @override
  String get missingLabel => 'Falta';

  @override
  String get allTargetsReady => 'Todos los idiomas objetivo están listos.';

  @override
  String get reviewed => 'Revisado';

  @override
  String get optionalValueLabel => 'Valor inicial opcional';

  @override
  String get addBranchLabel => 'Agregar rama';

  @override
  String get saveFailed => 'Error al guardar';

  @override
  String get selectLocaleLabel => 'Idioma';

  @override
  String get displayOnlyLabel => 'Solo visualización';

  @override
  String get invalidKeyPath => 'Ingresa una ruta de clave válida con puntos.';

  @override
  String get confirmCreateWithoutSource => '¿Crear esta clave sin valor fuente?';

  @override
  String get deleteKeyConfirmation => '¿Eliminar esta clave de todos los idiomas?';

  @override
  String get deleteSourceValueConfirmation => '¿Eliminar el valor fuente?';

  @override
  String get deleteLocaleValueConfirmation => '¿Eliminar este valor del idioma?';

  @override
  String get translationLabel => 'Traducción';

  @override
  String get sourcePreviewLabel => 'Vista previa de origen';

  @override
  String get noteIndicator => 'Tiene nota';

  @override
  String get noNote => 'Aún no hay nota.';

  @override
  String get bootstrapError => 'No se pudo cargar el inicio del catálogo.';

  @override
  String get noteSaved => 'Nota guardada';

  @override
  String get noteAutosave => 'Las notas se guardan automáticamente después de un breve retraso.';

  @override
  String get queueTitle => 'Cola de traducción';

  @override
  String get sortLabel => 'Ordenar';

  @override
  String get sortAlphabetical => 'A-Z';

  @override
  String get sortNamespace => 'Espacio';

  @override
  String get noKeysTitle => 'Aún no hay claves';

  @override
  String get noKeysBody => 'Crea la primera cadena para iniciar la cola de traducción.';

  @override
  String get noResultsTitle => 'No hay claves coincidentes';

  @override
  String get noResultsBody => 'Prueba otra búsqueda o limpia los filtros activos.';

  @override
  String get selectionPlaceholderTitle => 'Elige una clave';

  @override
  String get selectionPlaceholderBody =>
      'Selecciona un elemento de la cola para revisar notas, contexto fuente, idiomas y actividad.';

  @override
  String get sectionEmpty => 'No hay claves en esta sección.';

  @override
  String get overviewSection => 'Resumen';

  @override
  String get sourceContextSection => 'Contexto fuente';

  @override
  String get localesSection => 'Idiomas';

  @override
  String get detailsSection => 'Detalles';

  @override
  String get contextSection => 'Contexto del catálogo';

  @override
  String get activitySection => 'Actividad';

  @override
  String get namespaceLabel => 'Espacio';

  @override
  String localeProgress(int ready, int total) {
    return '$ready de $total idiomas de destino listos';
  }

  @override
  String get placeholdersLabel => 'Marcadores';

  @override
  String get noPlaceholders => 'No hay marcadores en el valor fuente.';

  @override
  String get reviewPendingLocales => 'Revisar idiomas pendientes';

  @override
  String reviewPendingSuccess(int count) {
    return 'Se revisaron $count idiomas pendientes.';
  }

  @override
  String get sourceLocaleMeta => 'Idioma fuente';

  @override
  String get fallbackLocaleMeta => 'Idioma de respaldo';

  @override
  String get formatMeta => 'Formato';

  @override
  String get stateFileMeta => 'Archivo de estado';

  @override
  String get activityEmpty => 'Todavía no hay actividad para esta clave.';

  @override
  String get activityKeyCreated => 'Clave creada';

  @override
  String get activitySourceUpdated => 'Fuente actualizada';

  @override
  String get activityTargetUpdated => 'Traducción actualizada';

  @override
  String get activityNoteUpdated => 'Nota actualizada';

  @override
  String get activityLocaleReviewed => 'Idioma marcado como listo';

  @override
  String get activityValueDeleted => 'Valor eliminado';
}
