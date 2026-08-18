// integration_test/clockwork_quest/play_to_complete/_helpers.dart
//
// Spec for the two commodity play-to-complete scenarios. The bodies live in
// shared/play_to_complete_suite.dart; this file supplies only what is
// specific to Clockwork Quest.
//
// The per-OPTION play-to-complete tests in this folder (bestof3,
// hard_landing_on, shield_round, and so on) are NOT templated — they assert
// game-specific settings effects and stay hand-written.

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/play_to_complete_suite.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.clockworkQuest();

final playToCompleteSpec = PlayToCompleteSpec(
  config: config,
  setupAndStart: (tester) =>
      GameSetupHelpers.setupAndStartClockworkQuest(tester, config),
  hasWinner: (tester) =>
      ProviderHelpers.getClockworkQuestProvider(tester).hasWinner,
  // Hit gears 1 and 2 — advances the track without finishing it.
  midGameDarts: (tester) async {
    await DartThrowHelpers.throwDartViaMock(tester, 1);
    await DartThrowHelpers.throwDartViaMock(tester, 2);
  },
  verifyNotWonBeforeAutoPlay: true,
);
