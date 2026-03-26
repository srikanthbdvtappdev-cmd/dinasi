import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';

class NotepadProvider extends ChangeNotifier {
  static const _key = 'saved_notes';
  static const _draftTextKey = 'notepad_draft_text';
  static const _draftStrokesKey = 'notepad_draft_strokes';
  static const _uuid = Uuid();

  final List<Note> _notes = [];
  List<Note> get notes => List.unmodifiable(_notes);

  String _draftText = '';
  String get draftText => _draftText;

  List<Map<String, dynamic>> _draftStrokes = [];
  List<Map<String, dynamic>> get draftStrokes =>
      List.unmodifiable(_draftStrokes);

  NotepadProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final List decoded = jsonDecode(raw) as List;
      _notes.addAll(
        decoded.map((e) => Note.fromJson(e as Map<String, dynamic>)),
      );
    }
    _draftText = prefs.getString(_draftTextKey) ?? '';
    final rawStrokes = prefs.getString(_draftStrokesKey);
    if (rawStrokes != null) {
      final List decoded = jsonDecode(rawStrokes) as List;
      _draftStrokes = decoded
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_notes.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> saveDraftText(String text) async {
    _draftText = text;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftTextKey, text);
  }

  Future<void> saveDraftStrokes(List<Map<String, dynamic>> strokes) async {
    _draftStrokes = strokes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftStrokesKey, jsonEncode(strokes));
  }

  Future<void> saveNote(String title, String content) async {
    final resolvedTitle = title.trim().isEmpty
        ? _autoTitle(content)
        : title.trim();
    final note = Note(
      id: _uuid.v4(),
      title: resolvedTitle,
      content: content,
      createdAt: DateTime.now(),
    );
    _notes.insert(0, note);
    await _persist();
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _persist();
    notifyListeners();
  }

  String _autoTitle(String content) {
    final firstLine = content.trim().split('\n').first.trim();
    return firstLine.length > 40 ? '${firstLine.substring(0, 40)}…' : firstLine;
  }
}
