import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';
import '../services/photo_service.dart';

class PlayerProvider extends ChangeNotifier {
  static const String _storageKey = 'players_roster';

  List<Player> _allPlayers = [];
  List<Player> _selectedPlayers = [];
  bool _isLoading = false;
  String? _error;

  final PhotoService _photoService = PhotoService();

  // Getters
  List<Player> get allPlayers => List.unmodifiable(_allPlayers);
  List<Player> get selectedPlayers => List.unmodifiable(_selectedPlayers);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load players from SharedPreferences
  Future<void> loadPlayers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? playersJson = prefs.getString(_storageKey);

      if (playersJson != null) {
        final List<dynamic> decoded = jsonDecode(playersJson);
        _allPlayers = decoded.map((json) => Player.fromJson(json)).toList();
      } else {
        _allPlayers = [];
      }
    } catch (e) {
      _error = 'Failed to load players: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save all players to SharedPreferences
  Future<void> _savePlayers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(
        _allPlayers.map((player) => player.toJson()).toList(),
      );
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      _error = 'Failed to save players: $e';
      print(_error);
      notifyListeners();
    }
  }

  // Add or update a player
  Future<void> savePlayer(Player player) async {
    try {
      final index = _allPlayers.indexWhere((p) => p.id == player.id);

      if (index >= 0) {
        // Update existing player
        _allPlayers[index] = player;
      } else {
        // Add new player
        _allPlayers.add(player);
      }

      await _savePlayers();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to save player: $e';
      print(_error);
      notifyListeners();
    }
  }

  // Delete a player
  Future<void> deletePlayer(String id) async {
    try {
      final player = _allPlayers.firstWhere((p) => p.id == id);

      // Delete photo if exists
      if (player.photoPath != null) {
        await _photoService.deletePhoto(player.photoPath!);
      }

      // Remove from all players
      _allPlayers.removeWhere((p) => p.id == id);

      // Remove from selected players if present
      _selectedPlayers.removeWhere((p) => p.id == id);

      await _savePlayers();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete player: $e';
      print(_error);
      notifyListeners();
    }
  }

  // Select a player for the current game
  void selectPlayer(Player player) {
    if (_selectedPlayers.length >= 8) {
      _error = 'Maximum 8 players allowed';
      notifyListeners();
      return;
    }

    if (!_selectedPlayers.any((p) => p.id == player.id)) {
      _selectedPlayers.add(player);
      notifyListeners();
    }
  }

  // Deselect a player
  void deselectPlayer(String id) {
    _selectedPlayers.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // Clear all selected players
  void clearSelection() {
    _selectedPlayers.clear();
    notifyListeners();
  }

  // Update player stats after a game
  Future<void> updatePlayerStats(String playerId, {bool won = false}) async {
    try {
      final index = _allPlayers.indexWhere((p) => p.id == playerId);
      if (index >= 0) {
        final player = _allPlayers[index];
        _allPlayers[index] = player.copyWith(
          gamesPlayed: player.gamesPlayed + 1,
          gamesWon: won ? player.gamesWon + 1 : player.gamesWon,
        );
        await _savePlayers();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update player stats: $e';
      print(_error);
      notifyListeners();
    }
  }

  // Get player by ID
  Player? getPlayerById(String id) {
    try {
      return _allPlayers.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
