import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 4: Cancel add player dialog does not add player',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    final playersBefore = ProviderHelpers.getAllPlayers(tester).length;

    await SettingsHelpers.openAddPlayerDialog(
        tester, getAddPlayerButton(tester));
    await tester.enterText(
        ElementFinders.getAddPlayerNameField(), 'CancelMe');
    await PumpSequences.textEntry(tester);
    await SettingsHelpers.cancelAddPlayerDialog(tester);

    final playersAfter = ProviderHelpers.getAllPlayers(tester).length;
    expect(playersAfter, playersBefore);
  });
}
