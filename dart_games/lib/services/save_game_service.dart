import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_game_metadata.dart';

class SaveGameService {
  static String _storageKey(String gameType) => 'saved_games_$gameType';

  Future<void> saveGame(SavedGameMetadata metadata) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKey(metadata.gameType);
    final existing = prefs.getStringList(key) ?? [];

    // Check if a save with this ID already exists (resumed game being re-saved)
    final existingIndex = existing.indexWhere((s) {
      final json = jsonDecode(s);
      return json['id'] == metadata.id;
    });

    final encoded = jsonEncode(metadata.toJson());
    if (existingIndex >= 0) {
      existing[existingIndex] = encoded;
    } else {
      existing.add(encoded);
    }
    await prefs.setStringList(key, existing);
  }

  Future<List<SavedGameMetadata>> loadSavedGames(String gameType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKey(gameType);
    final saved = prefs.getStringList(key) ?? [];
    return saved
        .map((s) => SavedGameMetadata.fromJson(jsonDecode(s)))
        .toList();
  }

  Future<void> deleteSavedGame(String gameType, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKey(gameType);
    final saved = prefs.getStringList(key) ?? [];
    final filtered = saved.where((s) {
      final json = jsonDecode(s);
      return json['id'] != id;
    }).toList();
    await prefs.setStringList(key, filtered);
  }

  Future<void> deleteAllSavedGames(String gameType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKey(gameType);
    await prefs.remove(key);
  }

  Future<bool> hasSavedGames(String gameType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKey(gameType);
    final saved = prefs.getStringList(key) ?? [];
    return saved.isNotEmpty;
  }
}
