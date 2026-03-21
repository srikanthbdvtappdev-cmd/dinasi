import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grocery_item.dart';
import '../services/kannada_parser.dart';

class GroceryListProvider extends ChangeNotifier {
  static const _itemsKey = 'grocery_items';
  static const _titleKey = 'grocery_title';

  final List<GroceryItem> _items = [];
  String _listTitle = 'Grocery List';

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
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _itemsKey,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(_titleKey, _listTitle);
  }

  void addItem(GroceryItem item) {
    _items.add(item);
    _save();
    notifyListeners();
  }

  void addItemsFromVoice(String spokenText) {
    final parsed = KannadaVoiceParser.parse(spokenText);
    for (final item in parsed) {
      _items.add(item);
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
    _items.add(GroceryItem(name: kannadaName, quantity: 1, unit: unit));
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
