import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static style checks over the per-game screens.
///
/// These exist because the defects that survive to human review are almost
/// never logic bugs — they are styling ones: a raw Material colour instead of
/// the game's palette, an AppBar title that skipped the display font, a back
/// button that doesn't match the others. They are invisible to behaviour tests
/// and only show up when someone looks at a screenshot.
///
/// Reading source as text (rather than rendering) keeps this in `flutter test`,
/// so it runs in seconds and can gate a build long before chromedriver exists.
///
/// Existing violations are recorded in baselines below. The rule for anything
/// new is zero: a game added after this test cannot introduce violations, and
/// the baselines only ever shrink.
void main() {
  final gameDir = Directory('lib/screens/games');

  /// Every .dart file under lib/screens/games, keyed by its path relative to
  /// that directory.
  Map<String, String> readGameSources() {
    final out = <String, String>{};
    for (final entity in gameDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll(r'\', '/');
      out[normalized.split('lib/screens/games/').last] =
          entity.readAsStringSync();
    }
    return out;
  }

  group('Game screen style rules', () {
    // Raw Material palette colours. Games must draw from their own spec
    // palette; a stray Colors.blue is a visual defect no behaviour test sees.
    final rawColor = RegExp(r'\bColors\.(blue|red|green|grey|gray|orange|'
        r'purple|yellow|pink|teal|indigo|cyan|lime|brown|amber)\b');

    // Violations present when this rule was introduced. Do not add entries:
    // new games start at zero. Lowering a number as a file is cleaned up is
    // encouraged.
    const rawColorBaseline = <String, int>{
      'carnival_horse_race/horse_race_game_screen.dart': 1,
      'carnival_horse_race/horse_race_menu_screen.dart': 1,
      'carnival_horse_race/horse_race_results_screen.dart': 22,
      'lunar_lander/lunar_lander_results_screen.dart': 3,
      'monster_mash/monster_mash_game_screen.dart': 1,
      'monster_mash/monster_mash_results_screen.dart': 3,
      'reef_royale/reef_royale_game_screen.dart': 5,
      'target_tag/target_tag_menu_screen.dart': 2,
      'target_tag/target_tag_results_screen.dart': 9,
    };

    test('no new raw Material colours', () {
      final offenders = <String>[];
      readGameSources().forEach((path, src) {
        final count = rawColor.allMatches(src).length;
        final allowed = rawColorBaseline[path] ?? 0;
        if (count > allowed) {
          offenders.add('$path: $count (baseline $allowed)');
        }
      });

      expect(offenders, isEmpty,
          reason: 'Use the game\'s palette, not the Material default swatches. '
              'If a use is genuinely justified, raise the file\'s baseline in '
              'this test and say why in the commit.\n${offenders.join('\n')}');
    });

    test('baselined files have not silently improved without updating the '
        'baseline', () {
      // Keeps the baseline honest: once a file is cleaned up, the number comes
      // down, so the ratchet can never slip back.
      final stale = <String>[];
      final sources = readGameSources();
      rawColorBaseline.forEach((path, allowed) {
        final src = sources[path];
        if (src == null) return; // file removed — fine
        final count = rawColor.allMatches(src).length;
        if (count < allowed) stale.add('$path: now $count, baseline $allowed');
      });

      expect(stale, isEmpty,
          reason: 'These files improved — lower their baseline so the '
              'progress is locked in.\n${stale.join('\n')}');
    });

    /// The full `IconButton( ... )` expression containing the back arrow,
    /// found by walking back to the nearest `IconButton(` and forward to its
    /// balanced close paren. Returns null when the arrow isn't in one (a few
    /// older screens use a custom button).
    String? backButtonBlock(String src) {
      final arrow = src.indexOf('Icons.arrow_back');
      if (arrow < 0) return null;
      final open = src.lastIndexOf('IconButton(', arrow);
      if (open < 0) return null;
      var depth = 0;
      for (var i = open; i < src.length; i++) {
        final ch = src[i];
        if (ch == '(') depth++;
        if (ch == ')') {
          depth--;
          if (depth == 0) return src.substring(open, i + 1);
        }
      }
      return null;
    }

    // Screens whose back control is not an IconButton. Left as-is rather than
    // restyled; new games must use the standard IconButton.
    const customBackButton = <String>{
      'carnival_horse_race/horse_race_menu_screen.dart',
      'carnival_horse_race/horse_race_game_screen.dart',
    };

    test('AppBar back buttons use the shared size and suppress hover effects',
        () {
      // The back arrow appears on every menu and game screen, so any deviation
      // reads as a different app. Rules: 32px icon, and all three hover /
      // highlight / splash colours transparent.
      final offenders = <String>[];
      readGameSources().forEach((path, src) {
        if (customBackButton.contains(path)) return;
        final block = backButtonBlock(src);
        if (block == null) return;

        if (!block.contains('size: 32')) {
          offenders.add('$path: back arrow is not size: 32');
        }
        for (final property in const [
          'hoverColor: Colors.transparent',
          'highlightColor: Colors.transparent',
          'splashColor: Colors.transparent',
        ]) {
          if (!block.contains(property)) {
            offenders.add('$path: back button missing $property');
          }
        }
      });

      expect(offenders, isEmpty,
          reason: 'Back buttons must match across games.\n'
              '${offenders.join('\n')}');
    });

    test('AppBar titles use a display font, never a bare TextStyle', () {
      // A title that falls back to the default font is the single most
      // common "the game looks wrong" defect, and it survives every
      // behaviour test.
      final offenders = <String>[];
      readGameSources().forEach((path, src) {
        if (!path.endsWith('_menu_screen.dart') &&
            !path.endsWith('_game_screen.dart') &&
            !path.endsWith('_results_screen.dart')) {
          return;
        }
        final index = src.indexOf('AppBar(');
        if (index < 0) return;
        final end = (index + 1600).clamp(0, src.length);
        final window = src.substring(index, end);
        if (!window.contains('title:')) return;
        if (!window.contains('GoogleFonts.')) {
          offenders.add('$path: AppBar title does not use GoogleFonts');
        }
      });

      expect(offenders, isEmpty,
          reason: 'AppBar titles carry the game\'s identity.\n'
              '${offenders.join('\n')}');
    });
  });
}
