// Kannada voice processing - parse spoken Kannada into grocery items
// All processing is done locally with no API calls.
import '../models/grocery_item.dart';

class KannadaVoiceParser {
  /// Map of Kannada number words to their numeric values
  static const Map<String, double> _kannadaNumbers = {
    // ── Canonical written forms ───────────────────────────────────────────
    'ಒಂದು': 1, 'ಎರಡು': 2, 'ಮೂರು': 3, 'ನಾಲ್ಕು': 4, 'ಐದು': 5,
    'ಆರು': 6, 'ಏಳು': 7, 'ಎಂಟು': 8, 'ಒಂಬತ್ತು': 9, 'ಹತ್ತು': 10,
    'ಹನ್ನೊಂದು': 11, 'ಹನ್ನೆರಡು': 12, 'ಹದಿಮೂರು': 13, 'ಹದಿನಾಲ್ಕು': 14,
    'ಹದಿನೈದು': 15, 'ಹದಿನಾರು': 16, 'ಹದಿನೇಳು': 17, 'ಹದಿನೆಂಟು': 18,
    'ಹತ್ತೊಂಬತ್ತು': 19, 'ಇಪ್ಪತ್ತು': 20, 'ಇಪ್ಪತ್ತೈದು': 25,
    'ಮೂವತ್ತು': 30, 'ನಲವತ್ತು': 40, 'ಐವತ್ತು': 50,
    'ಅರವತ್ತು': 60, 'ಎಪ್ಪತ್ತು': 70, 'ಎಂಭತ್ತು': 80, 'ತೊಂಬತ್ತು': 90,
    'ನೂರು': 100, 'ಅರ್ಧ': 0.5, 'ಕಾಲು': 0.25,

    // ── Spoken / colloquial alternates (final vowel dropped) ──────────────
    'ಒಂದ್': 1, 'ಎರಡ್': 2, 'ಮೂರ್': 3, 'ನಾಲ್ಕ್': 4, 'ಐದ್': 5,
    'ಆರ್': 6, 'ಏಳ್': 7, 'ಎಂಟ್': 8,
    'ಒಂಬತ್': 9, // ಒಂಬತ್ತು → ಒಂಬತ್
    'ಹತ್': 10, // ಹತ್ತು  → ಹತ್
    'ಇಪ್ಪತ್': 20, // ಇಪ್ಪತ್ತು → ಇಪ್ಪತ್
    'ಮೂವತ್': 30, 'ಮೂವತ': 30, // ಮೂವತ್ತು → ಮೂವತ್ / ಮೂವತ
    'ನಲವತ್': 40, 'ನಲ್ಪತ್ತು': 40, 'ನಲ್ಪತ್': 40, // ನಲವತ್ತು variants
    'ಐವತ್': 50, // ಐವತ್ತು → ಐವತ್
    'ಅರವತ್': 60, // ಅರವತ್ತು → ಅರವತ್
    'ಎಪ್ಪತ್': 70, // ಎಪ್ಪತ್ತು → ಎಪ್ಪತ್
    'ಎಂಭತ್': 80, 'ಎಂಬತ್ತು': 80, 'ಎಂಬತ್': 80, // ಎಂಭತ್ತು variants
    'ತೊಂಬತ್': 90, // ತೊಂಬತ್ತು → ತೊಂಬತ್
    'ನೂರ್': 100,
    'ನೂರ': 100, // STT drops the final ು
    // ── Teen alternate spellings ──────────────────────────────────────────
    'ಹದ್ನೊಂದು': 11, 'ಹದ್ನೆರಡು': 12,
    'ಹದ್ನೈದು': 15, 'ಹದ್ನಾರು': 16,
    'ಹತ್ತೊಂಬತ್': 19,

    // ── Common compound quantities (1½, 2½ …) ────────────────────────────
    'ಒಂದೂವರೆ': 1.5, 'ಒಂದೂ ವರೆ': 1.5,
    'ಎರಡೂವರೆ': 2.5, 'ಎರಡೂ ವರೆ': 2.5,
    'ಮೂರೂವರೆ': 3.5, 'ಮೂರ್ ವರೆ': 3.5,
    'ನಾಲ್ಕೂವರೆ': 4.5, 'ಐದೂವರೆ': 5.5,

    // ── Kannada digit glyphs ──────────────────────────────────────────────
    '೧': 1, '೨': 2, '೩': 3, '೪': 4, '೫': 5,
    '೬': 6, '೭': 7, '೮': 8, '೯': 9, '೧೦': 10,
    '೨೦': 20, '೩೦': 30, '೪೦': 40, '೫೦': 50,
    '೬೦': 60, '೭೦': 70, '೮೦': 80, '೯೦': 90, '೧೦೦': 100,

    // ── Transliterated (Latin) forms — STT sometimes returns these ────────
    'ondu': 1, 'ond': 1,
    'eradu': 2, 'erdu': 2, 'iradu': 2,
    'mooru': 3, 'muru': 3,
    'nalku': 4, 'naaku': 4, 'naalu': 4, 'naalku': 4,
    'aidhu': 5, 'aidu': 5, 'aydu': 5, 'idu': 5,
    'aaru': 6, 'aru': 6,
    'ezhu': 7, 'yelu': 7, 'ezlu': 7, 'elu': 7,
    'entu': 8, 'ettu': 8,
    'ombattu': 9, 'ombotto': 9, 'ombuttu': 9,
    'hattu': 10, 'hatu': 10, 'pattu': 10,
    'nuru': 100, 'nooru': 100,
    'ardha': 0.5, 'artha': 0.5,
    'kaalu': 0.25, 'kaal': 0.25,
  };

