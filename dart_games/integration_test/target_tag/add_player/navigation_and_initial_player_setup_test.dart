import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import 'package:dart_games/constants/test_keys.dart';

import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Navigation and Initial Player Setup - Validates app launch, game navigation, and basic player addition workflow with two players', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // Navigate to Target Tag menu
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Verify we're on the Target Tag menu screen
    expect(find.textContaining('Shield Max:'), findsOneWidget);
    expect(find.text('Solo'), findsOneWidget);
    expect(find.text('Team'), findsOneWidget);

    // Add first player (using empty state button)
    final addButtonEmpty = find.byKey(TargetTagMenuKeys.addPlayerButtonEmptyState);
    expect(addButtonEmpty, findsOneWidget);
    await tester.tap(addButtonEmpty);
    await PumpSequences.dialogOpen(tester);

    // Enter first player name
    final nameField = ElementFinders.getAddPlayerNameField();
    await tester.enterText(nameField, 'Player 1');
    await PumpSequences.textEntry(tester);

    // Tap Add Player button
    final addPlayerButton = ElementFinders.getAddPlayerAddButton();
    await tester.tap(addPlayerButton.first);
    await PumpSequences.dialogClose(tester);

    // Verify first player was added
    expect(find.text('Player 1'), findsOneWidget);

    // Add second player (now using normal state button)
    final addButtonNormal = ElementFinders.getTargetTagAddPlayerButton();
    expect(addButtonNormal, findsAtLeastNWidgets(1));
    await tester.tap(addButtonNormal.first);
    await PumpSequences.dialogOpen(tester);

    // Enter second player name
    await tester.enterText(nameField, 'Player 2');
    await PumpSequences.textEntry(tester);

    // Tap Add Player button
    await tester.tap(addPlayerButton.first);
    await PumpSequences.dialogClose(tester);

    // Verify second player was added
    expect(find.text('Player 2'), findsOneWidget);
  });
}
