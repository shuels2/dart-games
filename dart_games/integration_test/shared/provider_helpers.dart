import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_games/providers/horse_race_provider.dart';
import 'package:dart_games/providers/target_tag_provider.dart';
import 'package:dart_games/providers/player_provider.dart';
import 'package:dart_games/providers/dartboard_provider.dart';
import 'package:dart_games/models/player.dart';

/// Helpers for accessing provider state in UI tests.
class ProviderHelpers {
  /// Get the MaterialApp context from tester
  static BuildContext getContext(WidgetTester tester) {
    return tester.element(find.byType(MaterialApp));
  }

  // ==========================================================================
  // PROVIDER GETTERS
  // ==========================================================================

  /// Get Carnival Derby provider
  static HorseRaceProvider getCarnivalDerbyProvider(WidgetTester tester) {
    final context = getContext(tester);
    return Provider.of<HorseRaceProvider>(context, listen: false);
  }

  /// Get Target Tag provider
  static TargetTagProvider getTargetTagProvider(WidgetTester tester) {
    final context = getContext(tester);
    return Provider.of<TargetTagProvider>(context, listen: false);
  }

  /// Get Player provider
  static PlayerProvider getPlayerProvider(WidgetTester tester) {
    final context = getContext(tester);
    return Provider.of<PlayerProvider>(context, listen: false);
  }

  /// Get Dartboard provider
  static DartboardProvider getDartboardProvider(WidgetTester tester) {
    final context = getContext(tester);
    return Provider.of<DartboardProvider>(context, listen: false);
  }

  // ==========================================================================
  // CARNIVAL DERBY HELPERS
  // ==========================================================================

  /// Carnival Derby: Get current player score
  static int getCarnivalDerbyPlayerScore(WidgetTester tester, String playerId) {
    final provider = getCarnivalDerbyProvider(tester);
    return provider.getPlayerScore(playerId);
  }

  /// Carnival Derby: Get current player score (current player)
  static int getCarnivalDerbyCurrentPlayerScore(WidgetTester tester) {
    final provider = getCarnivalDerbyProvider(tester);
    final currentPlayerId = provider.getCurrentPlayerId();
    if (currentPlayerId == null) return 0;
    return provider.getPlayerScore(currentPlayerId);
  }

  /// Carnival Derby: Check if player busted
  static bool hasCarnivalDerbyPlayerBusted(WidgetTester tester) {
    final provider = getCarnivalDerbyProvider(tester);
    return provider.currentPlayerBusted;
  }

  /// Carnival Derby: Check for winner
  static bool carnivalDerbyHasWinner(WidgetTester tester) {
    final provider = getCarnivalDerbyProvider(tester);
    return provider.hasWinner;
  }

  /// Carnival Derby: Get winner
  static Player? getCarnivalDerbyWinner(WidgetTester tester, List<Player> players) {
    final provider = getCarnivalDerbyProvider(tester);
    return provider.getWinner(players);
  }

  /// Carnival Derby: Check if game is active
  static bool isCarnivalDerbyGameActive(WidgetTester tester) {
    final provider = getCarnivalDerbyProvider(tester);
    return provider.isGameActive;
  }

  /// Carnival Derby: Get current player ID
  static String? getCarnivalDerbyCurrentPlayerId(WidgetTester tester) {
    final provider = getCarnivalDerbyProvider(tester);
    return provider.getCurrentPlayerId();
  }

  // ==========================================================================
  // TARGET TAG HELPERS
  // ==========================================================================

  /// Target Tag: Get player shields
  static int getTargetTagPlayerShields(WidgetTester tester, String playerId) {
    final provider = getTargetTagProvider(tester);
    return provider.getShields(playerId);
  }

  /// Target Tag: Check if player is tagged in
  static bool isTargetTagPlayerTaggedIn(WidgetTester tester, String playerId) {
    final provider = getTargetTagProvider(tester);
    return provider.isTaggedIn(playerId);
  }

  /// Target Tag: Check if player is eliminated
  static bool isTargetTagPlayerEliminated(WidgetTester tester, String playerId) {
    final provider = getTargetTagProvider(tester);
    return provider.isEliminated(playerId);
  }

  /// Target Tag: Get player target number
  static int? getTargetTagPlayerTarget(WidgetTester tester, String playerId) {
    final provider = getTargetTagProvider(tester);
    return provider.getTargetNumber(playerId);
  }

  /// Target Tag: Check for winner
  static bool targetTagHasWinner(WidgetTester tester) {
    final provider = getTargetTagProvider(tester);
    return provider.hasWinner;
  }

  /// Target Tag: Get winners (returns list for team mode support)
  static List<Player> getTargetTagWinners(WidgetTester tester, List<Player> players) {
    final provider = getTargetTagProvider(tester);
    return provider.getWinners(players);
  }

  /// Target Tag: Check if game is active
  static bool isTargetTagGameActive(WidgetTester tester) {
    final provider = getTargetTagProvider(tester);
    return provider.isGameActive;
  }

  /// Target Tag: Get current player ID
  static String? getTargetTagCurrentPlayerId(WidgetTester tester) {
    final provider = getTargetTagProvider(tester);
    return provider.getCurrentPlayerId();
  }

  // ==========================================================================
  // PLAYER PROVIDER HELPERS
  // ==========================================================================

  /// Get all players
  static List<Player> getAllPlayers(WidgetTester tester) {
    final provider = getPlayerProvider(tester);
    return provider.allPlayers;
  }

  /// Get selected players
  static List<Player> getSelectedPlayers(WidgetTester tester) {
    final provider = getPlayerProvider(tester);
    return provider.selectedPlayers;
  }

  /// Find player by ID
  static Player? findPlayerById(WidgetTester tester, String playerId) {
    final provider = getPlayerProvider(tester);
    try {
      return provider.allPlayers.firstWhere((p) => p.id == playerId);
    } catch (e) {
      return null;
    }
  }

  /// Find player by name
  static Player? findPlayerByName(WidgetTester tester, String name) {
    final provider = getPlayerProvider(tester);
    try {
      return provider.allPlayers.firstWhere((p) => p.name == name);
    } catch (e) {
      return null;
    }
  }

  // ==========================================================================
  // DARTBOARD PROVIDER HELPERS
  // ==========================================================================

  /// Check if dartboard is connected
  static bool isDartboardConnected(WidgetTester tester) {
    final provider = getDartboardProvider(tester);
    return provider.isConnected;
  }

  /// Check if using emulator
  static bool isUsingEmulator(WidgetTester tester) {
    final provider = getDartboardProvider(tester);
    return provider.isEmulator;
  }
}
