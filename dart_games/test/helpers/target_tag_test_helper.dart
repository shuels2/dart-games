import 'package:dart_games/models/player.dart';
import 'package:dart_games/models/target_tag_game.dart';
import 'package:dart_games/providers/target_tag_provider.dart';
import '../mocks/mock_target_tag_audio_queue_service.dart';

/// Helper class to simulate game screen announcement logic in tests
class TargetTagTestHelper {
  final TargetTagProvider provider;
  final MockTargetTagAudioQueueService audioQueue;
  final List<Player> players;

  // Track state before each dart throw for proper announcements
  final Map<String, int> _shieldsBefore = {};
  final Map<String, bool> _taggedInBefore = {};
  Set<String> _eliminatedBefore = {};
  String? _currentPlayerId;
  bool _gameStartAnnounced = false;

  TargetTagTestHelper({
    required this.provider,
    required this.audioQueue,
    required this.players,
  });

  /// Call this at the start of the game
  void announceGameStart() {
    if (!_gameStartAnnounced) {
      audioQueue.announceGameStart();
      _gameStartAnnounced = true;
    }
  }

  /// Call this before processing a dart throw
  void captureStateBefore() {
    final game = provider.currentGame!;
    _currentPlayerId = provider.getCurrentPlayerId();

    // Capture all player/team shields
    _shieldsBefore.clear();
    _taggedInBefore.clear();
    for (final playerId in game.playerIds) {
      _shieldsBefore[playerId] = provider.getShields(playerId);
      _taggedInBefore[playerId] = provider.isTaggedIn(playerId);
    }

    // Capture eliminated players
    _eliminatedBefore = game.playerIds
        .where((id) => provider.isEliminated(id))
        .toSet();
  }

