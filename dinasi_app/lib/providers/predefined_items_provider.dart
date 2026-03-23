import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grocery_item.dart';

/// Manages the predefined items list, including user-added custom items.
class PredefinedItemsProvider extends ChangeNotifier {
  static const _customKey = 'custom_predefined_items';
  // Built-in items (cannot be deleted)
  static const List<Map<String, String>> _builtIn = [
    // Grains & Cereals
    {'kannada': 'ಅಕ್ಕಿ', 'english': 'Akki (Rice)', 'unit': 'kg'},
    {'kannada': 'ರಾಗಿ', 'english': 'Ragi (Finger Millet)', 'unit': 'kg'},
    {'kannada': 'ಗೋಧಿ', 'english': 'Godhi (Wheat)', 'unit': 'kg'},
    {'kannada': 'ಜೋಳ', 'english': 'Jola (Sorghum)', 'unit': 'kg'},
    {'kannada': 'ಮೆಕ್ಕೆ ಜೋಳ', 'english': 'Mekke Jola (Corn)', 'unit': 'kg'},
    {'kannada': 'ಅವಲಕ್ಕಿ', 'english': 'Avalakki (Poha)', 'unit': 'kg'},
    {'kannada': 'ಸೇಮಿಗೆ', 'english': 'Semige (Vermicelli)', 'unit': 'kg'},
    // Pulses & Lentils
    {
      'kannada': 'ತೊಗರಿ ಬೇಳೆ',
      'english': 'Togari Bele (Toor Dal)',
      'unit': 'kg',
    },
    {
      'kannada': 'ಕಡಲೆ ಬೇಳೆ',
      'english': 'Kadale Bele (Chana Dal)',
      'unit': 'kg',
    },
    {
      'kannada': 'ಉದ್ದಿನ ಬೇಳೆ',
      'english': 'Uddina Bele (Urad Dal)',
      'unit': 'kg',
    },
    {'kannada': 'ಮೂಂಗ ಬೇಳೆ', 'english': 'Munga Bele (Moong Dal)', 'unit': 'kg'},
    {
      'kannada': 'ಹೆಸರು ಕಾಳು',
      'english': 'Hesaru Kalu (Green Moong)',
      'unit': 'kg',
    },
    {'kannada': 'ಕಡಲೆಕಾಯಿ', 'english': 'Kadale Kayi (Peanuts)', 'unit': 'kg'},
    {'kannada': 'ರಾಜ್ಮಾ', 'english': 'Rajma (Kidney Beans)', 'unit': 'kg'},
    // Vegetables
    {'kannada': 'ಆಲೂಗಡ್ಡೆ', 'english': 'Alugadde (Potato)', 'unit': 'kg'},
    {'kannada': 'ಈರುಳ್ಳಿ', 'english': 'Eerulli (Onion)', 'unit': 'kg'},
    {'kannada': 'ಟೊಮೇಟೊ', 'english': 'Tometo (Tomato)', 'unit': 'kg'},
    {'kannada': 'ಕ್ಯಾರೆಟ್', 'english': 'Carrot', 'unit': 'kg'},
    {'kannada': 'ಬೀನ್ಸ್', 'english': 'Beans', 'unit': 'kg'},
    {'kannada': 'ಕುಂಬಳಕಾಯಿ', 'english': 'Kumbala Kayi (Pumpkin)', 'unit': 'kg'},
    {'kannada': 'ಬದನೆಕಾಯಿ', 'english': 'Badane Kayi (Brinjal)', 'unit': 'kg'},
    {'kannada': 'ಬೆಂಡೆಕಾಯಿ', 'english': 'Bende Kayi (Okra)', 'unit': 'kg'},
    {
      'kannada': 'ಹೀರೆಕಾಯಿ',
      'english': 'Heere Kayi (Ridge Gourd)',
      'unit': 'kg',
    },
    {
      'kannada': 'ಸೋರೆಕಾಯಿ',
      'english': 'Sore Kayi (Bottle Gourd)',
      'unit': 'kg',
    },
    {
      'kannada': 'ನುಗ್ಗೆಕಾಯಿ',
      'english': 'Nugge Kayi (Drumstick)',
      'unit': 'bunch',
    },
    {'kannada': 'ಮೆಣಸಿನಕಾಯಿ', 'english': 'Mensina Kayi (Chilli)', 'unit': 'kg'},
    {'kannada': 'ಶುಂಠಿ', 'english': 'Shunthi (Ginger)', 'unit': 'kg'},
    {'kannada': 'ಬೆಳ್ಳುಳ್ಳಿ', 'english': 'Bellulli (Garlic)', 'unit': 'kg'},
    {
      'kannada': 'ಕೊತ್ತಂಬರಿ',
      'english': 'Kottambari (Coriander)',
      'unit': 'bunch',
    },
    {'kannada': 'ಪಾಲಕ್', 'english': 'Palak (Spinach)', 'unit': 'bunch'},
    {
      'kannada': 'ಮೆಂತ್ಯ ಸೊಪ್ಪು',
      'english': 'Menthya Soppu (Fenugreek Leaves)',
      'unit': 'bunch',
    },
    // Fruits
    {'kannada': 'ಬಾಳೆಹಣ್ಣು', 'english': 'Bale Hannu (Banana)', 'unit': 'dozen'},
    {'kannada': 'ಮಾವಿನಹಣ್ಣು', 'english': 'Mavina Hannu (Mango)', 'unit': 'kg'},
    {'kannada': 'ಸೇಬು', 'english': 'Sebu (Apple)', 'unit': 'kg'},
    {'kannada': 'ದ್ರಾಕ್ಷಿ', 'english': 'Drakshi (Grapes)', 'unit': 'kg'},
    {'kannada': 'ದಾಳಿಂಬೆ', 'english': 'Dalimbe (Pomegranate)', 'unit': 'pcs'},
    {'kannada': 'ಕಿತ್ತಳೆ', 'english': 'Kittale (Orange)', 'unit': 'kg'},
    {'kannada': 'ನಿಂಬೆಹಣ್ಣು', 'english': 'Nimbe Hannu (Lemon)', 'unit': 'pcs'},
    {
      'kannada': 'ತೆಂಗಿನಕಾಯಿ',
      'english': 'Tengina Kayi (Coconut)',
      'unit': 'pcs',
    },
    {'kannada': 'ಚಿಕ್ಕು', 'english': 'Chikku (Sapota)', 'unit': 'kg'},
    {'kannada': 'ಪಪ್ಪಾಯಿ', 'english': 'Pappayi (Papaya)', 'unit': 'pcs'},
    // Dairy & Eggs
    {'kannada': 'ಹಾಲು', 'english': 'Halu (Milk)', 'unit': 'L'},
    {'kannada': 'ಮೊಟ್ಟೆ', 'english': 'Motte (Eggs)', 'unit': 'dozen'},
    {'kannada': 'ಮೊಸರು', 'english': 'Mosaru (Curd)', 'unit': 'kg'},
    {'kannada': 'ಬೆಣ್ಣೆ', 'english': 'Benne (Butter)', 'unit': 'g'},
    {'kannada': 'ಪನೀರ್', 'english': 'Paneer', 'unit': 'g'},
    {'kannada': 'ತುಪ್ಪ', 'english': 'Tuppa (Ghee)', 'unit': 'mL'},
    // Oils & Cooking Essentials
    {
      'kannada': 'ಅಡಿಗೆ ಎಣ್ಣೆ',
      'english': 'Adige Enne (Cooking Oil)',
      'unit': 'L',
    },
    {'kannada': 'ಸಾಸಿವೆ', 'english': 'Sasive (Mustard Seeds)', 'unit': 'g'},
    {'kannada': 'ಜೀರಿಗೆ', 'english': 'Jirige (Cumin)', 'unit': 'g'},
    {'kannada': 'ಮೆಂತ್ಯ', 'english': 'Menthya (Fenugreek Seeds)', 'unit': 'g'},
    {'kannada': 'ಉಪ್ಪು', 'english': 'Uppu (Salt)', 'unit': 'kg'},
    {'kannada': 'ಸಕ್ಕರೆ', 'english': 'Sakkare (Sugar)', 'unit': 'kg'},
    {'kannada': 'ಬೆಲ್ಲ', 'english': 'Bella (Jaggery)', 'unit': 'kg'},
    {'kannada': 'ಅರಿಶಿನ', 'english': 'Arishina (Turmeric)', 'unit': 'g'},
    {
      'kannada': 'ಕೆಂಪು ಮೆಣಸಿನ ಪುಡಿ',
      'english': 'Kempu Mensina Pudi (Red Chilli Powder)',
      'unit': 'g',
    },
    {
      'kannada': 'ಧನಿಯಾ ಪುಡಿ',
      'english': 'Dhaniya Pudi (Coriander Powder)',
      'unit': 'g',
    },
    {'kannada': 'ಇಂಗು', 'english': 'Ingu (Asafoetida)', 'unit': 'g'},
    {
      'kannada': 'ಕರಿಬೇವು',
      'english': 'Karibevu (Curry Leaves)',
      'unit': 'bunch',
    },
    // Snacks & Others
    {
      'kannada': 'ಮೈಸೂರ್ ಸ್ಯಾಂಡಲ್ ಸೋಪು',
      'english': 'Mysore Sandal Soap',
      'unit': 'pcs',
    },
    {'kannada': 'ಟೂಥ್ ಪೇಸ್ಟ್', 'english': 'Toothpaste', 'unit': 'pcs'},
    {'kannada': 'ಶಾಂಪೂ', 'english': 'Shampoo', 'unit': 'pcs'},
    {'kannada': 'ಸಾಬೂನು', 'english': 'Sabunu (Soap)', 'unit': 'pcs'},
    {'kannada': 'ಡಿಟರ್ಜೆಂಟ್', 'english': 'Detergent', 'unit': 'kg'},
    {
      'kannada': 'ಕಾಫಿ ಪುಡಿ',
      'english': 'Coffee Pudi (Coffee Powder)',
      'unit': 'g',
    },
    {'kannada': 'ಚಹಾ', 'english': 'Chaha (Tea)', 'unit': 'g'},
  ];

