// integration_test/tiki_golf/results_screen/solo_tie_test.dart
//
// Solo-mode tie: when two players finish a Tiki Golf game with identical
// total strokes, the results screen must show BOTH players as tied
// champions, and BOTH players must receive a win in their stats.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dart_games/constants/test_keys.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Results: solo tie shows both winners and credits both with a win',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        maxStrokes: 3, playerNames: ['Alice', 'Bob']);

    // Both players birdie every hole → tied at total=9 strokes each.
    await driveToTie(tester);
    await tester.pump(const Duration(seconds: 5));
    await PumpSequences.fullRebuild(tester);

    // Provider reflects the tie
    final provider = ProviderHelpers.getTikiGolfProvider(tester);
    final winnerIds = provider.currentGame!.winnerIds!;
    expect(winnerIds.length, 2,
        reason: 'Both players should be tied winners after identical totals');

    // Results screen displays plural "GOLDEN TIKI CHAMPIONS!" heading
    expect(find.text('GOLDEN TIKI CHAMPIONS!'), findsOneWidget,
        reason: 'Tied solo game should show plural champions heading');
    expect(find.text('TIED!'), findsOneWidget,
        reason: 'Tied solo game should display a TIED! label');

    // Both tied-winner avatar tiles are present
    final alice = ProviderHelpers.findPlayerByName(tester, 'Alice')!;
    final bob = ProviderHelpers.findPlayerByName(tester, 'Bob')!;
    expect(find.byKey(TikiGolfResultsKeys.tiedWinnerPhoto(alice.id)),
        findsOneWidget,
        reason: 'Alice tied-winner avatar should be on results screen');
    expect(find.byKey(TikiGolfResultsKeys.tiedWinnerPhoto(bob.id)),
        findsOneWidget,
        reason: 'Bob tied-winner avatar should be on results screen');
    expect(find.byKey(TikiGolfResultsKeys.tiedWinnerName(alice.id)),
        findsOneWidget);
    expect(find.byKey(TikiGolfResultsKeys.tiedWinnerName(bob.id)),
        findsOneWidget);

    // Stats: BOTH tied players receive a win
    final aliceAfter = ProviderHelpers.findPlayerByName(tester, 'Alice')!;
    final bobAfter = ProviderHelpers.findPlayerByName(tester, 'Bob')!;
    expect(aliceAfter.gamesWon, 1,
        reason: 'Alice is tied for the win → gamesWon should increment');
    expect(bobAfter.gamesWon, 1,
        reason: 'Bob is tied for the win → gamesWon should increment');
    expect(aliceAfter.gamesPlayed, 1);
    expect(bobAfter.gamesPlayed, 1);
  });
}
