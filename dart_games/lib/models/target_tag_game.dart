import 'dart:math';
import 'package:uuid/uuid.dart';
import 'player.dart';

enum GameMode {
  solo,  // Every player for themselves
  team,  // Teams of 2 players
}

enum GameState {
  setup,       // Configuring game
  playing,     // Active game
  suddenDeath, // Overtime mode
  finished,    // Game over
}

class TargetTagGame {
  final String id;
  final GameMode mode;
  final int shieldMax;
  final bool soloHeroBonus;
  final DateTime startedAt;

  // Player management
  final List<String> playerIds; // All players in turn order
  final Map<String, int> targetNumbers; // playerId -> target number (1-20)

  // Team mode specific
  final Map<String, String>? playerToTeam; // playerId -> teamId
  final Map<String, List<String>>? teamPlayers; // teamId -> [playerIds]
  final Map<String, String>? teamIcons; // teamId -> icon path

  // Solo Hero Bonus (for team games with solo players)
  final Map<String, int>? soloHeroBuffNumbers; // playerId -> buff number
  final Map<String, String>? soloHeroBuffMultipliers; // playerId -> required multiplier ("double" or "triple")

  // Runtime state (using entity ID: playerId for solo, teamId for team)
  Map<String, int> shields; // entityId -> current shields
  Map<String, bool> taggedIn; // entityId -> tagged in status
  Map<String, bool> eliminated; // entityId -> eliminated status
  Map<String, int> dartsThrown; // playerId -> darts thrown this turn
  Map<String, List<String>> currentTurnDarts; // playerId -> dart segments
  Map<String, List<bool>> dartThrowTaggedInStatus; // playerId -> was tagged in when each dart was thrown
  Map<String, List<bool>> dartThrowHeroBonusHit; // playerId -> was each dart a hero bonus hit
  Map<String, List<bool>> dartThrowReachedMax; // playerId -> did each dart cause shields to reach max
  Map<String, List<bool>> dartThrowCausedElimination; // playerId -> did each dart cause an elimination
  Map<String, List<bool>> dartThrowHitOpponentTarget; // playerId -> did each dart hit an opponent's target (at the time)

  // Turn start state tracking (for score editing)
  Map<String, int> turnStartShields; // entityId -> shields at start of current turn
  Map<String, bool> turnStartTaggedIn; // entityId -> tagged in at start of current turn
  Map<String, bool> turnStartEliminated; // entityId -> eliminated at start of current turn
  String? turnStartWinnerId; // winnerId at start of current turn
  GameState turnStartState; // game state at start of current turn

  GameState state;
  int currentPlayerIndex;
  String? winnerId; // entityId (playerId or teamId)

  TargetTagGame({
    required this.id,
    required this.mode,
    required this.shieldMax,
    required this.soloHeroBonus,
    required this.startedAt,
    required this.playerIds,
    required this.targetNumbers,
    this.playerToTeam,
    this.teamPlayers,
    this.teamIcons,
    this.soloHeroBuffNumbers,
    this.soloHeroBuffMultipliers,
    Map<String, int>? shields,
    Map<String, bool>? taggedIn,
    Map<String, bool>? eliminated,
    Map<String, int>? dartsThrown,
    Map<String, List<String>>? currentTurnDarts,
    Map<String, List<bool>>? dartThrowTaggedInStatus,
    Map<String, List<bool>>? dartThrowHeroBonusHit,
    Map<String, List<bool>>? dartThrowReachedMax,
    Map<String, List<bool>>? dartThrowCausedElimination,
    Map<String, List<bool>>? dartThrowHitOpponentTarget,
    Map<String, int>? turnStartShields,
    Map<String, bool>? turnStartTaggedIn,
    Map<String, bool>? turnStartEliminated,
    String? turnStartWinnerId,
    GameState? turnStartState,
    this.state = GameState.setup,
    this.currentPlayerIndex = 0,
    this.winnerId,
  })  : shields = shields ?? {},
        taggedIn = taggedIn ?? {},
        eliminated = eliminated ?? {},
        dartsThrown = dartsThrown ?? {},
        currentTurnDarts = currentTurnDarts ?? {},
        dartThrowTaggedInStatus = dartThrowTaggedInStatus ?? {},
        dartThrowHeroBonusHit = dartThrowHeroBonusHit ?? {},
        dartThrowReachedMax = dartThrowReachedMax ?? {},
        dartThrowCausedElimination = dartThrowCausedElimination ?? {},
        dartThrowHitOpponentTarget = dartThrowHitOpponentTarget ?? {},
        turnStartShields = turnStartShields ?? {},
        turnStartTaggedIn = turnStartTaggedIn ?? {},
        turnStartEliminated = turnStartEliminated ?? {},
        turnStartWinnerId = turnStartWinnerId,
        turnStartState = turnStartState ?? GameState.setup {
    // Initialize state for each entity (player or team)
    final entities = _getEntityIds();
    for (var entityId in entities) {
      this.shields[entityId] ??= 0;
      this.taggedIn[entityId] ??= false;
      this.eliminated[entityId] ??= false;
    }

    // Initialize per-player tracking
    for (var playerId in playerIds) {
      this.dartsThrown[playerId] ??= 0;
      this.currentTurnDarts[playerId] ??= [];
      this.dartThrowTaggedInStatus[playerId] ??= [];
      this.dartThrowHeroBonusHit[playerId] ??= [];
      this.dartThrowReachedMax[playerId] ??= [];
      this.dartThrowCausedElimination[playerId] ??= [];
      this.dartThrowHitOpponentTarget[playerId] ??= [];
    }
  }

