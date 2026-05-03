import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.lunarLander();

  // Verifies that the AppBar Hard Landing badge is HIDDEN when the option
  // is OFF.
  testWidgets('Visual: hard landing badge NOT visible when option is OFF',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartLunarLander(tester, config,
        hardLanding: false, playerNames: ['Player A', 'Player B']);

    expect(find.byKey(LunarLanderGameKeys.hardLandingBadge), findsNothing,
        reason: 'Hard Landing badge should not render when option is OFF');
  });

  // Verifies that the AppBar Hard Landing badge IS visible when the option
  // is ON, and that the badge displays the "HARD LANDING" label.
  testWidgets('Visual: hard landing badge visible with correct text when option is ON',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartLunarLander(tester, config,
        hardLanding: true, playerNames: ['Player A', 'Player B']);

    expect(find.byKey(LunarLanderGameKeys.hardLandingBadge), findsOneWidget,
        reason: 'Hard Landing badge should render when option is ON');
    expect(
      find.descendant(
        of: find.byKey(LunarLanderGameKeys.hardLandingBadge),
        matching: find.text('HARD LANDING'),
      ),
      findsOneWidget,
      reason: 'Hard Landing badge should display "HARD LANDING" text',
    );
  });
}
