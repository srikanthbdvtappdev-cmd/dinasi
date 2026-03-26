import 'language_provider.dart';

/// All UI strings in both Kannada and English.
/// Usage: AppStrings.of(languageProvider).someString
class AppStrings {
  final AppLanguage language;
  AppStrings(this.language);

  factory AppStrings.of(LanguageProvider p) => AppStrings(p.language);

  bool get _kn => language == AppLanguage.kannada;

  // ── App / Header ──────────────────────────────────────────────────────────
  String get appTitle => _kn ? 'ದಿನಸಿ' : 'Groceries';
  String get defaultListTitle => _kn ? 'Grocery List' : 'Grocery List';
  // ── Tab labels ───────────────────────────────────────────────────────────────────
  String get tabGroceries => _kn ? 'ದಿನಸಿ / ಮದ್ದು' : 'Groceries & Medicines';
  String get tabNotepad => _kn ? 'ಸ್ವತಂತ್ರ ಟಿಪ್ಪಣಿ' : 'Free Notes';
  // ── Header tooltips ───────────────────────────────────────────────────────
  String get tooltipPredefinedList => _kn ? 'ಪಟ್ಟಿ' : 'Item List';
  String get tooltipExport => _kn ? 'ರಫ್ತು ಮಾಡಿ' : 'Export';
  String get tooltipSaveList => _kn ? 'ಪಟ್ಟಿ ಉಳಿಸಿ' : 'Save List';
  String get tooltipSavedLists => _kn ? 'ಉಳಿಸಿದ ಪಟ್ಟಿಗಳು' : 'Saved Lists';
  String get tooltipClearAll => _kn ? 'ಎಲ್ಲ ಅಳಿಸಿ' : 'Clear All';
  String get tooltipLanguage => _kn ? 'Switch to English' : 'ಕನ್ನಡಕ್ಕೆ ಬದಲಿಸಿ';

  // ── Clear all dialog ──────────────────────────────────────────────────────
  String get clearAllTitle => _kn ? 'ಎಲ್ಲ ಅಳಿಸಿ?' : 'Clear All?';
  String get clearAllBody => _kn
      ? 'ಪಟ್ಟಿಯಲ್ಲಿರುವ ಎಲ್ಲ ವಸ್ತುಗಳನ್ನು ತೆಗೆಯಬೇಕೇ?'
      : 'Remove all items from the list?';
  String get btnCancel => _kn ? 'ಬೇಡ' : 'Cancel';
  String get btnDelete => _kn ? 'ಅಳಿಸಿ' : 'Delete';
  String get btnSave => _kn ? 'ಉಳಿಸಿ' : 'Save';
  String get btnAdd => _kn ? 'ಸೇರಿಸಿ' : 'Add';

  // ── Item count badge ──────────────────────────────────────────────────────
  String itemCount(int n) => _kn ? '$n ವಸ್ತುಗಳು' : '$n items';

  // ── Empty state ───────────────────────────────────────────────────────────
  String get emptyStateTitle => _kn ? 'ಪಟ್ಟಿ ಖಾಲಿ ಇದೆ' : 'List is empty';
  String get emptyStateSubtitle => _kn
      ? 'ಮೈಕ್ ಒತ್ತಿ ಕನ್ನಡದಲ್ಲಿ ಹೇಳಿ\nಅಥವಾ ಪಟ್ಟಿಯಿಂದ ಆರಿಸಿ'
      : 'Tap the mic and speak in English\nor choose from the item list';

  // ── Manual add ────────────────────────────────────────────────────────────
  String get btnAddItem => _kn ? '+ ಹೊಸ ವಸ್ತು ಸೇರಿಸಿ' : '+ Add new item';
  String get addItemTitle => _kn ? 'ಹೊಸ ವಸ್ತು' : 'New Item';
  String get fieldName => _kn ? 'ಹೆಸರು' : 'Name';
  String get fieldQuantity => _kn ? 'ಪ್ರಮಾಣ' : 'Quantity';
  String get addItemHint => _kn ? 'ಉದಾ: ಅಕ್ಕಿ' : 'e.g. Rice';

