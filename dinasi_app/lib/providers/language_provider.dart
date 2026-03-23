import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { kannada, english }

class LanguageProvider extends ChangeNotifier {
  static const _key = 'app_language';
  AppLanguage _language = AppLanguage.kannada;

  AppLanguage get language => _language;
  bool get isKannada => _language == AppLanguage.kannada;
  bool get isEnglish => _language == AppLanguage.english;

  LanguageProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'english') {
      _language = AppLanguage.english;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    _language = isKannada ? AppLanguage.english : AppLanguage.kannada;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, isKannada ? 'kannada' : 'english');
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    if (_language == lang) return;
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, isKannada ? 'kannada' : 'english');
    notifyListeners();
  }
}