  // Factory: Create solo mode game
  factory TargetTagGame.createSolo({
    required List<String> playerIds,
    required int shieldMax,
    required bool heroBonus,
  }) {
    final targetNumbers = _assignTargetNumbers(playerIds.length);
    final playerTargets = <String, int>{};

    for (int i = 0; i < playerIds.length; i++) {
      playerTargets[playerIds[i]] = targetNumbers[i];
    }

    // Assign hero bonus to ALL players if enabled
    Map<String, int>? heroBuffNumbers;
    Map<String, String>? heroBuffMultipliers;
    if (heroBonus) {
      heroBuffNumbers = <String, int>{};
      heroBuffMultipliers = <String, String>{};
      final usedNumbers = targetNumbers.toSet();
      final availableNumbers = List.generate(20, (i) => i + 1)
          .where((n) => !usedNumbers.contains(n))
          .toList()
        ..shuffle();

      final random = Random();
      final multiplierOptions = ['double', 'triple'];

      for (int i = 0; i < playerIds.length; i++) {
        final playerId = playerIds[i];
        final buffNumber = availableNumbers[i];
        final buffMultiplier = multiplierOptions[random.nextInt(2)];

        heroBuffNumbers[playerId] = buffNumber;
        heroBuffMultipliers[playerId] = buffMultiplier;
        usedNumbers.add(buffNumber);
      }
    }

    return TargetTagGame(
      id: const Uuid().v4(),
      mode: GameMode.solo,
      shieldMax: shieldMax,
      soloHeroBonus: heroBonus,
      startedAt: DateTime.now(),
      playerIds: playerIds,
      targetNumbers: playerTargets,
      soloHeroBuffNumbers: heroBuffNumbers,
      soloHeroBuffMultipliers: heroBuffMultipliers,
      state: GameState.playing,
      currentPlayerIndex: 0,
    );
  }

