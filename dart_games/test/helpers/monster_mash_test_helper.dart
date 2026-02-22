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
///
/// Announcement precedence rules (highest priority wins per dart throw):
/// 1. Hit suppressed when any secondary effect exists
/// 2. Elimination supersedes attack text
/// 3. Elimination supersedes health warning
/// 4. Elimination supersedes heal (same throw)
/// 5. Clutch heal supersedes healing amount
/// 6. Health warning only on tier crossing (not repeated same tier)
/// 7. Hat trick supersedes attack (3rd dart)
/// 8. Hat trick + elimination merged into single announcement
/// 9. Multiple eliminations combined into single announcement
/// 10. Remove darts always fires on 3rd dart or skip-with-darts
class MonsterMashTestHelper {
  final MonsterMashProvider provider;
  final MockMonsterMashAudioQueueService audioQueue;
  final List<Player> players;

  String? _currentPlayerId;
  bool _gameStartAnnounced = false;

  // Track health tiers for threshold-crossing detection
  // 0=healthy(>70%), 1=weakening(<=70%), 2=critical(<=30%), 3=barely(<=10%)
  final Map<String, int> _playerHealthTier = {};

  MonsterMashTestHelper({
    required this.provider,
    required this.audioQueue,
    required this.players,
  });

  static int _getHealthTier(double pct) {
    if (pct <= 0.10) return 3;
    if (pct <= 0.30) return 2;
    if (pct <= 0.70) return 1;
    return 0;
  }

  void _initializeHealthTiers() {
    final currentGame = provider.currentGame!;
    for (final playerId in currentGame.playerIds) {
      final pct = provider.getHealth(playerId) / currentGame.healthMax;
      _playerHealthTier[playerId] = _getHealthTier(pct);
    }
  }

  /// Call this at the start of the game (mirrors _initializeGame)
  void announceGameStart() {
    if (!_gameStartAnnounced) {
      audioQueue.announceGameStart();
      _gameStartAnnounced = true;
    }
  }

