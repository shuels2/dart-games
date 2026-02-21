import 'package:dart_games/models/monster_mash_game.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/providers/monster_mash_provider.dart';
import '../mocks/mock_monster_mash_audio_queue_service.dart';

/// Helper class to simulate the game screen's announcement logic in tests.
///
/// This replicates the announcement trigger logic from
/// monster_mash_game_screen.dart (_handleDartThrow, _handleTakeoutFinished,
/// _handleGameWon) so tests can validate exact announcement sequences
/// without needing a widget tree.
class MonsterMashTestHelper {
  final MonsterMashProvider provider;
  final MockMonsterMashAudioQueueService audioQueue;
  final List<Player> players;

  String? _currentPlayerId;
  bool _gameStartAnnounced = false;

  MonsterMashTestHelper({
    required this.provider,
    required this.audioQueue,
    required this.players,
  });

  /// Call this at the start of the game (mirrors _initializeGame)
  void announceGameStart() {
    if (!_gameStartAnnounced) {
      audioQueue.announceGameStart();
      _gameStartAnnounced = true;
    }
  }

  /// Process a dart throw with all announcement logic.
  /// Mirrors _handleDartThrow from monster_mash_game_screen.dart lines 171-268.
  void processDartThrowWithAnnouncements(String sector) {
    if (!provider.isGameActive) return;

    _currentPlayerId ??= provider.getCurrentPlayerId();
    final currentPlayer = players.firstWhere((p) => p.id == _currentPlayerId);
    final currentGame = provider.currentGame!;

    // Announce turn if this is the first dart (mirrors _announceCurrentPlayerTurn)
    final dartsThrown = provider.getCurrentPlayerDartsThrown();
    if (dartsThrown == 0) {
      audioQueue.announceTurn(currentPlayer.name);
    }

    // Capture health before processing (mirrors lines 187-191)
    final allHealthBefore = <String, int>{};
    for (final playerId in currentGame.playerIds) {
      allHealthBefore[playerId] = provider.getHealth(playerId);
    }
    final eliminatedBefore = currentGame.playerIds
        .where((id) => provider.isEliminated(id))
        .toSet();

    // Process the dart throw
    provider.processDartThrow(sector);

    // Parse sector for announcements
    final parsed = _parseSector(sector);
    final isMiss = sector == 'None' || parsed == null;

    // 1. Hit announcement (lines 200-205)
    if (!isMiss && parsed != null) {
      audioQueue.announceHit(
          parsed['number'] as int, parsed['multiplier'] as String);
    } else {
      audioQueue.announceHit(0, 'single', isMiss: true);
    }

    // 2. Healing announcements (lines 207-219)
    final healthAfter = provider.getHealth(_currentPlayerId!);
    final healthBefore = allHealthBefore[_currentPlayerId!]!;
    if (healthAfter > healthBefore) {
      final healAmount = healthAfter - healthBefore;
      final multiplierStr = parsed?['multiplier'] as String? ?? 'single';
      audioQueue.announceHealing(multiplierStr, healAmount);

      // Clutch heal check (lines 215-218)
      if (healthBefore < 10 && healthBefore > 0) {
        audioQueue.announceClutchHeal(currentPlayer.name);
      }
    }

    // 3. Attack announcements (lines 221-238)
    final dartThrowTargetPlayerIds =
        provider.getDartThrowTargetPlayerId(_currentPlayerId!);
    final dartThrowDamageDealt =
        provider.getDartThrowDamageDealt(_currentPlayerId!);
    final dartIndex = dartThrowTargetPlayerIds.length - 1;

    if (dartIndex >= 0 && dartThrowTargetPlayerIds[dartIndex] != null) {
      final targetId = dartThrowTargetPlayerIds[dartIndex]!;
      final damage = dartThrowDamageDealt[dartIndex];
      final targetPlayer = players.firstWhere((p) => p.id == targetId);
      final multiplierStr = parsed?['multiplier'] as String? ?? 'single';
      audioQueue.announceAttack(targetPlayer.name, multiplierStr, damage);

      // Health warning for damaged opponent (lines 233-237)
      final opponentHealthAfter = provider.getHealth(targetId);
      final healthMax = currentGame.healthMax;
      final pct = opponentHealthAfter / healthMax;
      audioQueue.announceHealthWarning(targetPlayer.name, pct);
    }

    // 4. Elimination announcements (lines 240-246)
    final eliminatedAfter = currentGame.playerIds
        .where((id) => provider.isEliminated(id))
        .toSet();
    final newlyEliminated = eliminatedAfter.difference(eliminatedBefore);
    for (final eliminatedId in newlyEliminated) {
      final eliminatedPlayer = players.firstWhere((p) => p.id == eliminatedId);
      audioQueue.announceElimination(eliminatedPlayer.name);
    }

    // 5. Hat trick check (lines 248-255)
    if (dartThrowTargetPlayerIds.length == 3) {
      final targets =
          dartThrowTargetPlayerIds.where((t) => t != null).toList();
      if (targets.length == 3 && targets.every((t) => t == targets.first)) {
        final targetPlayer = players.firstWhere((p) => p.id == targets.first);
        audioQueue.announceHatTrick(targetPlayer.name);
      }
    }

    // 6. Remove darts if turn is over (lines 258-262)
    final dartsThrowAfter = provider.getCurrentPlayerDartsThrown();
    if (dartsThrowAfter >= 3 || provider.hasWinner) {
      audioQueue.announceRemoveDarts();
    }
  }

