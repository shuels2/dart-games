import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add Player: photo UI elements are visible in dialog',
      (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Open Add Player dialog
    await tester
        .tap(ElementFinders.getGladiatorArenaAddPlayerButtonEmptyState());
    await PumpSequences.dialogOpen(tester);

    // Verify dialog has photo buttons
    expect(ElementFinders.getAddPlayerDialog(), findsOneWidget);
    expect(ElementFinders.getAddPlayerCameraButton(), findsOneWidget);
    expect(ElementFinders.getAddPlayerGalleryButton(), findsOneWidget);
    expect(ElementFinders.getAddPlayerNameField(), findsOneWidget);

    // Cancel dialog
    await tester.tap(ElementFinders.getAddPlayerCancelButton());
    await PumpSequences.dialogClose(tester);
  });
}
