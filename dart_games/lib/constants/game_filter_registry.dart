import '../models/game_metadata.dart';

/// Authoritative registry of filter metadata for every game.
///
/// **MANDATORY for every new game.** Phase 4 of the game.build skill (and
/// Rule §42 in the Accumulated Build Quality Rules) requires the new
/// game's `GameMetadata` entry to be added here in the same change that
/// adds the game card to `lib/screens/home_screen.dart`. AR-4 audit grep
/// fails if the registry is missing the new game's id.
///
/// The order of entries here doesn't affect the home screen's render
/// order (that's controlled separately in `home_screen.dart`'s `games`
/// list). Order entries here however you like; alphabetical-by-displayName
/// is the current convention.
class GameFilterRegistry {
  static const List<GameMetadata> _all = [
    GameMetadata(
      gameId: 'gladiator_arena',
      displayName: 'Gladiator Arena',
      maxPlayers: MaxPlayersBucket.upToEight,
      gameplayStyles: {GameplayStyle.race, GameplayStyle.versus},
      playerInteraction: PlayerInteraction.heavy,
      gameLength: GameLength.medium,
      soloTeam: SoloTeamSupport.soloOnly,
    ),
    GameMetadata(
      gameId: 'carnival_derby',
      displayName: 'Carnival Derby',
      maxPlayers: MaxPlayersBucket.upToEight,
      gameplayStyles: {GameplayStyle.race},
      playerInteraction: PlayerInteraction.parallel,
      gameLength: GameLength.medium,
      soloTeam: SoloTeamSupport.soloOnly,
    ),
    GameMetadata(
      gameId: 'clockwork_quest',
      displayName: 'Clockwork Quest',
      maxPlayers: MaxPlayersBucket.upToEight,
      gameplayStyles: {GameplayStyle.race},
      playerInteraction: PlayerInteraction.parallel,
      gameLength: GameLength.medium,
      soloTeam: SoloTeamSupport.soloOnly,
    ),
    GameMetadata(
      gameId: 'lunar_lander',
      displayName: 'Lunar Lander',
      maxPlayers: MaxPlayersBucket.upToEight,
      gameplayStyles: {GameplayStyle.race},
      playerInteraction: PlayerInteraction.parallel,
      gameLength: GameLength.quick,
      soloTeam: SoloTeamSupport.soloOnly,
    ),
    GameMetadata(
      gameId: 'monster_mash',
      displayName: 'Monster Mash',
      maxPlayers: MaxPlayersBucket.upToEight,
      gameplayStyles: {GameplayStyle.versus},
      playerInteraction: PlayerInteraction.heavy,
      gameLength: GameLength.medium,
      soloTeam: SoloTeamSupport.soloOnly,
    ),
    GameMetadata(
      gameId: 'pirates_grid',
      displayName: "Pirate's Grid",
      maxPlayers: MaxPlayersBucket.twoOnly,
      gameplayStyles: {GameplayStyle.strategy},
      playerInteraction: PlayerInteraction.light,
      gameLength: GameLength.quick,
      soloTeam: SoloTeamSupport.soloOnly,
    ),
    GameMetadata(
      gameId: 'reef_royale',
      displayName: 'Reef Royale',
      maxPlayers: MaxPlayersBucket.upToEight,
      gameplayStyles: {GameplayStyle.strategy},
      playerInteraction: PlayerInteraction.light,
      gameLength: GameLength.medium,
      soloTeam: SoloTeamSupport.soloOnly,
    ),
    GameMetadata(
      gameId: 'target_tag',
      displayName: 'Target Tag',
      maxPlayers: MaxPlayersBucket.upToTen,
      gameplayStyles: {GameplayStyle.versus},
      playerInteraction: PlayerInteraction.heavy,
      gameLength: GameLength.long,
      soloTeam: SoloTeamSupport.soloOrTeam,
    ),
    GameMetadata(
      gameId: 'tiki_golf',
      displayName: 'Tiki Golf',
      maxPlayers: MaxPlayersBucket.upToSixteen,
      gameplayStyles: {GameplayStyle.race},
      playerInteraction: PlayerInteraction.parallel,
      gameLength: GameLength.medium,
      soloTeam: SoloTeamSupport.soloOrTeam,
    ),
  ];

  /// Every registered game's metadata, in registration order.
  static List<GameMetadata> get all => _all;

  /// Lookup by game id, or null if the id isn't registered.
  static GameMetadata? byId(String gameId) {
    for (final m in _all) {
      if (m.gameId == gameId) return m;
    }
    return null;
  }

  /// Returns games that match every active criterion in [filters].
  /// See [GameMetadata.matchesFilters] for the AND/OR semantics.
  static List<GameMetadata> filter(Map<FilterCriterion, Set<Object>> filters) {
    return _all.where((m) => m.matchesFilters(filters)).toList();
  }
}
