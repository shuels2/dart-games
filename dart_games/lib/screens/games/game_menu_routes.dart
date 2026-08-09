import 'package:flutter/material.dart';

import '../../constants/game_filter_registry.dart';
import 'carnival_horse_race/horse_race_menu_screen.dart';
import 'clockwork_quest/clockwork_quest_menu_screen.dart';
import 'gladiator_arena/gladiator_arena_menu_screen.dart';
import 'lunar_lander/lunar_lander_menu_screen.dart';
import 'monster_mash/monster_mash_menu_screen.dart';
import 'pirates_grid/pirates_grid_menu_screen.dart';
import 'reef_royale/reef_royale_menu_screen.dart';
import 'target_tag/target_tag_menu_screen.dart';
import 'tiki_golf/tiki_golf_menu_screen.dart';

/// Maps a `gameId` to the menu screen that opens it (WS03 §3.2).
///
/// Replaces the ten-case `switch (gameType)` that lived inside
/// `home_screen.dart`. A missing case there was a silent no-op — the card
/// simply did nothing when tapped — so this deliberately exposes
/// [missingGameIds] and is covered by a test asserting every registered game
/// can actually be opened.
///
/// ─── WHY IT LIVES HERE, NOT ON GameMetadata ────────────────────────────────
/// The plan sketched a `menuBuilder` field on the registry entry. That would
/// make `lib/constants/` import ten screens, inverting the dependency
/// direction — constants are imported BY the UI layer, not the reverse, and
/// every test that touches the registry would start pulling in the whole
/// screen graph. Keeping the builders in the screens layer, keyed by the same
/// gameId, gets the switch deleted without that cost.
class GameMenuRoutes {
  const GameMenuRoutes._();

  /// Games whose menu is reached by a named route rather than a direct push.
  /// Treasure Divide is the only one, and it stays that way because its route
  /// carries arguments the home screen does not have.
  static const Map<String, String> namedRoutes = {
    'treasure_divide': '/treasure-divide',
  };

  static final Map<String, WidgetBuilder> _builders = {
    'carnival_derby': (_) => const HorseRaceMenuScreen(),
    'target_tag': (_) => const TargetTagMenuScreen(),
    'monster_mash': (_) => const MonsterMashMenuScreen(),
    'reef_royale': (_) => const ReefRoyaleMenuScreen(),
    'clockwork_quest': (_) => const ClockworkQuestMenuScreen(),
    'lunar_lander': (_) => const LunarLanderMenuScreen(),
    'pirates_grid': (_) => const PiratesGridMenuScreen(),
    'gladiator_arena': (_) => const GladiatorArenaMenuScreen(),
    'tiki_golf': (_) => const TikiGolfMenuScreen(),
  };

  static WidgetBuilder? builderFor(String gameId) => _builders[gameId];

  /// Opens [gameId]'s menu. Returns false when the game has no route at all,
  /// which is what the old switch's `default: return;` did silently.
  static bool open(BuildContext context, String gameId) {
    final route = namedRoutes[gameId];
    if (route != null) {
      Navigator.pushNamed(context, route);
      return true;
    }
    final builder = _builders[gameId];
    if (builder == null) return false;
    Navigator.push(context, MaterialPageRoute(builder: builder));
    return true;
  }

  /// Registered games with no way to open them. Must always be empty —
  /// see the test. This is the check the old switch could not offer.
  static List<String> get missingGameIds => [
        for (final g in GameFilterRegistry.all)
          if (!_builders.containsKey(g.gameId) &&
              !namedRoutes.containsKey(g.gameId))
            g.gameId
      ];
}
