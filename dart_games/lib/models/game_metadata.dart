/// Game-discovery metadata used by the home-screen filter bar.
///
/// Each game in `lib/constants/game_filter_registry.dart` registers exactly
/// one [GameMetadata] entry. The home screen reads the registry to decide
/// which game cards to render given the user's filter selections.
///
/// Adding a new filter criterion is additive: add a field + enum here, set
/// it on every existing entry in the registry, and update the filter bar
/// widget to render a dropdown for it. Dropping a criterion is also
/// additive (mark the field deprecated, stop rendering the dropdown — the
/// data stays so older code paths don't break).
library;

import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// Maximum number of players a game supports.
///
/// Bucketed because individual games' true caps (2, 8, 10) are useful as
/// filter values but a numeric range slider would be UI overkill given the
/// small set of distinct values.
enum MaxPlayersBucket {
  /// 1v1 only — exactly 2 players.
  twoOnly('2 (1v1)'),

  /// Up to 8 players.
  upToEight('Up to 8'),

  /// Up to 10 players.
  upToTen('Up to 10'),

  /// Up to 16 players (team games like Tiki Golf).
  upToSixteen('Up to 16');

  const MaxPlayersBucket(this.label);
  final String label;
}

/// How players compete with each other.
enum GameplayStyle {
  /// First to reach a target wins. Players don't directly affect each other.
  race('Race'),

  /// Direct attacks or eliminations between players.
  versus('Versus'),

  /// Claim positions or patterns; conflict via placement.
  strategy('Strategy');

  const GameplayStyle(this.label);
  final String label;
}

/// How much one player's actions affect other players.
enum PlayerInteraction {
  /// Players race in side-by-side lanes; no inter-player effects.
  parallel('Parallel'),

  /// Occasional disruption (steal, buff, claim) but no direct attack.
  light('Light'),

  /// Direct attacks, eliminations, damage between players.
  heavy('Heavy');

  const PlayerInteraction(this.label);
  final String label;
}

/// Approximate game length at default settings.
///
/// Length depends on settings (high HP / high target / Best Of 5 push games
/// from Quick to Long). The bucket here is the duration at the SPEC's
/// DEFAULT settings — useful as a "what should I expect" filter, not an
/// exact prediction.
enum GameLength {
  /// Less than ~10 minutes at default settings.
  quick('Quick'),

  /// ~10 to 25 minutes at default settings.
  medium('Medium'),

  /// 25+ minutes at default settings or with maxed-out options.
  long('Long');

  const GameLength(this.label);
  final String label;
}

/// Whether the game supports team play in addition to solo.
enum SoloTeamSupport {
  /// Every player for themselves; no team mode.
  soloOnly('Solo only'),

  /// Either solo OR team mode is selectable in the menu.
  soloOrTeam('Solo or Team');

  const SoloTeamSupport(this.label);
  final String label;
}

/// All filter criteria the home-screen filter bar exposes.
///
/// Adding a new criterion: add an enum here, add the corresponding field
/// to [GameMetadata], populate it for every game in the registry, and
/// render the dropdown in [GameFilterBar].
enum FilterCriterion {
  maxPlayers('Max Players'),
  gameplayStyle('Gameplay Style'),
  playerInteraction('Player Interaction'),
  gameLength('Game Length'),
  soloTeam('Solo / Team');

  const FilterCriterion(this.label);
  final String label;
}

/// Filter-relevant metadata for a single game.
///
/// `gameplayStyles` is a Set because a game CAN span styles (e.g. a hybrid
/// race-with-elimination would carry both `race` and `versus`). All current
/// games map to a single style; the Set leaves room without forcing
/// future re-modeling.
class GameMetadata {
  /// Snake-case game id matching the directory name (e.g. 'pirates_grid').
  /// Used to key the registry and to match the home-screen card's tap target.
  final String gameId;

  /// Human-readable game name (e.g. "Pirate's Grid"). Shown nowhere in the
  /// filter UI but useful for diagnostic logging when a filter row changes.
  final String displayName;

  /// How this game's name is drawn on its home-screen card.
  ///
  /// WS03 §3.2. The home screen used to pick this with an eleven-way ternary
  /// keyed on the DISPLAY STRING (`title == 'Carnival Derby' ? ... : title ==
  /// 'Target Tag' ? ...`), which meant renaming a game silently dropped it to
  /// the default style. Registering it here makes the styling data rather
  /// than control flow, and impossible to forget for game #11.
  ///
  /// Null means "use the app's default title style" — Pirate's Grid does.
  final GameCardTitleStyle? cardTitleStyle;

  /// The game's own [GameTheme] (WS03 §3.1).
  final GameTheme? theme;

  final MaxPlayersBucket maxPlayers;
  final Set<GameplayStyle> gameplayStyles;
  final PlayerInteraction playerInteraction;
  final GameLength gameLength;
  final SoloTeamSupport soloTeam;

  const GameMetadata({
    required this.gameId,
    required this.displayName,
    this.cardTitleStyle,
    this.theme,
    required this.maxPlayers,
    required this.gameplayStyles,
    required this.playerInteraction,
    required this.gameLength,
    required this.soloTeam,
  });

  /// Returns true when this game matches every active filter selection in
  /// [filters]. An entry whose value-set is empty is treated as "no filter
  /// applied for this criterion" and matches all games.
  ///
  /// Within a criterion: OR semantics (a game matches if ANY selected value
  /// matches the game's value).
  /// Across criteria: AND semantics (a game must satisfy every active
  /// criterion to be shown).
  bool matchesFilters(Map<FilterCriterion, Set<Object>> filters) {
    for (final entry in filters.entries) {
      final selected = entry.value;
      if (selected.isEmpty) continue; // no filter active for this criterion
      switch (entry.key) {
        case FilterCriterion.maxPlayers:
          if (!selected.contains(maxPlayers)) return false;
        case FilterCriterion.gameplayStyle:
          // OR within criterion: game matches if ANY of its styles is selected.
          final selectedStyles = selected.cast<GameplayStyle>();
          if (!gameplayStyles.any(selectedStyles.contains)) return false;
        case FilterCriterion.playerInteraction:
          if (!selected.contains(playerInteraction)) return false;
        case FilterCriterion.gameLength:
          if (!selected.contains(gameLength)) return false;
        case FilterCriterion.soloTeam:
          if (!selected.contains(soloTeam)) return false;
      }
    }
    return true;
  }
}

/// Per-game styling for the home-screen card label.
///
/// The sizes are DELTAS on the ambient `titleMedium` size, exactly as the
/// original ternary expressed them, so the cards keep responding to text
/// scaling. `height` and `letterSpacing` carry the two games that needed
/// optical corrections.
@immutable
class GameCardTitleStyle {
  const GameCardTitleStyle({
    required this.font,
    required this.sizeDelta,
    this.fontWeight,
    this.letterSpacing,
    this.height,
  });

  /// The GoogleFonts builder for this game's display face.
  final GameFont font;

  /// Added to the ambient titleMedium size (16 when unset).
  final double sizeDelta;

  final FontWeight? fontWeight;
  final double? letterSpacing;

  /// Line-height override. Tiki Golf uses 0.6 because Boogaloo's descender
  /// pushes its baseline visually low against its peers.
  final double? height;

  TextStyle resolve({required double baseSize, required Color color}) => font(
        fontSize: baseSize + sizeDelta,
        color: color,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
      );
}