  // Factory: Create team mode game
  factory TargetTagGame.createTeam({
    required Map<String, List<String>> teams, // teamId -> playerIds
    required int shieldMax,
    required bool soloHeroBonus,
    Map<String, String>? teamIconOverrides,
  }) {
    // Build player lists and mappings
    final playerToTeam = <String, String>{};
    final allPlayers = <String>[];
    final teamIconPaths = <String, String>{};

    // Use provided icon assignments if available (menu pre-selects shuffled
    // icons so the game screen matches what players saw), otherwise random.
    final iconIndices = teamIconOverrides == null
        ? (List.generate(10, (i) => i + 1)..shuffle())
        : null;
    int iconIndex = 0;

    for (final entry in teams.entries) {
      final teamId = entry.key;
      final players = entry.value;

      // Assign team icon
      teamIconPaths[teamId] = teamIconOverrides?[teamId] ??
          'assets/games/target_tag/icons/TargetTag-TeamIcon-${iconIndices![iconIndex].toString().padLeft(2, '0')}.png';
      iconIndex++;

      for (final playerId in players) {
        playerToTeam[playerId] = teamId;
        allPlayers.add(playerId);
      }
    }

    // Build turn order: Alternate between teams (1A → 2A → 1B → 2B)
    final turnOrder = _buildTeamTurnOrder(teams);

    // Assign target numbers (one per team)
    final teamIds = teams.keys.toList();
    final targetNumbers = _assignTargetNumbers(teamIds.length);
    final playerTargets = <String, int>{};

    for (int i = 0; i < teamIds.length; i++) {
      final teamId = teamIds[i];
      final teamNumber = targetNumbers[i];

      for (final playerId in teams[teamId]!) {
        playerTargets[playerId] = teamNumber;
      }
    }

    // Assign hero bonus to ALL teams if enabled
    // In team mode, all members of the same team share the same hero buff
    Map<String, int>? soloHeroBuffs;
    Map<String, String>? soloHeroMultipliers;
    if (soloHeroBonus) {
      soloHeroBuffs = <String, int>{};
      soloHeroMultipliers = <String, String>{};
      final usedNumbers = targetNumbers.toSet();
      final availableNumbers = List.generate(20, (i) => i + 1)
          .where((n) => !usedNumbers.contains(n))
          .toList()
        ..shuffle();

      final random = Random();
      final multiplierOptions = ['double', 'triple'];

      int buffIndex = 0;
      // Assign one hero buff per team (all team members share it)
      for (final entry in teams.entries) {
        final teamPlayerIds = entry.value;

        // Get a unique hero buff for this team
        final buffNumber = availableNumbers[buffIndex];
        final buffMultiplier = multiplierOptions[random.nextInt(2)];

        // Assign the same buff to all players on this team
        for (final playerId in teamPlayerIds) {
          soloHeroBuffs[playerId] = buffNumber;
          soloHeroMultipliers[playerId] = buffMultiplier;
        }

        usedNumbers.add(buffNumber);
        buffIndex++;
      }
    }

    return TargetTagGame(
      id: const Uuid().v4(),
      mode: GameMode.team,
      shieldMax: shieldMax,
      soloHeroBonus: soloHeroBonus,
      startedAt: DateTime.now(),
      playerIds: turnOrder,
      targetNumbers: playerTargets,
      playerToTeam: playerToTeam,
      teamPlayers: teams,
      teamIcons: teamIconPaths,
      soloHeroBuffNumbers: soloHeroBuffs,
      soloHeroBuffMultipliers: soloHeroMultipliers,
      state: GameState.playing,
      currentPlayerIndex: 0,
    );
  }

  // Assign random unique target numbers (1-20)
  static List<int> _assignTargetNumbers(int count) {
    final numbers = List.generate(20, (i) => i + 1)..shuffle();
    return numbers.take(count).toList();
  }

  // Build turn order for team mode: 1A → 2A → 1B → 2B
  // Solo players (teams of 1) appear twice (as both A and B)
  static List<String> _buildTeamTurnOrder(Map<String, List<String>> teams) {
    final turnOrder = <String>[];
    final teamLists = teams.values.toList();
    final maxPlayersPerTeam = 2; // Always use 2 slots per team

    for (int i = 0; i < maxPlayersPerTeam; i++) {
      for (final teamPlayers in teamLists) {
        if (i < teamPlayers.length) {
          // Regular player: add them once
          turnOrder.add(teamPlayers[i]);
        } else if (teamPlayers.length == 1) {
          // Solo player: add them again (they take both A and B slots)
          turnOrder.add(teamPlayers[0]);
        }
      }
    }

    return turnOrder;
  }

  // Get entity IDs (playerIds for solo, teamIds for team mode)
  List<String> _getEntityIds() {
    if (mode == GameMode.solo) {
      return playerIds;
    } else {
      return teamPlayers!.keys.toList();
    }
  }

  // Get entity ID for a player (playerId for solo, teamId for team)
  String _getEntityId(String playerId) {
    if (mode == GameMode.solo) {
      return playerId;
    } else {
      return playerToTeam![playerId]!;
    }
  }

