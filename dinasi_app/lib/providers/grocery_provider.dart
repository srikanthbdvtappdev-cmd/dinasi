import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grocery_item.dart';
import '../services/kannada_parser.dart';
import '../services/english_parser.dart';
import 'language_provider.dart';

class GroceryListProvider extends ChangeNotifier {
  static const _itemsKey = 'grocery_items';
  static const _titleKey = 'grocery_title';
  static const _freqKey = 'item_frequency';

  final List<GroceryItem> _items = [];
  String _listTitle = 'Grocery List';
  final Map<String, Map<String, dynamic>> _frequency = {};

  List<GroceryItem> get items => List.unmodifiable(_items);
  String get listTitle => _listTitle;
  int get itemCount => _items.length;

  GroceryListProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_itemsKey);
    if (raw != null) {
      final List decoded = jsonDecode(raw) as List;
      _items.addAll(
        decoded.map((e) => GroceryItem.fromJson(e as Map<String, dynamic>)),
      );
    }
    _listTitle = prefs.getString(_titleKey) ?? 'Grocery List';
    final freqRaw = prefs.getString(_freqKey);
    if (freqRaw != null) {
      final decoded = jsonDecode(freqRaw) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        final map = Map<String, dynamic>.from(value as Map);
        // Skip entries from older app versions that lack 'quantity' —
        // they will be re-recorded correctly the next time the item is added.
        if (map.containsKey('quantity')) {
          _frequency[key] = map;
        }
      });
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _itemsKey,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(_titleKey, _listTitle);
    await prefs.setString(_freqKey, jsonEncode(_frequency));
  }

  void _recordFrequency(GroceryItem item) {
    if (_frequency.containsKey(item.name)) {
      _frequency[item.name]!['count'] =
          (_frequency[item.name]!['count'] as int) + 1;
      _frequency[item.name]!['quantity'] = item.quantity;
      _frequency[item.name]!['unit'] = item.unit.label;
    } else {
      _frequency[item.name] = {
        'count': 1,
        'quantity': item.quantity,
        'unit': item.unit.label,
      };
    }
  }

  /// Returns up to [count] most-frequently-added items not already in the list.
  List<Map<String, String>> getSmartSuggestions(int count) {
    final currentNames = _items.map((i) => i.name).toSet();
    final entries =
        _frequency.entries.where((e) => !currentNames.contains(e.key)).toList()
          ..sort(
            (a, b) =>
                (b.value['count'] as int).compareTo(a.value['count'] as int),
          );
    return entries.take(count).map((e) {
      final qty = e.value['quantity'];
      final qtyDouble = qty != null
          ? (qty is double ? qty : (qty as num).toDouble())
          : 1.0;
      return {
        'name': e.key,
        'quantity': qtyDouble.toString(),
        'unit': e.value['unit'] as String,
      };
    }).toList();
  }

  void clearForLanguageSwitch() {
    _frequency.clear();
    _save();
    notifyListeners();
  }

  void addItem(GroceryItem item) {
    _items.add(item);
    _recordFrequency(item);
    _save();
    notifyListeners();
  }

  void addItemsFromVoice(
    String spokenText, {
    AppLanguage language = AppLanguage.kannada,
  }) {
    final parsed = language == AppLanguage.english
        ? EnglishVoiceParser.parse(spokenText)
        : KannadaVoiceParser.parse(spokenText);
    for (final item in parsed) {
      _items.add(item);
      _recordFrequency(item);
    }
    if (parsed.isNotEmpty) {
      _save();
      notifyListeners();
    }
  }

  void addPredefinedItem(String kannadaName, String unitLabel) {
    final unit = UnitLabel.fromLabel(unitLabel);
    final existing = _items.where((i) => i.name == kannadaName).toList();
    if (existing.isNotEmpty) {
      existing.first.quantity += 1;
      _save();
      notifyListeners();
      return;
    }
    final newItem = GroceryItem(name: kannadaName, quantity: 1, unit: unit);
    _items.add(newItem);
    _recordFrequency(newItem);
    _save();
    notifyListeners();
  }

  void updateItem(String id, {String? name, double? quantity, Unit? unit}) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    _items[idx] = _items[idx].copyWith(
      name: name,
      quantity: quantity,
      unit: unit,
    );
    // Keep frequency in sync with latest quantity/unit edits
    final updated = _items[idx];
    if (_frequency.containsKey(updated.name)) {
      _frequency[updated.name]!['quantity'] = updated.quantity;
      _frequency[updated.name]!['unit'] = updated.unit.label;
    }
    _save();
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    _save();
    notifyListeners();
  }

  void reorderItems(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);
    _save();
    notifyListeners();
  }

  void clearAll() {
    _items.clear();
    _save();
    notifyListeners();
  }

  void setTitle(String title) {
    _listTitle = title;
    _save();
    notifyListeners();
  }

  void loadFromSaved(List<GroceryItem> items, String title) {
    _items.clear();
    _items.addAll(items.map((i) => i.copyWith()));
    _listTitle = title;
    _save();
    notifyListeners();
  }
}
