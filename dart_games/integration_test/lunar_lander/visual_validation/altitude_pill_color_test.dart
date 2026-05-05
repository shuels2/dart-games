import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Color constants from lunar_lander_game_screen.dart
  const rocketFlame = Color(0xFFF26430); // active, altitude >= 0
  const thrusterRed = Color(0xFFE63946); // any player, altitude < 0

  final config = GameUIConfig.lunarLander();

  // Verifies the altitude pill on the active player's track turns RED when
  // altitude drops below 0 (Hard Landing OFF). At start it should be ORANGE
  // (rocketFlame) for the active player. After overshooting (alt < 0) the
  // pill colour switches to thrusterRed.
  testWidgets('Visual: altitude pill turns red when altitude goes below 0',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    // Hard Landing OFF + low starting altitude so a couple of triple-20s push
    // us below zero. Going below 0 with HL OFF triggers a win, but the game
    // screen remains visible (post-win takeout flow has multi-second delays
    // before navigation), so we can still inspect the rendered pill colour.
    await GameSetupHelpers.setupAndStartLunarLander(tester, config,
        altitude: 100, hardLanding: false, playerNames: ['Player A', 'Player B']);

    final p1Id = ProviderHelpers.getLunarLanderCurrentPlayerId(tester)!;

    // Initial: active player altitude readout should be ORANGE (alt = 100 > 0)
    final initialPill = tester.widget<Container>(
      find.byKey(LunarLanderGameKeys.altitudeReadout),
    );
    final initialDeco = initialPill.decoration as BoxDecoration;
    expect(initialDeco.color, rocketFlame.withOpacity(0.9),
        reason: 'Active player altitude pill should be orange at the start');

    // Drive altitude below zero. T20 (60) twice -> 100 - 60 - 60 = -20.
    // After dart 2 the provider triggers a win and locks _waitingForTakeout,
    // so subsequent dart throws are no-ops. The pill should now be RED.
    await DartThrowHelpers.throwDartViaMock(tester, 20, multiplier: 'triple');
    await DartThrowHelpers.throwDartViaMock(tester, 20, multiplier: 'triple');

    // Sanity: altitude is negative and the game has registered a winner
    expect(ProviderHelpers.getLunarLanderAltitude(tester, p1Id), lessThan(0),
        reason: 'Altitude should be below 0 after two triple-20s');
    expect(ProviderHelpers.lunarLanderHasWinner(tester), isTrue,
        reason: 'Hard Landing OFF: going below 0 should win the game');

    // Pump a small amount but stay well below the 3000ms navigation delay
    await tester.pump(const Duration(milliseconds: 200));

    // The active player altitude pill should now be RED (thrusterRed)
    final redPill = tester.widget<Container>(
      find.byKey(LunarLanderGameKeys.altitudeReadout),
    );
    final redDeco = redPill.decoration as BoxDecoration;
    expect(redDeco.color, thrusterRed.withOpacity(0.9),
        reason: 'Altitude pill should turn red when altitude < 0');
  });
}