  // Process a miss (dart that doesn't score)
  void processMiss(String playerId) {
    if (state != GameState.playing && state != GameState.suddenDeath) return;
    if (playerId != playerIds[currentPlayerIndex]) return;

    final entityId = _getEntityId(playerId);

    // Record tagged-in status at time of throw
    dartThrowTaggedInStatus[playerId] ??= [];
    dartThrowTaggedInStatus[playerId]!.add(taggedIn[entityId] ?? false);

    // Initialize tracking lists for this dart (all false for a miss)
    dartThrowHeroBonusHit[playerId] ??= [];
    dartThrowHeroBonusHit[playerId]!.add(false);

    dartThrowReachedMax[playerId] ??= [];
    dartThrowReachedMax[playerId]!.add(false);

    dartThrowCausedElimination[playerId] ??= [];
    dartThrowCausedElimination[playerId]!.add(false);

    dartThrowHitOpponentTarget[playerId] ??= [];
    dartThrowHitOpponentTarget[playerId]!.add(false);

    // Increment dart counter
    dartsThrown[playerId] = (dartsThrown[playerId] ?? 0) + 1;
  }

  // Process dart hit (core game logic)
  void processDartHit(String playerId, int hitNumber, String multiplier) {
    if (state != GameState.playing && state != GameState.suddenDeath) return;
    if (playerId != playerIds[currentPlayerIndex]) return;

    final entityId = _getEntityId(playerId);
    final playerTarget = targetNumbers[playerId]!;

    // Calculate shield value based on multiplier
    int shieldValue = 1; // Single
    if (multiplier == 'double') shieldValue = 2;
    if (multiplier == 'triple') shieldValue = 3;

    // Check for hero buff hit (must match exact number AND required multiplier)
    final isHeroBuff = soloHeroBuffNumbers?.containsKey(playerId) == true &&
                       hitNumber == soloHeroBuffNumbers![playerId] &&
                       soloHeroBuffMultipliers?.containsKey(playerId) == true &&
                       multiplier == soloHeroBuffMultipliers![playerId];

    // Record tagged-in status BEFORE processing this hit
    // This ensures colors don't retroactively change if player gets tagged in mid-turn
    dartThrowTaggedInStatus[playerId] ??= [];
    dartThrowTaggedInStatus[playerId]!.add(taggedIn[entityId] ?? false);

    // Initialize tracking lists for this dart
    dartThrowHeroBonusHit[playerId] ??= [];
    dartThrowReachedMax[playerId] ??= [];
    dartThrowCausedElimination[playerId] ??= [];
    dartThrowHitOpponentTarget[playerId] ??= [];

    // Store dart segment
    currentTurnDarts[playerId] ??= [];
    dartsThrown[playerId] = (dartsThrown[playerId] ?? 0) + 1;

    // Track if this is a hero bonus hit
    final bool isHeroBonusHit = isHeroBuff;
    dartThrowHeroBonusHit[playerId]!.add(isHeroBonusHit);

    // Track if shields reached max, if elimination occurred, and if opponent target was hit
    bool reachedMaxShields = false;
    bool causedElimination = false;
    bool hitOpponentTarget = false;

    // Process hero bonus hit
    if (isHeroBuff) {
      // Fill all remaining shields for the current player/team
      final shieldsBefore = shields[entityId]!;
      shields[entityId] = shieldMax;
      taggedIn[entityId] = true;
      reachedMaxShields = (shieldsBefore < shieldMax);

      // Take 1 shield from ALL other players/teams
      final allEntityIds = _getEntityIds();
      for (final otherEntityId in allEntityIds) {
        if (otherEntityId != entityId) {
          final shieldsBeforeHit = shields[otherEntityId]!;
          shields[otherEntityId] = max(0, shieldsBeforeHit - 1);

          // Check if opponent lost Tagged In status
          if (shields[otherEntityId]! < shieldMax) {
            taggedIn[otherEntityId] = false;
          }

          // Check for elimination: was at 0 AND still at 0 after hit
          if (shieldsBeforeHit == 0 && shields[otherEntityId]! == 0) {
            _eliminateEntity(otherEntityId);
            causedElimination = true;
          }
        }
      }
    }
    // Determine if this is a self-hit or opponent hit
    else if (hitNumber == playerTarget) {
      // Hit own number: Build shields (cap at shieldMax)
      final currentShields = shields[entityId]!;
      shields[entityId] = min(currentShields + shieldValue, shieldMax);

      // Check if reached Tagged In (reached max shields)
      if (shields[entityId]! >= shieldMax && currentShields < shieldMax) {
        taggedIn[entityId] = true;
        reachedMaxShields = true;
      }
    } else {
      // Hit opponent's number: Attack if tagged in
      if (taggedIn[entityId]!) {
        // Find which opponent owns this number
        String? targetEntityId;

        for (final entry in targetNumbers.entries) {
          if (entry.value == hitNumber) {
            targetEntityId = _getEntityId(entry.key);
            break;
          }
        }

        if (targetEntityId != null && targetEntityId != entityId) {
          // Only process attack if opponent is NOT already eliminated
          if (!eliminated[targetEntityId]!) {
            // Mark this dart as hitting an opponent's target number
            hitOpponentTarget = true;

            // Subtract shields from opponent
            final shieldsBeforeHit = shields[targetEntityId]!;
            shields[targetEntityId] = max(0, shieldsBeforeHit - shieldValue);

            // Check if opponent lost Tagged In status
            if (shields[targetEntityId]! < shieldMax) {
              taggedIn[targetEntityId] = false;
            }

            // Check for elimination: was at 0 AND still at 0 after hit
            if (shieldsBeforeHit == 0 && shields[targetEntityId]! == 0) {
              _eliminateEntity(targetEntityId);
              causedElimination = true;
            }
          }
        }
      }
    }

    // Record whether this dart reached max, caused elimination, or hit opponent target
    dartThrowReachedMax[playerId]!.add(reachedMaxShields);
    dartThrowCausedElimination[playerId]!.add(causedElimination);
    dartThrowHitOpponentTarget[playerId]!.add(hitOpponentTarget);

    // Check for winner or sudden death
    _checkGameEnd();
  }

