import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:dart_games/models/pirates_grid_game.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/models/reef_royale_game.dart';
import 'package:dart_games/models/saved_game_metadata.dart';
import 'package:dart_games/models/tiki_golf_game.dart';
import 'package:dart_games/models/treasure_divide_game.dart';
import 'package:dart_games/providers/clockwork_quest_provider.dart';
import 'package:dart_games/providers/gladiator_arena_provider.dart';
import 'package:dart_games/providers/horse_race_provider.dart';
import 'package:dart_games/providers/lunar_lander_provider.dart';
import 'package:dart_games/providers/monster_mash_provider.dart';
import 'package:dart_games/providers/pirates_grid_provider.dart';
import 'package:dart_games/providers/reef_royale_provider.dart';
import 'package:dart_games/providers/target_tag_provider.dart';
import 'package:dart_games/providers/tiki_golf_provider.dart';
import 'package:dart_games/providers/treasure_divide_provider.dart';

/// Table-driven behavior suite run against EVERY game provider.
///
/// This is the shared enforcement point the per-game test files can't give
/// us: when a rule must hold for all ten providers — including games written
/// AFTER the rule — a row here is what keeps a new game from shipping
/// without it. Add a row when you add a game.
///
/// Rows exercise the provider surface that is uniform across all ten
/// (`currentGame`/`toJson`, `restoreGame`, `resumedSavedGameId`, a start
/// method), via small per-game adapter lambdas for the parts that differ.
class ProviderCase {
  final String name;
  final String gameType;

  /// Builds a fresh provider instance.
  final dynamic Function() build;

  /// Starts a minimal valid game on [provider]. Called twice per test —
  /// must succeed both times on the same provider instance.
  final void Function(dynamic provider) start;

  const ProviderCase({
    required this.name,
    required this.gameType,
    required this.build,
    required this.start,
  });
}

List<Player> _players(int n) => [
      for (int i = 1; i <= n; i++)
        Player(id: 'p$i', name: 'Player$i', createdAt: DateTime(2026)),
    ];

final List<ProviderCase> providerCases = [
  ProviderCase(
    name: 'TargetTag',
    gameType: 'target_tag',
    build: () => TargetTagProvider(),
    start: (p) => p.startSoloGame(_players(2), 5, false),
  ),
  ProviderCase(
    name: 'TreasureDivide',
    gameType: 'treasure_divide',
    build: () => TreasureDivideProvider(),
    start: (p) => p.startGame(
      playerIds: ['p1', 'p2'],
      numberOfRounds: 9,
      quarterItEnabled: false,
      customTargetsEnabled: false,
      gameMode: TreasureDivideGameMode.solo,
      teamAssignment: TreasureDivideTeamAssignment.random,
    ),
  ),
  ProviderCase(
    name: 'TikiGolf',
    gameType: 'tiki_golf',
    build: () => TikiGolfProvider(),
    start: (p) => p.startGame(
      playerIds: ['p1', 'p2'],
      maxStrokes: 3,
      mulliganEnabled: false,
      gameMode: TikiGolfGameMode.solo,
      teamAssignment: TikiGolfTeamAssignment.random,
    ),
  ),
  ProviderCase(
    name: 'HorseRace',
    gameType: 'horse_race',
    build: () => HorseRaceProvider(),
    start: (p) => p.startGame(_players(2), 200),
  ),
  ProviderCase(
    name: 'MonsterMash',
    gameType: 'monster_mash',
    build: () => MonsterMashProvider(),
    start: (p) => p.startGame(_players(2), 20, false, false, 5),
  ),
  ProviderCase(
    name: 'ReefRoyale',
    gameType: 'reef_royale',
    build: () => ReefRoyaleProvider(),
    start: (p) => p.startGame(
      _players(2),
      ReefRoyaleGameMode.standard,
      false, // easyClaim
      false, // neighborNumbers
      false, // randomReefs
      false, // bonusBuffs
      false, // showHints
      false, // speedPlay
      8, // roundLimit
    ),
  ),
  ProviderCase(
    name: 'ClockworkQuest',
    gameType: 'clockwork_quest',
    build: () => ClockworkQuestProvider(),
    start: (p) => p.startGame(_players(2), false, false, 1),
  ),
  ProviderCase(
    name: 'LunarLander',
    gameType: 'lunar_lander',
    build: () => LunarLanderProvider(),
    start: (p) => p.startGame(
      playerIds: ['p1', 'p2'],
      startingAltitude: 200,
      hardLandingEnabled: false,
    ),
  ),
  ProviderCase(
    name: 'PiratesGrid',
    gameType: 'pirates_grid',
    build: () => PiratesGridProvider(),
    start: (p) => p.startGame(
      ['p1', 'p2'],
      TargetDifficulty.easy,
      1, // bestOf
      false, // stealMode
      false, // speedPlay
    ),
  ),
  ProviderCase(
    name: 'GladiatorArena',
    gameType: 'gladiator_arena',
    build: () => GladiatorArenaProvider(),
    start: (p) => p.startGame(
      playerIds: ['p1', 'p2'],
      targetScore: 200,
      doubleFinishEnabled: false,
      shieldRoundEnabled: false,
      speedPlayEnabled: false,
      random: Random(0),
    ),
  ),
];

/// Wraps the provider's current game state in a metadata row, the same way
/// each provider's own saveGame does. Only gameType/gameState matter to
/// restoreGame; the display fields are dummies.
SavedGameMetadata _metadataFor(ProviderCase c, dynamic provider) {
  final json = (provider.currentGame as dynamic).toJson() as Map<String, dynamic>;
  return SavedGameMetadata.create(
    gameType: c.gameType,
    playerNames: const ['Player1', 'Player2'],
    progressInfo: 'test',
    gameModeName: 'test',
    leadingPlayerName: 'Player1',
    leadingPlayerScore: '0',
    gameState: json,
  );
}

void main() {
  group('Provider base behavior — saved-game slot lifecycle', () {
    for (final c in providerCases) {
      group(c.name, () {
        test('restoreGame records the saved-game slot id', () {
          final provider = c.build();
          c.start(provider);
          expect(provider.currentGame, isNotNull,
              reason: 'start() must produce a game — check the row\'s args');

          final meta = _metadataFor(c, provider);
          provider.restoreGame(meta);

          expect(provider.currentGame, isNotNull,
              reason: 'restore must rebuild the game from gameState');
          expect(provider.resumedSavedGameId, meta.id,
              reason: 'resume must remember the slot so saves overwrite it');
        });

        test('a NEW game after an abandoned resume does not inherit the slot',
            () {
          // The F2 data-loss bug: resume game A, back out with Don't Save,
          // start a new game B. Nothing on that path cleared the slot id, so
          // B's first save was written with existingId = A's slot —
          // overwriting, and effectively destroying, the still-resumable A.
          final provider = c.build();
          c.start(provider);
          final meta = _metadataFor(c, provider);
          provider.restoreGame(meta);
          expect(provider.resumedSavedGameId, meta.id);

          // Abandon (Don't Save just pops the route — no provider call) and
          // start a fresh game.
          c.start(provider);

          expect(provider.currentGame, isNotNull);
          expect(provider.resumedSavedGameId, isNull,
              reason:
                  'a genuinely new game must not save into the abandoned '
                  'game\'s slot — that overwrites a still-resumable game');
        });
      });
    }
  });
}
