// English voice input parser - mirrors the structure of KannadaVoiceParser.
// Parses spoken English like "2 kg rice and 1 dozen eggs" into GroceryItems.
import '../models/grocery_item.dart';

class EnglishVoiceParser {
  static const Map<String, double> _englishNumbers = {
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
    'twenty': 20,
    'twenty five': 25,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90,
    'hundred': 100,
    'half': 0.5,
    'quarter': 0.25,
    'a': 1,
    'an': 1,
    'one and a half': 1.5,
    'two and a half': 2.5,
  };

  static const Map<String, Unit> _unitKeywords = {
    'kg': Unit.kg,
    'kgs': Unit.kg,
    'kilogram': Unit.kg,
    'kilograms': Unit.kg,
    'kilo': Unit.kg,
    'kilos': Unit.kg,
    'g': Unit.g,
    'gram': Unit.g,
    'grams': Unit.g,
    'gm': Unit.g,
    'gms': Unit.g,
    'l': Unit.L,
    'liter': Unit.L,
    'litre': Unit.L,
    'liters': Unit.L,
    'litres': Unit.L,
    'ml': Unit.mL,
    'milliliter': Unit.mL,
    'millilitre': Unit.mL,
    'milliliters': Unit.mL,
    'millilitres': Unit.mL,
    'pcs': Unit.pcs,
    'pc': Unit.pcs,
    'piece': Unit.pcs,
    'pieces': Unit.pcs,
    'nos': Unit.pcs,
    'no': Unit.pcs,
    'number': Unit.pcs,
    'dozen': Unit.dozen,
    'dozens': Unit.dozen,
    'bunch': Unit.bunch,
    'bunches': Unit.bunch,
    'pack': Unit.pack,
    'packs': Unit.pack,
    'packet': Unit.pack,
    'packets': Unit.pack,
    'bundle': Unit.bunch,
  };

  static const Map<String, Unit> _knownItems = {
    'rice': Unit.kg,
    'wheat': Unit.kg,
    'flour': Unit.kg,
    'ragi': Unit.kg,
    'bajra': Unit.kg,
    'jowar': Unit.kg,
    'poha': Unit.kg,
    'semolina': Unit.kg,
    'rava': Unit.kg,
    'sooji': Unit.kg,
    'dal': Unit.kg,
    'lentils': Unit.kg,
    'toor dal': Unit.kg,
    'arhar dal': Unit.kg,
    'chana dal': Unit.kg,
    'moong dal': Unit.kg,
    'urad dal': Unit.kg,
    'potato': Unit.kg,
    'potatoes': Unit.kg,
    'onion': Unit.kg,
    'onions': Unit.kg,
    'tomato': Unit.kg,
    'tomatoes': Unit.kg,
    'carrot': Unit.kg,
    'carrots': Unit.kg,
    'beans': Unit.kg,
    'eggplant': Unit.kg,
    'brinjal': Unit.kg,
    'okra': Unit.kg,
    'ladyfinger': Unit.kg,
    'ginger': Unit.kg,
    'garlic': Unit.kg,
    'milk': Unit.L,
    'curd': Unit.kg,
    'yogurt': Unit.kg,
    'ghee': Unit.mL,
    'butter': Unit.g,
    'paneer': Unit.g,
    'oil': Unit.L,
    'cooking oil': Unit.L,
    'salt': Unit.kg,
    'sugar': Unit.kg,
    'jaggery': Unit.kg,
    'turmeric': Unit.g,
    'coconut': Unit.pcs,
    'lemon': Unit.pcs,
    'lemons': Unit.pcs,
    'lime': Unit.pcs,
    'banana': Unit.dozen,
    'bananas': Unit.dozen,
    'mango': Unit.kg,
    'mangoes': Unit.kg,
    'apple': Unit.kg,
    'apples': Unit.kg,
    'grapes': Unit.kg,
    'curry leaves': Unit.bunch,
    'coriander': Unit.bunch,
    'cilantro': Unit.bunch,
    'spinach': Unit.bunch,
    'eggs': Unit.dozen,
    'egg': Unit.dozen,
  };