  // Eliminate entity (player or team)
  void _eliminateEntity(String entityId) {
    eliminated[entityId] = true;
    taggedIn[entityId] = false;

    // In team mode, mark all team members as eliminated
    if (mode == GameMode.team) {
      final players = teamPlayers![entityId] ?? [];
      for (final playerId in players) {
        // Mark individual players for UI purposes
        eliminated[playerId] = true;
      }
    }
  }

  // Check if game has ended or entered sudden death
  void _checkGameEnd() {
    final activeEntities = _getEntityIds().where((id) => !eliminated[id]!).toList();

    if (activeEntities.length == 1) {
      // Winner found
      winnerId = activeEntities.first;
      state = GameState.finished;
    } else if (activeEntities.isEmpty) {
      // All eliminated simultaneously → Sudden Death
      state = GameState.suddenDeath;
      // Note: This should be rare but we handle it
    }
  }

  // Check if entity (player/team) is tagged in
  bool isEntityTaggedIn(String entityId) {
    return taggedIn[entityId] ?? false;
  }

  // Check if entity is eliminated
  bool isEntityEliminated(String entityId) {
    return eliminated[entityId] ?? false;
  }

  // Get shields for entity
  int getEntityShields(String entityId) {
    return shields[entityId] ?? 0;
  }

  // Get current player ID
  String getCurrentPlayerId() {
    return playerIds[currentPlayerIndex];
  }

  // Get current player object
  Player getCurrentPlayer(List<Player> players) {
    final currentPlayerId = getCurrentPlayerId();
    return players.firstWhere((p) => p.id == currentPlayerId);
  }

  // Get winner object
  Player? getWinner(List<Player> players) {
    if (winnerId == null) return null;

    // In team mode, winnerId is teamId - get first player from team
    if (mode == GameMode.team) {
      final winningPlayers = teamPlayers![winnerId] ?? [];
      if (winningPlayers.isEmpty) return null;
      try {
        return players.firstWhere((p) => p.id == winningPlayers.first);
      } catch (e) {
        return null;
      }
    } else {
      // Solo mode: winnerId is playerId
      try {
        return players.firstWhere((p) => p.id == winnerId);
      } catch (e) {
        return null;
      }
    }
  }

  // Get all winners (for team mode)
  List<Player> getWinners(List<Player> players) {
    if (winnerId == null) return [];

    if (mode == GameMode.team) {
      final winningPlayerIds = teamPlayers![winnerId] ?? [];
      return players.where((p) => winningPlayerIds.contains(p.id)).toList();
    } else {
      final winner = getWinner(players);
      return winner != null ? [winner] : [];
    }
  }

