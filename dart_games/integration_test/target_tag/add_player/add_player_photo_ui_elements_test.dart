import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';

import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 3: Add Player Photo UI Elements - Validates photo upload interface elements (Camera/Gallery buttons, icons, placeholder avatar, optional photo label), player creation with photo UI workflow', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // Navigate to Target Tag menu
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Find and tap "NEW PLAYER" button (empty state since no players yet)
    final addButton = ElementFinders.getTargetTagAddPlayerButtonEmptyState();
    expect(addButton, findsAtLeastNWidgets(1));
    await tester.tap(addButton.first);
    await PumpSequences.dialogOpen(tester);

    // Verify dialog opened
    expect(find.text('Add New Player'), findsWidgets);

    // Verify photo selection UI elements are present
    expect(find.text('CAMERA'), findsOneWidget);
    expect(find.text('GALLERY'), findsOneWidget);
    expect(find.text('Photo (Optional)'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget); // Placeholder avatar
    expect(find.byIcon(Icons.camera_alt), findsOneWidget); // Camera button icon
    expect(find.byIcon(Icons.photo_library), findsOneWidget); // Gallery button icon

    // Enter player name
    final nameField = ElementFinders.getAddPlayerNameField();
    await tester.enterText(nameField, 'Photo Player');
    await PumpSequences.textEntry(tester);

    // Note: We cannot test actual photo selection in integration tests
    // without complex mocking. This test verifies UI elements exist.

    // Tap "Add Player" button
    final addPlayerButton = ElementFinders.getAddPlayerAddButton();
    await tester.tap(addPlayerButton.first);
    await PumpSequences.dialogClose(tester);

    // Verify player was added
    expect(find.text('Photo Player'), findsOneWidget);
  });
}
