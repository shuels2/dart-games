// integration_test/tiki_golf/add_player/photo_ui_elements_test.dart
//
// Test 3 — Open Add Player dialog, assert photo UI elements present
//           (camera button OR upload button, placeholder avatar).
//
// Section 12B File 1 — add_player Test 3
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add Player dialog shows photo UI elements',
      (tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_add_player_photo_ui_elements',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToGameMenu(tester, config);

        // Open Add Player dialog from empty state
        final addButton = ElementFinders.getTikiGolfAddPlayerButtonEmptyState();
        expect(addButton, findsAtLeastNWidgets(1),
            reason: '[DIAG photo_ui] Empty-state add button not found');
        await tester.ensureVisible(addButton.first);
        await tester.pump();
        await tester.tap(addButton.first);
        await PumpSequences.dialogOpen(tester);

        // Verify dialog opened
        expect(find.text('Add New Player'), findsWidgets,
            reason: '[DIAG photo_ui] Add New Player dialog title not found');

        // Verify photo placeholder avatar icon
        expect(find.byIcon(Icons.person), findsOneWidget,
            reason: '[DIAG photo_ui] Person placeholder icon not found');

        // Verify Camera button (text or icon)
        expect(find.text('CAMERA'), findsOneWidget,
            reason: '[DIAG photo_ui] CAMERA button text not found');
        expect(find.byIcon(Icons.camera_alt), findsOneWidget,
            reason: '[DIAG photo_ui] Camera icon not found');

        // Verify Gallery button
        expect(find.text('GALLERY'), findsOneWidget,
            reason: '[DIAG photo_ui] GALLERY button text not found');
        expect(find.byIcon(Icons.photo_library), findsOneWidget,
            reason: '[DIAG photo_ui] Gallery icon not found');

        // Verify Photo label
        expect(find.text('Photo (Optional)'), findsOneWidget,
            reason: '[DIAG photo_ui] Photo (Optional) label not found');

        // Verify Cancel button is present
        expect(find.text('Cancel'), findsOneWidget,
            reason: '[DIAG photo_ui] Cancel button not found in dialog');
      },
    );
  });
}