  /// Skip remaining darts with announcements.
  /// Mirrors the skip button logic from lines 662-676.
  void skipTurn() {
    final dartsThrown = provider.getCurrentPlayerDartsThrown();

    // Announce turn if this is the first action
    if (dartsThrown == 0) {
      _currentPlayerId ??= provider.getCurrentPlayerId();
      final currentPlayer =
          players.firstWhere((p) => p.id == _currentPlayerId);
      audioQueue.announceTurn(currentPlayer.name);
    }

    provider.skipTurn();

    // Remove darts announcement only if darts were actually thrown (line 665)
    if (dartsThrown > 0) {
      audioQueue.announceRemoveDarts();
    }
    // If 0 darts thrown, screen auto-triggers takeoutFinished with no
    // remove darts announcement (lines 672-675)
  }

  /// Handle takeout finished with announcements.
  /// Mirrors _handleTakeoutFinished from lines 287-324.
  void handleTakeoutFinished() {
    if (provider.hasWinner) {
      _handleGameWon();
      _currentPlayerId = null;
      return;
    }

    if (!provider.isGameActive) {
      _currentPlayerId = null;
      return;
    }

    // Get buff before advancing (line 299)
    final buffBefore = provider.getActiveBuff();

    provider.handleTakeoutFinished();

    // Check if buff changed (new round started) (lines 304-308)
    final buffAfter = provider.getActiveBuff();
    if (buffAfter != null && buffAfter != buffBefore) {
      audioQueue.announceBuff(buffAfter);
    }

    // Check for game end after advancing (round limit) (lines 312-317)
    if (provider.hasWinner) {
      _handleGameWon();
      _currentPlayerId = null;
      return;
    }

    _currentPlayerId = null; // Reset for next player
  }

  /// Handle game won announcements.
  /// Mirrors _handleGameWon from lines 335-354.
  void _handleGameWon() {
    final winners = provider.getWinners(players);
    if (winners.isNotEmpty) {
      audioQueue.announceWinners(winners.map((p) => p.name).toList());
    }
  }

  /// Parse dartboard sector string (mirrors _parseSector in game screen)
  Map<String, dynamic>? _parseSector(String sector) {
    if (sector == 'Bull') return {'number': 50, 'multiplier': 'single'};
    if (sector == '25') return {'number': 25, 'multiplier': 'single'};
    if (sector == 'None' || sector.isEmpty) return null;

    final match = RegExp(r'[A-Za-z](\d+)').firstMatch(sector);
    if (match == null) return null;

    final baseNumber = int.parse(match.group(1)!);
    String multiplier = 'single';
    if (sector.startsWith('D') || sector.startsWith('d')) multiplier = 'double';
    if (sector.startsWith('T') || sector.startsWith('t')) multiplier = 'triple';

    return {'number': baseNumber, 'multiplier': multiplier};
  }

  /// Verify announcements match expected list exactly
  void verifyAnnouncements(List<String> expected) {
    final actual = audioQueue.announcements;
    if (actual.length != expected.length) {
      throw Exception(
          'Announcement count mismatch:\n'
          'Expected ${expected.length} announcements: $expected\n'
          'Got ${actual.length} announcements: $actual');
    }

    for (int i = 0; i < expected.length; i++) {
      if (actual[i] != expected[i]) {
        throw Exception(
            'Announcement mismatch at index $i:\n'
            'Expected: "${expected[i]}"\n'
            'Got: "${actual[i]}"\n'
            'Full expected: $expected\n'
            'Full actual: $actual');
      }
    }
  }

  /// Clear announcements for next test step
  void clearAnnouncements() {
    audioQueue.clearAnnouncements();
  }
}