  /// Process dart throw with announcements
  void processDartThrowWithAnnouncements(String sector) {
    _currentPlayerId ??= provider.getCurrentPlayerId();

    final currentPlayer = players.firstWhere((p) => p.id == _currentPlayerId);
    final game = provider.currentGame!;

    // Announce turn if this is the first dart
    final dartsThrown = provider.getCurrentPlayerDartsThrown();
    if (dartsThrown == 0) {
      audioQueue.announceTurn(currentPlayer.name);
    }

    // Capture state before
    captureStateBefore();
    final wasTaggedIn = _taggedInBefore[currentPlayer.id] ?? false;

    // Process the throw
    provider.processDartThrow(sector);

    // Get state after
    final shieldsAfter = provider.getShields(currentPlayer.id);
    final isNowTaggedIn = provider.isTaggedIn(currentPlayer.id);
    final dartsThrowAfter = provider.getCurrentPlayerDartsThrown();

    // Get dart throw tracking info
    final dartIndex = dartsThrowAfter - 1;
    final hitOpponentTargetList = provider.getDartThrowHitOpponentTarget(currentPlayer.id);
    final heroBonusHitList = provider.getDartThrowHeroBonusHit(currentPlayer.id);

    final didHitOpponentTarget = dartIndex >= 0 && dartIndex < hitOpponentTargetList.length
        ? hitOpponentTargetList[dartIndex]
        : false;
    final didHitHeroBonus = dartIndex >= 0 && dartIndex < heroBonusHitList.length
        ? heroBonusHitList[dartIndex]
        : false;

    // Parse sector
    final parsed = _parseSector(sector);

    // ===== PHASE 1: GATHER FACTS =====

    // Check current player shield changes
    final shieldsBefore = _shieldsBefore[currentPlayer.id] ?? 0;
    final hasShieldGain = !wasTaggedIn && parsed != null && shieldsAfter > shieldsBefore;
    final hasTaggedIn = isNowTaggedIn && !wasTaggedIn;
    final hasSuccessfulTag = didHitOpponentTarget || (didHitHeroBonus && wasTaggedIn);

    // Check opponent status changes
    final eliminatedAfter = game.playerIds
        .where((id) => provider.isEliminated(id))
        .toSet();
    final newlyEliminated = eliminatedAfter.difference(_eliminatedBefore);
    final hasElimination = newlyEliminated.isNotEmpty;

    // Check for opponents who lost tagged-in status
    final lostTaggedInPlayers = <String>[];
    for (final playerId in game.playerIds) {
      final wasPreviouslyTaggedIn = _taggedInBefore[playerId] ?? false;
      final isStillTaggedIn = provider.isTaggedIn(playerId);
      if (wasPreviouslyTaggedIn && !isStillTaggedIn && playerId != currentPlayer.id) {
        lostTaggedInPlayers.add(playerId);
      }
    }
    final hasTaggedOut = lostTaggedInPlayers.isNotEmpty;

    // Check for opponents at low shields (exactly 1)
    final lowShieldPlayers = <String>[];
    for (final playerId in game.playerIds) {
      if (provider.isEliminated(playerId)) continue;
      if (playerId == currentPlayer.id) continue;
      final sb = _shieldsBefore[playerId] ?? 0;
      final sn = provider.getShields(playerId);
      if (sb > 1 && sn == 1) {
        lowShieldPlayers.add(playerId);
      }
    }
    final hasLowShields = lowShieldPlayers.isNotEmpty;

    // Check for opponents at vulnerable (exactly 0 shields, not eliminated)
    final vulnerablePlayers = <String>[];
    for (final playerId in game.playerIds) {
      if (provider.isEliminated(playerId)) continue;
      if (playerId == currentPlayer.id) continue;
      final sb = _shieldsBefore[playerId] ?? 0;
      final sn = provider.getShields(playerId);
      if (sb > 0 && sn == 0) {
        vulnerablePlayers.add(playerId);
      }
    }
    final hasVulnerable = vulnerablePlayers.isNotEmpty;

    // Determine if any secondary effect exists
    final hasSecondary = hasShieldGain || hasTaggedIn || hasSuccessfulTag ||
        hasTaggedOut || hasLowShields || hasVulnerable || hasElimination;

    // ===== PHASE 2: APPLY PRECEDENCE (max 1 moment announcement) =====

    // Hit/Miss: only fire if NO secondary effect exists
    if (!hasSecondary) {
      if (parsed != null) {
        audioQueue.announceHit(
          parsed['number'] as int,
          parsed['multiplier'] as String,
        );
      } else {
        audioQueue.announceHit(0, 'single', isMiss: true);
      }
    }

    // Pick highest-priority moment and fire exactly one
    if (hasElimination) {
      // Priority 1: Elimination
      if (game.mode == GameMode.team) {
        final eliminatedByTeam = <String, List<String>>{};
        for (final playerId in newlyEliminated) {
          final teamId = game.playerToTeam![playerId]!;
          eliminatedByTeam[teamId] ??= [];
          final playerName = players.firstWhere((p) => p.id == playerId).name;
          if (!eliminatedByTeam[teamId]!.contains(playerName)) {
            eliminatedByTeam[teamId]!.add(playerName);
          }
        }
        for (final entry in eliminatedByTeam.entries) {
          final teamId = entry.key;
          final teamPlayerIds = game.teamPlayers![teamId]!;
          final teamNames = teamPlayerIds
              .map((id) => players.firstWhere((p) => p.id == id).name)
              .toList();
          audioQueue.announceEliminated(teamNames);
        }
      } else {
        final eliminatedNames = newlyEliminated
            .map((id) => players.firstWhere((p) => p.id == id).name)
            .toList();
        audioQueue.announceEliminated(eliminatedNames);
      }
    } else if (hasVulnerable) {
      // Priority 2: Vulnerable
      if (game.mode == GameMode.team) {
        final vulnerableByTeam = <String, List<String>>{};
        for (final playerId in vulnerablePlayers) {
          final teamId = game.playerToTeam![playerId]!;
          vulnerableByTeam[teamId] ??= [];
        }
        for (final teamId in vulnerableByTeam.keys) {
          final teamPlayerIds = game.teamPlayers![teamId]!;
          final teamNames = teamPlayerIds
              .map((id) => players.firstWhere((p) => p.id == id).name)
              .toList();
          audioQueue.announceVulnerable(teamNames);
        }
      } else {
        final vulnerableNames = vulnerablePlayers
            .map((id) => players.firstWhere((p) => p.id == id).name)
            .toList();
        audioQueue.announceVulnerable(vulnerableNames);
      }
    } else if (hasLowShields) {
      // Priority 3: Low Shields
      if (game.mode == GameMode.team) {
        final lowShieldsByTeam = <String, List<String>>{};
        for (final playerId in lowShieldPlayers) {
          final teamId = game.playerToTeam![playerId]!;
          lowShieldsByTeam[teamId] ??= [];
        }
        for (final teamId in lowShieldsByTeam.keys) {
          final teamPlayerIds = game.teamPlayers![teamId]!;
          final teamNames = teamPlayerIds
              .map((id) => players.firstWhere((p) => p.id == id).name)
              .toList();
          audioQueue.announceLowShields(teamNames);
        }
      } else {
        final lowShieldNames = lowShieldPlayers
            .map((id) => players.firstWhere((p) => p.id == id).name)
            .toList();
        audioQueue.announceLowShields(lowShieldNames);
      }
    } else if (hasTaggedOut) {
      // Priority 4: Tagged Out
      if (game.mode == GameMode.team) {
        final lostByTeam = <String, List<String>>{};
        for (final playerId in lostTaggedInPlayers) {
          final teamId = game.playerToTeam![playerId]!;
          lostByTeam[teamId] ??= [];
        }
        for (final teamId in lostByTeam.keys) {
          final teamPlayerIds = game.teamPlayers![teamId]!;
          final teamNames = teamPlayerIds
              .map((id) => players.firstWhere((p) => p.id == id).name)
              .toList();
          audioQueue.announceTaggedOut(teamNames);
        }
      } else {
        final lostNames = lostTaggedInPlayers
            .map((id) => players.firstWhere((p) => p.id == id).name)
            .toList();
        audioQueue.announceTaggedOut(lostNames);
      }
    } else if (hasSuccessfulTag) {
      // Priority 5: Successful Tag (no status change triggered)
      audioQueue.announceSuccessfulTag();
    } else if (hasTaggedIn) {
      // Priority 6: Tagged In
      List<String> playerNames;
      if (game.mode == GameMode.team) {
        final teamId = game.playerToTeam![currentPlayer.id]!;
        final teamPlayerIds = game.teamPlayers![teamId]!;
        playerNames = teamPlayerIds
            .map((id) => players.firstWhere((p) => p.id == id).name)
            .toList();
      } else {
        playerNames = [currentPlayer.name];
      }
      audioQueue.announceTaggedIn(playerNames);
    } else if (hasShieldGain) {
      // Priority 7: Shield Gained
      audioQueue.announceShieldGained(currentPlayer.name, shieldsAfter, game.shieldMax);
    }
    // Priority 8: Hit/Miss already handled above (when !hasSecondary)

    // ===== ALWAYS-FIRE ANNOUNCEMENTS (not counted toward moment limit) =====

    // Remove darts announcement (if turn is over)
    if (provider.shouldPromptTakeout) {
      audioQueue.announceRemoveDarts();
    }

    // Game over / winner announcement
    if (provider.hasWinner) {
      final winners = provider.getWinners(players);
      final winnerNames = winners.map((p) => p.name).toList();
      audioQueue.announceWinner(winnerNames);
    }
  }