  // ── Snackbars ─────────────────────────────────────────────────────────────
  String get snackListEmpty => _kn
      ? 'ಪಟ್ಟಿ ಖಾಲಿ ಇದೆ — ಮೊದಲು ವಸ್ತುಗಳನ್ನು ಸೇರಿಸಿ'
      : 'List is empty — add items first';
  String listSaved(String name) =>
      _kn ? '"$name" ಪಟ್ಟಿ ಉಳಿಸಲಾಗಿದೆ' : 'List "$name" saved';

  // ── Save list dialog ──────────────────────────────────────────────────────
  String get saveListTitle => _kn ? 'ಪಟ್ಟಿ ಉಳಿಸಿ' : 'Save List';
  String get saveListLabel => _kn ? 'ಪಟ್ಟಿಯ ಹೆಸರು' : 'List name';

  // ── Export sheet ──────────────────────────────────────────────────────────
  String get exportTitle => _kn ? 'ರಫ್ತು ಮಾಡಿ' : 'Export';
  String exportSubtitle(int n) => _kn ? '$n ವಸ್ತುಗಳ ಪಟ್ಟಿ' : '$n item list';
  String get exportPdfTitle => _kn ? 'PDF ಆಗಿ' : 'As PDF';
  String get exportPdfSubtitle =>
      _kn ? 'ಪಟ್ಟಿಯನ್ನು PDF ರೂಪದಲ್ಲಿ ಶೇರ್ ಮಾಡಿ' : 'Share the list as a PDF';
  String get exportImageTitle => _kn ? 'ಚಿತ್ರವಾಗಿ' : 'As Image';
  String get exportImageSubtitle => _kn
      ? 'ಪಿಕ್ಚರ್ (PNG) ರೂಪದಲ್ಲಿ ಶೇರ್ ಮಾಡಿ'
      : 'Share the list as a picture (PNG)';

  // ── Edit item dialog ──────────────────────────────────────────────────────
  String get editItemTitle => _kn ? 'ಪಟ್ಟಿ ಬದಲಾಯಿಸಿ' : 'Edit Item';
  String get editItemNameLabel => _kn ? 'ವಸ್ತುವಿನ ಹೆಸರು' : 'Item name';

  // ── Predefined items sheet ────────────────────────────────────────────────
  String get predefinedSheetTitle => _kn ? 'ಪಟ್ಟಿಯಲ್ಲಿ ಸೇರಿಸಿ' : 'Add to List';
  String get predefinedAddNew => _kn ? 'ಹೊಸದು' : 'New';
  String get predefinedSearchHint => _kn ? 'ಹುಡುಕಿ / Search...' : 'Search...';
  String get predefinedNoResults => _kn ? 'ಯಾವುದೂ ಸಿಗಲಿಲ್ಲ' : 'Nothing found';
  String get predefinedAddNewItem => _kn ? 'ಹೊಸ ವಸ್ತು ಸೇರಿಸಿ' : 'Add new item';
  String get predefinedAddDialogTitle =>
      _kn ? 'ಹೊಸ ವಸ್ತು ಸೇರಿಸಿ' : 'Add New Item';
  String get predefinedKannadaLabel => _kn ? 'ಕನ್ನಡ ಹೆಸರು *' : 'Kannada name *';
  String get predefinedKannadaHint => _kn ? 'ಉದಾ: ಶ್ಯಾವಿಗೆ' : 'e.g. ಶ್ಯಾವಿಗೆ';
  String get predefinedEnglishLabel =>
      _kn ? 'English name (optional)' : 'English name (optional)';
  String get predefinedEnglishHint =>
      _kn ? 'e.g. Vermicelli' : 'e.g. Vermicelli';
  String get predefinedDefaultUnit => _kn ? 'Default unit: ' : 'Default unit: ';
  String get predefinedDuplicate =>
      _kn ? 'ಈ ಹೆಸರು ಈಗಾಗಲೇ ಇದೆ' : 'This name already exists';
  String predefinedAddedToList(String name) => _kn
      ? 'ಪೂರ್ವನಿರ್ಧಾರಿತ ಪಟ್ಟಿಗೆ ಸೇರಿಸಲಾಗಿದೆ: $name'
      : 'Added "$name" to the item list';
  String get predefinedAddedToCart =>
      _kn ? 'ಪಟ್ಟಿಗೆ ಸೇರಿಸಲಾಗಿದೆ' : 'Added to list';
  String predefinedAddedItem(String name) =>
      _kn ? 'ಪಟ್ಟಿಗೆ ಸೇರಿಸಲಾಗಿದೆ: $name' : 'Added to list: $name';
  String get predefinedInCart => _kn ? 'ಪಟ್ಟಿಯಲ್ಲಿದೆ' : 'In list';
  String get predefinedBtnAddAnother => _kn ? '+ ಸೇರಿಸಿ' : '+ Add';
  String get predefinedBtnAddMore => _kn ? ' ಮತ್ತೊಂದು' : ' more';
  String get predefinedDeleteTooltip => _kn ? 'ತೆಗೆದುಹಾಕು' : 'Remove';

