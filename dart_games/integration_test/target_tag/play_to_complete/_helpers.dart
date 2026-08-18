// integration_test/target_tag/play_to_complete/_helpers.dart
//
// Spec for the two commodity play-to-complete scenarios. The bodies live in
// shared/play_to_complete_suite.dart; this file supplies only what is
// specific to Target Tag.
//
// The per-OPTION play-to-complete tests in this folder (bestof3,
// hard_landing_on, shield_round, and so on) are NOT templated — they assert
// game-specific settings effects and stay hand-written.
import 'package:flutter_test/flutter_test.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/play_to_complete_suite.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/ui_test_helpers.dart';

final config = GameUIConfig.targetTag();

Future<void> _setupAndStart(WidgetTester tester) async {
  await UITestHelpers.navigateToGameMenu(tester, config);
  await UITestHelpers.addPlayer(tester, 'Player A', config);
  await UITestHelpers.addPlayer(tester, 'Player B', config);
  await UITestHelpers.startGame(tester, config);
}

/// Two darts on the player's own target — builds shields without ending the
/// game, so auto-play has a genuinely mid-turn board to pick up.
Future<void> _midGameDarts(WidgetTester tester) async {
  final targetNumber = GameSetupHelpers.getCurrentPlayerTargetNumber(tester);
  await DartThrowHelpers.throwDartViaMock(tester, targetNumber,
      multiplier: 'single');
  await DartThrowHelpers.throwDartViaMock(tester, targetNumber,
      multiplier: 'single');
}

final playToCompleteSpec = PlayToCompleteSpec(
  config: config,
  setupAndStart: _setupAndStart,
  hasWinner: (tester) => ProviderHelpers.getTargetTagProvider(tester).hasWinner,
  midGameDarts: _midGameDarts,
  maxIterations: 800,
  verifyNotWonBeforeAutoPlay: true,
);