  /// Skip remaining darts with announcements
  void skipTurn() {
    final currentPlayer = players.firstWhere((p) => p.id == provider.getCurrentPlayerId());
    final dartsThrown = provider.getCurrentPlayerDartsThrown();

    // Announce turn if this is the first action
    if (dartsThrown == 0) {
      audioQueue.announceTurn(currentPlayer.name);
    }

    provider.skipTurn();

    if (provider.shouldPromptTakeout) {
      audioQueue.announceRemoveDarts();
    }
  }

  /// Handle takeout finished
  void handleTakeoutFinished() {
    provider.handleTakeoutFinished();
    _currentPlayerId = null; // Reset for next player
  }

  /// Parse dartboard sector string
  Map<String, dynamic>? _parseSector(String sector) {
    if (sector == 'Bull') {
      return {'number': 50, 'multiplier': 'single'};
    }
    if (sector == '25') {
      return {'number': 25, 'multiplier': 'single'};
    }
    if (sector == 'None' || sector == 'Miss' || sector.isEmpty) {
      return null;
    }

    final match = RegExp(r'[A-Za-z](\d+)').firstMatch(sector);
    if (match == null) return null;

    final baseNumber = int.parse(match.group(1)!);
    String multiplier = 'single';

    if (sector.startsWith('D') || sector.startsWith('d')) {
      multiplier = 'double';
    } else if (sector.startsWith('T') || sector.startsWith('t')) {
      multiplier = 'triple';
    }

    return {'number': baseNumber, 'multiplier': multiplier};
  }

  /// Verify announcements match expected
  void verifyAnnouncements(List<String> expected) {
    final actual = audioQueue.announcements;
    if (actual.length != expected.length) {
      throw Exception(
        'Announcement count mismatch:\n'
        'Expected ${expected.length} announcements: $expected\n'
        'Got ${actual.length} announcements: $actual'
      );
    }

    for (int i = 0; i < expected.length; i++) {
      if (actual[i] != expected[i]) {
        throw Exception(
          'Announcement mismatch at index $i:\n'
          'Expected: "${expected[i]}"\n'
          'Got: "${actual[i]}"\n'
          'Full expected: $expected\n'
          'Full actual: $actual'
        );
      }
    }
  }

  /// Clear announcements for next test step
  void clearAnnouncements() {
    audioQueue.clearAnnouncements();
  }
}
