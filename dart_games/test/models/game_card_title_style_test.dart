// WS03 §3.2. The home screen used to choose each card's label style with an
// eleven-way ternary keyed on the DISPLAY STRING. That had two failure modes
// no test could see: renaming a game silently dropped its card to the default
// style, and game #11 had to remember to extend a chain buried in a build
// method. The styles now live in the registry, so they can be asserted.
//
// The values below were captured from the ternary BEFORE it was deleted.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dart_games/constants/game_filter_registry.dart';
import 'package:dart_games/theme/game_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // game -> (sizeDelta, fontWeight, letterSpacing, height)
  const expected = <String, List<Object?>>{
    'carnival_derby': [2.0, null, null, null],
    'target_tag': [4.0, null, 1.2, null],
    'monster_mash': [6.0, FontWeight.bold, null, null],
    'reef_royale': [5.0, FontWeight.bold, null, null],
    'clockwork_quest': [3.0, FontWeight.bold, null, null],
    'lunar_lander': [3.0, FontWeight.bold, null, null],
    'gladiator_arena': [4.0, FontWeight.bold, null, null],
    'tiki_golf': [6.0, FontWeight.bold, null, 0.6],
    'treasure_divide': [6.0, null, 1.0, null],
  };

  group('card title styles survive the move into the registry', () {
    expected.forEach((gameId, spec) {
      test(gameId, () {
        final style = GameFilterRegistry.byId(gameId)?.cardTitleStyle;
        expect(style, isNotNull, reason: '$gameId lost its card style');
        expect(style!.sizeDelta, spec[0]);
        expect(style.fontWeight, spec[1]);
        expect(style.letterSpacing, spec[2]);
        expect(style.height, spec[3]);
      });
    });

    test("Pirate's Grid has no style and falls back to the default", () {
      // It was the ternary's else branch; that must stay true.
      expect(GameFilterRegistry.byId('pirates_grid'), isNotNull);
      expect(GameFilterRegistry.byId('pirates_grid')!.cardTitleStyle, isNull);
    });

    testWidgets('resolve() applies the delta to the ambient size',
        (tester) async {
      final style = GameFilterRegistry.byId('monster_mash')!.cardTitleStyle!;
      final resolved = style.resolve(baseSize: 16, color: Colors.white);
      expect(resolved.fontSize, 22, reason: '16 + 6');
      expect(resolved.color, Colors.white);
      expect(resolved.fontWeight, FontWeight.bold);
    });
  });

  group('every game carries its GameTheme', () {
    test('all ten registry entries are themed', () {
      final unthemed = [
        for (final g in GameFilterRegistry.all)
          if (g.theme == null) g.gameId
      ];
      expect(unthemed, isEmpty,
          reason: 'A game with no theme cannot be styled from the registry: '
              '$unthemed');
    });

    test('each entry points at the theme with the matching gameId', () {
      for (final g in GameFilterRegistry.all) {
        expect(g.theme!.gameId, g.gameId,
            reason: '${g.gameId} is wired to the wrong GameTheme');
        expect(g.theme, same(GameTheme.of(g.gameId)));
      }
    });
  });
}
