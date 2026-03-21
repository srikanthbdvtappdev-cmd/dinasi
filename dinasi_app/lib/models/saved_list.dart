import 'grocery_item.dart';

class SavedList {
  final String id;
  final String name;
  final DateTime savedAt;
  final List<GroceryItem> items;

  SavedList({
    required this.id,
    required this.name,
    required this.savedAt,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'savedAt': savedAt.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory SavedList.fromJson(Map<String, dynamic> json) => SavedList(
    id: json['id'] as String,
    name: json['name'] as String,
    savedAt: DateTime.parse(json['savedAt'] as String),
    items: (json['items'] as List)
        .map((e) => GroceryItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