  /// Process a dart throw with all announcement logic and precedence rules.
  /// Mirrors _handleDartThrow from monster_mash_game_screen.dart.
  void processDartThrowWithAnnouncements(String sector) {
    if (!provider.isGameActive) return;

    // Lazy-initialize health tiers on first use
    if (_playerHealthTier.isEmpty) {
      _initializeHealthTiers();
    }

    _currentPlayerId ??= provider.getCurrentPlayerId();
    final currentPlayer = players.firstWhere((p) => p.id == _currentPlayerId);
    final currentGame = provider.currentGame!;

    // Announce turn if this is the first dart
    final dartsThrown = provider.getCurrentPlayerDartsThrown();
    if (dartsThrown == 0) {
      audioQueue.announceTurn(currentPlayer.name);
    }

    // Capture health before processing
    final allHealthBefore = <String, int>{};
    for (final playerId in currentGame.playerIds) {
      allHealthBefore[playerId] = provider.getHealth(playerId);
    }
    final eliminatedBefore = currentGame.playerIds
        .where((id) => provider.isEliminated(id))
        .toSet();

    // Process the dart throw
    provider.processDartThrow(sector);

    // Parse sector
    final parsed = _parseSector(sector);
    final isMiss = sector == 'None' || parsed == null;

    // --- Gather facts ---

    // Healing
    final healthAfter = provider.getHealth(_currentPlayerId!);
    final healthBefore = allHealthBefore[_currentPlayerId!]!;
    final hasHealing = healthAfter > healthBefore;
    final healAmount = hasHealing ? healthAfter - healthBefore : 0;
    final hasClutchHeal = hasHealing && healthBefore < 10 && healthBefore > 0;

    // Attack
    final dartThrowTargetPlayerIds =
        provider.getDartThrowTargetPlayerId(_currentPlayerId!);
    final dartThrowDamageDealt =
        provider.getDartThrowDamageDealt(_currentPlayerId!);
    final dartIndex = dartThrowTargetPlayerIds.length - 1;

    String? attackTargetId;
    String? attackTargetName;
    final attackMultiplier = parsed?['multiplier'] as String? ?? 'single';
    int attackDamage = 0;
    bool hasAttack = false;

    if (dartIndex >= 0 && dartThrowTargetPlayerIds[dartIndex] != null) {
      attackTargetId = dartThrowTargetPlayerIds[dartIndex]!;
      attackDamage = dartThrowDamageDealt[dartIndex];
      attackTargetName = players.firstWhere((p) => p.id == attackTargetId).name;
      hasAttack = true;
    }

    // Eliminations
    final eliminatedAfter = currentGame.playerIds
        .where((id) => provider.isEliminated(id))
        .toSet();
    final newlyEliminated = eliminatedAfter.difference(eliminatedBefore);
    final hasElimination = newlyEliminated.isNotEmpty;

    // Hat trick
    bool hasHatTrick = false;
    String? hatTrickTargetId;
    String? hatTrickTargetName;
    if (dartThrowTargetPlayerIds.length == 3) {
      final targets =
          dartThrowTargetPlayerIds.where((t) => t != null).toList();
      if (targets.length == 3 && targets.every((t) => t == targets.first)) {
        hasHatTrick = true;
        hatTrickTargetId = targets.first;
        hatTrickTargetName =
            players.firstWhere((p) => p.id == hatTrickTargetId).name;
      }
    }

    // Health warning tier crossing (only for direct attack target)
    bool hasHealthWarningCrossing = false;
    double? warningPct;
    if (hasAttack && attackTargetId != null) {
      final opponentPct =
          provider.getHealth(attackTargetId) / currentGame.healthMax;
      final newTier = _getHealthTier(opponentPct);
      final oldTier = _playerHealthTier[attackTargetId] ?? 0;
      if (newTier > oldTier) {
        hasHealthWarningCrossing = true;
        warningPct = opponentPct;
      }
    }

    // Update tiers for all players whose health changed
    for (final playerId in currentGame.playerIds) {
      final pct = provider.getHealth(playerId) / currentGame.healthMax;
      _playerHealthTier[playerId] = _getHealthTier(pct);
    }

    // --- Apply precedence rules ---
    final hasSecondary =
        hasHealing || hasClutchHeal || hasAttack || hasElimination || hasHatTrick;

    // Rule 1: Hit only fires when no secondary effect exists
    if (!hasSecondary) {
      if (!isMiss && parsed != null) {
        audioQueue.announceHit(
            parsed['number'] as int, parsed['multiplier'] as String);
      } else {
        audioQueue.announceHit(0, 'single', isMiss: true);
      }
    }

    // Determine which moment announcement fires (highest priority wins)
    if (hasHatTrick &&
        hasElimination &&
        newlyEliminated.contains(hatTrickTargetId)) {
      // Rule 8: Merged hat trick + elimination
      audioQueue.announceHatTrickElimination(hatTrickTargetName!);
      // Handle any OTHER eliminations not covered by the hat trick
      final otherEliminated =
          newlyEliminated.where((id) => id != hatTrickTargetId).toList();
      if (otherEliminated.isNotEmpty) {
        final names = otherEliminated
            .map((id) => players.firstWhere((p) => p.id == id).name)
            .toList();
        if (names.length > 1) {
          audioQueue.announceCombinedElimination(names);
        } else {
          audioQueue.announceElimination(names.first);
        }
      }
    } else if (hasElimination) {
      // Rules 2,3,4,9: Elimination supersedes attack, health warning, heal
      final eliminatedNames = newlyEliminated
          .map((id) => players.firstWhere((p) => p.id == id).name)
          .toList();
      if (eliminatedNames.length > 1) {
        audioQueue.announceCombinedElimination(eliminatedNames);
      } else {
        audioQueue.announceElimination(eliminatedNames.first);
      }
    } else if (hasHatTrick) {
      // Rule 7: Hat trick supersedes attack and health warning
      audioQueue.announceHatTrick(hatTrickTargetName!);
    } else if (hasClutchHeal) {
      // Rule 5: Clutch heal supersedes healing amount
      audioQueue.announceClutchHeal(currentPlayer.name);
    } else if (hasAttack) {
      // Attack fires (hit already suppressed by rule 1)
      audioQueue.announceAttack(attackTargetName!, attackMultiplier, attackDamage);
      // Rule 6: Health warning only on tier crossing
      if (hasHealthWarningCrossing) {
        audioQueue.announceHealthWarning(attackTargetName!, warningPct!);
      }
    } else if (hasHealing) {
      // Healing fires (hit already suppressed by rule 1)
      final multiplierStr = parsed?['multiplier'] as String? ?? 'single';
      audioQueue.announceHealing(multiplierStr, healAmount);
    }

    // Remove darts if turn is over (always fires)
    final dartsThrowAfter = provider.getCurrentPlayerDartsThrown();
    if (dartsThrowAfter >= 3 || provider.hasWinner) {
      audioQueue.announceRemoveDarts();
    }
  }

  /// Skip remaining darts with announcements.
  /// Mirrors the skip button logic.
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

    // Remove darts announcement only if darts were actually thrown
    if (dartsThrown > 0) {
      audioQueue.announceRemoveDarts();
    }
  }

  /// Handle takeout finished with announcements.
  /// Mirrors _handleTakeoutFinished.
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

    // Get buff before advancing
    final buffBefore = provider.getActiveBuff();

    provider.handleTakeoutFinished();

    // Check if buff changed (new round started)
    final buffAfter = provider.getActiveBuff();
    if (buffAfter != null && buffAfter != buffBefore) {
      audioQueue.announceBuff(buffAfter);
    }

    // Check for game end after advancing (round limit)
    if (provider.hasWinner) {
      _handleGameWon();
      _currentPlayerId = null;
      return;
    }

    _currentPlayerId = null; // Reset for next player
  }

  /// Handle game won announcements.
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