  // Medicines (always displayed in English)
  static const List<Map<String, String>> _medicineBuiltIn = [
    // Pain Relief
    {
      'kannada': 'Paracetamol',
      'english': 'Paracetamol – Crocin / Dolo 650',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Ibuprofen',
      'english': 'Ibuprofen – Brufen / Combiflam',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Aspirin',
      'english': 'Aspirin – Ecosprin (75/150mg)',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Diclofenac',
      'english': 'Diclofenac – Voveran / Diclomol',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    // Diabetes
    {
      'kannada': 'Metformin',
      'english': 'Metformin – Glycomet / Glucophage',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Glimepiride',
      'english': 'Glimepiride – Amaryl / Glimer',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Glibenclamide',
      'english': 'Glibenclamide – Daonil',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Sitagliptin',
      'english': 'Sitagliptin – Januvia',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Insulin',
      'english': 'Insulin (inject) – Lantus / Mixtard',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    // Blood Pressure
    {
      'kannada': 'Amlodipine',
      'english': 'Amlodipine – Stamlo / Norvasc',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Atenolol',
      'english': 'Atenolol – Tenormin',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Losartan',
      'english': 'Losartan – Losar / Cozaar',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Telmisartan',
      'english': 'Telmisartan – Telma / Telsartan',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Ramipril',
      'english': 'Ramipril – Cardace / Hopace',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    // Cholesterol
    {
      'kannada': 'Atorvastatin',
      'english': 'Atorvastatin – Atorva / Lipitor',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Rosuvastatin',
      'english': 'Rosuvastatin – Rozavel / Crestor',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    // Acidity & Stomach
    {
      'kannada': 'Omeprazole',
      'english': 'Omeprazole – Omez / Prilosec',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Pantoprazole',
      'english': 'Pantoprazole – Pan-D / Pantocid',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Ranitidine',
      'english': 'Ranitidine – Zinetac / Rantac',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Antacid',
      'english': 'Antacid – Gelusil / Digene',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'ORS',
      'english': 'ORS Sachet – Electral / Pedialyte',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    // Allergy, Cold & Cough
    {
      'kannada': 'Cetirizine',
      'english': 'Cetirizine – Cetriz / Zyrtec',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Levocetirizine',
      'english': 'Levocetirizine – L-Cetriz',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Cough Syrup',
      'english': 'Cough Syrup – Benadryl / Ascoril',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Nasal Drops',
      'english': 'Nasal Drops – Nasivion / Otrivin',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    // Antibiotics
    {
      'kannada': 'Azithromycin',
      'english': 'Azithromycin – Azee / Zithromax',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Amoxicillin',
      'english': 'Amoxicillin – Mox / Amoxil',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Ciprofloxacin',
      'english': 'Ciprofloxacin – Cifran / Ciplox',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    // Vitamins & Supplements
    {
      'kannada': 'Vitamin D3',
      'english': 'Vitamin D3 – Calcirol / Uprise-D3',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Vitamin C',
      'english': 'Vitamin C – Celin 500',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'B-Complex',
      'english': 'Vitamin B-Complex – Becosules',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Calcium D3',
      'english': 'Calcium + D3 – Shelcal / Calcimax',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Iron Folic',
      'english': 'Iron + Folic Acid – Dexorange',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    // First Aid
    {
      'kannada': 'Betadine',
      'english': 'Betadine – Antiseptic Solution',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Band Aid',
      'english': 'Band Aid / Bandage',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'Thermometer',
      'english': 'Digital Thermometer',
      'unit': 'pcs',
      'category': 'Medicines',
    },
    {
      'kannada': 'BP Monitor',
      'english': 'BP Monitor / Glucometer Strips',
      'unit': 'pcs',
      'category': 'Medicines',
    },
  ];

  // User-added custom items
  final List<Map<String, String>> _customItems = [];

  PredefinedItemsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customKey);
    if (raw != null) {
      final List decoded = jsonDecode(raw) as List;
      _customItems.addAll(
        decoded.map((e) => Map<String, String>.from(e as Map)),
      );
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customKey, jsonEncode(_customItems));
  }

  List<Map<String, String>> get all => [
    ..._builtIn,
    ..._medicineBuiltIn,
    ..._customItems,
  ];

  List<Map<String, String>> get groceryItems => [
    ..._builtIn,
    ..._customItems.where((i) => (i['category'] ?? '') != 'Medicines'),
  ];

  List<Map<String, String>> get medicineItems => [
    ..._medicineBuiltIn,
    ..._customItems.where((i) => i['category'] == 'Medicines'),
  ];

  List<Map<String, String>> get customItems => List.unmodifiable(_customItems);

  List<Map<String, String>> search(String query) {
    if (query.isEmpty) return all;
    final lower = query.toLowerCase();
    return all.where((item) {
      return item['kannada']!.contains(query) ||
          item['english']!.toLowerCase().contains(lower);
    }).toList();
  }

  List<Map<String, String>> searchGroceries(String query) {
    if (query.isEmpty) return groceryItems;
    final lower = query.toLowerCase();
    return groceryItems.where((item) {
      return item['kannada']!.contains(query) ||
          item['english']!.toLowerCase().contains(lower);
    }).toList();
  }

  List<Map<String, String>> searchMedicines(String query) {
    if (query.isEmpty) return medicineItems;
    final lower = query.toLowerCase();
    return medicineItems.where((item) {
      return item['english']!.toLowerCase().contains(lower);
    }).toList();
  }

  bool isCustom(Map<String, String> item) => _customItems.contains(item);

  /// Add a new custom item. Returns false if a duplicate name exists.
  bool addCustomItem(
    String kannada,
    String english,
    String unit, {
    String category = 'Groceries',
  }) {
    final trimmed = kannada.trim();
    if (trimmed.isEmpty) return false;
    final duplicate = all.any((i) => i['kannada']!.trim() == trimmed);
    if (duplicate) return false;
    _customItems.add({
      'kannada': trimmed,
      'english': english.trim().isEmpty ? trimmed : english.trim(),
      'unit': unit,
      if (category != 'Groceries') 'category': category,
    });
    _save();
    notifyListeners();
    return true;
  }

  void removeCustomItem(Map<String, String> item) {
    _customItems.remove(item);
    _save();
    notifyListeners();
  }

  /// Appends items from JSON import, skipping duplicates. Returns count of added items.
  int importItems(List<Map<String, String>> items) {
    int added = 0;
    for (final item in items) {
      final kannada = item['kannada']?.trim() ?? '';
      if (kannada.isEmpty) continue;
      final duplicate = all.any((i) => i['kannada']!.trim() == kannada);
      if (duplicate) continue;
      _customItems.add({
        'kannada': kannada,
        'english': item['english'] ?? kannada,
        'unit': item['unit'] ?? 'pcs',
        if ((item['category'] ?? '') == 'Medicines') 'category': 'Medicines',
      });
      added++;
    }
    if (added > 0) {
      _save();
      notifyListeners();
    }
    return added;
  }

  // For use in KannadaVoiceParser / GroceryListProvider
  static Unit defaultUnitFor(String kannadaName) {
    final match = _builtIn.where((i) => i['kannada'] == kannadaName).toList();
    if (match.isEmpty) return Unit.pcs;
    return UnitLabel.fromLabel(match.first['unit'] ?? 'pcs');
  }
}
