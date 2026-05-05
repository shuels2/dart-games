import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Menu: start with default settings (altitude=200, hard landing=OFF)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartLunarLander(tester, GameUIConfig.lunarLander());

    // Verify game started with correct settings
    expect(ProviderHelpers.isLunarLanderGameActive(tester), isTrue);
    expect(ProviderHelpers.getLunarLanderStartingAltitude(tester), 200);
    expect(ProviderHelpers.isLunarLanderHardLandingEnabled(tester), isFalse);
  });
}
