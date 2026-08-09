// test/meta/guarded_tap_lint_test.dart
//
// Detector (a) of the three from ANSWERS-FROM-FABLE-2 §A8.2.
//
// A tap wrapped in `if (finder.evaluate().isNotEmpty) { ... tester.tap(...) }`
// CANNOT FAIL. If the finder never matches — a dead widget key, a tooltip that
// was never set — the guard is silently false, the tap never happens, and the
// test passes while asserting nothing about the interaction it is named for.
//
// This is not hypothetical. All three of these were found this way:
//
//   * Carnival's "Pause blocks settings controls" tapped
//     `carnival_menu_target_score_dropdown`, a key declared in test_keys.dart
//     but never attached to any widget (the menu builds a Slider under a
//     different key). The guard was permanently false for the life of the test.
//   * Clockwork's and Lunar's "Pause blocks AppBar back button" used
//     `find.byTooltip('Back')`; neither back button carries that tooltip.
//
// Prefer: tap unguarded with `warnIfMissed: false` and assert the CONSEQUENCE
// (the overlay is still up, the screen did not navigate). That fails loudly
// when the finder rots.
//
// ─── SCOPE ─────────────────────────────────────────────────────────────────
// `integration_test/shared/` is exempt. Its guards are genuine branch logic —
// navigation_suite's game-back runner dismisses a Save prompt that may or may
// not be present depending on whether the game threw a dart — not a
// can-never-fire tap.
//
// The existing files are baselined BY NAME rather than fixed: several are
// screenshot flows where an optional step is legitimately conditional, and
// auditing all fifteen is separate work. The baseline is shrink-only — the
// hygiene test below fails if a file is fixed and left listed.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files containing at least one guarded tap today.
///
/// NOTE ON THE COUNT: ANSWERS-FROM-FABLE-2 estimated 34. That came from
/// grepping `evaluate().isNotEmpty` anywhere, which also matches legitimate
/// existence assertions. Matching the guard-wrapping-a-tap shape specifically
/// finds 15.
const _baseline = <String>{
  'clockwork_quest/add_player/remove_player_test.dart',
  'monster_mash/visual_validation/round_progress_bar_states_test.dart',
  'pause_modal/home_screen_pause_test.dart',
  'reef_royale/edit_score/edit_creates_winner_stats_test.dart',
  'reef_royale/edit_score/edit_removes_winner_no_stats_test.dart',
  'reef_royale/edit_score/triggers_win_when_final_target_claimed_test.dart',
  'reef_royale/reef_royale_screenshot_test.dart',
  'reef_royale/reef_royale_showcase_test.dart',
  'target_tag/menu_and_mechanics/player_count_validation_all_modes_test.dart',
  'tiki_golf/team_setup/random_distribution_full_table_test.dart',
  'tiki_golf/visual_validation/tiki_golf_screenshot_results_test.dart',
  'tiki_golf/visual_validation/tiki_golf_screenshot_test.dart',
  'treasure_divide/gameplay/custom_targets_on_randomizes_sequence_test.dart',
  'treasure_divide/menu_and_settings/start_button_disabled_below_min_players_test.dart',
  'treasure_divide/visual_validation/treasure_divide_screenshot_test.dart',
};

final _guardedTap = RegExp(
  r'if\s*\([^)]*\.evaluate\(\)\.isNotEmpty\)\s*\{[^}]*\btester\.tap\(',
  dotAll: true,
);

Set<String> _offenders() {
  final found = <String>{};
  for (final entity in Directory('integration_test').listSync(recursive: true)) {
    if (entity is! File) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (!path.endsWith('_test.dart')) continue;
    if (path.contains('/shared/')) continue;
    if (_guardedTap.hasMatch(entity.readAsStringSync())) {
      found.add(path.split('integration_test/').last);
    }
  }
  return found;
}

void main() {
  final offenders = _offenders();

  test('no NEW guarded taps in per-game UI tests', () {
    final unexpected = offenders.difference(_baseline);
    expect(unexpected, isEmpty,
        reason: 'A tap behind `if (finder.evaluate().isNotEmpty)` cannot fail: '
            'if the finder rots, the test silently stops testing. Tap with '
            '`warnIfMissed: false` and assert the consequence instead. '
            'Offenders: $unexpected');
  });

  test('baseline is not stale — fixed files must be removed from it', () {
    final fixed = _baseline.difference(offenders);
    expect(fixed, isEmpty,
        reason: 'These no longer contain a guarded tap. Delete them from the '
            'baseline so it keeps guarding them: $fixed');
  });
}
