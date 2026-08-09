// test/theme/game_theme_test.dart
//
// WS03 §3.1. Characterization cover for the GameTheme extraction.
//
// The point of these tests is that they were written from the values the
// config factories produced BEFORE the migration. They pin rendered output,
// so a factory rewritten to read from GameTheme instead of a colour literal
// is proven value-preserving rather than assumed to be.
//
// They also pin the DEVIATIONS — the places a widget deliberately departs
// from its game's theme. Those are design decisions (Tiki's save-modal icon
// is Tropical Orange, not its Lagoon Blue accent; Carnival's icon is 56px
// where everyone else uses 48) and flattening them into the theme would
// change what the app looks like.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dart_games/theme/game_theme.dart';
import 'package:dart_games/widgets/save_game_modal/save_game_modal_config.dart';

/// (gameId, the factory that config file exposes for it).
final _saveModalByGame = <String, SaveGameModalConfig Function()>{
  'carnival_derby': SaveGameModalConfig.carnivalDerby,
  'target_tag': SaveGameModalConfig.targetTag,
  'monster_mash': SaveGameModalConfig.monsterMash,
  'reef_royale': SaveGameModalConfig.reefRoyale,
  'lunar_lander': SaveGameModalConfig.lunarLander,
  'pirates_grid': SaveGameModalConfig.piratesGrid,
  'gladiator_arena': SaveGameModalConfig.gladiatorArena,
  'clockwork_quest': SaveGameModalConfig.clockworkQuest,
  'tiki_golf': SaveGameModalConfig.tikiGolf,
  'treasure_divide': SaveGameModalConfig.treasureDivide,
};

/// Don't Save button fill, per game. Eight are transparent; two are not.
const _expectedDontSaveFill = <String, Color>{
  'carnival_derby': Colors.transparent,
  'target_tag': Colors.transparent,
  'monster_mash': Colors.transparent,
  'reef_royale': Colors.transparent,
  'lunar_lander': Colors.transparent,
  'pirates_grid': Colors.transparent,
  'gladiator_arena': Color(0xFFC0392B),
  'clockwork_quest': Colors.transparent,
  'tiki_golf': Colors.transparent,
  'treasure_divide': Color(0xFFC41E3A),
};

void main() {
  // GoogleFonts touches the services binding when a style is built, and will
  // otherwise try to fetch font files over the network mid-test.
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('GameTheme registry', () {
    test('covers every game exactly once', () {
      expect(GameTheme.all.length, 10);
      for (final entry in GameTheme.all.entries) {
        expect(entry.value.gameId, entry.key,
            reason: 'registry key must match the theme gameId');
      }
    });

    test('of() throws for an unknown game rather than returning a default', () {
      // A silent default would let game #11 render with another game's palette
      // and look merely "wrong" rather than fail.
      expect(() => GameTheme.of('not_a_game'), throwsArgumentError);
      expect(GameTheme.of('tiki_golf'), same(GameTheme.tikiGolf));
    });

    test('surface falls back to background when not given', () {
      expect(GameTheme.tikiGolf.surface, GameTheme.tikiGolf.background);
    });

    testWidgets('font builders are usable and carry the requested size',
        (tester) async {
      final style = GameTheme.monsterMash.titleFont(fontSize: 28);
      expect(style.fontSize, 28);
      expect(GameTheme.monsterMash.bodyFont(fontSize: 18).fontSize, 18);
    });

    test('the accent-shadow games are recorded as such', () {
      // Half the roster shadows in black; the other half glows in its own
      // colour. Two of those do NOT use their accent, which is exactly the
      // kind of detail a "tidy-up" would silently normalise.
      expect(GameTheme.gladiatorArena.shadow, const Color(0xFFDAA520),
          reason: 'Gladiator shadows in gold, not its bronze accent');
      expect(GameTheme.clockworkQuest.shadow, const Color(0xFFFFBF00),
          reason: 'Clockwork shadows in amber, not its brass accent');
      expect(GameTheme.clockworkQuest.shadowOpacity, 0.4,
          reason: 'Clockwork is the only game at 0.4');
    });
  });

  group('SaveGameModalConfig matches its GameTheme', () {
    // Captured from the pre-migration factories.
    _saveModalByGame.forEach((gameId, factory) {
      testWidgets(gameId, (tester) async {
        final config = factory();
        final theme = GameTheme.of(gameId);

        expect(config.backgroundColor, theme.background,
            reason: 'panel colour must come from the theme');
        expect(config.borderColor, theme.accent,
            reason: 'border must come from the theme accent');
        expect(config.boxShadowColor, theme.shadow);
        expect(config.boxShadowOpacity, theme.shadowOpacity);
        expect(config.dontSaveButtonTextColor, theme.onDark);
        // NOT asserted as universally transparent: Gladiator Arena
        // (0xFFC0392B) and Treasure Divide (0xFFC41E3A) give the
        // Don't Save button a solid red fill. Writing this test from the
        // real values rather than from the pattern is what surfaced that.
        expect(config.dontSaveButtonColor, _expectedDontSaveFill[gameId]);
      });
    });
  });

  group('SaveGameModalConfig deviations are preserved', () {
    testWidgets('Carnival Derby uses a 56px icon where the rest use 48', (tester) async {
      expect(SaveGameModalConfig.carnivalDerby().iconSize, 56);
      expect(SaveGameModalConfig.targetTag().iconSize, 48);
      expect(SaveGameModalConfig.tikiGolf().iconSize, 48);
    });

    testWidgets('Tiki Golf icon is Tropical Orange, NOT its Lagoon Blue accent', (tester) async {
      expect(SaveGameModalConfig.tikiGolf().iconColor,
          const Color(0xFFFF8C42));
      expect(SaveGameModalConfig.tikiGolf().iconColor,
          isNot(GameTheme.tikiGolf.accent));
    });

    testWidgets('Tiki Golf title keeps its four-shadow outline', (tester) async {
      final shadows = SaveGameModalConfig.tikiGolf().titleTextStyle.shadows;
      expect(shadows, isNotNull);
      expect(shadows!.length, 4,
          reason: 'the offset outline is the Tiki look; losing it is visible');
      for (final s in shadows) {
        expect(s.color, const Color(0xFF8B5E3C));
      }
    });

    testWidgets('save-button text sizes differ per game and are not normalised', (tester) async {
      expect(SaveGameModalConfig.tikiGolf().saveButtonTextStyle.fontSize, 22);
      expect(SaveGameModalConfig.targetTag().saveButtonTextStyle.fontSize, 20);
    });

    testWidgets('title sizes differ per game', (tester) async {
      expect(SaveGameModalConfig.carnivalDerby().titleTextStyle.fontSize, 28);
      expect(SaveGameModalConfig.targetTag().titleTextStyle.fontSize, 24);
    });
  });
}
