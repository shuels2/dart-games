import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_games/providers/horse_race_provider.dart';
import 'package:dart_games/providers/target_tag_provider.dart';
import 'package:dart_games/providers/monster_mash_provider.dart';
import 'package:dart_games/providers/reef_royale_provider.dart';
import 'package:dart_games/providers/clockwork_quest_provider.dart';
import 'package:dart_games/providers/lunar_lander_provider.dart';
import 'package:dart_games/providers/player_provider.dart';
import 'package:dart_games/providers/dartboard_provider.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/models/monster_mash_game.dart';
import 'package:dart_games/models/reef_royale_game.dart';

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
  // MONSTER MASH HELPERS
  // ==========================================================================

  /// Get Monster Mash provider
  static MonsterMashProvider getMonsterMashProvider(WidgetTester tester) {
    final context = getContext(tester);
    return Provider.of<MonsterMashProvider>(context, listen: false);
  }

  /// Monster Mash: Get player health
  static int getMonsterMashPlayerHealth(WidgetTester tester, String playerId) {
    final provider = getMonsterMashProvider(tester);
    return provider.getHealth(playerId);
  }

  /// Monster Mash: Get player health percentage (0.0-1.0)
  static double getMonsterMashHealthPercentage(WidgetTester tester, String playerId) {
    final provider = getMonsterMashProvider(tester);
    return provider.getHealthPercentage(playerId);
  }

  /// Monster Mash: Check if player is eliminated
  static bool isMonsterMashPlayerEliminated(WidgetTester tester, String playerId) {
    final provider = getMonsterMashProvider(tester);
    return provider.isEliminated(playerId);
  }

  /// Monster Mash: Get player target number
  static int? getMonsterMashPlayerTarget(WidgetTester tester, String playerId) {
    final provider = getMonsterMashProvider(tester);
    return provider.getTargetNumber(playerId);
  }

  /// Monster Mash: Get player monster type
  static MonsterType? getMonsterMashPlayerMonsterType(WidgetTester tester, String playerId) {
    final provider = getMonsterMashProvider(tester);
    return provider.getMonsterType(playerId);
  }

  /// Monster Mash: Get player monster image path
  static String? getMonsterMashPlayerMonsterImagePath(WidgetTester tester, String playerId) {
    final provider = getMonsterMashProvider(tester);
    return provider.getMonsterImagePath(playerId);
  }

  /// Monster Mash: Get active buff
  static BonusBuff? getMonsterMashActiveBuff(WidgetTester tester) {
    final provider = getMonsterMashProvider(tester);
    return provider.getActiveBuff();
  }

  /// Monster Mash: Get current round
  static int getMonsterMashCurrentRound(WidgetTester tester) {
    final provider = getMonsterMashProvider(tester);
    return provider.getCurrentRound();
  }

  /// Monster Mash: Get round limit
  static int getMonsterMashRoundLimit(WidgetTester tester) {
    final provider = getMonsterMashProvider(tester);
    return provider.getRoundLimit();
  }

  /// Monster Mash: Check for winner
  static bool monsterMashHasWinner(WidgetTester tester) {
    final provider = getMonsterMashProvider(tester);
    return provider.hasWinner;
  }

  /// Monster Mash: Get winners
  static List<Player> getMonsterMashWinners(WidgetTester tester, List<Player> players) {
    final provider = getMonsterMashProvider(tester);
    return provider.getWinners(players);
  }

  /// Monster Mash: Get current player ID
  static String? getMonsterMashCurrentPlayerId(WidgetTester tester) {
    final provider = getMonsterMashProvider(tester);
    return provider.getCurrentPlayerId();
  }

  /// Monster Mash: Check if game is active
  static bool isMonsterMashGameActive(WidgetTester tester) {
    final provider = getMonsterMashProvider(tester);
    return provider.isGameActive;
  }

  /// Monster Mash: Get current player darts thrown
  static int getMonsterMashCurrentPlayerDartsThrown(WidgetTester tester) {
    final provider = getMonsterMashProvider(tester);
    return provider.getCurrentPlayerDartsThrown();
  }

  /// Monster Mash: Get dart throw heal amounts for a player
  static List<int> getMonsterMashDartThrowHealAmount(WidgetTester tester, String playerId) {
    final provider = getMonsterMashProvider(tester);
    return provider.getDartThrowHealAmount(playerId);
  }

  /// Monster Mash: Get dart throw damage dealt for a player
  static List<int> getMonsterMashDartThrowDamageDealt(WidgetTester tester, String playerId) {
    final provider = getMonsterMashProvider(tester);
    return provider.getDartThrowDamageDealt(playerId);
  }

  /// Monster Mash: Get dart throw target player IDs for a player
  static List<String?> getMonsterMashDartThrowTargetPlayerId(WidgetTester tester, String playerId) {
    final provider = getMonsterMashProvider(tester);
    return provider.getDartThrowTargetPlayerId(playerId);
  }

  // ==========================================================================
  // REEF ROYALE HELPERS
  // ==========================================================================

  /// Get Reef Royale provider
  static ReefRoyaleProvider getReefRoyaleProvider(WidgetTester tester) {
    final context = getContext(tester);
    return Provider.of<ReefRoyaleProvider>(context, listen: false);
  }

  /// Reef Royale: Get player pearls
  static int getReefRoyalePlayerPearls(WidgetTester tester, String playerId) {
    final provider = getReefRoyaleProvider(tester);
    return provider.getPlayerPearls(playerId);
  }

  /// Reef Royale: Get player claimed coral count
  static int getReefRoyalePlayerClaimedCount(WidgetTester tester, String playerId) {
    final provider = getReefRoyaleProvider(tester);
    return provider.getPlayerClaimedCount(playerId);
  }

  /// Reef Royale: Check if player claimed a target
  static bool reefRoyaleHasPlayerClaimed(WidgetTester tester, String playerId, int target) {
    final provider = getReefRoyaleProvider(tester);
    return provider.hasPlayerClaimed(playerId, target);
  }

  /// Reef Royale: Get player marks on a target
  static int getReefRoyalePlayerMarks(WidgetTester tester, String playerId, int target) {
    final provider = getReefRoyaleProvider(tester);
    return provider.getPlayerMarks(playerId, target);
  }

  /// Reef Royale: Check if target is locked
  static bool isReefRoyaleTargetLocked(WidgetTester tester, int target) {
    final provider = getReefRoyaleProvider(tester);
    return provider.isTargetLocked(target);
  }

  /// Reef Royale: Get active buff
  static ReefBuff? getReefRoyaleActiveBuff(WidgetTester tester) {
    final provider = getReefRoyaleProvider(tester);
    return provider.getActiveBuff();
  }

  /// Reef Royale: Get current round
  static int getReefRoyaleCurrentRound(WidgetTester tester) {
    final provider = getReefRoyaleProvider(tester);
    return provider.getCurrentRound();
  }

  /// Reef Royale: Check for winner
  static bool reefRoyaleHasWinner(WidgetTester tester) {
    final provider = getReefRoyaleProvider(tester);
    return provider.hasWinner;
  }

  /// Reef Royale: Get current player ID
  static String? getReefRoyaleCurrentPlayerId(WidgetTester tester) {
    final provider = getReefRoyaleProvider(tester);
    return provider.getCurrentPlayerId();
  }

  /// Reef Royale: Check if game is active
  static bool isReefRoyaleGameActive(WidgetTester tester) {
    final provider = getReefRoyaleProvider(tester);
    return provider.isGameActive;
  }

  /// Reef Royale: Get current player darts thrown
  static int getReefRoyaleCurrentPlayerDartsThrown(WidgetTester tester) {
    final provider = getReefRoyaleProvider(tester);
    return provider.getCurrentPlayerDartsThrown();
  }

  /// Reef Royale: Set active buff programmatically
  static void setReefRoyaleActiveBuff(WidgetTester tester, ReefBuff buff) {
    final provider = getReefRoyaleProvider(tester);
    provider.setActiveBuff(buff);
  }

  /// Reef Royale: Get game mode
  static ReefRoyaleGameMode? getReefRoyaleGameMode(WidgetTester tester) {
    final provider = getReefRoyaleProvider(tester);
    return provider.getGameMode();
  }

  /// Reef Royale: Get round limit
  static int getReefRoyaleRoundLimit(WidgetTester tester) {
    final provider = getReefRoyaleProvider(tester);
    return provider.getRoundLimit();
  }

  /// Reef Royale: Get ranked player IDs
  static List<String> getReefRoyaleRankedPlayerIds(WidgetTester tester) {
    final provider = getReefRoyaleProvider(tester);
    return provider.getRankedPlayerIds();
  }

  // ==========================================================================
  // CLOCKWORK QUEST HELPERS
  // ==========================================================================

  /// Get Clockwork Quest provider
  static ClockworkQuestProvider getClockworkQuestProvider(WidgetTester tester) {
    final context = getContext(tester);
    return Provider.of<ClockworkQuestProvider>(context, listen: false);
  }

  /// Clockwork Quest: Get player current target
  static int getClockworkQuestPlayerCurrentTarget(WidgetTester tester, String playerId) {
    final provider = getClockworkQuestProvider(tester);
    return provider.getPlayerCurrentTarget(playerId);
  }

  /// Clockwork Quest: Get player laps completed
  static int getClockworkQuestPlayerLapsCompleted(WidgetTester tester, String playerId) {
    final provider = getClockworkQuestProvider(tester);
    return provider.getPlayerLapsCompleted(playerId);
  }

  /// Clockwork Quest: Check for winner
  static bool clockworkQuestHasWinner(WidgetTester tester) {
    final provider = getClockworkQuestProvider(tester);
    return provider.hasWinner;
  }

  /// Clockwork Quest: Get current player ID
  static String? getClockworkQuestCurrentPlayerId(WidgetTester tester) {
    final provider = getClockworkQuestProvider(tester);
    return provider.getCurrentPlayerId();
  }

  /// Clockwork Quest: Check if game is active
  static bool isClockworkQuestGameActive(WidgetTester tester) {
    final provider = getClockworkQuestProvider(tester);
    return provider.isGameActive;
  }

  /// Clockwork Quest: Get current player darts thrown
  static int getClockworkQuestCurrentPlayerDartsThrown(WidgetTester tester) {
    final provider = getClockworkQuestProvider(tester);
    return provider.getCurrentPlayerDartsThrown();
  }

  /// Clockwork Quest: Set player target programmatically (for tests)
  static void setClockworkQuestPlayerTarget(WidgetTester tester, String playerId, int target) {
    final provider = getClockworkQuestProvider(tester);
    provider.currentGame!.currentTarget[playerId] = target;
    provider.notifyListeners();
  }

  // ==========================================================================
  // LUNAR LANDER HELPERS
  // ==========================================================================

  /// Get Lunar Lander provider
  static LunarLanderProvider getLunarLanderProvider(WidgetTester tester) {
    final context = getContext(tester);
    return Provider.of<LunarLanderProvider>(context, listen: false);
  }

  /// Lunar Lander: Get current altitude for a player
  static int getLunarLanderAltitude(WidgetTester tester, String playerId) {
    final provider = getLunarLanderProvider(tester);
    return provider.getCurrentAltitude(playerId);
  }

  /// Lunar Lander: Check for winner
  static bool lunarLanderHasWinner(WidgetTester tester) {
    final provider = getLunarLanderProvider(tester);
    return provider.hasWinner;
  }

  /// Lunar Lander: Get current player ID
  static String? getLunarLanderCurrentPlayerId(WidgetTester tester) {
    final provider = getLunarLanderProvider(tester);
    return provider.getCurrentPlayerId();
  }

  /// Lunar Lander: Check if game is active
  static bool isLunarLanderGameActive(WidgetTester tester) {
    final provider = getLunarLanderProvider(tester);
    return provider.isGameActive;
  }

  /// Lunar Lander: Get darts thrown for current player
  static int getLunarLanderCurrentPlayerDartsThrown(WidgetTester tester) {
    final provider = getLunarLanderProvider(tester);
    return provider.getCurrentPlayerDartsThrown();
  }

  /// Lunar Lander: Get starting altitude from current game
  static int getLunarLanderStartingAltitude(WidgetTester tester) {
    final provider = getLunarLanderProvider(tester);
    return provider.currentGame?.startingAltitude ?? 200;
  }

  /// Lunar Lander: Check if hard landing is enabled
  static bool isLunarLanderHardLandingEnabled(WidgetTester tester) {
    final provider = getLunarLanderProvider(tester);
    return provider.currentGame?.hardLandingEnabled ?? false;
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
  ///
  /// Prefers selectedPlayers (players active in the current game) to avoid
  /// returning stale leaked players from allPlayers that have different UUIDs
  /// than the IDs stored in the game's state maps (e.g., targetNumbers).
  /// Falls back to allPlayers if not found in selectedPlayers.
  static Player? findPlayerById(WidgetTester tester, String playerId) {
    final provider = getPlayerProvider(tester);
    try {
      return provider.selectedPlayers.firstWhere((p) => p.id == playerId);
    } catch (_) {
      try {
        return provider.allPlayers.firstWhere((p) => p.id == playerId);
      } catch (_) {
        return null;
      }
    }
  }

  /// Find player by name
  ///
  /// Prefers selectedPlayers (players active in the current game) to avoid
  /// returning stale leaked players from allPlayers that have different UUIDs
  /// than the IDs stored in the game's state maps (e.g., targetNumbers).
  /// Falls back to allPlayers if not found in selectedPlayers.
  static Player? findPlayerByName(WidgetTester tester, String name) {
    final provider = getPlayerProvider(tester);
    try {
      return provider.selectedPlayers.firstWhere((p) => p.name == name);
    } catch (_) {
      try {
        return provider.allPlayers.firstWhere((p) => p.name == name);
      } catch (_) {
        return null;
      }
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

  /// Simulate dartboard disconnection (triggers DartboardPausedModal)
  static void simulateDartboardDisconnection(WidgetTester tester) {
    getDartboardProvider(tester).simulateDisconnection();
  }

  /// Simulate dartboard reconnection (dismisses DartboardPausedModal)
  static void simulateDartboardReconnection(WidgetTester tester) {
    getDartboardProvider(tester).simulateReconnection();
  }
}