  /// Unit keywords in Kannada
  static const Map<String, Unit> _unitKeywords = {
    // ── Kannada script ────────────────────────────────────────────────────
    'ಕೆ.ಜಿ': Unit.kg,
    'ಕೇಜಿ': Unit.kg,
    'ಕೆಜಿ': Unit.kg, // short-e variant — STT commonly returns this
    'ಕಿ.ಗ್ರಾ': Unit.kg,
    'ಕಿಲೋ': Unit.kg,
    'ಗ್ರಾಂ': Unit.g,
    'ಗ್ರಾಮ್': Unit.g,
    'ಗ್ರಾಮ': Unit.g, // STT drops the final ್ virama
    'ಗ್ರಾ': Unit.g, // abbreviated form
    'ಲೀಟರ್': Unit.L,
    'ಲೀಟರ': Unit.L,
    'ಲೀಟ': Unit.L, // abbreviated STT form
    'ಮಿಲಿ': Unit.mL,
    'ಮಿ.ಲಿ': Unit.mL,
    'ಮಿಲಿಲೀಟರ್': Unit.mL,
    'ತುಂಡು': Unit.pcs,
    'ಪಿಸ್': Unit.pcs,
    'ಸಂಖ್ಯೆ': Unit.pcs,
    'ಡಜನ್': Unit.dozen,
    'ಡಜನ': Unit.dozen,
    'ಗೊಂಚಲು': Unit.bunch,
    'ಗುಚ್ಛ': Unit.bunch,
    'ಪ್ಯಾಕ್': Unit.pack,
    'ಪ್ಯಾಕೇಟ್': Unit.pack,
    // ── Latin script — STT commonly returns metric units in Latin ─────────
    'kilograms': Unit.kg,
    'kilogram': Unit.kg,
    'kilos': Unit.kg,
    'kilo': Unit.kg,
    'kgs': Unit.kg,
    'kg': Unit.kg,
    'grams': Unit.g,
    'gram': Unit.g,
    'gms': Unit.g,
    'gm': Unit.g,
    'litres': Unit.L,
    'liters': Unit.L,
    'litre': Unit.L,
    'liter': Unit.L,
    'milliliters': Unit.mL,
    'millilitres': Unit.mL,
    'milliliter': Unit.mL,
    'millilitre': Unit.mL,
    'ml': Unit.mL,
    'pieces': Unit.pcs,
    'piece': Unit.pcs,
    'pcs': Unit.pcs,
    'pc': Unit.pcs,
    'nos': Unit.pcs,
    'dozens': Unit.dozen,
    'dozen': Unit.dozen,
    'bunches': Unit.bunch,
    'bunch': Unit.bunch,
    'packets': Unit.pack,
    'packet': Unit.pack,
    'packs': Unit.pack,
    'pack': Unit.pack,
  };

  /// Known grocery items (Kannada name → default unit)
  static const Map<String, Unit> _knownItems = {
    'ಅಕ್ಕಿ': Unit.kg,
    'ರಾಗಿ': Unit.kg,
    'ಗೋಧಿ': Unit.kg,
    'ಜೋಳ': Unit.kg,
    'ಅವಲಕ್ಕಿ': Unit.kg,
    'ತೊಗರಿ ಬೇಳೆ': Unit.kg,
    'ತೊಗರಿಬೇಳೆ': Unit.kg,
    'ಕಡಲೆ ಬೇಳೆ': Unit.kg,
    'ಉದ್ದಿನ ಬೇಳೆ': Unit.kg,
    'ಮೂಂಗ ಬೇಳೆ': Unit.kg,
    'ಹೆಸರು ಕಾಳು': Unit.kg,
    'ಆಲೂಗಡ್ಡೆ': Unit.kg,
    'ಈರುಳ್ಳಿ': Unit.kg,
    'ಟೊಮೇಟೊ': Unit.kg,
    'ಟೊಮಾಟೊ': Unit.kg,
    'ಕ್ಯಾರೆಟ್': Unit.kg,
    'ಬೀನ್ಸ್': Unit.kg,
    'ಬದನೆಕಾಯಿ': Unit.kg,
    'ಬೆಂಡೆಕಾಯಿ': Unit.kg,
    'ಶುಂಠಿ': Unit.kg,
    'ಬೆಳ್ಳುಳ್ಳಿ': Unit.kg,
    'ಹಾಲು': Unit.L,
    'ಮೊಸರು': Unit.kg,
    'ತುಪ್ಪ': Unit.mL,
    'ಬೆಣ್ಣೆ': Unit.g,
    'ಪನೀರ್': Unit.g,
    'ಅಡಿಗೆ ಎಣ್ಣೆ': Unit.L,
    'ಎಣ್ಣೆ': Unit.L,
    'ಉಪ್ಪು': Unit.kg,
    'ಸಕ್ಕರೆ': Unit.kg,
    'ಬೆಲ್ಲ': Unit.kg,
    'ಅರಿಶಿನ': Unit.g,
    'ಇಂಗು': Unit.g,
    'ತೆಂಗಿನಕಾಯಿ': Unit.pcs,
    'ನಿಂಬೆಹಣ್ಣು': Unit.pcs,
    'ಬಾಳೆಹಣ್ಣು': Unit.dozen,
    'ಮಾವಿನಹಣ್ಣು': Unit.kg,
    'ಸೇಬು': Unit.kg,
    'ದ್ರಾಕ್ಷಿ': Unit.kg,
    'ಕರಿಬೇವು': Unit.bunch,
    'ಕೊತ್ತಂಬರಿ': Unit.bunch,
    'ನುಗ್ಗೆಕಾಯಿ': Unit.bunch,
    'ಪಾಲಕ್': Unit.bunch,
  };

