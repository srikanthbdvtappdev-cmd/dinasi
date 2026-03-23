import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/grocery_item.dart';
import '../models/saved_list.dart';

class SavedListsProvider extends ChangeNotifier {
  static const _key = 'saved_lists';
  static const _uuid = Uuid();

  final List<SavedList> _lists = [];

  List<SavedList> get lists => List.unmodifiable(_lists);

  SavedListsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final List decoded = jsonDecode(raw) as List;
      _lists.addAll(
        decoded.map((e) => SavedList.fromJson(e as Map<String, dynamic>)),
      );
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_lists.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> saveList(String name, List<GroceryItem> items) async {
    final saved = SavedList(
      id: _uuid.v4(),
      name: name,
      savedAt: DateTime.now(),
      items: List.from(items),
    );
    _lists.insert(0, saved);
    await _save();
    notifyListeners();
  }

  Future<void> deleteList(String id) async {
    _lists.removeWhere((l) => l.id == id);
    await _save();
    notifyListeners();
  }

  /// Parses [jsonString] as a SavedList and inserts it at the top.
  /// Returns the imported list name on success, or null if parsing fails.
  Future<String?> importFromJsonString(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final original = SavedList.fromJson(decoded);
      final imported = SavedList(
        id: _uuid.v4(), // fresh id to avoid collision
        name: original.name,
        savedAt: DateTime.now(),
        items: original.items,
      );
      _lists.insert(0, imported);
      await _save();
      notifyListeners();
      return imported.name;
    } catch (_) {
      return null;
    }
  }
}