  // ── Saved lists sheet ─────────────────────────────────────────────────────
  String savedListsTitle(int n) =>
      _kn ? 'ಉಳಿಸಿದ ಪಟ್ಟಿಗಳು ($n)' : 'Saved Lists ($n)';
  String savedListsCount(int n) =>
      _kn ? '$n ಪಟ್ಟಿ' : '$n list${n == 1 ? '' : 's'}';
  String get savedListsEmpty =>
      _kn ? 'ಯಾವುದೇ ಪಟ್ಟಿ ಉಳಿಸಿಲ್ಲ' : 'No saved lists yet';
  String get savedListsEmptyHint => _kn
      ? 'ಪಟ್ಟಿ ತಯಾರಿಸಿ ಮತ್ತು ಉಳಿಸಿ ಬಟನ್ ಒತ್ತಿ'
      : 'Build a list and tap the Save button';
  String get savedListsRestoreTitle =>
      _kn ? 'ಪಟ್ಟಿ ತರೋಣವೇ?' : 'Load this list?';
  String savedListsRestoreBody(String name) => _kn
      ? '"$name" ಪಟ್ಟಿ ತಂದರೆ ಈಗಿನ ಪಟ್ಟಿ ಅಳಿಯುತ್ತದೆ.'
      : 'Loading "$name" will replace your current list.';
  String get savedListsRestoreBtn => _kn ? 'ತರಿಸಿ' : 'Load';
  String get savedListsDeleteTitle => _kn ? 'ಅಳಿಸಬೇಕೇ?' : 'Delete?';
  String savedListsDeleteBody(String name) => _kn
      ? '"$name" ಪಟ್ಟಿ ಶಾಶ್ವತವಾಗಿ ತೆಗೆಯಬೇಕೇ?'
      : 'Permanently remove "$name"?';
  String get savedListsExportJson =>
      _kn ? 'JSON ಆಗಿ ರಫ್ತು ಮಾಡಿ' : 'Export as JSON';
  String get savedListsImportJson =>
      _kn ? 'JSON ಫೈಲ್ ಆಮದು ಮಾಡಿ' : 'Import JSON';
  String savedListsImportSuccess(String name) =>
      _kn ? '"$name" ಆಮದು ಮಾಡಲಾಗಿದೆ' : '"$name" imported successfully';
  String get savedListsImportFailed => _kn
      ? 'ಆಮದು ವಿಫಲವಾಯಿತು — ಫೈಲ್ ಪರಿಶೀಲಿಸಿ'
      : 'Import failed — check the file and try again';

  // ── Date labels ───────────────────────────────────────────────────────────
  String get dateToday => _kn ? 'ಇಂದು' : 'Today';
  String get dateYesterday => _kn ? 'ನಿನ್ನೆ' : 'Yesterday';
  String daysAgo(int n) => _kn ? '$n ದಿನಗಳ ಹಿಂದೆ' : '$n days ago';

  // ── Smart suggestions ─────────────────────────────────────────────────────
  String get smartSuggestions => _kn ? 'ಸ್ಮಾರ್ಟ್ ಸಲಹೆ' : 'Smart Picks';

