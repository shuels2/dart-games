import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // MANDATORY: max player count test.
  // Pirate's Grid is always 2 players (min = max = 2).
  // Verifies no layout overflow with 2 players and full UI renders correctly.
  testWidgets('Gameplay: 2 players (spec maximum) — no overflow, full UI renders',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Captain Jack', 'Captain Redbeard']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    expect(provider.currentGame!.playerIds.length, 2,
        reason: 'Game should have exactly 2 players (spec max)');

    // Verify no overflow errors — check key UI elements are visible
    expect(ElementFinders.getPiratesGridSkipTurnButton(), findsOneWidget,
        reason: 'Skip turn button should be visible with 2 players');
    expect(ElementFinders.getPiratesGridPlayerAvatarActive(), findsOneWidget,
        reason: 'Active player avatar should be visible');
    expect(ElementFinders.getPiratesGridPlayerAvatarInactive(), findsOneWidget,
        reason: 'Inactive player avatar should be visible');

    // Grid cells all visible
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        expect(ElementFinders.getPiratesGridGridCell(r, c), findsOneWidget,
            reason: 'Grid cell [$r,$c] should be visible without overflow');
      }
    }

    // Verify player names rendered (no clipping)
    expect(find.text('Captain Jack'), findsWidgets,
        reason: 'P1 name should be rendered without clipping');
    expect(find.text('Captain Redbeard'), findsWidgets,
        reason: 'P2 name should be rendered without clipping');
  });
}