  static final List<String> _itemSeparators = [
    ' and ',
    ' then ',
    ', ',
    ' also ',
    ' plus ',
  ];

  static List<GroceryItem> parse(String text) {
    if (text.trim().isEmpty) return [];
    final segments = _splitIntoSegments(text.toLowerCase());
    final results = <GroceryItem>[];
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

    // Try multi-word number phrases first (at start of segment)
    final sortedNumbers = _englishNumbers.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final word in sortedNumbers) {
      if (segment.startsWith(word)) {
        quantity = _englishNumbers[word]!;
        segment = segment.substring(word.length).trim();
        break;
      }
    }

    // Try Arabic numerals at start
    if (quantity == 1) {
      final numMatch = RegExp(r'^(\d+\.?\d*)\s*').firstMatch(segment);
      if (numMatch != null) {
        quantity = double.tryParse(numMatch.group(1)!) ?? 1;
        segment = segment.substring(numMatch.end).trim();
      }
    }

    // Extract unit at start (longest match first)
    final sortedUnits = _unitKeywords.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final u in sortedUnits) {
      if (segment.startsWith(u) || segment.startsWith('$u ') || segment == u) {
        unit = _unitKeywords[u]!;
        segment = segment
            .replaceFirst(RegExp('^${RegExp.escape(u)}\\s*'), '')
            .trim();
        // strip "of" connector: "2 kg of rice" → "rice"
        if (segment.startsWith('of ')) segment = segment.substring(3).trim();
        break;
      }
    }

    itemName = segment.trim();

    // ── Handle "item qty unit" order: e.g. "rice 5 kgs", "milk 2 litres" ──
    // If we haven't found a quantity yet (still 1/pcs), try number+unit at end.
    if (quantity == 1 && unit == Unit.pcs && itemName.isNotEmpty) {
      // Match trailing: "item 5 kgs" or "item 5" or "item kgs"
      final trailingMatch = RegExp(
        r'^(.+?)\s+(\d+\.?\d*)\s+(' +
            sortedUnits.map(RegExp.escape).join('|') +
            r')$',
        caseSensitive: false,
      ).firstMatch(itemName);
      if (trailingMatch != null) {
        itemName = trailingMatch.group(1)!.trim();
        quantity = double.tryParse(trailingMatch.group(2)!) ?? 1;
        unit = _unitKeywords[trailingMatch.group(3)!.toLowerCase()]!;
      } else {
        // "item 5" — no unit word
        final trailingNumOnly = RegExp(
          r'^(.+?)\s+(\d+\.?\d*)$',
        ).firstMatch(itemName);
        if (trailingNumOnly != null) {
          final possibleItem = trailingNumOnly.group(1)!.trim();
          final possibleQty = double.tryParse(trailingNumOnly.group(2)!);
          if (possibleQty != null) {
            itemName = possibleItem;
            quantity = possibleQty;
          }
        }
        // "item unit" — no number word
        final trailingUnitOnly = RegExp(
          r'^(.+?)\s+(' + sortedUnits.map(RegExp.escape).join('|') + r')$',
          caseSensitive: false,
        ).firstMatch(itemName);
        if (trailingUnitOnly != null) {
          itemName = trailingUnitOnly.group(1)!.trim();
          unit = _unitKeywords[trailingUnitOnly.group(2)!.toLowerCase()]!;
        }
      }
    }

    if (itemName.isEmpty) return null;

    // Use known-item default unit if none was detected
    if (unit == Unit.pcs) {
      for (final k in _knownItems.keys) {
        if (itemName == k || itemName.endsWith(' $k') || itemName == '${k}s') {
          unit = _knownItems[k]!;
          break;
        }
      }
    }

    // Capitalize first letter for display
    final displayName = itemName[0].toUpperCase() + itemName.substring(1);
    return GroceryItem(name: displayName, quantity: quantity, unit: unit);
  }
}
