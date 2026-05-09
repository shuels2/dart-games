import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Gameplay: Starting Altitude option', () {
    testWidgets(
        'starting altitude 100 — game begins with all players at 100',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          altitude: 100, playerNames: ['Alice', 'Bob']);

      final provider = ProviderHelpers.getLunarLanderProvider(tester);
      expect(provider.currentGame!.startingAltitude, equals(100));

      for (final p in provider.currentGame!.playerIds) {
        expect(
          provider.currentGame!.getCurrentAltitude(p),
          equals(100),
          reason: 'Player $p should start at altitude 100',
        );
      }

      // The active player's altitude readout should display "100"
      final readout = find.byKey(LunarLanderGameKeys.altitudeReadout);
      expect(readout, findsOneWidget);
      expect(
        find.descendant(of: readout, matching: find.text('100')),
        findsOneWidget,
        reason: 'Altitude readout pill should show "100"',
      );
    });

    testWidgets(
        'starting altitude 200 (default) — game begins with all players at 200',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          altitude: 200, playerNames: ['Alice', 'Bob']);

      final provider = ProviderHelpers.getLunarLanderProvider(tester);
      expect(provider.currentGame!.startingAltitude, equals(200));

      for (final p in provider.currentGame!.playerIds) {
        expect(
          provider.currentGame!.getCurrentAltitude(p),
          equals(200),
          reason: 'Player $p should start at altitude 200',
        );
      }

      // The active player's altitude readout should display "200"
      final readout = find.byKey(LunarLanderGameKeys.altitudeReadout);
      expect(readout, findsOneWidget);
      expect(
        find.descendant(of: readout, matching: find.text('200')),
        findsOneWidget,
        reason: 'Altitude readout pill should show "200"',
      );
    });

    testWidgets(
        'starting altitude 500 — game begins with all players at 500',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          altitude: 500, playerNames: ['Alice', 'Bob']);

      final provider = ProviderHelpers.getLunarLanderProvider(tester);
      expect(provider.currentGame!.startingAltitude, equals(500));

      for (final p in provider.currentGame!.playerIds) {
        expect(
          provider.currentGame!.getCurrentAltitude(p),
          equals(500),
          reason: 'Player $p should start at altitude 500',
        );
      }

      // The active player's altitude readout should display "500"
      final readout = find.byKey(LunarLanderGameKeys.altitudeReadout);
      expect(readout, findsOneWidget);
      expect(
        find.descendant(of: readout, matching: find.text('500')),
        findsOneWidget,
        reason: 'Altitude readout pill should show "500"',
      );
    });
  });
}
