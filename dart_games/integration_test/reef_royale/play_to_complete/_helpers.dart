// integration_test/reef_royale/play_to_complete/_helpers.dart
//
// Spec for the two commodity play-to-complete scenarios. The bodies live in
// shared/play_to_complete_suite.dart; this file supplies only what is
// specific to Reef Royale.
//
// The per-OPTION play-to-complete tests in this folder (bestof3,
// hard_landing_on, shield_round, and so on) are NOT templated — they assert
// game-specific settings effects and stay hand-written.

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/play_to_complete_suite.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.reefRoyale();

final playToCompleteSpec = PlayToCompleteSpec(
  config: config,
  setupAndStart: (tester) =>
      GameSetupHelpers.setupAndStartReefRoyale(tester, config),
  hasWinner: (tester) =>
      ProviderHelpers.getReefRoyaleProvider(tester).hasWinner,
  midGameDarts: (tester) async {
    await DartThrowHelpers.throwDartViaMock(tester, 20, multiplier: 'single');
    await DartThrowHelpers.throwDartViaMock(tester, 20, multiplier: 'single');
  },
  maxIterations: 800,
  verifyNotWonBeforeAutoPlay: true,
);