  /// Separators between items in a spoken list
  static final List<String> _itemSeparators = [
    'ಮತ್ತು',
    'ಹಾಗೂ',
    ',',
    'ನಂತರ',
    'ಆಮೇಲೆ',
  ];

  /// Parse a Kannada spoken text into a list of grocery items
  static List<GroceryItem> parse(String text) {
    if (text.trim().isEmpty) return [];

    // Split by common separators to get individual item phrases
    List<String> segments = _splitIntoSegments(text);
    List<GroceryItem> results = [];

    for (final segment in segments) {
      final item = _parseSegment(segment.trim());
      if (item != null) results.add(item);
    }

    return results;
  }

  static List<String> _splitIntoSegments(String text) {
    String normalized = text;
    for (final sep in _itemSeparators) {
      normalized = normalized.replaceAll(sep, '|');
    }
    return normalized.split('|').where((s) => s.trim().isNotEmpty).toList();
  }

  static GroceryItem? _parseSegment(String segment) {
    if (segment.isEmpty) return null;

    double quantity = 1;
    Unit unit = Unit.pcs;
    String itemName = segment;

    // Extract quantity (Kannada number words or digits)
    final quantityResult = _extractQuantity(segment);
    if (quantityResult != null) {
      quantity = quantityResult.$1;
      segment = quantityResult.$2;
    }

    // Extract unit
    final unitResult = _extractUnit(segment);
    if (unitResult != null) {
      unit = unitResult.$1;
      segment = unitResult.$2;
    }

    // Remaining text is the item name
    itemName = segment.trim();
    if (itemName.isEmpty) return null;

    // If no unit found, use default for known items
    if (unitResult == null && _knownItems.containsKey(itemName)) {
      unit = _knownItems[itemName]!;
    }

    return GroceryItem(name: itemName, quantity: quantity, unit: unit);
  }

  static (double, String)? _extractQuantity(String text) {
    // Try Kannada number words first (longest match)
    final sortedKeys = _kannadaNumbers.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final word in sortedKeys) {
      if (word.codeUnitAt(0) < 128) {
        // Latin transliteration — case-insensitive regex (handles "Ondu", "ONDU")
        final pattern = RegExp(RegExp.escape(word), caseSensitive: false);
        if (pattern.hasMatch(text)) {
          final remaining = text.replaceFirst(pattern, '').trim();
          return (_kannadaNumbers[word]!, remaining);
        }
      } else {
        // Kannada/Unicode script — plain contains (case folding breaks Unicode)
        if (text.contains(word)) {
          final remaining = text.replaceFirst(word, '').trim();
          return (_kannadaNumbers[word]!, remaining);
        }
      }
    }

    // Try Arabic numerals anywhere in the string (not just at start)
    final numRegex = RegExp(r'(\d+\.?\d*)');
    final match = numRegex.firstMatch(text);
    if (match != null) {
      final num = double.tryParse(match.group(1)!);
      if (num != null) {
        final remaining = text.replaceFirst(match.group(0)!, '').trim();
        return (num, remaining);
      }
    }

    return null;
  }

  static (Unit, String)? _extractUnit(String text) {
    final sortedKeys = _unitKeywords.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final keyword in sortedKeys) {
      if (keyword.codeUnitAt(0) < 128) {
        // Latin unit — case-insensitive regex (handles "Kg", "KG", "ML")
        final pattern = RegExp(RegExp.escape(keyword), caseSensitive: false);
        if (pattern.hasMatch(text)) {
          final remaining = text.replaceFirst(pattern, '').trim();
          return (_unitKeywords[keyword]!, remaining);
        }
      } else {
        // Kannada/Unicode script — plain contains
        if (text.contains(keyword)) {
          final remaining = text.replaceFirst(keyword, '').trim();
          return (_unitKeywords[keyword]!, remaining);
        }
      }
    }
    return null;
  }
}