  // Advance to next player
  void advanceToNextPlayer() {
    if (state != GameState.playing && state != GameState.suddenDeath) return;

    // Reset current player's dart tracking
    final currentPlayerId = getCurrentPlayerId();
    dartsThrown[currentPlayerId] = 0;
    currentTurnDarts[currentPlayerId] = [];
    dartThrowTaggedInStatus[currentPlayerId] = [];
    dartThrowHeroBonusHit[currentPlayerId] = [];
    dartThrowReachedMax[currentPlayerId] = [];
    dartThrowCausedElimination[currentPlayerId] = [];
    dartThrowHitOpponentTarget[currentPlayerId] = [];

    // Move to next player (skip eliminated players)
    int attempts = 0;
    do {
      currentPlayerIndex = (currentPlayerIndex + 1) % playerIds.length;
      final nextPlayerId = playerIds[currentPlayerIndex];
      final nextEntityId = _getEntityId(nextPlayerId);

      // Stop if this entity is not eliminated
      if (!eliminated[nextEntityId]!) {
        break;
      }

      attempts++;
    } while (attempts < playerIds.length);

    // Save state at start of new turn (for score editing)
    _saveTurnStartState();
  }

  // Save game state at the start of a turn
  void _saveTurnStartState() {
    turnStartShields = Map.from(shields);
    turnStartTaggedIn = Map.from(taggedIn);
    turnStartEliminated = Map.from(eliminated);
    turnStartWinnerId = winnerId;
    turnStartState = state;
  }

  // Reset to the state at the start of the current turn
  void resetToStartOfTurn(String playerId) {
    // Restore shields, tagged in, eliminated status, winnerId, and state for all entities
    shields = Map.from(turnStartShields);
    taggedIn = Map.from(turnStartTaggedIn);
    eliminated = Map.from(turnStartEliminated);
    winnerId = turnStartWinnerId;
    state = turnStartState;
  }

  // Get current turn darts for a player
  List<String> getCurrentTurnDarts(String playerId) {
    return currentTurnDarts[playerId] ?? [];
  }

  // Get tagged-in status at the time each dart was thrown
  List<bool> getDartThrowTaggedInStatus(String playerId) {
    return dartThrowTaggedInStatus[playerId] ?? [];
  }

  // Get hero bonus hit status for each dart
  List<bool> getDartThrowHeroBonusHit(String playerId) {
    return dartThrowHeroBonusHit[playerId] ?? [];
  }

  // Get reached max shields status for each dart
  List<bool> getDartThrowReachedMax(String playerId) {
    return dartThrowReachedMax[playerId] ?? [];
  }

  // Get caused elimination status for each dart
  List<bool> getDartThrowCausedElimination(String playerId) {
    return dartThrowCausedElimination[playerId] ?? [];
  }

  // Get hit opponent target status for each dart
  List<bool> getDartThrowHitOpponentTarget(String playerId) {
    return dartThrowHitOpponentTarget[playerId] ?? [];
  }

  // Get darts thrown this turn for current player
  int getCurrentPlayerDartsThrown() {
    final currentPlayerId = getCurrentPlayerId();
    return dartsThrown[currentPlayerId] ?? 0;
  }

  // Check if game has winner
  bool hasWinner() {
    return winnerId != null && state == GameState.finished;
  }

  // Convert to JSON (for persistence if needed)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mode': mode.toString(),
      'shieldMax': shieldMax,
      'soloHeroBonus': soloHeroBonus,
      'startedAt': startedAt.toIso8601String(),
      'playerIds': playerIds,
      'targetNumbers': targetNumbers,
      'playerToTeam': playerToTeam,
      'teamPlayers': teamPlayers,
      'teamIcons': teamIcons,
      'soloHeroBuffNumbers': soloHeroBuffNumbers,
      'soloHeroBuffMultipliers': soloHeroBuffMultipliers,
      'shields': shields,
      'taggedIn': taggedIn,
      'eliminated': eliminated,
      'dartsThrown': dartsThrown,
      'currentTurnDarts': currentTurnDarts,
      'dartThrowTaggedInStatus': dartThrowTaggedInStatus,
      'state': state.toString(),
      'currentPlayerIndex': currentPlayerIndex,
      'winnerId': winnerId,
    };
  }
}