  // ── Voice mic ─────────────────────────────────────────────────────────────
  String get micTapToSpeak => _kn ? 'ಮಾತನಾಡಲು ಮೈಕ್ ಒತ್ತಿ' : 'Tap mic to speak';
  String get micListening => _kn ? 'ಕೇಳುತ್ತಿದ್ದೇನೆ...' : 'Listening...';
  String get micUnavailable =>
      _kn ? 'ಧ್ವನಿ ಗುರುತಿಸುವಿಕೆ ಲಭ್ಯವಿಲ್ಲ' : 'Speech recognition unavailable';

  // ── Export widget (off-screen render) ────────────────────────────────────
  String get exportColItem => _kn ? 'ವಸ್ತು' : 'Item';
  String get exportColQty => _kn ? 'ಪ್ರಮಾಣ' : 'Qty';
  String get exportFooter => _kn ? 'ದಿನಸಿ App' : 'Dinasi App';

  // ── Notepad screen ────────────────────────────────────────────────────────
  String get notepadTitle => _kn ? 'ಟಿಪ್ಪಣಿ' : 'Notepad';
  String get notepadPageTooltip => _kn ? 'ಟಿಪ್ಪಣಿ' : 'Notepad';
  String get notepadHint => _kn
      ? 'ಇಲ್ಲಿ ಏನಾದರೂ ಬರೆಯಿರಿ ಅಥವಾ ಮಾತನಾಡಿ...'
      : 'Write anything here or tap the mic to speak...';
  String get notepadSaveTooltip => _kn ? 'ಟಿಪ್ಪಣಿ ಉಳಿಸಿ' : 'Save note';
  String get notepadSavedNotesTooltip =>
      _kn ? 'ಉಳಿಸಿದ ಟಿಪ್ಪಣಿಗಳು' : 'Saved notes';
  String get notepadClearTooltip => _kn ? 'ಅಳಿಸಿ' : 'Clear pad';
  String get notepadSaveTitle => _kn ? 'ಟಿಪ್ಪಣಿ ಉಳಿಸಿ' : 'Save Note';
  String get notepadTitleLabel => _kn ? 'ಶೀರ್ಷಿಕೆ' : 'Title';
  String notepadSaved(String title) =>
      _kn ? '"$title" ಉಳಿಸಲಾಗಿದೆ' : '"$title" saved';
  String get notepadEmptySnack =>
      _kn ? 'ಏನಾದರೂ ಬರೆಯಿರಿ ಮೊದಲು' : 'Nothing to save — write something first';
  String get notepadClearTitle => _kn ? 'ಅಳಿಸಬೇಕೇ?' : 'Clear pad?';
  String get notepadClearBody =>
      _kn ? 'ಎಲ್ಲ ಬರಹ ತೆಗೆಯಬೇಕೇ?' : 'Remove all text from the notepad?';
  String notepadSavedTitle(int n) =>
      _kn ? 'ಉಳಿಸಿದ ಟಿಪ್ಪಣಿಗಳು ($n)' : 'Saved Notes ($n)';
  String get notepadNoNotes =>
      _kn ? 'ಯಾವುದೇ ಟಿಪ್ಪಣಿ ಇಲ್ಲ' : 'No saved notes yet';
  String get notepadDismissKeyboard =>
      _kn ? 'ಕೀಬೋರ್ಡ್ ಮುಚ್ಚಿ' : 'Dismiss keyboard';
  String get notepadLoadTooltip => _kn ? 'ಲೋಡ್ ಮಾಡಿ' : 'Load';
  String get notepadDeleteTooltip => _kn ? 'ತೆಗೆದುಹಾಕು' : 'Delete';
  String get notepadDrawMode => _kn ? 'ಚಿತ್ರಿಸಿ' : 'Draw';
  String get notepadTextMode => _kn ? 'ಬರೆಯಿರಿ' : 'Text';
  String get notepadClearDrawing => _kn ? 'ಚಿತ್ರ ಅಳಿಸಿ' : 'Clear drawing';
  String get notepadClearDrawingTitle =>
      _kn ? 'ಚಿತ್ರ ಅಳಿಸಬೇಕೇ?' : 'Clear drawing?';
  String get notepadClearDrawingBody =>
      _kn ? 'ಎಲ್ಲ ಚಿತ್ರ ತೆಗೆಯಬೇಕೇ?' : 'Remove all strokes from the canvas?';
  String get notepadUndoStroke => _kn ? 'ರದ್ದು' : 'Undo';
}
