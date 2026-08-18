// WS03 §3.2. The ten-case `switch (gameType)` in home_screen ended with
// `default: return;` — a game missing from it did nothing at all when its
// card was tapped, with no error and no log. That was untestable, because
// there was nothing to ask.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/constants/game_filter_registry.dart';
import 'package:dart_games/screens/games/game_menu_routes.dart';

void main() {
  group('GameMenuRoutes', () {
    test('every registered game can actually be opened', () {
      expect(GameMenuRoutes.missingGameIds, isEmpty,
          reason: 'These games appear on the home screen but have no menu '
              'route, so tapping their card silently does nothing: '
              '${GameMenuRoutes.missingGameIds}');
    });

    test('a game is reached by exactly one mechanism, not both', () {
      final both = [
        for (final g in GameFilterRegistry.all)
          if (GameMenuRoutes.builderFor(g.gameId) != null &&
              GameMenuRoutes.namedRoutes.containsKey(g.gameId))
            g.gameId
      ];
      expect(both, isEmpty,
          reason: 'A direct builder AND a named route for the same game means '
              'the two can drift apart: $both');
    });

    test('Treasure Divide keeps its named route', () {
      // It is the one game reached by name rather than a direct push, because
      // its route carries arguments the home screen does not have.
      expect(GameMenuRoutes.namedRoutes['treasure_divide'], '/treasure-divide');
      expect(GameMenuRoutes.builderFor('treasure_divide'), isNull);
    });

    test('an unknown game reports as unroutable rather than throwing', () {
      expect(GameMenuRoutes.builderFor('not_a_game'), isNull);
    });
  });

  group('registry card data', () {
    test('every game has the card fields the home screen renders', () {
      final incomplete = <String>[];
      for (final g in GameFilterRegistry.all) {
        if (g.cardKey == null ||
            g.cardImageAsset == null ||
            g.cardColor == null) {
          incomplete.add(g.gameId);
        }
      }
      expect(incomplete, isEmpty,
          reason: 'The home screen builds its cards from these fields; a null '
              'one renders a broken card: $incomplete');
    });

    test('card widget keys are unique', () {
      final keys = [for (final g in GameFilterRegistry.all) g.cardKey];
      expect(keys.toSet().length, keys.length,
          reason: 'Duplicate card keys make the UI suites match the wrong card');
    });

    test('card image assets are unique per game', () {
      // Carnival Derby uses the shared app icon; everything else is its own.
      final assets = [
        for (final g in GameFilterRegistry.all)
          if (g.gameId != 'carnival_derby') g.cardImageAsset
      ];
      expect(assets.toSet().length, assets.length);
    });
  });
}
