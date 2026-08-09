import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/game_theme.dart';
import '../constants/test_keys.dart';
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
      cardKey: HomeKeys.gladiatorArenaCard,
      cardImageAsset:
          'assets/games/gladiator_arena/icons/GladiatorArena-Icon.png',
      cardColor: Color(0xFF7B2D8E),
      displayName: 'Gladiator Arena',
      theme: GameTheme.gladiatorArena,
      cardTitleStyle: GameCardTitleStyle(
        font: GoogleFonts.cinzel,
        sizeDelta: 4,
        fontWeight: FontWeight.bold,
      ),
      maxPlayers: MaxPlayersBucket.upToEight,
      gameplayStyles: {GameplayStyle.race, GameplayStyle.versus},
      playerInteraction: PlayerInteraction.heavy,
      gameLength: GameLength.medium,
      soloTeam: SoloTeamSupport.soloOnly,
    ),
    GameMetadata(
      gameId: 'carnival_derby',
      cardKey: HomeKeys.carnivalDerbyCard,
      cardImageAsset:
          'assets/common/icons/icon.png',
      cardColor: Colors.amber,
      displayName: 'Carnival Derby',
      theme: GameTheme.carnivalDerby,
      cardTitleStyle: GameCardTitleStyle(
        font: GoogleFonts.rye,
        sizeDelta: 2,
      ),
      maxPlayers: MaxPlayersBucket.upToEight,
      gameplayStyles: {GameplayStyle.race},
      playerInteraction: PlayerInteraction.parallel,
      gameLength: GameLength.medium,
      soloTeam: SoloTeamSupport.soloOnly,
    ),
    GameMetadata(
      gameId: 'clockwork_quest',
      cardKey: HomeKeys.clockworkQuestCard,
      cardImageAsset:
          'assets/games/clockwork_quest/icons/icon.png',
      cardColor: Color(0xFF2C2C34),
      displayName: 'Clockwork Quest',
      theme: GameTheme.clockworkQuest,
      cardTitleStyle: GameCardTitleStyle(
        font: GoogleFonts.cinzelDecorative,
        sizeDelta: 3,
        fontWeight: FontWeight.bold,
      ),
      maxPlayers: MaxPlayersBucket.upToEight,
      gameplayStyles: {GameplayStyle.race},
      playerInteraction: PlayerInteraction.parallel,
      gameLength: GameLength.medium,
      soloTeam: SoloTeamSupport.soloOnly,
    ),
    GameMetadata(
      gameId: 'lunar_lander',
      cardKey: HomeKeys.lunarLanderCard,
      cardImageAsset:
          'assets/games/lunar_lander/icons/LunarLander-Icon.png',
      cardColor: Color(0xFF1B4965),
      displayName: 'Lunar Lander',
      theme: GameTheme.lunarLander,
      cardTitleStyle: GameCardTitleStyle(
        font: GoogleFonts.orbitron,
        sizeDelta: 3,
        fontWeight: FontWeight.bold,
      ),
      maxPlayers: MaxPlayersBucket.upToEight,
      gameplayStyles: {GameplayStyle.race},
      playerInteraction: PlayerInteraction.parallel,
      gameLength: GameLength.quick,
      soloTeam: SoloTeamSupport.soloOnly,
    ),
    GameMetadata(
      gameId: 'monster_mash',
      cardKey: HomeKeys.monsterMashCard,
      cardImageAsset:
          'assets/games/monster_mash/icons/MonsterMash-Icon.png',
      cardColor: Color(0xFF4B0082),
      displayName: 'Monster Mash',
      theme: GameTheme.monsterMash,
      cardTitleStyle: GameCardTitleStyle(
        font: GoogleFonts.creepster,
        sizeDelta: 6,
        fontWeight: FontWeight.bold,
      ),
      maxPlayers: MaxPlayersBucket.upToEight,
      gameplayStyles: {GameplayStyle.versus},
      playerInteraction: PlayerInteraction.heavy,
      gameLength: GameLength.medium,
      soloTeam: SoloTeamSupport.soloOnly,
    ),
    GameMetadata(
      gameId: 'pirates_grid',
      cardKey: HomeKeys.piratesGridCard,
      cardImageAsset:
          'assets/games/pirates_grid/icons/PiratesGrid-Icon.png',
      cardColor: Color(0xFF1B2838),
      displayName: "Pirate's Grid",
      theme: GameTheme.piratesGrid,
      // No cardTitleStyle on purpose: Pirate's Grid was the ternary's ELSE
      // branch and uses the app's default title style. Null means "default".
      maxPlayers: MaxPlayersBucket.twoOnly,
      gameplayStyles: {GameplayStyle.strategy},
      playerInteraction: PlayerInteraction.light,
      gameLength: GameLength.quick,
      soloTeam: SoloTeamSupport.soloOnly,
    ),
    GameMetadata(
      gameId: 'reef_royale',
      cardKey: HomeKeys.reefRoyaleCard,
      cardImageAsset:
          'assets/games/reef_royale/icons/ReefRoyale-Icon.png',
      cardColor: Color(0xFF0B3D91),
      displayName: 'Reef Royale',
      theme: GameTheme.reefRoyale,
      cardTitleStyle: GameCardTitleStyle(
        font: GoogleFonts.fredoka,
        sizeDelta: 5,
        fontWeight: FontWeight.bold,
      ),
      maxPlayers: MaxPlayersBucket.upToEight,
      gameplayStyles: {GameplayStyle.strategy},
      playerInteraction: PlayerInteraction.light,
      gameLength: GameLength.medium,
      soloTeam: SoloTeamSupport.soloOnly,
    ),
    GameMetadata(
      gameId: 'target_tag',
      cardKey: HomeKeys.targetTagCard,
      cardImageAsset:
          'assets/games/target_tag/icons/TargetTag-Icon.png',
      cardColor: Color(0xFFFF007A),
      displayName: 'Target Tag',
      theme: GameTheme.targetTag,
      cardTitleStyle: GameCardTitleStyle(
        font: GoogleFonts.luckiestGuy,
        sizeDelta: 4,
        letterSpacing: 1.2,
      ),
      maxPlayers: MaxPlayersBucket.upToTen,
      gameplayStyles: {GameplayStyle.versus},
      playerInteraction: PlayerInteraction.heavy,
      gameLength: GameLength.long,
      soloTeam: SoloTeamSupport.soloOrTeam,
    ),
    GameMetadata(
      gameId: 'tiki_golf',
      cardKey: HomeKeys.tikiGolfCard,
      cardImageAsset:
          'assets/games/tiki_golf/icons/TikiGolf-Icon.png',
      cardColor: Color(0xFF2D6A4F),
      displayName: 'Tiki Golf',
      theme: GameTheme.tikiGolf,
      cardTitleStyle: GameCardTitleStyle(
        font: GoogleFonts.boogaloo,
        sizeDelta: 6,
        fontWeight: FontWeight.bold,
        height: 0.6,
      ),
      maxPlayers: MaxPlayersBucket.upToSixteen,
      gameplayStyles: {GameplayStyle.race},
      playerInteraction: PlayerInteraction.parallel,
      gameLength: GameLength.medium,
      soloTeam: SoloTeamSupport.soloOrTeam,
    ),
    GameMetadata(
      gameId: 'treasure_divide',
      cardKey: HomeKeys.treasureDivideCard,
      cardImageAsset:
          'assets/games/treasure_divide/icons/TreasureDivide-Icon.png',
      cardColor: Color(0xFF008B8B),
      displayName: 'Treasure Divide',
      theme: GameTheme.treasureDivide,
      cardTitleStyle: GameCardTitleStyle(
        font: GoogleFonts.pirataOne,
        sizeDelta: 6,
        letterSpacing: 1.0,
      ),
      maxPlayers: MaxPlayersBucket.upToTen,
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
