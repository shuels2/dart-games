import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 3: Add player photo UI elements - Camera/gallery buttons present in dialog, player created without photo', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Open the add player dialog
    final emptyStateButton = ElementFinders.getMonsterMashAddPlayerButtonEmptyState();
    final normalStateButton = ElementFinders.getMonsterMashAddPlayerButton();

    Finder addButton;
    if (emptyStateButton.evaluate().isNotEmpty) {
      addButton = emptyStateButton;
    } else {
      addButton = normalStateButton;
    }

    await tester.ensureVisible(addButton.first);
    await tester.pump();
    await tester.tap(addButton.first);
    await PumpSequences.dialogOpen(tester);

    // Verify dialog is open
    final dialog = ElementFinders.getAddPlayerDialog();
    expect(dialog, findsOneWidget);

    // Verify camera and gallery buttons exist
    final cameraButton = ElementFinders.getAddPlayerCameraButton();
    final galleryButton = ElementFinders.getAddPlayerGalleryButton();
    expect(cameraButton, findsOneWidget);
    expect(galleryButton, findsOneWidget);

    // Verify name field exists
    final nameField = ElementFinders.getAddPlayerNameField();
    expect(nameField, findsOneWidget);

    // Enter a name and add player (without selecting photo)
    await tester.enterText(nameField, 'No Photo Player');
    await PumpSequences.textEntry(tester);

    final addPlayerButton = ElementFinders.getAddPlayerAddButton();
    await tester.tap(addPlayerButton.first);
    await PumpSequences.dialogClose(tester);

    // Verify player was created
    expect(find.text('No Photo Player'), findsWidgets);
  });
}
